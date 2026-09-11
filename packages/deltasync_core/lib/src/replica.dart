import 'delta.dart';
import 'operation.dart';
import 'replica_state.dart';
import 'vector_clock.dart';
import 'delta_change.dart';
import 'hlc.dart';
import 'lww_delta.dart';
import 'identity.dart';

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

  VectorClock get clock => _clock;

  HlcTimestamp get hlcTimestamp => _hlc.current;

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
    for (final change in delta.changes) {
      _clock = _clock.merge(change.vectorClock);
      state.apply(change);
      if (!_history.any((item) => item.id == change.id)) {
        _history.add(change);
        _observeOperationSequence(change.id);
      }
    }
    for (final change in delta.crdtChanges) {
      if (change is! LwwDelta<Object?>) {
        throw FormatException('Unsupported CRDT delta type');
      }
      state.applyDelta(change);
      if (change.dot != null) {
        _clock = _clock.merge(
          VectorClock({change.dot!.replicaId: change.dot!.counter}),
        );
      }
      if (!_deltaHistory.any((item) => item.id == change.id)) {
        _deltaHistory.add(change);
        _observeDeltaSequence(change.id);
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
