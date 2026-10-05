// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_transport/deltasync_transport.dart';

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

  /// Failures from transport stream callbacks; awaited methods still throw
  /// their own errors to the caller.
  Stream<SyncFailure> get errors => _errors.stream;

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

  /// Sends current pending changes without holding the commit queue during I/O.
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
  }

  Future<void> _commitCandidate(
    Replica candidate,
    Delta delta,
    OutboxEntry entry,
  ) async {
    if (storage != null) {
      await storage!.commit(_snapshot(candidate), [entry]);
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
      await _commitCandidate(
        candidate,
        delta,
        OutboxEntry(delta: delta, recipientPeerId: transport.peerReplicaId),
      );
      _replica.adopt(candidate);
      return change;
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

enum SyncFailureSource { incomingDelta, incomingStream }

/// Failure delivered by [SyncEngine.errors] from an incoming transport callback.
class SyncFailure {
  const SyncFailure({
    required this.source,
    required this.error,
    required this.stackTrace,
  });

  final SyncFailureSource source;
  final Object error;
  final StackTrace stackTrace;
}

/// Result of one push attempt. A null [acknowledgement] means only local send
/// completed; received ACKs do not populate [acknowledgedIds]. Legacy storage
/// retains changes even when remote ACK is received.
class SyncPushResult {
  SyncPushResult({
    required this.sent,
    required Iterable<String> acknowledgedIds,
    this.acknowledgement,
  }) : acknowledgedIds = Set.unmodifiable(acknowledgedIds);

  static SyncPushResult get empty =>
      SyncPushResult(sent: const Delta.empty(), acknowledgedIds: const []);

  final Delta sent;
  final Set<String> acknowledgedIds;
  final DeltaAcknowledgement? acknowledgement;

  bool get fullyAcknowledged =>
      sent.changes.every((change) => acknowledgedIds.contains(change.id));
}

/// Exponential retry policy for ReplicaStorage entries without confirmation.
///
/// Automatic retries stop after [maxAttempts] when configured. `push(force:
/// true)` deliberately bypasses both the retry delay and attempt cap for manual
/// retransmission. The legacy [PendingDeltaStore] path has no attempt metadata;
/// every push retries its retained delta and this policy does not apply there.
class SyncRetryPolicy {
  const SyncRetryPolicy({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 1),
    this.maxAttempts,
  });

  final Duration baseDelay;
  final Duration maxDelay;
  final int? maxAttempts;

  Duration delayFor(int attempts) {
    if (attempts <= 0) return Duration.zero;
    var delay = baseDelay > maxDelay ? maxDelay : baseDelay;
    for (var index = 1; index < attempts; index++) {
      final doubled = delay * 2;
      delay = doubled > maxDelay ? maxDelay : doubled;
    }
    return delay;
  }
}
