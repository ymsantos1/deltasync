import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';

/// Internal storage boundary. The engine adopts candidates and emits events
/// only after these methods succeed; this object never mutates live state.
class ReplicaPersistence {
  ReplicaPersistence({required this.storage});
  final ReplicaStorage storage;

  Future<void> restoreInto(Replica candidate) async {
    final snapshot = await storage.loadReplica(candidate.id);
    if (snapshot != null) {
      if (snapshot.version == 2) {
        final encodedState = snapshot.snapshot;
        if (encodedState == null) {
          throw FormatException('Missing canonical replica snapshot');
        }
        candidate.adopt(Replica.fromSnapshotJson(encodedState));
      } else if (snapshot.version == 1) {
        _restoreLegacySnapshot(candidate, snapshot);
      } else {
        throw FormatException('Unsupported storage snapshot version');
      }
    }
    for (final entry in await storage.pending(candidate.id)) {
      candidate.apply(entry.delta);
    }
  }

  Future<void> save(Replica candidate) async {
    await storage.saveReplica(ReplicaSnapshot.fromReplica(candidate));
  }

  Future<void> commitLocal(
    Replica candidate,
    List<DeltaChange> changes,
    String peer,
  ) async {
    await storage.commit(ReplicaSnapshot.fromReplica(candidate), [
      for (final change in changes)
        OutboxEntry(delta: Delta([change]), recipientPeerId: peer),
    ]);
  }

  Future<void> commitRemote(Replica candidate) async {
    await storage.commitRemote(ReplicaSnapshot.fromReplica(candidate));
  }

  Future<Delta> pendingDelta(String replicaId) async {
    return mergeOutbox(await storage.pending(replicaId));
  }

  Future<void> acknowledge(
    String replicaId,
    String peer,
    Set<String> ids,
  ) async {
    if (ids.isNotEmpty) await storage.acknowledge(replicaId, peer, ids);
  }

  void _restoreLegacySnapshot(Replica target, ReplicaSnapshot snapshot) {
    if (snapshot.replicaId != target.id) {
      throw FormatException('Snapshot replica ID mismatch');
    }
    final metadata = snapshot.legacyMetadata;
    final clock = snapshot.legacyClock;
    if (metadata == null || clock == null) {
      throw FormatException('Invalid legacy replica snapshot');
    }
    final encodedState = metadata['replicaState'];
    if (encodedState is Map) {
      target.adopt(
        Replica.fromSnapshotJson(Map<String, Object?>.from(encodedState)),
      );
      return;
    }
    final hlc = _readHlcOrNull(metadata);
    if (hlc != null) target.restoreMetadata(clock: clock, hlc: hlc);
    final encoded = metadata['delta'];
    if (encoded is Map) {
      target.apply(
        Delta.fromJson(
          Map<String, Object?>.from(encoded),
          allowLegacyOperations: true,
          allowLegacyCounterIdentity: true,
        ),
      );
      return;
    }
    if (snapshot.legacyState?.isNotEmpty ?? false) {
      throw FormatException('Legacy snapshot lacks replayable state');
    }
  }

  HlcTimestamp? _readHlcOrNull(Map<String, Object?> metadata) {
    final value = metadata['hlc'];
    if (value == null) return null;
    if (value is! Map) throw FormatException('Invalid snapshot HLC');
    return HlcTimestamp.fromJson(Map<String, Object?>.from(value));
  }
}

Delta mergeOutbox(Iterable<OutboxEntry> entries) {
  // Validate IDs once after collecting changes; repeated prefix merges make
  // reading a long offline outbox quadratic. Delta.merge keeps its ID/order rules.
  return Delta(
    entries.expand((entry) => entry.delta.changes),
  ).merge(const Delta.empty());
}
