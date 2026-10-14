import 'dart:async';

/// Internal serial boundary for durable commits and outbox updates. Network I/O
/// must stay outside run; failed actions cannot poison later commits.
class SerialCommitQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<void> get drained => _tail;
}
