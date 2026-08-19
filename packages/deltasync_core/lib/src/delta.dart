import 'change.dart';

/// A deduplicated batch of changes.
class Delta {
  Delta(Iterable<Change> changes) : changes = List.unmodifiable(changes);

  const Delta.empty() : changes = const [];

  final List<Change> changes;

  Delta merge(Delta other) {
    final byId = <String, Change>{
      for (final change in changes) change.id: change,
    };
    for (final change in other.changes) {
      byId[change.id] = change;
    }
    return Delta(byId.values);
  }
}
