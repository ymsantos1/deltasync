import 'vector_clock.dart';

/// Transport-neutral envelope. CRDTs interpret [type] and [payload].
class Operation {
  Operation({
    required this.id,
    required this.replicaId,
    required this.type,
    required this.vectorClock,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  factory Operation.fromJson(Map<String, Object?> json) {
    final clock = json['vectorClock'];
    if (clock is! Map) throw FormatException('Missing or invalid vectorClock');
    return Operation(
      id: _requiredString(json, 'id'),
      replicaId: _requiredString(json, 'replicaId'),
      type: _requiredString(json, 'type'),
      vectorClock: VectorClock.fromJson(Map<String, Object?>.from(clock)),
      payload: _objectMap(json['payload'], 'payload'),
    );
  }

  final String id;
  final String replicaId;
  final String type;
  final VectorClock vectorClock;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'id': id,
    'replicaId': replicaId,
    'type': type,
    'vectorClock': vectorClock.toJson(),
    'payload': payload,
  };

  /// Causal order; concurrent operations use deterministic tie-breakers.
  int compareTo(Operation other) {
    final relation = vectorClock.compare(other.vectorClock);
    if (relation == ClockRelation.before) return -1;
    if (relation == ClockRelation.after) return 1;
    final replica = replicaId.compareTo(other.replicaId);
    return replica == 0 ? id.compareTo(other.id) : replica;
  }

  @override
  bool operator ==(Object other) =>
      other is Operation &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.type == type &&
      other.vectorClock == vectorClock &&
      _mapsEqual(other.payload, payload);

  @override
  int get hashCode => Object.hash(id, replicaId, type, vectorClock);

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key');
    }
    return value;
  }

  static Map<String, Object?> _objectMap(Object? value, String key) {
    if (value is! Map) throw FormatException('Missing or invalid $key');
    return value.map((entryKey, entryValue) {
      if (entryKey is! String) throw FormatException('Invalid $key key');
      return MapEntry(entryKey, entryValue);
    });
  }

  static bool _mapsEqual(
    Map<String, Object?> first,
    Map<String, Object?> second,
  ) {
    if (first.length != second.length) return false;
    for (final entry in first.entries) {
      if (!second.containsKey(entry.key) || second[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
