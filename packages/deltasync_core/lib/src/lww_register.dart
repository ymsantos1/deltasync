import 'crdt.dart';
import 'lww_delta.dart';
import 'json_value.dart';
import 'json_set_value.dart';

/// Last-write-wins register with one native HLC winner and retained tombstone.
class LwwRegister<T> implements DeltaCrdt<T?, LwwDelta<T>> {
  /// [decodeValue] converts a JSON copy to [T] when [T] is a typed collection.
  /// It must accept valid persisted JSON and return a JSON-compatible value.
  LwwRegister({this.decodeValue});

  final T? Function(Object?)? decodeValue;
  LwwDelta<Object?>? _winner;

  bool get hasValue => _winner != null && !_winner!.deleted;

  bool get isDeleted => _winner?.deleted ?? false;

  @override
  T? get value => hasValue ? _decode(_winner!.value) : null;

  LwwDelta<T>? get winner {
    final winner = _winner;
    if (winner == null) return null;
    return LwwDelta<T>(
      key: winner.key,
      id: winner.id,
      replicaId: winner.replicaId,
      timestamp: winner.timestamp,
      value: winner.deleted ? null : _decode(winner.value),
      decodeValue: decodeValue,
      deleted: winner.deleted,
      dot: winner.dot,
    );
  }

  @override
  void applyDelta(LwwDelta<T> delta) {
    if (delta.key.isEmpty || delta.key.trim() != delta.key) {
      throw FormatException('Invalid LWW address');
    }
    if (delta.id.isEmpty || delta.id.trim() != delta.id) {
      throw FormatException('Invalid LWW delta ID');
    }
    if (delta.replicaId.isEmpty || delta.replicaId.trim() != delta.replicaId) {
      throw FormatException('Invalid LWW replica ID');
    }
    final dot = delta.dot;
    if (dot != null &&
        (dot.counter <= 0 ||
            dot.replicaId != delta.replicaId ||
            dot.crdtId != null)) {
      throw FormatException('Delta dot identity does not match LWW change');
    }
    final copiedValue = delta.deleted ? null : copyJsonValue(delta.value);
    // Check the configured typed conversion before accepting a new winner.
    if (!delta.deleted) _decode(copiedValue);
    _applyCanonical(
      LwwDelta<Object?>(
        key: delta.key,
        id: delta.id,
        replicaId: delta.replicaId,
        timestamp: delta.timestamp,
        value: copiedValue,
        deleted: delta.deleted,
        dot: delta.dot,
      ),
    );
  }

  @override
  void mergeState(covariant LwwRegister<T> other) {
    final winner = other._winner;
    if (winner != null) {
      if (!winner.deleted) _decode(winner.value);
      _applyCanonical(winner);
    }
  }

  T? _decode(Object? value) {
    if (value == null) return null;
    final copy = copyJsonValue(value);
    final decoded = decodeValue == null ? copy : decodeValue!(copy);
    if (decoded is! T?) {
      throw FormatException('LWW value does not match $T; provide decodeValue');
    }
    if (canonicalJsonSetKey(copyJsonValue(decoded)) !=
        canonicalJsonSetKey(copy)) {
      throw FormatException('LWW value conversion changed JSON content');
    }
    return decoded;
  }

  void _applyCanonical(LwwDelta<Object?> delta) {
    final current = _winner;
    if (current != null && _compare(delta, current) <= 0) return;
    _winner = delta;
  }

  @override
  Map<String, Object?> toJson() => {
    if (winner case final winner?) 'winner': winner.toJson(),
  };

  int _compare(LwwDelta<Object?> first, LwwDelta<Object?> second) {
    final timestamp = first.timestamp.compareTo(second.timestamp);
    if (timestamp != 0) return timestamp;
    final replica = first.replicaId.compareTo(second.replicaId);
    return replica == 0 ? first.id.compareTo(second.id) : replica;
  }
}
