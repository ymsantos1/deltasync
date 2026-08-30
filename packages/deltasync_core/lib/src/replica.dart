import 'delta.dart';
import 'operation.dart';
import 'replica_state.dart';
import 'vector_clock.dart';

/// Local CRDT replica. Storage and transport stay outside core.
class Replica {
  Replica(this.id, {VectorClock? initialClock})
    : _clock = initialClock ?? VectorClock();

  final String id;
  final ReplicaState state = ReplicaState();
  final List<Operation> _history = [];
  VectorClock _clock;
  int _operationSequence = 0;

  Operation set(String key, Object? value) => _record(key, value);

  Operation remove(String key) => _record(key, null, deleted: true);

  void apply(Delta delta) {
    for (final change in delta.changes) {
      _clock = _clock.merge(change.vectorClock);
      state.apply(change);
      if (!_history.any((item) => item.id == change.id)) _history.add(change);
    }
  }

  Delta export() => Delta(_history);

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
}
