import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  test(
    'pull validates peer and confirms only after successful commit',
    () async {
      final store = _Storage();
      final transport = _Transport();
      final engine = _engine(store, transport);
      addTearDown(() async {
        await engine.dispose();
        await transport.controller.close();
      });
      final local = await engine.setDelta('local', 'kept');
      final remote = Replica('peer').setDelta('remote', 'value');
      DeltaEnvelope envelope(String sender, String recipient) => DeltaEnvelope(
        senderReplicaId: sender,
        recipientReplicaId: recipient,
        delta: Delta([remote]),
      );
      for (final invalid in [
        envelope('wrong', 'client'),
        envelope('peer', 'wrong'),
      ]) {
        await expectLater(
          engine.receiveEnvelope(invalid),
          throwsFormatException,
        );
      }
      expect(transport.acks, isEmpty);
      expect(engine.valueAt('remote'), isNull);
      store.failRemote = true;
      await expectLater(
        engine.receiveEnvelope(envelope('peer', 'client')),
        throwsStateError,
      );
      expect(transport.acks, isEmpty);
      expect(engine.valueAt('remote'), isNull);
      store.failRemote = false;
      transport.inspect = (ack) async {
        expect(engine.valueAt('remote'), 'value');
        expect(
          (await store.loadReplica('client'))!.snapshot!['lww'],
          isNotEmpty,
        );
        expect(ack.peerReplicaId, 'client');
        expect(ack.stage, DeltaAckStage.appliedAndPersisted);
        expect(ack.changeIds, {remote.id});
      };
      final ack = await engine.receiveEnvelope(envelope('peer', 'client'));
      expect(ack.changeIds, {remote.id});
      await engine.receiveEnvelope(envelope('peer', 'client'));
      expect(transport.acks, hasLength(2));
      expect((await engine.pendingDelta()).changes.map((c) => c.id), [
        local.id,
      ]);
    },
  );

  test(
    'ACK network wait permits edits and disposal drains accepted receive',
    () async {
      final store = _Storage();
      final transport = _Transport();
      final engine = _engine(store, transport);
      final entered = Completer<void>();
      final release = Completer<void>();
      transport.inspect = (_) async {
        entered.complete();
        await release.future;
      };
      final envelope = DeltaEnvelope(
        senderReplicaId: 'peer',
        recipientReplicaId: 'client',
        delta: Delta([Replica('peer').setDelta('remote', 'value')]),
      );
      final receiving = engine.receiveEnvelope(envelope);
      await entered.future;
      await engine
          .setDelta('local', 'during ACK')
          .timeout(const Duration(seconds: 2));
      expect(engine.valueAt('local'), 'during ACK');
      var disposed = false;
      final disposing = engine.dispose().then((_) {
        disposed = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(disposed, isFalse);
      await expectLater(engine.receiveEnvelope(envelope), throwsStateError);
      release.complete();
      await receiving;
      await disposing;
      expect(disposed, isTrue);
      await transport.controller.close();
    },
  );

  test(
    'stream ACK failure is observable, preserves commit and supports replay',
    () async {
      final store = _Storage();
      final transport = _Transport();
      final engine = _engine(store, transport);
      addTearDown(() async {
        await engine.dispose();
        await transport.controller.close();
      });
      await engine.start();
      final envelope = DeltaEnvelope(
        senderReplicaId: 'peer',
        recipientReplicaId: 'client',
        delta: Delta([Replica('peer').setDelta('remote', 'value')]),
      );
      transport.inspect = (_) async {
        throw StateError('ACK lost');
      };
      final failure = engine.errors.first;
      transport.controller.add(envelope);
      expect((await failure).source, SyncFailureSource.incomingDelta);
      expect(engine.valueAt('remote'), 'value');
      expect((await engine.pendingDelta()).changes, isEmpty);
      transport.inspect = null;
      final confirmed = Completer<void>();
      transport.inspect = (_) async {
        confirmed.complete();
      };
      transport.controller.add(envelope);
      await confirmed.future;
      expect(engine.valueAt('remote'), 'value');
      expect(transport.acks, hasLength(2));
    },
  );
}

SyncEngine _engine(ReplicaStorage store, DeltaTransport transport) =>
    SyncEngine.withStorage(
      replica: Replica('client'),
      storage: store,
      transport: transport,
    );

class _Storage extends MemoryStorage {
  bool failRemote = false;
  @override
  Future<void> commitRemote(ReplicaSnapshot snapshot) async {
    if (failRemote) throw StateError('remote commit failed');
    await super.commitRemote(snapshot);
  }
}

class _Transport implements IncomingAcknowledgingDeltaTransport {
  final controller = StreamController<DeltaEnvelope>();
  final acks = <DeltaAcknowledgement>[];
  Future<void> Function(DeltaAcknowledgement)? inspect;
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => controller.stream;
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
  @override
  Future<void> acknowledge(DeltaAcknowledgement acknowledgement) async {
    acks.add(acknowledgement);
    await inspect?.call(acknowledgement);
  }
}
