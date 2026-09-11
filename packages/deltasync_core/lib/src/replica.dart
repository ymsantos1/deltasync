import 'delta.dart';
import 'operation.dart';
import 'replica_state.dart';
import 'vector_clock.dart';
import 'delta_change.dart';
import 'hlc.dart';
import 'lww_delta.dart';

/// Local CRDT replica. Storage and transport stay outside core.
class Replica {
  Replica(this.id, {VectorClock? initialClock, HlcClock? hlc})
    : _clock = initialClock ?? VectorClock(),
      _hlc = hlc ?? HlcClock();

  final String id;
  final ReplicaState state = ReplicaState();
  final List<Operation> _history = [];
  final List<DeltaChange> _deltaHistory = [];
  VectorClock _clock;
  final HlcClock _hlc;
  int _operationSequence = 0;
  int _deltaSequence = 0;

  Operation set(String key, Object? value) => _record(key, value);

  Operation remove(String key) => _record(key, null, deleted: true);

  void apply(Delta delta) {
    for (final change in delta.changes) {
      _clock = _clock.merge(change.vectorClock);
      state.apply(change);
      if (!_history.any((item) => item.id == change.id)) _history.add(change);
    }
    for (final change in delta.crdtChanges) {
      if (change is! LwwDelta<Object?>) {
        throw FormatException('Unsupported CRDT delta type');
      }
      state.applyDelta(change);
      if (!_deltaHistory.any((item) => item.id == change.id)) {
        _deltaHistory.add(change);
      }
      _hlc.observe(change.timestamp);
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

  LwwDelta<Object?> _recordDelta(
    String key,
    Object? value, {
    bool deleted = false,
  }) {
    final delta = LwwDelta<Object?>(
      key: key,
      id: '$id:delta:${++_deltaSequence}',
      replicaId: id,
      timestamp: _hlc.tick(),
      value: value,
      deleted: deleted,
    );
    state.applyDelta(delta);
    _deltaHistory.add(delta);
    return delta;
  }
}
