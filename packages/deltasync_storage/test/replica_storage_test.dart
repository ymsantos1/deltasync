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

  test(
    'atomic commit validates every outbox entry before publishing',
    () async {
      final initial = ReplicaSnapshot(
        replicaId: 'device-a',
        state: {'title': 'before'},
        clock: VectorClock(),
      );
      await storage.saveReplica(initial);
      final foreign = OutboxEntry(
        delta: Delta([Replica('device-b').setDelta('x', 1)]),
      );

      await expectLater(
        storage.commit(
          ReplicaSnapshot(
            replicaId: 'device-a',
            state: {'title': 'after'},
            clock: VectorClock(),
          ),
          [foreign],
        ),
        throwsArgumentError,
      );

      expect(await storage.loadReplica('device-a'), same(initial));
      expect(await storage.pending('device-a'), isEmpty);
    },
  );

  test('enqueues idempotently and acknowledges operations', () async {
    final change = Replica('device-a').setDelta('title', 'draft');
    final entry = OutboxEntry(delta: Delta([change]));

    await storage.enqueue(entry);
    await storage.enqueue(entry);
    expect((await storage.pending('device-a')).map((e) => e.changeIds.single), [
      change.id,
    ]);

    await storage.acknowledge('device-a', [change.id]);
    expect(await storage.pending('device-a'), isEmpty);
  });

  test(
    'partial ACK preserves unconfirmed changes in the replica outbox',
    () async {
      final source = Replica('device-a');
      final firstChange = source.setDelta('first', 1);
      final secondChange = source.setDelta('second', 2);
      final otherReplicaChange = Replica('device-b').setDelta('foreign', 3);

      await storage.enqueue(
        OutboxEntry(delta: Delta([firstChange, secondChange])),
      );
      await storage.enqueue(OutboxEntry(delta: Delta([otherReplicaChange])));

      await storage.acknowledge('device-b', [firstChange.id]);
      expect((await storage.pending('device-a')).single.changeIds, [
        firstChange.id,
        secondChange.id,
      ]);

      await storage.acknowledge('device-a', [firstChange.id]);
      final remaining = await storage.pending('device-a');
      expect(remaining, hasLength(1));
      expect(remaining.single.changeIds, [secondChange.id]);
      expect(remaining.single.delta.changes, [secondChange]);
      expect((await storage.pending('device-b')).single.changeIds, [
        otherReplicaChange.id,
      ]);
    },
  );

  test('counter outbox routes by origin and rejects mixed origins', () async {
    final first = Replica('device-a').incrementGCounter('cart/items');
    final second = Replica('device-b').incrementGCounter('cart/items');

    await storage.enqueue(OutboxEntry(delta: Delta([first])));
    expect((await storage.pending('device-a')).single.replicaId, 'device-a');

    await expectLater(
      storage.enqueue(OutboxEntry(delta: Delta([first, second]))),
      throwsA(isA<StateError>()),
    );
    expect(await storage.pending('device-b'), isEmpty);
  });

  test('pending excludes confirmed entries', () async {
    final change = Replica('device-a').setDelta('title', 'draft');
    await storage.enqueue(
      OutboxEntry(delta: Delta([change]), status: OutboxStatus.confirmed),
    );

    expect(await storage.pending('device-a'), isEmpty);
  });
}
