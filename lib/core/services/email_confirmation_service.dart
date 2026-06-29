import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

/// Task 5 — mock email-confirmation queue.
///
/// When a booking is successfully created (online or synced from offline) a job
/// is dispatched here. Jobs are processed strictly one at a time (a single
/// worker draining a FIFO queue) so we never overwhelm the "mail server".
class EmailConfirmationService {
  EmailConfirmationService({this.sendDelay = const Duration(seconds: 1)});

  /// How long the simulated send takes.
  final Duration sendDelay;

  final Queue<String> _queue = Queue<String>();
  bool _processing = false;
  String? _current; // the job currently being sent

  /// Booking ids still waiting to be (or being) processed — handy for testing.
  List<String> get pendingJobs =>
      List.unmodifiable([if (_current != null) _current!, ..._queue]);

  /// Completes once the queue has fully drained. Mainly for tests.
  Completer<void>? _idleCompleter;
  Future<void> get onIdle =>
      _processing ? (_idleCompleter ??= Completer<void>()).future : Future.value();

  /// Enqueue a confirmation email for a booking and kick the worker.
  void dispatch(String bookingId) {
    _queue.add(bookingId);
    _drain();
  }

  Future<void> _drain() async {
    if (_processing) return;
    _processing = true;
    try {
      while (_queue.isNotEmpty) {
        _current = _queue.removeFirst();
        await _send(_current!);
        _current = null;
      }
    } finally {
      _processing = false;
      _idleCompleter?.complete();
      _idleCompleter = null;
    }
  }

  Future<void> _send(String bookingId) async {
    developer.log('📧 Sending confirmation email for booking $bookingId...',
        name: 'EmailConfirmation');
    await Future.delayed(sendDelay);
    developer.log('✅ Confirmation email sent for booking $bookingId',
        name: 'EmailConfirmation');
  }
}
