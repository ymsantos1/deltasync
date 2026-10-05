import 'delta_change.dart';
import 'g_counter.dart';
import 'g_set.dart';
import 'lww_delta.dart';
import 'operation.dart';
import 'pn_counter.dart';
import 'two_p_set.dart';

/// Immutable batch of native CRDT changes.
class Delta {
  Delta(Iterable<DeltaChange> changes) : changes = List.unmodifiable(changes);

  @Deprecated('Use Delta(changes) for native changes.')
  Delta.crdt(Iterable<DeltaChange> changes) : this(changes);

  const Delta.empty() : changes = const [];

  final List<DeltaChange> changes;

  @Deprecated('Delta.changes now contains native CRDT changes.')
  List<DeltaChange> get crdtChanges => changes;

  bool get isEmpty => changes.isEmpty;

  Map<String, Object?> toJson() => {
    'changes': [for (final change in changes) change.toJson()],
  };

  /// Decodes native batches and migrates historical operation batches when
  /// explicitly enabled by a versioned codec.
  factory Delta.fromJson(
    Map<String, Object?> json, {
    bool allowLegacyOperations = false,
    bool allowLegacyCounterIdentity = false,
  }) {
    final encodedChanges = json['changes'];
    final encodedOperations = json['operations'];
    final encodedNativeChanges = json['crdtChanges'];
    if (encodedChanges is List) {
      if (allowLegacyOperations) {
        throw FormatException('Native delta is invalid in legacy format');
      }
      return Delta(
        encodedChanges.map(_decodeChange),
      ).merge(const Delta.empty());
    }
    if (!allowLegacyOperations ||
        encodedOperations is! List ||
        encodedNativeChanges is! List) {
      throw FormatException('Invalid delta');
    }
    final migrated = <DeltaChange>[
      for (final item in encodedOperations)
        migrateLegacyOperation(_decodeOperation(item)),
      for (final item in encodedNativeChanges)
        _decodeChange(
          item,
          allowLegacyCounterIdentity: allowLegacyCounterIdentity,
        ),
    ];
    return Delta(migrated).merge(const Delta.empty());
  }

  Delta merge(Delta other) {
    final byId = <String, DeltaChange>{};
    for (final change in [...changes, ...other.changes]) {
      final current = byId[change.id];
      if (current != null &&
          !_deepJsonEquals(current.toJson(), change.toJson())) {
        throw FormatException('Conflicting CRDT delta ID: ${change.id}');
      }
      byId[change.id] = change;
    }
    return Delta(byId.values);
  }
}

DeltaChange _decodeChange(
  Object? item, {
  bool allowLegacyCounterIdentity = false,
}) {
  if (item is! Map) throw FormatException('Invalid CRDT delta');
  final value = Map<String, Object?>.from(item);
  final encodedKind = value['type'];
  if (encodedKind is! String) {
    throw FormatException('Invalid CRDT delta type');
  }
  return switch (CrdtKind.fromWire(encodedKind)) {
    CrdtKind.lww => LwwDelta<Object?>.fromJson(value),
    CrdtKind.gCounter => GCounterDelta.fromJson(
      value,
      allowLegacyIdentity: allowLegacyCounterIdentity,
    ),
    CrdtKind.pnCounter => PnCounterDelta.fromJson(
      value,
      allowLegacyIdentity: allowLegacyCounterIdentity,
    ),
    CrdtKind.gSet => GSetDelta.fromJson(value),
    CrdtKind.twoPSet => TwoPSetDelta.fromJson(value),
  };
}

Operation _decodeOperation(Object? item) {
  if (item is! Map) throw FormatException('Invalid legacy operation');
  return Operation.fromJson(Map<String, Object?>.from(item));
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
