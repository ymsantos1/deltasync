import 'crdt.dart';
import 'delta_change.dart';
import 'identity.dart';
import 'json_set_value.dart';

/// Operation encoded by an addressed 2P-Set delta.
enum TwoPSetAction {
  add('add'),
  remove('remove');

  const TwoPSetAction(this.wireName);

  final String wireName;

  static TwoPSetAction fromWire(String value) => switch (value) {
    'add' => TwoPSetAction.add,
    'remove' => TwoPSetAction.remove,
    _ => throw FormatException('Unsupported 2P-Set action'),
  };
}

/// A batch of additions or permanent removals at one stable CRDT address.
class TwoPSetDelta implements DeltaChange {
  TwoPSetDelta({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required this.action,
    required Iterable<Object?> elements,
    required this.dot,
  }) : elements = normalizeJsonSetElements(elements) {
    if (id.isEmpty || id.trim() != id) {
      throw ArgumentError.value(id, 'id');
    }
    if (replicaId.isEmpty || replicaId.trim() != replicaId) {
      throw ArgumentError.value(replicaId, 'replicaId');
    }
    _validateAddress(crdtId);
    if (dot.counter <= 0 ||
        dot.replicaId != replicaId ||
        dot.crdtId != crdtId) {
      throw ArgumentError.value(dot, 'dot');
    }
    if (id !=
        crdtDeltaId(
          CrdtKind.twoPSet.wireName,
          crdtId,
          replicaId,
          dot.counter,
        )) {
      throw ArgumentError.value(id, 'id', 'does not match 2P-Set dot');
    }
    if (this.elements.isEmpty) {
      throw ArgumentError.value(elements, 'elements', 'must not be empty');
    }
  }

  @override
  final String id;
  @override
  final String replicaId;
  @override
  final String crdtId;
  final TwoPSetAction action;
  final List<Object?> elements;
  final Dot dot;

  @override
  CrdtKind get kind => CrdtKind.twoPSet;

  String get type => kind.wireName;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'replicaId': replicaId,
    'crdtId': crdtId,
    'action': action.wireName,
    'elements': elements,
    'dot': dot.toJson(),
  };

  factory TwoPSetDelta.fromJson(Map<String, Object?> json) {
    final id = _requiredString(json, 'id');
    final replicaId = _requiredString(json, 'replicaId');
    final crdtId = _requiredString(json, 'crdtId');
    final action = json['action'];
    final elements = json['elements'];
    final dot = json['dot'];
    if (action is! String || elements is! List || dot is! Map) {
      throw FormatException('Invalid 2P-Set delta');
    }
    try {
      return TwoPSetDelta(
        id: id,
        replicaId: replicaId,
        crdtId: crdtId,
        action: TwoPSetAction.fromWire(action),
        elements: elements,
        dot: Dot.fromJson(Map<String, Object?>.from(dot)),
      );
    } on ArgumentError {
      throw FormatException('Invalid 2P-Set delta');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TwoPSetDelta &&
      id == other.id &&
      replicaId == other.replicaId &&
      crdtId == other.crdtId &&
      action == other.action &&
      dot == other.dot &&
      jsonSetElementKeys(elements).join('\u0000') ==
          jsonSetElementKeys(other.elements).join('\u0000');

  @override
  int get hashCode => Object.hash(
    id,
    replicaId,
    crdtId,
    action,
    dot,
    Object.hashAll(jsonSetElementKeys(elements)),
  );
}

/// Two-phase set for JSON values. Added and removed sets grow monotonically;
/// membership is the additions minus permanent removal tombstones.
class TwoPSet implements DeltaCrdt<Set<Object?>, TwoPSetDelta> {
  TwoPSet(String replicaId, {required this.crdtId})
    : replicaId = ReplicaId(replicaId).value {
    _validateAddress(crdtId);
  }

  final String replicaId;
  final String crdtId;
  final Map<String, _TwoPSetEntry> _additions = {};
  final Map<String, _TwoPSetEntry> _removals = {};
  int _sequence = 0;

  @override
  Set<Object?> get value {
    final visible = <String, Object?>{};
    for (final entry in _additions.entries) {
      if (!_removals.containsKey(entry.key)) {
        visible[entry.key] = entry.value.element;
      }
    }
    return jsonSetValueView(visible);
  }

  /// Adds [element]. A previously removed value remains absent.
  TwoPSetDelta add(Object? element) => addAll([element]);

  /// Adds [elements] in one delta; removals are permanent.
  TwoPSetDelta addAll(Iterable<Object?> elements) =>
      _mutate(TwoPSetAction.add, elements);

  /// Permanently removes [element], including when removal arrives first.
  TwoPSetDelta remove(Object? element) => removeAll([element]);

  /// Permanently removes [elements] in one delta.
  TwoPSetDelta removeAll(Iterable<Object?> elements) =>
      _mutate(TwoPSetAction.remove, elements);

  TwoPSetDelta _mutate(TwoPSetAction action, Iterable<Object?> elements) {
    final normalized = normalizeJsonSetElements(elements);
    if (normalized.isEmpty) {
      throw ArgumentError.value(elements, 'elements', 'must not be empty');
    }
    final dot = Dot(replicaId: replicaId, counter: ++_sequence, crdtId: crdtId);
    final delta = TwoPSetDelta(
      id: crdtDeltaId(
        CrdtKind.twoPSet.wireName,
        crdtId,
        replicaId,
        dot.counter,
      ),
      replicaId: replicaId,
      crdtId: crdtId,
      action: action,
      elements: normalized,
      dot: dot,
    );
    applyDelta(delta);
    return delta;
  }

  @override
  void applyDelta(TwoPSetDelta delta) {
    if (delta.crdtId != crdtId) {
      throw FormatException('2P-Set address does not match instance');
    }
    for (final change in exportChanges()) {
      if (change.id == delta.id && change != delta) {
        throw FormatException('Conflicting 2P-Set delta ID');
      }
    }
    final target = delta.action == TwoPSetAction.add ? _additions : _removals;
    for (final element in delta.elements) {
      final key = canonicalJsonSetKey(element);
      final current = target[key];
      if (current == null || delta.id.compareTo(current.change.id) < 0) {
        target[key] = _TwoPSetEntry(element, delta);
      }
    }
    if (delta.replicaId == replicaId && delta.dot.counter > _sequence) {
      _sequence = delta.dot.counter;
    }
  }

  @override
  void mergeState(covariant DeltaCrdt<Set<Object?>, TwoPSetDelta> other) {
    final state = other as TwoPSet;
    if (state.crdtId != crdtId) {
      throw ArgumentError('Cannot merge 2P-Sets with different addresses');
    }
    for (final change in state.exportChanges()) {
      applyDelta(change);
    }
    if (state.replicaId == replicaId && state._sequence > _sequence) {
      _sequence = state._sequence;
    }
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'crdtId': crdtId,
    'sequence': _sequence,
    'changes': [for (final change in exportChanges()) change.toJson()],
  };

  factory TwoPSet.fromJson(Map<String, Object?> json) {
    final replicaId = json['replicaId'];
    final crdtId = json['crdtId'];
    final sequence = json['sequence'];
    final changes = json['changes'];
    if (replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        crdtId is! String ||
        sequence is! int ||
        sequence < 0 ||
        changes is! List) {
      throw FormatException('Invalid 2P-Set snapshot');
    }
    try {
      final restored = TwoPSet(replicaId, crdtId: crdtId);
      for (final item in changes) {
        if (item is! Map) throw FormatException('Invalid 2P-Set snapshot');
        restored.applyDelta(
          TwoPSetDelta.fromJson(Map<String, Object?>.from(item)),
        );
      }
      if (restored._sequence > sequence) {
        throw FormatException('2P-Set sequence is behind its changes');
      }
      restored._sequence = sequence;
      return restored;
    } on ArgumentError {
      throw FormatException('Invalid 2P-Set snapshot');
    }
  }

  /// Returns compact add/removal representatives for bootstrap and merge.
  Iterable<TwoPSetDelta> exportChanges() sync* {
    final changes = {
      for (final entry in _additions.values) entry.change,
      for (final entry in _removals.values) entry.change,
    }.toList()..sort((first, second) => first.id.compareTo(second.id));
    yield* changes;
  }
}

class _TwoPSetEntry {
  const _TwoPSetEntry(this.element, this.change);

  final Object? element;
  final TwoPSetDelta change;
}

void _validateAddress(String crdtId) {
  if (crdtId.isEmpty ||
      crdtId.trim() != crdtId ||
      crdtId.startsWith('legacy/')) {
    throw ArgumentError.value(crdtId, 'crdtId');
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw FormatException('Invalid 2P-Set $key');
  }
  return value;
}
