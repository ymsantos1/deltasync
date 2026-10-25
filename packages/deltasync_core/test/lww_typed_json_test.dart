import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

List<int> _intList(Object? json) => List<int>.from(json as List);

Map<String, List<int>> _nestedMap(Object? json) => (json as Map).map(
  (key, value) => MapEntry(key as String, List<int>.from(value as List)),
);

void main() {
  test('typed list keeps input and consulted values isolated', () {
    final supplied = [1, 2];
    final delta = LwwDelta<List<int>>(
      key: 'scores',
      id: 'a:1',
      replicaId: 'a',
      timestamp: const HlcTimestamp(1, 0),
      value: supplied,
      decodeValue: _intList,
    );
    final register = LwwRegister<List<int>>(decodeValue: _intList)
      ..applyDelta(delta);
    supplied.add(3);
    expect(delta.value, [1, 2]);
    delta.value!.add(6);
    expect(delta.value, [1, 2]);
    expect(register.value, [1, 2]);
    register.value!.add(4);
    register.winner!.value!.add(5);
    expect(register.value, [1, 2]);
    expect(register.toJson()['winner'], {
      ...delta.toJson(),
      'value': [1, 2],
    });

    final restoredDelta = LwwDelta<List<int>>.fromJson(
      register.winner!.toJson(),
      decodeValue: _intList,
    );
    final joined = LwwRegister<List<int>>(decodeValue: _intList)
      ..applyDelta(restoredDelta);
    expect(joined.value, [1, 2]);
    joined.mergeState(register);
    expect(joined.value, [1, 2]);
  });

  test('typed nested map survives JSON and join with independent children', () {
    final supplied = <String, List<int>>{
      'a': [1],
    };
    final first = LwwRegister<Map<String, List<int>>>(decodeValue: _nestedMap)
      ..applyDelta(
        LwwDelta<Map<String, List<int>>>(
          key: 'nested',
          id: 'a:1',
          replicaId: 'a',
          timestamp: const HlcTimestamp(2, 0),
          value: supplied,
          decodeValue: _nestedMap,
        ),
      );
    supplied['a']!.add(2);
    supplied['b'] = [3];
    expect(first.winner!.value, {
      'a': [1],
    });
    expect(first.value, {
      'a': [1],
    });
    first.value!['a']!.add(4);
    first.winner!.value!['a']!.add(5);
    expect(first.value, {
      'a': [1],
    });

    final encoded = first.winner!.toJson();
    final restored = LwwDelta<Map<String, List<int>>>.fromJson(
      encoded,
      decodeValue: _nestedMap,
    );
    (encoded['value'] as Map)['a'] = [8];
    expect(restored.value, {
      'a': [1],
    });
    final second = LwwRegister<Map<String, List<int>>>(decodeValue: _nestedMap)
      ..applyDelta(restored);
    expect(second.value, {
      'a': [1],
    });
    second.mergeState(first);
    expect(second.value, {
      'a': [1],
    });
  });

  test('typed contract rejects missing conversion and invalid JSON', () {
    final raw = LwwDelta<List<int>>(
      key: 'scores',
      id: 'a:1',
      replicaId: 'a',
      timestamp: const HlcTimestamp(1, 0),
      value: [1, 2],
      decodeValue: _intList,
    );
    expect(
      () => LwwRegister<List<int>>().applyDelta(raw),
      throwsFormatException,
    );
    expect(
      () => LwwDelta<List<int>>.fromJson(raw.toJson()),
      throwsFormatException,
    );
    expect(
      () => LwwRegister<List<int>>(decodeValue: _intList).applyDelta(
        LwwDelta<List<int>>(
          key: 'scores',
          id: 'a:2',
          replicaId: 'a',
          timestamp: const HlcTimestamp(2, 0),
          value: <int>[1, 2],
          decodeValue: _intList,
        ),
      ),
      returnsNormally,
    );
    expect(
      () => LwwDelta<Object?>.fromJson({
        ...raw.toJson(),
        'value': {'bad': double.nan},
      }),
      throwsFormatException,
    );
    expect(
      () => LwwRegister<List<int>>(decodeValue: (_) => [9]).applyDelta(raw),
      throwsFormatException,
    );
    expect(
      () => LwwDelta<List<int>>.fromJson(raw.toJson(), decodeValue: (_) => [9]),
      throwsFormatException,
    );
  });

  test('null, timestamp tie, and tombstone retain LWW ordering', () {
    final register = LwwRegister<List<int>>(decodeValue: _intList);
    register.applyDelta(
      LwwDelta<List<int>>(
        key: 'scores',
        id: 'a:1',
        replicaId: 'a',
        timestamp: HlcTimestamp(1, 0),
        value: null,
      ),
    );
    expect(register.hasValue, isTrue);
    expect(register.value, isNull);
    register.applyDelta(
      LwwDelta<List<int>>(
        key: 'scores',
        id: 'b:1',
        replicaId: 'b',
        timestamp: HlcTimestamp(1, 0),
        value: null,
        deleted: true,
      ),
    );
    expect(register.isDeleted, isTrue);
    register.applyDelta(
      LwwDelta<List<int>>(
        key: 'scores',
        id: 'a:2',
        replicaId: 'a',
        timestamp: const HlcTimestamp(1, 0),
        value: [9],
        decodeValue: _intList,
      ),
    );
    expect(register.isDeleted, isTrue);
    expect(register.winner!.replicaId, 'b');
  });

  test('Replica Object? route keeps nested LWW values isolated', () {
    final input = <String, Object?>{
      'numbers': [1, 2],
    };
    final source = Replica('source');
    final delta = source.setDelta('settings', input);
    input['numbers'] = [99];
    final receiver = Replica('receiver')..apply(Delta([delta]));
    final queried = receiver.state.values['settings'] as Map<String, Object?>;
    expect(() => (queried['numbers'] as List).add(3), throwsUnsupportedError);
    expect(receiver.state.values['settings'], {
      'numbers': [1, 2],
    });
    expect(
      Replica.fromSnapshotJson(receiver.toSnapshotJson())
          .state
          .values['settings'],
      {
        'numbers': [1, 2],
      },
    );
  });
}
