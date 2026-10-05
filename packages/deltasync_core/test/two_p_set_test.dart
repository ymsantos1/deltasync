import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('2P-Set removal tombstone defeats old and later additions', () {
    final source = TwoPSet('source', crdtId: 'labels');
    final addition = source.add('shared');
    final removal = source.remove('shared');
    final readmission = source.add('shared');

    expect(source.value, isEmpty);
    expect(readmission.action, TwoPSetAction.add);

    final oldMessage = TwoPSet('receiver', crdtId: 'labels')
      ..applyDelta(removal)
      ..applyDelta(addition)
      ..applyDelta(readmission)
      ..applyDelta(removal);
    expect(oldMessage.value, isEmpty);
    expect(
      oldMessage.exportChanges().toList(),
      TwoPSet.fromJson(source.toJson()).exportChanges().toList(),
    );
  });

  test('2P-Set join is associative, commutative, and idempotent', () {
    final added = TwoPSet('a', crdtId: 'members')..addAll(['one', 'shared']);
    final removed = TwoPSet('b', crdtId: 'members')..remove('shared');
    final concurrent = TwoPSet('c', crdtId: 'members')
      ..addAll(['two', 'shared']);

    TwoPSet copy(TwoPSet set) => TwoPSet.fromJson(set.toJson());
    TwoPSet join(TwoPSet first, TwoPSet second) =>
        copy(first)..mergeState(second);

    final ab = join(added, removed);
    final ba = join(removed, added);
    expect(ab.exportChanges().toList(), ba.exportChanges().toList());
    expect(
      join(ab, concurrent).exportChanges().toList(),
      join(added, join(removed, concurrent)).exportChanges().toList(),
    );
    expect(join(ab, ab).toJson(), ab.toJson());
    expect(ab.value, {'one'});
    expect(join(ab, concurrent).value, {'one', 'two'});
  });

  test('2P-Set uses structural JSON equality and rejects invalid values', () {
    final set = TwoPSet('device', crdtId: 'records');
    set.add({
      'a': [1, 2],
      'b': true,
    });
    expect(
      set.value.contains({
        'b': true,
        'a': [1, 2],
      }),
      isTrue,
    );
    expect(
      set.remove({
        'b': true,
        'a': [1, 2],
      }).action,
      TwoPSetAction.remove,
    );
    expect(set.value, isEmpty);
    expect(set.value.contains({1: 'invalid'}), isFalse);

    expect(() => TwoPSet('device', crdtId: '').add('x'), throwsArgumentError);
    expect(
      () => TwoPSet('device', crdtId: 'bad').add(Object()),
      throwsArgumentError,
    );
    expect(() => set.addAll([]), throwsArgumentError);
    expect(
      () => TwoPSetDelta.fromJson({
        'id': 'bad',
        'replicaId': 'device',
        'crdtId': 'records',
        'action': 'replace',
        'elements': ['x'],
        'dot': {'replicaId': 'device', 'counter': 1, 'crdtId': 'records'},
      }),
      throwsFormatException,
    );
  });

  test('2P-Set deltas codec and Replica snapshot retain tombstones', () {
    final source = Replica('device');
    final addition = source.addTwoPSet('members', 'shared');
    final removal = source.removeTwoPSet('members', 'shared');
    final decoded = DeltaCodec.decode(
      DeltaCodec.encode(Delta([addition, removal])),
    );
    final remote = Replica('remote')..apply(decoded);
    expect(remote.twoPSetValue('members'), isEmpty);
    expect(
      decoded.changes.map((change) => change.kind),
      everyElement(CrdtKind.twoPSet),
    );

    final snapshot = source.toSnapshotJson();
    expect(snapshot['version'], 5);
    final restored = Replica.fromSnapshotJson(snapshot);
    expect(restored.twoPSetValue('members'), isEmpty);
    expect(restored.addTwoPSet('members', 'shared').dot.counter, 3);
    expect(restored.twoPSetValue('members'), isEmpty);

    final versionFour = Map<String, Object?>.of(snapshot)
      ..remove('twoPSets')
      ..['version'] = 4;
    expect(
      Replica.fromSnapshotJson(versionFour).twoPSetValue('members'),
      isEmpty,
    );
  });

  test('2P-Set snapshot reconciliation matches exchanged deltas', () {
    final first = Replica('first')..addTwoPSet('members', 'shared');
    final second = Replica('second')..removeTwoPSet('members', 'shared');
    final exchanged = Replica('receiver')
      ..apply(Delta([...first.export().changes, ...second.export().changes]));
    final reconciled = Replica('receiver')
      ..mergeSnapshotJson(first.toSnapshotJson())
      ..mergeSnapshotJson(second.toSnapshotJson());

    expect(exchanged.twoPSetValue('members'), isEmpty);
    expect(
      reconciled.twoPSetValue('members'),
      exchanged.twoPSetValue('members'),
    );
    expect(
      reconciled.export().changes.map((change) => change.id).toSet(),
      exchanged.export().changes.map((change) => change.id).toSet(),
    );
  });

  test('2P-Set invalid local mutation does not bind Replica address', () {
    final replica = Replica('device');
    expect(() => replica.addTwoPSet('members', Object()), throwsArgumentError);
    expect(
      () => replica.removeTwoPSet('members', Object()),
      throwsArgumentError,
    );
    expect(replica.setDelta('members', true).id, 'device:delta:1');
  });

  test('Replica rejects conflicting 2P-Set address without partial apply', () {
    final replica = Replica('receiver')..setDelta('shared', true);
    final delta = Replica('source').addTwoPSet('shared', 'member');

    expect(() => replica.apply(Delta([delta])), throwsFormatException);
    expect(replica.state.values, {'shared': true});
    expect(replica.twoPSetValue('shared'), isEmpty);
  });
}
