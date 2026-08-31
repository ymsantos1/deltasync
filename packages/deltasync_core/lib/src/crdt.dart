import 'operation.dart';

/// Common contract implemented by every CRDT supported by the core.
///
/// Concrete CRDTs own merge rules. They must accept an operation more than
/// once without changing the resulting state after the first application.
/// Operations must carry a globally unique [Operation.id], their origin,
/// causal metadata and CRDT-specific payload.
abstract interface class Crdt<T> {
  T get value;

  void apply(Operation operation);
}

/// Operation envelope shared by CRDT implementations.
class CrdtOperation {
  CrdtOperation({
    required this.id,
    required this.replicaId,
    required this.type,
    required this.timestamp,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  factory CrdtOperation.fromJson(Map<String, Object?> json) {
    return CrdtOperation(
      id: _requiredString(json, 'id'),
      replicaId: _requiredString(json, 'replicaId'),
      type: _requiredString(json, 'type'),
      timestamp: _requiredInt(json, 'timestamp'),
      payload: _objectMap(json['payload'], 'payload'),
    );
  }

  final String id;
  final String replicaId;
  final String type;
  final int timestamp;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'id': id,
    'replicaId': replicaId,
    'type': type,
    'timestamp': timestamp,
    'payload': payload,
  };

  @override
  bool operator ==(Object other) =>
      other is CrdtOperation &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.type == type &&
      other.timestamp == timestamp &&
      _mapsEqual(other.payload, payload);

  @override
  int get hashCode => Object.hash(id, replicaId, type, timestamp);

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key');
    }
    return value;
  }

  static int _requiredInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('Missing or invalid $key');
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
