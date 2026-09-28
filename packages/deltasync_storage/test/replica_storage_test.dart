import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:test/test.dart';

void main() {
  late ReplicaStorage storage;

  setUp(() => storage = MemoryStorage());

  test('saves and loads replica snapshot', () async {
    final snapshot = ReplicaSnapshot(
      replicaId: 'device-a',
      state: {'title': 'draft'},
      clock: VectorClock().tick('device-a'),
      metadata: {'schema': 1},
    );

    await storage.saveReplica(snapshot);

    expect(await storage.loadReplica('device-a'), same(snapshot));
    expect((await storage.loadReplica('device-a'))!.state, {'title': 'draft'});
  });

  test('enqueues idempotently and acknowledges operations', () async {
    final operation = Replica('device-a').set('title', 'draft');
    final entry = OutboxEntry(operation: operation);

    await storage.enqueue(entry);
    await storage.enqueue(entry);
    expect((await storage.pending('device-a')).map((e) => e.operationId), [
      operation.id,
    ]);

    await storage.acknowledge('device-a', [operation.id]);
    expect(await storage.pending('device-a'), isEmpty);
  });

  test(
    'partial ACK preserves unconfirmed changes in the replica outbox',
    () async {
      final source = Replica('device-a');
      final firstOperation = source.set('first', 1);
      final secondChange = source.setDelta('second', 2);
      final otherReplicaOperation = Replica('device-b').set('foreign', 3);

      await storage.enqueue(
        OutboxEntry(
          delta: Delta([firstOperation]).merge(Delta.crdt([secondChange])),
        ),
      );
      await storage.enqueue(OutboxEntry(operation: otherReplicaOperation));

      await storage.acknowledge('device-b', [firstOperation.id]);
      expect((await storage.pending('device-a')).single.changeIds, [
        firstOperation.id,
        secondChange.id,
      ]);

      await storage.acknowledge('device-a', [firstOperation.id]);
      final remaining = await storage.pending('device-a');
      expect(remaining, hasLength(1));
      expect(remaining.single.changeIds, [secondChange.id]);
      expect(remaining.single.delta!.changes, isEmpty);
      expect(remaining.single.delta!.crdtChanges.single, secondChange);
      expect((await storage.pending('device-b')).single.changeIds, [
        otherReplicaOperation.id,
      ]);
    },
  );

  test('counter outbox routes by origin and rejects mixed origins', () async {
    final first = Replica('device-a').incrementGCounter('cart/items');
    final second = Replica('device-b').incrementGCounter('cart/items');

    await storage.enqueue(OutboxEntry(delta: Delta.crdt([first])));
    expect((await storage.pending('device-a')).single.replicaId, 'device-a');

    await expectLater(
      storage.enqueue(OutboxEntry(delta: Delta.crdt([first, second]))),
      throwsA(isA<StateError>()),
    );
    expect(await storage.pending('device-b'), isEmpty);
  });

  test('pending excludes confirmed entries', () async {
    final operation = Replica('device-a').set('title', 'draft');
    await storage.enqueue(
      OutboxEntry(operation: operation, status: OutboxStatus.confirmed),
    );

    expect(await storage.pending('device-a'), isEmpty);
  });
}
