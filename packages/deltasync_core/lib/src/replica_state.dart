import 'lww_register.dart';
import 'lww_delta.dart';
import 'operation.dart';

/// Materialized state produced by applying changes in any order.
class ReplicaState {
  ReplicaState() : _entries = {};

  ReplicaState._(Map<String, LwwRegister<Object?>> entries)
    : _entries = {...entries};

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
}
