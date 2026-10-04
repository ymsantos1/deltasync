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
  @override
  final String replicaId;
  @override
  final String crdtId;
  final int value;
  final Dot? dot;

  @override
  CrdtKind get kind => CrdtKind.gCounter;

  String get type => kind.wireName;

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
        (allowLegacyIdentity
            ? 'legacy/${CrdtKind.gCounter.wireName}/$replicaId'
            : null);
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
      CrdtKind.gCounter.wireName,
      crdtId,
      replicaId,
      dot.counter,
    );
    final legacyId = '$replicaId:${CrdtKind.gCounter.wireName}:${dot.counter}';
    if (id != expectedId &&
        !(crdtId == 'legacy/${CrdtKind.gCounter.wireName}/$replicaId' &&
            id == legacyId)) {
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
    Map<String, int>? sequences,
    int? sequence,
  }) : replicaId = ReplicaId(replicaId).value,
       _components = Map<String, int>.of(components),
       _sequences = Map<String, int>.of(
         sequences ??
             {
               if (components.containsKey(ReplicaId(replicaId).value))
                 ReplicaId(replicaId).value:
                     sequence ?? components[ReplicaId(replicaId).value]!,
             },
       ),
       _sequence =
           sequence ??
           sequences?[ReplicaId(replicaId).value] ??
           components[ReplicaId(replicaId).value] ??
           0 {
    _validateAddress(crdtId);
    if (_sequence < 0) throw ArgumentError.value(sequence, 'sequence');
    if (_components.values.any((value) => value < 0)) {
      throw ArgumentError.value(components, 'components');
    }
    if (_sequences.entries.any(
          (entry) =>
              entry.key.isEmpty ||
              entry.key.trim() != entry.key ||
              entry.value < 0,
        ) ||
        _sequence < (_sequences[replicaId] ?? 0) ||
        ((_components[replicaId] ?? 0) > 0 &&
            (_sequences[replicaId] ?? 0) == 0)) {
      throw ArgumentError('Invalid G-Counter sequence state');
    }
  }

  final String replicaId;

  /// Stable field/model address. Reuse same address when restoring this CRDT.
  final String crdtId;
  final Map<String, int> _components;
  final Map<String, int> _sequences;
  int _sequence;

  @override
  int get value => _components.values.fold(0, (sum, item) => sum + item);

  Map<String, int> get components => Map.unmodifiable(_components);

  GCounterDelta increment([int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    final next = (_components[replicaId] ?? 0) + amount;
    _components[replicaId] = next;
    final sequence = ++_sequence;
    _sequences[replicaId] = sequence;
    return GCounterDelta(
      id: counterDeltaId(
        CrdtKind.gCounter.wireName,
        crdtId,
        replicaId,
        sequence,
      ),
      replicaId: replicaId,
      crdtId: crdtId,
      value: next,
      dot: Dot(replicaId: replicaId, counter: sequence, crdtId: crdtId),
    );
  }

  @override
  void applyDelta(GCounterDelta delta) {
    if (delta.value < 0 ||
        delta.id.isEmpty ||
        delta.id.trim() != delta.id ||
        delta.replicaId.isEmpty ||
        delta.replicaId.trim() != delta.replicaId ||
        delta.dot == null ||
        delta.dot!.counter <= 0 ||
        delta.dot!.replicaId != delta.replicaId) {
      throw FormatException('Invalid G-Counter delta');
    }
    if (delta.crdtId != crdtId) {
      throw FormatException('G-Counter address does not match instance');
    }
    if (delta.dot!.crdtId != crdtId) {
      throw FormatException('G-Counter dot address does not match delta');
    }
    final expectedId = counterDeltaId(
      CrdtKind.gCounter.wireName,
      crdtId,
      delta.replicaId,
      delta.dot!.counter,
    );
    final legacyId =
        '${delta.replicaId}:${CrdtKind.gCounter.wireName}:${delta.dot!.counter}';
    if (delta.id != expectedId &&
        !(crdtId == 'legacy/${CrdtKind.gCounter.wireName}/${delta.replicaId}' &&
            delta.id == legacyId)) {
      throw FormatException('Invalid G-Counter delta ID');
    }
    final current = _components[delta.replicaId] ?? 0;
    final currentSequence = _sequences[delta.replicaId];
    if (currentSequence == null) {
      if (delta.value >= current) {
        _components[delta.replicaId] = delta.value;
        _sequences[delta.replicaId] = delta.dot!.counter;
      }
    } else if (delta.dot!.counter > currentSequence) {
      if (delta.value < current) throw FormatException('G-Counter regressed');
      _components[delta.replicaId] = delta.value;
      _sequences[delta.replicaId] = delta.dot!.counter;
    } else if (delta.dot!.counter == currentSequence &&
        delta.value != current) {
      throw FormatException('Conflicting G-Counter delta sequence');
    } else if (delta.value > current) {
      throw FormatException('G-Counter component regressed');
    }
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
    for (final entry in state._sequences.entries) {
      if (entry.value > (_sequences[entry.key] ?? 0)) {
        _sequences[entry.key] = entry.value;
      }
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
    'sequences': Map<String, int>.unmodifiable(_sequences),
    'sequence': _sequence,
  };

  Iterable<GCounterDelta> exportChanges({bool requireSequences = true}) sync* {
    for (final origin in {..._components.keys, ..._sequences.keys}) {
      final value = _components[origin] ?? 0;
      final counter = _sequences[origin];
      if (counter == null) {
        if (requireSequences) {
          throw StateError('Counter bootstrap needs missing origin sequence');
        }
        continue;
      }
      if (counter <= 0) continue;
      yield GCounterDelta(
        id: counterDeltaId(CrdtKind.gCounter.wireName, crdtId, origin, counter),
        replicaId: origin,
        crdtId: crdtId,
        value: value,
        dot: Dot(replicaId: origin, counter: counter, crdtId: crdtId),
      );
    }
  }

  static void _validateAddress(String address) {
    if (address.isEmpty || address.trim() != address) {
      throw ArgumentError.value(address, 'crdtId');
    }
  }
}
