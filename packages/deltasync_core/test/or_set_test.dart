import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('removal deletes only observed tags and concurrent add survives', () {
    final left = OrSet('left', crdtId: 'members');
    final right = OrSet('right', crdtId: 'members');
    final oldTag = left.add('reader');
    final concurrentTag = right.add('reader');
    final removal = left.remove('reader');

    expect(removal.observedDots, [oldTag.dot]);
    left.applyDelta(concurrentTag);
    right.applyDelta(removal);
    right.applyDelta(oldTag);
    expect(left.value, {'reader'});
    expect(right.value, {'reader'});
  });

  test('re-add uses fresh tag and old add stays removed after restore', () {
    final source = OrSet('source', crdtId: 'members');
    final oldTag = source.add('reader');
    final removal = source.remove('reader');
    final restored = OrSet.fromJson(source.toJson());
    restored.applyDelta(oldTag);
    expect(restored.value, isEmpty);

    final readdition = restored.add('reader');
    expect(readdition.dot, isNot(oldTag.dot));
    expect(restored.value, {'reader'});
    restored.applyDelta(removal);
    expect(restored.value, {'reader'});
    expect(OrSet.fromJson(restored.toJson()).value, {'reader'});
  });

  test(
    'join is associative, commutative, idempotent and matches delta exchange',
    () {
      final a = OrSet('a', crdtId: 'tags')..add('one');
      final b = OrSet('b', crdtId: 'tags')..add('one');
      final c = OrSet('c', crdtId: 'tags')
        ..applyDelta(a.exportChanges().single)
        ..remove('one');

      final ab = OrSet.fromJson(a.toJson())..mergeState(b);
      final ba = OrSet.fromJson(b.toJson())..mergeState(a);
      expect(ab.value, ba.value);
      final left = OrSet.fromJson(ab.toJson())..mergeState(c);
      final bc = OrSet.fromJson(b.toJson())..mergeState(c);
      final right = OrSet.fromJson(a.toJson())..mergeState(bc);
      expect(left.value, right.value);
      left.mergeState(left);

      final byDeltas = OrSet('receiver', crdtId: 'tags');
      for (final change in [
        ...a.exportChanges(),
        ...b.exportChanges(),
        ...c.exportChanges(),
      ].reversed) {
        byDeltas.applyDelta(change);
        byDeltas.applyDelta(change);
      }
      expect(byDeltas.value, left.value);
    },
  );

  test('codec and Replica snapshot preserve tags and tombstones', () {
    final source = Replica('source');
    final add = source.addOrSet('members', 'reader');
    final remove = source.removeOrSet('members', 'reader');
    final encoded = DeltaCodec.encode(Delta([add, remove]));
    final decoded = DeltaCodec.decode(encoded);
    final receiver = Replica('receiver')..apply(decoded);
    expect(receiver.orSetValue('members'), isEmpty);

    final restored = Replica.fromSnapshotJson(source.toSnapshotJson());
    expect(restored.toSnapshotJson()['version'], 8);
    restored.apply(Delta([add]));
    expect(restored.orSetValue('members'), isEmpty);
    expect(
      Replica.fromSnapshotJson(
        {...source.toSnapshotJson(), 'version': 6}..remove('orSets'),
      ).orSetValue('members'),
      isEmpty,
    );
  });

  test('rejects unknown, malformed and cross-address tags without binding', () {
    final replica = Replica('local');
    expect(() => replica.addOrSet('invalid', Object()), throwsArgumentError);
    expect(() => replica.removeOrSet('invalid', Object()), throwsArgumentError);
    expect(replica.state.addresses, isEmpty);

    final wrongAddress = OrSet('source', crdtId: 'other').add('reader');
    expect(
      () => OrSet('receiver', crdtId: 'members').applyDelta(wrongAddress),
      throwsFormatException,
    );

    final add = OrSet('source', crdtId: 'members').add('reader').toJson();
    expect(
      () => DeltaCodec.decode({
        'version': DeltaCodec.currentVersion,
        'delta': {
          'changes': [add..['type'] = 'future-set'],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => OrSetDelta.fromJson({...add, 'action': 'unknown'}),
      throwsFormatException,
    );

    final original = OrSet('source', crdtId: 'members').add('first');
    final divergent = OrSetDelta(
      id: original.id,
      replicaId: original.replicaId,
      crdtId: original.crdtId,
      action: OrSetAction.add,
      dot: original.dot,
      element: 'different',
    );
    final target = Replica('target')..apply(Delta([original]));
    expect(() => target.apply(Delta([divergent])), throwsFormatException);
    expect(target.orSetValue('members'), {'first'});
  });
}
