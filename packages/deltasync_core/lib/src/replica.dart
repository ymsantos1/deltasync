import 'change.dart';
import 'delta.dart';
import 'replica_state.dart';

/// Local CRDT replica. Storage and transport stay outside core.
class Replica {
  Replica(this.id, {int initialTimestamp = 0}) : _clock = initialTimestamp;

  final String id;
  final ReplicaState state = ReplicaState();
  final List<Change> _history = [];
  int _clock;

  Change set(String key, Object? value) => _record(key, value);

  Change remove(String key) => _record(key, null, deleted: true);

  void apply(Delta delta) {
    for (final change in delta.changes) {
      _clock = _clock < change.timestamp ? change.timestamp : _clock;
      state.apply(change);
      if (!_history.any((item) => item.id == change.id)) _history.add(change);
    }
  }

  Delta export() => Delta(_history);

  Change _record(String key, Object? value, {bool deleted = false}) {
    final change = Change(
      id: '$id:${++_clock}',
      replicaId: id,
      key: key,
      value: value,
      timestamp: _clock,
      deleted: deleted,
    );
    _history.add(change);
    state.apply(change);
    return change;
  }
}
