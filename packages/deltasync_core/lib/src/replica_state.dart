import 'lww_register.dart';
import 'lww_delta.dart';
import 'operation.dart';

/// Materialized state produced by applying changes in any order.
class ReplicaState {
  ReplicaState() : _entries = {};

  ReplicaState._(Map<String, LwwRegister<Object?>> entries)
    : _entries = {
        for (final entry in entries.entries)
          entry.key: LwwRegister<Object?>()..mergeState(entry.value),
      };

  final Map<String, LwwRegister<Object?>> _entries;

  Map<String, Object?> get values => {
    for (final entry in _entries.entries)
      if (entry.value.hasValue) entry.key: entry.value.value,
  };

  Object? operator [](String key) => values[key];

  void apply(Operation operation) {
    if (!operation.type.startsWith('lww.')) return;
    final key = operation.payload['key'];
    if (key is! String) {
      throw FormatException('LWW operation requires string key');
    }
    final register = _entries.putIfAbsent(key, LwwRegister<Object?>.new);
    register.apply(operation);
  }

  void applyDelta(LwwDelta<Object?> delta) {
    final register = _entries.putIfAbsent(delta.key, LwwRegister<Object?>.new);
    register.applyDelta(delta);
  }

  ReplicaState copy() => ReplicaState._(_entries);

  /// Encodes each winning register, including legacy winners and tombstones.
  Map<String, Object?> toSnapshotJson() => {
    for (final entry in _entries.entries) entry.key: entry.value.toJson(),
  };

  void restoreSnapshotJson(Map<String, Object?> json) {
    for (final entry in json.entries) {
      if (entry.value is! Map) throw FormatException('Invalid LWW snapshot');
      final encoded = Map<String, Object?>.from(entry.value as Map);
      final native = encoded['winner'];
      final legacy = encoded['legacyWinner'];
      if (native is Map) {
        applyDelta(
          LwwDelta<Object?>.fromJson(Map<String, Object?>.from(native)),
        );
      } else if (legacy is Map) {
        apply(Operation.fromJson(Map<String, Object?>.from(legacy)));
      } else {
        throw FormatException('Invalid LWW snapshot winner');
      }
    }
  }

  void replaceWith(ReplicaState other) {
    _entries
      ..clear()
      ..addAll(other.copy()._entries);
  }
}
