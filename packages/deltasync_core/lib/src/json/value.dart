import 'dart:collection';

/// Copies JSON-compatible values, optionally freezing every nested collection.
///
/// Rejects non-string map keys, non-finite numbers, and non-JSON objects.
Object? copyJsonValue(Object? value, {bool freeze = false}) => _visitJsonValue(
  value,
  freeze ? _JsonAction.freeze : _JsonAction.copy,
  HashSet<Object>.identity(),
);

/// Internal validation using the same rules as copying, without constructing
/// copied JSON containers or an encoded string. Shared DAGs are valid; cycles aren't.
void validateJsonValue(Object? value) {
  _visitJsonValue(value, _JsonAction.validate, HashSet<Object>.identity());
}

enum _JsonAction { copy, freeze, validate }

Object? _visitJsonValue(
  Object? value,
  _JsonAction action,
  Set<Object> ancestors,
) {
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
      if (action == _JsonAction.validate) {
        for (final item in value) {
          _visitJsonValue(item, action, ancestors);
        }
        return value;
      }
      final copy = value.map(
        (item) => _visitJsonValue(item, action, ancestors),
      );
      return action == _JsonAction.freeze
          ? List<Object?>.unmodifiable(copy)
          : copy.toList();
    } finally {
      ancestors.remove(value);
    }
  }
  if (value is Map) {
    if (!ancestors.add(value)) {
      throw ArgumentError.value(value, 'value', 'must not contain cycles');
    }
    final copy = action == _JsonAction.validate ? null : <String, Object?>{};
    try {
      for (final entry in value.entries) {
        if (entry.key is! String) throw ArgumentError.value(value, 'value');
        final item = _visitJsonValue(entry.value, action, ancestors);
        if (copy != null) copy[entry.key as String] = item;
      }
      if (copy == null) return value;
      return action == _JsonAction.freeze
          ? Map<String, Object?>.unmodifiable(copy)
          : copy;
    } finally {
      ancestors.remove(value);
    }
  }
  throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
}
