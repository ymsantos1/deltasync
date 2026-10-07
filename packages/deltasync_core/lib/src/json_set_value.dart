import 'dart:collection';
import 'dart:convert';

import 'json_value.dart';

/// Shared JSON set semantics for CRDTs that store arbitrary JSON values.
List<Object?> normalizeJsonSetElements(Iterable<Object?> elements) {
  final normalized = <String, Object?>{};
  try {
    for (final element in elements) {
      final copy = copyJsonValue(element, freeze: true);
      normalized.putIfAbsent(canonicalJsonSetKey(copy), () => copy);
    }
  } on ArgumentError {
    throw ArgumentError.value(elements, 'elements', 'must be JSON-compatible');
  }
  final keys = normalized.keys.toList()..sort();
  return List<Object?>.unmodifiable([for (final key in keys) normalized[key]]);
}

String canonicalJsonSetKey(Object? value) => jsonEncode(_canonicalValue(value));

List<String> jsonSetElementKeys(Iterable<Object?> elements) =>
    elements.map(canonicalJsonSetKey).toList()..sort();

Set<Object?> jsonSetValueView(Map<String, Object?> elements) =>
    _JsonValueSet(elements);

Object? _canonicalValue(Object? value) {
  if (value is List) return [for (final item in value) _canonicalValue(item)];
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonicalValue(value[key])};
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
      return _elements.containsKey(canonicalJsonSetKey(copyJsonValue(element)));
    } on ArgumentError {
      return false;
    }
  }

  @override
  Object? lookup(Object? element) {
    try {
      return _elements[canonicalJsonSetKey(copyJsonValue(element))];
    } on ArgumentError {
      return null;
    }
  }

  @override
  Set<Object?> toSet() => {..._elements.values};

  @override
  bool add(Object? value) => throw UnsupportedError('CRDT value is read-only');

  @override
  bool remove(Object? value) =>
      throw UnsupportedError('CRDT value is read-only');

  @override
  void clear() => throw UnsupportedError('CRDT value is read-only');
}
