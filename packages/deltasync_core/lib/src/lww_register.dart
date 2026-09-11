import 'crdt.dart';
import 'lww_delta.dart';
import 'operation.dart';
import 'operation_crdt.dart';

/// Last-write-wins register with deterministic conflict resolution.
///
/// Causal operations win over older operations. Concurrent operations are
/// ordered by [Operation.compareTo], which uses replica ID and operation ID as
/// deterministic tie-breakers. A delete is retained as a tombstone.
class LwwRegister<T> extends OperationCrdt<T?>
    implements DeltaCrdt<T?, LwwDelta<T>> {
  Operation? _winner;
  T? _value;
  LwwDelta<T>? _deltaWinner;

  /// Legacy operation currently winning this register, including a delete.
  ///
  /// Native delta state takes precedence while both representations coexist.
  Operation? get winner => _winner;

  /// Whether register has received at least one operation.
  bool get hasValue =>
      _deltaWinner == null ? _winner != null && !isDeleted : !isDeleted;

  /// Whether winning operation is a delete tombstone.
  bool get isDeleted => _deltaWinner == null
      ? _winner?.type == 'lww.delete'
      : _deltaWinner!.deleted;

  @override
  T? get value => _deltaWinner == null || !_deltaWinner!.deleted
      ? (_deltaWinner == null ? _value : _deltaWinner!.value)
      : null;

  @override
  void applyOperation(Operation operation) {
    // Native deltas are the new canonical representation. Once present,
    // legacy operations cannot overwrite them with a different ordering
    // model (VectorClock versus HLC).
    if (_deltaWinner != null) return;
    if (operation.type != 'lww.set' && operation.type != 'lww.delete') {
      throw FormatException('Unsupported LWW operation type');
    }
    if (operation.type == 'lww.set' &&
        !operation.payload.containsKey('value')) {
      throw FormatException('LWW set operation requires value');
    }

    final current = _winner;
    if (current != null && operation.compareTo(current) <= 0) return;

    _winner = operation;
    _value = operation.type == 'lww.set'
        ? operation.payload['value'] as T?
        : null;
  }

  @override
  void applyDelta(LwwDelta<T> delta) {
    if (delta.dot != null && delta.dot!.replicaId != delta.replicaId) {
      throw FormatException('Delta dot replica does not match origin');
    }
    final current = _deltaWinner;
    if (current != null && _compareDelta(delta, current) <= 0) return;
    _deltaWinner = delta;
  }

  @override
  void mergeState(covariant LwwRegister<T> other) {
    final delta = other._deltaWinner;
    if (delta != null) {
      applyDelta(delta);
    } else if (other._winner != null) {
      applyOperation(other._winner!);
    }
  }

  @override
  Map<String, Object?> toJson() {
    final winner = _deltaWinner;
    if (winner != null) return {'winner': winner.toJson()};
    final operation = _winner;
    if (operation != null) return {'legacyWinner': operation.toJson()};
    return const {};
  }

  int _compareDelta(LwwDelta<T> first, LwwDelta<T> second) {
    final timestamp = first.timestamp.compareTo(second.timestamp);
    if (timestamp != 0) return timestamp;
    final replica = first.replicaId.compareTo(second.replicaId);
    return replica == 0 ? first.id.compareTo(second.id) : replica;
  }
}
