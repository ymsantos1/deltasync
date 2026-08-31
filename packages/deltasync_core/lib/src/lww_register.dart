import 'operation.dart';
import 'operation_crdt.dart';

/// Last-write-wins register with deterministic conflict resolution.
///
/// Causal operations win over older operations. Concurrent operations are
/// ordered by [Operation.compareTo], which uses replica ID and operation ID as
/// deterministic tie-breakers. A delete is retained as a tombstone.
class LwwRegister<T> extends OperationCrdt<T?> {
  Operation? _winner;
  T? _value;

  /// Operation currently winning this register, including a delete.
  Operation? get winner => _winner;

  /// Whether register has received at least one operation.
  bool get hasValue => _winner != null && !isDeleted;

  /// Whether winning operation is a delete tombstone.
  bool get isDeleted => _winner?.type == 'lww.delete';

  @override
  T? get value => _value;

  @override
  void applyOperation(Operation operation) {
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
}
