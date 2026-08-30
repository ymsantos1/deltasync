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

  test('pending excludes confirmed entries', () async {
    final operation = Replica('device-a').set('title', 'draft');
    await storage.enqueue(
      OutboxEntry(operation: operation, status: OutboxStatus.confirmed),
    );

    expect(await storage.pending('device-a'), isEmpty);
  });
}
