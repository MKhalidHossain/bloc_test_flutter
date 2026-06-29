import 'package:equatable/equatable.dart';

import '../../domain/entity/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingLoaded extends BookingState {
  final List<Booking> items;
  final bool hasMore;
  final bool isLoadingMore;

  const BookingLoaded({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  BookingLoaded copyWith({
    List<Booking>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      BookingLoaded(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [items, hasMore, isLoadingMore];
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
  @override
  List<Object?> get props => [message];
}

/// One-shot states consumed by a BlocListener (snackbars). Carry a [nonce] so
/// two identical messages still emit distinctly.
class BookingActionSuccess extends BookingState {
  final String message;
  final int nonce;
  const BookingActionSuccess(this.message, this.nonce);
  @override
  List<Object?> get props => [message, nonce];
}

class BookingActionFailure extends BookingState {
  final String message;
  final int nonce;
  const BookingActionFailure(this.message, this.nonce);
  @override
  List<Object?> get props => [message, nonce];
}
