import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  SyncEngine open(MemoryStorage storage) => SyncEngine.withStorage(
    replica: Replica('decoder'),
    storage: storage,
    transport: _Transport(),
  );

  test(
    'conversion failures do not change snapshot, clocks, outbox or events',
    () async {
      final storage = MemoryStorage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      await engine.setDelta('profile', {
        'name': 'Ada',
        'items': [1],
      });
      await engine.setDelta('invalid', {'name': 42});
      final events = <Object>[];
      final commits = engine.commits.listen(events.add);
      final errors = engine.errors.listen(events.add);
      addTearDown(commits.cancel);
      addTearDown(errors.cancel);
      final before = engine.replica.toSnapshotJson();
      final saved = (await storage.loadReplica('decoder'))!.toJson();
      final pending = [
        for (final e in await storage.pending('decoder')) e.toJson(),
      ];
      final field = engine.query('profile') as PresentField;
      expect(field.decode(_name), 'Ada');
      expect(
        () => (engine.query('invalid') as PresentField).decode(_name),
        throwsFormatException,
      );
      expect(
        () => field.decode((raw) => ((raw as Map)['items'] as List).add(2)),
        throwsUnsupportedError,
      );
      final failure = StateError('decoder failure');
      expect(
        () => field.decode<Object?>((value) => throw failure),
        throwsA(same(failure)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      expect(engine.replica.toSnapshotJson(), before);
      expect((await storage.loadReplica('decoder'))!.toJson(), saved);
      expect([
        for (final e in await storage.pending('decoder')) e.toJson(),
      ], pending);
      // A query error does not undo a previously successful local commit.
      await expectLater(engine.push(), throwsStateError);
      expect(field.decode(_name), 'Ada');
      await engine.setDelta('another', true);
      expect(engine.valueAt('another'), isTrue);
    },
  );

  test('query lifecycle is enforced before decoder; detached result survives dispose', () async {
    final storage = _GatedStorage();
    final engine = open(storage);
    var calls = 0;
    String read() => (engine.query('profile') as PresentField).decode((value) {
      calls++;
      return _name(value);
    });
    expect(read, throwsStateError);
    final starting = engine.start();
    expect(read, throwsStateError);
    expect(calls, 0);
    storage.gate.complete();
    await starting;
    await engine.setDelta('profile', {'name': 'Ada'});
    expect(read(), 'Ada');
    expect(calls, 1);
    final retained = engine.query('profile') as PresentField;
    await engine.dispose();
    expect(read, throwsStateError);
    expect(calls, 1);
    expect(retained.decode(_name), 'Ada');
  });

  test(
    'batch conversion reads candidate; uncaught decoder error aborts batch',
    () async {
      final storage = MemoryStorage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      await engine.setDelta('profile', {'name': 'Ada'});
      final before = engine.replica.toSnapshotJson();
      await expectLater(
        engine.batch((batch) {
          batch.setDelta('profile', {'name': 42});
          (batch.query('profile') as PresentField).decode(_name);
        }),
        throwsFormatException,
      );
      expect(engine.replica.toSnapshotJson(), before);
      expect((await engine.pendingSummary()).totalCount, 1);
      late PresentField retained;
      late LocalBatch expired;
      await engine.batch((batch) {
        expired = batch;
        batch.setDelta('profile', {'name': 'Grace'});
        retained = batch.query('profile') as PresentField;
        expect(retained.decode(_name), 'Grace');
      });
      expect(() => expired.query('profile'), throwsStateError);
      expect(retained.decode(_name), 'Grace');
      expect((engine.query('profile') as PresentField).decode(_name), 'Grace');
    },
  );
}

String _name(Object? value) {
  if (value is! Map || value['name'] is! String) {
    throw FormatException('Invalid profile name');
  }
  return value['name'] as String;
}

class _GatedStorage extends MemoryStorage {
  final gate = Completer<void>();
  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) async {
    await gate.future;
    return super.loadReplica(replicaId);
  }
}

class _Transport implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async =>
      throw StateError('offline');
}
