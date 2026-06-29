/// Data-layer exceptions. These are translated into [Failure]s (online path)
/// or interpreted by the sync engine (queue path).
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => 'ServerException: $message';
}

/// Thrown when the server rejects a create with 409 (doctor/time already booked).
class DoubleBookingException implements Exception {
  final String message;
  DoubleBookingException(this.message);
  @override
  String toString() => 'DoubleBookingException: $message';
}

/// Thrown when the server returns 404 (e.g. deleting an already-deleted booking).
class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => 'NotFoundException: $message';
}
