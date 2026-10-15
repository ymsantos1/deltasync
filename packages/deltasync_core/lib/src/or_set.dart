import 'crdt.dart';
import 'delta_change.dart';
import 'identity.dart';
import 'json_set_value.dart';
import 'json_value.dart';

/// Operation encoded by an OR-Set delta.
enum OrSetAction {
  add('add'),
  remove('remove');

  const OrSetAction(this.wireName);

  final String wireName;

  static OrSetAction fromWire(String value) => switch (value) {
    'add' => OrSetAction.add,
    'remove' => OrSetAction.remove,
    _ => throw FormatException('Unsupported OR-Set action'),
  };
}

/// One OR-Set add tag or removal of the exact tags observed by that removal.
class OrSetDelta implements DeltaChange {
  OrSetDelta({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required this.action,
    required this.dot,
    Object? element,
    Iterable<Dot> observedDots = const [],
  }) : element = copyJsonValue(element, freeze: true),
       observedDots = List.unmodifiable(
         observedDots.toSet().toList()..sort(_compareDots),
       ) {
    _validateAddress(crdtId);
    if (id.isEmpty ||
        id.trim() != id ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        dot.counter <= 0 ||
        dot.replicaId != replicaId ||
        dot.crdtId != crdtId ||
        id !=
            crdtDeltaId(
              CrdtKind.orSet.wireName,
              crdtId,
              replicaId,
              dot.counter,
            )) {
      throw ArgumentError('Invalid OR-Set delta identity');
    }
    if (action == OrSetAction.add && this.observedDots.isNotEmpty ||
        action == OrSetAction.remove && this.element != null ||
        this.observedDots.any(
          (observed) =>
              observed.crdtId != crdtId ||
              observed.replicaId.isEmpty ||
              observed.replicaId.trim() != observed.replicaId ||
              observed.counter <= 0 ||
              observed == dot,
        )) {
      throw ArgumentError('Invalid OR-Set delta payload');
    }
    _validateJsonValue(this.element);
  }

  @override
  final String id;
  @override
  final String replicaId;
  @override
  final String crdtId;
  final OrSetAction action;
  final Dot dot;
  final Object? element;
  final List<Dot> observedDots;

  @override
  CrdtKind get kind => CrdtKind.orSet;

  @override
  Map<String, Object?> toJson() => {
    'type': kind.wireName,
    'id': id,
    'replicaId': replicaId,
    'crdtId': crdtId,
    'action': action.wireName,
    'dot': dot.toJson(),
    if (action == OrSetAction.add) 'element': copyJsonValue(element),
    if (action == OrSetAction.remove)
      'observedDots': [for (final observed in observedDots) observed.toJson()],
  };

  factory OrSetDelta.fromJson(Map<String, Object?> json) {
    final action = json['action'];
    final dot = json['dot'];
    if (action is! String || dot is! Map) {
      throw const FormatException('Invalid OR-Set delta');
    }
    try {
      final parsedAction = OrSetAction.fromWire(action);
      final encodedObserved = json['observedDots'];
      if (parsedAction == OrSetAction.add && !json.containsKey('element') ||
          parsedAction == OrSetAction.remove &&
              (encodedObserved is! List ||
                  encodedObserved.any((item) => item is! Map))) {
        throw const FormatException('Invalid OR-Set delta payload');
      }
      return OrSetDelta(
        id: _requiredString(json, 'id'),
        replicaId: _requiredString(json, 'replicaId'),
        crdtId: _requiredString(json, 'crdtId'),
        action: parsedAction,
        dot: Dot.fromJson(Map<String, Object?>.from(dot)),
        element: json['element'],
        observedDots: parsedAction == OrSetAction.remove
            ? (encodedObserved as List).map(
                (item) => Dot.fromJson(Map<String, Object?>.from(item as Map)),
              )
            : const [],
      );
    } on ArgumentError {
      throw const FormatException('Invalid OR-Set delta');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is OrSetDelta &&
      id == other.id &&
      replicaId == other.replicaId &&
      crdtId == other.crdtId &&
      action == other.action &&
      dot == other.dot &&
      (action == OrSetAction.add
          ? canonicalJsonSetKey(element) == canonicalJsonSetKey(other.element)
          : _sameDots(observedDots, other.observedDots));

  @override
  int get hashCode => Object.hash(
    id,
    replicaId,
    crdtId,
    action,
    dot,
    action == OrSetAction.add
        ? canonicalJsonSetKey(element)
        : Object.hashAll(observedDots),
  );
}

/// Observed-remove set. Each add has unique dot tag; removals retain only tags
/// they observed, so concurrent additions and later re-additions remain visible.
class OrSet implements DeltaCrdt<Set<Object?>, OrSetDelta> {
  OrSet(String replicaId, {required this.crdtId})
    : replicaId = ReplicaId(replicaId).value {
    _validateAddress(crdtId);
  }

  final String replicaId;
  final String crdtId;
  int _sequence = 0;
  final Map<Dot, OrSetDelta> _adds = {};
  final Map<Dot, OrSetDelta> _removals = {};

  @override
  Set<Object?> get value {
    final removed = _removedDots;
    final visible = <String, Object?>{};
    for (final entry in _adds.entries) {
      if (!removed.contains(entry.key)) {
        visible.putIfAbsent(
          canonicalJsonSetKey(entry.value.element),
          () => copyJsonValue(entry.value.element, freeze: true),
        );
      }
    }
    return jsonSetValueView(visible);
  }

  /// Adds [element] with a fresh dot tag and returns the transportable delta.
  OrSetDelta add(Object? element) {
    _validateJsonValue(element);
    final dot = Dot(replicaId: replicaId, counter: ++_sequence, crdtId: crdtId);
    final delta = OrSetDelta(
      id: crdtDeltaId(CrdtKind.orSet.wireName, crdtId, replicaId, dot.counter),
      replicaId: replicaId,
      crdtId: crdtId,
      action: OrSetAction.add,
      dot: dot,
      element: element,
    );
    applyDelta(delta);
    return delta;
  }

  /// Removes only add tags for [element] currently observed by this replica.
  OrSetDelta remove(Object? element) {
    _validateJsonValue(element);
    final key = canonicalJsonSetKey(element);
    final removed = _removedDots;
    final observed = [
      for (final entry in _adds.entries)
        if (!removed.contains(entry.key) &&
            canonicalJsonSetKey(entry.value.element) == key)
          entry.key,
    ];
    final dot = Dot(replicaId: replicaId, counter: ++_sequence, crdtId: crdtId);
    final delta = OrSetDelta(
      id: crdtDeltaId(CrdtKind.orSet.wireName, crdtId, replicaId, dot.counter),
      replicaId: replicaId,
      crdtId: crdtId,
      action: OrSetAction.remove,
      dot: dot,
      observedDots: observed,
    );
    applyDelta(delta);
    return delta;
  }

  @override
  void applyDelta(OrSetDelta delta) {
    _checkDelta(delta);
    final target = delta.action == OrSetAction.add ? _adds : _removals;
    if (target.containsKey(delta.dot)) return;
    target[delta.dot] = delta;
    if (delta.replicaId == replicaId && delta.dot.counter > _sequence) {
      _sequence = delta.dot.counter;
    }
  }

  void _checkDelta(OrSetDelta delta) {
    if (delta.crdtId != crdtId) {
      throw FormatException('OR-Set address does not match instance');
    }
    final sameKind = delta.action == OrSetAction.add ? _adds : _removals;
    final otherKind = delta.action == OrSetAction.add ? _removals : _adds;
    final current = sameKind[delta.dot];
    if (current != null) {
      if (current != delta) {
        throw FormatException('Conflicting OR-Set delta ID');
      }
      return;
    }
    if (otherKind.containsKey(delta.dot) ||
        delta.observedDots.any(_removals.containsKey)) {
      throw FormatException('Conflicting OR-Set dot identity');
    }
  }

  @override
  void mergeState(covariant DeltaCrdt<Set<Object?>, OrSetDelta> other) {
    final state = other as OrSet;
    if (state.crdtId != crdtId) {
      throw ArgumentError('Cannot merge OR-Sets with different addresses');
    }
    final changes = state.exportChanges().toList();
    for (final change in changes) {
      _checkDelta(change);
    }
    for (final change in changes) {
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

  factory OrSet.fromJson(Map<String, Object?> json) {
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
      throw const FormatException('Invalid OR-Set snapshot');
    }
    try {
      final restored = OrSet(replicaId, crdtId: crdtId);
      for (final item in changes) {
        if (item is! Map) {
          throw const FormatException('Invalid OR-Set snapshot');
        }
        restored.applyDelta(
          OrSetDelta.fromJson(Map<String, Object?>.from(item)),
        );
      }
      if (restored._sequence > sequence) {
        throw const FormatException('OR-Set sequence is behind its changes');
      }
      restored._sequence = sequence;
      return restored;
    } on ArgumentError {
      throw const FormatException('Invalid OR-Set snapshot');
    }
  }

  /// Exports add tags and exact removal contexts for bootstrap and merge.
  Iterable<OrSetDelta> exportChanges() sync* {
    final changes = [..._adds.values, ..._removals.values]
      ..sort((a, b) => a.id.compareTo(b.id));
    yield* changes;
  }

  Set<Dot> get _removedDots => {
    for (final removal in _removals.values) ...removal.observedDots,
  };
}

bool _sameDots(List<Dot> first, List<Dot> second) =>
    first.length == second.length && first.toSet().containsAll(second);

int _compareDots(Dot a, Dot b) => a.replicaId.compareTo(b.replicaId) != 0
    ? a.replicaId.compareTo(b.replicaId)
    : a.counter.compareTo(b.counter);

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
    throw FormatException('Invalid OR-Set $key');
  }
  return value;
}

void _validateJsonValue(Object? value) {
  try {
    copyJsonValue(value);
  } on ArgumentError {
    throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
  }
}
