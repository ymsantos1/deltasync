import 'dart:convert';

import 'package:deltasync/deltasync.dart';
import 'package:test/test.dart';

void main() {
  test(
    'public ACK codec preserves pending IDs through failed and partial ACKs',
    () async {
      final transport = _JsonAckTransport();
      final engine = SyncEngine.withStorage(
        replica: Replica('client'),
        storage: MemoryStorage(),
        transport: transport,
      );
      addTearDown(engine.dispose);
      final first = await engine.setDelta('first', 'one');
      final second = await engine.setDelta('second', 'two');
      Set<String> pendingIds(Delta delta) =>
          delta.changes.map((change) => change.id).toSet();

      for (final invalid in [
        {
          'peerReplicaId': 'peer',
          'stage': 'future',
          'changeIds': [first.id],
        },
        {
          'peerReplicaId': 'peer',
          'stage': 'received',
          'changeIds': [1],
        },
      ]) {
        transport.reply = invalid;
        await expectLater(engine.push(force: true), throwsFormatException);
        expect(pendingIds(await engine.pendingDelta()), {first.id, second.id});
      }
      transport.reply = {
        'peerReplicaId': 'wrong',
        'stage': 'applied-and-persisted',
        'changeIds': [first.id, second.id],
      };
      await expectLater(engine.push(force: true), throwsStateError);
      expect(pendingIds(await engine.pendingDelta()), {first.id, second.id});

      transport.reply = {
        'peerReplicaId': 'peer',
        'stage': 'received',
        'changeIds': [first.id, second.id],
      };
      expect((await engine.push(force: true)).acknowledgedIds, isEmpty);
      expect(pendingIds(await engine.pendingDelta()), {first.id, second.id});

      transport.reply = DeltaAcknowledgement(
        peerReplicaId: 'peer',
        stage: DeltaAckStage.appliedAndPersisted,
        changeIds: [],
      ).toJson();
      expect((await engine.push(force: true)).acknowledgedIds, isEmpty);
      expect(pendingIds(await engine.pendingDelta()), {first.id, second.id});

      transport.reply = {
        'peerReplicaId': 'peer',
        'stage': 'applied-and-persisted',
        'changeIds': [first.id, first.id, 'outside-batch'],
      };
      expect((await engine.push(force: true)).acknowledgedIds, {first.id});
      expect(pendingIds(await engine.pendingDelta()), {second.id});
      transport.reply = DeltaAcknowledgement(
        peerReplicaId: 'peer',
        stage: DeltaAckStage.appliedAndPersisted,
        changeIds: [second.id],
      ).toJson();
      expect((await engine.push(force: true)).acknowledgedIds, {second.id});
      expect((await engine.pendingDelta()).changes, isEmpty);
    },
  );
}

/// Separate consumer of the public codec without Compass or HTTP dependencies.
class _JsonAckTransport implements AcknowledgingDeltaTransport {
  Map<String, Object?> reply = {};

  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async {
    await sendAndAwaitAck(envelope);
  }

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async =>
      DeltaAcknowledgement.fromJson(
        Map<String, Object?>.from(jsonDecode(jsonEncode(reply)) as Map),
      );
}
