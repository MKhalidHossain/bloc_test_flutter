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

  // All handlers return JSON bodies; declare it so clients (Dio) decode them.
  final jsonContentType = createMiddleware(
    responseHandler: (response) =>
        response.change(headers: {'content-type': 'application/json'}),
  );

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addMiddleware(jsonContentType)
      .addHandler(app);

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('Mock API server running at http://localhost:$port');
}
