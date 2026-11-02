import 'dart:async';
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

  test('a thousand pending entries survive durable restart and ACK', () async {
    final directory = await Directory.systemTemp.createTemp('restore-backlog-');
    final path = '${directory.path}/replica.sqlite';
    SqfliteReplicaStorage open() => SqfliteReplicaStorage(
      databaseFactory: databaseFactoryFfi,
      databasePath: path,
    );
    try {
      final writer = Replica('writer');
      final entries = <OutboxEntry>[];
      for (var index = 0; index < 1000; index++) {
        final change = writer.setDelta('note-$index', index);
        entries.add(
          OutboxEntry(delta: Delta([change]), recipientPeerId: 'peer'),
        );
      }
      final original = ReplicaSnapshot.fromReplica(writer);
      final initialStorage = open();
      await initialStorage.commit(original, entries);
      await initialStorage.close();

      final restoredStorage = open();
      final restored = SyncEngine.withStorage(
        replica: Replica('writer'),
        storage: restoredStorage,
        transport: _NoopTransport(),
      );
      try {
        await restored.start();
        expect(restored.replica.state.values.length, 1000);
        expect(restored.valueAt('note-0'), 0);
        expect(restored.valueAt('note-999'), 999);
        expect((await restoredStorage.pending('writer')).length, 1000);
        expect((await restored.pendingDelta()).changes.length, 1000);
        final after = (await restoredStorage.loadReplica('writer'))!.snapshot!;
        expect(after['lww'], original.snapshot!['lww']);
        expect(after['clock'], original.snapshot!['clock']);
        expect(after['deltaSequence'], original.snapshot!['deltaSequence']);
        await restoredStorage.acknowledge(
          'writer',
          'peer',
          entries.map((entry) => entry.entryId),
        );
        expect(await restoredStorage.pending('writer'), isEmpty);
      } finally {
        await restored.dispose();
        await restoredStorage.close();
      }

      final afterAckStorage = open();
      final afterAck = SyncEngine.withStorage(
        replica: Replica('writer'),
        storage: afterAckStorage,
        transport: _NoopTransport(),
      );
      try {
        await afterAck.start();
        expect(afterAck.replica.state.values.length, 1000);
        expect(afterAck.valueAt('note-999'), 999);
        expect(await afterAckStorage.pending('writer'), isEmpty);
      } finally {
        await afterAck.dispose();
        await afterAckStorage.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'newer outbox entry replays; invalid later entry leaves snapshot intact',
    () async {
      final directory = await Directory.systemTemp.createTemp('restore-retry-');
      final path = '${directory.path}/replica.sqlite';
      SqfliteReplicaStorage open() => SqfliteReplicaStorage(
        databaseFactory: databaseFactoryFfi,
        databasePath: path,
      );
      try {
        final writer = Replica('writer');
        writer.setDelta('title', 'base');
        final snapshot = ReplicaSnapshot.fromReplica(writer);
        final newer = OutboxEntry(
          delta: Delta([writer.setDelta('title', 'new')]),
          recipientPeerId: 'peer',
        );
        final invalid = OutboxEntry(
          delta: Delta([Replica('writer').incrementGCounter('title')]),
          recipientPeerId: 'peer',
        );
        final initial = open();
        await initial.saveReplica(snapshot);
        await initial.enqueue(newer);
        await initial.enqueue(invalid);
        await initial.close();

        final storage = open();
        final engine = SyncEngine.withStorage(
          replica: Replica('writer'),
          storage: storage,
          transport: _NoopTransport(),
        );
        try {
          await expectLater(engine.start(), throwsFormatException);
          expect(
            (await storage.loadReplica('writer'))!.snapshot,
            snapshot.snapshot,
          );
          expect((await storage.pending('writer')).length, 2);
          await storage.acknowledge('writer', 'peer', [invalid.entryId]);
          await engine.start();
          expect(engine.valueAt('title'), 'new');
          expect(engine.replica.toSnapshotJson()['deltaSequence'], 2);
          expect(
            (await storage.pending('writer')).single.entryId,
            newer.entryId,
          );
        } finally {
          await engine.dispose();
          await storage.close();
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}

class _NoopTransport implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';

  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();

  @override
  Future<void> send(DeltaEnvelope envelope) async {}
}
