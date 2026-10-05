import 'dart:collection';
import 'dart:convert';

import 'crdt.dart';
import 'delta_change.dart';
import 'identity.dart';
import 'json_value.dart';

/// One batch of values added to an addressed G-Set.
class GSetDelta implements DeltaChange {
  GSetDelta({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required Iterable<Object?> elements,
    required this.dot,
  }) : elements = _normalizeElements(elements) {
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
        crdtDeltaId(CrdtKind.gSet.wireName, crdtId, replicaId, dot.counter)) {
      throw ArgumentError.value(id, 'id', 'does not match G-Set dot');
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
  final List<Object?> elements;
  final Dot dot;

  @override
  CrdtKind get kind => CrdtKind.gSet;

  String get type => kind.wireName;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'id': id,
    'replicaId': replicaId,
    'crdtId': crdtId,
    'elements': copyJsonValue(elements),
    'dot': dot.toJson(),
  };

  factory GSetDelta.fromJson(Map<String, Object?> json) {
    final id = _requiredString(json, 'id');
    final replicaId = _requiredString(json, 'replicaId');
    final crdtId = _requiredString(json, 'crdtId');
    final elements = json['elements'];
    final dot = json['dot'];
    if (elements is! List || dot is! Map) {
      throw FormatException('Invalid G-Set delta');
    }
    try {
      return GSetDelta(
        id: id,
        replicaId: replicaId,
        crdtId: crdtId,
        elements: elements,
        dot: Dot.fromJson(Map<String, Object?>.from(dot)),
      );
    } on ArgumentError {
      throw FormatException('Invalid G-Set delta');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is GSetDelta &&
      id == other.id &&
      replicaId == other.replicaId &&
      crdtId == other.crdtId &&
      dot == other.dot &&
      _elementKeys(elements).join('\u0000') ==
          _elementKeys(other.elements).join('\u0000');

  @override
  int get hashCode => Object.hash(
    id,
    replicaId,
    crdtId,
    dot,
    Object.hashAll(_elementKeys(elements)),
  );
}

/// Grow-only set of JSON values, identified by a stable application address.
///
/// Each add creates an addressed event so callers can persist and exchange the
/// incremental additions. State merge unions events; [value] deduplicates equal
/// JSON values. Repeated adds are harmless and never remove existing values;
/// events that add no new value do not enlarge materialized state.
class GSet implements DeltaCrdt<Set<Object?>, GSetDelta> {
  GSet(String replicaId, {required this.crdtId})
    : replicaId = ReplicaId(replicaId).value {
    _validateAddress(crdtId);
  }

  final String replicaId;
  final String crdtId;
  final Map<String, _GSetEntry> _entries = {};
  int _sequence = 0;

  @override
  Set<Object?> get value {
    final elements = <String, Object?>{};
    for (final entry in _entries.entries) {
      elements[entry.key] = entry.value.element;
    }
    return _JsonValueSet(elements);
  }

  /// Adds [element] and returns its incremental change.
  GSetDelta add(Object? element) => addAll([element]);

  /// Adds [elements] as one incremental change.
  GSetDelta addAll(Iterable<Object?> elements) {
    final additions = _normalizeElements(elements);
    if (additions.isEmpty) {
      throw ArgumentError.value(elements, 'elements', 'must not be empty');
    }
    final novel = additions
        .where((element) => !_entries.containsKey(_canonicalJson(element)))
        .toList();
    final dot = Dot(replicaId: replicaId, counter: ++_sequence, crdtId: crdtId);
    final delta = GSetDelta(
      id: crdtDeltaId(CrdtKind.gSet.wireName, crdtId, replicaId, dot.counter),
      replicaId: replicaId,
      crdtId: crdtId,
      elements: novel.isEmpty ? additions : novel,
      dot: dot,
    );
    if (novel.isNotEmpty) applyDelta(delta);
    return delta;
  }

  @override
  void applyDelta(GSetDelta delta) {
    if (delta.crdtId != crdtId) {
      throw FormatException('G-Set address does not match instance');
    }
    for (final entry in _entries.values) {
      if (entry.change.id == delta.id && entry.change != delta) {
        throw FormatException('Conflicting G-Set delta ID');
      }
    }
    for (final element in delta.elements) {
      final key = _canonicalJson(element);
      final current = _entries[key];
      if (current == null || delta.id.compareTo(current.change.id) < 0) {
        _entries[key] = _GSetEntry(element, delta);
      }
    }
    if (delta.replicaId == replicaId && delta.dot.counter > _sequence) {
      _sequence = delta.dot.counter;
    }
  }

  @override
  void mergeState(covariant DeltaCrdt<Set<Object?>, GSetDelta> other) {
    final state = other as GSet;
    if (state.crdtId != crdtId) {
      throw ArgumentError('Cannot merge G-Sets with different addresses');
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

  factory GSet.fromJson(Map<String, Object?> json) {
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
      throw FormatException('Invalid G-Set snapshot');
    }
    try {
      final restored = GSet(replicaId, crdtId: crdtId);
      for (final item in changes) {
        if (item is! Map) throw FormatException('Invalid G-Set snapshot');
        restored.applyDelta(
          GSetDelta.fromJson(Map<String, Object?>.from(item)),
        );
      }
      if (restored._sequence > sequence) {
        throw FormatException('G-Set sequence is behind its changes');
      }
      restored._sequence = sequence;
      return restored;
    } on ArgumentError {
      throw FormatException('Invalid G-Set snapshot');
    }
  }

  /// Returns additions needed to bootstrap or reconcile materialized state.
  Iterable<GSetDelta> exportChanges() sync* {
    final changes =
        _entries.values.map((entry) => entry.change).toSet().toList()
          ..sort((first, second) => first.id.compareTo(second.id));
    yield* changes;
  }
}

class _GSetEntry {
  const _GSetEntry(this.element, this.change);

  final Object? element;
  final GSetDelta change;
}

List<Object?> _normalizeElements(Iterable<Object?> elements) {
  final normalized = <String, Object?>{};
  try {
    for (final element in elements) {
      final copy = copyJsonValue(element, freeze: true);
      normalized.putIfAbsent(_canonicalJson(copy), () => copy);
    }
  } on ArgumentError {
    throw ArgumentError.value(elements, 'elements', 'must be JSON-compatible');
  }
  final keys = normalized.keys.toList()..sort();
  return List<Object?>.unmodifiable([for (final key in keys) normalized[key]]);
}

List<String> _elementKeys(Iterable<Object?> elements) =>
    elements.map(_canonicalJson).toList()..sort();

String _canonicalJson(Object? value) => jsonEncode(_canonicalValue(value));

Object? _canonicalValue(Object? value) {
  if (value is List) return [for (final item in value) _canonicalValue(item)];
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonicalValue(value[key])};
  }
  return value;
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
    throw FormatException('Invalid G-Set $key');
  }
  return value;
}

class _JsonValueSet extends SetBase<Object?> {
  _JsonValueSet(this._elements);

  final Map<String, Object?> _elements;

  @override
  int get length => _elements.length;

  @override
  Iterator<Object?> get iterator => _elements.values.iterator;

  @override
  bool contains(Object? element) {
    try {
      return _elements.containsKey(_canonicalJson(element));
    } on ArgumentError {
      return false;
    }
  }

  @override
  Object? lookup(Object? element) {
    try {
      return _elements[_canonicalJson(element)];
    } on ArgumentError {
      return null;
    }
  }

  @override
  Set<Object?> toSet() => {..._elements.values};

  @override
  bool add(Object? value) => throw UnsupportedError('G-Set value is read-only');

  @override
  bool remove(Object? value) =>
      throw UnsupportedError('G-Set value is read-only');

  @override
  void clear() => throw UnsupportedError('G-Set value is read-only');
}
