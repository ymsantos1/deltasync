import 'delta_change.dart';
import 'g_counter.dart';
import 'lww_delta.dart';
import 'operation.dart';
import 'pn_counter.dart';

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

  /// Decodes a batch. Missing counter addresses map to legacy single-counter
  /// namespaces by default; versioned codecs control this migration explicitly.
  factory Delta.fromJson(
    Map<String, Object?> json, {
    bool allowLegacyCounterIdentity = true,
  }) {
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
      return switch (value['type']) {
        'lww' => LwwDelta<Object?>.fromJson(value),
        'g-counter' => GCounterDelta.fromJson(
          value,
          allowLegacyIdentity: allowLegacyCounterIdentity,
        ),
        'pn-counter' => PnCounterDelta.fromJson(
          value,
          allowLegacyIdentity: allowLegacyCounterIdentity,
        ),
        _ => throw FormatException('Unsupported CRDT delta'),
      };
    });
    return Delta._(
      operations: parsedOperations,
      crdtChanges: parsedNative,
    ).merge(const Delta.empty());
  }

  Delta merge(Delta other) {
    final byId = <String, Operation>{};
    for (final change in [...changes, ...other.changes]) {
      final current = byId[change.id];
      if (current != null &&
          !_deepJsonEquals(current.toJson(), change.toJson())) {
        throw FormatException('Conflicting operation ID: ${change.id}');
      }
      byId[change.id] = change;
    }
    final byDeltaId = <String, DeltaChange>{};
    for (final change in [...crdtChanges, ...other.crdtChanges]) {
      final current = byDeltaId[change.id];
      if (current != null &&
          !_deepJsonEquals(current.toJson(), change.toJson())) {
        throw FormatException('Conflicting CRDT delta ID: ${change.id}');
      }
      byDeltaId[change.id] = change;
    }
    final crossKindIds = byId.keys.toSet().intersection(byDeltaId.keys.toSet());
    if (crossKindIds.isNotEmpty) {
      throw FormatException(
        'Change ID used by operation and CRDT delta: ${crossKindIds.first}',
      );
    }
    return Delta._(operations: byId.values, crdtChanges: byDeltaId.values);
  }

  Delta._({
    required Iterable<Operation> operations,
    required Iterable<DeltaChange> crdtChanges,
  }) : changes = List.unmodifiable(operations),
       crdtChanges = List.unmodifiable(crdtChanges);
}

bool _deepJsonEquals(Object? first, Object? second) {
  if (first is Map && second is Map) {
    if (first.length != second.length) return false;
    for (final key in first.keys) {
      if (!second.containsKey(key) ||
          !_deepJsonEquals(first[key], second[key])) {
        return false;
      }
    }
    return true;
  }
  if (first is List && second is List) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (!_deepJsonEquals(first[index], second[index])) return false;
    }
    return true;
  }
  return first == second;
}
