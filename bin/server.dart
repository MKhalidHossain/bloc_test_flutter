import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'handlers.dart';

void main() async {
  final app = Router();

  // Welcome
  app.get('/', (Request request) => handleWelcome());

  // Auth
  app.post('/auth/login', (Request request) async {
    final body = await request.readAsString();
    return handleLogin(body);
  });

  app.post('/auth/refresh', (Request request) async {
    final body = await request.readAsString();
    return handleRefresh(body);
  });

  app.post('/auth/logout', (Request request) => handleLogout());

  // Bookings (protected)
  app.get('/bookings', (Request request) => handleGetBookings(request));

  app.post('/bookings', (Request request) async {
    final body = await request.readAsString();
    return handleCreateBooking(body);
  });

  app.delete(
    '/bookings/<id>',
    (Request request, String id) => handleDeleteBooking(id),
  );

  // Admin
  app.get('/admin/seed', (Request request) => handleSeed());

  app.get('/admin/expire-token', (Request request) => handleExpireToken());

  app.get('/admin/reset', (Request request) => handleReset());

  // Pending sync (testing)
  app.get('/pending-sync', (Request request) => handlePendingSync());

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addMiddleware(_jsonContentType())
      .addHandler(app);

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('Mock API server running at http://localhost:$port');
}

/// All handlers return `jsonEncode(...)` bodies, but `Response.ok(String)`
/// defaults to `content-type: text/plain`. Dio only decodes a response into a
/// Map when the content-type is a JSON mime type, so without this the client
/// receives a raw String and every request fails with a cast error. Stamp the
/// correct content-type on every JSON response.
Middleware _jsonContentType() => (innerHandler) => (request) async {
      final response = await innerHandler(request);
      // Leave non-JSON bodies (if any) untouched.
      final existing = response.headers['content-type'];
      if (existing != null && !existing.contains('text/plain')) {
        return response;
      }
      return response.change(
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    };
