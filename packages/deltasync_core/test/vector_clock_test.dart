import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('missing and zero components obey equality and hash in collections', () {
    final empty = VectorClock();
    final zero = VectorClock({'a': 0});
    final multipleZeros = VectorClock({'b': 0, 'a': 0});

    expect(empty, zero);
    expect(zero, multipleZeros);
    expect(empty.hashCode, zero.hashCode);
    expect(zero.hashCode, multipleZeros.hashCode);

    final clocks = <VectorClock>{empty, zero, multipleZeros};
    expect(clocks, hasLength(1));
    expect(clocks.contains(VectorClock({'b': 0})), isTrue);

    final byClock = <VectorClock, String>{zero: 'first'};
    expect(byClock[empty], 'first');
    byClock[multipleZeros] = 'updated';
    expect(byClock, hasLength(1));
    expect(byClock[VectorClock({'c': 0})], 'updated');
  });

  test('component insertion order and extra zeros preserve hash lookup', () {
    final first = VectorClock({'a': 2, 'b': 3});
    final reordered = VectorClock({'b': 3, 'a': 2});
    final withZeros = VectorClock({'unused': 0, 'b': 3, 'a': 2, 'other': 0});

    expect(first, reordered);
    expect(reordered, withZeros);
    expect(first.hashCode, reordered.hashCode);
    expect(reordered.hashCode, withZeros.hashCode);

    final clocks = <VectorClock>{first};
    expect(clocks.add(withZeros), isFalse);
    expect(clocks.contains(reordered), isTrue);
    expect(<VectorClock, int>{first: 7}[withZeros], 7);
    expect(first.compare(VectorClock({'a': 2, 'b': 4})), ClockRelation.before);
    expect(first, isNot(VectorClock({'a': 2, 'b': 4})));
  });

  test(
    'zero JSON remains accepted and tick, merge and validation stay intact',
    () {
      final restored = VectorClock.fromJson({'a': 0, 'b': 2});
      expect(restored.toJson(), {'a': 0, 'b': 2});
      expect(restored, VectorClock({'b': 2}));
      expect(restored.tick('a').entries, {'a': 1, 'b': 2});
      expect(restored.merge(VectorClock({'a': 3})).entries, {'a': 3, 'b': 2});
      expect(restored.compare(VectorClock({'b': 3})), ClockRelation.before);
      expect(restored.compare(VectorClock({'a': 1})), ClockRelation.concurrent);

      expect(() => VectorClock({'a': -1}), throwsArgumentError);
      expect(() => VectorClock.fromJson({'a': -1}), throwsArgumentError);
      expect(() => VectorClock.fromJson({'a': '1'}), throwsFormatException);
    },
  );
}
