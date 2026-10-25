import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:math';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
// Measurement of the actual preparation path, not an application extension API.
import 'package:deltasync_sync/src/sync/outbound_sync.dart';
import 'package:deltasync_sync/src/sync/replica_persistence.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _peerId = 'measurement-peer';
const _counts = [4, 8, 16, 32];
const _fixedMilliseconds = 1730000000000;

Future<void> main(List<String> arguments) async {
  if (arguments.length == 1 && arguments.single == '--paths') {
    await _measureSyncPaths();
    return;
  }
  if (arguments.isNotEmpty) throw ArgumentError('Expected no args or --paths');
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

// R-32 extends this instrument; production APIs/algorithms remain unchanged.
const _pathSeed = 20261024;
const _warmupRuns = 2;
const _measuredRuns = 5;
const _queryRepetitions = 5;
const _pathCases = [
  (name: 'base', fields: 16, valueBytes: 64, pending: 16),
  (name: 'fields-64', fields: 64, valueBytes: 64, pending: 16),
  (name: 'fields-256', fields: 256, valueBytes: 64, pending: 16),
  (name: 'value-256', fields: 16, valueBytes: 256, pending: 16),
  (name: 'value-1024', fields: 16, valueBytes: 1024, pending: 16),
  (name: 'pending-64', fields: 16, valueBytes: 64, pending: 64),
  (name: 'pending-256', fields: 16, valueBytes: 64, pending: 256),
];

Future<void> _measureSyncPaths() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final root = await Directory.systemTemp.createTemp('deltasync-r32-');
  final results = <Object?>[];
  try {
    for (final workload in _pathCases) {
      final random = Random(_pathSeed);
      final value = String.fromCharCodes([
        for (var i = 0; i < workload.valueBytes; i++) 97 + random.nextInt(26),
      ]);
      final replica = Replica(
        'paths',
        hlc: HlcClock(nowMilliseconds: () => _fixedMilliseconds),
      );
      for (var i = 0; i < workload.fields; i++) {
        _pathChange(replica, i, workload.fields, value);
        if (i % 8 == 7) replica.addOrMapValue(_address(i), 'key-$i', value);
      }
      final entries = <OutboxEntry>[];
      for (var i = 0; i < workload.pending; i++) {
        final change = _pathChange(replica, i, workload.fields, value);
        final sent = i % 3 == 0;
        entries.add(
          OutboxEntry(
            delta: Delta([change]),
            recipientPeerId: (i ~/ 8).isEven ? _peerId : 'other-peer',
            status: sent ? OutboxStatus.sent : OutboxStatus.pending,
            attempts: sent ? 2 : 0,
            createdAt: DateTime.utc(2024).add(Duration(milliseconds: i)),
            sentAt: sent ? DateTime.utc(2024, 1, 2) : null,
          ),
        );
      }
      final snapshot = replica.toSnapshotJson();
      final canonical = ReplicaSnapshot.fromReplica(replica);
      final values = _pathValues(replica);
      _require(
        replica.state.addresses.length == workload.fields,
        'field count',
      );
      _require(entries.length == workload.pending, 'pending count');
      _require(
        entries.map((e) => e.delta.changes.single.kind).toSet().length == 8,
        'eight pending kinds',
      );
      for (final sqlite in [false, true]) {
        final samples = <Map<String, Object?>>[];
        for (var run = -_warmupRuns; run < _measuredRuns; run++) {
          final sample = await _pathSample(
            root: root,
            name: '${workload.name}-$run',
            sqlite: sqlite,
            source: replica,
            snapshot: snapshot,
            canonical: canonical,
            entries: entries,
            values: values,
            value: value,
          );
          if (run >= 0) samples.add(sample);
        }
        final firstTimes = samples.first['microseconds']! as Map<String, int>;
        results.add({
          'case': workload.name,
          'backend': sqlite ? 'sqlite-ffi' : 'memory-volatile',
          'fields': workload.fields,
          'valueAsciiBytes': workload.valueBytes,
          'pendingEntries': entries.length,
          'pendingKinds': entries
              .map((e) => e.delta.changes.single.kind.wireName)
              .toSet()
              .toList(),
          'selectedPeerEntries': entries
              .where((e) => e.recipientPeerId == _peerId)
              .length,
          'sizes': {
            'visibleValuesJsonBytes': _jsonBytes(values),
            'causalMetadataProjectionJsonBytes': _jsonBytes(
              _metadataProjection(snapshot),
            ),
            'replicaSnapshotJsonBytes': _jsonBytes(snapshot),
            'storageSnapshotJsonBytes': _jsonBytes(canonical.toJson()),
            'outboxJsonBytes': _jsonBytes(
              entries.map((e) => e.toJson()).toList(),
            ),
          },
          'medianMicroseconds': {
            for (final key in firstTimes.keys)
              key: _median([
                for (final sample in samples)
                  (sample['microseconds']! as Map<String, int>)[key]!,
              ]),
          },
          'samples': samples,
        });
      }
    }
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'task': 'R-32',
        'environment': {
          'sdk': Platform.version,
          'os': Platform.operatingSystem,
          'osVersion': Platform.operatingSystemVersion,
          'abi': Abi.current().toString(),
          'processors': Platform.numberOfProcessors,
        },
        'seed': _pathSeed,
        'fixedMilliseconds': _fixedMilliseconds,
        'warmupRunsPerCaseAndBackend': _warmupRuns,
        'measuredRunsPerCaseAndBackend': _measuredRuns,
        'queryRepetitionsPerSample': _queryRepetitions,
        'heapMeasured': false,
        'allocationsMeasured': false,
        'memoryMetric':
            'ProcessInfo.currentRss/maxRss; whole process, including native SQLite; not heap or allocated bytes',
        'sizeMetric':
            'UTF-8 JSON bytes; values/metadata projections are not an additive partition or a recoverable backup',
        'metadataProjection':
            'Global clock/HLC/delta sequence; per-CRDT sequences, MV contexts/version dots, retained change identity/dots/observations (including nested OR-Map changes); excludes domain values',
        'timingScope':
            'Fresh identical storage per run; setup/checks outside timers; engineStart includes restore/replay/save and SQLite reopen; pushPreparation includes read/filter/merge/markSent, excludes queue/network; query times are batches',
        'mutationScope':
            'Overwrite existing LWW field with the same value; still advances clock/ID; engineMutation starts after restoration and includes commit/adopt',
        'queryScope':
            'Engine count includes both peers; storage status selects one peer; valueAt selects one LWW string; these are distinct operations',
        'sqliteFileScope':
            'Main/WAL/SHM after close, preparation and one new mutation; no vacuum or reclaimable-space measurement; not the pre-operation JSON sizes',
        'restorationScope':
            'Canonical snapshot already contains pending effects; replay is intentionally idempotent; storage was closed/reopened, OS caches were not cleared',
        'workloads': results,
      }),
    );
  } finally {
    await root.delete(recursive: true);
  }
}

Future<Map<String, Object?>> _pathSample({
  required Directory root,
  required String name,
  required bool sqlite,
  required Replica source,
  required Map<String, Object?> snapshot,
  required ReplicaSnapshot canonical,
  required List<OutboxEntry> entries,
  required Map<String, Object?> values,
  required String value,
}) async {
  final times = <String, int>{};
  final rssBefore = ProcessInfo.currentRss;
  T measure<T>(String key, T Function() action) {
    final timer = Stopwatch()..start();
    final result = action();
    timer.stop();
    times[key] = timer.elapsedMicroseconds;
    return result;
  }

  Future<T> measureAsync<T>(String key, Future<T> Function() action) async {
    final timer = Stopwatch()..start();
    final result = await action();
    timer.stop();
    times[key] = timer.elapsedMicroseconds;
    return result;
  }

  final fork = measure('fork', source.fork);
  _require(_sameSnapshot(fork.toSnapshotJson(), snapshot), 'fork snapshot');
  final change = measure(
    'nativeMutation',
    () => fork.setDelta(_address(0), value),
  );
  final adopted = source.fork();
  measure('adopt', () => adopted.adopt(fork));
  final encoded = measure('snapshot', source.toSnapshotJson);
  final json = measure('snapshotJsonEncode', () => jsonEncode(encoded));
  _require(json == jsonEncode(snapshot), 'snapshot contents');
  final restored = measure(
    'snapshotDecode',
    () => Replica.fromSnapshotJson(encoded),
  );
  _require(
    _sameSnapshot(restored.toSnapshotJson(), snapshot),
    'snapshot decode',
  );
  _require(
    _sameSnapshot(adopted.toSnapshotJson(), fork.toSnapshotJson()),
    'adopt',
  );

  ReplicaStorage storage = sqlite ? _storage(root, name) : MemoryStorage();
  await storage.commit(canonical, entries);
  if (storage is SqfliteReplicaStorage) {
    await storage.close();
    storage = _storage(root, name); // First open occurs inside the start timer.
  }
  final engine = _engine(
    replicaId: source.id,
    storage: storage,
    peer: const _NoopTransport(_peerId),
  );
  try {
    await measureAsync('engineStartWithOutbox', engine.start);
    _require(
      _sameSnapshot(engine.replica.toSnapshotJson(), snapshot),
      'restored snapshot',
    );
    _require(
      jsonEncode(_pathValues(engine.replica)) == jsonEncode(values),
      'restored values',
    );
    _require(
      jsonEncode(
            (await storage.pending(source.id)).map((e) => e.toJson()).toList(),
          ) ==
          jsonEncode(entries.map((e) => e.toJson()).toList()),
      'restored outbox metadata/order',
    );
    final beforeQueries = engine.replica.toSnapshotJson();
    final selected = entries
        .where((e) => e.recipientPeerId == _peerId)
        .toList();
    var totalCount = 0;
    var pendingCount = 0;
    var sentCount = 0;
    await measureAsync('pendingCountViaEngineBatch', () async {
      for (var i = 0; i < _queryRepetitions; i++) {
        totalCount += (await engine.pendingDelta()).changes.length;
      }
    });
    await measureAsync('countStatusViaStorageBatch', () async {
      for (var i = 0; i < _queryRepetitions; i++) {
        final retained = await storage.pending(
          source.id,
          recipientPeerId: _peerId,
        );
        pendingCount += retained
            .where((e) => e.status == OutboxStatus.pending)
            .length;
        sentCount += retained
            .where((e) => e.status == OutboxStatus.sent)
            .length;
      }
    });
    var summaryGlobal = OutboxSummary(pendingCount: 0, sentCount: 0);
    var summaryPeer = OutboxSummary(pendingCount: 0, sentCount: 0);
    await measureAsync('summaryGlobalBatch', () async {
      for (var i = 0; i < _queryRepetitions; i++) {
        summaryGlobal = await engine.pendingSummary();
      }
    });
    await measureAsync('summaryPeerBatch', () async {
      for (var i = 0; i < _queryRepetitions; i++) {
        summaryPeer = await engine.pendingSummary(recipientPeerId: _peerId);
      }
    });
    _require(
      summaryGlobal.totalCount * _queryRepetitions == totalCount &&
          summaryGlobal.sentCount ==
              entries.where((e) => e.status == OutboxStatus.sent).length,
      'global summary matches materialized entries',
    );
    _require(
      summaryPeer.pendingCount * _queryRepetitions == pendingCount &&
          summaryPeer.sentCount * _queryRepetitions == sentCount,
      'peer summary matches materialized entries',
    );
    Object? queried;
    measure('valueAtBatch', () {
      for (var i = 0; i < _queryRepetitions; i++) {
        queried = engine.valueAt(_address(0));
      }
    });
    _require(
      jsonEncode(queried) == jsonEncode(values[_address(0)]),
      'point value',
    );
    _require(totalCount == entries.length * _queryRepetitions, 'engine count');
    _require(
      pendingCount ==
          selected.where((e) => e.status == OutboxStatus.pending).length *
              _queryRepetitions,
      'pending status',
    );
    _require(
      sentCount ==
          selected.where((e) => e.status == OutboxStatus.sent).length *
              _queryRepetitions,
      'sent status',
    );
    _require(
      jsonEncode(engine.replica.toSnapshotJson()) == jsonEncode(beforeQueries),
      'queries must not change metadata',
    );

    final outbound = OutboundSync(
      replicaId: source.id,
      persistence: ReplicaPersistence(storage: storage),
      transport: const _NoopTransport(_peerId),
      retryPolicy: const SyncRetryPolicy(),
    );
    final batch = await measureAsync(
      'pushPreparation',
      () => outbound.prepare(force: true),
    );
    _require(
      batch.ids.join('|') == selected.map((e) => e.entryId).join('|'),
      'prepared IDs/order',
    );
    _require(
      jsonEncode(batch.delta.toJson()) ==
          jsonEncode(Delta(selected.expand((e) => e.delta.changes)).toJson()),
      'prepared payload',
    );
    final afterPrepare = await storage.pending(source.id);
    _require(
      afterPrepare.length == entries.length,
      'prepare must retain unacked entries',
    );
    for (var i = 0; i < afterPrepare.length; i++) {
      final before = entries[i], after = afterPrepare[i];
      if (before.recipientPeerId != _peerId) {
        _require(
          jsonEncode(before.toJson()) == jsonEncode(after.toJson()),
          'other peer metadata',
        );
      } else {
        _require(
          after.entryId == before.entryId &&
              after.attempts == before.attempts + 1 &&
              after.status == OutboxStatus.sent &&
              after.sentAt != null,
          'attempt metadata',
        );
      }
    }
    final committed = await measureAsync(
      'engineMutation',
      () => engine.setDelta(_address(0), value),
    );
    _require(
      committed.id == change.id,
      'restored sequence must produce same next ID',
    );
    _require(engine.valueAt(_address(0)) == value, 'committed value');
    _require(
      (await storage.pending(source.id)).length == entries.length + 1,
      'atomic outbox append',
    );
    _require(
      _sameSnapshot(
        (await storage.loadReplica(source.id))!.snapshot!,
        engine.replica.toSnapshotJson(),
      ),
      'committed snapshot',
    );
  } finally {
    await engine.dispose();
    if (storage is SqfliteReplicaStorage) await storage.close();
  }
  return {
    'microseconds': times,
    'verified': true,
    'processRssBytesBefore': rssBefore,
    'processRssBytesAfter': ProcessInfo.currentRss,
    'processMaxRssBytes': ProcessInfo.maxRss,
    if (sqlite)
      'sqliteFilesAfterCloseBytes': {
        for (final suffix in ['', '-wal', '-shm'])
          suffix.isEmpty ? 'main' : suffix.substring(1):
              await File('${root.path}/$name.db$suffix').exists()
              ? await File('${root.path}/$name.db$suffix').length()
              : 0,
      },
  };
}

String _address(int index) => 'field/${index.toString().padLeft(4, '0')}';

DeltaChange _pathChange(Replica replica, int index, int fields, String value) {
  final address = _address(index % fields);
  return switch (index % 8) {
    0 => replica.setDelta(address, value),
    1 => replica.incrementGCounter(address),
    2 => replica.incrementPnCounter(address),
    3 => replica.addGSet(address, value),
    4 => replica.addTwoPSet(address, value),
    5 => replica.writeMvRegister(address, value),
    6 => replica.addOrSet(address, value),
    _ => replica.addOrMapKey(address, 'key-$index'),
  };
}

Map<String, Object?> _pathValues(Replica replica) => {
  for (final address in (replica.state.addresses.toList()..sort()))
    address: _jsonValue(replica.valueAt(address)),
};

Object? _jsonValue(Object? value) {
  // Map/Set iteration order is not value semantics; ordered Lists stay ordered.
  if (value is Set) {
    return value.map(_jsonValue).toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
  }
  if (value is Map) {
    return {
      for (final key in (value.keys.cast<String>().toList()..sort()))
        key: _jsonValue(value[key]),
    };
  }
  if (value is List) return value.map(_jsonValue).toList();
  return value;
}

Map<String, Object?> _metadataProjection(Map<String, Object?> snapshot) {
  Map<String, Object?> changeMetadata(Map change) => {
    for (final key in [
      'id',
      'replicaId',
      'crdtId',
      'dot',
      'context',
      'observedDots',
      'keyDot',
      'timestamp',
      'deleted',
    ])
      if (change.containsKey(key)) key: change[key],
    if (change['valueChange'] case final Map nested)
      'valueChange': changeMetadata(nested),
  };
  return {
    for (final key in ['clock', 'hlc', 'deltaSequence']) key: snapshot[key],
    for (final table in [
      'gCounters',
      'pnCounters',
      'gSets',
      'twoPSets',
      'mvRegisters',
      'orSets',
      'orMaps',
    ])
      table: {
        for (final entry in (snapshot[table]! as Map).entries)
          entry.key: {
            for (final key in ['sequence', 'sequences', 'context'])
              if ((entry.value as Map).containsKey(key))
                key: (entry.value as Map)[key],
            if ((entry.value as Map)['changes'] case final List changes)
              'changes': changes.map((e) => changeMetadata(e as Map)).toList(),
            if ((entry.value as Map)['versions'] case final List versions)
              'versions': versions
                  .map((e) => changeMetadata(e as Map))
                  .toList(),
          },
      },
    'lww': {
      for (final entry in (snapshot['lww']! as Map).entries)
        entry.key: changeMetadata((entry.value as Map)['winner'] as Map),
    },
  };
}

bool _sameSnapshot(Map<String, Object?> left, Map<String, Object?> right) {
  // Replaying retained changes can advance the HLC during normal restoration.
  // Compare all other metadata/state and separately require HLC monotonicity.
  final leftHlc = HlcTimestamp.fromJson(
    Map<String, Object?>.from(left['hlc']! as Map),
  );
  final rightHlc = HlcTimestamp.fromJson(
    Map<String, Object?>.from(right['hlc']! as Map),
  );
  return leftHlc.compareTo(rightHlc) >= 0 &&
      jsonEncode(Map.of(left)..remove('hlc')) ==
          jsonEncode(Map.of(right)..remove('hlc'));
}

int _median(List<int> values) => (values..sort())[values.length ~/ 2];

void _require(bool condition, String message) {
  if (!condition) throw StateError('R-32 verification failed: $message');
}
