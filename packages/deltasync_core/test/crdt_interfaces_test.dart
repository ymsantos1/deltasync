import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('VectorClock identifies causal and concurrent operations', () {
    final first = VectorClock().tick('first');
    final second = first.tick('first');
    final concurrent = VectorClock().tick('second');

    expect(first.compare(second), ClockRelation.before);
    expect(second.compare(first), ClockRelation.after);
    expect(second.compare(concurrent), ClockRelation.concurrent);
  });

  test('Operation round trips through JSON shape', () {
    final operation = Operation(
      id: 'device-a:1',
      replicaId: 'device-a',
      type: 'register.set',
      vectorClock: VectorClock().tick('device-a'),
      payload: {'field': 'title', 'value': 'draft'},
    );

    expect(Operation.fromJson(operation.toJson()), operation);
  });
}
