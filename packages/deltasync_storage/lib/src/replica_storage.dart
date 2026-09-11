import 'package:deltasync_core/deltasync_core.dart';

/// Materialized state and metadata required to restore one replica.
class ReplicaSnapshot {
  ReplicaSnapshot({
    required this.replicaId,
    required Map<String, Object?> state,
    required this.clock,
    Map<String, Object?> metadata = const {},
  }) : state = Map.unmodifiable(state),
       metadata = Map.unmodifiable(metadata);

  final String replicaId;
  final Map<String, Object?> state;
  final VectorClock clock;
  final Map<String, Object?> metadata;
}

enum OutboxStatus { pending, sent, confirmed }

/// Durable local operation waiting for transport confirmation.
class OutboxEntry {
  OutboxEntry({
    Operation? operation,
    Delta? delta,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    DateTime? createdAt,
  }) : operation = operation,
       delta = delta ?? (operation == null ? null : Delta([operation])),
       createdAt = createdAt ?? DateTime.now().toUtc() {
    if (this.delta == null || this.delta!.isEmpty) {
      throw ArgumentError('non-empty operation or delta is required');
    }
  }

  final Operation? operation;
  final Delta? delta;
  final OutboxStatus status;
  final int attempts;
  final DateTime createdAt;

  String get operationId => delta!.changes.isNotEmpty
      ? delta!.changes.first.id
      : delta!.crdtChanges.first.id;

  String get replicaId => operation?.replicaId ?? _deltaReplicaId;

  String get _deltaReplicaId {
    final change = delta!.crdtChanges.first;
    if (change is LwwDelta<Object?>) return change.replicaId;
    throw StateError('Cannot determine delta replica ID');
  }
}

/// Domain-oriented persistence contract. Implementations may use any backend.
abstract interface class ReplicaStorage {
  Future<ReplicaSnapshot?> loadReplica(String replicaId);

  Future<void> saveReplica(ReplicaSnapshot snapshot);

  Future<void> enqueue(OutboxEntry entry);

  Future<List<OutboxEntry>> pending(String replicaId);

  Future<void> acknowledge(String replicaId, Iterable<String> operationIds);
}

/// Volatile in-memory implementation for tests, examples and prototypes.
///
/// Data is lost when the process ends. Applications requiring recovery after
/// restart must provide a persistent [ReplicaStorage] adapter.
class MemoryStorage implements ReplicaStorage {
  final Map<String, ReplicaSnapshot> _snapshots = {};
  final Map<String, Map<String, OutboxEntry>> _outbox = {};

  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) async =>
      _snapshots[replicaId];

  @override
  Future<void> saveReplica(ReplicaSnapshot snapshot) async {
    _snapshots[snapshot.replicaId] = snapshot;
  }

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    final replicaId = entry.replicaId;
    final entries = _outbox.putIfAbsent(replicaId, () => {});
    entries.putIfAbsent(entry.operationId, () => entry);
  }

  @override
  Future<List<OutboxEntry>> pending(String replicaId) async => [
    ...(_outbox[replicaId]?.values ?? const <OutboxEntry>[]).where(
      (entry) => entry.status != OutboxStatus.confirmed,
    ),
  ];

  @override
  Future<void> acknowledge(
    String replicaId,
    Iterable<String> operationIds,
  ) async {
    final entries = _outbox[replicaId];
    if (entries == null) return;
    for (final operationId in operationIds) {
      entries.remove(operationId);
    }
  }
}
