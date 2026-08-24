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
