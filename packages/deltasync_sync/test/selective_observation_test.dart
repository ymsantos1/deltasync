import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _Storage storage;
  late _Transport transport;
  late SyncEngine engine;
  setUp(() {
    storage = _Storage();
    transport = _Transport();
    engine = SyncEngine.withStorage(
      replica: Replica('local', hlc: HlcClock(nowMilliseconds: () => 1000)),
      storage: storage,
      transport: transport,
    );
  });
  tearDown(() async {
    final gate = storage.gate;
    if (gate != null && !gate.isCompleted) gate.complete();
    await engine.dispose();
    await transport.incomingController.close();
  });

  test(
    'eight-kind batch emits one isolated address set on all commit views',
    () async {
      final observations = <SyncObservation>[];
      final all = <SyncCommitEvent>[];
      final selected = <SyncCommitEvent>[];
      engine.observations.listen(observations.add);
      engine.commits.listen(all.add);
      engine.commitsFor('gs').listen((event) {
        selected.add(event);
        expect((engine.query('gs') as PresentField).value, {'a'});
      });
      final delta = await engine.batch((batch) {
        batch.setDelta('lww', 'one');
        batch.setDelta('lww', null);
        batch.incrementGCounter('g');
        batch.decrementPnCounter('pn');
        batch.addGSet('gs', 'a');
        batch.addTwoPSet('two', 'a');
        batch.writeMvRegister('mv', null);
        batch.addOrSet('os', 'a');
        batch.addOrMapKey('om', 'key');
      });
      await flush();
      expect(all, hasLength(1));
      expect(all.single.origin, SyncCommitOrigin.local);
      expect(all.single.addresses, {
        'lww',
        'g',
        'pn',
        'gs',
        'two',
        'mv',
        'os',
        'om',
      });
      expect(
        identical(all.single, observations.whereType<SyncCommitEvent>().single),
        isTrue,
      );
      expect(identical(all.single, selected.single), isTrue);
      expect(() => all.single.addresses.clear(), throwsUnsupportedError);
      expect((await engine.pendingSummary()).totalCount, delta.changes.length);
      await engine.setDelta('unrelated', true);
      await flush();
      expect(selected, hasLength(1));
      expect(all.first.addresses, isNot(contains('unrelated')));
      final input = {'field'};
      final external = SyncCommitEvent(
        origin: SyncCommitOrigin.local,
        addresses: input,
      );
      input.clear();
      expect(external.addresses, {'field'});
    },
  );

  test(
    'remote replay, losing values and snapshots report processed inputs',
    () async {
      final events = <SyncCommitEvent>[];
      engine.commits.listen(events.add);
      await engine.setDelta('local-only', true);
      await engine.setDelta('field', 'newer');
      final old = Replica('peer', hlc: HlcClock(nowMilliseconds: () => 1));
      final losing = old.setDelta('field', 'older');
      await engine.applyRemote(Delta([losing]));
      await engine.applyRemote(Delta([losing]));
      await engine.applyRemote(const Delta.empty());
      await flush();
      expect(events.skip(2).map((e) => e.addresses).toList(), [
        {'field'},
        {'field'},
        <String>{},
      ]);
      expect(engine.valueAt('field'), 'newer');
      old.removeDelta('deleted');
      final snapshot = Map<String, Object?>.of(old.toSnapshotJson());
      snapshot['gSets'] = {'empty': GSet('peer', crdtId: 'empty').toJson()};
      await engine.applyRemoteSnapshot(snapshot);
      await engine.applyRemoteSnapshot(snapshot);
      await flush();
      expect(events.last.origin, SyncCommitOrigin.remote);
      expect(events.last.addresses, {'field', 'deleted', 'empty'});
      expect(events[events.length - 2].addresses, events.last.addresses);
      expect(engine.valueAt('local-only'), isTrue);
      expect(engine.valueAt('empty'), isEmpty);
      expect(engine.query('deleted'), isA<DeletedField>());
      snapshot.clear();
      expect(events.last.addresses, {'field', 'deleted', 'empty'});
    },
  );

  test(
    'blocked commit emits only after adoption; rollback has no success event',
    () async {
      await engine.start();
      final events = <SyncCommitEvent>[];
      engine.commitsFor('field').listen((event) {
        events.add(event);
        expect(engine.valueAt('field'), 'committed');
      });
      storage.gate = Completer<void>();
      storage.entered = Completer<void>();
      final writing = engine.setDelta('field', 'committed');
      await storage.entered!.future;
      await flush();
      expect(engine.query('field'), isA<AbsentField>());
      expect(events, isEmpty);
      storage.gate!.complete();
      await writing;
      await flush();
      expect(events, hasLength(1));
      storage.gate = null;
      storage.entered = null;
      storage.failLocal = true;
      await expectLater(engine.setDelta('field', 'failed'), throwsStateError);
      storage.failRemote = true;
      final peer = Replica('peer')..setDelta('field', 'remote');
      await expectLater(engine.applyRemote(peer.export()), throwsStateError);
      await expectLater(
        engine.applyRemoteSnapshot(peer.toSnapshotJson()),
        throwsStateError,
      );
      await expectLater(
        engine.applyRemoteSnapshot({'version': -1}),
        throwsFormatException,
      );
      await flush();
      expect(events, hasLength(1));
      expect(engine.valueAt('field'), 'committed');
    },
  );

  test('ACK storage/send failures preserve commit events and shared failure identity', () async {
    final all = <SyncObservation>[];
    final errors = <SyncFailure>[];
    final commits = <SyncCommitEvent>[];
    engine.observations.listen(all.add);
    engine.errors.listen(errors.add);
    engine.commits.listen(commits.add);
    final first = await engine.setDelta('one', true);
    await engine.setDelta('two', true);
    transport.ids = [first.id];
    storage.failAck = true;
    await expectLater(engine.push(), throwsStateError);
    await flush();
    expect(all.last, isA<SyncPushFailure>());
    expect(errors, isEmpty);
    expect(commits, hasLength(2));
    expect((await engine.pendingSummary()).totalCount, 2);
    storage.failAck = false;
    final partial = await engine.push(force: true);
    await flush();
    expect(identical(all.last, partial), isTrue);
    expect(partial.acknowledgedIds, {first.id});
    expect(commits, hasLength(2));
    expect((await engine.pendingSummary()).totalCount, 1);
    transport.failIncomingAck = true;
    final delta = Replica('peer').setDelta('remote', 'retained');
    final envelope = DeltaEnvelope(
      senderReplicaId: 'peer',
      recipientReplicaId: 'local',
      delta: Delta([delta]),
    );
    await expectLater(engine.receiveEnvelope(envelope), throwsStateError);
    await flush();
    expect(engine.valueAt('remote'), 'retained');
    expect(commits.last.addresses, {'remote'});
    expect(errors, isEmpty); // Awaited failure belongs to its caller.
    final failed = engine.errors.first;
    transport.incomingController.add(
      envelope,
    ); // Replay commits before ACK failure.
    final failure = await failed;
    await flush();
    expect(identical(failure, errors.single), isTrue);
    expect(identical(failure, all.last), isTrue);
    expect(failure.source, SyncFailureSource.incomingDelta);
    expect(commits.where((e) => e.addresses.contains('remote')), hasLength(2));
    final streamFailure = engine.errors.first;
    transport.incomingController.addError(StateError('stream'));
    expect((await streamFailure).source, SyncFailureSource.incomingStream);
    await flush();
    expect(identical(errors.last, all.last), isTrue);
  });

  test('late/paused/throwing selective listeners preserve order and close on dispose', () async {
    await engine.start();
    await flush();
    final all = <SyncCommitEvent>[];
    final selected = <SyncCommitEvent>[];
    final lateEvents = <SyncCommitEvent>[];
    final done = Completer<void>();
    engine.commits.listen(all.add);
    final paused =
        engine.commitsFor('x').listen(selected.add, onDone: done.complete)
          ..pause();
    addTearDown(paused.cancel);
    final caught = Completer<Object>();
    late StreamSubscription<SyncCommitEvent> throwing;
    runZonedGuarded(
      () {
        throwing = engine.commitsFor('x').listen((_) {
          throw StateError('listener');
        });
      },
      (error, _) {
        if (!caught.isCompleted) caught.complete(error);
      },
    );
    await engine.setDelta('x', 1);
    await caught.future;
    await flush();
    expect(all, hasLength(1));
    final lateSubscription = engine.commits.listen(lateEvents.add);
    await flush();
    expect(lateEvents, isEmpty);
    await Future.wait([engine.setDelta('x', 2), engine.setDelta('y', 3)]);
    await flush();
    expect(all.map((e) => e.addresses).toList(), [
      {'x'},
      {'x'},
      {'y'},
    ]);
    expect(lateEvents, hasLength(2));
    expect(selected, isEmpty);
    await throwing.cancel();
    var disposed = false;
    final disposing = engine.dispose().then((_) {
      disposed = true;
    });
    await flush();
    expect(disposed, isFalse);
    paused.resume();
    await disposing.timeout(const Duration(seconds: 2));
    await done.future;
    expect(selected, hasLength(2));
    expect(identical(selected[0], all[0]), isTrue);
    expect(identical(selected[1], all[1]), isTrue);
    expect(() => engine.query('x'), throwsStateError);
    await lateSubscription.cancel();
    await expectLater(engine.commitsFor('x'), emitsDone);
    await expectLater(engine.errors, emitsDone);
    await expectLater(engine.observations, emitsDone);
  });

  test(
    'paused errors filter preserves failures and skips unrelated source events',
    () async {
      await engine.start();
      await flush();
      final errors = <SyncFailure>[];
      final all = <SyncObservation>[];
      engine.observations.listen(all.add);
      final subscription = engine.errors.listen(errors.add)..pause();
      addTearDown(subscription.cancel);
      final first = StateError('first failure');
      final second = StateError('second failure');
      await engine.setDelta('unrelated', true);
      transport.incomingController.addError(first);
      await engine.setDelta('another', true);
      transport.incomingController.addError(second);
      await flush();
      expect(errors, isEmpty);
      subscription.resume();
      await flush();
      expect(errors.map((e) => e.error).toList(), [first, second]);
      expect(all.whereType<SyncCommitEvent>(), hasLength(2));
      final failures = all.whereType<SyncFailure>().toList();
      expect(identical(errors[0], failures[0]), isTrue);
      expect(identical(errors[1], failures[1]), isTrue);
    },
  );

  test(
    'dispose drains an accepted blocked commit before closing selective stream',
    () async {
      await engine.start();
      final events = <SyncCommitEvent>[];
      final done = Completer<void>();
      engine.commitsFor('field').listen(events.add, onDone: done.complete);
      storage.gate = Completer<void>();
      storage.entered = Completer<void>();
      final writing = engine.setDelta('field', true);
      await storage.entered!.future;
      final disposing = engine.dispose();
      expect(events, isEmpty);
      storage.gate!.complete();
      await writing;
      await disposing;
      await done.future;
      expect(events.single.addresses, {'field'});
      await expectLater(engine.setDelta('later', true), throwsStateError);
    },
  );
}

class _Storage extends MemoryStorage {
  Completer<void>? gate;
  Completer<void>? entered;
  bool failLocal = false;
  bool failRemote = false;
  bool failAck = false;
  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    entered?.complete();
    await gate?.future;
    if (failLocal) throw StateError('local commit');
    await super.commit(snapshot, entries);
  }

  @override
  Future<void> commitRemote(ReplicaSnapshot snapshot) async {
    if (failRemote) throw StateError('remote commit');
    await super.commitRemote(snapshot);
  }

  @override
  Future<void> acknowledge(
    String replicaId,
    String peer,
    Iterable<String> ids,
  ) async {
    if (failAck) throw StateError('ACK storage');
    await super.acknowledge(replicaId, peer, ids);
  }
}

class _Transport
    implements
        AcknowledgingDeltaTransport,
        IncomingAcknowledgingDeltaTransport {
  final incomingController = StreamController<DeltaEnvelope>();
  List<String>? ids;
  bool failIncomingAck = false;
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => incomingController.stream;
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async =>
      DeltaAcknowledgement(
        peerReplicaId: 'peer',
        stage: DeltaAckStage.appliedAndPersisted,
        changeIds: ids ?? envelope.delta.changes.map((c) => c.id),
      );
  @override
  Future<void> acknowledge(DeltaAcknowledgement acknowledgement) async {
    if (failIncomingAck) throw StateError('ACK network');
  }
}
