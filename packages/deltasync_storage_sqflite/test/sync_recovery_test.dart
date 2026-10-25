import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

    for (final seed in [7, 42, 2026]) {
      test('generated durable history seed=$seed', () async {
        final random = Random(seed);
        final trace = <String>[];
        final paths = [
          '${directory.path}/a.sqlite',
          '${directory.path}/b.sqlite',
        ];
        final ids = ['a', 'b'];
        final stores = paths.map(_storage).toList();
        final transports = [_PeerTransport('b'), _PeerTransport('a')];
        SyncEngine openEngine(int writer) => SyncEngine.withStorage(
          replica: Replica(
            ids[writer],
            hlc: HlcClock(nowMilliseconds: () => 1000),
          ),
          storage: stores[writer],
          transport: transports[writer],
        );
        final engines = [for (var i = 0; i < 2; i++) openEngine(i)];
        // start/replay observes LWW timestamps and advances only the local HLC.
        Map<String, Object?> state(Replica replica) =>
            Map<String, Object?>.of(replica.toSnapshotJson())..remove('hlc');
        try {
          await Future.wait(engines.map((engine) => engine.start()));
          for (var writer = 0; writer < 2; writer++) {
            // Three rounds of all eight kinds, with seeded payloads/amounts.
            await _generatedDurableWrites(engines[writer], random, trace);
          }
          final original = [
            for (var writer = 0; writer < 2; writer++)
              (await stores[writer].pending(ids[writer]))
                  .expand((entry) => entry.delta.changes)
                  .toList(),
          ];
          final deliveries = [
            for (final events in original)
              List<DeltaChange>.of(events)..shuffle(random),
          ];
          for (var writer = 0; writer < 2; writer++) {
            trace.add(
              'writer=$writer order=${deliveries[writer].map((change) => change.id).join(",")}',
            );
          }
          for (var half = 0; half < 2; half++) {
            for (var writer = 0; writer < 2; writer++) {
              final events = deliveries[writer];
              final midpoint = events.length ~/ 2;
              for (final event in events.sublist(
                half == 0 ? 0 : midpoint,
                half == 0 ? midpoint : events.length,
              )) {
                final delta = DeltaCodec.decode(
                  DeltaCodec.encode(Delta([event])),
                );
                await engines[1 - writer].applyRemote(delta);
                await engines[1 - writer].applyRemote(delta);
              }
            }
            // Keep full snapshots and outbox metadata through a physical reopen.
            for (var writer = 0; writer < 2; writer++) {
              final snapshot = state(engines[writer].replica);
              final previousHlc = engines[writer].replica.hlcTimestamp;
              final outbox = [
                for (final entry in await stores[writer].pending(ids[writer]))
                  entry.toJson(),
              ];
              await engines[writer].dispose();
              await stores[writer].close();
              stores[writer] = _storage(paths[writer]);
              engines[writer] = openEngine(writer);
              await engines[writer].start();
              expect(state(engines[writer].replica), snapshot);
              expect(
                engines[writer].replica.hlcTimestamp.compareTo(previousHlc),
                greaterThanOrEqualTo(0),
              );
              expect([
                for (final entry in await stores[writer].pending(ids[writer]))
                  entry.toJson(),
              ], outbox);
              trace.add('writer=$writer reopened half=$half');
            }
          }
          for (var writer = 0; writer < 2; writer++) {
            final oldIds = original[writer].map((change) => change.id).toSet();
            final next = await _generatedDurableWrites(
              engines[writer],
              random,
              trace,
            );
            final pendingIds = (await stores[writer].pending(ids[writer]))
                .expand((entry) => entry.changeIds)
                .toSet();
            final nextIds = next.map((change) => change.id).toSet();
            expect(nextIds, hasLength(next.length));
            expect(nextIds.intersection(oldIds), isEmpty);
            expect(pendingIds, {...oldIds, ...nextIds});
            final before = state(engines[writer].replica);
            await engines[writer].applyRemote(
              Delta(original.expand((events) => events)),
            );
            expect(state(engines[writer].replica), before);
          }
          transports[0].receiver = engines[1];
          transports[1].receiver = engines[0];
          for (var writer = 0; writer < 2; writer++) {
            final pendingIds = (await stores[writer].pending(ids[writer]))
                .expand((entry) => entry.changeIds)
                .toSet();
            final result = await engines[writer].push(force: true);
            expect(result.acknowledgedIds, pendingIds);
            expect(await stores[writer].pending(ids[writer]), isEmpty);
          }
          // Compare full exported events (values, dots, contexts, tombstones).
          Map<String, Object?> exported(Replica replica) => {
            for (final change in replica.export().changes)
              change.id: change.toJson(),
          };
          expect(exported(engines[0].replica), exported(engines[1].replica));
          for (var writer = 0; writer < 2; writer++) {
            final snapshot = state(engines[writer].replica);
            final previousHlc = engines[writer].replica.hlcTimestamp;
            await engines[writer].dispose();
            await stores[writer].close();
            stores[writer] = _storage(paths[writer]);
            engines[writer] = openEngine(writer);
            await engines[writer].start();
            expect(state(engines[writer].replica), snapshot);
            expect(
              engines[writer].replica.hlcTimestamp.compareTo(previousHlc),
              greaterThanOrEqualTo(0),
            );
            expect(await stores[writer].pending(ids[writer]), isEmpty);
          }
        } catch (error, stack) {
          fail('seed=$seed\ntrace=${trace.join("\n")}\n$error\n$stack');
        } finally {
          await _dispose(engines, stores, transports);
        }
      });
    }

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
        (await storage.pending(replicaId))
            .map((entry) => entry.entryId)
            .toSet(),
        {oldChange.id, next.id},
      );
      await engine.dispose();
      await storage.close();
      await transport.close();
    });

    test(
      'invalid MV sequence fails start without overwriting SQLite',
      () async {
        const replicaId = 'durable-device';
        final path = '${directory.path}/invalid-mv-sequence.sqlite';
        final storage = _storage(path);
        final transport = _PeerTransport('peer');
        final original = _engine(replicaId, storage, transport);
        await original.start();
        await original.writeMvRegister('field', 'old');
        await original.writeMvRegister('field', 'current');
        await original.dispose();
        await storage.close();

        final database = await databaseFactoryFfi.openDatabase(path);
        final row = (await database.query('deltasync_snapshots')).single;
        final validPayload = row['payload'] as String;
        final invalid = jsonDecode(validPayload) as Map<String, dynamic>;
        final snapshot = invalid['snapshot'] as Map<String, dynamic>;
        final registers = snapshot['mvRegisters'] as Map<String, dynamic>;
        final field = registers['field'] as Map<String, dynamic>;
        field['sequence'] = 0;
        final invalidPayload = jsonEncode(invalid);
        await database.update(
          'deltasync_snapshots',
          {'payload': invalidPayload},
          where: 'replica_id = ?',
          whereArgs: [replicaId],
        );
        await database.close();

        final reopenedStorage = _storage(path);
        final engine = _engine(replicaId, reopenedStorage, transport);
        for (var attempt = 0; attempt < 2; attempt++) {
          await expectLater(engine.start(), throwsFormatException);
          expect(engine.lifecycle, SyncEngineLifecycle.created);
          expect(() => engine.replica, throwsStateError);
          final stored = await databaseFactoryFfi.openDatabase(
            path,
            options: OpenDatabaseOptions(singleInstance: false),
          );
          expect(
            (await stored.query('deltasync_snapshots')).single['payload'],
            invalidPayload,
          );
          await stored.close();
        }

        await reopenedStorage.close();
        final repaired = await databaseFactoryFfi.openDatabase(path);
        await repaired.update(
          'deltasync_snapshots',
          {'payload': validPayload},
          where: 'replica_id = ?',
          whereArgs: [replicaId],
        );
        await repaired.close();

        await engine.start();
        expect(engine.replica.mvRegisterValue('field'), {'current'});
        final next = await engine.writeMvRegister('field', 'next');
        expect(next.dot.counter, 3);
        expect(engine.replica.mvRegisterValue('field'), {'next'});
        await engine.dispose();
        await reopenedStorage.close();
        await transport.close();
      },
    );

    test(
      'migrates explicit MV snapshot and outbox contexts after reopen',
      () async {
        const replicaId = 'compact-device';
        const peerId = 'compact-peer';
        final path = '${directory.path}/compact-context.sqlite';
        final source = Replica(replicaId)..writeMvRegister('field', 'one');
        final first = source.export().changes.single as MvRegisterDelta;
        final second = source.writeMvRegister('field', 'two');
        final oldSnapshot = _legacySnapshotWithExplicitMvContext(source);
        final storage = _storage(path);
        await storage.saveReplica(
          ReplicaSnapshot(replicaId: replicaId, snapshot: oldSnapshot),
        );

        final oldChange = second.toJson()
          ..['context'] = [for (final dot in second.context) dot.toJson()];
        final oldEntryJson =
            OutboxEntry(
                delta: Delta([second]),
                recipientPeerId: peerId,
                status: OutboxStatus.sent,
                attempts: 1,
                createdAt: DateTime.utc(2026, 10, 12),
                sentAt: DateTime.utc(2026, 10, 12, 0, 1),
              ).toJson()
              ..['delta'] = {
                'version': 3,
                'delta': {
                  'changes': [oldChange],
                },
              };
        await storage.enqueue(OutboxEntry.fromJson(oldEntryJson));
        await storage.enqueue(
          OutboxEntry(
            delta: Delta([second]),
            recipientPeerId: peerId,
            createdAt: DateTime.utc(2026, 10, 12, 0, 2),
          ),
        );
        await storage.close();

        final reopenedStorage = _storage(path);
        final transport = _PeerTransport(peerId);
        final engine = _engine(replicaId, reopenedStorage, transport);
        await engine.start();
        expect(engine.replica.mvRegisterValue('field'), {'two'});
        final oldPending = (await reopenedStorage.pending(replicaId)).single;
        expect(oldPending.entryId, second.id);
        expect(oldPending.recipientPeerId, peerId);
        expect(oldPending.status, OutboxStatus.sent);
        expect(oldPending.attempts, 1);
        expect(oldPending.sentAt, DateTime.utc(2026, 10, 12, 0, 1));
        expect(oldPending.delta.changes.single, isA<MvRegisterDelta>());

        final next = await engine.writeMvRegister('field', 'three');
        expect(next.dot.counter, 3);
        expect(next.context, [first.dot, second.dot]);
        expect(next.toJson()['context'], {
          'crdtId': 'field',
          'replicas': {
            replicaId: {'prefix': 2, 'sparse': <int>[]},
          },
        });
        final savedSnapshot = await reopenedStorage.loadReplica(replicaId);
        expect(savedSnapshot!.snapshot!['version'], 9);
        expect(
          (await reopenedStorage.pending(replicaId))
              .map((entry) => entry.entryId)
              .toSet(),
          {second.id, next.id},
        );

        await engine.dispose();
        await reopenedStorage.close();
        await transport.close();

        final finalStorage = _storage(path);
        final finalTransport = _PeerTransport(peerId);
        final restored = _engine(replicaId, finalStorage, finalTransport);
        await restored.start();
        expect(restored.replica.mvRegisterValue('field'), {'three'});
        expect(
          (await finalStorage.pending(replicaId))
              .map((entry) => entry.entryId)
              .toSet(),
          {second.id, next.id},
        );
        await restored.dispose();
        await finalStorage.close();
        await finalTransport.close();
      },
    );

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
        final pendingIds = (await senderStorage.pending('sender-all'))
            .expand((entry) => entry.changeIds)
            .toSet();
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
          (await senderStorage.pending('sender-all'))
              .expand((entry) => entry.changeIds)
              .toSet(),
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

    test('offline replicas reconcile durable changes across reconnect and restart', () async {
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

      final pendingA = (await storageA.pending('offline-a'))
          .expand((entry) => entry.changeIds)
          .toSet();
      final pendingB = (await storageB.pending('offline-b'))
          .expand((entry) => entry.changeIds)
          .toSet();
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
        (await storageA.pending('offline-a'))
            .expand((entry) => entry.changeIds)
            .toSet(),
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
        (await storageA.pending('offline-a'))
            .expand((entry) => entry.changeIds)
            .toSet(),
        pendingA,
      );

      final retryA = engineA.push(force: true);
      await finalTransportA.firstDelivery.future;
      expect(
        (await storageA.pending('offline-a'))
            .expand((entry) => entry.changeIds)
            .toSet(),
        pendingA,
      );
      final duringAck = await engineA.setDelta('during-ack', 'edited');
      final retryB = engineB.push(force: true);
      await finalTransportB.firstDelivery.future;
      ackGate.complete();
      await Future.wait([retryA, retryB]);

      expect(
        (await storageA.pending('offline-a'))
            .expand((entry) => entry.changeIds)
            .toSet(),
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
    });

    test(
      'rolls back compact MV context and outbox when SQLite commit fails',
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
          engine.writeMvRegister('field', 'value'),
          throwsA(isA<DatabaseException>()),
        );
        expect(engine.replica.mvRegisterValue('field'), isEmpty);
        expect(await storage.pending('sender'), isEmpty);
        final snapshot = await storage.loadReplica('sender');
        expect(
          Replica.fromSnapshotJson(snapshot!.snapshot!)
              .mvRegisterValue('field'),
          isEmpty,
        );

        await database.execute('DROP TRIGGER reject_outbox');
        final recovered = await engine.writeMvRegister('field', 'value');
        expect(recovered.dot.counter, 1);
        expect(engine.replica.mvRegisterValue('field'), {'value'});
        expect(await storage.pending('sender'), hasLength(1));
        expect((await storage.loadReplica('sender'))!.snapshot!['version'], 9);

        await engine.dispose();
        await storage.close();
        await database.close();
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

Map<String, Object?> _legacySnapshotWithExplicitMvContext(Replica replica) {
  final snapshot = Map<String, Object?>.from(replica.toSnapshotJson())
    ..['version'] = 8;
  final registers = Map<String, Object?>.from(snapshot['mvRegisters'] as Map);
  for (final entry in registers.entries) {
    final state = Map<String, Object?>.from(entry.value as Map);
    state['context'] = _expandCompactContext(state['context'] as Map);
    state['versions'] = (state['versions'] as List).map((raw) {
      final version = Map<String, Object?>.from(raw as Map)
        ..['context'] = _expandCompactContext(raw['context'] as Map);
      return version;
    }).toList();
    registers[entry.key] = state;
  }
  snapshot['mvRegisters'] = registers;
  return snapshot;
}

Future<List<DeltaChange>> _generatedDurableWrites(
  SyncEngine engine,
  Random random,
  List<String> trace,
) async {
  final changes = <DeltaChange>[];
  for (var round = 0; round < 3; round++) {
    final value = {
      'items': [random.nextInt(10), true],
      'owner': engine.replica.id,
    };
    trace.add('${engine.replica.id} round=$round payload=${jsonEncode(value)}');
    changes.add(await engine.setDelta('lww', value));
    if (round == 1) {
      changes.add(await engine.removeDelta('lww'));
    }
    changes.add(await engine.incrementGCounter('g', random.nextInt(4) + 1));
    changes.add(await engine.decrementPnCounter('pn', random.nextInt(4) + 1));
    changes.add(await engine.addGSet('g-set', value));
    changes.add(await engine.addTwoPSet('two', value));
    if (round == 1) {
      changes.add(await engine.removeTwoPSet('two', value));
    }
    changes.add(await engine.writeMvRegister('mv', value));
    changes.add(await engine.addOrSet('or', 'shared'));
    if (round == 1) {
      changes.add(await engine.removeOrSet('or', 'shared'));
    }
    changes.add(await engine.addOrMapKey('map', 'roles'));
    changes.addAll(await engine.addOrMapValue('map', 'roles', value));
    if (round == 1) {
      changes.add(await engine.removeOrMapKey('map', 'roles'));
    }
  }
  trace.add('emitted=${jsonEncode(DeltaCodec.encode(Delta(changes)))}');
  return changes;
}

List<Map<String, Object?>> _expandCompactContext(Map context) {
  final crdtId = context['crdtId'] as String;
  final replicas = context['replicas'] as Map;
  final dots = <Dot>[];
  for (final entry in replicas.entries) {
    final replicaId = entry.key as String;
    final encoded = entry.value as Map;
    final prefix = encoded['prefix'] as int;
    final sparse = (encoded['sparse'] as List).cast<int>();
    dots.addAll([
      for (var counter = 1; counter <= prefix; counter++)
        Dot(replicaId: replicaId, counter: counter, crdtId: crdtId),
      for (final counter in sparse)
        Dot(replicaId: replicaId, counter: counter, crdtId: crdtId),
    ]);
  }
  return [for (final dot in dots) dot.toJson()];
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
