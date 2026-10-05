import 'package:deltasync/deltasync.dart';
import 'package:test/test.dart';

void main() {
  test('replicas converge after exchanging deltas', () {
    final first = Replica('first');
    final second = Replica('second');

    first.setDelta('title', 'offline edit');
    second.apply(first.export());

    expect(second.state.values['title'], 'offline edit');
  });

  test('export keeps the tombstone winner and duplicate is idempotent', () {
    final replica = Replica('first');
    replica.setDelta('title', 'draft');
    replica.removeDelta('title');
    final delta = replica.export();

    replica.apply(delta);
    expect(replica.state.values, isEmpty);
    expect(delta.changes, hasLength(1));
    expect(delta.changes.single, isA<LwwDelta<Object?>>());
    expect((delta.changes.single as LwwDelta<Object?>).deleted, isTrue);
    expect(delta.merge(delta).changes, hasLength(1));
  });

  test('facade exposes G-Set incremental delta API', () {
    final first = Replica('first');
    final second = Replica('second');
    final delta = first.addAllGSet('tags', ['offline', 'shared']);

    expect(delta, isA<GSetDelta>());
    second.apply(DeltaCodec.decode(DeltaCodec.encode(Delta([delta]))));
    expect(second.gSetValue('tags'), containsAll(['offline', 'shared']));
  });

  test('facade exposes permanent 2P-Set removals', () {
    final first = Replica('first');
    final second = Replica('second');
    final addition = first.addTwoPSet('members', 'device-a');
    final removal = first.removeTwoPSet('members', 'device-a');

    second.apply(
      DeltaCodec.decode(DeltaCodec.encode(Delta([addition, removal]))),
    );
    expect(second.twoPSetValue('members'), isEmpty);
    second.apply(Delta([addition]));
    expect(second.twoPSetValue('members'), isEmpty);
  });
}
