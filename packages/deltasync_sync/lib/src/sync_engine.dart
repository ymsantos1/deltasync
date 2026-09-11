import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_transport/deltasync_transport.dart';

/// Coordinates local CRDT changes, pending persistence, and remote deltas.
class SyncEngine {
  SyncEngine({
    required this.replica,
    this.store,
    this.storage,
    required this.transport,
  }) : assert(store != null || storage != null);

  SyncEngine.withStorage({
    required Replica replica,
    required ReplicaStorage storage,
    required DeltaTransport transport,
  }) : this(replica: replica, storage: storage, transport: transport);

  final Replica replica;
  final PendingDeltaStore? store;
  final ReplicaStorage? storage;
  final DeltaTransport transport;
  StreamSubscription<Delta>? _subscription;
  bool _started = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_started) throw StateError('SyncEngine already started');
    if (_disposed) throw StateError('SyncEngine already disposed');
    _started = true;
    if (storage != null) {
      final snapshot = await storage!.loadReplica(replica.id);
      if (snapshot != null) {
        final hlc = _readHlcOrNull(snapshot.metadata);
        if (hlc != null) {
          replica.restoreMetadata(clock: snapshot.clock, hlc: hlc);
        }
        final encoded = snapshot.metadata['delta'];
        if (encoded is Map) {
          replica.apply(Delta.fromJson(Map<String, Object?>.from(encoded)));
        }
      }
      for (final entry in await storage!.pending(replica.id)) {
        if (entry.delta != null) replica.apply(entry.delta!);
      }
    } else {
      replica.apply(await store!.read(replica.id));
    }
    _subscription = transport.incoming.listen((delta) async {
      replica.apply(delta);
      await _saveSnapshot();
    });
    await _saveSnapshot();
  }

  Future<Operation> set(String key, Object? value) async {
    final change = replica.set(key, value);
    if (storage != null) {
      await storage!.enqueue(OutboxEntry(operation: change));
      await _saveSnapshot();
    } else {
      await _persistPending(change);
    }
    return change;
  }

  Future<Operation> remove(String key) async {
    final change = replica.remove(key);
    if (storage != null) {
      await storage!.enqueue(OutboxEntry(operation: change));
      await _saveSnapshot();
    } else {
      await _persistPending(change);
    }
    return change;
  }

  Future<LwwDelta<Object?>> setDelta(String key, Object? value) async {
    final change = replica.setDelta(key, value);
    if (storage != null) {
      await storage!.enqueue(OutboxEntry(delta: Delta.crdt([change])));
      await _saveSnapshot();
    } else {
      await _persistPendingDelta(change);
    }
    return change;
  }

  Future<LwwDelta<Object?>> removeDelta(String key) async {
    final change = replica.removeDelta(key);
    if (storage != null) {
      await storage!.enqueue(OutboxEntry(delta: Delta.crdt([change])));
      await _saveSnapshot();
    } else {
      await _persistPendingDelta(change);
    }
    return change;
  }

  Future<void> push() async {
    if (storage != null) {
      final entries = await storage!.pending(replica.id);
      if (entries.isEmpty) return;
      var pending = const Delta.empty();
      for (final entry in entries) {
        pending = pending.merge(entry.delta ?? Delta([entry.operation!]));
      }
      await transport.send(pending);
      await storage!.acknowledge(
        replica.id,
        entries.map((entry) => entry.operationId),
      );
      return;
    }
    final pending = await store!.read(replica.id);
    if (pending.isEmpty) return;
    await transport.send(pending);
    await store!.write(replica.id, const Delta.empty());
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription?.cancel();
  }

  Future<void> _persistPending(Operation change) async {
    final pending = await store!.read(replica.id);
    await store!.write(replica.id, pending.merge(Delta([change])));
  }

  Future<void> _persistPendingDelta(DeltaChange change) async {
    final pending = await store!.read(replica.id);
    await store!.write(replica.id, pending.merge(Delta.crdt([change])));
  }

  Future<void> _saveSnapshot() async {
    if (storage == null) return;
    await storage!.saveReplica(
      ReplicaSnapshot(
        replicaId: replica.id,
        state: replica.state.values,
        clock: replica.clock,
        metadata: {
          'delta': replica.export().toJson(),
          'hlc': replica.hlcTimestamp.toJson(),
        },
      ),
    );
  }

  HlcTimestamp? _readHlcOrNull(Map<String, Object?> metadata) {
    final value = metadata['hlc'];
    if (value == null) return null;
    if (value is! Map) throw FormatException('Invalid snapshot HLC');
    return HlcTimestamp.fromJson(Map<String, Object?>.from(value));
  }
}
