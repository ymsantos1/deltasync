import '../identity.dart';

/// Internal exact causal context, scoped to one CRDT address. Prefixes encode
/// only contiguous observation; sparse counters preserve every remaining gap.
/// Owns membership, union and both legacy/compact JSON readers.
class DotContext {
  DotContext(this.crdtId) : _prefixes = {}, _sparse = {};

  DotContext._(this.crdtId, this._prefixes, this._sparse);

  final String crdtId;
  final Map<String, int> _prefixes;
  final Map<String, Set<int>> _sparse;

  factory DotContext.decode(
    Object? encoded,
    String crdtId, {
    bool allowCompactContext = true,
  }) {
    if (encoded is List) {
      return DotContext.fromDots(
        crdtId,
        encoded.map((item) {
          if (item is! Map) {
            throw const FormatException('Invalid MV-Register context');
          }
          return Dot.fromJson(Map<String, Object?>.from(item));
        }),
      );
    }
    if (allowCompactContext && encoded is Map) {
      return DotContext.fromJson(Map<String, Object?>.from(encoded), crdtId);
    }
    throw const FormatException('Invalid MV-Register context');
  }

  factory DotContext.fromDots(String crdtId, Iterable<Dot> dots) {
    final context = DotContext(crdtId);
    for (final dot in dots) {
      if (dot.crdtId != crdtId ||
          dot.replicaId.isEmpty ||
          dot.replicaId.trim() != dot.replicaId ||
          dot.counter <= 0) {
        throw ArgumentError('Invalid MV-Register context dot');
      }
      context.add(dot);
    }
    return context;
  }

  factory DotContext.fromJson(Map<String, Object?> json, String crdtId) {
    final encodedReplicas = json['replicas'];
    if (json['crdtId'] != crdtId || encodedReplicas is! Map) {
      throw const FormatException('Invalid compact MV-Register context');
    }
    final context = DotContext(crdtId);
    for (final entry in encodedReplicas.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid compact MV-Register context');
      }
      final replicaId = entry.key as String;
      final encoded = Map<String, Object?>.from(entry.value as Map);
      final prefix = encoded['prefix'];
      final sparse = encoded['sparse'];
      if (replicaId.isEmpty ||
          replicaId.trim() != replicaId ||
          prefix is! int ||
          prefix < 0 ||
          sparse is! List ||
          sparse.any((counter) => counter is! int || counter <= prefix)) {
        throw const FormatException('Invalid compact MV-Register context');
      }
      final sparseCounters = sparse.cast<int>();
      if (sparseCounters.toSet().length != sparseCounters.length ||
          !_isSorted(sparseCounters)) {
        throw const FormatException('Invalid compact MV-Register context');
      }
      if (prefix > 0 || sparseCounters.isNotEmpty) {
        context._prefixes[replicaId] = prefix;
        if (sparseCounters.isNotEmpty) {
          context._sparse[replicaId] = sparseCounters.toSet();
        }
      }
      if (sparseCounters.contains(prefix + 1)) {
        throw const FormatException(
          'Non-canonical compact MV-Register context',
        );
      }
    }
    return context;
  }

  DotContext copy() => DotContext._(crdtId, Map<String, int>.of(_prefixes), {
    for (final entry in _sparse.entries) entry.key: Set<int>.of(entry.value),
  });

  void add(Dot dot) {
    if (dot.crdtId != crdtId) {
      throw ArgumentError('MV-Register context address mismatch');
    }
    final prefix = _prefixes[dot.replicaId] ?? 0;
    if (dot.counter <= prefix) return;
    final sparse = _sparse.putIfAbsent(dot.replicaId, () => <int>{});
    sparse.add(dot.counter);
    var next = prefix + 1;
    while (sparse.remove(next)) {
      _prefixes[dot.replicaId] = next;
      next++;
    }
    if (sparse.isEmpty) _sparse.remove(dot.replicaId);
  }

  void addAll(DotContext other) {
    if (other.crdtId != crdtId) {
      throw ArgumentError('MV-Register context address mismatch');
    }
    for (final replicaId in {
      ..._prefixes.keys,
      ..._sparse.keys,
      ...other._prefixes.keys,
      ...other._sparse.keys,
    }) {
      final prefix = _maxOf(
        _prefixes[replicaId] ?? 0,
        other._prefixes[replicaId] ?? 0,
      );
      final sparse = <int>{...?_sparse[replicaId], ...?other._sparse[replicaId]}
        ..removeWhere((counter) => counter <= prefix);
      var compactPrefix = prefix;
      while (sparse.remove(compactPrefix + 1)) {
        compactPrefix++;
      }
      if (compactPrefix == 0) {
        _prefixes.remove(replicaId);
      } else {
        _prefixes[replicaId] = compactPrefix;
      }
      if (sparse.isEmpty) {
        _sparse.remove(replicaId);
      } else {
        _sparse[replicaId] = sparse;
      }
    }
  }

  bool contains(Dot dot) {
    if (dot.crdtId != crdtId) return false;
    return dot.counter <= (_prefixes[dot.replicaId] ?? 0) ||
        (_sparse[dot.replicaId]?.contains(dot.counter) ?? false);
  }

  bool containsAll(DotContext other) {
    if (other.crdtId != crdtId) return false;
    for (final entry in other._prefixes.entries) {
      if ((_prefixes[entry.key] ?? 0) < entry.value) return false;
    }
    for (final entry in other._sparse.entries) {
      if (entry.value.any(
        (counter) => !contains(
          Dot(replicaId: entry.key, counter: counter, crdtId: crdtId),
        ),
      )) {
        return false;
      }
    }
    return true;
  }

  int highestCounter(String replicaId) {
    final sparse = _sparse[replicaId];
    if (sparse == null || sparse.isEmpty) return _prefixes[replicaId] ?? 0;
    return _maxOf(_prefixes[replicaId] ?? 0, sparse.reduce(_maxOf));
  }

  List<Dot> toDots() {
    final dots = <Dot>[];
    for (final replicaId in {..._prefixes.keys, ..._sparse.keys}) {
      final prefix = _prefixes[replicaId] ?? 0;
      dots.addAll(
        Iterable<int>.generate(prefix, (index) => index + 1).map(
          (counter) =>
              Dot(replicaId: replicaId, counter: counter, crdtId: crdtId),
        ),
      );
      for (final counter in _sparse[replicaId] ?? const <int>{}) {
        dots.add(Dot(replicaId: replicaId, counter: counter, crdtId: crdtId));
      }
    }
    dots.sort(_compareDots);
    return List.unmodifiable(dots);
  }

  List<String> _sortedReplicaIds() =>
      ({..._prefixes.keys, ..._sparse.keys}.toList()..sort());

  Map<String, Object?> toJson() => {
    'crdtId': crdtId,
    'replicas': {
      for (final replicaId in _sortedReplicaIds())
        replicaId: {
          'prefix': _prefixes[replicaId] ?? 0,
          'sparse': (_sparse[replicaId]?.toList() ?? <int>[])..sort(),
        },
    },
  };
}

bool _isSorted(List<int> values) {
  for (var index = 1; index < values.length; index++) {
    if (values[index - 1] >= values[index]) return false;
  }
  return true;
}

int _maxOf(int a, int b) => a > b ? a : b;

int _compareDots(Dot a, Dot b) => a.replicaId.compareTo(b.replicaId) != 0
    ? a.replicaId.compareTo(b.replicaId)
    : a.counter.compareTo(b.counter);
