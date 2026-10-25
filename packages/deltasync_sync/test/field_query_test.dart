import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  SyncEngine open(_Storage storage) => SyncEngine.withStorage(
    replica: Replica('field-query', hlc: HlcClock(nowMilliseconds: () => 1000)),
    storage: storage,
    transport: _OfflineTransport(),
  );

  test(
    'typed query obeys created/starting/failed/started/disposed lifecycle',
    () async {
      final storage = _Storage()..loadGate = Completer<void>();
      final engine = open(storage);
      expect(() => engine.query('field'), throwsStateError);
      final starting = engine.start();
      expect(() => engine.query('field'), throwsStateError);
      storage.loadGate!.completeError(StateError('load failed'));
      await expectLater(starting, throwsStateError);
      expect(() => engine.query('field'), throwsStateError);
      storage.loadGate = null;
      await engine.start();
      expect(engine.query('field'), isA<AbsentField>());
      await engine.dispose();
      expect(() => engine.query('field'), throwsStateError);
    },
  );

  test(
    'engine sees adopted state during commit; batch query sees candidate only',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      await engine.setDelta('field', null);
      final old = engine.query('field') as PresentField;
      storage.gate = Completer<void>();
      storage.entered = Completer<void>();
      late LocalBatch escaped;
      final writing = engine.batch((batch) {
        escaped = batch;
        batch.removeDelta('field');
        batch.setDelta('new', {
          'items': [1],
        });
        expect(batch.query('field'), isA<DeletedField>());
        expect((batch.query('new') as PresentField).value, {
          'items': [1],
        });
      });
      await storage.entered!.future;
      expect(engine.query('field'), isA<PresentField>());
      expect((engine.query('field') as PresentField).value, isNull);
      expect(engine.query('new'), isA<AbsentField>());
      expect(() => escaped.query('new'), throwsStateError);
      storage.gate!.complete();
      await writing;
      expect(engine.query('field'), isA<DeletedField>());
      expect(engine.query('new'), isA<PresentField>());
      expect(old.value, isNull);
      storage.gate = null;
      storage.entered = null;
      storage.fail = true;
      await expectLater(engine.setDelta('field', 'failed'), throwsStateError);
      expect(engine.query('field'), isA<DeletedField>());
      expect((await engine.pendingSummary()).totalCount, 3);
    },
  );

  test(
    'queries of eight types restore and remain independent of outbox/ACK',
    () async {
      final storage = _Storage();
      var engine = open(storage);
      await engine.batch((batch) {
        batch.setDelta('null', null);
        batch.removeDelta('deleted');
        batch.incrementGCounter('g');
        batch.incrementPnCounter('pn');
        batch.decrementPnCounter('pn');
        batch.addGSet('gs', {
          'items': [1],
        });
        batch.addTwoPSet('two', 'a');
        batch.removeTwoPSet('two', 'a');
        batch.writeMvRegister('mv', null);
        batch.addOrSet('os', 'a');
        batch.removeOrSet('os', 'a');
        batch.addOrMapKey('om', 'key');
        batch.removeOrMapKey('om', 'key');
      });
      await expectLater(engine.push(), throwsStateError);
      final entries = await storage.pending('field-query');
      await storage.acknowledge(
        'field-query',
        'peer',
        entries.map((e) => e.entryId),
      );
      expect((await engine.pendingSummary()).totalCount, 0);
      expect(engine.query('deleted'), isA<DeletedField>());
      await engine.dispose();
      engine = open(storage);
      addTearDown(engine.dispose);
      await engine.start();
      expect(engine.query('unknown'), isA<AbsentField>());
      expect((engine.query('null') as PresentField).value, isNull);
      expect(engine.query('deleted'), isA<DeletedField>());
      for (final field in ['g', 'pn', 'gs', 'two', 'mv', 'os', 'om']) {
        final result = engine.query(field) as PresentField;
        expect(result.value, engine.valueAt(field));
      }
      final snapshot = engine.replica.toSnapshotJson();
      final result = engine.query('gs') as PresentField;
      expect(
        () => ((result.value as Set).single as Map)['items'] = [],
        throwsUnsupportedError,
      );
      expect(engine.replica.toSnapshotJson(), snapshot);
      expect((await engine.pendingSummary()).totalCount, 0);
      expect(engine.valueAt('null'), isNull);
      expect(engine.valueAt('deleted'), isNull);
      expect(engine.valueAt('unknown'), isNull);
    },
  );
}

class _Storage extends MemoryStorage {
  Completer<void>? loadGate;
  Completer<void>? gate;
  Completer<void>? entered;
  bool fail = false;
  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) async {
    await loadGate?.future;
    return super.loadReplica(replicaId);
  }

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    entered?.complete();
    await gate?.future;
    if (fail) throw StateError('commit failed');
    await super.commit(snapshot, entries);
  }
}

class _OfflineTransport implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) =>
      Future.error(StateError('offline'));
}
