import 'dart:convert';
import 'dart:core';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

// ============================================================================
// Data Store (in-memory)
// ============================================================================
final _uuid = Uuid();
final _bookings = <Map<String, dynamic>>[];
final _pendingSync = <Map<String, dynamic>>[];
int _bookingIdCounter = 1;
String? _currentToken;
DateTime? _tokenIssuedAt;
bool _isTokenExpired = false;
const _tokenExpirySeconds = 300; // 5 minutes

// ============================================================================
// Helpers
// ============================================================================
Map<String, dynamic> _errorResponse(String message, {int? code}) => {
  'error': message,
  if (code != null) 'code': code,
};

Map<String, dynamic> _createBooking({
  required String serviceId,
  required String bookingTime,
  String? doctorId,
}) {
  return {
    'id': _bookingIdCounter++,
    'service_id': serviceId,
    'booking_time': bookingTime,
    'doctor_id': doctorId ?? 'dr_001',
    'status': 'confirmed',
    'created_at': DateTime.now().toIso8601String(),
  };
}

void _seedBookings() {
  final now = DateTime.now();
  for (var i = 1; i <= 25; i++) {
    _bookings.add({
      'id': _bookingIdCounter++,
      'service_id': 'svc_${(i % 5) + 1}',
      'booking_time': now
          .add(Duration(days: i, hours: i % 24))
          .toIso8601String(),
      'doctor_id': 'dr_${(i % 3) + 1}',
      'status': i % 5 == 0 ? 'cancelled' : 'confirmed',
      'created_at': now.subtract(Duration(days: 30 - i)).toIso8601String(),
    });
  }
}

// ============================================================================
// Token Management
// ============================================================================
String _generateToken() =>
    'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';

Map<String, dynamic> _generateTokens() {
  _currentToken = _generateToken();
  _tokenIssuedAt = DateTime.now();
  _isTokenExpired = false;
  return {
    'access_token': _currentToken,
    'refresh_token':
        'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    'expires_in': _tokenExpirySeconds,
    'token_type': 'Bearer',
  };
}

bool _isTokenValid(String? token) {
  if (token == null || _currentToken == null) return false;
  if (_isTokenExpired) return false;
  if (token != _currentToken) return false;
  if (_tokenIssuedAt == null) return false;
  return DateTime.now().difference(_tokenIssuedAt!).inSeconds <
      _tokenExpirySeconds;
}

void _expireToken() => _isTokenExpired = true;

// ============================================================================
// Middleware (auth check)
// ============================================================================
Response? _checkAuth(Request request) {
  final path = request.url.path;
  if (path == 'auth/login' || path == 'auth/refresh') return null;

  final authHeader = request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return Response.unauthorized(
      jsonEncode(_errorResponse('Missing or invalid auth header')),
    );
  }

  final token = authHeader.substring(7);
  if (!_isTokenValid(token)) {
    if (token == _currentToken && _isTokenExpired) {
      return Response(
        401,
        body: jsonEncode(_errorResponse('Token expired', code: 401)),
      );
    }

    return Response.unauthorized(jsonEncode(_errorResponse('Invalid token')));
  }

  return null;
}

// ============================================================================
// Handlers
// ============================================================================
Response handleWelcome() => Response.ok(
  jsonEncode({
    'message': 'Mock API server is running.',
    'endpoints': [
      'POST /auth/login',
      'POST /auth/refresh',
      'POST /auth/logout',
      'GET /bookings',
      'POST /bookings',
      'DELETE /bookings/{id}',
      'GET /pending-sync',
      'POST /admin/expire-token',
      'POST /admin/reset',
    ],
  }),
);

Response handleLogin(String body) {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final username = data['username'] as String?;
    final password = data['password'] as String?;
    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return Response.badRequest(
        body: jsonEncode(_errorResponse('Username and password required')),
      );
    }
    final tokens = _generateTokens();
    return Response.ok(
      jsonEncode({
        ...tokens,
        'user': {'id': 'user_001', 'username': username, 'name': 'Test User'},
      }),
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode(_errorResponse('Login failed: $e')),
    );
  }
}

Response handleRefresh(String body) {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final refreshToken = data['refresh_token'] as String?;
    if (refreshToken == null ||
        !refreshToken.startsWith('mock_refresh_token_')) {
      return Response.unauthorized(
        jsonEncode(_errorResponse('Invalid refresh token')),
      );
    }
    final tokens = _generateTokens();
    return Response.ok(jsonEncode(tokens));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode(_errorResponse('Refresh failed: $e')),
    );
  }
}

Response handleLogout() {
  _currentToken = null;
  _tokenIssuedAt = null;
  _isTokenExpired = false;
  return Response.ok(jsonEncode({'message': 'Logged out'}));
}

Response handleGetBookings(Request request) {
  final auth = _checkAuth(request);
  if (auth != null) return auth;

  try {
    final params = request.url.queryParameters;
    final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
    final cursor = params['cursor'];

    var filtered = List<Map<String, dynamic>>.from(_bookings);
    if (cursor != null) {
      final cursorId = int.tryParse(cursor);
      if (cursorId != null) {
        final index = filtered.indexWhere((b) => b['id'] == cursorId);
        if (index != -1) filtered = filtered.sublist(index + 1);
      }
    }
    filtered.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    final hasMore = filtered.length > limit;
    final items = filtered.take(limit).toList();
    final nextCursor = hasMore ? items.last['id'].toString() : null;

    return Response.ok(
      jsonEncode({
        'data': items,
        'pagination': {
          'limit': limit,
          'next_cursor': nextCursor,
          'has_more': hasMore,
          'total': _bookings.length,
        },
      }),
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode(_errorResponse('Failed to fetch bookings: $e')),
    );
  }
}

Response handleCreateBooking(String body) {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final serviceId = data['service_id'] as String?;
    final bookingTime = data['booking_time'] as String?;
    final doctorId = data['doctor_id'] as String? ?? 'dr_001';

    if (serviceId == null ||
        serviceId.isEmpty ||
        bookingTime == null ||
        bookingTime.isEmpty) {
      return Response.badRequest(
        body: jsonEncode(
          _errorResponse('service_id and booking_time required'),
        ),
      );
    }

    // Double-booking check
    final existing = _bookings
        .where(
          (b) =>
              b['doctor_id'] == doctorId &&
              b['booking_time'] == bookingTime &&
              b['status'] != 'cancelled',
        )
        .toList();
    if (existing.isNotEmpty) {
      return Response(
        409,
        body: jsonEncode(
          _errorResponse('Doctor already booked for this time slot', code: 409),
        ),
      );
    }

    final newBooking = _createBooking(
      serviceId: serviceId,
      bookingTime: bookingTime,
      doctorId: doctorId,
    );
    _bookings.add(newBooking);

    // Queue email job
    _pendingSync.add({
      'id': _uuid.v4(),
      'booking_id': newBooking['id'],
      'type': 'email_confirmation',
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    return Response(
      201,
      body: jsonEncode({'message': 'Booking created', 'booking': newBooking}),
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode(_errorResponse('Create failed: $e')),
    );
  }
}

Response handleDeleteBooking(String id) {
  try {
    final bookingId = int.tryParse(id);
    if (bookingId == null)
      return Response.badRequest(
        body: jsonEncode(_errorResponse('Invalid ID')),
      );

    final index = _bookings.indexWhere((b) => b['id'] == bookingId);
    if (index == -1)
      return Response(
        404,
        body: jsonEncode(_errorResponse('Booking not found', code: 404)),
      );

    final booking = _bookings[index];
    if (booking['status'] == 'cancelled') {
      return Response.badRequest(
        body: jsonEncode(_errorResponse('Already cancelled')),
      );
    }
    booking['status'] = 'cancelled';
    _bookings[index] = booking;

    return Response.ok(
      jsonEncode({'message': 'Cancelled', 'booking': booking}),
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode(_errorResponse('Delete failed: $e')),
    );
  }
}

Response handlePendingSync() => Response.ok(
  jsonEncode({'pending_jobs': _pendingSync, 'count': _pendingSync.length}),
);

Response handleSeed() {
  _bookings.clear();
  _pendingSync.clear();
  _bookingIdCounter = 1;
  _currentToken = null;
  _tokenIssuedAt = null;
  _isTokenExpired = false;
  _seedBookings();
  return Response.ok(
    jsonEncode({
      'message': 'Seed complete',
      'bookings_count': _bookings.length,
    }),
  );
}

Response handleExpireToken() {
  _expireToken();
  return Response.ok(
    jsonEncode({'message': 'Token expired. Next request will return 401.'}),
  );
}

Response handleReset() {
  _bookings.clear();
  _pendingSync.clear();
  _bookingIdCounter = 1;
  _currentToken = null;
  _tokenIssuedAt = null;
  _isTokenExpired = false;
  _seedBookings();
  return Response.ok(
    jsonEncode({
      'message': 'Reset complete',
      'bookings_count': _bookings.length,
    }),
  );
}
