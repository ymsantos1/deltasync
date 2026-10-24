import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late SqfliteReplicaStorage storage;
  late SyncEngine engine;
  String getPath() => '${directory.path}/query.sqlite';
  void open() {
    storage = SqfliteReplicaStorage(
      databaseFactory: databaseFactoryFfi,
      databasePath: getPath(),
    );
    engine = SyncEngine.withStorage(
      replica: Replica('query', hlc: HlcClock(nowMilliseconds: () => 1000)),
      storage: storage,
      transport: _Transport(),
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('deltasync-r42-');
    open();
  });
  tearDown(() async {
    await engine.dispose();
    await storage.close();
    await directory.delete(recursive: true);
  });

  test(
    'all seven bound empty kinds remain present after physical reopen',
    () async {
      final snapshot = Map<String, Object?>.of(
        Replica('query').toSnapshotJson(),
      );
      snapshot['gCounters'] = {'g': GCounter('query', crdtId: 'g').toJson()};
      snapshot['pnCounters'] = {
        'pn': PnCounter('query', crdtId: 'pn').toJson(),
      };
      snapshot['gSets'] = {'gs': GSet('query', crdtId: 'gs').toJson()};
      snapshot['twoPSets'] = {'two': TwoPSet('query', crdtId: 'two').toJson()};
      snapshot['mvRegisters'] = {
        'mv': MvRegister('query', crdtId: 'mv').toJson(),
      };
      snapshot['orSets'] = {'os': OrSet('query', crdtId: 'os').toJson()};
      snapshot['orMaps'] = {'om': OrMap('query', crdtId: 'om').toJson()};
      await storage.saveReplica(
        ReplicaSnapshot.fromReplica(Replica.fromSnapshotJson(snapshot)),
      );
      await engine.dispose();
      await storage.close();
      open();
      await engine.start();
      for (final field in ['g', 'pn', 'gs', 'two', 'mv', 'os', 'om']) {
        final result = engine.query(field) as PresentField;
        expect(result.value, engine.valueAt(field));
        expect(result.value, field == 'g' || field == 'pn' ? 0 : isEmpty);
      }
      expect(engine.query('unbound'), isA<AbsentField>());
      expect((await engine.pendingSummary()).totalCount, 0);
    },
  );

  test('typed results of eight kinds survive SQLite reopen and ACK', () async {
    await engine.batch((batch) {
      batch.setDelta('null', null);
      batch.setDelta('nested', {
        'items': [1],
      });
      batch.removeDelta('deleted');
      batch.incrementGCounter('g');
      batch.incrementPnCounter('pn');
      batch.decrementPnCounter('pn');
      batch.addGSet('gs', 'a');
      batch.addTwoPSet('two', 'a');
      batch.removeTwoPSet('two', 'a');
      batch.writeMvRegister('mv', null);
      batch.addOrSet('os', 'a');
      batch.removeOrSet('os', 'a');
      batch.addOrMapKey('om', 'a');
      batch.removeOrMapKey('om', 'a');
    });
    final pending = await storage.pending('query');
    await storage.acknowledge('query', 'peer', pending.map((e) => e.entryId));
    await engine.dispose();
    await storage.close();
    open();
    expect(() => engine.query('null'), throwsStateError);
    await engine.start();
    final before = (await storage.loadReplica('query'))!.toJson();
    expect(engine.query('missing'), isA<AbsentField>());
    expect(engine.query('deleted'), isA<DeletedField>());
    expect((engine.query('null') as PresentField).value, isNull);
    final results = [
      for (final key in ['null', 'g', 'pn', 'gs', 'two', 'mv', 'os', 'om'])
        engine.query(key) as PresentField,
    ];
    expect(results.map((r) => r.kind).toSet(), CrdtKind.values.toSet());
    expect(results.map((r) => r.value).toList(), [
      null,
      1,
      0,
      {'a'},
      <Object?>{},
      {null},
      <Object?>{},
      <String, Set<Object?>>{},
    ]);
    final nested = (engine.query('nested') as PresentField).value as Map;
    expect(() => (nested['items'] as List).add(2), throwsUnsupportedError);
    expect((await storage.loadReplica('query'))!.toJson(), before);
    expect((await engine.pendingSummary()).totalCount, 0);
    for (final key in ['missing', 'null', 'deleted']) {
      expect(engine.valueAt(key), isNull);
    }
  });

  test(
    'failed SQLite deletion preserves present null before and after reopen',
    () async {
      await engine.setDelta('field', null);
      final saved = (await storage.loadReplica('query'))!.toJson();
      final pending = [
        for (final e in await storage.pending('query')) e.toJson(),
      ];
      final database = await databaseFactoryFfi.openDatabase(
        getPath(),
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.execute('''
        CREATE TRIGGER reject_query BEFORE INSERT ON deltasync_outbox
        BEGIN SELECT RAISE(ABORT, 'query deletion failed'); END
      ''');
        await expectLater(
          engine.removeDelta('field'),
          throwsA(
            isA<DatabaseException>().having(
              (error) => error.toString(),
              'trigger',
              contains('query deletion failed'),
            ),
          ),
        );
        expect((engine.query('field') as PresentField).value, isNull);
        expect((await storage.loadReplica('query'))!.toJson(), saved);
        expect([
          for (final e in await storage.pending('query')) e.toJson(),
        ], pending);
        await engine.dispose();
        await storage.close();
        open();
        await engine.start();
        expect((engine.query('field') as PresentField).value, isNull);
        await database.execute('DROP TRIGGER reject_query');
        await engine.removeDelta('field');
        expect(engine.query('field'), isA<DeletedField>());
        await engine.dispose();
        await storage.close();
        open();
        await engine.start();
        expect(engine.query('field'), isA<DeletedField>());
      } finally {
        await database.close();
      }
    },
  );
}

class _Transport implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
}
