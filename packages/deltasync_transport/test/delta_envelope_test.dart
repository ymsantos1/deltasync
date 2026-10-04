import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  test('DeltaEnvelope round trips versioned delta', () {
    final replica = Replica('device-a');
    final envelope = DeltaEnvelope(
      senderReplicaId: replica.id,
      delta: Delta([replica.setDelta('title', 'draft')]),
    );

    final decoded = DeltaEnvelope.fromJson(envelope.toJson());
    expect(decoded.senderReplicaId, 'device-a');
    expect(decoded.delta.changes, envelope.delta.changes);
  });

  test('DeltaEnvelope rejects incompatible versions', () {
    expect(
      () => DeltaEnvelope.fromJson({
        'version': 99,
        'senderReplicaId': 'device-a',
        'delta': {},
      }),
      throwsFormatException,
    );
  });
}
