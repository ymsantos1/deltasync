import 'delta_change.dart';
import 'crdt.dart';
import 'g_counter.dart';
import 'identity.dart';

/// Delta carrying positive and negative monotonic components of a PN-Counter.
class PnCounterDelta implements DeltaChange {
  const PnCounterDelta({
    required this.id,
    required this.replicaId,
    required this.positive,
    required this.negative,
    this.dot,
  });

  @override
  final String id;
  final String replicaId;
  final int positive;
  final int negative;
  final Dot? dot;

  String get type => 'pn-counter';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'replicaId': replicaId,
    'positive': positive,
    'negative': negative,
    if (dot != null) 'dot': dot!.toJson(),
  };

  factory PnCounterDelta.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final replicaId = json['replicaId'];
    final positive = json['positive'];
    final negative = json['negative'];
    if (id is! String ||
        id.isEmpty ||
        replicaId is! String ||
        replicaId.isEmpty ||
        positive is! int ||
        positive < 0 ||
        negative is! int ||
        negative < 0) {
      throw FormatException('Invalid PN-Counter delta');
    }
    final encodedDot = json['dot'];
    return PnCounterDelta(
      id: id,
      replicaId: replicaId,
      positive: positive,
      negative: negative,
      dot: encodedDot is Map
          ? Dot.fromJson(Map<String, Object?>.from(encodedDot))
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PnCounterDelta &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.positive == positive &&
      other.negative == negative &&
      other.dot == dot;

  @override
  int get hashCode => Object.hash(id, replicaId, positive, negative, dot);
}

/// Positive-negative counter built from two grow-only component maps.
class PnCounter implements DeltaCrdt<int, PnCounterDelta> {
  PnCounter(
    this.replicaId, {
    Map<String, int> positive = const {},
    Map<String, int> negative = const {},
  }) : _positive = GCounter(replicaId, components: positive),
       _negative = GCounter(replicaId, components: negative),
       _sequence = (positive[replicaId] ?? 0) + (negative[replicaId] ?? 0);

  final String replicaId;
  final GCounter _positive;
  final GCounter _negative;
  int _sequence;

  @override
  int get value => _positive.value - _negative.value;
  Map<String, int> get positive => _positive.components;
  Map<String, int> get negative => _negative.components;

  PnCounterDelta increment([int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _positive.increment(amount);
    return _delta();
  }

  PnCounterDelta decrement([int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _negative.increment(amount);
    return _delta();
  }

  @override
  void applyDelta(PnCounterDelta delta) {
    if (delta.dot != null && delta.dot!.replicaId != delta.replicaId) {
      throw FormatException('Delta dot replica does not match origin');
    }
    _positive.applyDelta(
      GCounterDelta(
        id: delta.id,
        replicaId: delta.replicaId,
        value: delta.positive,
        dot: delta.dot,
      ),
    );
    _negative.applyDelta(
      GCounterDelta(
        id: delta.id,
        replicaId: delta.replicaId,
        value: delta.negative,
        dot: delta.dot,
      ),
    );
  }

  @override
  void mergeState(covariant DeltaCrdt<int, PnCounterDelta> other) {
    final state = other as PnCounter;
    _positive.mergeState(state._positive);
    _negative.mergeState(state._negative);
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'positive': positive,
    'negative': negative,
  };

  PnCounterDelta _delta() => PnCounterDelta(
    id: '$replicaId:pn-counter:${++_sequence}',
    replicaId: replicaId,
    positive: _positive.components[replicaId] ?? 0,
    negative: _negative.components[replicaId] ?? 0,
    dot: Dot(replicaId: replicaId, counter: _sequence),
  );
}
