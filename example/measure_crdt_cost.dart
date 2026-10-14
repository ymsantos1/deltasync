import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _peerId = 'measurement-peer';
const _counts = [4, 8, 16, 32];
const _fixedMilliseconds = 1730000000000;

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final root = await Directory.systemTemp.createTemp('deltasync-cost-');
  try {
    print(
      'environment: os=${Platform.operatingSystem}, '
      'dart=${Platform.version.split(' ').first}, '
      'abi=${Abi.current()}, '
      'processors=${Platform.numberOfProcessors}',
    );
    await _measureFewChangesInLargeState(root);
    for (final count in _counts) {
      await _measureMvRegister(root, count);
    }
    await _measureOrSet(root, cycles: 8);
  } finally {
    await root.delete(recursive: true);
  }
}

Future<void> _measureFewChangesInLargeState(Directory root) async {
  const replicaId = 'large-state-replica';
  final seed = Replica(
    replicaId,
    hlc: HlcClock(nowMilliseconds: () => _fixedMilliseconds),
  );
  for (var index = 0; index < 250; index++) {
    seed.addGSet('catalog', 'item-$index');
  }
  final storage = _storage(root, 'large-state');
  await storage.saveReplica(ReplicaSnapshot.fromReplica(seed));
  final engine = _engine(
    replicaId: replicaId,
    storage: storage,
    peer: _NoopTransport(_peerId),
  );
  await engine.start();
  final changes = <DeltaChange>[];
  for (var index = 250; index < 253; index++) {
    changes.add(await engine.addGSet('catalog', 'item-$index'));
  }
  final delta = Delta(changes);
  final envelope = DeltaEnvelope(
    senderReplicaId: replicaId,
    recipientReplicaId: _peerId,
    delta: delta,
  );
  final state = engine.replica.toSnapshotJson();
  print(
    'large-state: existing=250, changes=3, visible=${engine.replica.gSetValue('catalog').length}, '
    'delta=${_jsonBytes(DeltaCodec.encode(delta))} B, '
    'envelope=${_jsonBytes(envelope.toJson())} B, '
    'snapshot=${_jsonBytes(state)} B, '
    'outbox=${await _outboxBytes(storage, replicaId)} B',
  );
  await engine.dispose();
  await storage.close();
}

Future<void> _measureMvRegister(Directory root, int count) async {
  final replicaId = 'mv-$count';
  final peerId = 'peer-$count';
  final localStorage = _storage(root, '$replicaId-local');
  final peerStorage = _storage(root, '$replicaId-peer');
  late final SyncEngine peer;
  peer = _engine(
    replicaId: peerId,
    storage: peerStorage,
    peer: _NoopTransport(replicaId),
  );
  final local = _engine(
    replicaId: replicaId,
    storage: localStorage,
    peer: _DurablePeerTransport(peer, peerId),
  );
  final samples = <int>[];
  await local.start();
  for (var index = 0; index < count; index++) {
    final timer = Stopwatch()..start();
    await local.writeMvRegister('profile/name', 'value-$index');
    timer.stop();
    samples.add(timer.elapsedMicroseconds);
  }

  final pendingBefore = await localStorage.pending(replicaId);
  final pendingDelta = _mergeEntries(pendingBefore);
  final mvChanges = pendingDelta.changes.whereType<MvRegisterDelta>().toList();
  final contextReferences = mvChanges.fold<int>(
    0,
    (total, change) => total + change.context.length,
  );
  final compactContextUnits = mvChanges.fold<int>(
    0,
    (total, change) => total + _compactContextUnits(change),
  );
  final snapshotBefore = local.replica.toSnapshotJson();
  final envelope = DeltaEnvelope(
    senderReplicaId: replicaId,
    recipientReplicaId: peerId,
    delta: pendingDelta,
  );
  final bytesBeforeAck = _jsonBytes(DeltaCodec.encode(pendingDelta));
  final envelopeBytes = _jsonBytes(envelope.toJson());
  final outboxBytes = await _outboxBytes(localStorage, replicaId);
  final dbBytesBeforeAck = await _databaseBytes(root, '$replicaId-local');

  final ackTimer = Stopwatch()..start();
  final push = await local.push(force: true);
  ackTimer.stop();
  final pendingAfter = await localStorage.pending(replicaId);
  final outboxBytesAfter = await _outboxBytes(localStorage, replicaId);
  final snapshotAfter = local.replica.toSnapshotJson();
  final activeVersions = local.replica.mvRegisterValue('profile/name').length;
  final contextDots = _mvContextCount(snapshotAfter, 'profile/name');
  final stateBytes = _jsonBytes(snapshotAfter);
  final dbBytesAfterAck = await _databaseBytes(root, '$replicaId-local');
  print(
    'mv-register: N=$count, expected-context-refs=${count * (count - 1) ~/ 2}, '
    'actual-context-refs=$contextReferences, '
    'compact-context-units=$compactContextUnits, '
    'active-versions=$activeVersions, '
    'context-dots=$contextDots, delta=$bytesBeforeAck B, '
    'envelope=$envelopeBytes B, outbox-with-metadata=$outboxBytes B, '
    'snapshot-before-ack=${_jsonBytes(snapshotBefore)} B, snapshot-after-ack=$stateBytes B, '
    'pending-before=${pendingBefore.length}, pending-after=${pendingAfter.length}, '
    'outbox-after-ack=$outboxBytesAfter B, '
    'acknowledged=${push.acknowledgedIds.length}, '
    'write-us=${_range(samples)}, ack-ms=${ackTimer.elapsedMilliseconds}, '
    'sqlite-before-ack=$dbBytesBeforeAck B, sqlite-after-ack=$dbBytesAfterAck B',
  );

  await local.dispose();
  await peer.dispose();
  await localStorage.close();
  await peerStorage.close();
}

Future<void> _measureOrSet(Directory root, {required int cycles}) async {
  const replicaId = 'or-set-replica';
  const peerId = 'or-set-peer';
  final localStorage = _storage(root, 'or-set-local');
  final peerStorage = _storage(root, 'or-set-peer');
  final peer = _engine(
    replicaId: peerId,
    storage: peerStorage,
    peer: _NoopTransport(replicaId),
  );
  final local = _engine(
    replicaId: replicaId,
    storage: localStorage,
    peer: _DurablePeerTransport(peer, peerId),
  );
  await local.start();
  for (var index = 0; index < cycles; index++) {
    await local.addOrSet('recent-items', 'same-item');
    await local.removeOrSet('recent-items', 'same-item');
  }
  await local.addOrSet('recent-items', 'same-item');

  final entries = await localStorage.pending(replicaId);
  final delta = _mergeEntries(entries);
  final events = delta.changes.whereType<OrSetDelta>().toList();
  final addTags = events
      .where((change) => change.action == OrSetAction.add)
      .length;
  final observedReferences = events.fold<int>(
    0,
    (total, change) => total + change.observedDots.length,
  );
  final snapshot = local.replica.toSnapshotJson();
  final envelope = DeltaEnvelope(
    senderReplicaId: replicaId,
    recipientReplicaId: peerId,
    delta: delta,
  );
  print(
    'or-set: cycles=$cycles, visible=${local.replica.orSetValue('recent-items').length}, '
    'add-tags=$addTags, retained-events=${events.length}, '
    'observed-dot-refs=$observedReferences, delta=${_jsonBytes(DeltaCodec.encode(delta))} B, '
    'envelope=${_jsonBytes(envelope.toJson())} B, '
    'outbox-with-metadata=${await _outboxBytes(localStorage, replicaId)} B, '
    'snapshot=${_jsonBytes(snapshot)} B',
  );

  await local.dispose();
  await peer.dispose();
  await localStorage.close();
  await peerStorage.close();
}

SqfliteReplicaStorage _storage(Directory root, String name) =>
    SqfliteReplicaStorage(
      databaseFactory: databaseFactory,
      databasePath: '${root.path}/$name.db',
    );

SyncEngine _engine({
  required String replicaId,
  required ReplicaStorage storage,
  required DeltaTransport peer,
}) => SyncEngine.withStorage(
  replica: Replica(
    replicaId,
    hlc: HlcClock(nowMilliseconds: () => _fixedMilliseconds),
  ),
  storage: storage,
  transport: peer,
);

Delta _mergeEntries(List<OutboxEntry> entries) => entries.fold(
  const Delta.empty(),
  (result, entry) => result.merge(entry.delta),
);

Future<int> _outboxBytes(ReplicaStorage storage, String replicaId) async {
  final entries = await storage.pending(replicaId);
  return entries.fold<int>(
    0,
    (total, entry) => total + _jsonBytes(entry.toJson()),
  );
}

int _mvContextCount(Map<String, Object?> snapshot, String crdtId) {
  final registers = snapshot['mvRegisters']! as Map<String, Object?>;
  final register = registers[crdtId]! as Map<String, Object?>;
  return _compactContextLogicalDots(register['context']! as Map);
}

int _compactContextUnits(MvRegisterDelta change) =>
    _compactContextUnitsFromJson(change.toJson()['context']! as Map);

int _compactContextUnitsFromJson(Map context) {
  final replicas = context['replicas']! as Map;
  return replicas.values.fold<int>(0, (total, raw) {
    final entry = raw as Map;
    return total +
        ((entry['prefix']! as int) > 0 ? 1 : 0) +
        (entry['sparse']! as List).length;
  });
}

int _compactContextLogicalDots(Map context) {
  final replicas = context['replicas']! as Map;
  return replicas.values.fold<int>(0, (total, raw) {
    final entry = raw as Map;
    return total +
        (entry['prefix']! as int) +
        (entry['sparse']! as List).length;
  });
}

Future<int> _databaseBytes(Directory root, String name) async {
  final file = File('${root.path}/$name.db');
  return await file.exists() ? file.length() : 0;
}

String _range(List<int> values) {
  final sorted = values.toList()..sort();
  return '${sorted.first}-${sorted.last}';
}

int _jsonBytes(Object value) => utf8.encode(jsonEncode(value)).length;

class _NoopTransport implements DeltaTransport {
  const _NoopTransport(this.peerReplicaId);

  @override
  final String peerReplicaId;

  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();

  @override
  Future<void> send(DeltaEnvelope envelope) async {}
}

class _DurablePeerTransport implements AcknowledgingDeltaTransport {
  const _DurablePeerTransport(this.peerEngine, this.peerReplicaId);

  final SyncEngine peerEngine;

  @override
  final String peerReplicaId;

  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();

  @override
  Future<void> send(DeltaEnvelope envelope) async {}

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await peerEngine.applyRemote(envelope.delta);
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }
}
