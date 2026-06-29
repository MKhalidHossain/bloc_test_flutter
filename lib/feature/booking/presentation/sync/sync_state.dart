import 'package:equatable/equatable.dart';

/// Single source of truth for the Sync Engine state (Task 8).
abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

/// No sync in progress.
class SyncIdle extends SyncState {
  /// Number of operations still waiting in the queue.
  final int pending;
  const SyncIdle({this.pending = 0});
  @override
  List<Object?> get props => [pending];
}

/// Currently processing pending operations. [currentOperation] is a
/// human-readable label such as "Submitting Booking #A1B2C3...".
class SyncSyncing extends SyncState {
  final String currentOperation;
  final int processed;
  final int total;
  const SyncSyncing({
    required this.currentOperation,
    required this.processed,
    required this.total,
  });
  @override
  List<Object?> get props => [currentOperation, processed, total];
}

/// A conflict (e.g. 409 double-booking, or 404 already-deleted) was found and
/// resolved during sync.
class SyncConflictDetected extends SyncState {
  final String message;
  const SyncConflictDetected(this.message);
  @override
  List<Object?> get props => [message];
}

/// Sync paused after too many consecutive failures.
class SyncPausedBackoff extends SyncState {
  final String message;
  final int failures;
  const SyncPausedBackoff(this.message, this.failures);
  @override
  List<Object?> get props => [message, failures];
}

/// An operation failed; the engine is waiting before retrying it.
class SyncErrorRetrying extends SyncState {
  final String message;
  final int attempt;
  const SyncErrorRetrying(this.message, this.attempt);
  @override
  List<Object?> get props => [message, attempt];
}
