import 'delta_change.dart';
import 'crdt.dart';
import 'identity.dart';

/// Delta carrying the monotonic component value of a G-Counter.
class GCounterDelta implements DeltaChange {
  const GCounterDelta({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required this.value,
    this.dot,
  });

  @override
  final String id;
  final String replicaId;
  final String crdtId;
  final int value;
  final Dot? dot;

  String get type => 'g-counter';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'replicaId': replicaId,
    'crdtId': crdtId,
    'value': value,
    if (dot != null) 'dot': dot!.toJson(),
  };

  factory GCounterDelta.fromJson(
    Map<String, Object?> json, {
    bool allowLegacyIdentity = false,
  }) {
    final id = json['id'];
    final replicaId = json['replicaId'];
    final encodedCrdtId = json['crdtId'];
    final value = json['value'];
    if (id is! String ||
        id.isEmpty ||
        replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        value is! int ||
        value < 0) {
      throw FormatException('Invalid G-Counter delta');
    }
    final crdtId =
        encodedCrdtId ??
        (allowLegacyIdentity ? 'legacy/g-counter/$replicaId' : null);
    if (crdtId is! String || crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw FormatException('Invalid G-Counter CRDT address');
    }
    final encodedDot = json['dot'];
    Dot? dot;
    if (encodedDot is Map) {
      dot = Dot.fromJson(Map<String, Object?>.from(encodedDot));
      if (dot.crdtId == null && encodedCrdtId == null && allowLegacyIdentity) {
        dot = Dot(
          replicaId: dot.replicaId,
          counter: dot.counter,
          crdtId: crdtId,
        );
      } else if (dot.crdtId != crdtId) {
        throw FormatException('G-Counter dot address does not match delta');
      }
    }
    if (dot == null || dot.replicaId != replicaId) {
      throw FormatException('Invalid G-Counter dot origin');
    }
    final expectedId = counterDeltaId(
      'g-counter',
      crdtId,
      replicaId,
      dot.counter,
    );
    final legacyId = '$replicaId:g-counter:${dot.counter}';
    if (id != expectedId &&
        !(crdtId == 'legacy/g-counter/$replicaId' && id == legacyId)) {
      throw FormatException('Invalid G-Counter delta ID');
    }
    return GCounterDelta(
      id: id,
      replicaId: replicaId,
      crdtId: crdtId,
      value: value,
      dot: dot,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GCounterDelta &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.crdtId == crdtId &&
      other.value == value &&
      other.dot == dot;

  @override
  int get hashCode => Object.hash(id, replicaId, crdtId, value, dot);
}

/// Grow-only counter with one monotonic component per replica.
class GCounter implements DeltaCrdt<int, GCounterDelta> {
  GCounter(
    String replicaId, {
    required this.crdtId,
    Map<String, int> components = const {},
    int? sequence,
  }) : replicaId = ReplicaId(replicaId).value,
       _components = Map<String, int>.of(components),
       _sequence = sequence ?? components[ReplicaId(replicaId).value] ?? 0 {
    _validateAddress(crdtId);
    if (_sequence < 0) throw ArgumentError.value(sequence, 'sequence');
    if (_components.values.any((value) => value < 0)) {
      throw ArgumentError.value(components, 'components');
    }
  }

  final String replicaId;

  /// Stable field/model address. Reuse same address when restoring this CRDT.
  final String crdtId;
  final Map<String, int> _components;
  int _sequence;

  @override
  int get value => _components.values.fold(0, (sum, item) => sum + item);

  Map<String, int> get components => Map.unmodifiable(_components);

  GCounterDelta increment([int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    final next = (_components[replicaId] ?? 0) + amount;
    _components[replicaId] = next;
    final sequence = ++_sequence;
    return GCounterDelta(
      id: counterDeltaId('g-counter', crdtId, replicaId, sequence),
      replicaId: replicaId,
      crdtId: crdtId,
      value: next,
      dot: Dot(replicaId: replicaId, counter: sequence, crdtId: crdtId),
    );
  }

  @override
  void applyDelta(GCounterDelta delta) {
    if (delta.value < 0) throw FormatException('Negative G-Counter value');
    if (delta.crdtId != crdtId) {
      throw FormatException('G-Counter address does not match instance');
    }
    if (delta.dot != null && delta.dot!.replicaId != delta.replicaId) {
      throw FormatException('Delta dot replica does not match origin');
    }
    if (delta.dot != null && delta.dot!.crdtId != crdtId) {
      throw FormatException('G-Counter dot address does not match delta');
    }
    final current = _components[delta.replicaId] ?? 0;
    if (delta.value > current) _components[delta.replicaId] = delta.value;
    if (delta.replicaId == replicaId &&
        delta.dot != null &&
        delta.dot!.counter > _sequence) {
      _sequence = delta.dot!.counter;
    }
  }

  @override
  void mergeState(covariant DeltaCrdt<int, GCounterDelta> other) {
    final state = other as GCounter;
    if (state.crdtId != crdtId) {
      throw ArgumentError('Cannot merge counters with different addresses');
    }
    for (final entry in state._components.entries) {
      final current = _components[entry.key] ?? 0;
      if (entry.value > current) _components[entry.key] = entry.value;
    }
    if (state.replicaId == replicaId && state._sequence > _sequence) {
      _sequence = state._sequence;
    }
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'crdtId': crdtId,
    'components': components,
    'sequence': _sequence,
  };

  static void _validateAddress(String address) {
    if (address.isEmpty || address.trim() != address) {
      throw ArgumentError.value(address, 'crdtId');
    }
  }
}
