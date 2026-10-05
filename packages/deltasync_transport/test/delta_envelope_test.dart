import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  test('ACK stages expose stable wire labels and reject unknown labels', () {
    expect(DeltaAckStage.received.wireName, 'received');
    expect(DeltaAckStage.appliedAndPersisted.wireName, 'applied-and-persisted');
    expect(
      DeltaAckStage.fromWire('applied-and-persisted'),
      DeltaAckStage.appliedAndPersisted,
    );
    expect(() => DeltaAckStage.fromWire('future'), throwsFormatException);
  });

  test('DeltaEnvelope round trips versioned delta', () {
    final replica = Replica('device-a');
    final envelope = DeltaEnvelope(
      senderReplicaId: replica.id,
      recipientReplicaId: 'server-a',
      delta: Delta([replica.setDelta('title', 'draft')]),
    );

    final decoded = DeltaEnvelope.fromJson(envelope.toJson());
    expect(decoded.senderReplicaId, 'device-a');
    expect(decoded.recipientReplicaId, 'server-a');
    expect(decoded.delta.changes, envelope.delta.changes);
  });

  test('DeltaEnvelope rejects incompatible versions', () {
    expect(
      () => DeltaEnvelope.fromJson({
        'version': 99,
        'senderReplicaId': 'device-a',
        'recipientReplicaId': 'server-a',
        'delta': {},
      }),
      throwsFormatException,
    );
  });

  test('legacy envelope requires explicit destination binding', () {
    final replica = Replica('device-a');
    final legacy = {
      'version': 1,
      'senderReplicaId': 'device-a',
      'delta': DeltaCodec.encode(Delta([replica.setDelta('title', 'draft')])),
    };

    expect(() => DeltaEnvelope.fromJson(legacy), throwsFormatException);
    expect(
      DeltaEnvelope.fromJson(
        legacy,
        legacyRecipientReplicaId: 'peer-b',
      ).recipientReplicaId,
      'peer-b',
    );
  });

  test('envelope preserves mixed CRDT metadata through codec', () {
    final source = Replica('source');
    final delta = Delta([
      source.setDelta('title', 'draft'),
      source.incrementGCounter('cart/apples', 2),
      source.incrementPnCounter('account/balance', 5),
    ]);
    final envelope = DeltaEnvelope(
      senderReplicaId: 'relay',
      recipientReplicaId: 'device-b',
      delta: delta,
    );

    final decoded = DeltaEnvelope.fromJson(envelope.toJson());

    expect(decoded.senderReplicaId, 'relay');
    expect(decoded.recipientReplicaId, 'device-b');
    expect(decoded.senderReplicaId, isNot('source'));
    expect(decoded.delta.changes, delta.changes);
    expect(decoded.delta.changes.map((change) => change.kind), [
      CrdtKind.lww,
      CrdtKind.gCounter,
      CrdtKind.pnCounter,
    ]);
    expect(decoded.delta.changes.map((change) => change.crdtId), [
      'title',
      'cart/apples',
      'account/balance',
    ]);
    expect(decoded.delta.changes.map((change) => change.replicaId), [
      'source',
      'source',
      'source',
    ]);
  });

  test('envelope validates constructor and malformed wire data', () {
    final delta = Replica('source').setDelta('title', 'draft');
    expect(
      () => DeltaEnvelope(
        senderReplicaId: ' ',
        recipientReplicaId: 'peer',
        delta: Delta([delta]),
      ),
      throwsArgumentError,
    );
    expect(
      () => DeltaEnvelope(
        senderReplicaId: 'relay',
        recipientReplicaId: 'peer',
        delta: Delta([delta]),
        version: 99,
      ),
      throwsArgumentError,
    );
    for (final invalid in [
      {
        'version': 2,
        'senderReplicaId': ' ',
        'recipientReplicaId': 'peer',
        'delta': {},
      },
      {
        'version': 2,
        'senderReplicaId': 3,
        'recipientReplicaId': 'peer',
        'delta': {},
      },
      {
        'version': 2,
        'senderReplicaId': 'relay',
        'recipientReplicaId': 'peer',
        'delta': {'version': 99},
      },
      {
        'version': 2,
        'senderReplicaId': 'relay',
        'recipientReplicaId': 'peer',
        'delta': {
          'version': 3,
          'delta': {
            'changes': [
              {'type': 'unknown'},
            ],
          },
        },
      },
    ]) {
      expect(() => DeltaEnvelope.fromJson(invalid), throwsFormatException);
    }
  });
}
