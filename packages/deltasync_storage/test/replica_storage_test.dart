// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:test/test.dart';

void main() {
  late ReplicaStorage storage;

  setUp(() => storage = MemoryStorage());

  test('saves and loads replica snapshot', () async {
    final snapshot = ReplicaSnapshot(
      replicaId: 'device-a',
      snapshot: (Replica(
        'device-a',
      )..setDelta('title', 'draft')).toSnapshotJson(),
    );

    await storage.saveReplica(snapshot);

    expect(await storage.loadReplica('device-a'), same(snapshot));
    expect(
      (await storage.loadReplica('device-a'))!.snapshot!['replicaId'],
      'device-a',
    );
    expect(
      ReplicaSnapshot.fromJson(snapshot.toJson()).snapshot,
      snapshot.snapshot,
    );
  });

  test(
    'atomic commit validates every outbox entry before publishing',
    () async {
      final initial = ReplicaSnapshot(
        replicaId: 'device-a',
        snapshot: (Replica(
          'device-a',
        )..setDelta('title', 'before')).toSnapshotJson(),
      );
      await storage.saveReplica(initial);
      final foreign = OutboxEntry(
        delta: Delta([Replica('device-b').setDelta('x', 1)]),
      );

      await expectLater(
        storage.commit(
          ReplicaSnapshot(
            replicaId: 'device-a',
            snapshot: (Replica(
              'device-a',
            )..setDelta('title', 'after')).toSnapshotJson(),
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
    expect(entry.entryId, change.id);

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

      await storage.enqueue(OutboxEntry(delta: Delta([firstChange])));
      await storage.enqueue(OutboxEntry(delta: Delta([secondChange])));
      await storage.enqueue(OutboxEntry(delta: Delta([otherReplicaChange])));

      await storage.acknowledge('device-b', [firstChange.id]);
      expect(
        (await storage.pending('device-a')).map((e) => e.changeIds.single),
        [firstChange.id, secondChange.id],
      );

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

    expect(
      () => OutboxEntry(delta: Delta([first, second])),
      throwsArgumentError,
    );
    expect(await storage.pending('device-b'), isEmpty);
  });

  test('snapshot copies nested state and outbox accepts one change only', () {
    final source = Replica('device-a')..setDelta('nested', [1, 2]);
    final values =
        jsonDecode(jsonEncode(source.toSnapshotJson())) as Map<String, Object?>;
    final snapshot = ReplicaSnapshot(replicaId: 'device-a', snapshot: values);
    (((values['lww'] as Map)['nested'] as Map)['winner'] as Map)['value'] = [
      'outside',
    ];
    expect(
      ((((snapshot.snapshot!['lww'] as Map)['nested'] as Map)['winner']
              as Map)['value']
          as List),
      [1, 2],
    );
    expect(
      () =>
          ((((snapshot.snapshot!['lww'] as Map)['nested'] as Map)['winner']
                      as Map)['value']
                  as List)
              .add(4),
      throwsUnsupportedError,
    );

    expect(() => OutboxEntry(delta: const Delta.empty()), throwsArgumentError);
  });

  test('outbox entry isolates nested delta values and enforces attempts', () {
    final nested = <String, Object?>{
      'items': <Object?>['one'],
    };
    final change = Replica('device-a').setDelta('payload', nested);
    final entry = OutboxEntry(delta: Delta([change]));
    (nested['items'] as List<Object?>).add('outside');
    expect(
      ((entry.delta.changes.single as LwwDelta<Object?>).value
          as Map<String, Object?>)['items'],
      ['one'],
    );
    expect(
      () => OutboxEntry(delta: Delta([change]), attempts: -1),
      throwsArgumentError,
    );
    expect(
      () => OutboxEntry(delta: Delta([change]), status: OutboxStatus.sent),
      throwsArgumentError,
    );
  });

  test('outbox wire format preserves status and rejects unknown labels', () {
    final change = Replica('device-a').setDelta('title', 'draft');
    final entry = OutboxEntry(delta: Delta([change]));
    final restored = OutboxEntry.fromJson(entry.toJson());

    expect(restored.changeIds, [change.id]);
    expect(restored.status, OutboxStatus.pending);
    expect(restored.entryId, change.id);
    expect(
      () => OutboxEntry.fromJson({...entry.toJson(), 'status': 'future'}),
      throwsFormatException,
    );
  });

  test(
    'atomic commit rejects reused pending ID with divergent payload',
    () async {
      final first = Replica('device-a').setDelta('title', 'first');
      final conflicting = LwwDelta<Object?>(
        key: first.key,
        id: first.id,
        replicaId: first.replicaId,
        timestamp: first.timestamp,
        value: 'conflicting',
        dot: first.dot,
      );
      final initialSnapshot = Replica('device-a')..setDelta('old', true);
      await storage.commit(
        ReplicaSnapshot(
          replicaId: 'device-a',
          snapshot: initialSnapshot.toSnapshotJson(),
        ),
        [
          OutboxEntry(delta: Delta([first])),
        ],
      );
      final next = Replica('device-a')..setDelta('new', true);

      await expectLater(
        storage.commit(
          ReplicaSnapshot(
            replicaId: 'device-a',
            snapshot: next.toSnapshotJson(),
          ),
          [
            OutboxEntry(delta: Delta([conflicting])),
          ],
        ),
        throwsFormatException,
      );
      expect(
        (await storage.loadReplica('device-a'))!.snapshot!['lww'],
        initialSnapshot.toSnapshotJson()['lww'],
      );
      expect(
        (await storage.pending('device-a')).single.delta.changes.single,
        first,
      );
    },
  );

  test('pending excludes confirmed entries', () async {
    final change = Replica('device-a').setDelta('title', 'draft');
    await storage.enqueue(
      OutboxEntry(delta: Delta([change]), status: OutboxStatus.confirmed),
    );

    expect(await storage.pending('device-a'), isEmpty);
  });
}
