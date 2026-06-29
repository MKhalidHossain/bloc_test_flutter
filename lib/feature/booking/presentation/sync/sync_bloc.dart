import 'dart:convert';

import 'package:bloc/bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/email_confirmation_service.dart';
import '../../data/datasource/booking_local_data_source.dart';
import '../../data/datasource/booking_remote_data_source.dart';
import '../../data/models/booking_model.dart';
import 'sync_event.dart';
import 'sync_state.dart';

enum _OpResult { success, conflict, failure }

/// The Sync Engine (Task 8): the single source of truth for sync state.
///
/// Drains the `pending_operations` queue FIFO. Per operation it retries a few
/// times with exponential backoff; after [maxConsecutiveFailures] operations
/// fail in a row it pauses (Paused_Backoff) until the next trigger.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final BookingLocalDataSource localDataSource;
  final BookingRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;
  final EmailConfirmationService emailService;

  final int maxRetriesPerOp;
  final int maxConsecutiveFailures;
  final Duration retryBaseDelay;

  bool _isSyncing = false;

  SyncBloc({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
    required this.emailService,
    this.maxRetriesPerOp = 2,
    this.maxConsecutiveFailures = 3,
    this.retryBaseDelay = const Duration(milliseconds: 400),
  }) : super(const SyncIdle()) {
    on<SyncRequested>(_onSyncRequested);
    on<SyncConnectivityChanged>(_onConnectivityChanged);
  }

  Future<void> _onConnectivityChanged(
    SyncConnectivityChanged event,
    Emitter<SyncState> emit,
  ) async {
    // Task 7 — automatically sync when connectivity is restored.
    if (event.isOnline) {
      await _drainQueue(emit);
    }
  }

  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    await _drainQueue(emit);
  }

  Future<void> _drainQueue(Emitter<SyncState> emit) async {
    if (_isSyncing) return; // guard against overlapping runs
    _isSyncing = true;
    try {
      if (!await connectivityService.isOnline) {
        emit(SyncIdle(pending: await localDataSource.pendingOperationCount()));
        return;
      }

      final ops = await localDataSource.getPendingOperations();
      if (ops.isEmpty) {
        emit(const SyncIdle());
        return;
      }

      var consecutiveFailures = 0;
      var processed = 0;
      final total = ops.length;

      for (final op in ops) {
        final label = _describe(op);
        emit(SyncSyncing(
          currentOperation: label,
          processed: processed,
          total: total,
        ));

        final result = await _processWithRetry(op, label, emit);
        switch (result) {
          case _OpResult.success:
          case _OpResult.conflict:
            consecutiveFailures = 0;
            processed++;
            break;
          case _OpResult.failure:
            consecutiveFailures++;
            if (consecutiveFailures >= maxConsecutiveFailures) {
              emit(SyncPausedBackoff(
                'Sync paused after $consecutiveFailures consecutive failures. '
                'Will retry when connectivity is restored.',
                consecutiveFailures,
              ));
              return;
            }
            break;
        }
      }

      emit(SyncIdle(pending: await localDataSource.pendingOperationCount()));
    } finally {
      _isSyncing = false;
    }
  }

  /// Attempts one operation up to [maxRetriesPerOp] extra times with backoff.
  Future<_OpResult> _processWithRetry(
    PendingOperation op,
    String label,
    Emitter<SyncState> emit,
  ) async {
    for (var attempt = 0; attempt <= maxRetriesPerOp; attempt++) {
      try {
        return await _processOnce(op, emit);
      } on DoubleBookingException catch (e) {
        // 409 — server rejects the create. Drop the optimistic row + op.
        await localDataSource.deleteByLocalUuid(op.localUuid);
        await localDataSource.deleteOperation(op.id);
        emit(SyncConflictDetected('Conflict on $label: ${e.message}'));
        return _OpResult.conflict;
      } on NotFoundException {
        // 404 — already deleted on the server. Ignore and drop the op.
        await localDataSource.deleteOperation(op.id);
        emit(SyncConflictDetected(
          '$label already removed on server — skipping.',
        ));
        return _OpResult.conflict;
      } on ServerException catch (e) {
        if (attempt >= maxRetriesPerOp) return _OpResult.failure;
        emit(SyncErrorRetrying(
          'Failed $label: ${e.message}. Retrying…',
          attempt + 1,
        ));
        await Future.delayed(retryBaseDelay * (1 << attempt)); // 1x, 2x, 4x…
      }
    }
    return _OpResult.failure;
  }

  Future<_OpResult> _processOnce(
    PendingOperation op,
    Emitter<SyncState> emit,
  ) async {
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;
    if (op.operationType == 'create') {
      final created = await remoteDataSource.createBooking(
        CreateBookingRequest(
          serviceId: payload['service_id'] as String,
          bookingTime: payload['booking_time'] as String,
          doctorId: payload['doctor_id'] as String,
        ),
      );
      await localDataSource.markSynced(op.localUuid, created);
      await localDataSource.deleteOperation(op.id);
      // Task 5 — email confirmation on a successfully synced create.
      emailService.dispatch('#${created.id}');
      return _OpResult.success;
    } else {
      final serverId = payload['server_id'] as int;
      await remoteDataSource.deleteBooking(serverId);
      await localDataSource.markCancelledByServerId(serverId);
      await localDataSource.deleteOperation(op.id);
      return _OpResult.success;
    }
  }

  String _describe(PendingOperation op) {
    if (op.operationType == 'create') {
      return 'Submitting Booking #${op.localUuid.substring(0, 6).toUpperCase()}…';
    }
    try {
      final serverId = (jsonDecode(op.payload) as Map<String, dynamic>)['server_id'];
      return 'Cancelling Booking #$serverId…';
    } catch (_) {
      return 'Cancelling Booking…';
    }
  }
}
