import 'dart:convert';

import 'delta.dart';
import 'replica_state.dart';
import 'vector_clock.dart';
import 'delta_change.dart';
import 'hlc.dart';
import 'lww_delta.dart';
import 'identity.dart';
import 'g_counter.dart';
import 'pn_counter.dart';
import 'json_value.dart';

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
    _clock = candidate._clock;
    _hlc.restore(candidate.hlcTimestamp);
    _deltaSequence = candidate._deltaSequence;
  }

  /// Compact, versioned materialized state for durable snapshots.
  Map<String, Object?> toSnapshotJson() =>
      copyJsonValue({
            'version': 3,
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
          }, freeze: true)
          as Map<String, Object?>;

  /// Reconstructs materialized state without replaying prior delta history.
  static Replica fromSnapshotJson(Map<String, Object?> json) {
    if (json['version'] != 1 && json['version'] != 2 && json['version'] != 3) {
      throw FormatException('Unsupported replica snapshot version');
    }
    final replicaId = json['replicaId'];
    final clock = json['clock'];
    final hlc = json['hlc'];
    final lww = json['lww'];
    final gCounters = json['gCounters'];
    final pnCounters = json['pnCounters'];
    if (replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        clock is! Map ||
        hlc is! Map ||
        lww is! Map ||
        gCounters is! Map ||
        pnCounters is! Map) {
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
        sequence: _requiredSequence(encoded['sequence']),
      );
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
      value: value,
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
    final otherType =
        _state.kindAt(crdtId) == CrdtKind.lww ||
        (type == CrdtKind.gCounter
            ? _pnCounters.containsKey(crdtId)
            : _gCounters.containsKey(crdtId));
    if (otherType) {
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
