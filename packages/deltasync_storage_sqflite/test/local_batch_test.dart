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
  Future<String> path() async {
    final directory = await Directory.systemTemp.createTemp('deltasync-batch-');
    addTearDown(() => directory.delete(recursive: true));
    return '${directory.path}/batch.sqlite';
  }

  SyncEngine engine(_Storage storage, [_Transport? transport]) =>
      SyncEngine.withStorage(
        replica: Replica(
          'durable-batch',
          hlc: HlcClock(nowMilliseconds: () => 1000),
        ),
        storage: storage,
        transport: transport ?? _Transport(),
      );

  test('mutator/callback failures never write partial SQLite state', () async {
    final storage = _Storage(await path());
    var local = engine(storage);
    await local.start();
    final before = local.replica.toSnapshotJson();
    await expectLater(
      local.batch((batch) {
        batch.setDelta('name', 'partial');
        batch.incrementGCounter('edits');
        batch.addGSet('invalid', DateTime.utc(2024));
      }),
      throwsArgumentError,
    );
    await expectLater(
      local.batch((batch) {
        batch.setDelta('name', 'partial');
        throw StateError('abort');
      }),
      throwsStateError,
    );
    expect(storage.commitAttempts, 0);
    expect(local.replica.toSnapshotJson(), before);
    expect((await storage.loadReplica('durable-batch'))!.snapshot, before);
    expect((await storage.pendingSummary('durable-batch')).totalCount, 0);
    await local.dispose();
    await storage.close();
    local = engine(storage);
    await local.start();
    expect(local.valueAt('name'), isNull);
    expect((await local.setDelta('valid', true)).id, 'durable-batch:delta:1');
    expect((await local.incrementGCounter('edits')).dot!.counter, 1);
    await local.dispose();
    await storage.close();
  });

  test(
    'SQL failure on second insertion rolls back snapshot and complete outbox',
    () async {
      final file = await path();
      final storage = _Storage(file);
      var local = engine(storage);
      final saved = await local.setDelta('saved', true);
      await storage.markSent('durable-batch', 'peer', [saved.id]);
      final before = local.replica.toSnapshotJson();
      final oldEntry = (await storage.pending('durable-batch')).single.toJson();
      final database = await databaseFactoryFfi.openDatabase(file);
      await database.execute('''
      CREATE TRIGGER fail_second_batch_change BEFORE INSERT ON deltasync_outbox
      WHEN NEW.entry_id = 'durable-batch:delta:3'
      BEGIN SELECT RAISE(ABORT, 'fail after first entry and snapshot'); END
    ''');
      await expectLater(
        local.batch((batch) {
          batch.setDelta('first', 1);
          batch.setDelta('second', 2);
        }),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'fail after first entry and snapshot',
            ),
          ),
        ),
      );
      expect(storage.commitAttempts, 2);
      expect(local.replica.toSnapshotJson(), before);
      expect((await storage.loadReplica('durable-batch'))!.snapshot, before);
      expect(
        (await storage.pending('durable-batch')).single.toJson(),
        oldEntry,
      );
      await local.dispose();
      await storage.close();

      local = engine(storage);
      await local.start();
      expect(local.valueAt('first'), isNull);
      expect(
        (await storage.pending('durable-batch')).single.toJson(),
        oldEntry,
      );
      final reopened = await databaseFactoryFfi.openDatabase(file);
      await reopened.execute('DROP TRIGGER fail_second_batch_change');
      final result = await local.batch((batch) {
        batch.setDelta('first', 1);
        batch.setDelta('second', 2);
      });
      expect(result.changes.map((e) => e.id), [
        'durable-batch:delta:2',
        'durable-batch:delta:3',
      ]);
      expect((await local.pendingSummary()).totalCount, 3);
      await local.dispose();
      await storage.close();
    },
  );

  test(
    'eight-type batch reopens intact; partial ACK retains other batch entries',
    () async {
      final storage = _Storage(await path());
      final transport = _Transport();
      var local = engine(storage, transport);
      final delta = await local.batch((batch) {
        batch.setDelta('title', 'Ada');
        batch.incrementGCounter('g', 2);
        batch.decrementPnCounter('pn', 3);
        batch.addGSet('gs', 'a');
        batch.addTwoPSet('two', 'a');
        batch.writeMvRegister('mv', 'a');
        batch.addOrSet('os', 'a');
        batch.addOrMapKey('om', 'key');
      });
      expect(storage.commitAttempts, 1);
      expect(delta.changes.map((e) => e.kind).toSet(), CrdtKind.values.toSet());
      final snapshot = local.replica.toSnapshotJson();
      final ids = delta.changes.map((e) => e.id).toSet();
      await local.dispose();
      await storage.close();
      local = engine(storage, transport);
      await local.start();
      expect(
        (await storage.pending('durable-batch')).map((e) => e.entryId).toSet(),
        ids,
      );
      expect(local.valueAt('title'), 'Ada');
      expect(local.valueAt('g'), 2);
      expect(local.valueAt('pn'), -3);
      expect(local.valueAt('gs'), {'a'});
      expect(local.valueAt('two'), {'a'});
      expect(local.valueAt('mv'), {'a'});
      expect(local.valueAt('os'), {'a'});
      expect(local.valueAt('om'), {'key': <Object?>{}});
      // Normal replay may advance HLC; all other state/metadata is preserved.
      expect(
        Map.of(local.replica.toSnapshotJson())..remove('hlc'),
        Map.of(snapshot)..remove('hlc'),
      );
      transport.ids = [delta.changes.first.id];
      await local.push(force: true);
      await local.dispose();
      await storage.close();
      local = engine(storage);
      await local.start();
      expect((await local.pendingSummary()).sentCount, 7);
      expect(
        (await storage.pending('durable-batch')).map((e) => e.entryId).toSet(),
        ids.difference(transport.ids!.toSet()),
      );
      expect(local.valueAt('title'), 'Ada');
      await local.dispose();
      await storage.close();
    },
  );
}

class _Storage extends SqfliteReplicaStorage {
  _Storage(String path)
    : super(databaseFactory: databaseFactoryFfi, databasePath: path);
  int commitAttempts = 0;
  @override
  Future<void> commit(ReplicaSnapshot snapshot, Iterable<OutboxEntry> entries) {
    commitAttempts++;
    return super.commit(snapshot, entries);
  }
}

class _Transport implements AcknowledgingDeltaTransport {
  List<String>? ids;
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async =>
      DeltaAcknowledgement(
        peerReplicaId: peerReplicaId,
        stage: DeltaAckStage.appliedAndPersisted,
        changeIds: ids ?? envelope.delta.changes.map((e) => e.id),
      );
}
