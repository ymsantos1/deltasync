import 'operation.dart';

/// A deduplicated batch of changes.
class Delta {
  Delta(Iterable<Operation> changes) : changes = List.unmodifiable(changes);

  const Delta.empty() : changes = const [];

  final List<Operation> changes;

  Delta merge(Delta other) {
    final byId = <String, Operation>{
      for (final change in changes) change.id: change,
    };
    for (final change in other.changes) {
      byId[change.id] = change;
    }
    return Delta(byId.values);
  }
}
