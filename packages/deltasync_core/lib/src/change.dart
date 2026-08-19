/// A last-write-wins operation on one logical key.
class Change {
  const Change({
    required this.id,
    required this.replicaId,
    required this.key,
    required this.value,
    required this.timestamp,
    this.deleted = false,
  });

  final String id;
  final String replicaId;
  final String key;
  final Object? value;
  final int timestamp;
  final bool deleted;

  /// Deterministic ordering makes concurrent changes converge.
  int compareTo(Change other) {
    final time = timestamp.compareTo(other.timestamp);
    if (time != 0) return time;
    final replica = replicaId.compareTo(other.replicaId);
    if (replica != 0) return replica;
    return id.compareTo(other.id);
  }
}
