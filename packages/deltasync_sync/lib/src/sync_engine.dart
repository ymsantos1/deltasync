// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_transport/deltasync_transport.dart';

part 'sync_types.dart';

/// Coordinates local CRDT changes, pending persistence, and remote deltas.
class SyncEngine {
  SyncEngine({
    required Replica replica,
    @Deprecated('Use SyncEngine.withStorage and ReplicaStorage.') this.store,
    this.storage,
    required this.transport,
    this.retryPolicy = const SyncRetryPolicy(),
  }) : _replica = replica.fork() {
    if ((store != null) == (storage != null)) {
      throw ArgumentError('Provide exactly one of storage or store');
    }
    if (transport.peerReplicaId.isEmpty ||
        transport.peerReplicaId.trim() != transport.peerReplicaId) {
      throw ArgumentError.value(transport.peerReplicaId, 'peerReplicaId');
    }
  }

  SyncEngine.withStorage({
    required Replica replica,
    required ReplicaStorage storage,
    required DeltaTransport transport,
    SyncRetryPolicy retryPolicy = const SyncRetryPolicy(),
  }) : this(
         replica: replica,
         storage: storage,
         transport: transport,
         retryPolicy: retryPolicy,
       );

  final Replica _replica;

  /// Detached view. Available after restoration; mutations cannot bypass commits.
  Replica get replica {
    if (_lifecycle != SyncEngineLifecycle.started &&
        _lifecycle != SyncEngineLifecycle.disposed) {
      throw StateError('SyncEngine state is not restored');
    }
    return _replica.fork();
  }

  /// Current initialization, running or terminal lifecycle state.
  SyncEngineLifecycle get lifecycle => _lifecycle;

  /// Failures from transport stream callbacks; awaited methods throw to callers.
  /// This stream does not report successful commits or push progress.
  Stream<SyncFailure> get errors => _errors.stream;

  /// Non-replaying notifications after a local or remote commit is adopted.
  /// Read [replica] for the latest state; this event does not imply remote ACK.
  /// The stream closes when [dispose] completes.
  Stream<SyncCommitEvent> get commits => _commits.stream;

  @Deprecated('Use SyncEngine.withStorage and ReplicaStorage.')
  final PendingDeltaStore? store;
  final ReplicaStorage? storage;
  final DeltaTransport transport;
  StreamSubscription<DeltaEnvelope>? _subscription;
  SyncEngineLifecycle _lifecycle = SyncEngineLifecycle.created;
  Future<void>? _startFuture;
  Future<void>? _disposeFuture;
  Future<SyncPushResult>? _pushFuture;
  Future<void> _serialTail = Future<void>.value();
  int _activeRequests = 0;
  Completer<void>? _activeRequestsDrained;
  final StreamController<SyncFailure> _errors =
      StreamController<SyncFailure>.broadcast();
  final StreamController<SyncCommitEvent> _commits =
      StreamController<SyncCommitEvent>.broadcast(sync: false);
  final SyncRetryPolicy retryPolicy;

  /// Restores state and subscribes to remote changes. Repeated calls after
  /// success are harmless; failed starts can be retried.
  Future<void> start() {
    if (_lifecycle == SyncEngineLifecycle.disposed) {
      return Future.error(StateError('SyncEngine already disposed'));
    }
    if (_lifecycle == SyncEngineLifecycle.started) return Future.value();
    final running = _startFuture;
    if (running != null) return running;

    _lifecycle = SyncEngineLifecycle.starting;
    late final Future<void> starting;
    starting = _startInternal().whenComplete(() {
      if (identical(_startFuture, starting)) _startFuture = null;
    });
    _startFuture = starting;
    return starting;
  }

  Future<void> _startInternal() async {
    final candidate = _replica.fork();
    try {
      if (storage != null) {
        final snapshot = await storage!.loadReplica(candidate.id);
        if (snapshot != null) {
          if (snapshot.version == 2) {
            final encodedState = snapshot.snapshot;
            if (encodedState == null) {
              throw FormatException('Missing canonical replica snapshot');
            }
            candidate.adopt(Replica.fromSnapshotJson(encodedState));
          } else if (snapshot.version == 1) {
            _restoreLegacySnapshot(candidate, snapshot);
          } else {
            throw FormatException('Unsupported storage snapshot version');
          }
        }
        for (final entry in await storage!.pending(candidate.id)) {
          candidate.apply(entry.delta);
        }
      } else {
        candidate.apply(await store!.read(candidate.id));
      }

      if (_lifecycle == SyncEngineLifecycle.disposed) {
        throw StateError('SyncEngine disposed while starting');
      }
      if (storage != null) await storage!.saveReplica(_snapshot(candidate));
      if (_lifecycle == SyncEngineLifecycle.disposed) {
        throw StateError('SyncEngine disposed while starting');
      }
      _replica.adopt(candidate);
      _lifecycle = SyncEngineLifecycle.started;
      _subscription = transport.incoming.listen(
        _receiveRemote,
        onError: _receiveStreamError,
      );
    } catch (_) {
      if (_lifecycle != SyncEngineLifecycle.disposed) {
        _lifecycle = SyncEngineLifecycle.created;
      }
      rethrow;
    }
  }

  @Deprecated('Use setDelta; returns native LwwDelta.')
  Future<LwwDelta<Object?>> set(String key, Object? value) =>
      setDelta(key, value);

  /// Applies remote changes after a serialized snapshot commit succeeds.
  Future<void> applyRemote(Delta delta) =>
      _withStarted(() => _applyRemoteReady(delta));

  Future<void> _applyRemoteReady(Delta delta) => _serialize(() async {
    final candidate = _replica.fork()..apply(delta);
    if (storage != null) await storage!.commitRemote(_snapshot(candidate));
    _replica.adopt(candidate);
    _notifyCommit(SyncCommitOrigin.remote);
  });

  /// Merges a peer's materialized snapshot for bootstrap or recovery.
  Future<void> applyRemoteSnapshot(Map<String, Object?> snapshot) =>
      _withStarted(
        () => _serialize(() async {
          final candidate = _replica.fork()..mergeSnapshotJson(snapshot);
          if (storage != null) {
            await storage!.commitRemote(_snapshot(candidate));
          }
          _replica.adopt(candidate);
          _notifyCommit(SyncCommitOrigin.remote);
        }),
      );

  @Deprecated('Use removeDelta; returns native LwwDelta.')
  Future<LwwDelta<Object?>> remove(String key) => removeDelta(key);

  Future<LwwDelta<Object?>> setDelta(String key, Object? value) =>
      _commitLocal((candidate) => candidate.setDelta(key, value));

  Future<LwwDelta<Object?>> removeDelta(String key) =>
      _commitLocal((candidate) => candidate.removeDelta(key));

  /// Increments G-Counter at stable application-defined [crdtId].
  Future<GCounterDelta> incrementGCounter(String crdtId, [int amount = 1]) =>
      _commitLocal((candidate) => candidate.incrementGCounter(crdtId, amount));

  /// Increments PN-Counter at stable application-defined [crdtId].
  Future<PnCounterDelta> incrementPnCounter(String crdtId, [int amount = 1]) =>
      _commitLocal((candidate) => candidate.incrementPnCounter(crdtId, amount));

  /// Decrements PN-Counter at stable application-defined [crdtId].
  Future<PnCounterDelta> decrementPnCounter(String crdtId, [int amount = 1]) =>
      _commitLocal((candidate) => candidate.decrementPnCounter(crdtId, amount));

  /// Adds [element] to the addressed G-Set and commits its change to the outbox.
  Future<GSetDelta> addGSet(String crdtId, Object? element) =>
      _commitLocal((candidate) => candidate.addGSet(crdtId, element));

  /// Adds [elements] to the addressed G-Set as one committed change.
  Future<GSetDelta> addAllGSet(String crdtId, Iterable<Object?> elements) =>
      _commitLocal((candidate) => candidate.addAllGSet(crdtId, elements));

  /// Adds [element] to the addressed 2P-Set and commits its change to the outbox.
  Future<TwoPSetDelta> addTwoPSet(String crdtId, Object? element) =>
      _commitLocal((candidate) => candidate.addTwoPSet(crdtId, element));

  /// Adds [elements] to the addressed 2P-Set as one committed change.
  Future<TwoPSetDelta> addAllTwoPSet(
    String crdtId,
    Iterable<Object?> elements,
  ) => _commitLocal((candidate) => candidate.addAllTwoPSet(crdtId, elements));

  /// Permanently removes [element] from the addressed 2P-Set.
  Future<TwoPSetDelta> removeTwoPSet(String crdtId, Object? element) =>
      _commitLocal((candidate) => candidate.removeTwoPSet(crdtId, element));

  /// Permanently removes [elements] from the addressed 2P-Set in one change.
  Future<TwoPSetDelta> removeAllTwoPSet(
    String crdtId,
    Iterable<Object?> elements,
  ) =>
      _commitLocal((candidate) => candidate.removeAllTwoPSet(crdtId, elements));

  /// Writes an MV-Register version and commits its causal delta to the outbox.
  Future<MvRegisterDelta> writeMvRegister(String crdtId, Object? value) =>
      _commitLocal((candidate) => candidate.writeMvRegister(crdtId, value));

  /// Adds an OR-Set value and commits its unique tag to the outbox.
  Future<OrSetDelta> addOrSet(String crdtId, Object? element) =>
      _commitLocal((candidate) => candidate.addOrSet(crdtId, element));

  /// Removes OR-Set tags observed by this replica and commits removal context.
  Future<OrSetDelta> removeOrSet(String crdtId, Object? element) =>
      _commitLocal((candidate) => candidate.removeOrSet(crdtId, element));

  /// Creates a key in an OR-Map with a nested G-Set value.
  Future<OrMapDelta> addOrMapKey(String crdtId, String key) =>
      _commitLocal((candidate) => candidate.addOrMapKey(crdtId, key));

  /// Removes key incarnations observed by this replica.
  Future<OrMapDelta> removeOrMapKey(String crdtId, String key) =>
      _commitLocal((candidate) => candidate.removeOrMapKey(crdtId, key));

  /// Adds a value to nested G-Sets for observed key incarnations.
  Future<List<OrMapDelta>> addOrMapValue(
    String crdtId,
    String key,
    Object? value,
  ) => _commitLocalBatch(
    (candidate) => candidate.addOrMapValue(crdtId, key, value),
  );

  /// Sends eligible pending changes without holding the commit queue during I/O.
  /// The caller schedules each push; this engine has no background retry timer.
  /// With [ReplicaStorage], normal calls select new entries and sent entries
  /// whose delay has elapsed and attempts remain below the cap. [force] bypasses
  /// those filters.
  /// Result lists IDs durably acknowledged by an acknowledging transport.
  Future<SyncPushResult> push({bool force = false}) {
    if (_lifecycle == SyncEngineLifecycle.disposed) {
      return Future.error(StateError('SyncEngine already disposed'));
    }
    final running = _pushFuture;
    if (running != null) return running;
    late final Future<SyncPushResult> pushing;
    pushing = start().then((_) => _pushReady(force: force)).whenComplete(() {
      if (identical(_pushFuture, pushing)) _pushFuture = null;
    });
    _pushFuture = pushing;
    return pushing;
  }

  Future<SyncPushResult> _pushReady({required bool force}) async {
    final outbound = await _serialize(() => _prepareOutbound(force: force));
    if (outbound.delta.isEmpty) return SyncPushResult.empty;

    final envelope = DeltaEnvelope(
      senderReplicaId: _replica.id,
      recipientReplicaId: transport.peerReplicaId,
      delta: outbound.delta,
    );
    final acknowledgement = transport is AcknowledgingDeltaTransport
        ? await (transport as AcknowledgingDeltaTransport).sendAndAwaitAck(
            envelope,
          )
        : await _sendWithoutAck(envelope);
    if (acknowledgement != null &&
        acknowledgement.peerReplicaId != transport.peerReplicaId) {
      throw StateError('ACK peer does not match configured transport peer');
    }
    final acceptedIds =
        acknowledgement?.stage == DeltaAckStage.appliedAndPersisted
        ? acknowledgement!.changeIds
              .where(outbound.ids.toSet().contains)
              .toSet()
        : <String>{};
    if (storage != null && acceptedIds.isNotEmpty) {
      await _serialize(
        () => storage!.acknowledge(
          _replica.id,
          transport.peerReplicaId,
          acceptedIds,
        ),
      );
    }
    return SyncPushResult(
      sent: outbound.delta,
      acknowledgedIds: acceptedIds,
      acknowledgement: acknowledgement,
    );
  }

  Future<({Delta delta, List<String> ids})> _prepareOutbound({
    required bool force,
  }) async {
    if (storage == null) {
      final pending = await store!.read(_replica.id);
      return (
        delta: pending,
        ids: pending.changes.map((change) => change.id).toList(),
      );
    }
    final allEntries = await storage!.pending(
      _replica.id,
      recipientPeerId: transport.peerReplicaId,
    );
    final now = DateTime.now().toUtc();
    final entries = allEntries.where((entry) {
      if (force || entry.status == OutboxStatus.pending) return true;
      final maxAttempts = retryPolicy.maxAttempts;
      if (maxAttempts != null && entry.attempts >= maxAttempts) return false;
      final sentAt = entry.sentAt;
      return sentAt == null ||
          now.difference(sentAt) >= retryPolicy.delayFor(entry.attempts);
    }).toList();
    if (entries.isEmpty) {
      return (delta: const Delta.empty(), ids: const <String>[]);
    }
    var pending = const Delta.empty();
    for (final entry in entries) {
      pending = pending.merge(entry.delta);
    }
    final ids = entries.expand((entry) => entry.changeIds).toList();
    await storage!.markSent(_replica.id, transport.peerReplicaId, ids);
    return (delta: pending, ids: ids);
  }

  /// Locally retained changes, including sent but unacknowledged changes. The
  /// deprecated store cannot remove entries even after a remote ACK.
  Future<Delta> pendingDelta() async {
    return _withStarted(
      () => _serialize(() async {
        if (storage == null) return store!.read(_replica.id);
        var pending = const Delta.empty();
        for (final entry in await storage!.pending(_replica.id)) {
          pending = pending.merge(entry.delta);
        }
        return pending;
      }),
    );
  }

  Future<void> dispose() {
    if (_lifecycle == SyncEngineLifecycle.disposed) {
      return _disposeFuture ?? Future.value();
    }
    _lifecycle = SyncEngineLifecycle.disposed;
    final disposing = _disposeInternal();
    _disposeFuture = disposing;
    return disposing;
  }

  Future<void> _disposeInternal() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    try {
      await _startFuture;
    } catch (_) {
      // Start error was already returned to its caller.
    }
    try {
      await _pushFuture;
    } catch (_) {
      // Push error was already returned to its caller.
    }
    if (_activeRequests > 0) {
      final drained = _activeRequestsDrained ??= Completer<void>();
      await drained.future;
    }
    await _serialTail;
    await _errors.close();
    await _commits.close();
  }

  Future<void> _commitCandidate(
    Replica candidate,
    Delta delta,
    List<OutboxEntry> entries,
  ) async {
    if (storage != null) {
      await storage!.commit(_snapshot(candidate), entries);
    } else {
      final pending = await store!.read(_replica.id);
      await store!.write(_replica.id, pending.merge(delta));
    }
  }

  Future<DeltaAcknowledgement?> _sendWithoutAck(DeltaEnvelope envelope) async {
    await transport.send(envelope);
    return null;
  }

  ReplicaSnapshot _snapshot([Replica? source]) {
    final snapshotSource = source ?? _replica;
    return ReplicaSnapshot.fromReplica(snapshotSource);
  }

  Future<T> _commitLocal<T extends DeltaChange>(
    T Function(Replica candidate) mutate,
  ) => _withStarted(
    () => _serialize(() async {
      final candidate = _replica.fork();
      final change = mutate(candidate);
      final delta = Delta([change]);
      await _commitCandidate(candidate, delta, [
        OutboxEntry(delta: delta, recipientPeerId: transport.peerReplicaId),
      ]);
      _replica.adopt(candidate);
      _notifyCommit(SyncCommitOrigin.local);
      return change;
    }),
  );

  Future<List<T>> _commitLocalBatch<T extends DeltaChange>(
    List<T> Function(Replica candidate) mutate,
  ) => _withStarted(
    () => _serialize(() async {
      final candidate = _replica.fork();
      final changes = mutate(candidate);
      if (changes.isEmpty) throw StateError('Local change batch is empty');
      final delta = Delta(changes);
      await _commitCandidate(candidate, delta, [
        for (final change in changes)
          OutboxEntry(
            delta: Delta([change]),
            recipientPeerId: transport.peerReplicaId,
          ),
      ]);
      _replica.adopt(candidate);
      _notifyCommit(SyncCommitOrigin.local);
      return changes;
    }),
  );

  void _receiveRemote(DeltaEnvelope envelope) {
    unawaited(
      _applyIncomingReady(envelope).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _reportFailure(SyncFailureSource.incomingDelta, error, stackTrace);
      }),
    );
  }

  void _notifyCommit(SyncCommitOrigin origin) {
    if (!_commits.isClosed) _commits.add(SyncCommitEvent(origin: origin));
  }

  Future<void> _applyIncomingReady(DeltaEnvelope envelope) {
    if (envelope.recipientReplicaId != _replica.id ||
        envelope.senderReplicaId != transport.peerReplicaId) {
      return Future.error(
        FormatException('Envelope peer identity does not match sync link'),
      );
    }
    return _applyRemoteReady(envelope.delta);
  }

  void _receiveStreamError(Object error, StackTrace stackTrace) {
    _reportFailure(SyncFailureSource.incomingStream, error, stackTrace);
  }

  void _reportFailure(
    SyncFailureSource source,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!_errors.isClosed) {
      _errors.add(
        SyncFailure(source: source, error: error, stackTrace: stackTrace),
      );
    }
  }

  Future<T> _withStarted<T>(Future<T> Function() action) {
    if (_lifecycle == SyncEngineLifecycle.disposed) {
      return Future.error(StateError('SyncEngine already disposed'));
    }
    _activeRequests++;
    return start().then((_) => action()).whenComplete(() {
      _activeRequests--;
      if (_activeRequests == 0) {
        final drained = _activeRequestsDrained;
        _activeRequestsDrained = null;
        if (drained != null && !drained.isCompleted) drained.complete();
      }
    });
  }

  void _restoreLegacySnapshot(Replica target, ReplicaSnapshot snapshot) {
    if (snapshot.replicaId != target.id) {
      throw FormatException('Snapshot replica ID mismatch');
    }
    final metadata = snapshot.legacyMetadata;
    final clock = snapshot.legacyClock;
    if (metadata == null || clock == null) {
      throw FormatException('Invalid legacy replica snapshot');
    }
    final encodedState = metadata['replicaState'];
    if (encodedState is Map) {
      target.adopt(
        Replica.fromSnapshotJson(Map<String, Object?>.from(encodedState)),
      );
      return;
    }
    final hlc = _readHlcOrNull(metadata);
    if (hlc != null) target.restoreMetadata(clock: clock, hlc: hlc);
    final encoded = metadata['delta'];
    if (encoded is Map) {
      target.apply(
        Delta.fromJson(
          Map<String, Object?>.from(encoded),
          allowLegacyOperations: true,
          allowLegacyCounterIdentity: true,
        ),
      );
      return;
    }
    if (snapshot.legacyState?.isNotEmpty ?? false) {
      throw FormatException('Legacy snapshot lacks replayable state');
    }
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _serialTail = _serialTail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  HlcTimestamp? _readHlcOrNull(Map<String, Object?> metadata) {
    final value = metadata['hlc'];
    if (value == null) return null;
    if (value is! Map) throw FormatException('Invalid snapshot HLC');
    return HlcTimestamp.fromJson(Map<String, Object?>.from(value));
  }
}

/// Public lifecycle of a [SyncEngine]. A failed start returns to [created] and
/// may be retried; [disposed] is terminal.
enum SyncEngineLifecycle { created, starting, started, disposed }
