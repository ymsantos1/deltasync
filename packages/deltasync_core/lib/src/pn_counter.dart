import 'delta_change.dart';
import 'crdt.dart';
import 'g_counter.dart';
import 'identity.dart';

/// Delta carrying positive and negative monotonic components of a PN-Counter.
class PnCounterDelta implements DeltaChange {
  const PnCounterDelta({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required this.positive,
    required this.negative,
    this.dot,
  });

  @override
  final String id;
  final String replicaId;
  final String crdtId;
  final int positive;
  final int negative;
  final Dot? dot;

  String get type => 'pn-counter';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'replicaId': replicaId,
    'crdtId': crdtId,
    'positive': positive,
    'negative': negative,
    if (dot != null) 'dot': dot!.toJson(),
  };

  factory PnCounterDelta.fromJson(
    Map<String, Object?> json, {
    bool allowLegacyIdentity = false,
  }) {
    final id = json['id'];
    final replicaId = json['replicaId'];
    final encodedCrdtId = json['crdtId'];
    final positive = json['positive'];
    final negative = json['negative'];
    if (id is! String ||
        id.isEmpty ||
        replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        positive is! int ||
        positive < 0 ||
        negative is! int ||
        negative < 0) {
      throw FormatException('Invalid PN-Counter delta');
    }
    final crdtId =
        encodedCrdtId ??
        (allowLegacyIdentity ? 'legacy/pn-counter/$replicaId' : null);
    if (crdtId is! String || crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw FormatException('Invalid PN-Counter CRDT address');
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
        throw FormatException('PN-Counter dot address does not match delta');
      }
    }
    if (dot == null || dot.replicaId != replicaId) {
      throw FormatException('Invalid PN-Counter dot origin');
    }
    final expectedId = counterDeltaId(
      'pn-counter',
      crdtId,
      replicaId,
      dot.counter,
    );
    final legacyId = '$replicaId:pn-counter:${dot.counter}';
    if (id != expectedId &&
        !(crdtId == 'legacy/pn-counter/$replicaId' && id == legacyId)) {
      throw FormatException('Invalid PN-Counter delta ID');
    }
    return PnCounterDelta(
      id: id,
      replicaId: replicaId,
      crdtId: crdtId,
      positive: positive,
      negative: negative,
      dot: dot,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PnCounterDelta &&
      other.id == id &&
      other.replicaId == replicaId &&
      other.crdtId == crdtId &&
      other.positive == positive &&
      other.negative == negative &&
      other.dot == dot;

  @override
  int get hashCode =>
      Object.hash(id, replicaId, crdtId, positive, negative, dot);
}

/// Positive-negative counter built from two grow-only component maps.
class PnCounter implements DeltaCrdt<int, PnCounterDelta> {
  PnCounter(
    String replicaId, {
    required this.crdtId,
    Map<String, int> positive = const {},
    Map<String, int> negative = const {},
    int? sequence,
  }) : replicaId = ReplicaId(replicaId).value,
       _positive = GCounter(
         replicaId,
         crdtId: '$crdtId/positive',
         components: positive,
       ),
       _negative = GCounter(
         replicaId,
         crdtId: '$crdtId/negative',
         components: negative,
       ),
       _sequence =
           sequence ??
           (positive[ReplicaId(replicaId).value] ?? 0) +
               (negative[ReplicaId(replicaId).value] ?? 0) {
    if (crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw ArgumentError.value(crdtId, 'crdtId');
    }
    if (_sequence < 0) throw ArgumentError.value(sequence, 'sequence');
  }

  final String replicaId;

  /// Stable field/model address. Reuse same address when restoring this CRDT.
  final String crdtId;
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
    if (delta.crdtId != crdtId) {
      throw FormatException('PN-Counter address does not match instance');
    }
    if (delta.dot != null && delta.dot!.replicaId != delta.replicaId) {
      throw FormatException('Delta dot replica does not match origin');
    }
    if (delta.dot != null && delta.dot!.crdtId != crdtId) {
      throw FormatException('PN-Counter dot address does not match delta');
    }
    _positive.applyDelta(
      GCounterDelta(
        id: delta.id,
        replicaId: delta.replicaId,
        crdtId: '$crdtId/positive',
        value: delta.positive,
        dot: delta.dot == null
            ? null
            : Dot(
                replicaId: delta.dot!.replicaId,
                counter: delta.dot!.counter,
                crdtId: '$crdtId/positive',
              ),
      ),
    );
    _negative.applyDelta(
      GCounterDelta(
        id: delta.id,
        replicaId: delta.replicaId,
        crdtId: '$crdtId/negative',
        value: delta.negative,
        dot: delta.dot == null
            ? null
            : Dot(
                replicaId: delta.dot!.replicaId,
                counter: delta.dot!.counter,
                crdtId: '$crdtId/negative',
              ),
      ),
    );
    if (delta.replicaId == replicaId &&
        delta.dot != null &&
        delta.dot!.counter > _sequence) {
      _sequence = delta.dot!.counter;
    }
  }

  @override
  void mergeState(covariant DeltaCrdt<int, PnCounterDelta> other) {
    final state = other as PnCounter;
    if (state.crdtId != crdtId) {
      throw ArgumentError('Cannot merge counters with different addresses');
    }
    _positive.mergeState(state._positive);
    _negative.mergeState(state._negative);
    if (state.replicaId == replicaId && state._sequence > _sequence) {
      _sequence = state._sequence;
    }
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'crdtId': crdtId,
    'positive': positive,
    'negative': negative,
    'sequence': _sequence,
  };

  PnCounterDelta _delta() => PnCounterDelta(
    id: counterDeltaId('pn-counter', crdtId, replicaId, ++_sequence),
    replicaId: replicaId,
    crdtId: crdtId,
    positive: _positive.components[replicaId] ?? 0,
    negative: _negative.components[replicaId] ?? 0,
    dot: Dot(replicaId: replicaId, counter: _sequence, crdtId: crdtId),
  );
}
