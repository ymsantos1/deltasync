import 'lww_delta.dart';
import 'identity.dart';
import 'hlc.dart';
import 'vector_clock.dart';

/// Legacy operation shape accepted only by explicit version 1/2 migration.
@Deprecated('Legacy codec input only; create native DeltaChange values.')
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
}

/// Converts one version 1/2 LWW operation into a native delta.
///
/// The legacy vector-clock weight becomes a synthetic HLC physical value;
/// replica ID and operation ID retain the old deterministic tie-break order.
LwwDelta<Object?> migrateLegacyOperation(Operation operation) {
  if (operation.type != 'lww.set' && operation.type != 'lww.delete') {
    throw FormatException('Unsupported legacy operation type');
  }
  if (operation.id.isEmpty ||
      operation.id.trim() != operation.id ||
      operation.replicaId.isEmpty ||
      operation.replicaId.trim() != operation.replicaId) {
    throw FormatException('Invalid legacy operation identity');
  }
  final key = operation.payload['key'];
  if (key is! String || key.isEmpty || key.trim() != key) {
    throw FormatException('Invalid legacy LWW address');
  }
  if (operation.type == 'lww.set' && !operation.payload.containsKey('value')) {
    throw FormatException('Legacy LWW set requires value');
  }
  final weight = operation.vectorClock.entries.values.fold<BigInt>(
    BigInt.zero,
    (sum, counter) => sum + BigInt.from(counter),
  );
  if (weight > BigInt.from(0x7fffffffffffffff)) {
    throw FormatException('Legacy LWW clock exceeds migration range');
  }
  final ownCounter = operation.vectorClock.entries[operation.replicaId] ?? 0;
  if (ownCounter <= 0) {
    throw FormatException('Legacy LWW clock does not include its origin');
  }
  return LwwDelta<Object?>(
    key: key,
    id: operation.id,
    replicaId: operation.replicaId,
    timestamp: HlcTimestamp(weight.toInt(), 0),
    value: operation.payload['value'],
    deleted: operation.type == 'lww.delete',
    dot: Dot(replicaId: operation.replicaId, counter: ownCounter),
  );
}
