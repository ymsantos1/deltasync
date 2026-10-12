import 'dart:convert';

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

/// Local CRDT replica. Storage and transport stay outside core.
class Replica {
  Replica(String id, {VectorClock? initialClock, HlcClock? hlc})
    : id = ReplicaId(id).value,
      _clock = initialClock ?? VectorClock(),
      _hlc = hlc ?? HlcClock();

  final String id;
  final ReplicaState _state = ReplicaState();
  final Map<String, GCounter> _gCounters = {};
  final Map<String, PnCounter> _pnCounters = {};
  final Map<String, GSet> _gSets = {};
  final Map<String, TwoPSet> _twoPSets = {};
  final Map<String, MvRegister> _mvRegisters = {};
  final Map<String, OrSet> _orSets = {};
  final Map<String, OrMap> _orMaps = {};
  VectorClock _clock;
  final HlcClock _hlc;
  int _deltaSequence = 0;

  /// Detached read-only state; mutations must go through this Replica.
  ReplicaState get state => _state.copy();

  VectorClock get clock => _clock;

  HlcTimestamp get hlcTimestamp => _hlc.current;

  /// Value of addressed G-Counter, or zero before its first change.
  int gCounterValue(String crdtId) => _gCounters[crdtId]?.value ?? 0;

  /// Value of addressed PN-Counter, or zero before its first change.
  int pnCounterValue(String crdtId) => _pnCounters[crdtId]?.value ?? 0;

  /// Read-only value of addressed G-Set, empty before its first addition.
  Set<Object?> gSetValue(String crdtId) =>
      _gSets[crdtId]?.value ?? const <Object?>{};

  /// Read-only value of addressed 2P-Set, empty before its first addition.
  Set<Object?> twoPSetValue(String crdtId) =>
      _twoPSets[crdtId]?.value ?? const <Object?>{};

  Set<Object?> mvRegisterValue(String crdtId) =>
      _mvRegisters[crdtId]?.value ?? const <Object?>{};

  /// Read-only value of addressed OR-Set, empty before its first change.
  Set<Object?> orSetValue(String crdtId) =>
      _orSets[crdtId]?.value ?? const <Object?>{};

  /// Read-only map value; each present key contains its nested G-Set value.
  Map<String, Set<Object?>> orMapValue(String crdtId) =>
      _orMaps[crdtId]?.value ?? const <String, Set<Object?>>{};

  void restoreMetadata({
    required VectorClock clock,
    required HlcTimestamp hlc,
  }) {
    _clock = clock;
    _hlc.restore(hlc);
  }

  /// Creates isolated working copy for a transaction or rollback boundary.
  Replica fork() {
    final copy = Replica(id, initialClock: _clock, hlc: _hlc.copy());
    copy._state.replaceWith(_state);
    copy._deltaSequence = _deltaSequence;
    for (final entry in _gCounters.entries) {
      final json = entry.value.toJson();
      copy._gCounters[entry.key] = GCounter(
        id,
        crdtId: entry.key,
        components: _intMap(json['components']),
        sequences: _optionalIntMap(json['sequences']),
        sequence: json['sequence'] as int,
      );
    }
    for (final entry in _pnCounters.entries) {
      final json = entry.value.toJson();
      copy._pnCounters[entry.key] = PnCounter(
        id,
        crdtId: entry.key,
        positive: _intMap(json['positive']),
        negative: _intMap(json['negative']),
        sequences: _optionalIntMap(json['sequences']),
        sequence: json['sequence'] as int,
      );
    }
    for (final entry in _gSets.entries) {
      copy._gSets[entry.key] = GSet.fromJson(entry.value.toJson());
    }
    for (final entry in _twoPSets.entries) {
      copy._twoPSets[entry.key] = TwoPSet.fromJson(entry.value.toJson());
    }
    for (final entry in _mvRegisters.entries) {
      copy._mvRegisters[entry.key] = MvRegister.fromJson(entry.value.toJson());
    }
    for (final entry in _orSets.entries) {
      copy._orSets[entry.key] = OrSet.fromJson(entry.value.toJson());
    }
    for (final entry in _orMaps.entries) {
      copy._orMaps[entry.key] = OrMap.fromJson(entry.value.toJson());
    }
    return copy;
  }

  /// Replaces this replica with an already committed isolated candidate.
  void adopt(Replica candidate) {
    if (candidate.id != id) throw ArgumentError('Replica ID mismatch');
    _state.replaceWith(candidate._state);
    final copiedCounters = candidate.fork();
    _gCounters
      ..clear()
      ..addAll(copiedCounters._gCounters);
    _pnCounters
      ..clear()
      ..addAll(copiedCounters._pnCounters);
    _gSets
      ..clear()
      ..addAll(copiedCounters._gSets);
    _twoPSets
      ..clear()
      ..addAll(copiedCounters._twoPSets);
    _mvRegisters
      ..clear()
      ..addAll(copiedCounters._mvRegisters);
    _orSets
      ..clear()
      ..addAll(copiedCounters._orSets);
    _orMaps
      ..clear()
      ..addAll(copiedCounters._orMaps);
    _clock = candidate._clock;
    _hlc.restore(candidate.hlcTimestamp);
    _deltaSequence = candidate._deltaSequence;
  }

  /// Compact, versioned materialized state for durable snapshots.
  Map<String, Object?> toSnapshotJson() =>
      copyJsonValue({
            'version': 8,
            'replicaId': id,
            'clock': _clock.toJson(),
            'hlc': _hlc.current.toJson(),
            'deltaSequence': _deltaSequence,
            'lww': _state.toSnapshotJson(),
            'gCounters': {
              for (final entry in _gCounters.entries)
                entry.key: entry.value.toJson(),
            },
            'pnCounters': {
              for (final entry in _pnCounters.entries)
                entry.key: entry.value.toJson(),
            },
            'gSets': {
              for (final entry in _gSets.entries)
                entry.key: entry.value.toJson(),
            },
            'twoPSets': {
              for (final entry in _twoPSets.entries)
                entry.key: entry.value.toJson(),
            },
            'mvRegisters': {
              for (final entry in _mvRegisters.entries)
                entry.key: entry.value.toJson(),
            },
            'orSets': {
              for (final entry in _orSets.entries)
                entry.key: entry.value.toJson(),
            },
            'orMaps': {
              for (final entry in _orMaps.entries)
                entry.key: entry.value.toJson(),
            },
          }, freeze: true)
          as Map<String, Object?>;

  /// Reconstructs materialized state without replaying prior delta history.
  static Replica fromSnapshotJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version != 1 &&
        version != 2 &&
        version != 3 &&
        version != 4 &&
        version != 5 &&
        version != 6 &&
        version != 7 &&
        version != 8) {
      throw FormatException('Unsupported replica snapshot version');
    }
    final replicaId = json['replicaId'];
    final clock = json['clock'];
    final hlc = json['hlc'];
    final lww = json['lww'];
    final gCounters = json['gCounters'];
    final pnCounters = json['pnCounters'];
    final encodedGSets = json['gSets'];
    final gSets =
        encodedGSets ??
        (version == 1 || version == 2 || version == 3
            ? const <String, Object?>{}
            : null);
    final encodedTwoPSets = json['twoPSets'];
    final twoPSets =
        encodedTwoPSets ??
        (version == 1 || version == 2 || version == 3 || version == 4
            ? const <String, Object?>{}
            : null);
    final encodedMvRegisters = json['mvRegisters'];
    final mvRegisters =
        encodedMvRegisters ??
        (version == 6 || version == 7 || version == 8
            ? null
            : const <String, Object?>{});
    final encodedOrSets = json['orSets'];
    final orSets =
        encodedOrSets ??
        (version == 7 || version == 8 ? null : const <String, Object?>{});
    final encodedOrMaps = json['orMaps'];
    final orMaps =
        encodedOrMaps ?? (version == 8 ? null : const <String, Object?>{});
    if (replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        clock is! Map ||
        hlc is! Map ||
        lww is! Map ||
        gCounters is! Map ||
        pnCounters is! Map ||
        gSets is! Map ||
        twoPSets is! Map ||
        mvRegisters is! Map ||
        orSets is! Map ||
        orMaps is! Map) {
      throw FormatException('Invalid replica snapshot');
    }
    final restored = Replica(
      replicaId,
      initialClock: VectorClock.fromJson(Map<String, Object?>.from(clock)),
      hlc: HlcClock(
        initial: HlcTimestamp.fromJson(Map<String, Object?>.from(hlc)),
      ),
    );
    final restoredLwwTimestamp = restored._state.restoreSnapshotJson(
      Map<String, Object?>.from(lww),
    );
    if (restoredLwwTimestamp != null) {
      restored._hlc.restore(restoredLwwTimestamp);
    }
    for (final entry in gCounters.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid G-Counter snapshot');
      }
      final encoded = Map<String, Object?>.from(entry.value as Map);
      if (encoded['crdtId'] != entry.key || encoded['replicaId'] != replicaId) {
        throw FormatException('G-Counter snapshot identity mismatch');
      }
      restored._state.bind(entry.key as String, CrdtKind.gCounter);
      restored._gCounters[entry.key as String] = GCounter(
        replicaId,
        crdtId: entry.key as String,
        components: _intMap(encoded['components']),
        sequences: _optionalIntMap(encoded['sequences']),
        sequence: _requiredSequence(encoded['sequence']),
      );
    }
    for (final entry in pnCounters.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid PN-Counter snapshot');
      }
      final encoded = Map<String, Object?>.from(entry.value as Map);
      if (encoded['crdtId'] != entry.key || encoded['replicaId'] != replicaId) {
        throw FormatException('PN-Counter snapshot identity mismatch');
      }
      restored._state.bind(entry.key as String, CrdtKind.pnCounter);
      restored._pnCounters[entry.key as String] = PnCounter(
        replicaId,
        crdtId: entry.key as String,
        positive: _intMap(encoded['positive']),
        negative: _intMap(encoded['negative']),
        sequences: _optionalIntMap(encoded['sequences']),
        sequence: _requiredSequence(encoded['sequence']),
      );
    }
    for (final entry in gSets.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid G-Set snapshot');
      }
      final encoded = Map<String, Object?>.from(entry.value as Map);
      if (encoded['replicaId'] != replicaId || encoded['crdtId'] != entry.key) {
        throw FormatException('G-Set snapshot identity mismatch');
      }
      final set = GSet.fromJson(encoded);
      if (set.replicaId != replicaId || set.crdtId != entry.key) {
        throw FormatException('G-Set snapshot identity mismatch');
      }
      restored._state.bind(entry.key as String, CrdtKind.gSet);
      restored._gSets[entry.key as String] = set;
    }
    for (final entry in twoPSets.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid 2P-Set snapshot');
      }
      final encoded = Map<String, Object?>.from(entry.value as Map);
      if (encoded['replicaId'] != replicaId || encoded['crdtId'] != entry.key) {
        throw FormatException('2P-Set snapshot identity mismatch');
      }
      final set = TwoPSet.fromJson(encoded);
      if (set.replicaId != replicaId || set.crdtId != entry.key) {
        throw FormatException('2P-Set snapshot identity mismatch');
      }
      restored._state.bind(entry.key as String, CrdtKind.twoPSet);
      restored._twoPSets[entry.key as String] = set;
    }
    for (final entry in mvRegisters.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid MV-Register snapshot');
      }
      final register = MvRegister.fromJson(
        Map<String, Object?>.from(entry.value as Map),
      );
      if (register.replicaId != replicaId || register.crdtId != entry.key) {
        throw FormatException('MV-Register snapshot identity mismatch');
      }
      restored._state.bind(entry.key as String, CrdtKind.mvRegister);
      restored._mvRegisters[entry.key as String] = register;
    }
    for (final entry in orSets.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid OR-Set snapshot');
      }
      final set = OrSet.fromJson(Map<String, Object?>.from(entry.value as Map));
      if (set.replicaId != replicaId || set.crdtId != entry.key) {
        throw FormatException('OR-Set snapshot identity mismatch');
      }
      restored._state.bind(entry.key as String, CrdtKind.orSet);
      restored._orSets[entry.key as String] = set;
    }
    for (final entry in orMaps.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid OR-Map snapshot');
      }
      final map = OrMap.fromJson(Map<String, Object?>.from(entry.value as Map));
      if (map.replicaId != replicaId || map.crdtId != entry.key) {
        throw FormatException('OR-Map snapshot identity mismatch');
      }
      restored._state.bind(entry.key as String, CrdtKind.orMap);
      restored._orMaps[entry.key as String] = map;
    }
    restored._deltaSequence = _requiredSequence(json['deltaSequence']);
    for (final address in restored._state.addresses) {
      final winner = restored._state.winnerAt(address);
      if (winner != null) restored._observeDeltaSequence(winner.id);
    }
    return restored;
  }

  void apply(Delta delta) {
    _validateBatch(delta);
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
          _state.bind(change.crdtId, CrdtKind.gCounter);
          _gCounters
              .putIfAbsent(
                change.crdtId,
                () => GCounter(id, crdtId: change.crdtId),
              )
              .applyDelta(change);
          break;
        case PnCounterDelta():
          _state.bind(change.crdtId, CrdtKind.pnCounter);
          _pnCounters
              .putIfAbsent(
                change.crdtId,
                () => PnCounter(id, crdtId: change.crdtId),
              )
              .applyDelta(change);
          break;
        case GSetDelta():
          _state.bind(change.crdtId, CrdtKind.gSet);
          _gSets
              .putIfAbsent(change.crdtId, () => GSet(id, crdtId: change.crdtId))
              .applyDelta(change);
          break;
        case TwoPSetDelta():
          _state.bind(change.crdtId, CrdtKind.twoPSet);
          _twoPSets
              .putIfAbsent(
                change.crdtId,
                () => TwoPSet(id, crdtId: change.crdtId),
              )
              .applyDelta(change);
          break;
        case MvRegisterDelta():
          _state.bind(change.crdtId, CrdtKind.mvRegister);
          _mvRegisters
              .putIfAbsent(
                change.crdtId,
                () => MvRegister(id, crdtId: change.crdtId),
              )
              .applyDelta(change);
          break;
        case OrSetDelta():
          _state.bind(change.crdtId, CrdtKind.orSet);
          _orSets
              .putIfAbsent(
                change.crdtId,
                () => OrSet(id, crdtId: change.crdtId),
              )
              .applyDelta(change);
          break;
        case OrMapDelta():
          _state.bind(change.crdtId, CrdtKind.orMap);
          _orMaps
              .putIfAbsent(
                change.crdtId,
                () => OrMap(id, crdtId: change.crdtId),
              )
              .applyDelta(change);
          break;
        default:
          throw FormatException('Unsupported CRDT delta type');
      }
      _observeDeltaSequence(change.id);
    }
  }

  /// Exports current winners and cumulative counter components for bootstrap.
  /// It is not a durable operation log or peer-specific ACK history.
  Delta export() => Delta([
    ..._lwwWinners,
    ..._gCounters.values.expand((counter) => counter.exportChanges()),
    ..._pnCounters.values.expand((counter) => counter.exportChanges()),
    ..._gSets.values.expand((set) => set.exportChanges()),
    ..._twoPSets.values.expand((set) => set.exportChanges()),
    ..._mvRegisters.values.expand((register) => register.exportChanges()),
    ..._orSets.values.expand((set) => set.exportChanges()),
    ..._orMaps.values.expand((map) => map.exportChanges()),
  ]);

  /// Compact, versioned materialized state for bootstrap and storage.
  Map<String, Object?> exportSnapshot() => toSnapshotJson();

  /// Joins a peer snapshot without replacing this replica's identity.
  ///
  /// Useful for initial bootstrap when a peer lacks deltas. The merge is
  /// isolated: malformed or conflicting state leaves this replica unchanged.
  void mergeSnapshotJson(Map<String, Object?> json) {
    final remote = Replica.fromSnapshotJson(json);
    final candidate = fork();
    candidate._state.mergeState(remote._state);
    for (final entry in remote._gCounters.entries) {
      final counter = candidate._gCounters.putIfAbsent(
        entry.key,
        () => GCounter(id, crdtId: entry.key),
      );
      counter.mergeState(entry.value);
    }
    for (final entry in remote._pnCounters.entries) {
      final counter = candidate._pnCounters.putIfAbsent(
        entry.key,
        () => PnCounter(id, crdtId: entry.key),
      );
      counter.mergeState(entry.value);
    }
    for (final entry in remote._gSets.entries) {
      final set = candidate._gSets.putIfAbsent(
        entry.key,
        () => GSet(id, crdtId: entry.key),
      );
      set.mergeState(entry.value);
    }
    for (final entry in remote._twoPSets.entries) {
      final set = candidate._twoPSets.putIfAbsent(
        entry.key,
        () => TwoPSet(id, crdtId: entry.key),
      );
      set.mergeState(entry.value);
    }
    for (final entry in remote._mvRegisters.entries) {
      candidate._mvRegisters
          .putIfAbsent(entry.key, () => MvRegister(id, crdtId: entry.key))
          .mergeState(entry.value);
    }
    for (final entry in remote._orSets.entries) {
      candidate._orSets
          .putIfAbsent(entry.key, () => OrSet(id, crdtId: entry.key))
          .mergeState(entry.value);
    }
    for (final entry in remote._orMaps.entries) {
      candidate._orMaps
          .putIfAbsent(entry.key, () => OrMap(id, crdtId: entry.key))
          .mergeState(entry.value);
    }
    candidate
      .._clock = _clock.merge(remote._clock)
      .._hlc.restore(remote.hlcTimestamp);
    if (remote.id == id && remote._deltaSequence > candidate._deltaSequence) {
      candidate._deltaSequence = remote._deltaSequence;
    }
    adopt(candidate);
  }

  /// Creates and applies native LWW delta.
  LwwDelta<Object?> setDelta(String key, Object? value) =>
      _recordDelta(key, value);

  @Deprecated('Use setDelta; returned change is a native LwwDelta.')
  LwwDelta<Object?> set(String key, Object? value) => setDelta(key, value);

  /// Creates and applies native LWW delete tombstone.
  LwwDelta<Object?> removeDelta(String key) =>
      _recordDelta(key, null, deleted: true);

  @Deprecated('Use removeDelta; returned change is a native LwwDelta.')
  LwwDelta<Object?> remove(String key) => removeDelta(key);

  /// Increments G-Counter at stable application-defined [crdtId].
  GCounterDelta incrementGCounter(String crdtId, [int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _ensureLocalAddress(crdtId, CrdtKind.gCounter);
    _state.bind(crdtId, CrdtKind.gCounter);
    final counter = _gCounters.putIfAbsent(
      crdtId,
      () => GCounter(id, crdtId: crdtId),
    );
    final delta = counter.increment(amount);
    return delta;
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
    final existing = _gSets[crdtId];
    if (existing != null) return existing.addAll(elements);
    final created = GSet(id, crdtId: crdtId);
    final delta = created.addAll(elements);
    _state.bind(crdtId, CrdtKind.gSet);
    _gSets[crdtId] = created;
    return delta;
  }

  /// Adds [element] to the addressed 2P-Set and returns its delta.
  TwoPSetDelta addTwoPSet(String crdtId, Object? element) =>
      addAllTwoPSet(crdtId, [element]);

  /// Adds [elements] to the addressed 2P-Set in one delta.
  TwoPSetDelta addAllTwoPSet(String crdtId, Iterable<Object?> elements) {
    _ensureLocalAddress(crdtId, CrdtKind.twoPSet);
    final existing = _twoPSets[crdtId];
    if (existing != null) return existing.addAll(elements);
    final created = TwoPSet(id, crdtId: crdtId);
    final delta = created.addAll(elements);
    _state.bind(crdtId, CrdtKind.twoPSet);
    _twoPSets[crdtId] = created;
    return delta;
  }

  /// Permanently removes [element] from the addressed 2P-Set.
  TwoPSetDelta removeTwoPSet(String crdtId, Object? element) =>
      removeAllTwoPSet(crdtId, [element]);

  /// Permanently removes [elements] from the addressed 2P-Set in one delta.
  TwoPSetDelta removeAllTwoPSet(String crdtId, Iterable<Object?> elements) {
    _ensureLocalAddress(crdtId, CrdtKind.twoPSet);
    final existing = _twoPSets[crdtId];
    if (existing != null) return existing.removeAll(elements);
    final created = TwoPSet(id, crdtId: crdtId);
    final delta = created.removeAll(elements);
    _state.bind(crdtId, CrdtKind.twoPSet);
    _twoPSets[crdtId] = created;
    return delta;
  }

  /// Writes an addressed MV-Register value and returns its causal delta.
  MvRegisterDelta writeMvRegister(String crdtId, Object? value) {
    _validateJsonValue(value);
    _ensureLocalAddress(crdtId, CrdtKind.mvRegister);
    final register = _mvRegisters.putIfAbsent(
      crdtId,
      () => MvRegister(id, crdtId: crdtId),
    );
    _state.bind(crdtId, CrdtKind.mvRegister);
    final delta = register.write(value);
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Adds [element] to the addressed OR-Set with a unique observed-remove tag.
  OrSetDelta addOrSet(String crdtId, Object? element) {
    _validateJsonValue(element);
    _ensureLocalAddress(crdtId, CrdtKind.orSet);
    final set = _orSets.putIfAbsent(crdtId, () => OrSet(id, crdtId: crdtId));
    _state.bind(crdtId, CrdtKind.orSet);
    final delta = set.add(element);
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Removes only OR-Set add tags for [element] already observed locally.
  OrSetDelta removeOrSet(String crdtId, Object? element) {
    _validateJsonValue(element);
    _ensureLocalAddress(crdtId, CrdtKind.orSet);
    final set = _orSets.putIfAbsent(crdtId, () => OrSet(id, crdtId: crdtId));
    _state.bind(crdtId, CrdtKind.orSet);
    final delta = set.remove(element);
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Adds a fresh OR-Map key incarnation with an empty G-Set value.
  OrMapDelta addOrMapKey(String crdtId, String key) {
    _ensureLocalAddress(crdtId, CrdtKind.orMap);
    final map = _orMaps[crdtId] ?? OrMap(id, crdtId: crdtId);
    final delta = map.addKey(key);
    _orMaps[crdtId] = map;
    _state.bind(crdtId, CrdtKind.orMap);
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Removes only observed OR-Map key incarnations.
  OrMapDelta removeOrMapKey(String crdtId, String key) {
    _ensureLocalAddress(crdtId, CrdtKind.orMap);
    final map = _orMaps[crdtId] ?? OrMap(id, crdtId: crdtId);
    final delta = map.removeKey(key);
    _orMaps[crdtId] = map;
    _state.bind(crdtId, CrdtKind.orMap);
    _observeDeltaSequence(delta.id);
    return delta;
  }

  /// Adds value to nested G-Set at each key incarnation observed locally.
  List<OrMapDelta> addOrMapValue(String crdtId, String key, Object? value) {
    _validateJsonValue(value);
    _ensureLocalAddress(crdtId, CrdtKind.orMap);
    final map = _orMaps[crdtId];
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
    if (!deleted) _validateJsonValue(value);
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

  void _validateJsonValue(Object? value) {
    try {
      copyJsonValue(value);
      jsonEncode(
        value,
        toEncodable: (_) => throw UnsupportedError('Not a JSON value'),
      );
    } on JsonUnsupportedObjectError {
      throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
    } on UnsupportedError {
      throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
    }
  }

  PnCounterDelta _changePnCounter(
    String crdtId,
    PnCounterDelta Function(PnCounter) mutate,
    int amount,
  ) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _ensureLocalAddress(crdtId, CrdtKind.pnCounter);
    _state.bind(crdtId, CrdtKind.pnCounter);
    final counter = _pnCounters.putIfAbsent(
      crdtId,
      () => PnCounter(id, crdtId: crdtId),
    );
    final delta = mutate(counter);
    return delta;
  }

  void _validateBatch(Delta delta) {
    // Merge is also the shared check for duplicate IDs with divergent payloads.
    const Delta.empty().merge(delta);
    final retained = <DeltaChange>[
      ..._lwwWinners,
      ..._gCounters.values.expand(
        (counter) => counter.exportChanges(requireSequences: false),
      ),
      ..._pnCounters.values.expand(
        (counter) => counter.exportChanges(requireSequences: false),
      ),
      ..._gSets.values.expand((set) => set.exportChanges()),
      ..._twoPSets.values.expand((set) => set.exportChanges()),
      ..._mvRegisters.values.expand((register) => register.exportChanges()),
      ..._orSets.values.expand((set) => set.exportChanges()),
    ];
    Delta(retained).merge(delta);
    final addressTypes = <String, CrdtKind>{};
    for (final address in _state.addresses) {
      addressTypes[address] = _state.kindAt(address)!;
    }
    for (final address in _gCounters.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.gCounter);
    }
    for (final address in _pnCounters.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.pnCounter);
    }
    for (final address in _gSets.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.gSet);
    }
    for (final address in _twoPSets.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.twoPSet);
    }
    for (final address in _mvRegisters.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.mvRegister);
    }
    for (final address in _orSets.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.orSet);
    }
    for (final address in _orMaps.keys) {
      _validateAddressType(addressTypes, address, CrdtKind.orMap);
    }
    for (final change in delta.changes) {
      if (change is LwwDelta<Object?>) {
        _validateMessageId(change.id, 'delta');
        _validateReplicaId(change.replicaId);
        if (change.key.isEmpty ||
            change.key.trim() != change.key ||
            change.timestamp.physicalMilliseconds < 0 ||
            change.timestamp.logical < 0 ||
            (change.deleted && change.value != null) ||
            (change.dot != null &&
                (change.dot!.counter <= 0 ||
                    change.dot!.replicaId != change.replicaId ||
                    change.dot!.crdtId != null))) {
          throw FormatException('Invalid LWW delta');
        }
        if (!change.deleted) {
          try {
            _validateJsonValue(change.value);
          } on ArgumentError {
            throw FormatException('Invalid LWW delta value');
          }
        }
        _validateAddressType(addressTypes, change.key, CrdtKind.lww);
      } else if (change is GCounterDelta) {
        _validateCounterDelta(
          id: change.id,
          replicaId: change.replicaId,
          crdtId: change.crdtId,
          dot: change.dot,
          type: CrdtKind.gCounter,
          expectedId: counterDeltaId(
            CrdtKind.gCounter.wireName,
            change.crdtId,
            change.replicaId,
            change.dot?.counter ?? 0,
          ),
        );
        if (change.dot == null || change.value < 0) {
          throw FormatException('Invalid G-Counter delta');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.gCounter);
      } else if (change is PnCounterDelta) {
        _validateCounterDelta(
          id: change.id,
          replicaId: change.replicaId,
          crdtId: change.crdtId,
          dot: change.dot,
          type: CrdtKind.pnCounter,
          expectedId: counterDeltaId(
            CrdtKind.pnCounter.wireName,
            change.crdtId,
            change.replicaId,
            change.dot?.counter ?? 0,
          ),
        );
        if (change.dot == null || change.positive < 0 || change.negative < 0) {
          throw FormatException('Invalid PN-Counter delta');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.pnCounter);
      } else if (change is GSetDelta) {
        _validateMessageId(change.id, 'G-Set delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.gSet.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                )) {
          throw FormatException('Invalid G-Set delta identity');
        }
        for (final element in change.elements) {
          try {
            _validateJsonValue(element);
          } on ArgumentError {
            throw FormatException('Invalid G-Set element');
          }
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.gSet);
      } else if (change is TwoPSetDelta) {
        _validateMessageId(change.id, '2P-Set delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.twoPSet.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                )) {
          throw FormatException('Invalid 2P-Set delta identity');
        }
        for (final element in change.elements) {
          try {
            _validateJsonValue(element);
          } on ArgumentError {
            throw FormatException('Invalid 2P-Set element');
          }
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.twoPSet);
      } else if (change is MvRegisterDelta) {
        _validateMessageId(change.id, 'MV-Register delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.mvRegister.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                ) ||
            change.context.any(
              (dot) => dot.crdtId != change.crdtId || dot.counter <= 0,
            )) {
          throw FormatException(
            'Invalid MV-Register delta identity or context',
          );
        }
        try {
          _validateJsonValue(change.value);
        } on ArgumentError {
          throw FormatException('Invalid MV-Register value');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.mvRegister);
      } else if (change is OrSetDelta) {
        _validateMessageId(change.id, 'OR-Set delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.orSet.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                ) ||
            change.observedDots.any(
              (dot) =>
                  dot.replicaId.trim() != dot.replicaId ||
                  dot.counter <= 0 ||
                  dot.crdtId != change.crdtId,
            )) {
          throw FormatException('Invalid OR-Set delta identity or context');
        }
        if (change.action == OrSetAction.add) {
          try {
            _validateJsonValue(change.element);
          } on ArgumentError {
            throw FormatException('Invalid OR-Set element');
          }
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.orSet);
      } else if (change is OrMapDelta) {
        _validateMessageId(change.id, 'OR-Map delta');
        _validateReplicaId(change.replicaId);
        if (change.crdtId.isEmpty ||
            change.crdtId.trim() != change.crdtId ||
            change.crdtId.startsWith('legacy/') ||
            change.dot.counter <= 0 ||
            change.dot.replicaId != change.replicaId ||
            change.dot.crdtId != change.crdtId ||
            change.id !=
                crdtDeltaId(
                  CrdtKind.orMap.wireName,
                  change.crdtId,
                  change.replicaId,
                  change.dot.counter,
                ) ||
            change.observedDots.any(
              (dot) =>
                  dot.replicaId.trim() != dot.replicaId ||
                  dot.counter <= 0 ||
                  dot.crdtId != change.crdtId,
            )) {
          throw FormatException('Invalid OR-Map delta identity or context');
        }
        _validateAddressType(addressTypes, change.crdtId, CrdtKind.orMap);
      } else {
        throw FormatException('Unsupported CRDT delta type');
      }
    }
  }

  Iterable<LwwDelta<Object?>> get _lwwWinners sync* {
    for (final address in _state.addresses) {
      final winner = _state.winnerAt(address);
      if (winner != null) yield winner;
    }
  }

  void _validateCounterDelta({
    required String id,
    required String replicaId,
    required String crdtId,
    required Dot? dot,
    required CrdtKind type,
    required String expectedId,
  }) {
    _validateMessageId(id, 'counter delta');
    _validateReplicaId(replicaId);
    if (crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw FormatException('Invalid CRDT address');
    }
    final legacyAddress =
        dot != null && _isLegacyCounterId(id, replicaId, type, dot);
    if (dot == null ||
        dot.counter <= 0 ||
        dot.replicaId != replicaId ||
        dot.crdtId != crdtId ||
        (crdtId.startsWith('legacy/') && !legacyAddress) ||
        (id != expectedId && !legacyAddress)) {
      throw FormatException('Counter delta identity does not match address');
    }
  }

  bool _isLegacyCounterId(String id, String replicaId, CrdtKind type, Dot dot) {
    return dot.crdtId == 'legacy/${type.wireName}/$replicaId' &&
        id == '$replicaId:${type.wireName}:${dot.counter}';
  }

  void _validateAddressType(
    Map<String, CrdtKind> addressTypes,
    String crdtId,
    CrdtKind type,
  ) {
    final knownType = addressTypes[crdtId];
    if (knownType != null && knownType != type) {
      throw FormatException('CRDT address is already bound to another type');
    }
    addressTypes[crdtId] = type;
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

  void _validateMessageId(String id, String kind) {
    if (id.isEmpty || id.trim() != id) {
      throw FormatException('Invalid $kind ID');
    }
  }

  void _validateReplicaId(String replicaId) {
    if (replicaId.isEmpty || replicaId.trim() != replicaId) {
      throw FormatException('Invalid replica ID');
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

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) throw FormatException('Invalid counter components');
    return value.map((key, item) {
      if (key is! String || item is! int || item < 0) {
        throw FormatException('Invalid counter component');
      }
      return MapEntry(key, item);
    });
  }

  static Map<String, int>? _optionalIntMap(Object? value) =>
      value == null ? null : _intMap(value);

  static int _requiredSequence(Object? value) {
    if (value is! int || value < 0) {
      throw FormatException('Invalid replica sequence');
    }
    return value;
  }
}
