import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_transport/deltasync_transport.dart';

/// Coordinates local CRDT changes, pending persistence, and remote deltas.
class SyncEngine {
  SyncEngine({
    required this.replica,
    required this.store,
    required this.transport,
  });

  final Replica replica;
  final PendingDeltaStore store;
  final DeltaTransport transport;
  StreamSubscription<Delta>? _subscription;

  Future<void> start() async {
    replica.apply(await store.read(replica.id));
    _subscription = transport.incoming.listen(replica.apply);
  }

  Future<Operation> set(String key, Object? value) async {
    final change = replica.set(key, value);
    await _persistPending(change);
    return change;
  }

  Future<Operation> remove(String key) async {
    final change = replica.remove(key);
    await _persistPending(change);
    return change;
  }

  Future<LwwDelta<Object?>> setDelta(String key, Object? value) async {
    final change = replica.setDelta(key, value);
    await _persistPendingDelta(change);
    return change;
  }

  Future<LwwDelta<Object?>> removeDelta(String key) async {
    final change = replica.removeDelta(key);
    await _persistPendingDelta(change);
    return change;
  }

  Future<void> push() async {
    final pending = await store.read(replica.id);
    if (pending.isEmpty) return;
    await transport.send(pending);
    await store.write(replica.id, const Delta.empty());
  }

  Future<void> dispose() => _subscription?.cancel() ?? Future.value();

  Future<void> _persistPending(Operation change) async {
    final pending = await store.read(replica.id);
    await store.write(replica.id, pending.merge(Delta([change])));
  }

  Future<void> _persistPendingDelta(DeltaChange change) async {
    final pending = await store.read(replica.id);
    await store.write(replica.id, pending.merge(Delta.crdt([change])));
  }
}
