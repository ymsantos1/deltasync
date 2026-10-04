import 'dart:collection';

/// Copies JSON-compatible values, optionally freezing every nested collection.
///
/// Rejects non-string map keys, non-finite numbers, and non-JSON objects.
Object? copyJsonValue(Object? value, {bool freeze = false}) =>
    _copyJsonValue(value, freeze, HashSet<Object>.identity());

Object? _copyJsonValue(Object? value, bool freeze, Set<Object> ancestors) {
  if (value == null || value is String || value is bool) return value;
  if (value is num) {
    if (!value.isFinite) throw ArgumentError.value(value, 'value');
    return value;
  }
  if (value is List) {
    if (!ancestors.add(value)) {
      throw ArgumentError.value(value, 'value', 'must not contain cycles');
    }
    try {
      final copy = value.map((item) => _copyJsonValue(item, freeze, ancestors));
      return freeze ? List<Object?>.unmodifiable(copy) : copy.toList();
    } finally {
      ancestors.remove(value);
    }
  }
  if (value is Map) {
    if (!ancestors.add(value)) {
      throw ArgumentError.value(value, 'value', 'must not contain cycles');
    }
    final copy = <String, Object?>{};
    try {
      for (final entry in value.entries) {
        if (entry.key is! String) throw ArgumentError.value(value, 'value');
        copy[entry.key as String] = _copyJsonValue(
          entry.value,
          freeze,
          ancestors,
        );
      }
      return freeze ? Map<String, Object?>.unmodifiable(copy) : copy;
    } finally {
      ancestors.remove(value);
    }
  }
  throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
}
