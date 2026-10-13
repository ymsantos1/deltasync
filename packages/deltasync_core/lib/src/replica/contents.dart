import '../crdt.dart';
import '../delta_change.dart';
import '../g_counter.dart';
import '../g_set.dart';
import '../lww_delta.dart';
import '../mv_register.dart';
import '../or_map.dart';
import '../or_set.dart';
import '../pn_counter.dart';
import '../replica_state.dart';
import '../two_p_set.dart';

/// Internal owner of addressed CRDT instances. Not exported by the facade.
///
/// Tables share storage/copy/restore mechanics; each CRDT still owns its join.
/// There is no registration API: the eight supported kinds remain explicit.
class ReplicaContents {
  ReplicaContents(this.replicaId);

  final String replicaId;
  final ReplicaState state = ReplicaState();

  late final gCounters = CrdtTable<int, GCounterDelta, GCounter>(
    state,
    replicaId,
    CrdtKind.gCounter,
    'gCounters',
    'G-Counter',
    1,
    (address) => GCounter(replicaId, crdtId: address),
    (json, _) => GCounter(
      replicaId,
      crdtId: json['crdtId'] as String,
      components: _intMap(json['components']),
      sequences: _optionalIntMap(json['sequences']),
      sequence: readReplicaSequence(json['sequence']),
    ),
    (counter, validation) =>
        counter.exportChanges(requireSequences: !validation),
  );
  late final pnCounters = CrdtTable<int, PnCounterDelta, PnCounter>(
    state,
    replicaId,
    CrdtKind.pnCounter,
    'pnCounters',
    'PN-Counter',
    1,
    (address) => PnCounter(replicaId, crdtId: address),
    (json, _) => PnCounter(
      replicaId,
      crdtId: json['crdtId'] as String,
      positive: _intMap(json['positive']),
      negative: _intMap(json['negative']),
      sequences: _optionalIntMap(json['sequences']),
      sequence: readReplicaSequence(json['sequence']),
    ),
    (counter, validation) =>
        counter.exportChanges(requireSequences: !validation),
  );
  late final gSets = CrdtTable<Set<Object?>, GSetDelta, GSet>(
    state,
    replicaId,
    CrdtKind.gSet,
    'gSets',
    'G-Set',
    4,
    (address) => GSet(replicaId, crdtId: address),
    (json, _) => GSet.fromJson(json),
    (set, _) => set.exportChanges(),
  );
  late final twoPSets = CrdtTable<Set<Object?>, TwoPSetDelta, TwoPSet>(
    state,
    replicaId,
    CrdtKind.twoPSet,
    'twoPSets',
    '2P-Set',
    5,
    (address) => TwoPSet(replicaId, crdtId: address),
    (json, _) => TwoPSet.fromJson(json),
    (set, _) => set.exportChanges(),
  );
  late final mvRegisters = CrdtTable<Set<Object?>, MvRegisterDelta, MvRegister>(
    state,
    replicaId,
    CrdtKind.mvRegister,
    'mvRegisters',
    'MV-Register',
    6,
    (address) => MvRegister(replicaId, crdtId: address),
    (json, compact) => MvRegister.fromJson(json, allowCompactContext: compact),
    (register, _) => register.exportChanges(),
  );
  late final orSets = CrdtTable<Set<Object?>, OrSetDelta, OrSet>(
    state,
    replicaId,
    CrdtKind.orSet,
    'orSets',
    'OR-Set',
    7,
    (address) => OrSet(replicaId, crdtId: address),
    (json, _) => OrSet.fromJson(json),
    (set, _) => set.exportChanges(),
  );
  late final orMaps = CrdtTable<Map<String, Set<Object?>>, OrMapDelta, OrMap>(
    state,
    replicaId,
    CrdtKind.orMap,
    'orMaps',
    'OR-Map',
    8,
    (address) => OrMap(replicaId, crdtId: address),
    (json, _) => OrMap.fromJson(json),
    (map, _) => map.exportChanges(),
  );

  late final List<_CrdtTable> _tables = [
    gCounters,
    pnCounters,
    gSets,
    twoPSets,
    mvRegisters,
    orSets,
    orMaps,
  ];

  Iterable<LwwDelta<Object?>> get lwwWinners sync* {
    for (final address in state.addresses) {
      final winner = state.winnerAt(address);
      if (winner != null) yield winner;
    }
  }

  Map<String, CrdtKind> get addressTypes => {
    for (final address in state.addresses) address: state.kindAt(address)!,
  };

  Iterable<DeltaChange> exportChanges({bool forValidation = false}) sync* {
    yield* lwwWinners;
    for (final table in _tables) {
      // OR-Map retains context beyond its exported active changes. Preserve
      // the existing batch-validation boundary; its own join checks conflicts.
      if (forValidation && table.kind == CrdtKind.orMap) continue;
      yield* table.exportChanges(forValidation);
    }
  }

  ReplicaContents copy() {
    final copy = ReplicaContents(replicaId)..state.replaceWith(state);
    for (var i = 0; i < _tables.length; i++) {
      copy._tables[i].restore(_tables[i].toJson(), allowCompactContext: true);
    }
    return copy;
  }

  void merge(ReplicaContents remote) {
    state.mergeState(remote.state);
    for (var i = 0; i < _tables.length; i++) {
      _tables[i].mergeFrom(remote._tables[i]);
    }
  }

  Map<String, Object?> toSnapshotJson() => {
    'lww': state.toSnapshotJson(),
    for (final table in _tables) table.snapshotKey: table.toJson(),
  };

  void restoreTables(
    Map<String, Object?> json,
    int version, {
    required bool allowCompactContext,
  }) {
    for (final table in _tables) {
      table.restore(
        _snapshotTable(json, table, version),
        allowCompactContext: allowCompactContext,
      );
    }
  }

  /// Validate all sections before adopting any state, including legacy absence.
  void validateSnapshotTables(Map<String, Object?> json, int version) {
    for (final table in _tables) {
      _snapshotTable(json, table, version);
    }
  }

  Map _snapshotTable(Map<String, Object?> json, _CrdtTable table, int version) {
    final encoded =
        json[table.snapshotKey] ??
        (version < table.introducedInVersion
            ? const <String, Object?>{}
            : null);
    if (encoded is! Map) throw FormatException('Invalid replica snapshot');
    return encoded;
  }
}

abstract class _CrdtTable {
  _CrdtTable(this.kind, this.snapshotKey, this.label, this.introducedInVersion);
  final CrdtKind kind;
  final String snapshotKey;
  final String label;
  final int introducedInVersion;
  Map<String, Object?> toJson();
  void restore(Map json, {required bool allowCompactContext});
  void mergeFrom(covariant _CrdtTable remote);
  Iterable<DeltaChange> exportChanges(bool forValidation);
}

/// Typed table shared by the seven non-LWW kinds. Mutable instances never leave
/// the owning replica's working state; callers expose detached values instead.
class CrdtTable<V, D extends DeltaChange, C extends DeltaCrdt<V, D>>
    extends _CrdtTable {
  CrdtTable(
    this._state,
    this._replicaId,
    super.kind,
    super.snapshotKey,
    super.label,
    super.introducedInVersion,
    this._create,
    this._decode,
    this._export,
  );

  final ReplicaState _state;
  final String _replicaId;
  final C Function(String) _create;
  final C Function(Map<String, Object?>, bool) _decode;
  final Iterable<D> Function(C, bool) _export;
  final Map<String, C> _instances = {};

  C? operator [](String address) => _instances[address];

  /// Store a new address only after its mutation succeeds. Empty batches and
  /// invalid model keys must not bind a previously unused address.
  R mutate<R>(String address, R Function(C) action) {
    final instance = _instances[address] ?? _create(address);
    final result = action(instance);
    _state.bind(address, kind);
    _instances[address] = instance;
    return result;
  }

  void apply(D delta) =>
      mutate(delta.crdtId, (instance) => instance.applyDelta(delta));

  @override
  Iterable<D> exportChanges(bool forValidation) sync* {
    for (final instance in _instances.values) {
      yield* _export(instance, forValidation);
    }
  }

  @override
  Map<String, Object?> toJson() => {
    for (final entry in _instances.entries) entry.key: entry.value.toJson(),
  };

  @override
  void restore(Map json, {required bool allowCompactContext}) {
    for (final entry in json.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw FormatException('Invalid $label snapshot');
      }
      final encoded = Map<String, Object?>.from(entry.value as Map);
      if (encoded['crdtId'] != entry.key ||
          encoded['replicaId'] != _replicaId) {
        throw FormatException('$label snapshot identity mismatch');
      }
      final instance = _decode(encoded, allowCompactContext);
      _state.bind(entry.key as String, kind);
      _instances[entry.key as String] = instance;
    }
  }

  @override
  void mergeFrom(CrdtTable<V, D, C> remote) {
    for (final entry in remote._instances.entries) {
      mutate(entry.key, (instance) => instance.mergeState(entry.value));
    }
  }
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) throw FormatException('Invalid counter components');
  return value.map((key, item) {
    if (key is! String || item is! int || item < 0) {
      throw FormatException('Invalid counter component');
    }
    return MapEntry(key, item);
  });
}

Map<String, int>? _optionalIntMap(Object? value) =>
    value == null ? null : _intMap(value);
int readReplicaSequence(Object? value) {
  if (value is! int || value < 0) {
    throw FormatException('Invalid replica sequence');
  }
  return value;
}
