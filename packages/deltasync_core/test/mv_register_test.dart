import 'dart:convert';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

List<Map<String, Object?>> _expandCompactContext(Map context) {
  final crdtId = context['crdtId'] as String;
  final replicas = context['replicas'] as Map;
  final dots = <Dot>[];
  for (final entry in replicas.entries) {
    final replicaId = entry.key as String;
    final encoded = entry.value as Map;
    final prefix = encoded['prefix'] as int;
    final sparse = (encoded['sparse'] as List).cast<int>();
    dots.addAll([
      for (var counter = 1; counter <= prefix; counter++)
        Dot(replicaId: replicaId, counter: counter, crdtId: crdtId),
      for (final counter in sparse)
        Dot(replicaId: replicaId, counter: counter, crdtId: crdtId),
    ]);
  }
  dots.sort((a, b) => a.counter.compareTo(b.counter));
  return [for (final dot in dots) dot.toJson()];
}

void main() {
  test('concurrent writes remain visible and observed write dominates', () {
    final first = MvRegister('a', crdtId: 'field');
    final second = MvRegister('b', crdtId: 'field');
    final a = first.write('A');
    final b = second.write('B');
    first.applyDelta(b);
    second.applyDelta(a);
    expect(first.value, {'A', 'B'});
    expect(second.value, {'A', 'B'});
    second.applyDelta(a);
    expect(second.value, {'A', 'B'});

    final later = first.write('C');
    expect(later.context.toSet(), {a.dot, b.dot});
    second.applyDelta(later);
    expect(second.value, {'C'});
    second.applyDelta(a); // delayed prior dot stays suppressed by C's context
    expect(second.value, {'C'});
  });

  test(
    'causal context survives delta and state JSON with missing earlier dot',
    () {
      final author = MvRegister('author', crdtId: 'field');
      final previous = author.write('old');
      final observed = MvRegister('observer', crdtId: 'field')
        ..applyDelta(previous);
      final later = observed.write('new');
      final decoded = MvRegisterDelta.fromJson(later.toJson());
      final receiver = MvRegister('receiver', crdtId: 'field')
        ..applyDelta(decoded);
      receiver.applyDelta(previous);
      expect(receiver.value, {'new'});

      final restored = MvRegister.fromJson(receiver.toJson());
      expect(restored.value, {'new'});
      expect(restored.toJson(), receiver.toJson());
    },
  );

  test('compact contexts preserve prefixes, gaps and namespace', () {
    final author = MvRegister('author', crdtId: 'field');
    final first = author.write('one');
    final second = author.write('two');
    final third = author.write('three');
    final isolatedThird = MvRegisterDelta(
      id: crdtDeltaId('mv-register', 'field', 'author', 3),
      replicaId: 'author',
      crdtId: 'field',
      dot: third.dot,
      value: third.value,
      context: const [],
    );

    final gapObserver = MvRegister('gap-observer', crdtId: 'field')
      ..applyDelta(isolatedThird);
    final gapWrite = gapObserver.write('after-gap');
    expect(gapWrite.context, [third.dot]);
    expect(gapWrite.toJson()['context'], {
      'crdtId': 'field',
      'replicas': {
        'author': {
          'prefix': 0,
          'sparse': [3],
        },
      },
    });

    final prefixObserver = MvRegister('prefix-observer', crdtId: 'field')
      ..applyDelta(first)
      ..applyDelta(second)
      ..applyDelta(third);
    final prefixWrite = MvRegisterDelta(
      id: crdtDeltaId('mv-register', 'field', 'prefix-writer', 1),
      replicaId: 'prefix-writer',
      crdtId: 'field',
      dot: Dot(replicaId: 'prefix-writer', counter: 1, crdtId: 'field'),
      value: 'after-prefix',
      context: [first.dot, second.dot, third.dot],
    );
    expect(prefixWrite.context, [first.dot, second.dot, third.dot]);
    expect(prefixWrite.toJson()['context'], {
      'crdtId': 'field',
      'replicas': {
        'author': {'prefix': 3, 'sparse': <int>[]},
      },
    });

    final joinedObserver = MvRegister('join-observer', crdtId: 'field')
      ..applyDelta(isolatedThird)
      ..mergeState(prefixObserver);
    final joined = joinedObserver.write('after-join');
    expect(joined.context.toSet(), {first.dot, second.dot, third.dot});
    expect(joined.toJson()['context'], prefixWrite.toJson()['context']);
    expect(
      () => MvRegisterDelta(
        id: crdtDeltaId('mv-register', 'other', 'replica', 1),
        replicaId: 'replica',
        crdtId: 'other',
        dot: Dot(replicaId: 'replica', counter: 1, crdtId: 'other'),
        value: 'value',
        context: [third.dot],
      ),
      throwsArgumentError,
    );
  });

  test('compact context join matches explicit-dot union across gaps', () {
    final universe = [
      for (final replicaId in ['a', 'b'])
        for (final counter in [1, 2, 4])
          Dot(replicaId: replicaId, counter: counter, crdtId: 'field'),
    ];

    MvRegister state(String writer, List<Dot> context) {
      final dot = Dot(replicaId: writer, counter: 1, crdtId: 'field');
      return MvRegister('observer-$writer', crdtId: 'field')..applyDelta(
        MvRegisterDelta(
          id: crdtDeltaId('mv-register', 'field', writer, 1),
          replicaId: writer,
          crdtId: 'field',
          dot: dot,
          value: writer,
          context: context,
        ),
      );
    }

    for (var leftMask = 0; leftMask < 1 << universe.length; leftMask++) {
      for (var rightMask = 0; rightMask < 1 << universe.length; rightMask++) {
        final leftContext = [
          for (var index = 0; index < universe.length; index++)
            if (leftMask & (1 << index) != 0) universe[index],
        ];
        final rightContext = [
          for (var index = 0; index < universe.length; index++)
            if (rightMask & (1 << index) != 0) universe[index],
        ];
        final joined = state('writer-a', leftContext)
          ..mergeState(state('writer-b', rightContext));
        final expected = {
          ...leftContext,
          ...rightContext,
          Dot(replicaId: 'writer-a', counter: 1, crdtId: 'field'),
          Dot(replicaId: 'writer-b', counter: 1, crdtId: 'field'),
        };
        final observed = _expandCompactContext(
          joined.toJson()['context'] as Map,
        ).map((dot) => Dot.fromJson(dot)).toSet();
        expect(observed, expected, reason: 'left=$leftMask right=$rightMask');
        for (final dot in universe) {
          expect(
            observed.contains(dot),
            expected.contains(dot),
            reason: 'left=$leftMask right=$rightMask dot=$dot',
          );
        }
      }
    }
  });

  test('DeltaCodec v4 reads compact and v3 reads explicit contexts only', () {
    final register = MvRegister('author', crdtId: 'field')
      ..write('one')
      ..write('two');
    final change = register.write('three');
    final compact = DeltaCodec.encode(Delta([change]));
    expect(compact['version'], 4);
    expect(DeltaCodec.decode(compact).changes.single, isA<MvRegisterDelta>());

    final legacyChange = change.toJson()
      ..['context'] = [for (final dot in change.context) dot.toJson()];
    final version3 = {
      'version': 3,
      'delta': {
        'changes': [legacyChange],
      },
    };
    expect(DeltaCodec.decode(version3).changes.single, isA<MvRegisterDelta>());
    expect(
      () => DeltaCodec.decode({'version': 3, 'delta': compact['delta']}),
      throwsFormatException,
    );
  });

  test('Replica snapshot v9 reads old explicit MV contexts', () {
    final replica = Replica('author')
      ..writeMvRegister('field', 'one')
      ..writeMvRegister('field', 'two');
    final current = replica.toSnapshotJson();
    expect(current['version'], 9);

    final legacy = Map<String, Object?>.from(current)..['version'] = 8;
    final registers = Map<String, Object?>.from(legacy['mvRegisters'] as Map);
    final state = Map<String, Object?>.from(registers['field'] as Map);
    state['context'] = _expandCompactContext(state['context'] as Map);
    final versions = (state['versions'] as List).map((raw) {
      final version = Map<String, Object?>.from(raw as Map);
      version['context'] = _expandCompactContext(version['context'] as Map);
      return version;
    }).toList();
    state['versions'] = versions;
    registers['field'] = state;
    legacy['mvRegisters'] = registers;

    final restored = Replica.fromSnapshotJson(legacy);
    expect(restored.mvRegisterValue('field'), {'two'});
    expect(restored.writeMvRegister('field', 'three').context, hasLength(2));
  });

  test(
    'join is idempotent, commutative, associative and Replica routes snapshot',
    () {
      final a = MvRegister('a', crdtId: 'field')..write('A');
      final b = MvRegister('b', crdtId: 'field')..write('B');
      final c = MvRegister('c', crdtId: 'field')..write('C');
      final ab = MvRegister.fromJson(a.toJson())..mergeState(b);
      final ba = MvRegister.fromJson(b.toJson())..mergeState(a);
      expect(ab.value, ba.value);
      final left = MvRegister.fromJson(ab.toJson())..mergeState(c);
      final bc = MvRegister.fromJson(b.toJson())..mergeState(c);
      final right = MvRegister.fromJson(a.toJson())..mergeState(bc);
      expect(left.value, right.value);
      left.mergeState(left);
      expect(left.value, {'A', 'B', 'C'});
      final byDeltas = MvRegister('receiver', crdtId: 'field')
        ..applyDelta(a.exportChanges().single)
        ..applyDelta(b.exportChanges().single)
        ..applyDelta(c.exportChanges().single);
      expect(byDeltas.value, left.value);

      final mapA = MvRegister('map-a', crdtId: 'map')..write({'a': 1, 'b': 2});
      final mapB = MvRegister('map-b', crdtId: 'map')..write({'b': 2, 'a': 1});
      final sameJson = MvRegister('map-c', crdtId: 'map')
        ..applyDelta(mapA.exportChanges().single)
        ..applyDelta(mapB.exportChanges().single);
      expect(sameJson.value, hasLength(1));

      final source = Replica('source')..writeMvRegister('field', 'value');
      final encoded = DeltaCodec.encode(source.export());
      final target = Replica('target')..apply(DeltaCodec.decode(encoded));
      expect(target.mvRegisterValue('field'), {'value'});
      final restored = Replica.fromSnapshotJson(source.toSnapshotJson());
      expect(restored.mvRegisterValue('field'), {'value'});
      final later = restored.writeMvRegister('field', 'next');
      expect(
        later.context,
        contains(Dot(replicaId: 'source', counter: 1, crdtId: 'field')),
      );
    },
  );

  test('rejects unknown, malformed and cross-address causal dots', () {
    final register = MvRegister('a', crdtId: 'field');
    expect(() => register.write(Object()), throwsArgumentError);
    final delta = register.write('value').toJson()..['type'] = 'unknown';
    expect(
      () => DeltaCodec.decode({
        'version': DeltaCodec.currentVersion,
        'delta': {
          'changes': [delta],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => MvRegister.fromJson({
        'replicaId': 'a',
        'crdtId': 'field',
        'sequence': 0,
        'context': [],
        'versions': [
          {
            'dot': Dot(replicaId: 'x', counter: 1, crdtId: 'other').toJson(),
            'value': 1,
            'context': [],
          },
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => MvRegister.fromJson({
        'replicaId': 'local',
        'crdtId': 'field',
        'sequence': 0,
        'context': {
          'crdtId': 'field',
          'replicas': {
            'peer': {
              'prefix': 0,
              'sparse': [1],
            },
          },
        },
        'versions': [],
      }),
      throwsFormatException,
    );

    final replica = Replica('local');
    expect(
      () => replica.writeMvRegister('not-bound', Object()),
      throwsArgumentError,
    );
    expect(replica.state.addresses, isEmpty);
  });

  test('rejects a sequence behind local dots, including replaced versions', () {
    final original = MvRegister('local', crdtId: 'field');
    final first = original.write('old');
    final second = original.write('current');
    final encoded = original.toJson();
    expect(
      _expandCompactContext(
        encoded['context'] as Map,
      ).any((item) => item['counter'] == first.dot.counter),
      isTrue,
    );
    expect(encoded['versions'], hasLength(1));

    for (final staleSequence in [0, 1]) {
      final invalid = Map<String, Object?>.from(encoded)
        ..['sequence'] = staleSequence;
      expect(
        () => MvRegister.fromJson(invalid),
        throwsA(isA<FormatException>()),
      );
    }

    final unnormalized = Map<String, Object?>.from(encoded)
      ..['replicaId'] = ' local ';
    expect(() => MvRegister.fromJson(unnormalized), throwsFormatException);

    final restored = MvRegister.fromJson(encoded);
    final next = restored.write('next');
    expect(next.dot.counter, 3);
    expect(next.context, containsAll([first.dot, second.dot]));
  });

  test('remote dots do not consume the local sequence', () {
    final remote = MvRegister('peer', crdtId: 'field')
      ..write('old')
      ..write('remote');
    final local = MvRegister('local', crdtId: 'field')
      ..applyDelta(remote.exportChanges().single);
    final restored = MvRegister.fromJson(local.toJson());
    final next = restored.write('local');
    expect(next.dot.counter, 1);
    expect(next.context.map((dot) => dot.replicaId).toSet(), {'peer'});
    expect(next.context.map((dot) => dot.counter).toSet(), {1, 2});
    expect(restored.value, {'local'});
  });

  test('Replica rejects a stale MV sequence before returning a snapshot', () {
    final source = Replica('local')
      ..writeMvRegister('field', 'old')
      ..writeMvRegister('field', 'current');
    final snapshot =
        jsonDecode(jsonEncode(source.toSnapshotJson())) as Map<String, dynamic>;
    final registers = snapshot['mvRegisters'] as Map<String, Object?>;
    final field = registers['field'] as Map<String, Object?>;
    field['sequence'] = 0;

    expect(
      () => Replica.fromSnapshotJson(snapshot),
      throwsA(isA<FormatException>()),
    );
    expect(source.mvRegisterValue('field'), {'current'});
    expect(source.writeMvRegister('field', 'next').dot.counter, 3);
  });
}
