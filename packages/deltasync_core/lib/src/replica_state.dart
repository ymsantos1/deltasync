import 'operation.dart';

/// Materialized state produced by applying changes in any order.
class ReplicaState {
  ReplicaState() : _entries = {};

  ReplicaState._(Map<String, Operation> entries) : _entries = {...entries};

  final Map<String, Operation> _entries;

  Map<String, Object?> get values => {
    for (final entry in _entries.entries)
      if (entry.value.type == 'lww.set')
        entry.key: entry.value.payload['value'],
  };

  Object? operator [](String key) => values[key];

  void apply(Operation operation) {
    if (!operation.type.startsWith('lww.')) return;
    final key = operation.payload['key'];
    if (key is! String) {
      throw FormatException('LWW operation requires string key');
    }
    final previous = _entries[key];
    if (previous == null || operation.compareTo(previous) > 0) {
      _entries[key] = operation;
    }
  }

  ReplicaState copy() => ReplicaState._(_entries);
}
