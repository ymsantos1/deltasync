import 'delta_change.dart';
import 'crdt.dart';
import 'identity.dart';

/// Delta carrying the monotonic component value of a G-Counter.
class GCounterDelta implements DeltaChange {
  const GCounterDelta({
    required this.id,
    required this.replicaId,
    required this.value,
    this.dot,
  });

  @override
  final String id;
  final String replicaId;
  final int value;
  final Dot? dot;

  String get type => 'g-counter';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'replicaId': replicaId,
    'value': value,
    if (dot != null) 'dot': dot!.toJson(),
  };

  factory GCounterDelta.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final replicaId = json['replicaId'];
    final value = json['value'];
    if (id is! String ||
        id.isEmpty ||
        replicaId is! String ||
        replicaId.isEmpty ||
        value is! int ||
        value < 0) {
      throw FormatException('Invalid G-Counter delta');
    }
    final encodedDot = json['dot'];
    return GCounterDelta(
      id: id,
      replicaId: replicaId,
      value: value,
      dot: encodedDot is Map
          ? Dot.fromJson(Map<String, Object?>.from(encodedDot))
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GCounterDelta &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.value == value &&
      other.dot == dot;

  @override
  int get hashCode => Object.hash(id, replicaId, value, dot);
}

/// Grow-only counter with one monotonic component per replica.
class GCounter implements DeltaCrdt<int, GCounterDelta> {
  GCounter(this.replicaId, {Map<String, int> components = const {}})
    : _components = Map<String, int>.of(components),
      _sequence = components[replicaId] ?? 0 {
    ReplicaId(replicaId);
    if (_components.values.any((value) => value < 0)) {
      throw ArgumentError.value(components, 'components');
    }
  }

  final String replicaId;
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
      id: '$replicaId:g-counter:$sequence',
      replicaId: replicaId,
      value: next,
      dot: Dot(replicaId: replicaId, counter: sequence),
    );
  }

  @override
  void applyDelta(GCounterDelta delta) {
    if (delta.value < 0) throw FormatException('Negative G-Counter value');
    if (delta.dot != null && delta.dot!.replicaId != delta.replicaId) {
      throw FormatException('Delta dot replica does not match origin');
    }
    final current = _components[delta.replicaId] ?? 0;
    if (delta.value > current) _components[delta.replicaId] = delta.value;
  }

  @override
  void mergeState(covariant DeltaCrdt<int, GCounterDelta> other) {
    final state = other as GCounter;
    for (final entry in state._components.entries) {
      final current = _components[entry.key] ?? 0;
      if (entry.value > current) _components[entry.key] = entry.value;
    }
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'components': components,
  };
}
