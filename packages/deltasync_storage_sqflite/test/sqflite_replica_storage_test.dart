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
