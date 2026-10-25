import 'dart:io';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import '../example/commit_status_example.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late _FaultStorage storage;
  late SyncEngine engine;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('deltasync-guide-');
    storage = _FaultStorage('${directory.path}/replica.sqlite');
    engine = SyncEngine.withStorage(
      replica: Replica('stable-installation'),
      storage: storage,
      transport: OfflinePeer(),
    );
    await engine.start();
  });
  tearDown(() async {
    try {
      await engine.dispose();
    } finally {
      await storage.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'status failure preserves local success, outbox and SQLite recovery',
    () async {
      final messages = <String>[];
      final events = <SyncCommitEvent>[];
      final subscription = engine.commitsFor('profile').listen(events.add);
      addTearDown(subscription.cancel);
      final payloadReads = storage.payloadReads;
      storage.failSummary = true;
      await saveAndRefresh(engine, {
        'name': 'Ada',
        'tags': <String>[],
      }, messages.add);
      await Future<void>.delayed(Duration.zero);
      expect(messages.first, 'saved locally');
      expect(
        messages[1],
        startsWith('saved locally; pending status unavailable:'),
      );
      expect(messages.last, 'profile: Ada');
      expect(
        messages.any((line) => line.startsWith('local commit failed:')),
        isFalse,
      );
      expect(events.single.addresses, {'profile'});
      expect(storage.payloadReads, payloadReads);
      expect((engine.query('profile') as PresentField).value, {
        'name': 'Ada',
        'tags': [],
      });

      final retainedIds = (await storage.pending('stable-installation'))
          .map((entry) => entry.entryId)
          .toList();
      await expectLater(engine.push(), throwsStateError);
      expect(
        (engine.query('profile') as PresentField).decode(
          (raw) => (raw as Map)['name'],
        ),
        'Ada',
      );
      await subscription.cancel();
      await engine.dispose();
      await storage.close();

      final reopened = SqfliteReplicaStorage(
        databaseFactory: databaseFactoryFfi,
        databasePath: storage.databasePath,
      );
      final restored = SyncEngine.withStorage(
        replica: Replica('stable-installation'),
        storage: reopened,
        transport: OfflinePeer(),
      );
      try {
        await restored.start();
        expect((restored.query('profile') as PresentField).value, {
          'name': 'Ada',
          'tags': [],
        });
        expect((await restored.pendingSummary()).sentCount, 1);
        expect(
          (await reopened.pending('stable-installation'))
              .map((entry) => entry.entryId),
          retainedIds,
        );
        await restored.setDelta('profile', {'name': 'Grace', 'tags': []});
        expect((await restored.pendingSummary()).totalCount, 2);
      } finally {
        try {
          await restored.dispose();
        } finally {
          await reopened.close();
        }
      }
    },
  );

  test(
    'valid JSON with invalid model remains a committed present value',
    () async {
      final messages = <String>[];
      await saveAndRefresh(engine, {'name': 42, 'tags': []}, messages.add);
      expect(messages.first, 'saved locally');
      expect(messages[1], 'awaiting ACK: 1');
      expect(messages.last, startsWith('invalid model:'));
      expect((engine.query('profile') as PresentField).value, {
        'name': 42,
        'tags': [],
      });
      expect(
        (await storage.pending('stable-installation')).single.changeIds,
        hasLength(1),
      );
      final saved = await storage.loadReplica('stable-installation');
      expect(
        (Replica.fromSnapshotJson(
          saved!.snapshot!,
        ).query('profile') as PresentField).value,
        {'name': 42, 'tags': []},
      );
    },
  );

  test(
    'commit failure is reported without querying status or exposing candidate',
    () async {
      final messages = <String>[];
      storage.failCommit = true;
      await saveAndRefresh(engine, {'name': 'Ada', 'tags': []}, messages.add);
      expect(messages, hasLength(1));
      expect(messages.single, startsWith('local commit failed:'));
      expect(storage.summaryReads, 0);
      expect(engine.query('profile'), isA<AbsentField>());
      expect(await storage.pending('stable-installation'), isEmpty);
    },
  );
}

// Fault injection overrides public adapter methods only; no src imports.
class _FaultStorage extends SqfliteReplicaStorage {
  _FaultStorage(String path)
    : super(databaseFactory: databaseFactoryFfi, databasePath: path);
  bool failSummary = false;
  bool failCommit = false;
  int summaryReads = 0;
  int payloadReads = 0;

  @override
  Future<OutboxSummary> pendingSummary(
    String replicaId, {
    String? recipientPeerId,
  }) {
    summaryReads++;
    if (failSummary) return Future.error(StateError('summary unavailable'));
    return super.pendingSummary(replicaId, recipientPeerId: recipientPeerId);
  }

  @override
  Future<List<OutboxEntry>> pending(
    String replicaId, {
    String? recipientPeerId,
  }) {
    payloadReads++;
    return super.pending(replicaId, recipientPeerId: recipientPeerId);
  }

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    if (failCommit) throw StateError('commit unavailable');
    await super.commit(snapshot, entries);
  }
}
