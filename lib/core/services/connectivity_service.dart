import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus exposing a simple online/offline
/// boolean and a de-duplicated stream of online/offline transitions.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Emits `true` when the device comes online and `false` when it goes offline.
  /// Only emits on actual transitions.
  Stream<bool> get onStatusChange {
    bool? last;
    return _connectivity.onConnectivityChanged
        .map(_hasConnection)
        .where((online) {
      if (online == last) return false;
      last = online;
      return true;
    });
  }
}
