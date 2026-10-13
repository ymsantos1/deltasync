// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_transport/deltasync_transport.dart';

import 'sync_types.dart';
import 'sync/outbound_sync.dart';
import 'sync/replica_persistence.dart';
import 'sync/serial_commit_queue.dart';

export 'sync_types.dart';

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
  final SerialCommitQueue _queue = SerialCommitQueue();
  late final ReplicaPersistence _persistence = ReplicaPersistence(
    storage: storage,
    store: store,
  );
  late final OutboundSync _outbound = OutboundSync(
    replicaId: _replica.id,
    persistence: _persistence,
    transport: transport,
    retryPolicy: retryPolicy,
  );
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
      await _persistence.restoreInto(candidate);

      if (_lifecycle == SyncEngineLifecycle.disposed) {
        throw StateError('SyncEngine disposed while starting');
      }
      await _persistence.save(candidate);
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

  Future<void> _applyRemoteReady(Delta delta) =>
      _commitRemote((candidate) => candidate.apply(delta));

  /// Merges a peer's materialized snapshot for bootstrap or recovery.
  Future<void> applyRemoteSnapshot(Map<String, Object?> snapshot) =>
      _withStarted(
        () =>
            _commitRemote((candidate) => candidate.mergeSnapshotJson(snapshot)),
      );

  Future<void> _commitRemote(void Function(Replica) mutate) =>
      _queue.run(() async {
        final candidate = _replica.fork();
        mutate(candidate);
        await _persistence.commitRemote(candidate);
        _replica.adopt(candidate);
        _notifyCommit(SyncCommitOrigin.remote);
      });

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
    final batch = await _queue.run(() => _outbound.prepare(force: force));
    if (batch.delta.isEmpty) return SyncPushResult.empty;
    final result = await _outbound.send(batch);
    if (storage != null && result.acknowledgedIds.isNotEmpty) {
      await _queue.run(
        () => _persistence.acknowledge(
          _replica.id,
          transport.peerReplicaId,
          result.acknowledgedIds,
        ),
      );
    }
    return result;
  }

  /// Locally retained changes, including sent but unacknowledged changes. The
  /// deprecated store cannot remove entries even after a remote ACK.
  Future<Delta> pendingDelta() => _withStarted(
    () => _queue.run(() => _persistence.pendingDelta(_replica.id)),
  );

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
    await _queue.drained;
    await _errors.close();
    await _commits.close();
  }

  Future<T> _commitLocal<T extends DeltaChange>(T Function(Replica) mutate) =>
      _commitLocalResult(mutate, (change) => [change]);

  Future<List<T>> _commitLocalBatch<T extends DeltaChange>(
    List<T> Function(Replica) mutate,
  ) => _commitLocalResult(mutate, (changes) => changes);

  Future<R> _commitLocalResult<R>(
    R Function(Replica) mutate,
    Iterable<DeltaChange> Function(R) changesOf,
  ) => _withStarted(
    () => _queue.run(() async {
      final candidate = _replica.fork();
      final result = mutate(candidate);
      final changes = changesOf(result).toList();
      if (changes.isEmpty) throw StateError('Local change batch is empty');
      await _persistence.commitLocal(
        candidate,
        changes,
        transport.peerReplicaId,
      );
      _replica.adopt(candidate);
      _notifyCommit(SyncCommitOrigin.local);
      return result;
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
}
