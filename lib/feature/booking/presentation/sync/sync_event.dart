import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class SyncRequested extends SyncEvent {
  const SyncRequested();
}

class SyncConnectivityChanged extends SyncEvent {
  final bool isOnline;
  const SyncConnectivityChanged(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}
