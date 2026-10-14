import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('incoming failure reuses the errors event in observations', () async {
    final transport = _IncomingTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('client'),
      storage: MemoryStorage(),
      transport: transport,
    );
    await engine.start();
    final observed = engine.observations
        .where((event) => event is SyncFailure)
        .first;
    final legacy = engine.errors.first;
    transport.controller.addError(StateError('incoming failed'));
    expect(identical(await observed, await legacy), isTrue);
    await engine.setDelta('local', 'still editable');
    expect(engine.valueAt('local'), 'still editable');
    await engine.dispose();
    await transport.controller.close();
  });
  test(
    'observations distinguish restore, commit, partial ACK and failure/retry',
    () async {
      final store = _Storage();
      final transport = _Transport();
      final engine = SyncEngine.withStorage(
        replica: Replica('client'),
        storage: store,
        transport: transport,
      );
      final events = <SyncObservation>[];
      final closed = Completer<void>();
      engine.observations.listen(events.add, onDone: closed.complete);
      await engine.start();
      await flush();
      expect(events.single, isA<SyncRestoredEvent>());
      final first = await engine.setDelta('first', 'one');
      final second = await engine.setDelta('second', 'two');
      await flush();
      expect(events.whereType<SyncCommitEvent>(), hasLength(2));
      expect(events.whereType<SyncPushResult>(), isEmpty);
      store.failCommit = true;
      await expectLater(engine.setDelta('failed', 'value'), throwsStateError);
      await flush();
      expect(events.whereType<SyncCommitEvent>(), hasLength(2));
      expect(engine.valueAt('failed'), isNull);
      store.failCommit = false;
      transport.stage = DeltaAckStage.received;
      await engine.push(force: true);
      await flush();
      expect(events.whereType<SyncPushResult>().last.acknowledgedIds, isEmpty);
      expect((await engine.pendingDelta()).changes, hasLength(2));
      transport.stage = DeltaAckStage.appliedAndPersisted;
      transport.ids = [first.id];
      final partial = await engine.push(force: true);
      await flush();
      expect(
        identical(events.whereType<SyncPushResult>().last, partial),
        isTrue,
      );
      expect(partial.acknowledgedIds, {first.id});
      expect((await engine.pendingDelta()).changes.single.id, second.id);
      transport.fail = true;
      await expectLater(engine.push(force: true), throwsStateError);
      await flush();
      expect(events.last, isA<SyncPushFailure>());
      expect((await engine.pendingDelta()).changes.single.id, second.id);
      transport.fail = false;
      transport.ids = [second.id];
      await engine.push(force: true);
      await flush();
      expect(events.whereType<SyncPushResult>().last.acknowledgedIds, {
        second.id,
      });
      expect((await engine.pendingDelta()).changes, isEmpty);
      await engine.dispose();
      await closed.future;
      final restored = SyncEngine.withStorage(
        replica: Replica('client'),
        storage: store,
        transport: _Transport(),
      );
      final restoredEvents = <SyncObservation>[];
      restored.observations.listen(restoredEvents.add);
      await restored.start();
      await flush();
      expect(restoredEvents.single, isA<SyncRestoredEvent>());
      expect(restored.valueAt('first'), 'one');
      expect((await restored.pendingDelta()).changes, isEmpty);
      await restored.dispose();
    },
  );

  test('late, paused and throwing listeners never govern commits', () async {
    final engine = SyncEngine.withStorage(
      replica: Replica('client'),
      storage: MemoryStorage(),
      transport: _Transport(),
    );
    await engine.start();
    await flush();
    final events = <SyncObservation>[];
    final paused = engine.observations.listen(events.add)..pause();
    final caught = Completer<Object>();
    late StreamSubscription<SyncObservation> throwing;
    runZonedGuarded(
      () {
        throwing = engine.observations.listen((_) {
          throw StateError('listener');
        });
      },
      (error, _) {
        if (!caught.isCompleted) caught.complete(error);
      },
    );
    await engine.setDelta('field', 'value').timeout(const Duration(seconds: 2));
    await caught.future;
    expect(engine.valueAt('field'), 'value');
    expect(events, isEmpty);
    await paused.cancel();
    await throwing.cancel();
    await engine.dispose();
  });
}

class _Storage extends MemoryStorage {
  bool failCommit = false;
  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    if (failCommit) throw StateError('rollback');
    await super.commit(snapshot, entries);
  }
}

class _Transport implements AcknowledgingDeltaTransport {
  DeltaAckStage stage = DeltaAckStage.appliedAndPersisted;
  List<String>? ids;
  bool fail = false;
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    if (fail) throw StateError('offline');
    return DeltaAcknowledgement(
      peerReplicaId: 'peer',
      stage: stage,
      changeIds: ids ?? envelope.delta.changes.map((c) => c.id),
    );
  }
}

class _IncomingTransport implements DeltaTransport {
  final controller = StreamController<DeltaEnvelope>();
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => controller.stream;
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
}
