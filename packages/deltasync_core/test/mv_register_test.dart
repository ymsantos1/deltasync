import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

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

    final replica = Replica('local');
    expect(
      () => replica.writeMvRegister('not-bound', Object()),
      throwsArgumentError,
    );
    expect(replica.state.addresses, isEmpty);
  });
}
