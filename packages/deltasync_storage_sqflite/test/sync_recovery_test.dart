import 'dart:async';
import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();

  group('SQLite sync recovery', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('deltasync-recovery-');
    });

    tearDown(() => directory.delete(recursive: true));

    test('start retries transient open and restores before editing', () async {
      const replicaId = 'durable-device';
      final path = '${directory.path}/open-retry.sqlite';
      final originalStorage = _storage(path);
      final originalTransport = _PeerTransport('peer');
      final original = _engine(replicaId, originalStorage, originalTransport);
      await original.start();
      final oldChange = await original.setDelta('name', 'Ada');
      await original.dispose();
      await originalStorage.close();
      await originalTransport.close();

      final factory = _ControlledOpenFactory(failFirst: true);
      final storage = SqfliteReplicaStorage(
        databaseFactory: factory,
        databasePath: path,
      );
      final transport = _PeerTransport('peer');
      final engine = _engine(replicaId, storage, transport);

      await expectLater(engine.start(), throwsStateError);
      expect(factory.opens, 1);
      expect(engine.lifecycle, SyncEngineLifecycle.created);

      await engine.start();
      expect(factory.opens, 2);
      expect(engine.lifecycle, SyncEngineLifecycle.started);
      expect(engine.replica.state.values, {'name': 'Ada'});
      expect((await storage.pending(replicaId)).single.entryId, oldChange.id);

      final next = await engine.setDelta('next', true);
      expect(next.id, isNot(oldChange.id));
      expect(engine.replica.state.values, {'name': 'Ada', 'next': true});
      expect(
        (await storage.pending(
          replicaId,
        )).map((entry) => entry.entryId).toSet(),
        {oldChange.id, next.id},
      );
      await engine.dispose();
      await storage.close();
      await transport.close();
    });

    test('concurrent callers share a failed open and later retry', () async {
      final gate = Completer<void>();
      final factory = _ControlledOpenFactory(failFirst: true, firstGate: gate);
      final storage = SqfliteReplicaStorage(
        databaseFactory: factory,
        databasePath: '${directory.path}/concurrent.sqlite',
      );
      final first = storage.loadReplica('device');
      final second = storage.loadReplica('device');
      expect(factory.opens, 1);
      final firstError = expectLater(first, throwsStateError);
      final secondError = expectLater(second, throwsStateError);
      gate.complete();
      await Future.wait([firstError, secondError]);

      expect(await storage.loadReplica('device'), isNull);
      expect(factory.opens, 2);
      await storage.close();
    });

    test('old open failure cannot clear a newer successful opening', () async {
      final gate = Completer<void>();
      final factory = _ControlledOpenFactory(failFirst: true, firstGate: gate);
      final storage = SqfliteReplicaStorage(
        databaseFactory: factory,
        databasePath: '${directory.path}/stale-open.sqlite',
      );
      final firstError = expectLater(
        storage.loadReplica('device'),
        throwsStateError,
      );
      final closeError = expectLater(storage.close(), throwsStateError);
      expect(await storage.loadReplica('device'), isNull);
      expect(factory.opens, 2);

      gate.complete();
      await Future.wait([firstError, closeError]);
      expect(await storage.loadReplica('device'), isNull);
      expect(factory.opens, 2);
      await storage.close();
    });

    test('incompatible schema fails each retry and preserves data', () async {
      final path = '${directory.path}/incompatible.sqlite';
      final baseline = _storage(path);
      final replica = Replica('device')..setDelta('name', 'Ada');
      await baseline.saveReplica(ReplicaSnapshot.fromReplica(replica));
      await baseline.close();
      final newer = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 2),
      );
      await newer.close();

      final factory = _ControlledOpenFactory();
      final incompatible = SqfliteReplicaStorage(
        databaseFactory: factory,
        databasePath: path,
      );
      await expectLater(
        incompatible.loadReplica(replica.id),
        throwsFormatException,
      );
      await expectLater(
        incompatible.loadReplica(replica.id),
        throwsFormatException,
      );
      expect(factory.opens, 2);
      final preserved = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 2),
      );
      expect(await preserved.query('deltasync_snapshots'), hasLength(1));
      await preserved.close();
    });

    test(
      'restores identity, HLC, counter dots, tombstone, and pending outbox',
      () async {
        const replicaId = 'durable-device';
        final path = '${directory.path}/replica.sqlite';
        final transport = _PeerTransport('peer');
        var storage = _storage(path);
        var engine = _engine(replicaId, storage, transport);
        await engine.start();
        await engine.setDelta('name', 'Ada');
        final tombstone = await engine.removeDelta('name');
        final g1 = await engine.incrementGCounter('visits');
        final p1 = await engine.incrementPnCounter('balance', 4);
        final before = engine.replica;
        final timestamp = before.hlcTimestamp;
        final pendingIds = (await storage.pending(replicaId))
            .expand((entry) => entry.delta.changes)
            .map((change) => change.id)
            .toSet();
        expect(pendingIds, containsAll([g1.id, p1.id]));
        expect(before.state.winnerAt('name')!.deleted, isTrue);

        await engine.dispose();
        await storage.close();
        storage = _storage(path);
        engine = _engine(replicaId, storage, transport);
        await engine.start();
        final restored = engine.replica;
        expect(restored.id, replicaId);
        expect(
          restored.hlcTimestamp.compareTo(timestamp),
          greaterThanOrEqualTo(0),
        );
        expect(restored.state.winnerAt('name')!.deleted, isTrue);
        expect(restored.gCounterValue('visits'), 1);
        expect(restored.pnCounterValue('balance'), 4);
        expect(
          (await storage.pending(replicaId))
              .expand((entry) => entry.delta.changes)
              .map((change) => change.id)
              .toSet(),
          pendingIds,
        );
        final next = await engine.setDelta('after-reopen', true);
        final g2 = await engine.incrementGCounter('visits');
        final p2 = await engine.decrementPnCounter('balance', 2);
        expect(next.timestamp.compareTo(timestamp), greaterThan(0));
        expect(pendingIds, isNot(contains(next.id)));
        expect(pendingIds, contains(tombstone.id));
        expect(g2.dot!.counter, greaterThan(g1.dot!.counter));
        expect(p2.dot!.counter, greaterThan(p1.dot!.counter));
        await engine.dispose();
        await storage.close();
        await transport.close();
      },
    );

    test(
      'restores all eight CRDTs and mixed outbox before SQLite peer delivery',
      () async {
        var senderStorage = _storage('${directory.path}/sender-all.sqlite');
        var receiverStorage = _storage('${directory.path}/receiver-all.sqlite');
        final receiverTransport = _PeerTransport('sender-all');
        final senderTransport = _PeerTransport('receiver-all')
          ..receiver = _engine(
            'receiver-all',
            receiverStorage,
            receiverTransport,
          )
          ..failBeforeDeliveryOnce = true;
        var sender = _engine('sender-all', senderStorage, senderTransport);
        await Future.wait([sender.start(), senderTransport.receiver!.start()]);

        await sender.setDelta('lww', 'value');
        await sender.incrementGCounter('g-counter', 2);
        await sender.decrementPnCounter('pn-counter', 3);
        await sender.addGSet('g-set', 'kept');
        final twoPAdd = await sender.addTwoPSet('two-p-set', 'removed');
        await sender.removeTwoPSet('two-p-set', 'removed');
        await sender.writeMvRegister('mv-register', 'version');
        final orSetAdd = await sender.addOrSet('or-set', 'removed');
        await sender.removeOrSet('or-set', 'removed');
        final orMapKeyAdd = await sender.addOrMapKey('or-map', 'removed');
        final orMapValueAdd = (await sender.addOrMapValue(
          'or-map',
          'removed',
          'value',
        )).single;
        await sender.removeOrMapKey('or-map', 'removed');

        await expectLater(sender.push(), throwsStateError);
        final pendingIds = (await senderStorage.pending(
          'sender-all',
        )).expand((entry) => entry.changeIds).toSet();
        expect(pendingIds, hasLength(12));
        expect(sender.replica.twoPSetValue('two-p-set'), isEmpty);
        expect(sender.replica.orSetValue('or-set'), isEmpty);
        expect(sender.replica.orMapValue('or-map'), isEmpty);

        await _dispose(
          [sender, senderTransport.receiver!],
          [senderStorage, receiverStorage],
          [senderTransport, receiverTransport],
        );
        senderStorage = _storage('${directory.path}/sender-all.sqlite');
        receiverStorage = _storage('${directory.path}/receiver-all.sqlite');
        final reopenedReceiverTransport = _PeerTransport('sender-all');
        final reopenedSenderTransport = _PeerTransport('receiver-all')
          ..receiver = _engine(
            'receiver-all',
            receiverStorage,
            reopenedReceiverTransport,
          );
        sender = _engine('sender-all', senderStorage, reopenedSenderTransport);
        reopenedSenderTransport.failBeforeDeliveryOnce = false;
        await Future.wait([
          sender.start(),
          reopenedSenderTransport.receiver!.start(),
        ]);

        _expectAllCrdts(sender.replica);
        await sender.applyRemote(
          Delta([twoPAdd, orSetAdd, orMapKeyAdd, orMapValueAdd]),
        );
        expect(sender.replica.twoPSetValue('two-p-set'), isEmpty);
        expect(sender.replica.orSetValue('or-set'), isEmpty);
        expect(sender.replica.orMapValue('or-map'), isEmpty);
        expect(
          (await senderStorage.pending(
            'sender-all',
          )).expand((entry) => entry.changeIds).toSet(),
          pendingIds,
        );
        final result = await sender.push(force: true);
        expect(result.sent.changes, hasLength(12));
        expect(result.acknowledgedIds, pendingIds);
        expect(await senderStorage.pending('sender-all'), isEmpty);
        _expectAllCrdts(reopenedSenderTransport.receiver!.replica);

        await _dispose(
          [sender, reopenedSenderTransport.receiver!],
          [senderStorage, receiverStorage],
          [reopenedSenderTransport, reopenedReceiverTransport],
        );
      },
    );

    test('retries after interruption before remote delivery', () async {
      var senderStorage = _storage('${directory.path}/sender.sqlite');
      final receiverStorage = _storage('${directory.path}/receiver.sqlite');
      final receiverTransport = _PeerTransport('sender');
      final senderTransport = _PeerTransport('receiver')
        ..receiver = _engine('receiver', receiverStorage, receiverTransport)
        ..failBeforeDeliveryOnce = true;
      var sender = _engine('sender', senderStorage, senderTransport);
      await senderTransport.receiver!.start();
      await sender.start();
      await sender.setDelta('item', 'value');
      await expectLater(sender.push(), throwsStateError);
      expect(
        (await senderStorage.pending('sender')).single.status,
        OutboxStatus.sent,
      );
      expect(sender.replica.state.values, {'item': 'value'});
      expect(senderTransport.receiver!.replica.state.values, isEmpty);

      await sender.dispose();
      await senderStorage.close();
      senderStorage = _storage('${directory.path}/sender.sqlite');
      sender = _engine('sender', senderStorage, senderTransport);
      await sender.start();
      await sender.push(force: true);
      expect(senderTransport.receiver!.replica.state.values, {'item': 'value'});
      expect(await senderStorage.pending('sender'), isEmpty);
      await _dispose(
        [sender, senderTransport.receiver!],
        [senderStorage, receiverStorage],
        [senderTransport, receiverTransport],
      );
    });

    test('retries idempotently after delivery but before ACK', () async {
      var senderStorage = _storage('${directory.path}/sender.sqlite');
      var receiverStorage = _storage('${directory.path}/receiver.sqlite');
      final receiverTransport = _PeerTransport('sender');
      final senderTransport = _PeerTransport('receiver')
        ..receiver = _engine('receiver', receiverStorage, receiverTransport)
        ..failAfterDeliveryOnce = true;
      var sender = _engine('sender', senderStorage, senderTransport);
      await senderTransport.receiver!.start();
      await sender.start();
      await sender.setDelta('item', 'value');
      await expectLater(sender.push(), throwsStateError);
      expect(senderTransport.receiver!.replica.state.values, {'item': 'value'});
      expect(await senderStorage.pending('sender'), hasLength(1));

      await senderTransport.receiver!.dispose();
      await receiverStorage.close();
      receiverStorage = _storage('${directory.path}/receiver.sqlite');
      senderTransport.receiver = _engine(
        'receiver',
        receiverStorage,
        receiverTransport,
      );
      await senderTransport.receiver!.start();
      expect(senderTransport.receiver!.replica.state.values, {'item': 'value'});

      await sender.dispose();
      await senderStorage.close();
      senderStorage = _storage('${directory.path}/sender.sqlite');
      sender = _engine('sender', senderStorage, senderTransport);
      await sender.start();
      await sender.push(force: true);
      expect(senderTransport.receiver!.replica.state.values, {'item': 'value'});
      expect(await senderStorage.pending('sender'), isEmpty);
      await _dispose(
        [sender, senderTransport.receiver!],
        [senderStorage, receiverStorage],
        [senderTransport, receiverTransport],
      );
    });

    test(
      'offline replicas reconcile durable changes across reconnect and restart',
      () async {
        var storageA = _storage('${directory.path}/offline-a.sqlite');
        var storageB = _storage('${directory.path}/offline-b.sqlite');
        final transportA = _PeerTransport('offline-b')..unavailable = true;
        final transportB = _PeerTransport('offline-a')..unavailable = true;
        var engineA = _engine('offline-a', storageA, transportA);
        var engineB = _engine('offline-b', storageB, transportB);
        await Future.wait([engineA.start(), engineB.start()]);

        await engineA.setDelta('owner-a', 'a');
        await engineA.incrementGCounter('total', 2);
        await engineA.addOrSet('members', 'from-a');
        await engineA.removeOrSet('members', 'from-a');
        await engineB.setDelta('owner-b', 'b');
        await engineB.incrementGCounter('total', 5);
        await engineB.addOrSet('members', 'from-b');
        await expectLater(engineA.push(), throwsStateError);
        await expectLater(engineB.push(), throwsStateError);

        final pendingA = (await storageA.pending(
          'offline-a',
        )).expand((entry) => entry.changeIds).toSet();
        final pendingB = (await storageB.pending(
          'offline-b',
        )).expand((entry) => entry.changeIds).toSet();
        expect(pendingA, hasLength(4));
        expect(pendingB, hasLength(3));
        await _dispose([engineA, engineB], [storageA, storageB], [
          transportA,
          transportB,
        ]);

        // A different configured peer must not consume the durable outbox for B.
        storageA = _storage('${directory.path}/offline-a.sqlite');
        final otherPeer = _PeerTransport('offline-c');
        engineA = _engine('offline-a', storageA, otherPeer);
        await engineA.start();
        expect((await engineA.push(force: true)).sent.isEmpty, isTrue);
        expect(
          (await storageA.pending(
            'offline-a',
          )).expand((entry) => entry.changeIds).toSet(),
          pendingA,
        );
        await engineA.dispose();
        await storageA.close();
        await otherPeer.close();

        storageA = _storage('${directory.path}/offline-a.sqlite');
        storageB = _storage('${directory.path}/offline-b.sqlite');
        final reopenedTransportA = _PeerTransport('offline-b')
          ..reverseNextBatch = true
          ..failAfterDeliveryOnce = true;
        final reopenedTransportB = _PeerTransport('offline-a');
        engineA = _engine('offline-a', storageA, reopenedTransportA);
        engineB = _engine('offline-b', storageB, reopenedTransportB);
        reopenedTransportA.receiver = engineB;
        reopenedTransportB.receiver = engineA;
        await Future.wait([engineA.start(), engineB.start()]);

        // Remote commit succeeds but ACK is lost; close and reopen both engines.
        await expectLater(engineA.push(force: true), throwsStateError);
        expect(engineB.replica.state.values, {'owner-a': 'a', 'owner-b': 'b'});
        expect(engineB.replica.gCounterValue('total'), 7);
        expect(engineB.replica.orSetValue('members'), {'from-b'});
        await _dispose([engineA, engineB], [storageA, storageB], [
          reopenedTransportA,
          reopenedTransportB,
        ]);

        storageA = _storage('${directory.path}/offline-a.sqlite');
        storageB = _storage('${directory.path}/offline-b.sqlite');
        final finalTransportA = _PeerTransport('offline-b');
        final finalTransportB = _PeerTransport('offline-a');
        engineA = _engine('offline-a', storageA, finalTransportA);
        engineB = _engine('offline-b', storageB, finalTransportB);
        finalTransportA.receiver = engineB;
        finalTransportB.receiver = engineA;
        final ackGate = Completer<void>();
        finalTransportA.acknowledgementGate = ackGate;
        await Future.wait([engineA.start(), engineB.start()]);

        expect(engineB.replica.state.values, {'owner-a': 'a', 'owner-b': 'b'});
        expect(engineB.replica.gCounterValue('total'), 7);
        expect(engineB.replica.orSetValue('members'), {'from-b'});
        expect(
          (await storageA.pending(
            'offline-a',
          )).expand((entry) => entry.changeIds).toSet(),
          pendingA,
        );

        final retryA = engineA.push(force: true);
        await finalTransportA.firstDelivery.future;
        expect(
          (await storageA.pending(
            'offline-a',
          )).expand((entry) => entry.changeIds).toSet(),
          pendingA,
        );
        final duringAck = await engineA.setDelta('during-ack', 'edited');
        final retryB = engineB.push(force: true);
        await finalTransportB.firstDelivery.future;
        ackGate.complete();
        await Future.wait([retryA, retryB]);

        expect(
          (await storageA.pending(
            'offline-a',
          )).expand((entry) => entry.changeIds).toSet(),
          {duringAck.id},
        );
        await engineA.push(force: true);
        _expectOfflineConvergence(engineA, engineB);
        expect(await storageA.pending('offline-a'), isEmpty);
        expect(await storageB.pending('offline-b'), isEmpty);
        await _dispose([engineA, engineB], [storageA, storageB], [
          finalTransportA,
          finalTransportB,
        ]);
      },
    );

    test(
      'keeps local state and outbox atomic when SQLite commit fails',
      () async {
        final path = '${directory.path}/replica.sqlite';
        final storage = _storage(path);
        final transport = _PeerTransport('peer');
        final engine = _engine('sender', storage, transport);
        await engine.start();
        final database = await databaseFactoryFfi.openDatabase(path);
        await database.execute('''
        CREATE TRIGGER reject_outbox BEFORE INSERT ON deltasync_outbox
        BEGIN SELECT RAISE(ABORT, 'injected outbox failure'); END
      ''');

        await expectLater(
          engine.setDelta('item', 'value'),
          throwsA(isA<DatabaseException>()),
        );
        expect(engine.replica.state.values, isEmpty);
        expect(await storage.pending('sender'), isEmpty);
        final snapshot = await storage.loadReplica('sender');
        expect(
          Replica.fromSnapshotJson(snapshot!.snapshot!).state.values,
          isEmpty,
        );

        await engine.dispose();
        await storage.close();
        await transport.close();
      },
    );

    test(
      'two durable engines retry remote commit failure and mutation during ACK',
      () async {
        final pathA = '${directory.path}/a.sqlite';
        final pathB = '${directory.path}/b.sqlite';
        final storageA = _storage(pathA);
        final storageB = _storage(pathB);
        final transportA = _PeerTransport('b');
        final transportB = _PeerTransport('a');
        final engineA = _engine('a', storageA, transportA);
        final engineB = _engine('b', storageB, transportB);
        transportA.receiver = engineB;
        transportB.receiver = engineA;
        await engineA.start();
        await engineB.start();
        await engineB.setDelta('from-b', 3);
        await engineB.incrementGCounter('visits');
        await engineB.incrementPnCounter('balance', 5);

        final databaseB = await databaseFactoryFfi.openDatabase(pathB);
        await databaseB.execute('''
        CREATE TRIGGER reject_remote BEFORE INSERT ON deltasync_snapshots
        WHEN NEW.replica_id = 'b'
        BEGIN SELECT RAISE(ABORT, 'injected remote commit failure'); END
      ''');
        await engineA.setDelta('first', 1);
        await engineA.incrementGCounter('visits', 2);
        await engineA.decrementPnCounter('balance', 2);
        await expectLater(engineA.push(), throwsA(isA<DatabaseException>()));
        expect(
          (await storageA.pending('a')).expand((entry) => entry.delta.changes),
          hasLength(3),
        );
        expect(engineB.replica.state.values, {'from-b': 3});
        await databaseB.execute('DROP TRIGGER reject_remote');

        final gate = Completer<void>();
        transportA.acknowledgementGate = gate;
        final firstPush = engineA.push(force: true);
        await transportA.firstDelivery.future;
        final duringAck = await engineA.setDelta('during-ack', 2);
        final simultaneous = engineB.push(force: true);
        await transportB.firstDelivery.future;
        gate.complete();
        await Future.wait([firstPush, simultaneous]);
        final retainedIds = (await storageA.pending('a'))
            .expand((entry) => entry.delta.changes)
            .map((change) => change.id)
            .toSet();
        expect(retainedIds, {duringAck.id});
        await engineA.push(force: true);
        expect(engineB.replica.state.values, {
          'first': 1,
          'during-ack': 2,
          'from-b': 3,
        });
        expect(engineA.replica.gCounterValue('visits'), 3);
        expect(engineB.replica.gCounterValue('visits'), 3);
        expect(engineA.replica.pnCounterValue('balance'), 3);
        expect(engineB.replica.pnCounterValue('balance'), 3);
        expect(await storageA.pending('a'), isEmpty);

        await _dispose([engineA, engineB], [storageA, storageB], [
          transportA,
          transportB,
        ]);
      },
    );
  });
}

void _expectAllCrdts(Replica replica) {
  expect(replica.state.values, {'lww': 'value'});
  expect(replica.gCounterValue('g-counter'), 2);
  expect(replica.pnCounterValue('pn-counter'), -3);
  expect(replica.gSetValue('g-set'), {'kept'});
  expect(replica.twoPSetValue('two-p-set'), isEmpty);
  expect(replica.mvRegisterValue('mv-register'), {'version'});
  expect(replica.orSetValue('or-set'), isEmpty);
  expect(replica.orMapValue('or-map'), isEmpty);
}

class _ControlledOpenFactory implements DatabaseFactory {
  _ControlledOpenFactory({this.failFirst = false, this.firstGate});

  final bool failFirst;
  final Completer<void>? firstGate;
  int opens = 0;

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    final attempt = ++opens;
    if (attempt == 1 && failFirst) {
      final gate = firstGate;
      if (gate != null) await gate.future;
      throw StateError('injected opening failure');
    }
    return databaseFactoryFfi.openDatabase(path, options: options);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

SqfliteReplicaStorage _storage(String path) => SqfliteReplicaStorage(
  databaseFactory: databaseFactoryFfi,
  databasePath: path,
);

SyncEngine _engine(
  String id,
  ReplicaStorage storage,
  DeltaTransport transport,
) => SyncEngine.withStorage(
  replica: Replica(id),
  storage: storage,
  transport: transport,
);

Future<void> _dispose(
  List<SyncEngine> engines,
  List<SqfliteReplicaStorage> stores,
  List<_PeerTransport> transports,
) async {
  for (final engine in engines) {
    await engine.dispose();
  }
  for (final store in stores) {
    await store.close();
  }
  for (final transport in transports) {
    await transport.close();
  }
}

class _PeerTransport implements AcknowledgingDeltaTransport {
  _PeerTransport(this.peerReplicaId);

  @override
  final String peerReplicaId;
  final _incoming = StreamController<DeltaEnvelope>.broadcast();
  SyncEngine? receiver;
  bool failBeforeDeliveryOnce = false;
  bool failAfterDeliveryOnce = false;
  bool unavailable = false;
  bool reverseNextBatch = false;
  Completer<void>? acknowledgementGate;
  final firstDelivery = Completer<void>();

  @override
  Stream<DeltaEnvelope> get incoming => _incoming.stream;

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    await sendAndAwaitAck(envelope);
  }

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    if (envelope.recipientReplicaId != peerReplicaId) {
      throw StateError('Envelope addressed to wrong peer');
    }
    if (unavailable) throw StateError('Peer unavailable');
    if (failBeforeDeliveryOnce) {
      failBeforeDeliveryOnce = false;
      throw StateError('interrupted before delivery');
    }
    final changes = reverseNextBatch
        ? envelope.delta.changes.reversed
        : envelope.delta.changes;
    reverseNextBatch = false;
    await receiver!.applyRemote(Delta(changes));
    if (!firstDelivery.isCompleted) firstDelivery.complete();
    if (failAfterDeliveryOnce) {
      failAfterDeliveryOnce = false;
      throw StateError('interrupted before ACK');
    }
    await acknowledgementGate?.future;
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }

  Future<void> close() => _incoming.close();
}

void _expectOfflineConvergence(SyncEngine first, SyncEngine second) {
  for (final engine in [first, second]) {
    expect(engine.replica.state.values, {
      'owner-a': 'a',
      'owner-b': 'b',
      'during-ack': 'edited',
    });
    expect(engine.replica.gCounterValue('total'), 7);
    expect(engine.replica.orSetValue('members'), {'from-b'});
  }
}
