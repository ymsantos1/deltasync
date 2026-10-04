import 'crdt.dart';
import 'lww_delta.dart';
import 'json_value.dart';

/// Last-write-wins register with one native HLC winner and retained tombstone.
class LwwRegister<T> implements DeltaCrdt<T?, LwwDelta<T>> {
  LwwDelta<T>? _winner;

  bool get hasValue => _winner != null && !_winner!.deleted;

  bool get isDeleted => _winner?.deleted ?? false;

  @override
  T? get value => hasValue ? copyJsonValue(_winner!.value) as T? : null;

  LwwDelta<T>? get winner {
    final winner = _winner;
    if (winner == null) return null;
    return LwwDelta<T>(
      key: winner.key,
      id: winner.id,
      replicaId: winner.replicaId,
      timestamp: winner.timestamp,
      value: winner.deleted ? null : copyJsonValue(winner.value) as T?,
      deleted: winner.deleted,
      dot: winner.dot,
    );
  }

  @override
  void applyDelta(LwwDelta<T> delta) {
    if (delta.key.isEmpty || delta.key.trim() != delta.key) {
      throw FormatException('Invalid LWW address');
    }
    if (delta.id.isEmpty || delta.id.trim() != delta.id) {
      throw FormatException('Invalid LWW delta ID');
    }
    if (delta.replicaId.isEmpty || delta.replicaId.trim() != delta.replicaId) {
      throw FormatException('Invalid LWW replica ID');
    }
    final dot = delta.dot;
    if (dot != null &&
        (dot.counter <= 0 ||
            dot.replicaId != delta.replicaId ||
            dot.crdtId != null)) {
      throw FormatException('Delta dot identity does not match LWW change');
    }
    final current = _winner;
    if (current != null && _compare(delta, current) <= 0) return;
    _winner = LwwDelta<T>(
      key: delta.key,
      id: delta.id,
      replicaId: delta.replicaId,
      timestamp: delta.timestamp,
      value: delta.deleted ? null : copyJsonValue(delta.value) as T?,
      deleted: delta.deleted,
      dot: delta.dot,
    );
  }

  @override
  void mergeState(covariant LwwRegister<T> other) {
    final winner = other._winner;
    if (winner != null) applyDelta(winner);
  }

  @override
  Map<String, Object?> toJson() => {
    if (winner case final winner?) 'winner': winner.toJson(),
  };

  int _compare(LwwDelta<T> first, LwwDelta<T> second) {
    final timestamp = first.timestamp.compareTo(second.timestamp);
    if (timestamp != 0) return timestamp;
    final replica = first.replicaId.compareTo(second.replicaId);
    return replica == 0 ? first.id.compareTo(second.id) : replica;
  }
}
