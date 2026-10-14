import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  SyncEngine open(ReplicaStorage storage) => SyncEngine.withStorage(
    replica: Replica('query'),
    storage: storage,
    transport: _OfflineTransport(),
  );

  test(
    'queries cover eight kinds after restore and during network failure',
    () async {
      final storage = MemoryStorage();
      var engine = open(storage);
      await engine.setDelta('lww', {
        'items': [1],
      });
      await engine.incrementGCounter('g', 2);
      await engine.decrementPnCounter('pn', 3);
      await engine.addGSet('gs', 'a');
      await engine.addTwoPSet('two', 'a');
      await engine.writeMvRegister('mv', 'a');
      await engine.addOrSet('os', 'a');
      await engine.addOrMapKey('om', 'key');
      await engine.addOrMapValue('om', 'key', 'a');
      final expected = <String, Object?>{
        'lww': {
          'items': [1],
        },
        'g': 2,
        'pn': -3,
        'gs': {'a'},
        'two': {'a'},
        'mv': {'a'},
        'os': {'a'},
        'om': {
          'key': {'a'},
        },
      };
      await expectLater(engine.push(), throwsStateError);
      for (final entry in expected.entries) {
        expect(engine.valueAt(entry.key), entry.value);
      }
      await engine.dispose();
      engine = open(storage);
      addTearDown(engine.dispose);
      await engine.start();
      for (final entry in expected.entries) {
        expect(engine.valueAt(entry.key), entry.value);
      }
      final value = engine.valueAt('lww') as Map;
      expect(() => (value['items'] as List).clear(), throwsUnsupportedError);
      await engine.setDelta('lww', 'new');
      expect(value, {
        'items': [1],
      });
      expect(engine.valueAt('lww'), 'new');
      await engine.setDelta('null', null);
      await engine.removeDelta('deleted');
      expect(engine.valueAt('absent'), isNull);
      expect(engine.valueAt('null'), isNull);
      expect(engine.valueAt('deleted'), isNull);
    },
  );

  test(
    'queries reject created, starting, failed start and disposed engines',
    () async {
      final storage = _GatedStorage()..loading = Completer<void>();
      final engine = open(storage);
      expect(() => engine.valueAt('x'), throwsStateError);
      final starting = engine.start();
      expect(engine.lifecycle, SyncEngineLifecycle.starting);
      expect(() => engine.valueAt('x'), throwsStateError);
      storage.loading!.completeError(StateError('load failed'));
      await expectLater(starting, throwsStateError);
      expect(() => engine.valueAt('x'), throwsStateError);
      storage.loading = null;
      await engine.start();
      expect(engine.valueAt('x'), isNull);
      await engine.dispose();
      expect(() => engine.valueAt('x'), throwsStateError);
    },
  );

  test('query sees adopted state during commit and rollback', () async {
    final storage = _GatedStorage();
    final engine = open(storage);
    addTearDown(engine.dispose);
    await engine.setDelta('x', 'old');
    storage.committing = Completer<void>();
    storage.entered = Completer<void>();
    final writing = engine.setDelta('x', 'new');
    await storage.entered!.future;
    expect(engine.valueAt('x'), 'old');
    storage.committing!.complete();
    await writing;
    expect(engine.valueAt('x'), 'new');
    storage.committing = null;
    storage.entered = null;
    storage.failCommit = true;
    await expectLater(engine.setDelta('x', 'failed'), throwsStateError);
    expect(engine.valueAt('x'), 'new');
  });
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

class _GatedStorage extends MemoryStorage {
  Completer<void>? loading;
  Completer<void>? committing;
  Completer<void>? entered;
  bool failCommit = false;
  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) async {
    await loading?.future;
    return super.loadReplica(replicaId);
  }

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    entered?.complete();
    await committing?.future;
    if (failCommit) throw StateError('commit failed');
    await super.commit(snapshot, entries);
  }
}
