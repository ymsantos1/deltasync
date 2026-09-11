import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('ReplicaId and Dot round trip and validate identity', () {
    final id = ReplicaId(' device-a ');
    const dot = Dot(replicaId: 'device-a', counter: 3);

    expect(id.value, 'device-a');
    expect(Dot.fromJson(dot.toJson()), dot);
    expect(
      () => Dot.fromJson({'replicaId': 'device-a', 'counter': 0}),
      throwsFormatException,
    );
    expect(
      () => Dot(replicaId: '', counter: 1),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => LwwRegister<String>().applyDelta(
        const LwwDelta<String>(
          key: 'title',
          id: 'device-a:1',
          replicaId: 'device-a',
          timestamp: HlcTimestamp(1, 0),
          value: 'draft',
          dot: Dot(replicaId: 'other', counter: 1),
        ),
      ),
      throwsFormatException,
    );
  });

  test('DeltaCodec round trips and rejects unknown versions', () {
    final replica = Replica('device-a');
    final delta = Delta.crdt([replica.setDelta('title', 'draft')]);

    expect(DeltaCodec.decode(DeltaCodec.encode(delta)).crdtChanges, [
      delta.crdtChanges.single,
    ]);
    expect(
      () => DeltaCodec.decode({...DeltaCodec.encode(delta), 'version': 99}),
      throwsFormatException,
    );
  });

  test('HLC advances logical component and observes remote timestamp', () {
    var physical = 100;
    final clock = HlcClock(nowMilliseconds: () => physical);

    expect(clock.tick(), const HlcTimestamp(100, 0));
    expect(clock.tick(), const HlcTimestamp(100, 1));
    expect(
      clock.observe(const HlcTimestamp(200, 7)),
      const HlcTimestamp(200, 8),
    );

    physical = 300;
    expect(clock.tick(), const HlcTimestamp(300, 0));
  });

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

  test('LWW Delta-CRDT is idempotent and order independent', () {
    const first = LwwDelta<String>(
      key: 'title',
      id: 'first:1',
      replicaId: 'first',
      timestamp: HlcTimestamp(10, 0),
      value: 'first',
    );
    const second = LwwDelta<String>(
      key: 'title',
      id: 'second:1',
      replicaId: 'second',
      timestamp: HlcTimestamp(10, 0),
      value: 'second',
    );

    final left = LwwRegister<String>()..applyDelta(first);
    left.applyDelta(second);
    left.applyDelta(second);

    final right = LwwRegister<String>()..applyDelta(second);
    right.applyDelta(first);

    expect(left.value, 'second');
    expect(left.value, right.value);
    expect(left.toJson(), right.toJson());
  });

  test('DeltaCrdt contract merges complete LWW state', () {
    const delta = LwwDelta<String>(
      key: 'title',
      id: 'device:1',
      replicaId: 'device',
      timestamp: HlcTimestamp(20, 0),
      value: 'draft',
    );
    final source = LwwRegister<String>()..applyDelta(delta);
    final target = LwwRegister<String>()..mergeState(source);

    expect(target.value, 'draft');
    expect(target.toJson(), source.toJson());
  });

  test('Delta carries native CRDT changes and merges them by delta ID', () {
    const first = LwwDelta<String>(
      key: 'title',
      id: 'device:1',
      replicaId: 'device',
      timestamp: HlcTimestamp(20, 0),
      value: 'draft',
    );
    final delta = Delta.crdt([first, first]);
    final merged = delta.merge(Delta.crdt([first]));

    expect(delta.changes, isEmpty);
    expect(merged.crdtChanges, hasLength(1));
    expect(merged.crdtChanges.single, first);
  });

  test('LWW Delta-CRDT retains delete tombstone', () {
    const delta = LwwDelta<String>(
      key: 'title',
      id: 'device:2',
      replicaId: 'device',
      timestamp: HlcTimestamp(21, 0),
      value: null,
      deleted: true,
    );
    final register = LwwRegister<String>()..applyDelta(delta);

    expect(register.value, isNull);
    expect(register.hasValue, isFalse);
    expect(register.isDeleted, isTrue);
  });

  test('Replica applies and exports native CRDT deltas', () {
    const delta = LwwDelta<String>(
      key: 'title',
      id: 'device:3',
      replicaId: 'device',
      timestamp: HlcTimestamp(30, 0),
      value: 'native',
    );
    final replica = Replica('target')..apply(Delta.crdt([delta]));

    expect(replica.state.values, {'title': 'native'});
    expect(replica.export().crdtChanges, [delta]);
  });

  test(
    'native delta remains canonical when legacy operation arrives later',
    () {
      const delta = LwwDelta<String>(
        key: 'title',
        id: 'device:4',
        replicaId: 'device',
        timestamp: HlcTimestamp(40, 0),
        value: 'native',
      );
      final legacy = Replica('legacy')..set('title', 'legacy');
      final register = LwwRegister<String>()..applyDelta(delta);
      register.apply(legacy.export().changes.single);

      expect(register.value, 'native');
      expect(register.toJson()['winner'], delta.toJson());
    },
  );

  test('Replica native mutations use HLC and converge', () {
    final first = Replica('first', hlc: HlcClock(nowMilliseconds: () => 100));
    final second = Replica('second', hlc: HlcClock(nowMilliseconds: () => 100));
    first.setDelta('title', 'first');
    second.setDelta('title', 'second');

    final left = Replica('left')..apply(first.export());
    left.apply(second.export());
    final right = Replica('right')..apply(second.export());
    right.apply(first.export());

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
