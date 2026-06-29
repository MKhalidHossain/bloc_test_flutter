import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entity/booking.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../sync/sync_bloc.dart';
import '../sync/sync_event.dart';
import '../sync/sync_state.dart';
import '../widgets/sync_status_banner.dart';
import 'create_booking_sheet.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final _scrollController = ScrollController();
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<BookingBloc>().add(const LoadBookings());

    // Task 7 — detect connectivity changes and auto-sync on reconnect.
    final connectivity = context.read<ConnectivityService>();
    final syncBloc = context.read<SyncBloc>();
    _connectivitySub = connectivity.onStatusChange.listen((online) {
      syncBloc.add(SyncConnectivityChanged(online));
    });
    // Kick an initial sync in case the queue already has work.
    syncBloc.add(const SyncRequested());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BookingBloc>().add(const LoadMoreBookings());
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateBookingSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          // When the sync engine finishes work, refresh the list.
          BlocListener<SyncBloc, SyncState>(
            listenWhen: (prev, curr) =>
                (curr is SyncIdle && prev is! SyncIdle) ||
                curr is SyncConflictDetected,
            listener: (context, _) =>
                context.read<BookingBloc>().add(const LoadBookings()),
            child: const SizedBox.shrink(),
          ),
          Expanded(
            child: BlocConsumer<BookingBloc, BookingState>(
              listenWhen: (_, curr) =>
                  curr is BookingActionSuccess || curr is BookingActionFailure,
              listener: (context, state) {
                final messenger = ScaffoldMessenger.of(context);
                if (state is BookingActionFailure) {
                  messenger.showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red.shade700,
                  ));
                } else if (state is BookingActionSuccess) {
                  messenger.showSnackBar(
                      SnackBar(content: Text(state.message)));
                }
              },
              buildWhen: (_, curr) =>
                  curr is BookingLoading ||
                  curr is BookingLoaded ||
                  curr is BookingError,
              builder: (context, state) {
                if (state is BookingLoading || state is BookingInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is BookingError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<BookingBloc>().add(const LoadBookings()),
                  );
                }
                final loaded = state as BookingLoaded;
                if (loaded.items.isEmpty) {
                  return const _EmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<BookingBloc>().add(const LoadBookings());
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: loaded.items.length + (loaded.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= loaded.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _BookingTile(booking: loaded.items[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.tryParse(booking.bookingTime);
    final timeLabel = time != null
        ? DateFormat('EEE, d MMM yyyy • HH:mm').format(time)
        : booking.bookingTime;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: booking.isCancelled
            ? Colors.grey
            : booking.isPending
                ? Colors.orange
                : Colors.green,
        child: Icon(
          booking.isPending ? Icons.cloud_upload : Icons.event,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text('Booking ${booking.displayId} · ${booking.doctorId}'),
      subtitle: Text('$timeLabel\nService: ${booking.serviceId} · ${booking.status}'),
      isThreeLine: true,
      trailing: booking.isCancelled
          ? const Text('cancelled')
          : IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel',
              onPressed: () => context
                  .read<BookingBloc>()
                  .add(CancelBookingRequested(booking)),
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.event_busy, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Center(child: Text('No bookings yet. Tap "Book" to create one.')),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
