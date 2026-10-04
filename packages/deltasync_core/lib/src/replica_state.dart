import 'lww_register.dart';
import 'lww_delta.dart';
import 'operation.dart';
import 'hlc.dart';

/// Materialized state produced by applying changes in any order.
class ReplicaState {
  ReplicaState() : _entries = {};

  ReplicaState._(Map<String, LwwRegister<Object?>> entries)
    : _entries = {
        for (final entry in entries.entries)
          entry.key: LwwRegister<Object?>()..mergeState(entry.value),
      };

  final Map<String, LwwRegister<Object?>> _entries;

  Set<String> get addresses => Set.unmodifiable(_entries.keys);

  Map<String, Object?> get values => {
    for (final entry in _entries.entries)
      if (entry.value.hasValue) entry.key: entry.value.value,
  };

  Object? operator [](String key) => values[key];

  void applyDelta(LwwDelta<Object?> delta) {
    final register = _entries.putIfAbsent(delta.key, LwwRegister<Object?>.new);
    register.applyDelta(delta);
  }

  ReplicaState copy() => ReplicaState._(_entries);

  /// Encodes each native winning register, including tombstones.
  Map<String, Object?> toSnapshotJson() => {
    for (final entry in _entries.entries) entry.key: entry.value.toJson(),
  };

  HlcTimestamp? restoreSnapshotJson(Map<String, Object?> json) {
    HlcTimestamp? latestTimestamp;
    for (final entry in json.entries) {
      if (entry.value is! Map) throw FormatException('Invalid LWW snapshot');
      final encoded = Map<String, Object?>.from(entry.value as Map);
      final native = encoded['winner'];
      final legacy = encoded['legacyWinner'];
      if (native is Map) {
        final delta = LwwDelta<Object?>.fromJson(
          Map<String, Object?>.from(native),
        );
        if (delta.key != entry.key) {
          throw FormatException('LWW snapshot address mismatch');
        }
        applyDelta(delta);
        if (latestTimestamp == null ||
            delta.timestamp.compareTo(latestTimestamp) > 0) {
          latestTimestamp = delta.timestamp;
        }
      } else if (legacy is Map) {
        final delta = migrateLegacyOperation(
          Operation.fromJson(Map<String, Object?>.from(legacy)),
        );
        if (delta.key != entry.key) {
          throw FormatException('LWW snapshot address mismatch');
        }
        applyDelta(delta);
        if (latestTimestamp == null ||
            delta.timestamp.compareTo(latestTimestamp) > 0) {
          latestTimestamp = delta.timestamp;
        }
      } else {
        throw FormatException('Invalid LWW snapshot winner');
      }
    }
    return latestTimestamp;
  }

  void replaceWith(ReplicaState other) {
    _entries
      ..clear()
      ..addAll(other.copy()._entries);
  }
}
