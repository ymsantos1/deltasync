import 'delta_change.dart';
import 'hlc.dart';
import 'identity.dart';
import 'json_value.dart';

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
    this.dot,
  });

  /// Stable field identified by this delta.
  final String key;
  @override
  final String id;
  @override
  final String replicaId;
  final HlcTimestamp timestamp;
  final T? value;
  final bool deleted;
  final Dot? dot;

  factory LwwDelta.fromJson(Map<String, Object?> json) {
    final timestamp = json['timestamp'];
    if (timestamp is! Map) {
      throw FormatException('Missing or invalid timestamp');
    }
    final deleted = json['deleted'];
    if (deleted is! bool) throw FormatException('Invalid LWW deleted flag');
    final value = json['value'];
    if (deleted && value != null) {
      throw FormatException('Deleted LWW delta cannot carry a value');
    }
    final encodedDot = json['dot'];
    if (encodedDot != null && encodedDot is! Map) {
      throw FormatException('Invalid LWW dot');
    }
    final key = _requiredString(json, 'key');
    final id = _requiredString(json, 'id');
    final replicaId = _requiredString(json, 'replicaId');
    if (key.trim() != key || id.trim() != id || replicaId.trim() != replicaId) {
      throw FormatException('Invalid LWW identity');
    }
    Object? copiedValue;
    try {
      copiedValue = copyJsonValue(value);
    } on ArgumentError {
      throw FormatException('Invalid LWW value');
    }
    return LwwDelta<T>(
      key: key,
      id: id,
      replicaId: replicaId,
      timestamp: HlcTimestamp.fromJson(Map<String, Object?>.from(timestamp)),
      value: copiedValue as T?,
      deleted: deleted,
      dot: encodedDot is Map
          ? Dot.fromJson(Map<String, Object?>.from(encodedDot))
          : null,
    );
  }

  @override
  CrdtKind get kind => CrdtKind.lww;

  @override
  String get crdtId => key;

  String get type => kind.wireName;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'key': key,
    'id': id,
    'replicaId': replicaId,
    'timestamp': timestamp.toJson(),
    'value': copyJsonValue(value),
    'deleted': deleted,
    if (dot != null) 'dot': dot!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is LwwDelta &&
      other.key == key &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.timestamp == timestamp &&
      other.value == value &&
      other.deleted == deleted &&
      other.dot == dot;

  @override
  int get hashCode =>
      Object.hash(key, id, replicaId, timestamp, value, deleted, dot);

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key');
    }
    return value;
  }
}
