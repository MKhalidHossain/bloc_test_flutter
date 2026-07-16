import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {
  final int pending;
  const SyncIdle({this.pending = 0});
  @override
  List<Object?> get props => [pending];
}

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

class SyncConflictDetected extends SyncState {
  final String message;
  const SyncConflictDetected(this.message);
  @override
  List<Object?> get props => [message];
}

class SyncPausedBackoff extends SyncState {
  final String message;
  final int failures;
  const SyncPausedBackoff(this.message, this.failures);
  @override
  List<Object?> get props => [message, failures];
}

class SyncErrorRetrying extends SyncState {
  final String message;
  final int attempt;
  const SyncErrorRetrying(this.message, this.attempt);
  @override
  List<Object?> get props => [message, attempt];
}
