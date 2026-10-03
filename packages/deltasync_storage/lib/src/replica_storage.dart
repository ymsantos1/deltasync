import 'package:deltasync_core/deltasync_core.dart';

/// Materialized state and metadata required to restore one replica.
class ReplicaSnapshot {
  ReplicaSnapshot({
    required this.replicaId,
    required Map<String, Object?> state,
    required this.clock,
    this.version = 1,
    Map<String, Object?> metadata = const {},
  }) : state = Map.unmodifiable(state),
       metadata = Map.unmodifiable(metadata);

  final String replicaId;
  final int version;
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
    this.sentAt,
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
  final DateTime? sentAt;

  List<String> get changeIds => [
    ...delta!.changes.map((change) => change.id),
    ...delta!.crdtChanges.map((change) => change.id),
  ];

  /// Legacy singular alias. New code should use [changeIds].
  String get operationId => changeIds.first;

  String get entryId => changeIds.join('|');

  String get replicaId {
    final origins = <String>{
      if (operation != null) operation!.replicaId,
      ...delta!.changes.map((change) => change.replicaId),
      ...delta!.crdtChanges.map(_originOf),
    };
    if (origins.length != 1) {
      throw StateError('Outbox entry must contain changes from one replica');
    }
    return origins.single;
  }

  static String _originOf(DeltaChange change) => switch (change) {
    LwwDelta<Object?>() => change.replicaId,
    GCounterDelta() => change.replicaId,
    PnCounterDelta() => change.replicaId,
    _ => throw StateError('Cannot determine delta replica ID'),
  };
}

/// Domain-oriented persistence contract. Implementations may use any backend.
abstract interface class ReplicaStorage {
  Future<ReplicaSnapshot?> loadReplica(String replicaId);

  /// Atomically persists materialized replica state and its new outbox entries.
  /// Implementations must expose either all changes or none after failure.
  Future<void> commit(ReplicaSnapshot snapshot, Iterable<OutboxEntry> entries);

  /// Atomically replaces materialized state after a remote merge.
  Future<void> commitRemote(ReplicaSnapshot snapshot);

  Future<void> saveReplica(ReplicaSnapshot snapshot);

  Future<void> enqueue(OutboxEntry entry);

  Future<List<OutboxEntry>> pending(String replicaId);

  /// Marks entries sent without removing them, allowing retry before ACK.
  Future<void> markSent(
    String replicaId,
    Iterable<String> operationIds,
  ) async {}

  /// Confirms only [operationIds] in this replica's outbox.
  ///
  /// If an entry contains multiple changes, unacknowledged changes remain
  /// pending as a smaller entry. Implementations must not discard them.
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
  Future<void> commitRemote(ReplicaSnapshot snapshot) async {
    _snapshots[snapshot.replicaId] = snapshot;
  }

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    if (entries.any((entry) => entry.replicaId != snapshot.replicaId)) {
      throw ArgumentError('Commit entries must belong to snapshot replica');
    }
    final nextOutbox = Map<String, OutboxEntry>.of(
      _outbox[snapshot.replicaId] ?? const {},
    );
    for (final entry in entries) {
      nextOutbox.putIfAbsent(entry.entryId, () => entry);
    }
    _snapshots[snapshot.replicaId] = snapshot;
    _outbox[snapshot.replicaId] = nextOutbox;
  }

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    final replicaId = entry.replicaId;
    final entries = _outbox.putIfAbsent(replicaId, () => {});
    entries.putIfAbsent(entry.entryId, () => entry);
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
    final ids = operationIds.toSet();
    for (final entryKey in entries.keys.toList()) {
      final entry = entries[entryKey]!;
      if (!entry.changeIds.any(ids.contains)) continue;

      final remainder = _excluding(entry.delta!, ids);
      entries.remove(entryKey);
      if (!remainder.isEmpty) {
        final pendingEntry = OutboxEntry(
          delta: remainder,
          status: entry.status,
          attempts: entry.attempts,
          createdAt: entry.createdAt,
          sentAt: entry.sentAt,
        );
        entries[pendingEntry.entryId] = pendingEntry;
      }
    }
  }

  @override
  Future<void> markSent(String replicaId, Iterable<String> operationIds) async {
    final entries = _outbox[replicaId];
    if (entries == null) return;
    final ids = operationIds.toSet();
    for (final entryKey in entries.keys.toList()) {
      final entry = entries[entryKey]!;
      if (!entry.changeIds.any(ids.contains)) continue;
      entries[entryKey] = OutboxEntry(
        operation: entry.operation,
        delta: entry.delta,
        status: OutboxStatus.sent,
        attempts: entry.attempts + 1,
        createdAt: entry.createdAt,
        sentAt: DateTime.now().toUtc(),
      );
    }
  }
}

Delta _excluding(Delta delta, Set<String> acknowledgedIds) {
  final operations = delta.changes.where(
    (change) => !acknowledgedIds.contains(change.id),
  );
  final crdtChanges = delta.crdtChanges.where(
    (change) => !acknowledgedIds.contains(change.id),
  );
  return Delta(operations).merge(Delta.crdt(crdtChanges));
}
