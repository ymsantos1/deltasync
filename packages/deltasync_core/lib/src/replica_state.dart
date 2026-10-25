import 'lww_register.dart';
import 'lww_delta.dart';
import 'operation.dart';
import 'hlc.dart';
import 'delta_change.dart';
import 'json_value.dart';

/// Materialized state produced by applying changes in any order.
class ReplicaState {
  ReplicaState() : _entries = {}, _addressKinds = {};

  ReplicaState._(
    Map<String, LwwRegister<Object?>> entries,
    Map<String, CrdtKind> addressKinds,
  ) : _entries = {
        for (final entry in entries.entries)
          entry.key: LwwRegister<Object?>()..mergeState(entry.value),
      },
      _addressKinds = Map.of(addressKinds);

  final Map<String, LwwRegister<Object?>> _entries;
  final Map<String, CrdtKind> _addressKinds;

  Set<String> get addresses => Set.unmodifiable(_addressKinds.keys);

  Map<String, Object?> get values => {
    for (final entry in _entries.entries)
      if (entry.value.hasValue)
        entry.key: copyJsonValue(entry.value.value, freeze: true),
  };

  Object? operator [](String key) {
    final register = _entries[key];
    if (register == null || !register.hasValue) return null;
    return copyJsonValue(register.value, freeze: true);
  }

  void applyDelta(LwwDelta<Object?> delta) {
    final kind = _addressKinds[delta.key];
    if (kind != null && kind != CrdtKind.lww) {
      throw FormatException('CRDT address is already bound to another type');
    }
    final register = LwwRegister<Object?>();
    final existing = _entries[delta.key];
    if (existing != null) register.mergeState(existing);
    register.applyDelta(delta);
    _entries[delta.key] = register;
    _addressKinds[delta.key] = CrdtKind.lww;
  }

  ReplicaState copy() => ReplicaState._(_entries, _addressKinds);

  CrdtKind? kindAt(String address) => _addressKinds[address];

  /// True only for a retained LWW tombstone; reads no value or delta payload.
  /// For presence and values across all kinds, use Replica.query.
  bool isDeletedAt(String address) => _entries[address]?.isDeleted ?? false;

  LwwDelta<Object?>? winnerAt(String address) => _entries[address]?.winner;

  void bind(String address, CrdtKind kind) {
    final current = _addressKinds[address];
    if (current != null && current != kind) {
      throw StateError('CRDT address is already bound to another type');
    }
    _addressKinds[address] = kind;
  }

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
    _addressKinds
      ..clear()
      ..addAll(other._addressKinds);
  }

  void mergeState(ReplicaState other) {
    for (final entry in other._addressKinds.entries) {
      final current = _addressKinds[entry.key];
      if (current != null && current != entry.value) {
        throw FormatException('CRDT address is already bound to another type');
      }
    }
    for (final entry in other._entries.entries) {
      final register = _entries.putIfAbsent(
        entry.key,
        LwwRegister<Object?>.new,
      );
      register.mergeState(entry.value);
    }
    _addressKinds.addAll(other._addressKinds);
  }
}
