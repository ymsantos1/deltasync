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
}
