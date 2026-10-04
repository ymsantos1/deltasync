import 'delta_change.dart';
import 'crdt.dart';
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
  @override
  final String replicaId;
  @override
  final String crdtId;
  final int positive;
  final int negative;
  final Dot? dot;

  @override
  CrdtKind get kind => CrdtKind.pnCounter;

  String get type => kind.wireName;

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
        (allowLegacyIdentity
            ? 'legacy/${CrdtKind.pnCounter.wireName}/$replicaId'
            : null);
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
      CrdtKind.pnCounter.wireName,
      crdtId,
      replicaId,
      dot.counter,
    );
    final legacyId = '$replicaId:${CrdtKind.pnCounter.wireName}:${dot.counter}';
    if (id != expectedId &&
        !(crdtId == 'legacy/${CrdtKind.pnCounter.wireName}/$replicaId' &&
            id == legacyId)) {
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
       _positive = Map.of(positive),
       _negative = Map.of(negative),
       _sequence =
           sequence ??
           (positive[ReplicaId(replicaId).value] ?? 0) +
               (negative[ReplicaId(replicaId).value] ?? 0) {
    if (crdtId.isEmpty || crdtId.trim() != crdtId) {
      throw ArgumentError.value(crdtId, 'crdtId');
    }
    if (_positive.values.any((value) => value < 0) ||
        _negative.values.any((value) => value < 0)) {
      throw ArgumentError('PN-Counter components must be non-negative');
    }
    if (_sequence < 0) throw ArgumentError.value(sequence, 'sequence');
  }

  final String replicaId;

  /// Stable field/model address. Reuse same address when restoring this CRDT.
  final String crdtId;
  final Map<String, int> _positive;
  final Map<String, int> _negative;
  int _sequence;

  @override
  int get value => _sum(_positive) - _sum(_negative);
  Map<String, int> get positive => Map.unmodifiable(_positive);
  Map<String, int> get negative => Map.unmodifiable(_negative);

  PnCounterDelta increment([int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _positive[replicaId] = (_positive[replicaId] ?? 0) + amount;
    return _delta();
  }

  PnCounterDelta decrement([int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _negative[replicaId] = (_negative[replicaId] ?? 0) + amount;
    return _delta();
  }

  @override
  void applyDelta(PnCounterDelta delta) {
    if (delta.id.isEmpty ||
        delta.id.trim() != delta.id ||
        delta.replicaId.isEmpty ||
        delta.replicaId.trim() != delta.replicaId ||
        delta.positive < 0 ||
        delta.negative < 0 ||
        delta.dot == null ||
        delta.dot!.counter <= 0 ||
        delta.dot!.replicaId != delta.replicaId ||
        delta.dot!.crdtId != crdtId) {
      throw FormatException('Invalid PN-Counter delta');
    }
    final expectedId = counterDeltaId(
      CrdtKind.pnCounter.wireName,
      crdtId,
      delta.replicaId,
      delta.dot!.counter,
    );
    final legacyId =
        '${delta.replicaId}:${CrdtKind.pnCounter.wireName}:${delta.dot!.counter}';
    if (delta.id != expectedId &&
        !(crdtId ==
                'legacy/${CrdtKind.pnCounter.wireName}/${delta.replicaId}' &&
            delta.id == legacyId)) {
      throw FormatException('Invalid PN-Counter delta ID');
    }
    if (delta.crdtId != crdtId) {
      throw FormatException('PN-Counter address does not match instance');
    }
    final currentPositive = _positive[delta.replicaId] ?? 0;
    final currentNegative = _negative[delta.replicaId] ?? 0;
    if (delta.positive > currentPositive) {
      _positive[delta.replicaId] = delta.positive;
    }
    if (delta.negative > currentNegative) {
      _negative[delta.replicaId] = delta.negative;
    }
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
    _mergeMax(_positive, state._positive);
    _mergeMax(_negative, state._negative);
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
    id: counterDeltaId(
      CrdtKind.pnCounter.wireName,
      crdtId,
      replicaId,
      ++_sequence,
    ),
    replicaId: replicaId,
    crdtId: crdtId,
    positive: _positive[replicaId] ?? 0,
    negative: _negative[replicaId] ?? 0,
    dot: Dot(replicaId: replicaId, counter: _sequence, crdtId: crdtId),
  );

  static int _sum(Map<String, int> values) =>
      values.values.fold(0, (sum, value) => sum + value);

  static void _mergeMax(Map<String, int> target, Map<String, int> source) {
    for (final entry in source.entries) {
      if (entry.value > (target[entry.key] ?? 0)) {
        target[entry.key] = entry.value;
      }
    }
  }
}
