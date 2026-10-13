import 'crdt.dart';
import 'delta_change.dart';
import 'identity.dart';
import 'json_value.dart';
import 'json_set_value.dart';

/// One write and the exact causal dots it had observed.
class MvRegisterDelta implements DeltaChange {
  MvRegisterDelta({
    required String id,
    required String replicaId,
    required String crdtId,
    required Dot dot,
    required Object? value,
    required Iterable<Dot> context,
  }) : this._(
         id: id,
         replicaId: replicaId,
         crdtId: crdtId,
         dot: dot,
         value: value,
         context: _CompactDotContext.fromDots(crdtId, context),
       );

  MvRegisterDelta._({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required this.dot,
    required Object? value,
    required _CompactDotContext context,
  }) : value = copyJsonValue(value, freeze: true),
       _context = context.copy() {
    _validateAddress(crdtId);
    if (replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        dot.replicaId != replicaId ||
        dot.crdtId != crdtId ||
        dot.counter <= 0 ||
        id !=
            crdtDeltaId(
              CrdtKind.mvRegister.wireName,
              crdtId,
              replicaId,
              dot.counter,
            ) ||
        _context.crdtId != crdtId ||
        _context.contains(dot)) {
      throw ArgumentError('Invalid MV-Register delta identity or context');
    }
    _validateJsonValue(this.value);
  }

  @override
  final String id;
  @override
  final String replicaId;
  @override
  final String crdtId;
  final Dot dot;
  final Object? value;
  final _CompactDotContext _context;

  /// Exact observed dots. Access expands compact prefixes into a list.
  List<Dot> get context => _context.toDots();
  @override
  CrdtKind get kind => CrdtKind.mvRegister;

  @override
  Map<String, Object?> toJson() => {
    'type': kind.wireName,
    'id': id,
    'replicaId': replicaId,
    'crdtId': crdtId,
    'dot': dot.toJson(),
    'value': copyJsonValue(value),
    'context': _context.toJson(),
  };

  factory MvRegisterDelta.fromJson(
    Map<String, Object?> json, {
    bool allowCompactContext = true,
  }) {
    final dot = json['dot'];
    final context = json['context'];
    if (dot is! Map ||
        context is! List && (!allowCompactContext || context is! Map)) {
      throw const FormatException('Invalid MV-Register delta');
    }
    try {
      final crdtId = _requiredString(json, 'crdtId');
      final causalContext = context is List
          ? _CompactDotContext.fromDots(
              crdtId,
              context.map((item) {
                if (item is! Map) {
                  throw const FormatException('Invalid MV-Register context');
                }
                return Dot.fromJson(Map<String, Object?>.from(item));
              }),
            )
          : _CompactDotContext.fromJson(
              Map<String, Object?>.from(context as Map),
              crdtId,
            );
      return MvRegisterDelta._(
        id: _requiredString(json, 'id'),
        replicaId: _requiredString(json, 'replicaId'),
        crdtId: crdtId,
        dot: Dot.fromJson(Map<String, Object?>.from(dot)),
        value: json['value'],
        context: causalContext,
      );
    } on ArgumentError {
      throw const FormatException('Invalid MV-Register delta');
    }
  }
}

/// Multi-value register. Exact observed dots preserve causality across gaps.
class MvRegister implements DeltaCrdt<Set<Object?>, MvRegisterDelta> {
  MvRegister(String replicaId, {required this.crdtId})
    : replicaId = ReplicaId(replicaId).value {
    _validateAddress(crdtId);
  }

  final String replicaId;
  final String crdtId;
  int _sequence = 0;
  late final _CompactDotContext _context = _CompactDotContext(crdtId);
  final Map<Dot, _MvVersion> _versions = {};

  @override
  Set<Object?> get value {
    final visible = <String, Object?>{};
    for (final version in _versions.values) {
      visible.putIfAbsent(
        canonicalJsonSetKey(version.value),
        () => copyJsonValue(version.value, freeze: true),
      );
    }
    return jsonSetValueView(visible);
  }

  /// Writes value, replacing only versions whose dots this replica observed.
  MvRegisterDelta write(Object? value) {
    _validateJsonValue(value);
    final dot = Dot(replicaId: replicaId, counter: ++_sequence, crdtId: crdtId);
    final delta = MvRegisterDelta._(
      id: crdtDeltaId(kind.wireName, crdtId, replicaId, dot.counter),
      replicaId: replicaId,
      crdtId: crdtId,
      dot: dot,
      value: value,
      context: _context,
    );
    applyDelta(delta);
    return delta;
  }

  @override
  void applyDelta(MvRegisterDelta delta) {
    if (delta.crdtId != crdtId) {
      throw FormatException('MV-Register address does not match instance');
    }
    final old = _versions[delta.dot];
    if (old != null &&
        canonicalJsonSetKey(old.value) != canonicalJsonSetKey(delta.value)) {
      throw FormatException('Conflicting MV-Register dot');
    }
    final observedByCurrent = _versions.values.any(
      (v) => v.context.contains(delta.dot),
    );
    _context.addAll(delta._context);
    _versions.removeWhere((dot, _) => delta._context.contains(dot));
    _context.add(delta.dot);
    if (!observedByCurrent) {
      _versions.putIfAbsent(
        delta.dot,
        () => _MvVersion(copyJsonValue(delta.value), delta._context.copy()),
      );
    }
    if (delta.replicaId == replicaId && delta.dot.counter > _sequence) {
      _sequence = delta.dot.counter;
    }
  }

  @override
  void mergeState(covariant DeltaCrdt<Set<Object?>, MvRegisterDelta> other) {
    final state = other as MvRegister;
    if (state.crdtId != crdtId) {
      throw ArgumentError('Cannot merge MV-Registers with different addresses');
    }
    _context.addAll(state._context);
    for (final entry in state._versions.entries) {
      final current = _versions[entry.key];
      if (current != null &&
          canonicalJsonSetKey(current.value) !=
              canonicalJsonSetKey(entry.value.value)) {
        throw FormatException('Conflicting MV-Register dot');
      }
      _versions.putIfAbsent(
        entry.key,
        () => _MvVersion(
          copyJsonValue(entry.value.value),
          entry.value.context.copy(),
        ),
      );
    }
    final observed = [for (final version in _versions.values) version.context];
    _versions.removeWhere(
      (dot, _) => observed.any((context) => context.contains(dot)),
    );
    if (state.replicaId == replicaId && state._sequence > _sequence) {
      _sequence = state._sequence;
    }
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'crdtId': crdtId,
    'sequence': _sequence,
    'context': _context.toJson(),
    'versions': [
      for (final e in _versions.entries)
        {
          'dot': e.key.toJson(),
          'value': copyJsonValue(e.value.value),
          'context': e.value.context.toJson(),
        },
    ],
  };

  Iterable<MvRegisterDelta> exportChanges() sync* {
    for (final entry in _versions.entries) {
      yield MvRegisterDelta._(
        id: crdtDeltaId(
          kind.wireName,
          crdtId,
          entry.key.replicaId,
          entry.key.counter,
        ),
        replicaId: entry.key.replicaId,
        crdtId: crdtId,
        dot: entry.key,
        value: entry.value.value,
        context: entry.value.context,
      );
    }
  }

  /// Restores state only if the local sequence cannot reuse an observed dot.
  factory MvRegister.fromJson(
    Map<String, Object?> json, {
    bool allowCompactContext = true,
  }) {
    final replicaId = json['replicaId'],
        crdtId = json['crdtId'],
        sequence = json['sequence'],
        context = json['context'],
        versions = json['versions'];
    if (replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        crdtId is! String ||
        crdtId.isEmpty ||
        crdtId.trim() != crdtId ||
        crdtId.startsWith('legacy/') ||
        sequence is! int ||
        sequence < 0 ||
        (context is! List && (!allowCompactContext || context is! Map)) ||
        versions is! List) {
      throw const FormatException('Invalid MV-Register state');
    }
    final result = MvRegister(replicaId, crdtId: crdtId).._sequence = sequence;
    if (context is List) {
      for (final raw in context) {
        if (raw is! Map) {
          throw const FormatException('Invalid MV-Register context');
        }
        final dot = Dot.fromJson(Map<String, Object?>.from(raw));
        if (dot.crdtId != crdtId || dot.replicaId.trim() != dot.replicaId) {
          throw const FormatException('Invalid MV-Register context');
        }
        result._context.add(dot);
      }
    } else {
      result._context.addAll(
        _CompactDotContext.fromJson(
          Map<String, Object?>.from(context as Map),
          crdtId,
        ),
      );
    }
    if (result._context.highestCounter(replicaId) > sequence) {
      throw const FormatException(
        'MV-Register sequence is behind local context',
      );
    }
    for (final raw in versions) {
      if (raw is! Map ||
          raw['dot'] is! Map ||
          (raw['context'] is! List &&
              (!allowCompactContext || raw['context'] is! Map))) {
        throw const FormatException('Invalid MV-Register version');
      }
      final dot = Dot.fromJson(Map<String, Object?>.from(raw['dot'] as Map));
      final encodedVersionContext = raw['context'];
      final versionContext = encodedVersionContext is List
          ? _CompactDotContext.fromDots(
              crdtId,
              encodedVersionContext.map((item) {
                if (item is! Map) {
                  throw const FormatException('Invalid MV-Register context');
                }
                return Dot.fromJson(Map<String, Object?>.from(item));
              }),
            )
          : _CompactDotContext.fromJson(
              Map<String, Object?>.from(encodedVersionContext as Map),
              crdtId,
            );
      if (dot.crdtId != crdtId ||
          !result._context.contains(dot) ||
          !result._context.containsAll(versionContext)) {
        throw const FormatException('Invalid MV-Register version context');
      }
      _validateJsonValue(raw['value']);
      result._versions[dot] = _MvVersion(
        copyJsonValue(raw['value']),
        versionContext,
      );
    }
    return result;
  }

  CrdtKind get kind => CrdtKind.mvRegister;
}

class _MvVersion {
  _MvVersion(this.value, this.context);
  final Object? value;
  final _CompactDotContext context;
}

class _CompactDotContext {
  _CompactDotContext(this.crdtId) : _prefixes = {}, _sparse = {};

  _CompactDotContext._(this.crdtId, this._prefixes, this._sparse);

  final String crdtId;
  final Map<String, int> _prefixes;
  final Map<String, Set<int>> _sparse;

  factory _CompactDotContext.fromDots(String crdtId, Iterable<Dot> dots) {
    final context = _CompactDotContext(crdtId);
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

  factory _CompactDotContext.fromJson(
    Map<String, Object?> json,
    String crdtId,
  ) {
    final encodedReplicas = json['replicas'];
    if (json['crdtId'] != crdtId || encodedReplicas is! Map) {
      throw const FormatException('Invalid compact MV-Register context');
    }
    final context = _CompactDotContext(crdtId);
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

  _CompactDotContext copy() => _CompactDotContext._(
    crdtId,
    Map<String, int>.of(_prefixes),
    {for (final entry in _sparse.entries) entry.key: Set<int>.of(entry.value)},
  );

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

  void addAll(_CompactDotContext other) {
    if (other.crdtId != crdtId) {
      throw ArgumentError('MV-Register context address mismatch');
    }
    for (final replicaId in {
      ..._prefixes.keys,
      ..._sparse.keys,
      ...other._prefixes.keys,
      ...other._sparse.keys,
    }) {
      final prefix = maxOf(
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

  bool containsAll(_CompactDotContext other) {
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
    return maxOf(_prefixes[replicaId] ?? 0, sparse.reduce(maxOf));
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

int maxOf(int a, int b) => a > b ? a : b;

int _compareDots(Dot a, Dot b) => a.replicaId.compareTo(b.replicaId) != 0
    ? a.replicaId.compareTo(b.replicaId)
    : a.counter.compareTo(b.counter);
String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw FormatException('Invalid MV-Register $key');
  }
  return value;
}

void _validateAddress(String value) {
  if (value.isEmpty || value.trim() != value || value.startsWith('legacy/')) {
    throw ArgumentError.value(value, 'crdtId');
  }
}

void _validateJsonValue(Object? value) {
  try {
    copyJsonValue(value);
  } on ArgumentError {
    throw ArgumentError.value(value, 'value', 'must be JSON-compatible');
  }
}
