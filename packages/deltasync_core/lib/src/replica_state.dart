import 'change.dart';

/// Materialized state produced by applying changes in any order.
class ReplicaState {
  ReplicaState() : _entries = {};

  ReplicaState._(Map<String, Change> entries) : _entries = {...entries};

  final Map<String, Change> _entries;

  Map<String, Object?> get values => {
    for (final entry in _entries.entries)
      if (!entry.value.deleted) entry.key: entry.value.value,
  };

  Object? operator [](String key) => values[key];

  void apply(Change change) {
    final previous = _entries[change.key];
    if (previous == null || change.compareTo(previous) > 0) {
      _entries[change.key] = change;
    }
  }

  ReplicaState copy() => ReplicaState._(_entries);
}
