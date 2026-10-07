import 'crdt.dart';
import 'delta_change.dart';
import 'identity.dart';
import 'json_value.dart';
import 'json_set_value.dart';

/// One write and the exact causal dots it had observed.
class MvRegisterDelta implements DeltaChange {
  MvRegisterDelta({
    required this.id,
    required this.replicaId,
    required this.crdtId,
    required this.dot,
    required Object? value,
    required Iterable<Dot> context,
  }) : value = copyJsonValue(value, freeze: true),
       context = List.unmodifiable(
         context.toSet().toList()..sort(_compareDots),
       ) {
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
        this.context.any(
          (item) =>
              item.crdtId != crdtId ||
              item.replicaId.isEmpty ||
              item.replicaId.trim() != item.replicaId ||
              item.counter <= 0 ||
              item == dot,
        )) {
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
  final List<Dot> context;
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
    'context': [for (final item in context) item.toJson()],
  };

  factory MvRegisterDelta.fromJson(Map<String, Object?> json) {
    final dot = json['dot'];
    final context = json['context'];
    if (dot is! Map ||
        context is! List ||
        context.any((item) => item is! Map)) {
      throw const FormatException('Invalid MV-Register delta');
    }
    try {
      return MvRegisterDelta(
        id: _requiredString(json, 'id'),
        replicaId: _requiredString(json, 'replicaId'),
        crdtId: _requiredString(json, 'crdtId'),
        dot: Dot.fromJson(Map<String, Object?>.from(dot)),
        value: json['value'],
        context: context.map(
          (item) => Dot.fromJson(Map<String, Object?>.from(item as Map)),
        ),
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
  final Set<Dot> _context = {};
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
    final delta = MvRegisterDelta(
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
    for (final dot in delta.context) {
      _context.add(dot);
      _versions.remove(dot);
    }
    _context.add(delta.dot);
    if (!observedByCurrent) {
      _versions.putIfAbsent(
        delta.dot,
        () => _MvVersion(copyJsonValue(delta.value), delta.context.toSet()),
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
    for (final dot in state._context) {
      _context.add(dot);
    }
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
          entry.value.context.toSet(),
        ),
      );
    }
    final observed = _versions.values.expand((v) => v.context).toSet();
    _versions.removeWhere((dot, _) => observed.contains(dot));
    if (state.replicaId == replicaId && state._sequence > _sequence) {
      _sequence = state._sequence;
    }
  }

  @override
  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'crdtId': crdtId,
    'sequence': _sequence,
    'context': [
      for (final dot in (_context.toList()..sort(_compareDots))) dot.toJson(),
    ],
    'versions': [
      for (final e in _versions.entries)
        {
          'dot': e.key.toJson(),
          'value': copyJsonValue(e.value.value),
          'context': [
            for (final dot in (e.value.context.toList()..sort(_compareDots)))
              dot.toJson(),
          ],
        },
    ],
  };

  Iterable<MvRegisterDelta> exportChanges() sync* {
    for (final entry in _versions.entries) {
      yield MvRegisterDelta(
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

  factory MvRegister.fromJson(Map<String, Object?> json) {
    final replicaId = json['replicaId'],
        crdtId = json['crdtId'],
        sequence = json['sequence'],
        context = json['context'],
        versions = json['versions'];
    if (replicaId is! String ||
        crdtId is! String ||
        sequence is! int ||
        sequence < 0 ||
        context is! List ||
        versions is! List) {
      throw const FormatException('Invalid MV-Register state');
    }
    final result = MvRegister(replicaId, crdtId: crdtId).._sequence = sequence;
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
    for (final raw in versions) {
      if (raw is! Map || raw['dot'] is! Map || raw['context'] is! List) {
        throw const FormatException('Invalid MV-Register version');
      }
      final dot = Dot.fromJson(Map<String, Object?>.from(raw['dot'] as Map));
      final dots = (raw['context'] as List).map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid MV-Register context');
        }
        return Dot.fromJson(Map<String, Object?>.from(item));
      }).toSet();
      if (dot.crdtId != crdtId ||
          !result._context.contains(dot) ||
          dots.any(
            (d) =>
                d.crdtId != crdtId ||
                d.replicaId.trim() != d.replicaId ||
                !result._context.contains(d),
          )) {
        throw const FormatException('Invalid MV-Register version context');
      }
      _validateJsonValue(raw['value']);
      result._versions[dot] = _MvVersion(copyJsonValue(raw['value']), dots);
    }
    return result;
  }

  CrdtKind get kind => CrdtKind.mvRegister;
}

class _MvVersion {
  _MvVersion(this.value, this.context);
  final Object? value;
  final Set<Dot> context;
}

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
