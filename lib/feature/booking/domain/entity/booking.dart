import 'package:equatable/equatable.dart';

/// A booking as understood by the domain & presentation layers.
///
/// [serverId] is null while a booking only exists locally (created offline and
/// not yet synced). [isPending] reflects whether a queued operation still needs
/// to be processed for this booking.
class Booking extends Equatable {
  final int? serverId;
  final String serviceId;
  final String bookingTime;
  final String doctorId;
  final String status;
  final String createdAt;
  final bool isPending;
  final String? localUuid;

  const Booking({
    this.serverId,
    required this.serviceId,
    required this.bookingTime,
    required this.doctorId,
    required this.status,
    required this.createdAt,
    this.isPending = false,
    this.localUuid,
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  /// A stable identifier for the UI ("#42" for synced, "#A123" style for
  /// pending creates that don't have a server id yet).
  String get displayId =>
      serverId != null ? '#$serverId' : '#${localUuid?.substring(0, 6) ?? '?'}';

  @override
  List<Object?> get props =>
      [serverId, serviceId, bookingTime, doctorId, status, createdAt, isPending, localUuid];
}

/// A page of bookings returned by cursor-based pagination.
class BookingPage extends Equatable {
  final List<Booking> items;
  final String? nextCursor;
  final bool hasMore;

  const BookingPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [items, nextCursor, hasMore];
}
