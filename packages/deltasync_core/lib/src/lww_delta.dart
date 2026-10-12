import 'delta_change.dart';
import 'hlc.dart';
import 'identity.dart';
import 'json_value.dart';
import 'json_set_value.dart';

/// Delta produced by an LWW register.
///
/// [id] identifies the delta for transport and tracing. Register correctness
/// comes from timestamp plus replica tie-breaking, not from ID deduplication.
class LwwDelta<T> implements DeltaChange {
  LwwDelta({
    required this.key,
    required this.id,
    required this.replicaId,
    required this.timestamp,
    required T? value,
    this.decodeValue,
    this.deleted = false,
    this.dot,
  }) : _value = copyJsonValue(value) {
    if (deleted && value != null) {
      throw FormatException('Deleted LWW delta cannot carry a value');
    }
    if (value != null) _decode(_value);
  }

  /// Stable field identified by this delta.
  final String key;
  @override
  final String id;
  @override
  final String replicaId;
  final HlcTimestamp timestamp;

  /// Converts JSON copies to [T]. Required for typed JSON collections.
  final T? Function(Object?)? decodeValue;
  final Object? _value;

  /// Fresh copy; modifying it cannot change this delta.
  T? get value => _value == null ? null : _decode(_value);
  final bool deleted;
  final Dot? dot;

  /// [decodeValue] converts copied JSON to [T] for typed collections.
  factory LwwDelta.fromJson(
    Map<String, Object?> json, {
    T? Function(Object?)? decodeValue,
  }) {
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
    final typedValue = copiedValue == null
        ? null
        : _decodeCopied<T>(copiedValue, decodeValue);
    return LwwDelta<T>(
      key: key,
      id: id,
      replicaId: replicaId,
      timestamp: HlcTimestamp.fromJson(Map<String, Object?>.from(timestamp)),
      value: typedValue,
      decodeValue: decodeValue,
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
    'value': copyJsonValue(_value),
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
      canonicalJsonSetKey(other._value) == canonicalJsonSetKey(_value) &&
      other.deleted == deleted &&
      other.dot == dot;

  @override
  int get hashCode => Object.hash(
    key,
    id,
    replicaId,
    timestamp,
    canonicalJsonSetKey(_value),
    deleted,
    dot,
  );

  T _decode(Object? value) =>
      _decodeCopied<T>(copyJsonValue(value), decodeValue);

  static V _decodeCopied<V>(Object? copy, V? Function(Object?)? decoder) {
    final decoded = decoder == null ? copy : decoder(copy);
    if (decoded is! V) {
      throw FormatException('LWW value does not match $V; provide decodeValue');
    }
    if (canonicalJsonSetKey(copyJsonValue(decoded)) !=
        canonicalJsonSetKey(copy)) {
      throw FormatException('LWW value conversion changed JSON content');
    }
    return decoded;
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key');
    }
    return value;
  }
}
