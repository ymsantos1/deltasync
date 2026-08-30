import 'package:deltasync_core/deltasync_core.dart';

/// Adapter for pending delta persistence. Implement with SQLite, files, etc.
abstract interface class PendingDeltaStore {
  Future<Delta> read(String replicaId);

  Future<void> write(String replicaId, Delta delta);
}

/// Volatile in-memory adapter useful for tests and examples.
///
/// Data is lost when the process ends. This legacy adapter is not suitable for
/// persistence or recovery after restart.
class MemoryPendingDeltaStore implements PendingDeltaStore {
  final Map<String, Delta> _data = {};

  @override
  Future<Delta> read(String replicaId) async =>
      _data[replicaId] ?? const Delta.empty();

  @override
  Future<void> write(String replicaId, Delta delta) async {
    _data[replicaId] = delta;
  }
}
