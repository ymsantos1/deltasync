/// Stable identity of a replica.
class ReplicaId implements Comparable<ReplicaId> {
  ReplicaId(String value) : value = value.trim() {
    if (this.value.isEmpty) throw ArgumentError.value(value, 'value');
  }

  final String value;

  @override
  int compareTo(ReplicaId other) => value.compareTo(other.value);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is ReplicaId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Causal event identity: one replica and one strictly positive counter.
class Dot {
  const Dot({required this.replicaId, required this.counter})
    : assert(replicaId != ''),
      assert(counter > 0);

  final String replicaId;
  final int counter;

  Map<String, Object?> toJson() => {'replicaId': replicaId, 'counter': counter};

  factory Dot.fromJson(Map<String, Object?> json) {
    final replicaId = json['replicaId'];
    final counter = json['counter'];
    if (replicaId is! String ||
        replicaId.isEmpty ||
        counter is! int ||
        counter <= 0) {
      throw FormatException('Invalid dot');
    }
    return Dot(replicaId: replicaId, counter: counter);
  }

  @override
  bool operator ==(Object other) =>
      other is Dot && other.replicaId == replicaId && other.counter == counter;

  @override
  int get hashCode => Object.hash(replicaId, counter);
}
