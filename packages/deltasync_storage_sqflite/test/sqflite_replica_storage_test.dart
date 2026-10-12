import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:deltasync_storage_testing/deltasync_storage_testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  replicaStorageContractTests(name: 'SQLite FFI', fixture: _SqliteFixture());

  group('SqfliteReplicaStorage', () {
    test(
      'conflicting commit leaves snapshot and sent outbox intact after reopen',
      () async {
        final directory = await Directory.systemTemp.createTemp('deltasync-');
        addTearDown(() => directory.delete(recursive: true));
        final path = '${directory.path}/conflict.sqlite';
        final storage = SqfliteReplicaStorage(
          databaseFactory: databaseFactoryFfi,
          databasePath: path,
        );
        final original = Replica(
          'durable-device',
          hlc: HlcClock(nowMilliseconds: () => 100),
        );
        final oldChange = original.setDelta('name', 'old');
        await storage.commit(ReplicaSnapshot.fromReplica(original), [
          OutboxEntry(delta: Delta([oldChange]), recipientPeerId: 'peer-a'),
        ]);
        await storage.markSent(original.id, 'peer-a', [oldChange.id]);
        final oldSnapshot = (await storage.loadReplica(original.id))!.toJson();
        final oldEntry = (await storage.pending(original.id)).single.toJson();

        final divergent = Replica(
          'durable-device',
          hlc: HlcClock(nowMilliseconds: () => 100),
        );
        final newChange = divergent.setDelta('name', 'new');
        final extraChange = divergent.setDelta('extra', true);
        expect(newChange.id, oldChange.id);
        await expectLater(
          storage.commit(ReplicaSnapshot.fromReplica(divergent), [
            OutboxEntry(delta: Delta([extraChange]), recipientPeerId: 'peer-a'),
            OutboxEntry(delta: Delta([newChange]), recipientPeerId: 'peer-a'),
          ]),
          throwsFormatException,
        );
        await storage.close();

        final reopened = SqfliteReplicaStorage(
          databaseFactory: databaseFactoryFfi,
          databasePath: path,
        );
        final snapshot = (await reopened.loadReplica(original.id))!;
        expect(snapshot.toJson(), oldSnapshot);
        expect(Replica.fromSnapshotJson(snapshot.snapshot!).state.values, {
          'name': 'old',
        });
        final pending = await reopened.pending(original.id);
        expect(pending, hasLength(1));
        expect(pending.single.toJson(), oldEntry);
        await reopened.close();
      },
    );

    test('reopens database and rejects a newer schema version', () async {
      final directory = await Directory.systemTemp.createTemp('deltasync-');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/replica.sqlite';
      final replica = Replica('durable-device')..setDelta('name', 'Ada');
      final storage = SqfliteReplicaStorage(
        databaseFactory: databaseFactoryFfi,
        databasePath: path,
      );

      await storage.saveReplica(ReplicaSnapshot.fromReplica(replica));
      await storage.close();
      final reopened = SqfliteReplicaStorage(
        databaseFactory: databaseFactoryFfi,
        databasePath: path,
      );
      final loaded = await reopened.loadReplica(replica.id);
      expect(loaded!.replicaId, replica.id);
      expect(Replica.fromSnapshotJson(loaded.snapshot!).state.values, {
        'name': 'Ada',
      });
      await reopened.close();

      final newer = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 2),
      );
      await newer.close();
      final incompatible = SqfliteReplicaStorage(
        databaseFactory: databaseFactoryFfi,
        databasePath: path,
      );
      await expectLater(
        incompatible.loadReplica(replica.id),
        throwsA(isA<FormatException>()),
      );
      final preserved = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 2),
      );
      expect(await preserved.query('deltasync_snapshots'), hasLength(1));
      await preserved.close();
    });
  });
}

class _SqliteFixture implements ReplicaStorageContractFixture {
  String _newPath() {
    final directory = Directory.systemTemp.createTempSync(
      'deltasync-contract-',
    );
    addTearDown(() => directory.delete(recursive: true));
    return '${directory.path}/contract.sqlite';
  }

  @override
  ReplicaStorage createStorage() => SqfliteReplicaStorage(
    databaseFactory: databaseFactoryFfi,
    databasePath: _newPath(),
  );

  @override
  ReplicaStorage createStorageWithCommitFailure() =>
      _FailOnOutboxInsertStorage(_newPath());
}

class _FailOnOutboxInsertStorage extends SqfliteReplicaStorage {
  _FailOnOutboxInsertStorage(String path)
    : super(databaseFactory: databaseFactoryFfi, databasePath: path);

  bool _triggerInstalled = false;

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    await super.enqueue(entry);
    if (_triggerInstalled) return;
    _triggerInstalled = true;
    final database = await databaseFactoryFfi.openDatabase(databasePath);
    await database.execute('''
      CREATE TRIGGER reject_outbox_insert
      BEFORE INSERT ON deltasync_outbox
      BEGIN SELECT RAISE(ABORT, 'injected commit failure'); END
    ''');
  }
}
