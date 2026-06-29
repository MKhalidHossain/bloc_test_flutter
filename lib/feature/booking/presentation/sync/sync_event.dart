import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

/// Process the pending-operations queue now (FIFO).
class SyncRequested extends SyncEvent {
  const SyncRequested();
}

/// Connectivity changed; when it comes back online we trigger a sync.
class SyncConnectivityChanged extends SyncEvent {
  final bool isOnline;
  const SyncConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}
