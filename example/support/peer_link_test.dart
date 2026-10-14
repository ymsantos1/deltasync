import 'dart:async';

import 'package:deltasync/deltasync.dart';
import 'package:test/test.dart';

import '../offline_reconciliation.dart' show DemoPeerLink;
import 'peer_link.dart';

void main() {
  final envelope = DeltaEnvelope(
    senderReplicaId: 'sender',
    recipientReplicaId: 'peer',
    delta: Delta([Replica('sender').setDelta('field', 'value')]),
  );
  test(
    'shared link preserves offline diagnostics and stream closure',
    () async {
      for (final link in [PeerLink('peer'), DemoPeerLink('peer')]) {
        final expected = link is DemoPeerLink
            ? 'Peer peer is offline'
            : 'Peer peer offline';
        await expectLater(
          link.sendAndAwaitAck(envelope),
          throwsA(
            isA<StateError>().having((e) => e.message, 'message', expected),
          ),
        );
        final done = Completer<void>();
        link.incoming.listen((_) {}, onDone: done.complete);
        await link.close();
        await done.future;
      }
    },
  );
  test(
    'shared link waits for commit and does not ACK a failed handler',
    () async {
      final link = PeerLink('peer');
      final committed = Completer<void>();
      link.deliver = (_) => committed.future;
      var acked = false;
      final receiving = link.sendAndAwaitAck(envelope).then((ack) {
        acked = true;
        expect(ack.peerReplicaId, 'peer');
        expect(ack.stage, DeltaAckStage.appliedAndPersisted);
        expect(ack.changeIds, envelope.delta.changes.map((c) => c.id).toSet());
      });
      await Future<void>.delayed(Duration.zero);
      expect(acked, isFalse);
      committed.complete();
      await receiving;
      link.deliver = (_) async {
        throw StateError('commit failed');
      };
      await expectLater(link.sendAndAwaitAck(envelope), throwsStateError);
      await link.close();
    },
  );
}
