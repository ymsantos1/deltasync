import 'dart:async';

import 'package:deltasync/deltasync.dart';

Future<void> main() async {
  final localLink = DemoPeerLink('device-b');
  final remoteLink = DemoPeerLink('device-a');
  final local = SyncEngine.withStorage(
    replica: Replica('device-a'),
    storage: MemoryStorage(),
    transport: localLink,
  );
  final remote = SyncEngine.withStorage(
    replica: Replica('device-b'),
    storage: MemoryStorage(),
    transport: remoteLink,
  );
  localLink.deliver = (message) => remote.applyRemote(message.delta);
  remoteLink.deliver = (message) => local.applyRemote(message.delta);

  final errors = local.errors.listen((failure) {
    print('sync error: ${failure.error}');
  });
  await Future.wait([local.start(), remote.start()]);
  await local.setDelta('document/title', 'edited offline');
  await local.incrementGCounter('cart/items', 2);
  await local.decrementPnCounter('account/balance', 1);

  // Local commit and outbox persistence finish before any network request.
  print('local: ${local.replica.state.values}');
  print('pending: ${(await local.pendingDelta()).changes.length}');
  final result = await local.push();
  print('confirmed: ${result.acknowledgedIds.length}');
  print('remote: ${remote.replica.state.values}');

  await errors.cancel();
  await local.dispose();
  await remote.dispose();
  await localLink.close();
  await remoteLink.close();
}

/// Minimal application adapter. A real transport maps this request/response
/// boundary to its chosen network and calls [deliver] only after remote commit.
class DemoPeerLink implements AcknowledgingDeltaTransport {
  DemoPeerLink(this.peerReplicaId);

  @override
  final String peerReplicaId;
  final _incoming = StreamController<DeltaEnvelope>.broadcast();
  Future<void> Function(DeltaEnvelope)? deliver;

  @override
  Stream<DeltaEnvelope> get incoming => _incoming.stream;

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    final handler = deliver;
    if (handler == null) throw StateError('Peer is not connected');
    await handler(envelope);
  }

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await send(envelope);
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }

  Future<void> close() => _incoming.close();
}
