import 'delta.dart';
import 'operation.dart';
import 'replica_state.dart';
import 'vector_clock.dart';
import 'delta_change.dart';
import 'hlc.dart';
import 'lww_delta.dart';
import 'identity.dart';
import 'g_counter.dart';
import 'pn_counter.dart';

/// Local CRDT replica. Storage and transport stay outside core.
class Replica {
  Replica(String id, {VectorClock? initialClock, HlcClock? hlc})
    : id = ReplicaId(id).value,
      _clock = initialClock ?? VectorClock(),
      _hlc = hlc ?? HlcClock();

  final String id;
  final ReplicaState state = ReplicaState();
  final List<Operation> _history = [];
  final List<DeltaChange> _deltaHistory = [];
  final Map<String, GCounter> _gCounters = {};
  final Map<String, PnCounter> _pnCounters = {};
  VectorClock _clock;
  final HlcClock _hlc;
  int _operationSequence = 0;
  int _deltaSequence = 0;

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

  Operation set(String key, Object? value) => _record(key, value);

  Operation remove(String key) => _record(key, null, deleted: true);

  void apply(Delta delta) {
    _validateBatch(delta);
    for (final change in delta.changes) {
      _clock = _clock.merge(change.vectorClock);
      state.apply(change);
      if (!_history.any((item) => item.id == change.id)) {
        _history.add(change);
        _observeOperationSequence(change.id);
      }
    }
    for (final change in delta.crdtChanges) {
      switch (change) {
        case LwwDelta<Object?>():
          state.applyDelta(change);
          if (change.dot != null) {
            _clock = _clock.merge(
              VectorClock({change.dot!.replicaId: change.dot!.counter}),
            );
          }
          _hlc.observe(change.timestamp);
          break;
        case GCounterDelta():
          _gCounters
              .putIfAbsent(
                change.crdtId,
                () => GCounter(id, crdtId: change.crdtId),
              )
              .applyDelta(change);
          break;
        case PnCounterDelta():
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
      if (!_deltaHistory.any((item) => item.id == change.id)) {
        _deltaHistory.add(change);
        _observeDeltaSequence(change.id);
      }
    }
  }

  Delta export() => Delta(_history).merge(Delta.crdt(_deltaHistory));

  Operation _record(String key, Object? value, {bool deleted = false}) {
    _clock = _clock.tick(id);
    final operation = Operation(
      id: '$id:${++_operationSequence}',
      replicaId: id,
      type: deleted ? 'lww.delete' : 'lww.set',
      vectorClock: _clock,
      payload: {'key': key, if (!deleted) 'value': value},
    );
    _history.add(operation);
    state.apply(operation);
    return operation;
  }

  /// Creates and applies native LWW delta. Legacy [set] remains available.
  LwwDelta<Object?> setDelta(String key, Object? value) =>
      _recordDelta(key, value);

  /// Creates and applies native LWW delete tombstone.
  LwwDelta<Object?> removeDelta(String key) =>
      _recordDelta(key, null, deleted: true);

  /// Increments G-Counter at stable application-defined [crdtId].
  GCounterDelta incrementGCounter(String crdtId, [int amount = 1]) {
    _ensureLocalAddress(crdtId, 'g-counter');
    final counter = _gCounters.putIfAbsent(
      crdtId,
      () => GCounter(id, crdtId: crdtId),
    );
    final delta = counter.increment(amount);
    _deltaHistory.add(delta);
    return delta;
  }

  /// Increments addressed PN-Counter and returns its transportable delta.
  PnCounterDelta incrementPnCounter(String crdtId, [int amount = 1]) =>
      _changePnCounter(crdtId, (counter) => counter.increment(amount));

  /// Decrements addressed PN-Counter and returns its transportable delta.
  PnCounterDelta decrementPnCounter(String crdtId, [int amount = 1]) =>
      _changePnCounter(crdtId, (counter) => counter.decrement(amount));

  LwwDelta<Object?> _recordDelta(
    String key,
    Object? value, {
    bool deleted = false,
  }) {
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
    state.applyDelta(delta);
    _deltaHistory.add(delta);
    return delta;
  }

  PnCounterDelta _changePnCounter(
    String crdtId,
    PnCounterDelta Function(PnCounter) mutate,
  ) {
    _ensureLocalAddress(crdtId, 'pn-counter');
    final counter = _pnCounters.putIfAbsent(
      crdtId,
      () => PnCounter(id, crdtId: crdtId),
    );
    final delta = mutate(counter);
    _deltaHistory.add(delta);
    return delta;
  }

  void _validateBatch(Delta delta) {
    // Merge is also the shared check for duplicate IDs with divergent payloads.
    const Delta.empty().merge(delta);
    Delta(_history).merge(Delta(delta.changes));
    Delta.crdt(_deltaHistory).merge(Delta.crdt(delta.crdtChanges));

    for (final operation in delta.changes) {
      _validateMessageId(operation.id, 'operation');
      _validateReplicaId(operation.replicaId);
      final key = operation.payload['key'];
      if ((operation.type != 'lww.set' && operation.type != 'lww.delete') ||
          key is! String ||
          key.isEmpty ||
          (operation.vectorClock.entries[operation.replicaId] ?? 0) <= 0 ||
          (operation.type == 'lww.set' &&
              !operation.payload.containsKey('value'))) {
        throw FormatException('Invalid LWW operation');
      }
    }

    final addressTypes = <String, String>{};
    for (final address in _gCounters.keys) {
      addressTypes[address] = 'g-counter';
    }
    for (final address in _pnCounters.keys) {
      _validateAddressType(addressTypes, address, 'pn-counter');
    }
    for (final change in delta.crdtChanges) {
      if (change is LwwDelta<Object?>) {
        _validateMessageId(change.id, 'delta');
        _validateReplicaId(change.replicaId);
        if (change.key.isEmpty ||
            (change.dot != null &&
                (change.dot!.replicaId != change.replicaId ||
                    change.dot!.crdtId != null))) {
          throw FormatException('Invalid LWW delta');
        }
      } else if (change is GCounterDelta) {
        _validateCounterDelta(
          id: change.id,
          replicaId: change.replicaId,
          crdtId: change.crdtId,
          dot: change.dot,
          type: 'g-counter',
          expectedId: counterDeltaId(
            'g-counter',
            change.crdtId,
            change.replicaId,
            change.dot?.counter ?? 0,
          ),
        );
        if (change.dot == null || change.value < 0) {
          throw FormatException('Invalid G-Counter delta');
        }
        _validateAddressType(addressTypes, change.crdtId, 'g-counter');
      } else if (change is PnCounterDelta) {
        _validateCounterDelta(
          id: change.id,
          replicaId: change.replicaId,
          crdtId: change.crdtId,
          dot: change.dot,
          type: 'pn-counter',
          expectedId: counterDeltaId(
            'pn-counter',
            change.crdtId,
            change.replicaId,
            change.dot?.counter ?? 0,
          ),
        );
        if (change.dot == null || change.positive < 0 || change.negative < 0) {
          throw FormatException('Invalid PN-Counter delta');
        }
        _validateAddressType(addressTypes, change.crdtId, 'pn-counter');
      } else {
        throw FormatException('Unsupported CRDT delta type');
      }
    }
  }

  void _validateCounterDelta({
    required String id,
    required String replicaId,
    required String crdtId,
    required Dot? dot,
    required String type,
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

  bool _isLegacyCounterId(String id, String replicaId, String type, Dot dot) {
    return dot.crdtId == 'legacy/$type/$replicaId' &&
        id == '$replicaId:$type:${dot.counter}';
  }

  void _validateAddressType(
    Map<String, String> addressTypes,
    String crdtId,
    String type,
  ) {
    final knownType = addressTypes[crdtId];
    if (knownType != null && knownType != type) {
      throw FormatException('CRDT address is already bound to another type');
    }
    addressTypes[crdtId] = type;
  }

  void _ensureLocalAddress(String crdtId, String type) {
    if (crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw ArgumentError.value(crdtId, 'crdtId');
    }
    if (crdtId.startsWith('legacy/')) {
      throw ArgumentError.value(crdtId, 'crdtId', 'legacy/ is reserved');
    }
    final otherType = type == 'g-counter'
        ? _pnCounters.containsKey(crdtId)
        : _gCounters.containsKey(crdtId);
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

  void _observeOperationSequence(String operationId) {
    final prefix = '$id:';
    if (!operationId.startsWith(prefix)) return;
    final sequence = int.tryParse(operationId.substring(prefix.length));
    if (sequence != null && sequence > _operationSequence) {
      _operationSequence = sequence;
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
