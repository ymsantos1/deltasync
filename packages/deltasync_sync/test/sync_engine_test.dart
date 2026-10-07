// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  test(
    'offline peer recovery stays bound to that peer and durable ACK stage',
    () async {
      final storage = MemoryStorage();
      final firstTransport = FailOnceDeltaTransport(peerReplicaId: 'peer-b');
      final first = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: firstTransport,
      );
      final change = await first.setDelta('title', 'draft');
      await expectLater(first.push(), throwsA(isA<StateError>()));
      expect(
        (await storage.pending('device-a')).single.recipientPeerId,
        'peer-b',
      );
      await first.dispose();

      final otherPeer = AcknowledgingTestDeltaTransport(
        peerReplicaId: 'peer-c',
      );
      final switched = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: otherPeer,
      );
      expect((await switched.push()).sent.isEmpty, isTrue);
      expect(
        (await storage.pending('device-a')).single.recipientPeerId,
        'peer-b',
      );
      await switched.dispose();

      final receiptOnly = FixedStageAckTransport(
        peerReplicaId: 'peer-b',
        stage: DeltaAckStage.received,
      );
      final receiver = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: receiptOnly,
      );
      final receiptResult = await receiver.push(force: true);
      expect(receiptResult.acknowledgedIds, isEmpty);
      expect(receiptResult.acknowledgement?.stage, DeltaAckStage.received);
      expect((await storage.pending('device-a')).single.changeIds, [change.id]);
      await receiver.dispose();

      final persisted = AcknowledgingTestDeltaTransport(
        peerReplicaId: 'peer-b',
      );
      final retry = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: persisted,
      );
      final result = await retry.push(force: true);
      expect(result.acknowledgedIds, {change.id});
      expect(persisted.sent.single.recipientReplicaId, 'peer-b');
      expect(await storage.pending('device-a'), isEmpty);
      await retry.dispose();
    },
  );

  test('ACK from a different peer cannot clear the target outbox', () async {
    final storage = MemoryStorage();
    final transport = FixedStageAckTransport(
      peerReplicaId: 'peer-b',
      ackPeerReplicaId: 'peer-c',
      stage: DeltaAckStage.appliedAndPersisted,
    );
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
    );
    await engine.setDelta('title', 'draft');

    await expectLater(engine.push(), throwsStateError);
    expect(
      (await storage.pending('device-a')).single.recipientPeerId,
      'peer-b',
    );
    await engine.dispose();
  });

  test(
    'OR-Set sync keeps concurrent tags and old tags removed after restore',
    () async {
      final leftStorage = MemoryStorage();
      final rightStorage = MemoryStorage();
      final leftLink = ConnectedPeerTransport(
        localReplicaId: 'left-or',
        peerReplicaId: 'right-or',
      );
      final rightLink = ConnectedPeerTransport(
        localReplicaId: 'right-or',
        peerReplicaId: 'left-or',
      );
      var left = SyncEngine.withStorage(
        replica: Replica('left-or'),
        storage: leftStorage,
        transport: leftLink,
      );
      var right = SyncEngine.withStorage(
        replica: Replica('right-or'),
        storage: rightStorage,
        transport: rightLink,
      );
      leftLink.receiver = right;
      rightLink.receiver = left;
      await Future.wait([left.start(), right.start()]);

      final original = await left.addOrSet('members', 'reader');
      await left.push();
      final observedRemoval = await right.removeOrSet('members', 'reader');
      final concurrentAdd = await left.addOrSet('members', 'reader');
      expect(observedRemoval.observedDots, [original.dot]);
      await left.push();
      await right.push();
      expect(left.replica.orSetValue('members'), {'reader'});
      expect(right.replica.orSetValue('members'), {'reader'});

      await right.removeOrSet('members', 'reader');
      await right.push();
      expect(left.replica.orSetValue('members'), isEmpty);
      expect(right.replica.orSetValue('members'), isEmpty);

      await left.addOrSet('members', 'reader');
      await left.push();
      expect(right.replica.orSetValue('members'), {'reader'});
      await right.removeOrSet('members', 'reader');
      await right.push();
      expect(left.replica.orSetValue('members'), isEmpty);
      expect(right.replica.orSetValue('members'), isEmpty);
      await right.dispose();

      right = SyncEngine.withStorage(
        replica: Replica('right-or'),
        storage: rightStorage,
        transport: TestDeltaTransport(peerReplicaId: 'left-or'),
      );
      await right.start();
      await right.applyRemote(Delta([original, concurrentAdd]));
      expect(right.replica.orSetValue('members'), isEmpty);
      await left.dispose();
      await right.dispose();
      await leftLink.close();
      await rightLink.close();
    },
  );

  test(
    'OR-Map nested values sync and old value stays hidden after restore',
    () async {
      final leftStorage = MemoryStorage();
      final rightStorage = MemoryStorage();
      final leftLink = ConnectedPeerTransport(
        localReplicaId: 'left-map',
        peerReplicaId: 'right-map',
      );
      final rightLink = ConnectedPeerTransport(
        localReplicaId: 'right-map',
        peerReplicaId: 'left-map',
      );
      var left = SyncEngine.withStorage(
        replica: Replica('left-map'),
        storage: leftStorage,
        transport: leftLink,
      );
      var right = SyncEngine.withStorage(
        replica: Replica('right-map'),
        storage: rightStorage,
        transport: rightLink,
      );
      leftLink.receiver = right;
      rightLink.receiver = left;
      await Future.wait([left.start(), right.start()]);

      await left.addOrMapKey('settings', 'colors');
      await left.push();
      await right.addOrMapKey('settings', 'colors');
      final oldValue = (await left.addOrMapValue(
        'settings',
        'colors',
        'red',
      )).single;
      final concurrentValues = await right.addOrMapValue(
        'settings',
        'colors',
        'blue',
      );
      expect(concurrentValues, hasLength(2));
      await left.push();
      await right.push();
      expect(left.replica.orMapValue('settings')['colors'], {'red', 'blue'});
      expect(
        right.replica.orMapValue('settings'),
        left.replica.orMapValue('settings'),
      );

      await left.removeOrMapKey('settings', 'colors');
      await right.addOrMapKey('settings', 'colors');
      await left.push();
      await right.push();
      expect(left.replica.orMapValue('settings'), {'colors': <Object?>{}});
      expect(right.replica.orMapValue('settings'), {'colors': <Object?>{}});

      await right.removeOrMapKey('settings', 'colors');
      await right.push();
      await right.dispose();
      right = SyncEngine.withStorage(
        replica: Replica('right-map'),
        storage: rightStorage,
        transport: TestDeltaTransport(peerReplicaId: 'left-map'),
      );
      await right.start();
      await right.applyRemote(Delta([oldValue]));
      expect(right.replica.orMapValue('settings'), isEmpty);
      await left.dispose();
      await right.dispose();
      await leftLink.close();
      await rightLink.close();
    },
  );

  test('OR-Map multi-tag update commits state and outbox atomically', () async {
    final storage = FailOnCommitNumberStorage(1);
    final engine = SyncEngine.withStorage(
      replica: Replica('local-map'),
      storage: storage,
      transport: TestDeltaTransport(peerReplicaId: 'remote-map'),
    );
    final remote = Replica('remote-map')
      ..addOrMapKey('settings', 'colors')
      ..addOrMapKey('settings', 'colors');
    await engine.applyRemote(remote.export());

    await expectLater(
      engine.addOrMapValue('settings', 'colors', 'blue'),
      throwsStateError,
    );
    expect(engine.replica.orMapValue('settings'), {'colors': <Object?>{}});
    expect(await storage.pending('local-map'), isEmpty);

    final committed = await engine.addOrMapValue('settings', 'colors', 'blue');
    expect(committed, hasLength(2));
    expect(engine.replica.orMapValue('settings')['colors'], {'blue'});
    expect(await storage.pending('local-map'), hasLength(2));
    await engine.dispose();
  });

  test('peer reconnect applies changes durably before partial ACK', () async {
    final senderStorage = MemoryStorage();
    final receiverStorage = MemoryStorage();
    final receiver = SyncEngine.withStorage(
      replica: Replica('device-b'),
      storage: receiverStorage,
      transport: TestDeltaTransport(peerReplicaId: 'device-a'),
    );
    final link = ConnectedPeerTransport(
      localReplicaId: 'device-a',
      peerReplicaId: 'device-b',
    )..online = false;
    link.receiver = receiver;
    final sender = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: senderStorage,
      transport: link,
    );
    final first = await sender.setDelta('first', 1);
    final second = await sender.setDelta('second', 2);

    await expectLater(sender.push(), throwsA(isA<StateError>()));
    expect(await senderStorage.pending('device-a'), hasLength(2));

    link.online = true;
    link.acknowledgedIds = {first.id};
    final partial = await sender.push(force: true);
    expect(partial.acknowledgedIds, {first.id});
    expect(receiver.replica.state.values, {'first': 1, 'second': 2});
    expect(
      (await receiverStorage.loadReplica('device-b'))!.snapshot,
      isNotNull,
    );
    expect((await senderStorage.pending('device-a')).single.changeIds, [
      second.id,
    ]);

    link.acknowledgedIds = {second.id};
    expect((await sender.push(force: true)).acknowledgedIds, {second.id});
    expect(await senderStorage.pending('device-a'), isEmpty);
    await sender.dispose();
    await receiver.dispose();
    await link.close();
  });

  test(
    'two connected engines converge all current CRDTs and restore identity',
    () async {
      final leftStorage = MemoryStorage();
      final rightStorage = MemoryStorage();
      final leftLink = ConnectedPeerTransport(
        localReplicaId: 'left',
        peerReplicaId: 'right',
      );
      final rightLink = ConnectedPeerTransport(
        localReplicaId: 'right',
        peerReplicaId: 'left',
      );
      final left = SyncEngine.withStorage(
        replica: Replica('left'),
        storage: leftStorage,
        transport: leftLink,
      );
      final right = SyncEngine.withStorage(
        replica: Replica('right'),
        storage: rightStorage,
        transport: rightLink,
      );
      leftLink.receiver = right;
      rightLink.receiver = left;
      await Future.wait([left.start(), right.start()]);

      await Future.wait([
        left.setDelta('title', 'from left'),
        left.incrementGCounter('items', 2),
        left.decrementPnCounter('balance', 3),
        left.addAllGSet('tags', ['from-left', 'shared']),
        left.addAllTwoPSet('membership', ['from-left', 'shared']),
        left.writeMvRegister('profile', 'left'),
        left.removeDelta('obsolete'),
        right.setDelta('title', 'from right'),
        right.incrementGCounter('items', 4),
        right.incrementPnCounter('balance', 8),
        right.addAllGSet('tags', ['from-right', 'shared']),
        right.addAllTwoPSet('membership', ['from-right', 'shared']),
        right.writeMvRegister('profile', 'right'),
      ]);
      expect(
        (await leftStorage.pending('left'))
            .expand((entry) => entry.delta.changes)
            .where((change) => change.kind == CrdtKind.gSet),
        hasLength(1),
      );
      expect(
        (await rightStorage.pending('right'))
            .expand((entry) => entry.delta.changes)
            .where((change) => change.kind == CrdtKind.gSet),
        hasLength(1),
      );
      expect(
        (await leftStorage.pending('left'))
            .expand((entry) => entry.delta.changes)
            .where((change) => change.kind == CrdtKind.twoPSet),
        hasLength(1),
      );
      final results = await Future.wait([left.push(), right.push()]);

      expect(
        results.every((result) => result.acknowledgedIds.isNotEmpty),
        isTrue,
      );
      for (final change in results.first.sent.changes.reversed) {
        await right.applyRemote(Delta([change]));
        await right.applyRemote(Delta([change]));
      }
      expect(await leftStorage.pending('left'), isEmpty);
      expect(await rightStorage.pending('right'), isEmpty);
      expect(
        left.replica.state.values['title'],
        right.replica.state.values['title'],
      );
      for (final engine in [left, right]) {
        expect(engine.replica.state.values['title'], isNotNull);
        expect(engine.replica.gCounterValue('items'), 6);
        expect(engine.replica.pnCounterValue('balance'), 5);
        expect(
          engine.replica.gSetValue('tags'),
          containsAll(['from-left', 'from-right', 'shared']),
        );
        expect(
          engine.replica.twoPSetValue('membership'),
          containsAll(['from-left', 'from-right', 'shared']),
        );
        expect(engine.replica.mvRegisterValue('profile'), {'left', 'right'});
        expect(engine.replica.state.winnerAt('obsolete')?.deleted, isTrue);
      }

      await left.removeTwoPSet('membership', 'shared');
      await left.push();
      expect(
        left.replica.twoPSetValue('membership'),
        isNot(contains('shared')),
      );
      expect(
        right.replica.twoPSetValue('membership'),
        isNot(contains('shared')),
      );
      await right.addTwoPSet('membership', 'shared');
      await right.push();
      expect(
        left.replica.twoPSetValue('membership'),
        isNot(contains('shared')),
      );
      expect(
        right.replica.twoPSetValue('membership'),
        isNot(contains('shared')),
      );

      // Restart from each MemoryStorage instance to verify snapshot identities,
      // tombstones, and counter sequence state survive the simulated recovery.
      final leftSnapshot = left.replica.toSnapshotJson();
      await left.dispose();
      await right.dispose();
      final restoredLeft = SyncEngine.withStorage(
        replica: Replica('left'),
        storage: leftStorage,
        transport: TestDeltaTransport(peerReplicaId: 'right'),
      );
      await restoredLeft.start();
      expect(restoredLeft.replica.id, 'left');
      expect(restoredLeft.replica.state.winnerAt('obsolete')?.deleted, isTrue);
      expect(restoredLeft.replica.gCounterValue('items'), 6);
      expect(restoredLeft.replica.pnCounterValue('balance'), 5);
      expect(
        restoredLeft.replica.gSetValue('tags'),
        containsAll(['from-left', 'from-right', 'shared']),
      );
      expect(
        restoredLeft.replica.twoPSetValue('membership'),
        containsAll(['from-left', 'from-right']),
      );
      expect(restoredLeft.replica.mvRegisterValue('profile'), {
        'left',
        'right',
      });
      expect(
        (await restoredLeft.addTwoPSet('membership', 'shared')).dot.counter,
        3,
      );
      expect(
        restoredLeft.replica.twoPSetValue('membership'),
        isNot(contains('shared')),
      );
      expect(restoredLeft.replica.state.values['title'], 'from right');
      final restoredSnapshot = restoredLeft.replica.toSnapshotJson();
      expect(restoredSnapshot['deltaSequence'], leftSnapshot['deltaSequence']);
      final oldGSet = leftSnapshot['gSets'] as Map<String, Object?>;
      final restoredGSet = restoredSnapshot['gSets'] as Map<String, Object?>;
      expect(
        (restoredGSet['tags'] as Map<String, Object?>)['sequence'],
        (oldGSet['tags'] as Map<String, Object?>)['sequence'],
      );
      expect(
        (await restoredLeft.addGSet('tags', 'after-restart')).dot.counter,
        2,
      );
      final expectedGCounter =
          leftSnapshot['gCounters'] as Map<String, Object?>;
      final restoredGCounter =
          restoredSnapshot['gCounters'] as Map<String, Object?>;
      expect(
        (restoredGCounter['items'] as Map<String, Object?>)['sequences'],
        (expectedGCounter['items'] as Map<String, Object?>)['sequences'],
      );
      final expectedPnCounter =
          leftSnapshot['pnCounters'] as Map<String, Object?>;
      final restoredPnCounter =
          restoredSnapshot['pnCounters'] as Map<String, Object?>;
      expect(
        (restoredPnCounter['balance'] as Map<String, Object?>)['sequences'],
        (expectedPnCounter['balance'] as Map<String, Object?>)['sequences'],
      );
      await restoredLeft.dispose();
      await leftLink.close();
      await rightLink.close();
    },
  );

  test(
    'connected send allows edits and never ACKs a failed remote commit',
    () async {
      final senderStorage = MemoryStorage();
      final receiverStorage = FailOnceSnapshotStorage();
      final receiver = SyncEngine.withStorage(
        replica: Replica('receiver'),
        storage: receiverStorage,
        transport: TestDeltaTransport(peerReplicaId: 'sender'),
      );
      final link = ConnectedPeerTransport(
        localReplicaId: 'sender',
        peerReplicaId: 'receiver',
      )..receiver = receiver;
      final sender = SyncEngine.withStorage(
        replica: Replica('sender'),
        storage: senderStorage,
        transport: link,
      );
      final first = await sender.setDelta('first', true);
      link.holdBeforeRemoteCommit = true;
      final pushing = sender.push();
      await link.sendStarted.future;
      final duringSend = await sender.setDelta('during-send', true);
      expect(sender.replica.state.values['during-send'], isTrue);
      link.releaseRemoteCommit.complete();
      final firstResult = await pushing;
      link.holdBeforeRemoteCommit = false;
      expect(firstResult.acknowledgedIds, {first.id});
      expect((await senderStorage.pending('sender')).single.changeIds, [
        duringSend.id,
      ]);

      receiverStorage.failNextSnapshot = true;
      await expectLater(sender.push(force: true), throwsStateError);
      expect(
        (await senderStorage.pending(
          'sender',
        )).map((entry) => entry.changeIds.single),
        contains(duringSend.id),
      );
      expect(receiver.replica.state.values['during-send'], isNull);
      expect((await sender.push(force: true)).acknowledgedIds, {duringSend.id});
      expect(receiver.replica.state.values['during-send'], isTrue);
      await sender.dispose();
      await receiver.dispose();
      await link.close();
    },
  );

  test('incoming envelope must match fixed sender and recipient', () async {
    final transport = TestDeltaTransport(peerReplicaId: 'peer-b');
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: MemoryStorage(),
      transport: transport,
    );
    await engine.start();
    final errorFuture = engine.errors.first;
    final remote = Replica('peer-c')..setDelta('title', 'not addressed');
    transport.emitDelta(
      remote.export(),
      senderReplicaId: 'peer-c',
      recipientReplicaId: 'device-a',
    );
    final failure = await errorFuture.timeout(const Duration(seconds: 1));
    expect(failure.source, SyncFailureSource.incomingDelta);
    expect(engine.replica.state.values, isEmpty);
    await engine.dispose();
  });

  test('counter sequence maxima carry cumulative state across gaps', () async {
    final source = Replica('source');
    final earlier = source.incrementGCounter('cart/items', 2);
    final later = source.incrementGCounter('cart/items', 3);
    final earlierPn = source.decrementPnCounter('account/balance', 3);
    final laterPn = source.incrementPnCounter('account/balance', 5);
    final receiver = Replica('receiver');

    receiver.apply(Delta([later]));
    receiver.apply(Delta([earlier]));
    receiver.apply(Delta([laterPn]));
    receiver.apply(Delta([earlierPn]));

    expect(receiver.gCounterValue('cart/items'), 5);
    expect(receiver.pnCounterValue('account/balance'), 2);
  });

  test('set persists local operation in outbox', () async {
    final store = TestPendingDeltaStore();
    final transport = TestDeltaTransport();
    final engine = SyncEngine(
      replica: Replica('device-a'),
      store: store,
      transport: transport,
    );

    final operation = await engine.setDelta('title', 'draft');

    expect(store.readCount, 2);
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
      transport.emitDelta(remote.export());
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
    expect(
      transport.sent.map((message) => message.delta.changes.single.id).toSet(),
      {store.deltaFor('device-a').changes.single.id},
    );
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

    expect(transport.sent.single.delta.changes, [change]);
    expect(transport.sent.single.senderReplicaId, 'device-a');
    expect(store.deltaFor('device-a').changes, [change]);
  });

  test(
    'legacy storage exposes remote ACK but retains its pending delta',
    () async {
      final store = TestPendingDeltaStore();
      final engine = SyncEngine(
        replica: Replica('device-a'),
        store: store,
        transport: AcknowledgingTestDeltaTransport(),
      );
      final change = await engine.setDelta('title', 'draft');

      final result = await engine.push();

      expect(result.acknowledgedIds, {change.id});
      expect(result.fullyAcknowledged, isTrue);
      expect((await engine.pendingDelta()).changes.single.id, change.id);
      await engine.dispose();
    },
  );

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

      expect(transport.sent.single.delta.changes, [
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
    expect(secondTransport.sent.single.delta.changes, [change]);
    expect(
      (await storage.pending('device-a')).single.changeIds.single,
      change.id,
    );
    await second.dispose();
  });

  test(
    'remote snapshot bootstrap commits state and preserves local outbox',
    () async {
      final storage = MemoryStorage();
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );
      final local = await engine.setDelta('local', 'pending');
      final remote = Replica('server')
        ..setDelta('remote', 'bootstrapped')
        ..incrementGCounter('items', 3);

      await engine.applyRemoteSnapshot(remote.toSnapshotJson());

      expect(engine.replica.state.values, {
        'local': 'pending',
        'remote': 'bootstrapped',
      });
      expect(engine.replica.gCounterValue('items'), 3);
      expect((await storage.pending('device-a')).single.changeIds, [local.id]);
      await engine.dispose();

      final restarted = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );
      await restarted.start();
      expect(restarted.replica.state.values, {
        'local': 'pending',
        'remote': 'bootstrapped',
      });
      expect(restarted.replica.gCounterValue('items'), 3);
      await restarted.dispose();
    },
  );

  test(
    'legacy operation snapshot migrates to compact native snapshot',
    () async {
      final storage = MemoryStorage();
      await storage.saveReplica(
        ReplicaSnapshot.legacy(
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
      expect((await storage.loadReplica('device-a'))!.version, 2);
      expect((await storage.loadReplica('device-a'))!.snapshot!['version'], 8);
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
    'failed counter commit leaves state, outbox and sequence unchanged',
    () async {
      final storage = FailOnceCommitStorage();
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );

      await expectLater(engine.incrementPnCounter('balance'), throwsStateError);
      expect(engine.replica.pnCounterValue('balance'), 0);
      expect(await storage.pending('device-a'), isEmpty);
      expect((await engine.incrementPnCounter('balance')).dot!.counter, 1);
      expect(await storage.pending('device-a'), hasLength(1));
    },
  );

  test(
    'engine isolates caller and read-view mutations during commit',
    () async {
      final storage = GatedCommitStorage();
      final supplied = Replica('device-a');
      final engine = SyncEngine.withStorage(
        replica: supplied,
        storage: storage,
        transport: TestDeltaTransport(),
      );
      final commit = engine.setDelta('owned', 'committed');
      await storage.commitStarted.future;
      supplied.setDelta('outside', 'must stay outside');
      final view = engine.replica;
      view.setDelta('view', 'must stay detached');
      storage.releaseCommit.complete();
      await commit;

      expect(engine.replica.state.values, {'owned': 'committed'});
      expect(supplied.state.values, {'outside': 'must stay outside'});
      expect(await storage.pending('device-a'), hasLength(1));
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

    expect(transport.sent.single.delta.changes, [change]);
    expect(await storage.pending('device-a'), isEmpty);
    await engine.dispose();
  });

  test('ACK handles a send batch backed by one entry per change', () async {
    final storage = MemoryStorage();
    final first = Replica('device-a');
    final firstChange = first.setDelta('first', 1);
    final secondChange = first.setDelta('second', 2);
    await storage.enqueue(
      OutboxEntry(delta: Delta([firstChange]), recipientPeerId: 'remote'),
    );
    await storage.enqueue(
      OutboxEntry(delta: Delta([secondChange]), recipientPeerId: 'remote'),
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
      await storage.enqueue(
        OutboxEntry(delta: Delta([first]), recipientPeerId: 'remote'),
      );
      await storage.enqueue(
        OutboxEntry(delta: Delta([second]), recipientPeerId: 'remote'),
      );
      await storage.enqueue(
        OutboxEntry(delta: Delta([deferred]), recipientPeerId: 'remote'),
      );
      await storage.markSent('device-a', 'remote', [deferred.id]);

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
      expect(transport.sent.single.delta.changes.map((change) => change.id), [
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

      expect(retryTransport.sent.single.delta.changes, [change]);
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
    transport.emitDelta(remote.export());
    await Future<void>.delayed(Duration.zero);

    expect(engine.replica.state.values, isEmpty);
  });

  test(
    'first mutation restores before writing and lifecycle is observable',
    () async {
      final storage = MemoryStorage();
      final restored = Replica('device-a')..setDelta('saved', 'from disk');
      await storage.saveReplica(ReplicaSnapshot.fromReplica(restored));
      final engine = SyncEngine.withStorage(
        replica: Replica('device-a'),
        storage: storage,
        transport: TestDeltaTransport(),
      );

      expect(engine.lifecycle, SyncEngineLifecycle.created);
      expect(() => engine.replica, throwsStateError);
      final local = await engine.setDelta('local', 'new edit');

      expect(engine.lifecycle, SyncEngineLifecycle.started);
      expect(engine.replica.state.values, {
        'saved': 'from disk',
        'local': 'new edit',
      });
      expect((await engine.pendingDelta()).changes.single.id, local.id);
      await engine.start();
      expect(engine.lifecycle, SyncEngineLifecycle.started);
      await engine.dispose();
      expect(engine.lifecycle, SyncEngineLifecycle.disposed);
      await expectLater(engine.setDelta('late', true), throwsStateError);
      await expectLater(
        engine.applyRemote(const Delta.empty()),
        throwsStateError,
      );
      await expectLater(engine.pendingDelta(), throwsStateError);
      await expectLater(engine.push(), throwsStateError);
    },
  );

  test('failed start returns to created and can be retried', () async {
    final storage = FailOnceLoadStorage();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: TestDeltaTransport(),
    );

    await expectLater(engine.start(), throwsStateError);
    expect(engine.lifecycle, SyncEngineLifecycle.created);
    await engine.start();
    expect(engine.lifecycle, SyncEngineLifecycle.started);
    await engine.dispose();
  });

  test('slow send does not block local commit or remote application', () async {
    final storage = MemoryStorage();
    final transport = GatedAckTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
    );
    final first = await engine.setDelta('first', 1);
    final pushing = engine.push();
    await transport.sendStarted.future;

    final local = await engine.setDelta('during-send', 2);
    final remote = Replica('remote')..setDelta('remote', 3);
    await engine.applyRemote(remote.export());
    expect(engine.replica.state.values, {
      'first': 1,
      'during-send': 2,
      'remote': 3,
    });

    transport.release.complete();
    final result = await pushing;
    expect(result.sent.changes.map((change) => change.id), [first.id]);
    expect(result.acknowledgedIds, {first.id});
    expect(result.fullyAcknowledged, isTrue);
    expect((await engine.pendingDelta()).changes.map((change) => change.id), [
      local.id,
    ]);
    await engine.dispose();
  });

  test('incoming failures are observable and do not partially apply', () async {
    final storage = MemoryStorage();
    final transport = TestDeltaTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
    );
    final failureFuture = engine.errors.first;
    await engine.start();

    final lww = Replica('remote-lww')..setDelta('collision', 'value');
    final counter = Replica('remote-counter')
      ..incrementGCounter('collision', 1);
    transport.emitDelta(lww.export().merge(counter.export()));
    final failure = await failureFuture.timeout(const Duration(seconds: 1));

    expect(failure.source, SyncFailureSource.incomingDelta);
    expect(failure.error, isA<FormatException>());
    expect(engine.replica.state.values, isEmpty);
    expect(engine.replica.gCounterValue('collision'), 0);

    final streamErrorFuture = engine.errors.first;
    transport.emitError(StateError('incoming stream failed'));
    final streamFailure = await streamErrorFuture.timeout(
      const Duration(seconds: 1),
    );
    expect(streamFailure.source, SyncFailureSource.incomingStream);
    expect(streamFailure.error, isA<StateError>());
    await engine.dispose();
  });

  test('dispose waits for active push and then rejects new work', () async {
    final storage = MemoryStorage();
    final transport = GatedAckTransport();
    final engine = SyncEngine.withStorage(
      replica: Replica('device-a'),
      storage: storage,
      transport: transport,
    );
    await engine.setDelta('title', 'pending');
    final pushing = engine.push();
    await transport.sendStarted.future;
    final disposing = engine.dispose();
    expect(engine.lifecycle, SyncEngineLifecycle.disposed);
    await Future<void>.delayed(Duration.zero);
    expect(await storage.pending('device-a'), hasLength(1));

    transport.release.complete();
    final result = await pushing;
    await disposing;
    expect(result.fullyAcknowledged, isTrue);
    expect(await storage.pending('device-a'), isEmpty);
    await expectLater(engine.push(), throwsStateError);
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

class FailOnCommitNumberStorage extends MemoryStorage {
  FailOnCommitNumberStorage(this.failAt);

  final int failAt;
  var _commitCount = 0;

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    if (++_commitCount == failAt) throw StateError('commit failed');
    await super.commit(snapshot, entries);
  }
}

class GatedCommitStorage extends MemoryStorage {
  final commitStarted = Completer<void>();
  final releaseCommit = Completer<void>();

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    commitStarted.complete();
    await releaseCommit.future;
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

class FailOnceLoadStorage extends MemoryStorage {
  bool _fail = true;

  @override
  Future<ReplicaSnapshot?> loadReplica(String replicaId) async {
    if (_fail) {
      _fail = false;
      throw StateError('load failed');
    }
    return super.loadReplica(replicaId);
  }
}

class TestDeltaTransport implements DeltaTransport {
  TestDeltaTransport({this.peerReplicaId = 'remote'});

  @override
  final String peerReplicaId;

  final StreamController<DeltaEnvelope> _incoming =
      StreamController<DeltaEnvelope>.broadcast();
  final List<DeltaEnvelope> sent = [];

  @override
  Stream<DeltaEnvelope> get incoming => _incoming.stream;

  @override
  Future<void> send(DeltaEnvelope envelope) async => sent.add(envelope);

  void emitDelta(
    Delta delta, {
    String senderReplicaId = 'remote',
    String recipientReplicaId = 'device-a',
  }) => _incoming.add(
    DeltaEnvelope(
      senderReplicaId: senderReplicaId,
      recipientReplicaId: recipientReplicaId,
      delta: delta,
    ),
  );

  void emitError(Object error) => _incoming.addError(error, StackTrace.current);
}

class FailOnceDeltaTransport extends TestDeltaTransport {
  FailOnceDeltaTransport({super.peerReplicaId});

  bool _fail = true;

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    if (_fail) {
      _fail = false;
      throw StateError('send failed');
    }
    await super.send(envelope);
  }
}

class AcknowledgingTestDeltaTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  AcknowledgingTestDeltaTransport({super.peerReplicaId});

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await send(envelope);
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }
}

class FixedStageAckTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  FixedStageAckTransport({
    required super.peerReplicaId,
    String? ackPeerReplicaId,
    required this.stage,
  }) : _ackPeerReplicaId = ackPeerReplicaId ?? peerReplicaId;

  final DeltaAckStage stage;
  final String _ackPeerReplicaId;

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await send(envelope);
    return DeltaAcknowledgement(
      peerReplicaId: _ackPeerReplicaId,
      stage: stage,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }
}

class ConnectedPeerTransport implements AcknowledgingDeltaTransport {
  ConnectedPeerTransport({
    required this.localReplicaId,
    required this.peerReplicaId,
  });

  final String localReplicaId;
  @override
  final String peerReplicaId;
  final StreamController<DeltaEnvelope> _incoming =
      StreamController<DeltaEnvelope>.broadcast();
  SyncEngine? receiver;
  bool online = true;
  Set<String>? acknowledgedIds;
  bool holdBeforeRemoteCommit = false;
  final sendStarted = Completer<void>();
  final releaseRemoteCommit = Completer<void>();

  @override
  Stream<DeltaEnvelope> get incoming => _incoming.stream;

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    if (!online) throw StateError('peer offline');
    final target = receiver;
    await target?.start();
    if (envelope.senderReplicaId != localReplicaId ||
        envelope.recipientReplicaId != peerReplicaId ||
        target == null ||
        target.replica.id != peerReplicaId) {
      throw StateError('peer link identity mismatch');
    }
    if (holdBeforeRemoteCommit) {
      sendStarted.complete();
      await releaseRemoteCommit.future;
    }
    await target.applyRemote(envelope.delta);
  }

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await send(envelope);
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds:
          acknowledgedIds ?? envelope.delta.changes.map((change) => change.id),
    );
  }

  Future<void> close() => _incoming.close();
}

class SelectiveAckTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  SelectiveAckTransport(this.acknowledgedIds);

  final List<String> acknowledgedIds;

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await send(envelope);
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: acknowledgedIds,
    );
  }
}

class TimeoutOnceAckTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  bool _timeout = true;

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await send(envelope);
    if (_timeout) {
      _timeout = false;
      throw TimeoutException('ACK timed out');
    }
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }
}

class GatedAckTransport extends TestDeltaTransport
    implements AcknowledgingDeltaTransport {
  final sendStarted = Completer<void>();
  final release = Completer<void>();

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    sent.add(envelope);
    sendStarted.complete();
    await release.future;
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }
}
