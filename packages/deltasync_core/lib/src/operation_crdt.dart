import 'crdt.dart';
import 'operation.dart';

/// Base implementation for CRDTs that consume DeltaSync operations.
///
/// The operation envelope carries identity, origin, causal metadata and
/// payload. Concrete CRDTs implement only their merge rule in
/// [applyOperation]. This base class makes duplicate delivery idempotent.
abstract class OperationCrdt<T> implements Crdt<T> {
  final Set<String> _appliedOperationIds = {};

  /// IDs already accepted by this CRDT, useful for snapshot implementations.
  Iterable<String> get appliedOperationIds =>
      List.unmodifiable(_appliedOperationIds);

  /// Whether operation with [operationId] was already accepted.
  bool hasApplied(String operationId) =>
      _appliedOperationIds.contains(operationId);

  @override
  void apply(Operation operation) {
    if (hasApplied(operation.id)) return;

    // Record only after merge succeeds. Invalid operations can be retried
    // after the caller fixes the input or rejects it explicitly.
    applyOperation(operation);
    _appliedOperationIds.add(operation.id);
  }

  /// Applies one operation according to concrete CRDT merge semantics.
  void applyOperation(Operation operation);
}
