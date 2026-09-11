import 'delta_change.dart';
import 'hlc.dart';

/// Delta produced by an LWW register.
///
/// [id] identifies the delta for transport and tracing. Register correctness
/// comes from timestamp plus replica tie-breaking, not from ID deduplication.
class LwwDelta<T> implements DeltaChange {
  const LwwDelta({
    required this.key,
    required this.id,
    required this.replicaId,
    required this.timestamp,
    required this.value,
    this.deleted = false,
  });

  /// Stable field identified by this delta.
  final String key;
  @override
  final String id;
  final String replicaId;
  final HlcTimestamp timestamp;
  final T? value;
  final bool deleted;

  factory LwwDelta.fromJson(Map<String, Object?> json) {
    final timestamp = json['timestamp'];
    if (timestamp is! Map) {
      throw FormatException('Missing or invalid timestamp');
    }
    return LwwDelta<T>(
      key: _requiredString(json, 'key'),
      id: _requiredString(json, 'id'),
      replicaId: _requiredString(json, 'replicaId'),
      timestamp: HlcTimestamp.fromJson(Map<String, Object?>.from(timestamp)),
      value: json['value'] as T?,
      deleted: json['deleted'] == true,
    );
  }

  String get type => 'lww';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'key': key,
    'id': id,
    'replicaId': replicaId,
    'timestamp': timestamp.toJson(),
    'value': value,
    'deleted': deleted,
  };

  @override
  bool operator ==(Object other) =>
      other is LwwDelta<T> &&
      other.key == key &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.timestamp == timestamp &&
      other.value == value &&
      other.deleted == deleted;

  @override
  int get hashCode =>
      Object.hash(key, id, replicaId, timestamp, value, deleted);

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key');
    }
    return value;
  }
}
