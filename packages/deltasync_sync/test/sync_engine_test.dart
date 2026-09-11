import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  test('set persists local operation in outbox', () async {
    final store = TestPendingDeltaStore();
    final transport = TestDeltaTransport();
    final engine = SyncEngine(
      replica: Replica('device-a'),
      store: store,
      transport: transport,
    );

    final operation = await engine.set('title', 'draft');

    expect(store.readCount, 1);
    expect(store.deltaFor('device-a').changes, [operation]);
    expect(engine.replica.state.values['title'], 'draft');
  });

  test(
    'start restores pending operations and listens for remote deltas',
    () async {
      final store = TestPendingDeltaStore();
      final transport = TestDeltaTransport();
      final source = Replica('source');
      final pending = source.set('title', 'recovered');
      store.seed('device-a', Delta([pending]));
      final engine = SyncEngine(
        replica: Replica('device-a'),
        store: store,
        transport: transport,
      );

      await engine.start();
      expect(engine.replica.state.values['title'], 'recovered');

      final remote = Replica('remote')..set('body', 'from server');
      transport.emit(remote.export());
      await Future<void>.delayed(Duration.zero);

      expect(engine.replica.state.values['body'], 'from server');
      await engine.dispose();
    },
  );

  test('push sends pending delta and clears outbox', () async {
    final store = TestPendingDeltaStore();
    final transport = TestDeltaTransport();
    final engine = SyncEngine(
      replica: Replica('device-a'),
      store: store,
      transport: transport,
    );
    await engine.set('title', 'draft');

    await engine.push();

    expect(transport.sent, hasLength(1));
    expect(transport.sent.single.changes, hasLength(1));
    expect(store.deltaFor('device-a'), const Delta.empty());
  });

  test('native delta mutation persists and pushes through outbox', () async {
    final store = TestPendingDeltaStore();
    final transport = TestDeltaTransport();
    final engine = SyncEngine(
      replica: Replica('device-a'),
      store: store,
      transport: transport,
    );

    final change = await engine.setDelta('title', 'draft');

    expect(store.deltaFor('device-a').crdtChanges, [change]);
    await engine.push();

    expect(transport.sent.single.crdtChanges, [change]);
    expect(store.deltaFor('device-a'), const Delta.empty());
  });

  test('ReplicaStorage restores native snapshot and outbox', () async {
    final storage = MemoryStorage();
    final firstTransport = TestDeltaTransport();
    final first = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: firstTransport,
    );
    final change = await first.setDelta('title', 'persisted');
    await first.dispose();

    final secondTransport = TestDeltaTransport();
    final second = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: secondTransport,
    );
    await second.start();

    expect(second.replica.state.values, {'title': 'persisted'});
    expect((await storage.pending('device-a')).single.operationId, change.id);
    await second.push();
    expect(secondTransport.sent.single.crdtChanges, [change]);
    expect((await storage.pending('device-a')).single.operationId, change.id);
    await second.dispose();
  });

  test('acknowledging transport clears storage outbox after ACK', () async {
    final storage = MemoryStorage();
    final transport = AcknowledgingTestDeltaTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
    );

    final change = await engine.setDelta('title', 'draft');
    await engine.push();

    expect(transport.sent.single.crdtChanges, [change]);
    expect(await storage.pending('device-a'), isEmpty);
    await engine.dispose();
  });

  test('ACK handles all changes in one outbox entry', () async {
    final storage = MemoryStorage();
    final first = Replica('device-a');
    final firstChange = first.setDelta('first', 1);
    final secondChange = first.setDelta('second', 2);
    await storage.enqueue(
      OutboxEntry(delta: Delta.crdt([firstChange, secondChange])),
    );
    final transport = AcknowledgingTestDeltaTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
    );

    await engine.push();

    expect(await storage.pending('device-a'), isEmpty);
    await engine.dispose();
  });

  test('unacknowledged entry retries only when due or forced', () async {
    final storage = MemoryStorage();
    final transport = TestDeltaTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
      retryPolicy: const SyncRetryPolicy(baseDelay: Duration(days: 1)),
    );
    await engine.setDelta('title', 'draft');

    await engine.push();
    await engine.push();
    expect(transport.sent, hasLength(1));
    expect((await storage.pending('device-a')).single.attempts, 1);

    await engine.push(force: true);
    expect(transport.sent, hasLength(2));
    expect((await storage.pending('device-a')).single.attempts, 2);
    await engine.dispose();
  });

  test('retry policy caps delay and validates max attempts', () {
    const policy = SyncRetryPolicy(
      baseDelay: Duration(seconds: 10),
      maxDelay: Duration(seconds: 3),
      maxAttempts: 2,
    );

    expect(policy.delayFor(1), const Duration(seconds: 3));
    expect(policy.delayFor(3), const Duration(seconds: 3));
    expect(policy.maxAttempts, 2);
  });

  test('restored replica advances local delta sequence', () async {
    final storage = MemoryStorage();
    final first = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: TestDeltaTransport(),
    );
    final previous = await first.setDelta('title', 'first');
    await first.dispose();

    final second = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: TestDeltaTransport(),
    );
    await second.start();
    final next = await second.setDelta('title', 'second');

    expect(next.id, isNot(previous.id));
    expect(next.id, 'device-a:delta:2');
    await second.dispose();
  });

  test('dispose stops applying incoming deltas', () async {
    final store = TestPendingDeltaStore();
    final transport = TestDeltaTransport();
    final engine = SyncEngine(
      replica: Replica('device-a'),
      store: store,
      transport: transport,
    );
    await engine.start();
    await engine.dispose();

    final remote = Replica('remote')..set('title', 'ignored');
    transport.emit(remote.export());
    await Future<void>.delayed(Duration.zero);

    expect(engine.replica.state.values, isEmpty);
  });
}

class TestPendingDeltaStore implements PendingDeltaStore {
  final Map<String, Delta> _data = {};
  int readCount = 0;

  void seed(String replicaId, Delta delta) => _data[replicaId] = delta;

  Delta deltaFor(String replicaId) => _data[replicaId] ?? const Delta.empty();

  @override
  Future<Delta> read(String replicaId) async {
    readCount++;
    return deltaFor(replicaId);
  }

  @override
  Future<void> write(String replicaId, Delta delta) async {
    _data[replicaId] = delta;
  }
}

class TestDeltaTransport implements DeltaTransport {
  final StreamController<Delta> _incoming = StreamController<Delta>.broadcast();
  final List<Delta> sent = [];

  @override
  Stream<Delta> get incoming => _incoming.stream;

  @override
  Future<void> send(Delta delta) async => sent.add(delta);

  void emit(Delta delta) => _incoming.add(delta);
}

class AcknowledgingTestDeltaTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  @override
  Future<Iterable<String>> sendAndAwaitAck(Delta delta) async {
    await send(delta);
    return [
      ...delta.changes.map((change) => change.id),
      ...delta.crdtChanges.map((change) => change.id),
    ];
  }
}
