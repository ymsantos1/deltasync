import 'dart:convert';

import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// SQLite implementation of [ReplicaStorage].
///
/// Pass `sqflite`'s `databaseFactory` from Flutter, or another compatible
/// factory such as `sqflite_common_ffi` on desktop. This package depends only
/// on the sqflite API and keeps Flutter out of core, sync, and storage.
class SqfliteReplicaStorage implements ReplicaStorage {
  SqfliteReplicaStorage({
    required this.databaseFactory,
    required this.databasePath,
  });

  static const schemaVersion = 1;
  static const _snapshotTable = 'deltasync_snapshots';
  static const _outboxTable = 'deltasync_outbox';

  final DatabaseFactory databaseFactory;
  final String databasePath;
  Future<Database>? _opening;

  Future<Database> _database() {
    final cached = _opening;
    if (cached != null) return cached;
    late final Future<Database> attempt;
    attempt = databaseFactory
        .openDatabase(
          databasePath,
          options: OpenDatabaseOptions(
            version: schemaVersion,
            onCreate: (database, version) async {
              await _createSchema(database);
            },
            onUpgrade: (database, oldVersion, newVersion) async {
              throw FormatException(
                'Unsupported DeltaSync SQLite schema upgrade: '
                '$oldVersion to $newVersion',
              );
            },
            onDowngrade: (database, oldVersion, newVersion) async {
              throw FormatException(
                'Unsupported DeltaSync SQLite schema downgrade: '
                '$oldVersion to $newVersion',
              );
            },
          ),
        )
        .catchError((Object error, StackTrace stack) {
          if (identical(_opening, attempt)) _opening = null;
          Error.throwWithStackTrace(error, stack);
        });
    return _opening = attempt;
  }

  /// Close this database before copying it. With WAL enabled, copy the database
  /// together with its `-wal` and `-shm` files, or use SQLite's online backup
  /// API. A restored copy retains replica IDs; applications must avoid opening
  /// two active replicas with the same ID unless they intentionally share state.
  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }

  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) async {
    final database = await _database();
    final rows = await database.query(
      _snapshotTable,
      columns: const ['payload'],
      where: 'replica_id = ?',
      whereArgs: [replicaId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReplicaSnapshot.fromJson(_decodeMap(rows.single['payload']));
  }

  @override
  Future<void> saveReplica(ReplicaSnapshot snapshot) async {
    _validate(snapshot);
    final database = await _database();
    await database.insert(
      _snapshotTable,
      _snapshotRow(snapshot),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    _validate(snapshot);
    final additions = List<OutboxEntry>.of(entries);
    if (additions.any((entry) => entry.replicaId != snapshot.replicaId)) {
      throw ArgumentError('Commit entries must belong to snapshot replica');
    }
    final database = await _database();
    await database.transaction((transaction) async {
      await transaction.insert(
        _snapshotTable,
        _snapshotRow(snapshot),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final entry in additions) {
        await _insertOrCheckPending(transaction, entry);
      }
    });
  }

  @override
  Future<void> commitRemote(ReplicaSnapshot snapshot) async {
    _validate(snapshot);
    final database = await _database();
    await database.transaction((transaction) async {
      await transaction.insert(
        _snapshotTable,
        _snapshotRow(snapshot),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> enqueue(OutboxEntry entry) async {
    final database = await _database();
    await database.transaction(
      (transaction) => _insertOrCheckPending(transaction, entry),
    );
  }

  static Future<void> _insertOrCheckPending(
    DatabaseExecutor transaction,
    OutboxEntry entry,
  ) async {
    final rows = await transaction.query(
      _outboxTable,
      columns: const ['payload'],
      where: 'replica_id = ? AND recipient_peer_id = ? AND entry_id = ?',
      whereArgs: [entry.replicaId, entry.recipientPeerId, entry.entryId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final existing = OutboxEntry.fromJson(_decodeMap(rows.single['payload']));
      existing.delta.merge(entry.delta);
      return;
    }
    await transaction.insert(_outboxTable, _outboxRow(entry));
  }

  @override
  Future<List<OutboxEntry>> pending(
    String replicaId, {
    String? recipientPeerId,
  }) async {
    final database = await _database();
    final rows = await database.query(
      _outboxTable,
      where: recipientPeerId == null
          ? 'replica_id = ?'
          : 'replica_id = ? AND recipient_peer_id = ?',
      whereArgs: recipientPeerId == null
          ? [replicaId]
          : [replicaId, recipientPeerId],
      orderBy: 'created_at, entry_id',
    );
    return [
      for (final row in rows) OutboxEntry.fromJson(_decodeMap(row['payload'])),
    ];
  }

  @override
  Future<void> markSent(
    String replicaId,
    String recipientPeerId,
    Iterable<String> operationIds,
  ) async {
    final ids = operationIds.toSet();
    if (ids.isEmpty) return;
    final database = await _database();
    await database.transaction((transaction) async {
      for (final id in ids) {
        final rows = await transaction.query(
          _outboxTable,
          columns: const ['payload'],
          where: 'replica_id = ? AND recipient_peer_id = ? AND entry_id = ?',
          whereArgs: [replicaId, recipientPeerId, id],
          limit: 1,
        );
        if (rows.isEmpty) continue;
        final entry = OutboxEntry.fromJson(_decodeMap(rows.single['payload']));
        final updated = OutboxEntry(
          delta: entry.delta,
          recipientPeerId: entry.recipientPeerId,
          status: OutboxStatus.sent,
          attempts: entry.attempts + 1,
          createdAt: entry.createdAt,
          sentAt: DateTime.now().toUtc(),
        );
        await transaction.update(
          _outboxTable,
          _outboxRow(updated),
          where: 'replica_id = ? AND recipient_peer_id = ? AND entry_id = ?',
          whereArgs: [replicaId, recipientPeerId, id],
        );
      }
    });
  }

  @override
  Future<void> acknowledge(
    String replicaId,
    String recipientPeerId,
    Iterable<String> operationIds,
  ) async {
    final ids = operationIds.toSet();
    if (ids.isEmpty) return;
    final database = await _database();
    await database.transaction((transaction) async {
      for (final id in ids) {
        await transaction.delete(
          _outboxTable,
          where: 'replica_id = ? AND recipient_peer_id = ? AND entry_id = ?',
          whereArgs: [replicaId, recipientPeerId, id],
        );
      }
    });
  }

  static Future<void> _createSchema(Database database) async {
    await database.execute('''
      CREATE TABLE $_snapshotTable (
        replica_id TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE $_outboxTable (
        replica_id TEXT NOT NULL,
        recipient_peer_id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (replica_id, recipient_peer_id, entry_id)
      )
    ''');
    await database.execute('''
      CREATE INDEX deltasync_outbox_replica_peer
      ON $_outboxTable (replica_id, recipient_peer_id, created_at)
    ''');
  }

  static Map<String, Object?> _snapshotRow(ReplicaSnapshot snapshot) => {
    'replica_id': snapshot.replicaId,
    'payload': jsonEncode(_snapshotJson(snapshot)),
  };

  static Map<String, Object?> _snapshotJson(ReplicaSnapshot snapshot) {
    if (snapshot.version == 2) return snapshot.toJson();
    return {
      'version': 1,
      'replicaId': snapshot.replicaId,
      'state': snapshot.legacyState,
      'clock': snapshot.legacyClock!.toJson(),
      'metadata': snapshot.legacyMetadata,
    };
  }

  static Map<String, Object?> _outboxRow(OutboxEntry entry) => {
    'replica_id': entry.replicaId,
    'recipient_peer_id': entry.recipientPeerId,
    'entry_id': entry.entryId,
    'created_at': entry.createdAt.toIso8601String(),
    'payload': jsonEncode(entry.toJson()),
  };

  static Map<String, Object?> _decodeMap(Object? encoded) {
    final value = jsonDecode(encoded as String);
    if (value is! Map) throw const FormatException('Invalid stored JSON map');
    return Map<String, Object?>.from(value);
  }

  static void _validate(ReplicaSnapshot snapshot) {
    if (snapshot.replicaId.isEmpty ||
        snapshot.replicaId.trim() != snapshot.replicaId) {
      throw ArgumentError('Invalid snapshot replica ID');
    }
    if (snapshot.version == 2) {
      if (snapshot.snapshot?['replicaId'] != snapshot.replicaId) {
        throw ArgumentError('Invalid canonical replica snapshot');
      }
    } else if (snapshot.version != 1 || snapshot.legacyClock == null) {
      throw ArgumentError('Unsupported replica snapshot version');
    }
  }
}
