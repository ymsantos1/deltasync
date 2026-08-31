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

  test('OperationCrdt ignores duplicate operation delivery', () {
    final crdt = RecordingCrdt();
    final operation = _operation('device-a:1', 3);

    crdt.apply(operation);
    crdt.apply(operation);

    expect(crdt.value, 3);
    expect(crdt.applications, 1);
    expect(crdt.appliedOperationIds, ['device-a:1']);
  });

  test('LwwRegister keeps delete as tombstone', () {
    final register = LwwRegister<String>();
    final replica = Replica('device-a');
    final set = replica.set('title', 'draft');
    final delete = replica.remove('title');

    register.apply(set);
    register.apply(delete);

    expect(register.value, isNull);
    expect(register.isDeleted, isTrue);
    expect(register.winner, delete);
  });

  test('LwwRegister resolves concurrent operations deterministically', () {
    final first = Replica('first')..set('title', 'first');
    final second = Replica('second')..set('title', 'second');
    final firstOperation = first.export().changes.single;
    final secondOperation = second.export().changes.single;

    final left = LwwRegister<String>()..apply(firstOperation);
    left.apply(secondOperation);
    final right = LwwRegister<String>()..apply(secondOperation);
    right.apply(firstOperation);

    expect(left.value, right.value);
    expect(left.winner, right.winner);
  });

  test('LWW state converges when concurrent operations arrive reordered', () {
    final first = Replica('first')..set('title', 'first');
    final second = Replica('second')..set('title', 'second');

    final left = Replica('left')
      ..apply(Delta([...first.export().changes, ...second.export().changes]));
    final right = Replica('right')
      ..apply(Delta([...second.export().changes, ...first.export().changes]));

    expect(left.state.values, right.state.values);
  });
}

class RecordingCrdt extends OperationCrdt<int> {
  int _value = 0;
  int applications = 0;

  @override
  int get value => _value;

  @override
  void applyOperation(Operation operation) {
    applications++;
    final value = operation.payload['value'];
    if (value is! int) throw FormatException('value must be int');
    _value = value;
  }
}

Operation _operation(String id, int value) => Operation(
  id: id,
  replicaId: 'device-a',
  type: 'test.set',
  vectorClock: VectorClock().tick('device-a'),
  payload: {'value': value},
);
