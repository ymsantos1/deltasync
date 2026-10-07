import 'dart:convert';

import 'crdt.dart';
import 'delta_change.dart';
import 'g_set.dart';
import 'identity.dart';
import 'json_set_value.dart';
import 'json_value.dart';

/// Operation carried by an OR-Map delta.
enum OrMapAction {
  addKey('add-key'),
  removeKey('remove-key'),
  addValue('add-value');

  const OrMapAction(this.wireName);

  final String wireName;

  static OrMapAction fromWire(String value) => switch (value) {
    'add-key' => OrMapAction.addKey,
    'remove-key' => OrMapAction.removeKey,
    'add-value' => OrMapAction.addValue,
    _ => throw FormatException('Unsupported OR-Map action'),
  };
}

/// One key tag, exact observed removal, or update to a key's nested G-Set.
class OrMapDelta implements DeltaChange {
  OrMapDelta({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required this.action,
    required this.dot,
    required this.key,
    Iterable<Dot> observedDots = const [],
    this.keyDot,
    this.valueChange,
  }) : observedDots = List.unmodifiable(
         observedDots.toSet().toList()..sort(_compareDots),
       ) {
    _validateKey(key);
    if (id.isEmpty ||
        id.trim() != id ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        crdtId.isEmpty ||
        crdtId.trim() != crdtId ||
        crdtId.startsWith('legacy/') ||
        dot.counter <= 0 ||
        dot.replicaId != replicaId ||
        dot.crdtId != crdtId ||
        id !=
            crdtDeltaId(
              CrdtKind.orMap.wireName,
              crdtId,
              replicaId,
              dot.counter,
            )) {
      throw ArgumentError('Invalid OR-Map delta identity');
    }
    final validShape = switch (action) {
      OrMapAction.addKey =>
        this.observedDots.isEmpty && keyDot == null && valueChange == null,
      OrMapAction.removeKey => keyDot == null && valueChange == null,
      OrMapAction.addValue =>
        this.observedDots.isEmpty && keyDot != null && valueChange != null,
    };
    if (!validShape ||
        this.observedDots.any(
          (item) =>
              item.crdtId != crdtId ||
              item.replicaId.isEmpty ||
              item.replicaId.trim() != item.replicaId ||
              item.counter <= 0 ||
              item == dot,
        )) {
      throw ArgumentError('Invalid OR-Map delta payload');
    }
    if (action == OrMapAction.addValue) {
      final nestedKeyDot = keyDot;
      final nestedChange = valueChange;
      if (nestedKeyDot == null ||
          nestedChange == null ||
          nestedKeyDot.crdtId != crdtId ||
          nestedKeyDot.replicaId.isEmpty ||
          nestedKeyDot.replicaId.trim() != nestedKeyDot.replicaId ||
          nestedKeyDot.counter <= 0 ||
          nestedKeyDot == dot ||
          nestedChange.crdtId != _valueAddress(crdtId, key, nestedKeyDot) ||
          nestedChange.replicaId != replicaId) {
        throw ArgumentError('Invalid OR-Map nested value identity');
      }
    }
  }

  @override
  final String id;
  @override
  final String replicaId;
  @override
  final String crdtId;
  final OrMapAction action;
  final Dot dot;
  final String key;
  final List<Dot> observedDots;
  final Dot? keyDot;
  final GSetDelta? valueChange;

  @override
  CrdtKind get kind => CrdtKind.orMap;

  @override
  Map<String, Object?> toJson() => {
    'type': kind.wireName,
    'id': id,
    'replicaId': replicaId,
    'crdtId': crdtId,
    'action': action.wireName,
    'dot': dot.toJson(),
    'key': key,
    if (action == OrMapAction.removeKey)
      'observedDots': [for (final item in observedDots) item.toJson()],
    if (action == OrMapAction.addValue) ...{
      'keyDot': keyDot!.toJson(),
      'valueChange': valueChange!.toJson(),
    },
  };

  factory OrMapDelta.fromJson(Map<String, Object?> json) {
    final action = json['action'];
    final dot = json['dot'];
    final observed = json['observedDots'];
    final keyDot = json['keyDot'];
    final valueChange = json['valueChange'];
    if (action is! String || dot is! Map) {
      throw const FormatException('Invalid OR-Map delta');
    }
    try {
      final parsedAction = OrMapAction.fromWire(action);
      if (parsedAction == OrMapAction.removeKey &&
              (observed is! List || observed.any((item) => item is! Map)) ||
          parsedAction == OrMapAction.addValue &&
              (keyDot is! Map || valueChange is! Map) ||
          parsedAction == OrMapAction.addKey &&
              (observed != null || keyDot != null || valueChange != null) ||
          parsedAction == OrMapAction.removeKey &&
              (keyDot != null || valueChange != null) ||
          parsedAction == OrMapAction.addValue && observed != null) {
        throw const FormatException('Invalid OR-Map delta payload');
      }
      return OrMapDelta(
        id: _requiredString(json, 'id'),
        replicaId: _requiredString(json, 'replicaId'),
        crdtId: _requiredString(json, 'crdtId'),
        action: parsedAction,
        dot: Dot.fromJson(Map<String, Object?>.from(dot)),
        key: _requiredString(json, 'key'),
        observedDots: parsedAction == OrMapAction.removeKey
            ? (observed as List).map(
                (item) => Dot.fromJson(Map<String, Object?>.from(item as Map)),
              )
            : const [],
        keyDot: parsedAction == OrMapAction.addValue
            ? Dot.fromJson(Map<String, Object?>.from(keyDot as Map))
            : null,
        valueChange: parsedAction == OrMapAction.addValue
            ? GSetDelta.fromJson(Map<String, Object?>.from(valueChange as Map))
            : null,
      );
    } on ArgumentError {
      throw const FormatException('Invalid OR-Map delta');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is OrMapDelta &&
      id == other.id &&
      replicaId == other.replicaId &&
      crdtId == other.crdtId &&
      action == other.action &&
      dot == other.dot &&
      key == other.key &&
      _sameDots(observedDots, other.observedDots) &&
      keyDot == other.keyDot &&
      valueChange == other.valueChange;

  @override
  int get hashCode => Object.hash(
    id,
    replicaId,
    crdtId,
    action,
    dot,
    key,
    Object.hashAll(observedDots),
    keyDot,
    valueChange,
  );
}

/// Add-wins map whose value at each key incarnation is a grow-only set.
///
/// Key presence is controlled only by add/remove key deltas. Value updates
/// union through G-Set; they do not recreate a removed key. Each key tag owns
/// one nested G-Set, so old value deltas remain hidden after removal/recreation.
class OrMap implements DeltaCrdt<Map<String, Set<Object?>>, OrMapDelta> {
  OrMap(String replicaId, {required this.crdtId})
    : replicaId = ReplicaId(replicaId).value {
    _validateAddress(crdtId);
  }

  final String replicaId;
  final String crdtId;
  int _sequence = 0;
  final Map<Dot, OrMapDelta> _keyAdds = {};
  final Map<Dot, OrMapDelta> _keyRemovals = {};
  final Map<Dot, OrMapDelta> _valueChanges = {};
  final Map<Dot, GSet> _values = {};

  @override
  Map<String, Set<Object?>> get value {
    final result = <String, Set<Object?>>{};
    for (final add in _keyAdds.values) {
      if (_removedDots.contains(add.dot)) continue;
      final elements = <String, Object?>{};
      for (final tag in _activeTags(add.key)) {
        for (final element in _values[tag]?.value ?? const <Object?>{}) {
          elements.putIfAbsent(canonicalJsonSetKey(element), () => element);
        }
      }
      result[add.key] = jsonSetValueView(elements);
    }
    return Map.unmodifiable(result);
  }

  /// Adds a fresh key incarnation and returns its key-presence delta.
  OrMapDelta addKey(String key) {
    _validateKey(key);
    final dot = _nextDot();
    final delta = OrMapDelta(
      id: _deltaId(dot),
      replicaId: replicaId,
      crdtId: crdtId,
      action: OrMapAction.addKey,
      dot: dot,
      key: key,
    );
    applyDelta(delta);
    return delta;
  }

  /// Removes only key incarnations currently observed for [key].
  OrMapDelta removeKey(String key) {
    _validateKey(key);
    final dot = _nextDot();
    final delta = OrMapDelta(
      id: _deltaId(dot),
      replicaId: replicaId,
      crdtId: crdtId,
      action: OrMapAction.removeKey,
      dot: dot,
      key: key,
      observedDots: _activeTags(key),
    );
    applyDelta(delta);
    return delta;
  }

  /// Adds [element] to each observed G-Set value for [key].
  List<OrMapDelta> addValue(String key, Object? element) {
    _validateKey(key);
    _validateJsonValue(element);
    final tags = _activeTags(key);
    if (tags.isEmpty) throw StateError('OR-Map key is not present');
    return [for (final tag in tags) _addValueForTag(key, tag, element)];
  }

  OrMapDelta _addValueForTag(String key, Dot tag, Object? element) {
    final state = _values.putIfAbsent(
      tag,
      () => GSet(replicaId, crdtId: _valueAddress(crdtId, key, tag)),
    );
    final nested = state.add(element);
    final dot = _nextDot();
    final delta = OrMapDelta(
      id: _deltaId(dot),
      replicaId: replicaId,
      crdtId: crdtId,
      action: OrMapAction.addValue,
      dot: dot,
      key: key,
      keyDot: tag,
      valueChange: nested,
    );
    applyDelta(delta);
    return delta;
  }

  @override
  void applyDelta(OrMapDelta delta) {
    _checkDelta(delta);
    switch (delta.action) {
      case OrMapAction.addKey:
        _keyAdds[delta.dot] = delta;
      case OrMapAction.removeKey:
        _keyRemovals[delta.dot] = delta;
      case OrMapAction.addValue:
        final tag = delta.keyDot!;
        final current = _values[tag];
        final candidate = current == null
            ? GSet(replicaId, crdtId: _valueAddress(crdtId, delta.key, tag))
            : GSet.fromJson(current.toJson());
        candidate.applyDelta(delta.valueChange!);
        _valueChanges[delta.dot] = delta;
        _values[tag] = candidate;
    }
    if (delta.replicaId == replicaId && delta.dot.counter > _sequence) {
      _sequence = delta.dot.counter;
    }
  }

  void _checkDelta(OrMapDelta delta) {
    if (delta.crdtId != crdtId) {
      throw FormatException('OR-Map address does not match instance');
    }
    final sameKind = switch (delta.action) {
      OrMapAction.addKey => _keyAdds,
      OrMapAction.removeKey => _keyRemovals,
      OrMapAction.addValue => _valueChanges,
    };
    final otherKinds = <Dot>{
      if (delta.action != OrMapAction.addKey) ..._keyAdds.keys,
      if (delta.action != OrMapAction.removeKey) ..._keyRemovals.keys,
      if (delta.action != OrMapAction.addValue) ..._valueChanges.keys,
    };
    final current = sameKind[delta.dot];
    if (current != null) {
      if (current != delta) {
        throw FormatException('Conflicting OR-Map delta ID');
      }
      return;
    }
    if (otherKinds.contains(delta.dot) ||
        (delta.action != OrMapAction.addKey &&
            _valueChanges.values.any((change) => change.keyDot == delta.dot)) ||
        delta.observedDots.any(
          (dot) =>
              _keyRemovals.containsKey(dot) || _valueChanges.containsKey(dot),
        )) {
      throw FormatException('Conflicting OR-Map dot identity');
    }
    if (delta.action == OrMapAction.addKey) {
      for (final removal in _keyRemovals.values) {
        if (removal.observedDots.contains(delta.dot) &&
            removal.key != delta.key) {
          throw FormatException('OR-Map removal key does not match key tag');
        }
      }
      for (final update in _valueChanges.values) {
        if (update.keyDot == delta.dot && update.key != delta.key) {
          throw FormatException('OR-Map value key does not match key tag');
        }
      }
    } else if (delta.action == OrMapAction.removeKey) {
      for (final dot in delta.observedDots) {
        final add = _keyAdds[dot];
        if (add != null && add.key != delta.key) {
          throw FormatException('OR-Map removal key does not match key tag');
        }
        if (_valueChanges.values.any(
          (update) => update.keyDot == dot && update.key != delta.key,
        )) {
          throw FormatException('OR-Map removal key does not match key tag');
        }
      }
    } else {
      final keyDot = delta.keyDot!;
      final add = _keyAdds[keyDot];
      if (_keyRemovals.containsKey(keyDot) ||
          _valueChanges.containsKey(keyDot) ||
          _removedDots.contains(delta.dot) ||
          (add != null && add.key != delta.key)) {
        throw FormatException('OR-Map value does not match key tag');
      }
    }
  }

  Set<Dot> _activeTags(String key) => {
    for (final add in _keyAdds.values)
      if (add.key == key && !_removedDots.contains(add.dot)) add.dot,
  };

  Set<Dot> get _removedDots => {
    for (final removal in _keyRemovals.values) ...removal.observedDots,
  };

  Dot _nextDot() =>
      Dot(replicaId: replicaId, counter: ++_sequence, crdtId: crdtId);

  String _deltaId(Dot dot) =>
      crdtDeltaId(CrdtKind.orMap.wireName, crdtId, replicaId, dot.counter);

  @override
  void mergeState(
    covariant DeltaCrdt<Map<String, Set<Object?>>, OrMapDelta> other,
  ) {
    final state = other as OrMap;
    if (state.crdtId != crdtId) {
      throw ArgumentError('Cannot merge OR-Maps with different addresses');
    }
    final candidate = OrMap.fromJson(toJson());
    for (final change in state.exportChanges()) {
      candidate.applyDelta(change);
    }
    if (state.replicaId == replicaId && state._sequence > candidate._sequence) {
      candidate._sequence = state._sequence;
    }
    _keyAdds
      ..clear()
      ..addAll(candidate._keyAdds);
    _keyRemovals
      ..clear()
      ..addAll(candidate._keyRemovals);
    _valueChanges
      ..clear()
      ..addAll(candidate._valueChanges);
    _values
      ..clear()
      ..addAll(candidate._values);
    _sequence = candidate._sequence;
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'crdtId': crdtId,
    'sequence': _sequence,
    'changes': [for (final change in exportChanges()) change.toJson()],
  };

  factory OrMap.fromJson(Map<String, Object?> json) {
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
      throw const FormatException('Invalid OR-Map snapshot');
    }
    try {
      final restored = OrMap(replicaId, crdtId: crdtId);
      for (final item in changes) {
        if (item is! Map) {
          throw const FormatException('Invalid OR-Map snapshot');
        }
        restored.applyDelta(
          OrMapDelta.fromJson(Map<String, Object?>.from(item)),
        );
      }
      if (restored._sequence > sequence) {
        throw const FormatException('OR-Map sequence is behind its changes');
      }
      restored._sequence = sequence;
      return restored;
    } on ArgumentError {
      throw const FormatException('Invalid OR-Map snapshot');
    }
  }

  Iterable<OrMapDelta> exportChanges() sync* {
    final changes = [
      ..._keyAdds.values,
      ..._keyRemovals.values,
      ..._valueChanges.values,
    ]..sort((a, b) => a.id.compareTo(b.id));
    yield* changes;
  }
}

String _valueAddress(String mapId, String key, Dot tag) =>
    'or-map-value:${jsonEncode([mapId, key, tag.replicaId, tag.counter])}';

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

void _validateKey(String key) {
  if (key.isEmpty || key.trim() != key) throw ArgumentError.value(key, 'key');
}

void _validateJsonValue(Object? value) {
  try {
    copyJsonValue(value);
  } on ArgumentError {
    throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw FormatException('Invalid OR-Map $key');
  }
  return value;
}
