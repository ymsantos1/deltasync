import 'dart:async';

import 'package:deltasync/deltasync.dart';

/// In-process peer for this demo. Delivery completes after the peer commits.
class PeerLink implements AcknowledgingDeltaTransport {
  PeerLink(this.peerReplicaId);

  @override
  final String peerReplicaId;

  final _incoming = StreamController<DeltaEnvelope>.broadcast();
  Future<void> Function(DeltaEnvelope)? deliver;

  @override
  Stream<DeltaEnvelope> get incoming => _incoming.stream;

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    final handler = deliver;
    if (handler == null) throw StateError('Peer $peerReplicaId offline');
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
