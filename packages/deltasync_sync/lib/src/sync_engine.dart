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
    this.retryPolicy = const SyncRetryPolicy(),
  }) : assert(store != null || storage != null);

  SyncEngine.withStorage({
    required Replica replica,
    required ReplicaStorage storage,
    required DeltaTransport transport,
    SyncRetryPolicy retryPolicy = const SyncRetryPolicy(),
  }) : this(
         replica: replica,
         storage: storage,
         transport: transport,
         retryPolicy: retryPolicy,
       );

  final Replica replica;
  final PendingDeltaStore? store;
  final ReplicaStorage? storage;
  final DeltaTransport transport;
  StreamSubscription<Delta>? _subscription;
  bool _started = false;
  bool _disposed = false;
  Future<void>? _pushFuture;
  final SyncRetryPolicy retryPolicy;

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

  /// Increments G-Counter at stable application-defined [crdtId].
  Future<GCounterDelta> incrementGCounter(
    String crdtId, [
    int amount = 1,
  ]) async {
    final change = replica.incrementGCounter(crdtId, amount);
    await _persistCounterChange(change);
    return change;
  }

  /// Increments PN-Counter at stable application-defined [crdtId].
  Future<PnCounterDelta> incrementPnCounter(
    String crdtId, [
    int amount = 1,
  ]) async {
    final change = replica.incrementPnCounter(crdtId, amount);
    await _persistCounterChange(change);
    return change;
  }

  /// Decrements PN-Counter at stable application-defined [crdtId].
  Future<PnCounterDelta> decrementPnCounter(
    String crdtId, [
    int amount = 1,
  ]) async {
    final change = replica.decrementPnCounter(crdtId, amount);
    await _persistCounterChange(change);
    return change;
  }

  Future<void> push({bool force = false}) {
    final running = _pushFuture;
    if (running != null) return running;
    final future = _pushInternal(force: force);
    _pushFuture = future.whenComplete(() => _pushFuture = null);
    return _pushFuture!;
  }

  Future<void> _pushInternal({required bool force}) async {
    if (storage != null) {
      final allEntries = await storage!.pending(replica.id);
      final now = DateTime.now().toUtc();
      final entries = allEntries.where((entry) {
        if (force || entry.status == OutboxStatus.pending) return true;
        final maxAttempts = retryPolicy.maxAttempts;
        if (maxAttempts != null && entry.attempts >= maxAttempts) return false;
        final sentAt = entry.sentAt;
        return sentAt == null ||
            now.difference(sentAt) >= retryPolicy.delayFor(entry.attempts);
      }).toList();
      if (entries.isEmpty) return;
      var pending = const Delta.empty();
      for (final entry in entries) {
        pending = pending.merge(entry.delta ?? Delta([entry.operation!]));
      }
      final ids = entries.expand((entry) => entry.changeIds).toList();
      await storage!.markSent(replica.id, ids);
      final acknowledged = transport is AcknowledgingDeltaTransport
          ? await (transport as AcknowledgingDeltaTransport).sendAndAwaitAck(
              pending,
            )
          : await _sendWithoutAck(pending);
      final sentIds = ids.toSet();
      final acceptedIds = acknowledged.where(sentIds.contains).toSet();
      if (acceptedIds.isNotEmpty) {
        await storage!.acknowledge(replica.id, acceptedIds);
      }
      return;
    }
    final pending = await store!.read(replica.id);
    if (pending.isEmpty) return;
    await transport.send(pending);
    // PendingDeltaStore has no ACK contract. Keep changes for at-least-once
    // retry instead of treating successful transmission as remote acceptance.
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

  Future<void> _persistCounterChange(DeltaChange change) async {
    if (storage != null) {
      await storage!.enqueue(OutboxEntry(delta: Delta.crdt([change])));
      await _saveSnapshot();
    } else {
      await _persistPendingDelta(change);
    }
  }

  Future<Iterable<String>> _sendWithoutAck(Delta delta) async {
    await transport.send(delta);
    return const [];
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

/// Exponential retry policy for ReplicaStorage entries without confirmation.
///
/// Automatic retries stop after [maxAttempts] when configured. `push(force:
/// true)` deliberately bypasses both the retry delay and attempt cap for manual
/// retransmission. The legacy [PendingDeltaStore] path has no attempt metadata;
/// every push retries its retained delta and this policy does not apply there.
class SyncRetryPolicy {
  const SyncRetryPolicy({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 1),
    this.maxAttempts,
  });

  final Duration baseDelay;
  final Duration maxDelay;
  final int? maxAttempts;

  Duration delayFor(int attempts) {
    if (attempts <= 0) return Duration.zero;
    var delay = baseDelay > maxDelay ? maxDelay : baseDelay;
    for (var index = 1; index < attempts; index++) {
      final doubled = delay * 2;
      delay = doubled > maxDelay ? maxDelay : doubled;
    }
    return delay;
  }
}
