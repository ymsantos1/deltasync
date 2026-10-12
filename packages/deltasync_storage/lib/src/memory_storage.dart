part of 'replica_storage.dart';

/// Volatile in-memory implementation for tests, examples and prototypes.
///
/// Data is lost when the process ends. Applications requiring recovery after
/// restart must provide a persistent [ReplicaStorage] adapter.
class MemoryStorage implements ReplicaStorage {
  final Map<String, ReplicaSnapshot> _snapshots = {};
  final Map<String, Map<(String, String), OutboxEntry>> _outbox = {};

  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) async =>
      _snapshots[replicaId];

  @override
  Future<void> saveReplica(ReplicaSnapshot snapshot) async {
    _validateSnapshot(snapshot);
    _snapshots[snapshot.replicaId] = snapshot;
  }

  @override
  Future<void> commitRemote(ReplicaSnapshot snapshot) async {
    _validateSnapshot(snapshot);
    _snapshots[snapshot.replicaId] = snapshot;
  }

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    _validateSnapshot(snapshot);
    final additions = List<OutboxEntry>.of(entries);
    if (additions.any((entry) => entry.replicaId != snapshot.replicaId)) {
      throw ArgumentError('Commit entries must belong to snapshot replica');
    }
    final nextOutbox = Map<(String, String), OutboxEntry>.of(
      _outbox[snapshot.replicaId] ?? const {},
    );
    for (final entry in additions) {
      final existing = nextOutbox[_outboxKey(entry)];
      if (existing == null) {
        nextOutbox[_outboxKey(entry)] = entry;
      } else {
        Delta(existing.delta.changes).merge(entry.delta);
      }
    }
    _snapshots[snapshot.replicaId] = snapshot;
    _outbox[snapshot.replicaId] = nextOutbox;
  }

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    final replicaId = entry.replicaId;
    final entries = _outbox[replicaId];
    final key = _outboxKey(entry);
    final existing = entries?[key];
    if (existing != null) {
      Delta(existing.delta.changes).merge(entry.delta);
    } else {
      _outbox.putIfAbsent(replicaId, () => {})[key] = entry;
    }
  }

  @override
  Future<List<OutboxEntry>> pending(
    String replicaId, {
    String? recipientPeerId,
  }) async {
    final entries = _outbox[replicaId];
    if (entries == null) return [];
    entries.removeWhere((_, entry) => entry.status == OutboxStatus.confirmed);
    return [
      ...entries.values.where(
        (entry) =>
            recipientPeerId == null || entry.recipientPeerId == recipientPeerId,
      ),
    ];
  }

  @override
  Future<void> acknowledge(
    String replicaId,
    String recipientPeerId,
    Iterable<String> operationIds,
  ) async {
    final entries = _outbox[replicaId];
    if (entries == null) return;
    final ids = operationIds.toSet();
    entries.removeWhere(
      (_, entry) =>
          entry.recipientPeerId == recipientPeerId &&
          ids.contains(entry.entryId),
    );
  }

  @override
  Future<void> markSent(
    String replicaId,
    String recipientPeerId,
    Iterable<String> operationIds,
  ) async {
    final entries = _outbox[replicaId];
    if (entries == null) return;
    final ids = operationIds.toSet();
    for (final entryKey in entries.keys.toList()) {
      final entry = entries[entryKey]!;
      if (entry.recipientPeerId != recipientPeerId ||
          !entry.changeIds.any(ids.contains)) {
        continue;
      }
      entries[entryKey] = OutboxEntry(
        delta: entry.delta,
        recipientPeerId: entry.recipientPeerId,
        status: OutboxStatus.sent,
        attempts: entry.attempts + 1,
        createdAt: entry.createdAt,
        sentAt: DateTime.now().toUtc(),
      );
    }
  }
}

(String, String) _outboxKey(OutboxEntry entry) =>
    (entry.recipientPeerId, entry.entryId);

void _validateSnapshot(ReplicaSnapshot snapshot) {
  if (snapshot.replicaId.isEmpty ||
      snapshot.replicaId.trim() != snapshot.replicaId) {
    throw ArgumentError('Invalid snapshot replica ID');
  }
  if (snapshot.version == 2) {
    final data = snapshot.snapshot;
    if (data == null || data['replicaId'] != snapshot.replicaId) {
      throw ArgumentError('Invalid canonical replica snapshot');
    }
  } else if (snapshot.version != 1 || snapshot.legacyClock == null) {
    throw ArgumentError('Unsupported replica snapshot version');
  }
}
