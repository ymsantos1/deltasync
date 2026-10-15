import 'dart:collection';
import 'dart:convert';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_core/src/replica/delta_validation.dart';
import 'package:test/test.dart';

void main() {
  test('MV batch validation does not expand the public context view', () {
    final delta = _ObservedContextDelta();
    final replica = Replica('receiver');
    replica.apply(Delta([delta]));
    replica.apply(Delta([delta]));
    expect(delta.expansions, 0);
    expect(replica.mvRegisterValue('field'), {'next'});
    expect(delta.context.map((dot) => dot.counter), [1, 3]);
    expect(delta.expansions, 1);
    expect(() => delta.context.clear(), throwsUnsupportedError);
    final restored = Replica.fromSnapshotJson(replica.toSnapshotJson());
    expect(restored.mvRegisterValue('field'), {'next'});
  });

  test(
    'compact MV prefix and sparse gap survive receive, codec and restore',
    () {
      const prefix = 10000;
      final delta = MvRegisterDelta.fromJson({
        'id': crdtDeltaId('mv-register', 'field', 'origin', prefix + 3),
        'replicaId': 'origin',
        'crdtId': 'field',
        'dot': {
          'replicaId': 'origin',
          'crdtId': 'field',
          'counter': prefix + 3,
        },
        'value': 'next',
        'context': {
          'crdtId': 'field',
          'replicas': {
            'origin': {
              'prefix': prefix,
              'sparse': [prefix + 2],
            },
          },
        },
      });
      final replica = Replica('receiver')
        ..apply(DeltaCodec.decode(DeltaCodec.encode(Delta([delta]))));
      final snapshot = replica.toSnapshotJson();
      final register = (snapshot['mvRegisters'] as Map)['field'] as Map;
      final encoded =
          ((register['context'] as Map)['replicas'] as Map)['origin'];
      expect(encoded, {
        'prefix': prefix,
        'sparse': [prefix + 2, prefix + 3],
      });
      final restored = Replica.fromSnapshotJson(snapshot);
      restored.apply(
        Delta([
          MvRegisterDelta(
            id: crdtDeltaId('mv-register', 'field', 'origin', prefix + 1),
            replicaId: 'origin',
            crdtId: 'field',
            dot: const Dot(
              replicaId: 'origin',
              crdtId: 'field',
              counter: prefix + 1,
            ),
            value: 'previously unseen',
            context: const [],
          ),
        ]),
      );
      expect(restored.mvRegisterValue('field'), {'next', 'previously unseen'});
    },
  );

  test('JSON validation traverses input once without rewriting it', () {
    final input = _ObservedList([
      1,
      null,
      {
        'nested': [true, 'text'],
      },
    ]);
    validateJsonInput({'input': input});
    expect(input.reads, 3);
    expect(input.length, 3);
    input[0] = 2;
    expect(input[0], 2);
  });

  test('JSON validation rejects invalid values before any local mutation', () {
    final listCycle = <Object?>[];
    listCycle.add(listCycle);
    final mapCycle = <String, Object?>{};
    mapCycle['self'] = mapCycle;
    final invalid = [
      Object(),
      double.nan,
      double.infinity,
      {1: 'bad'},
      listCycle,
      mapCycle,
    ];
    final mutations = <void Function(Replica, Object?)>[
      (replica, value) => replica.setDelta('title', value),
      (replica, value) => replica.writeMvRegister('field', value),
      (replica, value) => replica.addOrSet('members', value),
      (replica, value) => replica.removeOrSet('members', value),
      (replica, value) => replica.addOrMapValue('profile', 'roles', value),
    ];
    for (final value in invalid) {
      expect(() => validateJsonInput(value), throwsArgumentError);
      expect(() => copyJsonValue(value), throwsArgumentError);
      for (final mutate in mutations) {
        final replica = Replica('local');
        final before = replica.toSnapshotJson();
        expect(() => mutate(replica, value), throwsArgumentError);
        expect(replica.toSnapshotJson(), before);
        expect(replica.setDelta('valid', true).id, 'local:delta:1');
      }
    }
  });

  test('JSON validation preserves collection-read exception conversion', () {
    for (final error in [
      UnsupportedError('read'),
      JsonUnsupportedObjectError(Object()),
    ]) {
      final value = _FailingReadList(error);
      expect(() => validateJsonInput(value), throwsArgumentError);
      final replica = Replica('local');
      final before = replica.toSnapshotJson();
      expect(() => replica.setDelta('title', value), throwsArgumentError);
      expect(replica.toSnapshotJson(), before);
    }
  });

  test('JSON validation preserves the first failure in input order', () {
    final first = Object();
    expect(
      () => validateJsonInput({
        'first': first,
        'second': {1: 'bad'},
      }),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.invalidValue,
          'first invalid value',
          same(first),
        ),
      ),
    );
  });

  test('shared JSON DAGs remain valid and copies retain their isolation', () {
    final shared = <Object?>[
      1,
      {
        'nested': [true],
      },
    ];
    final source = {'left': shared, 'right': shared};
    validateJsonInput(source);
    final mutable = copyJsonValue(source) as Map;
    final frozen = copyJsonValue(source, freeze: true) as Map;
    (mutable['left'] as List)[0] = 2;
    expect((mutable['right'] as List)[0], 1);
    shared[0] = 3;
    expect((frozen['left'] as List)[0], 1);
    expect(() => (frozen['left'] as List).add(4), throwsUnsupportedError);
    expect(
      () => (((frozen['right'] as List)[1] as Map)['nested'] as List).clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'point query preserves absence, null, tombstones and frozen nested values',
    () {
      final replica = Replica('local')
        ..setDelta('nested', {
          'items': [1, 2],
        })
        ..setDelta('null', null)
        ..setDelta('deleted', 'old')
        ..removeDelta('deleted')
        ..incrementGCounter('counter');
      final state = replica.state;
      expect(state['absent'], isNull);
      expect(state['null'], isNull);
      expect(state['deleted'], isNull);
      expect(state['counter'], isNull);
      expect(state.values.containsKey('null'), isTrue);
      expect(state.values.containsKey('deleted'), isFalse);
      final value = state['nested'] as Map;
      expect(() => value['items'] = [], throwsUnsupportedError);
      expect(() => (value['items'] as List).clear(), throwsUnsupportedError);
      final snapshot = state.toSnapshotJson();
      ((snapshot['nested'] as Map)['winner'] as Map)['value'] = false;
      expect(state['nested'], {
        'items': [1, 2],
      });
      expect(replica.state['nested'], {
        'items': [1, 2],
      });
    },
  );
}

class _ObservedContextDelta extends MvRegisterDelta {
  _ObservedContextDelta()
    : super(
        id: crdtDeltaId('mv-register', 'field', 'origin', 4),
        replicaId: 'origin',
        crdtId: 'field',
        dot: const Dot(replicaId: 'origin', crdtId: 'field', counter: 4),
        value: 'next',
        context: const [
          Dot(replicaId: 'origin', crdtId: 'field', counter: 1),
          Dot(replicaId: 'origin', crdtId: 'field', counter: 3),
        ],
      );
  int expansions = 0;
  @override
  List<Dot> get context {
    expansions++;
    return super.context;
  }
}

class _ObservedList extends ListBase<Object?> {
  _ObservedList(this._items);
  final List<Object?> _items;
  int reads = 0;
  @override
  int get length => _items.length;
  @override
  set length(int value) => _items.length = value;
  @override
  Object? operator [](int index) {
    reads++;
    return _items[index];
  }

  @override
  void operator []=(int index, Object? value) => _items[index] = value;
}

class _FailingReadList extends _ObservedList {
  _FailingReadList(this.error) : super([null]);
  final Object error;
  @override
  Object? operator [](int index) => throw error;
}
