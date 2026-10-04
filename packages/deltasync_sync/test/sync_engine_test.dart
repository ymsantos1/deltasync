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

    final operation = await engine.setDelta('title', 'draft');

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
      final pending = source.setDelta('title', 'recovered');
      store.seed('device-a', Delta([pending]));
      final engine = SyncEngine(
        replica: Replica('device-a'),
        store: store,
        transport: transport,
      );

      await engine.start();
      expect(engine.replica.state.values['title'], 'recovered');

      final remote = Replica('remote')..setDelta('body', 'from server');
      transport.emit(remote.export());
      await Future<void>.delayed(Duration.zero);

      expect(engine.replica.state.values['body'], 'from server');
      await engine.dispose();
    },
  );

  test('legacy store retains sent delta because send is not an ACK', () async {
    final store = TestPendingDeltaStore();
    final transport = TestDeltaTransport();
    final engine = SyncEngine(
      replica: Replica('device-a'),
      store: store,
      transport: transport,
    );
    await engine.setDelta('title', 'draft');

    await engine.push();
    await engine.push();

    expect(transport.sent, hasLength(2));
    expect(transport.sent.map((delta) => delta.changes.single.id).toSet(), {
      store.deltaFor('device-a').changes.single.id,
    });
    expect(store.deltaFor('device-a').changes, hasLength(1));
  });

  test('legacy store retains delta when send fails', () async {
    final store = TestPendingDeltaStore();
    final transport = FailOnceDeltaTransport();
    final engine = SyncEngine(
      replica: Replica('device-a'),
      store: store,
      transport: transport,
    );
    await engine.setDelta('title', 'draft');

    await expectLater(engine.push(), throwsA(isA<StateError>()));
    expect(store.deltaFor('device-a').changes, hasLength(1));

    await engine.push();
    expect(transport.sent, hasLength(1));
    expect(store.deltaFor('device-a').changes, hasLength(1));
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

    expect(store.deltaFor('device-a').changes, [change]);
    await engine.push();

    expect(transport.sent.single.changes, [change]);
    expect(store.deltaFor('device-a').changes, [change]);
  });

  test(
    'SyncEngine routes mixed addressed counters and restores sequences',
    () async {
      final storage = MemoryStorage();
      final transport = TestDeltaTransport();
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: transport,
      );

      final firstG = await engine.incrementGCounter('cart/apples', 2);
      final secondG = await engine.incrementGCounter('cart/pears', 3);
      final firstPn = await engine.incrementPnCounter('account/balance', 5);
      final secondPn = await engine.decrementPnCounter('account/balance', 2);
      await engine.push();

      expect(transport.sent.single.changes, [
        firstG,
        secondG,
        firstPn,
        secondPn,
      ]);
      expect((await storage.pending('device-a')).length, 4);
      await engine.dispose();

      final restored = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );
      await restored.start();
      expect(restored.replica.gCounterValue('cart/apples'), 2);
      expect(restored.replica.gCounterValue('cart/pears'), 3);
      expect(restored.replica.pnCounterValue('account/balance'), 3);
      expect((await restored.incrementGCounter('cart/apples')).dot!.counter, 2);
      expect(
        (await restored.incrementPnCounter('account/balance')).dot!.counter,
        3,
      );
      await restored.dispose();
    },
  );

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
    expect(
      (await storage.pending('device-a')).single.changeIds.single,
      change.id,
    );
    await second.push();
    expect(secondTransport.sent.single.changes, [change]);
    expect(
      (await storage.pending('device-a')).single.changeIds.single,
      change.id,
    );
    await second.dispose();
  });

  test(
    'legacy operation snapshot migrates to compact native snapshot',
    () async {
      final storage = MemoryStorage();
      await storage.saveReplica(
        ReplicaSnapshot(
          replicaId: 'device-a',
          state: const {},
          clock: VectorClock({'device-a': 1}),
          metadata: {
            'delta': {
              'operations': [
                {
                  'id': 'device-a:1',
                  'replicaId': 'device-a',
                  'type': 'lww.set',
                  'vectorClock': {'device-a': 1},
                  'payload': {'key': 'title', 'value': 'legacy'},
                },
              ],
              'crdtChanges': [],
            },
            'hlc': const HlcTimestamp(1, 0).toJson(),
          },
        ),
      );
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );

      await engine.start();

      expect(engine.replica.state.values, {'title': 'legacy'});
      expect((await storage.loadReplica('device-a'))!.metadata.keys, {
        'replicaState',
      });
      await engine.dispose();
    },
  );

  test(
    'failed local commit leaves active replica and outbox unchanged',
    () async {
      final storage = FailOnceCommitStorage();
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );
      await expectLater(engine.setDelta('title', 'draft'), throwsStateError);
      expect(engine.replica.state.values, isEmpty);
      expect(await storage.pending('device-a'), isEmpty);

      final committed = await engine.setDelta('title', 'saved');
      expect(committed.id, 'device-a:delta:1');
      expect(engine.replica.state.values, {'title': 'saved'});
      expect((await storage.pending('device-a')).single.changeIds, [
        committed.id,
      ]);
    },
  );

  test(
    'failed remote snapshot commit leaves active replica unchanged',
    () async {
      final storage = FailOnceSnapshotStorage();
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );
      await engine.start();
      storage.failNextSnapshot = true;
      final remote = Replica('remote')..setDelta('title', 'remote');

      await expectLater(engine.applyRemote(remote.export()), throwsStateError);
      expect(engine.replica.state.values, isEmpty);
      await engine.applyRemote(remote.export());
      expect(engine.replica.state.values, {'title': 'remote'});
      await engine.dispose();
    },
  );

  test('concurrent local mutations serialize IDs and commits', () async {
    final storage = MemoryStorage();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: TestDeltaTransport(),
    );
    final changes = await Future.wait([
      for (var index = 0; index < 12; index++)
        engine.setDelta('key-$index', index),
    ]);

    expect(changes.map((change) => change.id).toSet(), hasLength(12));
    expect(engine.replica.state.values, hasLength(12));
    expect(await storage.pending('device-a'), hasLength(12));
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

    expect(transport.sent.single.changes, [change]);
    expect(await storage.pending('device-a'), isEmpty);
    await engine.dispose();
  });

  test('ACK handles all changes in one outbox entry', () async {
    final storage = MemoryStorage();
    final first = Replica('device-a');
    final firstChange = first.setDelta('first', 1);
    final secondChange = first.setDelta('second', 2);
    await storage.enqueue(
      OutboxEntry(delta: Delta([firstChange, secondChange])),
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

  test(
    'partial ACK keeps remainder and ignores IDs outside sent batch',
    () async {
      final storage = MemoryStorage();
      final source = Replica('device-a');
      final first = source.setDelta('first', 1);
      final second = source.setDelta('second', 2);
      final deferred = source.setDelta('deferred', 3);
      await storage.enqueue(OutboxEntry(delta: Delta([first, second])));
      await storage.enqueue(OutboxEntry(delta: Delta([deferred])));
      await storage.markSent('device-a', [deferred.id]);

      final transport = SelectiveAckTransport([
        first.id,
        deferred.id,
        'foreign',
      ]);
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: transport,
        retryPolicy: const SyncRetryPolicy(baseDelay: Duration(days: 1)),
      );

      await engine.push();

      final pending = await storage.pending('device-a');
      expect(pending.map((entry) => entry.changeIds.single).toSet(), {
        second.id,
        deferred.id,
      });
      final unacknowledgedBatch = pending.singleWhere(
        (entry) => entry.changeIds.contains(second.id),
      );
      expect(unacknowledgedBatch.status, OutboxStatus.sent);
      expect(unacknowledgedBatch.attempts, 1);
      expect(transport.sent.single.changes.map((change) => change.id), [
        first.id,
        second.id,
      ]);
      await engine.dispose();
    },
  );

  test(
    'timeout preserves outbox and retry can ACK it after engine restart',
    () async {
      final storage = MemoryStorage();
      final firstTransport = TimeoutOnceAckTransport();
      final first = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: firstTransport,
        retryPolicy: const SyncRetryPolicy(baseDelay: Duration.zero),
      );
      final change = await first.setDelta('title', 'draft');

      await expectLater(first.push(), throwsA(isA<TimeoutException>()));
      expect((await storage.pending('device-a')).single.attempts, 1);
      await first.dispose();

      final retryTransport = AcknowledgingTestDeltaTransport();
      final restarted = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: retryTransport,
        retryPolicy: const SyncRetryPolicy(baseDelay: Duration.zero),
      );
      await restarted.start();
      await restarted.push();

      expect(retryTransport.sent.single.changes, [change]);
      expect(await storage.pending('device-a'), isEmpty);
      await restarted.dispose();
    },
  );

  test('unacknowledged entry retries only when due or forced', () async {
    final storage = MemoryStorage();
    final transport = TestDeltaTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
      retryPolicy: const SyncRetryPolicy(
        baseDelay: Duration(days: 1),
        maxAttempts: 1,
      ),
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

    final remote = Replica('remote')..setDelta('title', 'ignored');
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

class FailOnceCommitStorage extends MemoryStorage {
  bool _fail = true;

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    if (_fail) {
      _fail = false;
      throw StateError('commit failed');
    }
    await super.commit(snapshot, entries);
  }
}

class FailOnceSnapshotStorage extends MemoryStorage {
  bool failNextSnapshot = false;

  @override
  Future<void> commitRemote(ReplicaSnapshot snapshot) async {
    if (failNextSnapshot) {
      failNextSnapshot = false;
      throw StateError('snapshot commit failed');
    }
    await super.commitRemote(snapshot);
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

class FailOnceDeltaTransport extends TestDeltaTransport {
  bool _fail = true;

  @override
  Future<void> send(Delta delta) async {
    if (_fail) {
      _fail = false;
      throw StateError('send failed');
    }
    await super.send(delta);
  }
}

class AcknowledgingTestDeltaTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  @override
  Future<Iterable<String>> sendAndAwaitAck(Delta delta) async {
    await send(delta);
    return delta.changes.map((change) => change.id);
  }
}

class SelectiveAckTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  SelectiveAckTransport(this.acknowledgedIds);

  final List<String> acknowledgedIds;

  @override
  Future<Iterable<String>> sendAndAwaitAck(Delta delta) async {
    await send(delta);
    return acknowledgedIds;
  }
}

class TimeoutOnceAckTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  bool _timeout = true;

  @override
  Future<Iterable<String>> sendAndAwaitAck(Delta delta) async {
    await send(delta);
    if (_timeout) {
      _timeout = false;
      throw TimeoutException('ACK timed out');
    }
    return delta.changes.map((change) => change.id);
  }
}
