import 'delta.dart';
import 'replica_state.dart';
import 'vector_clock.dart';
import 'delta_change.dart';
import 'hlc.dart';
import 'lww_delta.dart';
import 'identity.dart';
import 'g_counter.dart';
import 'g_set.dart';
import 'two_p_set.dart';
import 'pn_counter.dart';
import 'json_value.dart';
import 'mv_register.dart';
import 'or_set.dart';
import 'or_map.dart';

import 'replica/contents.dart';
import 'replica/delta_validation.dart';
import 'replica/snapshot_codec.dart';

part 'replica/field_query.dart';

/// Local CRDT replica. Storage and transport stay outside core.
class Replica {
  Replica(String id, {VectorClock? initialClock, HlcClock? hlc})
    : id = ReplicaId(id).value,
      _clock = initialClock ?? VectorClock(),
      _hlc = hlc ?? HlcClock();

  final String id;
  late ReplicaContents _contents = ReplicaContents(id);
  ReplicaState get _state => _contents.state;
  VectorClock _clock;
  final HlcClock _hlc;
  int _deltaSequence = 0;

  /// Detached read-only state; mutations must go through this Replica.
  ReplicaState get state => _state.copy();

  /// Returns the isolated value of one address without copying other fields.
  ///
  /// Missing addresses, LWW null values and LWW tombstones return null, as in
  /// indexing [ReplicaState]. Bound counters return int, sets/registers
  /// return `Set<Object?>` (except LWW), and OR-Map returns `Map<String, Set<Object?>>`.
  /// Nested collections are read-only and detached from future mutations.
  Object? valueAt(String address) {
    final kind = _state.kindAt(address);
    return kind == null ? null : _valueAtBoundAddress(address, kind);
  }

  /// Distinguishes an unbound address, a present value (including null), and
  /// a retained LWW deletion. Reads only the addressed materialized state;
  /// storage/outbox/ACK do not determine presence or deletion.
  ///
  /// The seven other bound kinds always return PresentField, even for zero or
  /// empty collections. Values follow [valueAt] types and are detached/read-only.
  /// This query does not change clocks, identities or CRDT state.
  FieldQuery query(String address) {
    final kind = _state.kindAt(address);
    if (kind == null) return const AbsentField._();
    if (kind == CrdtKind.lww && _state.isDeletedAt(address)) {
      return const DeletedField._();
    }
    return PresentField._(kind, _valueAtBoundAddress(address, kind));
  }

  Object? _valueAtBoundAddress(String address, CrdtKind kind) => switch (kind) {
    CrdtKind.lww => _state[address],
    CrdtKind.gCounter => gCounterValue(address),
    CrdtKind.pnCounter => pnCounterValue(address),
    CrdtKind.gSet => gSetValue(address),
    CrdtKind.twoPSet => twoPSetValue(address),
    CrdtKind.mvRegister => mvRegisterValue(address),
    CrdtKind.orSet => orSetValue(address),
    CrdtKind.orMap => orMapValue(address),
  };

  VectorClock get clock => _clock;

  HlcTimestamp get hlcTimestamp => _hlc.current;

  /// Value of addressed G-Counter, or zero before its first change.
  int gCounterValue(String crdtId) => _contents.gCounters[crdtId]?.value ?? 0;

  /// Value of addressed PN-Counter, or zero before its first change.
  int pnCounterValue(String crdtId) => _contents.pnCounters[crdtId]?.value ?? 0;

  /// Read-only value of addressed G-Set, empty before its first addition.
  Set<Object?> gSetValue(String crdtId) =>
      _contents.gSets[crdtId]?.value ?? const <Object?>{};

  /// Read-only value of addressed 2P-Set, empty before its first addition.
  Set<Object?> twoPSetValue(String crdtId) =>
      _contents.twoPSets[crdtId]?.value ?? const <Object?>{};

  Set<Object?> mvRegisterValue(String crdtId) =>
      _contents.mvRegisters[crdtId]?.value ?? const <Object?>{};

  /// Read-only value of addressed OR-Set, empty before its first change.
  Set<Object?> orSetValue(String crdtId) =>
      _contents.orSets[crdtId]?.value ?? const <Object?>{};

  /// Read-only map value; each present key contains its nested G-Set value.
  Map<String, Set<Object?>> orMapValue(String crdtId) =>
      _contents.orMaps[crdtId]?.value ?? const <String, Set<Object?>>{};

  void restoreMetadata({
    required VectorClock clock,
    required HlcTimestamp hlc,
  }) {
    _clock = clock;
    _hlc.restore(hlc);
  }

  /// Creates isolated working copy for a transaction or rollback boundary.
  Replica fork() => Replica(id, initialClock: _clock, hlc: _hlc.copy())
    .._contents = _contents.copy()
    .._deltaSequence = _deltaSequence;

  /// Replaces this replica with an already committed isolated candidate.
  void adopt(Replica candidate) {
    if (candidate.id != id) throw ArgumentError('Replica ID mismatch');
    final contents = candidate._contents.copy();
    _contents = contents;
    _clock = candidate._clock;
    _hlc.restore(candidate.hlcTimestamp);
    _deltaSequence = candidate._deltaSequence;
  }

  /// Compact, versioned materialized state for durable snapshots.
  Map<String, Object?> toSnapshotJson() => ReplicaSnapshotCodec.encode(
    replicaId: id,
    clock: _clock,
    hlc: _hlc.current,
    deltaSequence: _deltaSequence,
    contents: _contents,
  );

  /// Reconstructs materialized state without replaying prior delta history.
  static Replica fromSnapshotJson(Map<String, Object?> json) {
    final decoded = ReplicaSnapshotCodec.decode(json);
    final restored =
        Replica(
            decoded.replicaId,
            initialClock: decoded.clock,
            hlc: decoded.hlc,
          )
          .._contents = decoded.contents
          .._deltaSequence = decoded.deltaSequence;
    for (final winner in restored._contents.lwwWinners) {
      restored._observeDeltaSequence(winner.id);
    }
    return restored;
  }

  void apply(Delta delta) {
    validateReplicaDeltaBatch(delta, _contents);
    final candidate = fork().._applyValidated(delta);
    adopt(candidate);
  }

  void _applyValidated(Delta delta) {
    for (final change in delta.changes) {
      switch (change) {
        case LwwDelta<Object?>():
          _state.applyDelta(change);
          if (change.dot != null) {
            _clock = _clock.merge(
              VectorClock({change.dot!.replicaId: change.dot!.counter}),
            );
          }
          _hlc.observe(change.timestamp);
          break;
        case GCounterDelta():
          _contents.gCounters.apply(change);
          break;
        case PnCounterDelta():
          _contents.pnCounters.apply(change);
          break;
        case GSetDelta():
          _contents.gSets.apply(change);
          break;
        case TwoPSetDelta():
          _contents.twoPSets.apply(change);
          break;
        case MvRegisterDelta():
          _contents.mvRegisters.apply(change);
          break;
        case OrSetDelta():
          _contents.orSets.apply(change);
          break;
        case OrMapDelta():
          _contents.orMaps.apply(change);
          break;
        default:
          throw FormatException('Unsupported CRDT delta type');
      }
      _observeDeltaSequence(change.id);
    }
  }

  /// Exports current winners and cumulative counter components for bootstrap.
  /// It is not a durable operation log or peer-specific ACK history.
  Delta export() => Delta(_contents.exportChanges());

  /// Compact, versioned materialized state for bootstrap and storage.
  Map<String, Object?> exportSnapshot() => toSnapshotJson();

  /// Joins a peer snapshot without replacing this replica's identity.
  ///
  /// Useful for initial bootstrap when a peer lacks deltas. The merge is
  /// isolated: malformed or conflicting state leaves this replica unchanged.
  /// Returns the peer snapshot's bound addresses, including tombstones and
  /// empty CRDTs, as a detached read-only set. These are processed addresses,
  /// not a comparison of visible values; local-only addresses are not included.
  Set<String> mergeSnapshotJson(Map<String, Object?> json) {
    final remote = Replica.fromSnapshotJson(json);
    final candidate = fork();
    candidate._contents.merge(remote._contents);
    candidate
      .._clock = _clock.merge(remote._clock)
      .._hlc.restore(remote.hlcTimestamp);
    if (remote.id == id && remote._deltaSequence > candidate._deltaSequence) {
      candidate._deltaSequence = remote._deltaSequence;
    }
    adopt(candidate);
    return remote._state.addresses;
  }

  /// Creates and applies native LWW delta.
  LwwDelta<Object?> setDelta(String key, Object? value) =>
      _recordDelta(key, value);

  /// Creates and applies native LWW delete tombstone.
  LwwDelta<Object?> removeDelta(String key) =>
      _recordDelta(key, null, deleted: true);

  /// Increments G-Counter at stable application-defined [crdtId].
  GCounterDelta incrementGCounter(String crdtId, [int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _ensureLocalAddress(crdtId, CrdtKind.gCounter);
    return _contents.gCounters.mutate(
      crdtId,
      (counter) => counter.increment(amount),
    );
  }

  /// Increments addressed PN-Counter and returns its transportable delta.
  PnCounterDelta incrementPnCounter(String crdtId, [int amount = 1]) =>
      _changePnCounter(crdtId, (counter) => counter.increment(amount), amount);

  /// Decrements addressed PN-Counter and returns its transportable delta.
  PnCounterDelta decrementPnCounter(String crdtId, [int amount = 1]) =>
      _changePnCounter(crdtId, (counter) => counter.decrement(amount), amount);

  /// Adds [element] to the addressed G-Set and returns its delta.
  GSetDelta addGSet(String crdtId, Object? element) =>
      addAllGSet(crdtId, [element]);

  /// Adds [elements] to the addressed G-Set as one delta.
  GSetDelta addAllGSet(String crdtId, Iterable<Object?> elements) {
    _ensureLocalAddress(crdtId, CrdtKind.gSet);
    return _contents.gSets.mutate(crdtId, (set) => set.addAll(elements));
  }

  /// Adds [element] to the addressed 2P-Set and returns its delta.
  TwoPSetDelta addTwoPSet(String crdtId, Object? element) =>
      addAllTwoPSet(crdtId, [element]);

  /// Adds [elements] to the addressed 2P-Set in one delta.
  TwoPSetDelta addAllTwoPSet(String crdtId, Iterable<Object?> elements) {
    _ensureLocalAddress(crdtId, CrdtKind.twoPSet);
    return _contents.twoPSets.mutate(crdtId, (set) => set.addAll(elements));
  }

  /// Permanently removes [element] from the addressed 2P-Set.
  TwoPSetDelta removeTwoPSet(String crdtId, Object? element) =>
      removeAllTwoPSet(crdtId, [element]);

  /// Permanently removes [elements] from the addressed 2P-Set in one delta.
  TwoPSetDelta removeAllTwoPSet(String crdtId, Iterable<Object?> elements) {
    _ensureLocalAddress(crdtId, CrdtKind.twoPSet);
    return _contents.twoPSets.mutate(crdtId, (set) => set.removeAll(elements));
  }

  /// Writes an addressed MV-Register value and returns its causal delta.
  MvRegisterDelta writeMvRegister(String crdtId, Object? value) {
    validateJsonInput(value);
    _ensureLocalAddress(crdtId, CrdtKind.mvRegister);
    final delta = _contents.mvRegisters.mutate(
      crdtId,
      (register) => register.write(value),
    );
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Adds [element] to the addressed OR-Set with a unique observed-remove tag.
  OrSetDelta addOrSet(String crdtId, Object? element) {
    validateJsonInput(element);
    _ensureLocalAddress(crdtId, CrdtKind.orSet);
    final delta = _contents.orSets.mutate(crdtId, (set) => set.add(element));
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Removes only OR-Set add tags for [element] already observed locally.
  OrSetDelta removeOrSet(String crdtId, Object? element) {
    validateJsonInput(element);
    _ensureLocalAddress(crdtId, CrdtKind.orSet);
    final delta = _contents.orSets.mutate(crdtId, (set) => set.remove(element));
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Adds a fresh OR-Map key incarnation with an empty G-Set value.
  OrMapDelta addOrMapKey(String crdtId, String key) {
    _ensureLocalAddress(crdtId, CrdtKind.orMap);
    final delta = _contents.orMaps.mutate(crdtId, (map) => map.addKey(key));
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Removes only observed OR-Map key incarnations.
  OrMapDelta removeOrMapKey(String crdtId, String key) {
    _ensureLocalAddress(crdtId, CrdtKind.orMap);
    final delta = _contents.orMaps.mutate(crdtId, (map) => map.removeKey(key));
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Adds value to nested G-Set at each key incarnation observed locally.
  List<OrMapDelta> addOrMapValue(String crdtId, String key, Object? value) {
    validateJsonInput(value);
    _ensureLocalAddress(crdtId, CrdtKind.orMap);
    final map = _contents.orMaps[crdtId];
    if (map == null) throw StateError('OR-Map key is not present');
    final deltas = map.addValue(key, value);
    _state.bind(crdtId, CrdtKind.orMap);
    for (final delta in deltas) {
      _observeDeltaSequence(delta.id);
    }
    return deltas;
  }

  LwwDelta<Object?> _recordDelta(
    String key,
    Object? value, {
    bool deleted = false,
  }) {
    _validateLocalKey(key);
    if (!deleted) validateJsonInput(value);
    _clock = _clock.tick(id);
    final dot = Dot(replicaId: id, counter: _clock.entries[id]!);
    final delta = LwwDelta<Object?>(
      key: key,
      id: '$id:delta:${++_deltaSequence}',
      replicaId: id,
      timestamp: _hlc.tick(),
      value: deleted ? null : copyJsonValue(value, freeze: true),
      deleted: deleted,
      dot: dot,
    );
    _state.applyDelta(delta);
    return delta;
  }

  void _validateLocalKey(String key) {
    if (key.isEmpty || key.trim() != key) {
      throw ArgumentError.value(key, 'key');
    }
    if (_state.kindAt(key) case final kind? when kind != CrdtKind.lww) {
      throw StateError('CRDT address is already bound to another type');
    }
  }

  PnCounterDelta _changePnCounter(
    String crdtId,
    PnCounterDelta Function(PnCounter) mutate,
    int amount,
  ) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _ensureLocalAddress(crdtId, CrdtKind.pnCounter);
    return _contents.pnCounters.mutate(crdtId, mutate);
  }

  void _ensureLocalAddress(String crdtId, CrdtKind type) {
    if (crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw ArgumentError.value(crdtId, 'crdtId');
    }
    if (crdtId.startsWith('legacy/')) {
      throw ArgumentError.value(crdtId, 'crdtId', 'legacy/ is reserved');
    }
    final currentType = _state.kindAt(crdtId);
    if (currentType != null && currentType != type) {
      throw StateError('CRDT address is already bound to another type');
    }
  }

  void _observeDeltaSequence(String deltaId) {
    final prefix = '$id:delta:';
    if (!deltaId.startsWith(prefix)) return;
    final sequence = int.tryParse(deltaId.substring(prefix.length));
    if (sequence != null && sequence > _deltaSequence) {
      _deltaSequence = sequence;
    }
  }
}
