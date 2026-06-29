import 'package:bloc/bloc.dart';

import '../../domain/entity/booking.dart';
import '../../domain/usecase/cancel_booking_usecase.dart';
import '../../domain/usecase/create_booking_usecase.dart';
import '../../domain/usecase/get_bookings_usecase.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GetBookingsUsecase getBookings;
  final CreateBookingUsecase createBooking;
  final CancelBookingUsecase cancelBooking;
  final int pageSize;

  // Cached view of the current list so one-shot action states can re-render it.
  List<Booking> _items = [];
  String? _nextCursor;
  bool _hasMore = false;
  int _nonce = 0;

  BookingBloc({
    required this.getBookings,
    required this.createBooking,
    required this.cancelBooking,
    this.pageSize = 10,
  }) : super(const BookingInitial()) {
    on<LoadBookings>(_onLoad);
    on<LoadMoreBookings>(_onLoadMore);
    on<CreateBookingRequested>(_onCreate);
    on<CancelBookingRequested>(_onCancel);
  }

  int get _nextNonce => ++_nonce;

  Future<void> _onLoad(LoadBookings event, Emitter<BookingState> emit) async {
    emit(const BookingLoading());
    final result = await getBookings(GetBookingsParams(limit: pageSize));
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (page) {
        _items = page.items;
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        emit(BookingLoaded(items: _items, hasMore: _hasMore));
      },
    );
  }

  Future<void> _onLoadMore(
    LoadMoreBookings event,
    Emitter<BookingState> emit,
  ) async {
    if (!_hasMore) return;
    final current = state;
    if (current is BookingLoaded && current.isLoadingMore) return;

    emit(BookingLoaded(items: _items, hasMore: _hasMore, isLoadingMore: true));
    final result =
        await getBookings(GetBookingsParams(cursor: _nextCursor, limit: pageSize));
    result.fold(
      (failure) {
        emit(BookingLoaded(items: _items, hasMore: _hasMore));
        emit(BookingActionFailure(failure.message, _nextNonce));
      },
      (page) {
        final existing = _items.map((b) => b.serverId).toSet();
        final fresh =
            page.items.where((b) => !existing.contains(b.serverId)).toList();
        _items = [..._items, ...fresh];
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        emit(BookingLoaded(items: _items, hasMore: _hasMore));
      },
    );
  }

  Future<void> _onCreate(
    CreateBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    final result = await createBooking(CreateBookingParams(
      serviceId: event.serviceId,
      bookingTime: event.bookingTime,
      doctorId: event.doctorId,
    ));
    await result.fold(
      (failure) async => emit(BookingActionFailure(failure.message, _nextNonce)),
      (booking) async {
        emit(BookingActionSuccess(
          booking.isPending
              ? 'Booking queued — will sync when online.'
              : 'Booking ${booking.displayId} created.',
          _nextNonce,
        ));
        add(const LoadBookings());
      },
    );
  }

  Future<void> _onCancel(
    CancelBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    final result = await cancelBooking(event.booking);
    await result.fold(
      (failure) async => emit(BookingActionFailure(failure.message, _nextNonce)),
      (_) async {
        emit(BookingActionSuccess('Booking cancelled.', _nextNonce));
        add(const LoadBookings());
      },
    );
  }
}
