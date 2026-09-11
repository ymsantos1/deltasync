import 'delta_change.dart';
import 'operation.dart';

/// Batch carrying legacy operations during migration and native CRDT deltas.
class Delta {
  Delta(Iterable<Operation> changes)
    : changes = List.unmodifiable(changes),
      crdtChanges = const [];

  Delta.crdt(Iterable<DeltaChange> changes)
    : changes = const [],
      crdtChanges = List.unmodifiable(changes);

  const Delta.empty() : changes = const [], crdtChanges = const [];

  final List<Operation> changes;
  final List<DeltaChange> crdtChanges;

  bool get isEmpty => changes.isEmpty && crdtChanges.isEmpty;

  Delta merge(Delta other) {
    final byId = <String, Operation>{
      for (final change in changes) change.id: change,
    };
    for (final change in other.changes) {
      byId[change.id] = change;
    }
    final byDeltaId = <String, DeltaChange>{
      for (final change in crdtChanges) change.id: change,
    };
    for (final change in other.crdtChanges) {
      byDeltaId[change.id] = change;
    }
    return Delta._(operations: byId.values, crdtChanges: byDeltaId.values);
  }

  Delta._({
    required Iterable<Operation> operations,
    required Iterable<DeltaChange> crdtChanges,
  }) : changes = List.unmodifiable(operations),
       crdtChanges = List.unmodifiable(crdtChanges);
}
