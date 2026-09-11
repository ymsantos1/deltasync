import 'delta_change.dart';
import 'lww_delta.dart';
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

  Map<String, Object?> toJson() => {
    'operations': [for (final change in changes) change.toJson()],
    'crdtChanges': [for (final change in crdtChanges) change.toJson()],
  };

  factory Delta.fromJson(Map<String, Object?> json) {
    final operations = json['operations'];
    final nativeChanges = json['crdtChanges'];
    if (operations is! List || nativeChanges is! List) {
      throw FormatException('Invalid delta');
    }
    final parsedOperations = operations.map((item) {
      if (item is! Map) throw FormatException('Invalid operation');
      return Operation.fromJson(Map<String, Object?>.from(item));
    });
    final parsedNative = nativeChanges.map((item) {
      if (item is! Map) throw FormatException('Invalid CRDT delta');
      final value = Map<String, Object?>.from(item);
      if (value['type'] != 'lww') {
        throw FormatException('Unsupported CRDT delta');
      }
      return LwwDelta<Object?>.fromJson(value);
    });
    return Delta._(operations: parsedOperations, crdtChanges: parsedNative);
  }

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
