import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  SyncEngine open(_Storage storage, [_Transport? transport]) =>
      SyncEngine.withStorage(
        replica: Replica('batch', hlc: HlcClock(nowMilliseconds: () => 1000)),
        storage: storage,
        transport: transport ?? _Transport(),
      );

  test(
    'one batch edits all eight types with one commit and notification',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      final events = <SyncCommitEvent>[];
      final subscription = engine.commits.listen(events.add);
      addTearDown(subscription.cancel);
      late LocalBatch escaped;
      final delta = await engine.batch((batch) {
        escaped = batch;
        batch.setDelta('lww', {
          'items': [1],
        });
        expect(batch.valueAt('lww'), {
          'items': [1],
        });
        final value = batch.valueAt('lww') as Map;
        expect(() => (value['items'] as List).clear(), throwsUnsupportedError);
        batch.removeDelta('lww');
        batch.setDelta('null', null);
        batch.incrementGCounter('g', 2);
        batch.incrementPnCounter('pn', 4);
        batch.decrementPnCounter('pn');
        batch.addGSet('gs', 'a');
        batch.addAllGSet('gs', ['b']);
        batch.addTwoPSet('two', 'a');
        batch.addAllTwoPSet('two', ['b', 'c']);
        batch.removeTwoPSet('two', 'a');
        batch.removeAllTwoPSet('two', ['b']);
        batch.writeMvRegister('mv', 'before');
        batch.writeMvRegister('mv', 'after');
        batch.addOrSet('os', 'old');
        batch.removeOrSet('os', 'old');
        batch.addOrSet('os', 'new');
        batch.addOrMapKey('om', 'old');
        batch.addOrMapValue('om', 'old', 'x');
        batch.removeOrMapKey('om', 'old');
        batch.addOrMapKey('om', 'new');
        batch.addOrMapValue('om', 'new', 'value');
      });
      await Future<void>.delayed(Duration.zero);
      expect(delta.changes.map((e) => e.kind).toSet(), CrdtKind.values.toSet());
      expect(delta.changes, hasLength(22));
      expect(storage.commits, 1);
      expect(events, hasLength(1));
      expect(events.single.origin, SyncCommitOrigin.local);
      expect(
        (await engine.pendingSummary()).pendingCount,
        delta.changes.length,
      );
      expect(
        (await storage.pending('batch')).map((e) => e.entryId),
        delta.changes.map((e) => e.id),
      );
      expect(engine.valueAt('g'), 2);
      expect(engine.valueAt('pn'), 3);
      expect(engine.valueAt('gs'), {'a', 'b'});
      expect(engine.valueAt('two'), {'c'});
      expect(engine.valueAt('mv'), {'after'});
      expect(engine.valueAt('os'), {'new'});
      expect(engine.valueAt('om'), {
        'new': {'value'},
      });
      expect(() => escaped.setDelta('late', true), throwsStateError);
      expect(() => escaped.valueAt('g'), throwsStateError);
      expect(() => delta.changes.clear(), throwsUnsupportedError);
    },
  );

  test(
    'empty, thrown, failed and caught edits all abort without consuming IDs',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      await engine.setDelta('saved', 1);
      final before = engine.replica.toSnapshotJson();
      final entries = (await storage.pending('batch'))
          .map((e) => e.toJson())
          .toList();
      await expectLater(engine.batch((_) {}), throwsStateError);
      await expectLater(
        engine.batch((batch) {
          batch.setDelta('partial', 2);
          batch.incrementGCounter('g');
          throw StateError('application rejected');
        }),
        throwsStateError,
      );
      await expectLater(
        engine.batch((batch) {
          batch.setDelta('partial', 2);
          batch.incrementGCounter('g', -1);
        }),
        throwsArgumentError,
      );
      await expectLater(
        engine.batch((batch) {
          batch.setDelta('partial', 2);
          try {
            batch.incrementGCounter('g', -1);
          } on ArgumentError {
            /* Poison persists. */
          }
        }),
        throwsStateError,
      );
      expect(engine.replica.toSnapshotJson(), before);
      expect(
        (await storage.pending('batch')).map((e) => e.toJson()).toList(),
        entries,
      );
      expect(storage.commits, 1);
      final next = await engine.setDelta('next', 3);
      expect(next.id, 'batch:delta:2');
      expect((await engine.incrementGCounter('g')).dot!.counter, 1);
    },
  );

  test(
    'storage failure leaves state, IDs and outbox untouched; retry succeeds',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      await engine.setDelta('saved', 1);
      final before = engine.replica.toSnapshotJson();
      storage.fail = true;
      void editAllTypes(LocalBatch batch) {
        batch.setDelta('first', 2);
        batch.incrementGCounter('g');
        batch.decrementPnCounter('pn');
        batch.addGSet('gs', 'a');
        batch.addTwoPSet('two', 'a');
        batch.writeMvRegister('mv', 'a');
        batch.addOrSet('os', 'a');
        batch.addOrMapKey('om', 'key');
      }

      await expectLater(engine.batch(editAllTypes), throwsStateError);
      expect(engine.replica.toSnapshotJson(), before);
      expect((await engine.pendingSummary()).totalCount, 1);
      storage.fail = false;
      final result = await engine.batch(editAllTypes);
      expect(result.changes.first.id, 'batch:delta:2');
      expect(
        result.changes.map((e) => e.kind).toSet(),
        CrdtKind.values.toSet(),
      );
      for (final change in result.changes.skip(1)) {
        expect((change.toJson()['dot'] as Map)['counter'], 1);
      }
      expect(result.changes.map((e) => e.id).toSet(), hasLength(8));
      expect((await engine.pendingSummary()).totalCount, 9);
    },
  );

  test(
    'async callback is rejected immediately and its continuation cannot edit',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      final resume = Completer<void>();
      final finished = Completer<void>();
      late LocalBatch escaped;
      await expectLater(
        engine.batch((batch) async {
          escaped = batch;
          batch.setDelta('first', 1);
          await resume.future;
          try {
            batch.setDelta('late', 2);
          } finally {
            finished.complete();
          }
        }),
        throwsArgumentError,
      );
      expect(() => escaped.setDelta('outside', 3), throwsStateError);
      resume.complete();
      await finished.future;
      await Future<void>.delayed(Duration.zero);
      expect(storage.commits, 0);
      expect((await engine.pendingSummary()).totalCount, 0);
      expect(engine.valueAt('late'), isNull);
      expect((await engine.setDelta('valid', true)).id, 'batch:delta:1');
    },
  );

  test('rejected async continuation cannot call the engine directly', () async {
    final storage = _Storage();
    final engine = open(storage);
    addTearDown(engine.dispose);
    final resume = Completer<void>();
    final finished = Completer<void>();
    await expectLater(
      engine.batch((batch) async {
        batch.setDelta('first', 1);
        await resume.future;
        try {
          engine.setDelta('escape', 2);
        } finally {
          finished.complete();
        }
      }),
      throwsArgumentError,
    );
    resume.complete();
    await finished.future;
    await Future<void>.delayed(Duration.zero);
    expect(storage.commits, 0);
    expect((await engine.pendingSummary()).totalCount, 0);
    expect(engine.valueAt('escape'), isNull);
  });

  test(
    'nested engine writes, batches, push, start and dispose abort outer batch',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      for (final call in <void Function()>[
        () {
          engine.setDelta('escape', true);
        },
        () {
          engine.batch((batch) => batch.setDelta('nested', 1));
        },
        () {
          engine.push();
        },
        () {
          engine.start();
        },
        () {
          engine.dispose();
        },
        () {
          engine.pendingSummary();
        },
      ]) {
        await expectLater(
          engine.batch((batch) {
            batch.setDelta('first', 1);
            expect(call, throwsStateError);
          }),
          throwsStateError,
        );
      }
      expect(storage.commits, 0);
      expect((await engine.pendingSummary()).totalCount, 0);
    },
  );

  test(
    'editor closes before commit completes and concurrent edit serializes',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      await engine.start();
      storage.gate = Completer<void>();
      storage.entered = Completer<void>();
      late LocalBatch escaped;
      final first = engine.batch((batch) {
        escaped = batch;
        batch.setDelta('first', 1);
        batch.setDelta('second', 2);
      });
      await storage.entered!.future;
      expect(engine.valueAt('first'), isNull);
      expect(() => escaped.setDelta('escape', true), throwsStateError);
      final second = engine.setDelta('third', 3);
      storage.gate!.complete();
      await first;
      storage.gate = null;
      storage.entered = null;
      expect((await second).id, 'batch:delta:3');
      expect(storage.commits, 2);
      expect(engine.valueAt('first'), 1);
      expect(engine.valueAt('second'), 2);
      expect(engine.valueAt('third'), 3);
      await engine.dispose();
      await expectLater(
        engine.batch((batch) => batch.setDelta('late', 1)),
        throwsStateError,
      );
    },
  );

  test(
    'batch delivery retains per-change partial ACK and failed-network edits',
    () async {
      final storage = _Storage();
      final transport = _Transport();
      final engine = open(storage, transport);
      addTearDown(engine.dispose);
      final delta = await engine.batch((batch) {
        batch.setDelta('name', 'Ada');
        batch.incrementGCounter('edits');
      });
      transport.fail = true;
      await expectLater(engine.push(), throwsStateError);
      expect((await engine.pendingSummary()).sentCount, 2);
      await engine.batch((batch) => batch.setDelta('offline', true));
      transport.fail = false;
      transport.ids = [delta.changes.first.id];
      await engine.push(force: true);
      expect((await engine.pendingSummary()).totalCount, 2);
      expect(engine.valueAt('name'), 'Ada');
    },
  );
}

class _Storage extends MemoryStorage {
  int commits = 0;
  bool fail = false;
  Completer<void>? gate;
  Completer<void>? entered;
  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    if (!(entered?.isCompleted ?? true)) entered!.complete();
    await gate?.future;
    if (fail) throw StateError('injected commit failure');
    await super.commit(snapshot, entries);
    commits++;
  }
}

class _Transport implements AcknowledgingDeltaTransport {
  bool fail = false;
  List<String>? ids;
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
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: ids ?? envelope.delta.changes.map((e) => e.id),
    );
  }
}
