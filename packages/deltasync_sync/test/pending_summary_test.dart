import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  SyncEngine open(_Storage storage, [_Transport? transport]) =>
      SyncEngine.withStorage(
        replica: Replica('summary'),
        storage: storage,
        transport: transport ?? _Transport(),
      );

  test(
    'summary initializes, scopes peers, and never requests payload batches',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      addTearDown(engine.dispose);
      expect((await engine.pendingSummary()).totalCount, 0);
      final change = await engine.setDelta('field', 'committed');
      await storage.enqueue(
        OutboxEntry(delta: Delta([change]), recipientPeerId: 'other'),
      );
      storage.rejectPayloadReads = true;
      expect((await engine.pendingSummary()).pendingCount, 2);
      expect(
        (await engine.pendingSummary(recipientPeerId: 'peer')).pendingCount,
        1,
      );
      expect(
        (await engine.pendingSummary(recipientPeerId: 'missing')).totalCount,
        0,
      );
      expect(engine.valueAt('field'), 'committed');
    },
  );

  test(
    'summary error preserves committed edits and releases queue for retry',
    () async {
      final storage = _Storage();
      final engine = open(storage);
      await engine.setDelta('saved', 1);
      storage.failSummary = true;
      await expectLater(engine.pendingSummary(), throwsStateError);
      await engine.setDelta('saved', 2);
      expect(engine.valueAt('saved'), 2);
      storage.failSummary = false;
      expect((await engine.pendingSummary()).pendingCount, 2);
      await engine.dispose();
      await expectLater(engine.pendingSummary(), throwsStateError);
    },
  );

  test('summary retries failed initialization', () async {
    final storage = _Storage()..failLoad = true;
    final engine = open(storage);
    addTearDown(engine.dispose);
    await expectLater(engine.pendingSummary(), throwsStateError);
    storage.failLoad = false;
    expect((await engine.pendingSummary()).totalCount, 0);
  });

  test('summary waits for accepted local commit, including rollback', () async {
    final storage = _Storage();
    final engine = open(storage);
    addTearDown(engine.dispose);
    await engine.start();
    storage.gate = Completer<void>();
    storage.entered = Completer<void>();
    final writing = engine.setDelta('field', 'new');
    await storage.entered!.future;
    var completed = false;
    final reading = engine.pendingSummary().then((value) {
      completed = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    storage.gate!.complete();
    await writing;
    expect((await reading).totalCount, 1);
    storage.gate = null;
    storage.entered = null;
    storage.failCommit = true;
    await expectLater(engine.setDelta('field', 'failed'), throwsStateError);
    expect((await engine.pendingSummary()).totalCount, 1);
    expect(engine.valueAt('field'), 'new');
  });

  test(
    'network waits allow summary/edit and partial ACK only clears accepted IDs',
    () async {
      final storage = _Storage();
      final transport = _Transport();
      final engine = open(storage, transport);
      addTearDown(engine.dispose);
      final first = await engine.setDelta('first', 1);
      await engine.setDelta('second', 2);
      final pushing = engine.push();
      await transport.entered.future;
      expect((await engine.pendingSummary()).sentCount, 2);
      await engine.setDelta('third', 3);
      final during = await engine.pendingSummary();
      expect([during.pendingCount, during.sentCount], [1, 2]);
      transport.reply.complete(
        DeltaAcknowledgement(
          peerReplicaId: 'peer',
          stage: DeltaAckStage.appliedAndPersisted,
          changeIds: [first.id],
        ),
      );
      await pushing;
      final after = await engine.pendingSummary();
      expect(
        [after.pendingCount, after.sentCount, after.totalCount],
        [1, 1, 2],
      );
    },
  );
}

class _Storage extends MemoryStorage {
  bool rejectPayloadReads = false;
  bool failSummary = false;
  bool failLoad = false;
  bool failCommit = false;
  Completer<void>? gate;
  Completer<void>? entered;
  @override
  Future<OutboxSummary> pendingSummary(
    String replicaId, {
    String? recipientPeerId,
  }) {
    if (failSummary) return Future.error(StateError('summary unavailable'));
    return super.pendingSummary(replicaId, recipientPeerId: recipientPeerId);
  }

  @override
  Future<List<OutboxEntry>> pending(
    String replicaId, {
    String? recipientPeerId,
  }) {
    if (rejectPayloadReads) {
      return Future.error(StateError('Payload read not allowed'));
    }
    return super.pending(replicaId, recipientPeerId: recipientPeerId);
  }

  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) {
    if (failLoad) return Future.error(StateError('load unavailable'));
    return super.loadReplica(replicaId);
  }

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    entered?.complete();
    await gate?.future;
    if (failCommit) throw StateError('commit failed');
    await super.commit(snapshot, entries);
  }
}

class _Transport implements AcknowledgingDeltaTransport {
  final entered = Completer<void>();
  final reply = Completer<DeltaAcknowledgement>();
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) {
    entered.complete();
    return reply.future;
  }
}
