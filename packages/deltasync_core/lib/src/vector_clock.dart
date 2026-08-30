enum ClockRelation { equal, before, after, concurrent }

/// Causal version vector indexed by replica identifier.
class VectorClock {
  VectorClock([Map<String, int> entries = const {}])
    : entries = Map.unmodifiable(entries) {
    if (this.entries.values.any((value) => value < 0)) {
      throw ArgumentError.value(
        entries,
        'entries',
        'Counters cannot be negative',
      );
    }
  }

  final Map<String, int> entries;

  VectorClock tick(String replicaId) {
    if (replicaId.trim().isEmpty) throw ArgumentError.value(replicaId);
    return VectorClock({...entries, replicaId: (entries[replicaId] ?? 0) + 1});
  }

  VectorClock merge(VectorClock other) {
    final merged = {...entries};
    for (final entry in other.entries.entries) {
      final current = merged[entry.key] ?? 0;
      if (entry.value > current) merged[entry.key] = entry.value;
    }
    return VectorClock(merged);
  }

  ClockRelation compare(VectorClock other) {
    final replicas = {...entries.keys, ...other.entries.keys};
    var hasLess = false;
    var hasGreater = false;
    for (final replicaId in replicas) {
      final local = entries[replicaId] ?? 0;
      final remote = other.entries[replicaId] ?? 0;
      hasLess |= local < remote;
      hasGreater |= local > remote;
    }
    if (hasLess && hasGreater) return ClockRelation.concurrent;
    if (hasLess) return ClockRelation.before;
    if (hasGreater) return ClockRelation.after;
    return ClockRelation.equal;
  }

  Map<String, Object?> toJson() => {...entries};

  factory VectorClock.fromJson(Map<String, Object?> json) {
    return VectorClock(
      json.map((key, value) {
        if (value is! int) throw FormatException('Invalid vector clock value');
        return MapEntry(key, value);
      }),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VectorClock && compare(other) == ClockRelation.equal;

  @override
  int get hashCode => Object.hashAllUnordered(
    entries.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
