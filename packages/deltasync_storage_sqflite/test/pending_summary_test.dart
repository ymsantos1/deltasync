import 'dart:convert';
import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfi, sqfliteFfiInit;
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();
  Future<String> path() async {
    final directory = await Directory.systemTemp.createTemp(
      'deltasync-summary-',
    );
    addTearDown(() => directory.delete(recursive: true));
    return '${directory.path}/summary.sqlite';
  }

  SqfliteReplicaStorage open(String path, [DatabaseFactory? factory]) =>
      SqfliteReplicaStorage(
        databaseFactory: factory ?? databaseFactoryFfi,
        databasePath: path,
      );

  test(
    'summary survives reopen, sent state, partial ACK and another peer',
    () async {
      final file = await path();
      var storage = open(file);
      final replica = Replica('durable-summary');
      final changes = [
        replica.setDelta('a', 1),
        replica.incrementGCounter('b'),
      ];
      await storage.commit(ReplicaSnapshot.fromReplica(replica), [
        for (final peer in ['peer-a', 'peer-b'])
          for (final change in changes)
            OutboxEntry(delta: Delta([change]), recipientPeerId: peer),
      ]);
      await storage.markSent(replica.id, 'peer-a', changes.map((e) => e.id));
      await storage.close();
      storage = open(file);
      expect((await storage.pendingSummary(replica.id)).totalCount, 4);
      expect(
        (await storage.pendingSummary(
          replica.id,
          recipientPeerId: 'peer-a',
        )).sentCount,
        2,
      );
      await storage.acknowledge(replica.id, 'peer-a', [changes.first.id]);
      await storage.close();
      storage = open(file);
      final summary = await storage.pendingSummary(replica.id);
      expect([summary.pendingCount, summary.sentCount], [2, 1]);
      expect(
        (await storage.pendingSummary(
          replica.id,
          recipientPeerId: 'peer-b',
        )).pendingCount,
        2,
      );
      expect(
        (await storage.loadReplica(replica.id))!.snapshot,
        replica.toSnapshotJson(),
      );
      await storage.close();
    },
  );

  for (final noJson in [false, true]) {
    test(
      'summary ${noJson ? "compatibility fallback" : "SQL aggregation"} does not decode deltas',
      () async {
        final file = await path();
        final seeded = open(file);
        final change = Replica('metadata').setDelta('field', 'payload');
        await seeded.enqueue(
          OutboxEntry(delta: Delta([change]), recipientPeerId: 'peer'),
        );
        await seeded.close();
        final database = await databaseFactoryFfi.openDatabase(file);
        final original =
            (await database.query('deltasync_outbox')).single['payload']!
                as String;
        final json = jsonDecode(original) as Map<String, dynamic>;
        json['delta'] = {'not': 'a valid delta'};
        await database.update('deltasync_outbox', {
          'payload': jsonEncode(json),
        });
        await database.close();

        final factory = _Factory(noJson: noJson);
        final storage = open(file, factory);
        expect((await storage.pendingSummary('metadata')).pendingCount, 1);
        expect(factory.payloadRows, noJson ? 1 : 0);
        expect(factory.aggregateRows, noJson ? 0 : 1);
        await expectLater(storage.pending('metadata'), throwsFormatException);
        await storage.close();
      },
    );
  }

  test(
    'summary ignores confirmed metadata but rejects unknown or missing status',
    () async {
      final file = await path();
      final storage = open(file);
      final change = Replica('metadata').setDelta('field', true);
      await storage.enqueue(
        OutboxEntry(delta: Delta([change]), recipientPeerId: 'peer'),
      );
      final database = await databaseFactoryFfi.openDatabase(file);
      final json =
          jsonDecode(
                (await database.query('deltasync_outbox')).single['payload']!
                    as String,
              )
              as Map;
      json['status'] = 'confirmed';
      await database.update('deltasync_outbox', {'payload': jsonEncode(json)});
      expect((await storage.pendingSummary('metadata')).totalCount, 0);
      expect(await database.query('deltasync_outbox'), hasLength(1));
      for (final value in ['unknown', null]) {
        json['status'] = value;
        await database.update('deltasync_outbox', {
          'payload': jsonEncode(json),
        });
        await expectLater(
          storage.pendingSummary('metadata'),
          throwsFormatException,
        );
      }
      await database.update('deltasync_outbox', {'payload': '{invalid'});
      await expectLater(
        storage.pendingSummary('metadata'),
        throwsA(isA<DatabaseException>()),
      );
      await storage.close();
    },
  );

  test(
    'other SQL failures propagate without fallback or empty success',
    () async {
      final file = await path();
      final seed = open(file);
      await seed.pendingSummary('any');
      await seed.close();
      final factory = _Factory(failQuery: true);
      final storage = open(file, factory);
      await expectLater(
        storage.pendingSummary('any'),
        throwsA(isA<DatabaseException>()),
      );
      expect(factory.payloadRows, 0);
      await storage.close();
    },
  );
}

class _Factory implements DatabaseFactory {
  _Factory({this.noJson = false, this.failQuery = false});
  final bool noJson;
  final bool failQuery;
  int payloadRows = 0;
  int aggregateRows = 0;
  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async => _Database(
    await databaseFactoryFfi.openDatabase(path, options: options),
    this,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Database implements Database {
  _Database(this.database, this.factory);
  @override
  final Database database;
  final _Factory factory;
  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (factory.failQuery) throw _QueryException('database is locked');
    if (factory.noJson) throw _QueryException('no such function: json_extract');
    final rows = await database.rawQuery(sql, arguments);
    factory.aggregateRows += rows.length;
    expect(
      rows.every(
        (row) => row.keys.toSet().difference({'status', 'entry_count'}).isEmpty,
      ),
      isTrue,
    );
    return rows;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final rows = await database.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    factory.payloadRows += rows.length;
    return rows;
  }

  @override
  Future<void> close() => database.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _QueryException extends DatabaseException {
  _QueryException(super.message);
  @override
  int? getResultCode() => null;
  @override
  Object? get result => null;
}
