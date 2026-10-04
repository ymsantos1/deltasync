// ignore_for_file: deprecated_member_use

import 'package:deltasync_core/deltasync_core.dart';

/// Materialized state and metadata required to restore one replica.
class ReplicaSnapshot {
  factory ReplicaSnapshot.fromReplica(Replica replica) =>
      ReplicaSnapshot._trusted(replica.id, replica.toSnapshotJson());

  ReplicaSnapshot({
    required this.replicaId,
    required Map<String, Object?> snapshot,
  }) : version = 2,
       snapshot = _canonicalSnapshot(replicaId, snapshot),
       legacyState = null,
       legacyClock = null,
       legacyMetadata = null;

  ReplicaSnapshot._trusted(this.replicaId, this.snapshot)
    : version = 2,
      legacyState = null,
      legacyClock = null,
      legacyMetadata = null;

  /// Reads snapshots written before the canonical versioned payload.
  @Deprecated('Use the canonical snapshot constructor.')
  ReplicaSnapshot.legacy({
    required this.replicaId,
    required Map<String, Object?> state,
    required VectorClock clock,
    Map<String, Object?> metadata = const {},
  }) : version = 1,
       snapshot = null,
       legacyState = copyJsonValue(state, freeze: true) as Map<String, Object?>,
       legacyClock = clock,
       legacyMetadata =
           copyJsonValue(metadata, freeze: true) as Map<String, Object?>;

  final String replicaId;
  final int version;
  final Map<String, Object?>? snapshot;
  final Map<String, Object?>? legacyState;
  final VectorClock? legacyClock;
  final Map<String, Object?>? legacyMetadata;

  /// Encodes only the current, canonical storage format.
  Map<String, Object?> toJson() {
    final data = snapshot;
    if (version != 2 || data == null) {
      throw StateError('Migrate legacy snapshot before writing it');
    }
    return {'version': 2, 'replicaId': replicaId, 'snapshot': data};
  }

  /// Reads canonical v2 or legacy v1 snapshots with explicit validation.
  factory ReplicaSnapshot.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final replicaId = json['replicaId'];
    if (replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId) {
      throw FormatException('Invalid snapshot replica ID');
    }
    if (version == 2) {
      final encoded = json['snapshot'];
      if (encoded is! Map) throw FormatException('Missing replica snapshot');
      try {
        return ReplicaSnapshot(
          replicaId: replicaId,
          snapshot: Map<String, Object?>.from(encoded),
        );
      } on ArgumentError {
        throw FormatException('Invalid canonical replica snapshot');
      }
    }
    if (version == 1) {
      final state = json['state'];
      final clock = json['clock'];
      final metadata = json['metadata'] ?? const <String, Object?>{};
      if (state is! Map || clock is! Map || metadata is! Map) {
        throw FormatException('Invalid legacy replica snapshot');
      }
      try {
        return ReplicaSnapshot.legacy(
          replicaId: replicaId,
          state: Map<String, Object?>.from(state),
          clock: VectorClock.fromJson(Map<String, Object?>.from(clock)),
          metadata: Map<String, Object?>.from(metadata),
        );
      } on TypeError {
        throw FormatException('Invalid legacy replica snapshot');
      } on ArgumentError {
        throw FormatException('Invalid legacy replica snapshot');
      }
    }
    throw FormatException('Unsupported storage snapshot version');
  }
}

Map<String, Object?> _canonicalSnapshot(
  String replicaId,
  Map<String, Object?> snapshot,
) {
  final copied = copyJsonValue(snapshot, freeze: true) as Map<String, Object?>;
  if (copied['replicaId'] != replicaId) {
    throw ArgumentError('Snapshot replica ID does not match its owner');
  }
  Replica.fromSnapshotJson(copied);
  return copied;
}

/// `sent` counts attempts including the current unconfirmed transmission.
/// `confirmed` is read for legacy stores; ACK normally removes the entry.
enum OutboxStatus {
  pending('pending'),
  sent('sent'),
  @Deprecated('ACK removes entries; retained only for legacy records.')
  confirmed('confirmed');

  const OutboxStatus(this.wireName);

  final String wireName;

  static OutboxStatus fromWire(String value) => switch (value) {
    'pending' => OutboxStatus.pending,
    'sent' => OutboxStatus.sent,
    'confirmed' => OutboxStatus.confirmed,
    _ => throw FormatException('Unknown outbox status'),
  };
}

/// Local operation waiting for confirmation from one stable peer.
class OutboxEntry {
  OutboxEntry({
    required Delta delta,
    required this.recipientPeerId,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    DateTime? createdAt,
    DateTime? sentAt,
  }) : _delta = Delta.fromJson(delta.toJson()),
       createdAt = (createdAt ?? DateTime.now()).toUtc(),
       sentAt = sentAt?.toUtc() {
    if (recipientPeerId.isEmpty || recipientPeerId.trim() != recipientPeerId) {
      throw ArgumentError.value(recipientPeerId, 'recipientPeerId');
    }
    if (delta.changes.length != 1) {
      throw ArgumentError('outbox entry must contain exactly one change');
    }
    if (attempts < 0) {
      throw ArgumentError.value(attempts, 'attempts');
    }
    if (status == OutboxStatus.pending && (attempts != 0 || sentAt != null)) {
      throw ArgumentError('Pending outbox entries cannot have send metadata');
    }
    if (status == OutboxStatus.sent && (attempts == 0 || sentAt == null)) {
      throw ArgumentError('Sent outbox entries require attempt metadata');
    }
  }

  final Delta _delta;
  final String recipientPeerId;
  Delta get delta => Delta.fromJson(_delta.toJson());
  final OutboxStatus status;
  final int attempts;
  final DateTime createdAt;
  final DateTime? sentAt;

  List<String> get changeIds => [_delta.changes.single.id];

  /// Legacy singular alias. New code should use [changeIds].
  @Deprecated('Use changeIds for native CRDT changes.')
  String get operationId => changeIds.first;

  String get entryId => _delta.changes.single.id;

  Map<String, Object?> toJson() => {
    'version': 2,
    'recipientPeerId': recipientPeerId,
    'delta': DeltaCodec.encode(_delta),
    'status': status.wireName,
    'attempts': attempts,
    'createdAt': createdAt.toIso8601String(),
    if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
  };

  /// Decodes current v2 entries. Legacy v1 entries require explicit peer binding
  /// because their original destination was not stored.
  factory OutboxEntry.fromJson(
    Map<String, Object?> json, {
    String? legacyRecipientPeerId,
  }) {
    final version = json['version'];
    final encodedPeer = json['recipientPeerId'];
    final recipientPeerId = version == 1 ? legacyRecipientPeerId : encodedPeer;
    final encodedDelta = json['delta'];
    final status = json['status'];
    final attempts = json['attempts'];
    final createdAt = json['createdAt'];
    final sentAt = json['sentAt'];
    if ((version != 1 && version != 2) ||
        recipientPeerId is! String ||
        recipientPeerId.isEmpty ||
        recipientPeerId.trim() != recipientPeerId ||
        encodedDelta is! Map ||
        status is! String ||
        attempts is! int ||
        createdAt is! String ||
        (sentAt != null && sentAt is! String)) {
      throw FormatException('Invalid outbox entry');
    }
    final parsedCreatedAt = DateTime.tryParse(createdAt);
    final parsedSentAt = sentAt == null
        ? null
        : DateTime.tryParse(sentAt as String);
    if (parsedCreatedAt == null || (sentAt != null && parsedSentAt == null)) {
      throw FormatException('Invalid outbox timestamps');
    }
    try {
      return OutboxEntry(
        delta: DeltaCodec.decode(Map<String, Object?>.from(encodedDelta)),
        recipientPeerId: recipientPeerId,
        status: OutboxStatus.fromWire(status),
        attempts: attempts,
        createdAt: parsedCreatedAt,
        sentAt: parsedSentAt,
      );
    } on ArgumentError {
      throw FormatException('Invalid outbox entry');
    } on TypeError {
      throw FormatException('Invalid outbox entry');
    }
  }

  String get replicaId {
    return _delta.changes.single.replicaId;
  }
}

/// Domain-oriented persistence contract. Implementations may use any backend.
abstract interface class ReplicaStorage {
  Future<ReplicaSnapshot?> loadReplica(String replicaId);

  /// Atomically persists materialized replica state and its new outbox entries.
  /// Implementations must expose either all changes or none after failure.
  Future<void> commit(ReplicaSnapshot snapshot, Iterable<OutboxEntry> entries);

  /// Atomically replaces materialized state after a remote merge.
  Future<void> commitRemote(ReplicaSnapshot snapshot);

  /// Saves initial/bootstrap state without adding local pending changes.
  /// Local edits must use atomic [commit].
  Future<void> saveReplica(ReplicaSnapshot snapshot);

  /// Imports one pending change outside a local mutation transaction.
  /// Normal edits must use atomic [commit].
  Future<void> enqueue(OutboxEntry entry);

  /// Lists all peers' entries, or only entries addressed to [recipientPeerId].
  Future<List<OutboxEntry>> pending(
    String replicaId, {
    String? recipientPeerId,
  });

  /// Marks only this peer's entries sent without removing them, allowing retry.
  /// Implementations record the attempt count and send time for retry policy.
  Future<void> markSent(
    String replicaId,
    String recipientPeerId,
    Iterable<String> operationIds,
  );

  /// Confirms only [operationIds] addressed to [recipientPeerId].
  ///
  /// Entries whose IDs are not acknowledged remain pending.
  Future<void> acknowledge(
    String replicaId,
    String recipientPeerId,
    Iterable<String> operationIds,
  );
}

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
