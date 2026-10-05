import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:test/test.dart';

/// Creates adapters for the shared [ReplicaStorage] contract tests.
///
/// [createStorageWithCommitFailure] must inject a failure in the adapter's
/// commit path. Persistent adapters should place the failure after writes have
/// been staged so the suite verifies rollback of the real transaction.
abstract interface class ReplicaStorageContractFixture {
  ReplicaStorage createStorage();

  ReplicaStorage createStorageWithCommitFailure();
}

/// Registers shared behavior checks for an adapter implementation.
///
/// Adapter packages call this from their own `test/` entry point. Implementors
/// stay responsible for mapping snapshots and outbox entries to their backend;
/// this suite never switches on concrete CRDT classes.
void replicaStorageContractTests({
  required String name,
  required ReplicaStorageContractFixture fixture,
}) {
  group('$name ReplicaStorage contract', () {
    test('stores canonical snapshot and opaque outbox changes', () async {
      final storage = fixture.createStorage();
      final replica = Replica('contract-device')
        ..setDelta('profile/name', 'Ada')
        ..incrementGCounter('cart/items', 2)
        ..decrementPnCounter('account/balance', 1);
      final changes = replica.export().changes;
      final entries = [
        for (final change in changes)
          OutboxEntry(delta: Delta([change]), recipientPeerId: 'peer-a'),
      ];
      final snapshot = ReplicaSnapshot.fromReplica(replica);

      await storage.commit(snapshot, entries);

      final restoredSnapshot = await storage.loadReplica(replica.id);
      expect(restoredSnapshot, isNotNull);
      expect(restoredSnapshot!.version, 2);
      expect(restoredSnapshot.toJson()['version'], 2);
      expect(restoredSnapshot.snapshot, snapshot.snapshot);
      final pending = await storage.pending(replica.id);
      expect(pending.map((entry) => entry.entryId).toSet(), {
        for (final change in changes) change.id,
      });
      expect(
        pending.every((entry) => entry.recipientPeerId == 'peer-a'),
        isTrue,
      );
      expect(pending.every((entry) => entry.delta.changes.length == 1), isTrue);
      expect(pending.every((entry) => entry.toJson()['version'] == 2), isTrue);
    });

    test(
      'remote commit replaces snapshot and preserves local outbox',
      () async {
        final storage = fixture.createStorage();
        final local = Replica('contract-device');
        final localChange = local.setDelta('local', 'pending');
        await storage.commit(ReplicaSnapshot.fromReplica(local), [
          OutboxEntry(delta: Delta([localChange]), recipientPeerId: 'peer-a'),
        ]);

        final merged = local.fork()..setDelta('remote', 'merged');
        await storage.commitRemote(ReplicaSnapshot.fromReplica(merged));

        final restored = Replica.fromSnapshotJson(
          (await storage.loadReplica('contract-device'))!.snapshot!,
        );
        expect(restored.state.values, {'local': 'pending', 'remote': 'merged'});
        expect(
          (await storage.pending('contract-device')).single.entryId,
          localChange.id,
        );
      },
    );

    test(
      'ACK metadata and peer scoping survive partial confirmation',
      () async {
        final storage = fixture.createStorage();
        final replica = Replica('contract-device');
        final first = replica.setDelta('first', 1);
        final second = replica.setDelta('second', 2);
        for (final change in [first, second]) {
          await storage.enqueue(
            OutboxEntry(delta: Delta([change]), recipientPeerId: 'peer-a'),
          );
          await storage.enqueue(
            OutboxEntry(delta: Delta([change]), recipientPeerId: 'peer-b'),
          );
        }

        await storage.markSent('contract-device', 'peer-a', [first.id]);
        final sent = (await storage.pending(
          'contract-device',
          recipientPeerId: 'peer-a',
        )).singleWhere((entry) => entry.entryId == first.id);
        expect(sent.status, OutboxStatus.sent);
        expect(sent.attempts, 1);
        expect(sent.sentAt, isNotNull);
        final restoredSent = OutboxEntry.fromJson(sent.toJson());
        expect(restoredSent.recipientPeerId, 'peer-a');
        expect(restoredSent.status, OutboxStatus.sent);
        expect(restoredSent.attempts, sent.attempts);
        expect(restoredSent.sentAt, sent.sentAt);

        await storage.acknowledge('contract-device', 'peer-a', [first.id]);
        expect(
          (await storage.pending(
            'contract-device',
            recipientPeerId: 'peer-a',
          )).map((entry) => entry.entryId),
          [second.id],
        );
        expect(
          (await storage.pending(
            'contract-device',
            recipientPeerId: 'peer-b',
          )).map((entry) => entry.entryId).toSet(),
          {first.id, second.id},
        );
      },
    );

    test('returned data cannot mutate stored snapshot or outbox', () async {
      final storage = fixture.createStorage();
      final replica = Replica('contract-device')..setDelta('nested', [1, 2]);
      final change = replica.export().changes.single;
      await storage.commit(ReplicaSnapshot.fromReplica(replica), [
        OutboxEntry(delta: Delta([change]), recipientPeerId: 'peer-a'),
      ]);

      final loaded = (await storage.loadReplica(replica.id))!;
      expect(
        () => loaded.snapshot!['replicaId'] = 'other',
        throwsUnsupportedError,
      );
      final listed = await storage.pending(replica.id);
      try {
        listed.clear();
      } on UnsupportedError {
        // Immutable result lists are valid; detached mutable lists are too.
      }

      final outboxValue =
          (await storage.pending(replica.id)).single.delta.changes.single
              as LwwDelta<Object?>;
      final returnedItems = outboxValue.value! as List<Object?>;
      returnedItems[0] = 'changed outside';

      expect((await storage.loadReplica(replica.id))!.replicaId, replica.id);
      expect(await storage.pending(replica.id), hasLength(1));
      expect(
        (await storage.pending(replica.id)).single.delta.changes.single.id,
        change.id,
      );
      expect(
        ((await storage.pending(replica.id)).single.delta.changes.single
                as LwwDelta<Object?>)
            .value,
        [1, 2],
      );
    });

    test('concurrent commits retain every outbox change', () async {
      final storage = fixture.createStorage();
      final replica = Replica('contract-device');
      final first = replica.setDelta('first', 1);
      final firstSnapshot = ReplicaSnapshot.fromReplica(replica);
      final second = replica.setDelta('second', 2);
      final secondSnapshot = ReplicaSnapshot.fromReplica(replica);

      await Future.wait([
        storage.commit(firstSnapshot, [
          OutboxEntry(delta: Delta([first]), recipientPeerId: 'peer-a'),
        ]),
        storage.commit(secondSnapshot, [
          OutboxEntry(delta: Delta([second]), recipientPeerId: 'peer-a'),
        ]),
      ]);

      expect(
        (await storage.pending(
          'contract-device',
        )).map((entry) => entry.entryId).toSet(),
        {first.id, second.id},
      );
      final persisted = await storage.loadReplica('contract-device');
      expect(persisted, isNotNull);
      expect(persisted!.snapshot!['replicaId'], 'contract-device');
    });

    test(
      'failed commit leaves previous snapshot and outbox unchanged',
      () async {
        final storage = fixture.createStorageWithCommitFailure();
        final baseline = Replica('contract-device')..setDelta('base', true);
        final baselineChange = baseline.export().changes.single;
        await storage.saveReplica(ReplicaSnapshot.fromReplica(baseline));
        await storage.enqueue(
          OutboxEntry(
            delta: Delta([baselineChange]),
            recipientPeerId: 'peer-a',
          ),
        );
        final failedCandidate = baseline.fork();
        final failedChange = failedCandidate.setDelta('new', true);

        await expectLater(
          storage.commit(ReplicaSnapshot.fromReplica(failedCandidate), [
            OutboxEntry(
              delta: Delta([failedChange]),
              recipientPeerId: 'peer-a',
            ),
          ]),
          throwsA(anything),
        );

        final persisted = Replica.fromSnapshotJson(
          (await storage.loadReplica('contract-device'))!.snapshot!,
        );
        expect(persisted.state.values, {'base': true});
        expect(
          (await storage.pending(
            'contract-device',
          )).map((entry) => entry.entryId),
          [baselineChange.id],
        );
      },
    );
  });
}
