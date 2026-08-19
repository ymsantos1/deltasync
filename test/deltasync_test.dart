import 'package:deltasync/deltasync.dart';
import 'package:test/test.dart';

void main() {
  test('replicas converge after exchanging deltas', () {
    final first = Replica('first');
    final second = Replica('second');

    first.set('title', 'offline edit');
    second.apply(first.export());

    expect(second.state.values['title'], 'offline edit');
  });

  test('deletes and duplicate changes are idempotent', () {
    final replica = Replica('first');
    replica.set('title', 'draft');
    replica.remove('title');
    final delta = replica.export();

    replica.apply(delta);
    expect(replica.state.values, isEmpty);
    expect(delta.merge(delta).changes, hasLength(2));
  });
}
