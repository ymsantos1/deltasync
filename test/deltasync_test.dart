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

  test('facade exposes causal MV-Register writes', () {
    final first = Replica('first');
    final second = Replica('second');
    final concurrentA = first.writeMvRegister('title', 'A');
    final concurrentB = second.writeMvRegister('title', 'B');
    first.apply(Delta([concurrentB]));
    second.apply(Delta([concurrentA]));

    expect(first.mvRegisterValue('title'), {'A', 'B'});
    final resolved = first.writeMvRegister('title', 'resolved');
    second.apply(Delta([resolved]));
    expect(second.mvRegisterValue('title'), {'resolved'});
  });

  test('facade exposes observed-remove OR-Set operations', () {
    final first = Replica('first');
    final second = Replica('second');
    final oldTag = first.addOrSet('members', 'reader');
    second.apply(Delta([oldTag]));
    final removal = first.removeOrSet('members', 'reader');
    final concurrentAdd = second.addOrSet('members', 'reader');

    first.apply(Delta([removal, concurrentAdd]));
    second.apply(Delta([removal]));
    expect(first.orSetValue('members'), {'reader'});
    expect(second.orSetValue('members'), {'reader'});
    expect(removal.observedDots, [oldTag.dot]);
  });
}
