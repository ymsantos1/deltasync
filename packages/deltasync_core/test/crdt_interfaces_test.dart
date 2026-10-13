import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('native changes expose shared typed metadata and stable labels', () {
    final replica = Replica('device');
    final changes = <DeltaChange>[
      replica.setDelta('title', 'draft'),
      replica.incrementGCounter('cart/count'),
      replica.incrementPnCounter('wallet/balance'),
      replica.addGSet('labels', 'draft'),
      replica.addTwoPSet('members', 'device'),
      replica.addOrSet('observed-members', 'device'),
      replica.addOrMapKey('profile', 'roles'),
    ];

    expect(changes.map((change) => change.kind), [
      CrdtKind.lww,
      CrdtKind.gCounter,
      CrdtKind.pnCounter,
      CrdtKind.gSet,
      CrdtKind.twoPSet,
      CrdtKind.orSet,
      CrdtKind.orMap,
    ]);
    expect(changes.map((change) => change.crdtId), [
      'title',
      'cart/count',
      'wallet/balance',
      'labels',
      'members',
      'observed-members',
      'profile',
    ]);
    expect(changes.map((change) => change.replicaId), everyElement('device'));
    expect(changes.map((change) => change.toJson()['type']), [
      'lww',
      'g-counter',
      'pn-counter',
      'g-set',
      '2p-set',
      'or-set',
      'or-map',
    ]);
    expect(CrdtKind.fromWire('pn-counter'), CrdtKind.pnCounter);
    expect(CrdtKind.fromWire('g-set'), CrdtKind.gSet);
    expect(CrdtKind.fromWire('2p-set'), CrdtKind.twoPSet);
    expect(() => CrdtKind.fromWire('future'), throwsFormatException);
  });

  test('local LWW rejects invalid addresses and values before mutation', () {
    final replica = Replica('device');

    expect(() => replica.setDelta('', 'invalid'), throwsArgumentError);
    expect(() => replica.setDelta('title', Object()), throwsArgumentError);
    final cyclic = <Object?>[];
    cyclic.add(cyclic);
    expect(() => replica.setDelta('cycle', cyclic), throwsArgumentError);
    expect(() => replica.incrementGCounter(''), throwsArgumentError);
    expect(() => replica.addGSet('', 'invalid'), throwsArgumentError);
    expect(() => replica.addAllGSet('labels', []), throwsArgumentError);
    expect(() => replica.addGSet('labels', Object()), throwsArgumentError);
    expect(
      () => replica.incrementGCounter('cart/items', 0),
      throwsArgumentError,
    );
    expect(
      () => replica.incrementPnCounter('cart/items', 0),
      throwsArgumentError,
    );
    expect(replica.clock.entries, isEmpty);
    expect(replica.export().isEmpty, isTrue);

    final valid = replica.setDelta('title', {
      'labels': ['draft'],
      'visible': true,
    });
    expect(valid.id, 'device:delta:1');
    final encoded = DeltaCodec.encode(Delta([valid]));
    final restored = Replica('other')..apply(DeltaCodec.decode(encoded));
    expect(restored.state['title'], {
      'labels': ['draft'],
      'visible': true,
    });
  });

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
        LwwDelta<String>(
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

  test('invalid G-Set addition does not bind replica address', () {
    final replica = Replica('device');
    expect(() => replica.addGSet('labels', Object()), throwsArgumentError);
    expect(replica.setDelta('labels', 'text').id, 'device:delta:1');
  });

  test('DeltaCodec round trips and rejects unknown versions', () {
    final replica = Replica('device-a');
    final delta = Delta([replica.setDelta('title', 'draft')]);

    expect(DeltaCodec.decode(DeltaCodec.encode(delta)).changes, [
      delta.changes.single,
    ]);
    expect(
      () => DeltaCodec.decode({...DeltaCodec.encode(delta), 'version': 99}),
      throwsFormatException,
    );
  });

  test(
    'DeltaCodec round trips every native kind and rejects unknown labels',
    () {
      final replica = Replica('device')
        ..setDelta('title', 'draft')
        ..incrementGCounter('cart/count')
        ..incrementPnCounter('wallet/balance')
        ..addGSet('labels', 'draft')
        ..addTwoPSet('members', 'draft')
        ..addOrSet('observed-members', 'draft')
        ..addOrMapKey('profile', 'roles');
      final delta = DeltaCodec.decode(DeltaCodec.encode(replica.export()));

      expect(delta.changes, replica.export().changes);
      expect(delta.changes.map((change) => change.toJson()['type']), [
        'lww',
        'g-counter',
        'pn-counter',
        'g-set',
        '2p-set',
        'or-set',
        'or-map',
      ]);
      expect(
        () => DeltaCodec.decode({
          'version': DeltaCodec.currentVersion,
          'delta': {
            'changes': [
              {'type': 'future-crdt'},
            ],
          },
        }),
        throwsFormatException,
      );
    },
  );

  test('G-Counter merges component maxima idempotently', () {
    final first = GCounter('first', crdtId: 'shared-items');
    final second = GCounter('second', crdtId: 'shared-items');
    final firstDelta = first.increment(2);
    final secondDelta = second.increment(3);

    final left = GCounter('left', crdtId: 'shared-items');
    left.applyDelta(firstDelta);
    left.applyDelta(secondDelta);
    left.applyDelta(firstDelta);
    final right = GCounter('right', crdtId: 'shared-items');
    right.applyDelta(secondDelta);
    right.applyDelta(firstDelta);

    expect(left.value, 5);
    expect(left.components, right.components);
    expect(firstDelta.dot!.counter, 1);
  });

  test('G-Counter state join is associative, commutative, and idempotent', () {
    final first = GCounter('first', crdtId: 'shared-items')..increment(2);
    final second = GCounter('second', crdtId: 'shared-items')..increment(3);
    final third = GCounter('third', crdtId: 'shared-items')..increment(5);

    GCounter merge(GCounter left, GCounter right) =>
        GCounter('join', crdtId: 'shared-items')
          ..mergeState(left)
          ..mergeState(right);

    final firstSecond = merge(first, second);
    final secondFirst = merge(second, first);
    final leftAssociated = merge(firstSecond, third);
    final rightAssociated = merge(first, merge(second, third));

    expect(firstSecond.toJson(), secondFirst.toJson());
    final empty = GCounter('empty', crdtId: 'shared-items');
    expect(merge(first, first).toJson(), merge(first, empty).toJson());
    expect(leftAssociated.toJson(), rightAssociated.toJson());
  });

  test(
    'G-Set unions additions idempotently and retains incremental deltas',
    () {
      final alice = GSet('alice', crdtId: 'labels');
      final bob = GSet('bob', crdtId: 'labels');
      final first = alice.addAll([
        'red',
        {
          'name': 'blue',
          'shade': [2, 4],
        },
      ]);
      final second = alice.add('red');
      final nestedDuplicate = alice.add({
        'shade': [2, 4],
        'name': 'blue',
      });
      final third = bob.addAll(['green', 'red']);
      final decoded = [first, second, third]
          .map(
            (change) =>
                DeltaCodec.decode(
                      DeltaCodec.encode(Delta([change])),
                    ).changes.single
                    as GSetDelta,
          )
          .toList();

      final orders = [
        decoded,
        [decoded[2], decoded[0], decoded[1]],
        [decoded[1], decoded[2], decoded[0]],
      ];
      final states = <GSet>[];
      for (final order in orders) {
        final state = GSet('receiver', crdtId: 'labels');
        for (final change in order) {
          state.applyDelta(change);
          state.applyDelta(change);
        }
        expect(state.value.length, 3);
        expect(state.value.contains('red'), isTrue);
        expect(state.value.contains('green'), isTrue);
        expect(
          state.value.contains({
            'name': 'blue',
            'shade': [2, 4],
          }),
          isTrue,
        );
        states.add(state);
      }
      expect(states[0].toJson(), states[1].toJson());
      expect(states[1].toJson(), states[2].toJson());
      expect(first.elements, [
        'red',
        {
          'name': 'blue',
          'shade': [2, 4],
        },
      ]);
      expect(nestedDuplicate.elements, [
        {
          'name': 'blue',
          'shade': [2, 4],
        },
      ]);
      expect(alice.value.length, 2);
      expect(
        alice.value.contains({
          'shade': [2, 4],
          'name': 'blue',
        }),
        isTrue,
      );
      expect(alice.exportChanges(), hasLength(1));
      expect(
        () => states[0].value.add('write-through'),
        throwsUnsupportedError,
      );
      expect(second.elements, ['red']);

      final conflicting = GSetDelta(
        id: first.id,
        replicaId: first.replicaId,
        crdtId: first.crdtId,
        elements: ['different'],
        dot: first.dot,
      );
      expect(() => alice.applyDelta(conflicting), throwsFormatException);
    },
  );

  test('G-Set state join is associative, commutative, and idempotent', () {
    final a = GSet('a', crdtId: 'tags')..addAll(['x', 'shared']);
    final b = GSet('b', crdtId: 'tags')..addAll(['y', 'shared']);
    final c = GSet('c', crdtId: 'tags')..addAll(['z']);

    GSet copy(GSet source) => GSet.fromJson(source.toJson());
    GSet join(GSet first, GSet second) => copy(first)..mergeState(second);

    final ab = join(a, b);
    final ba = join(b, a);
    expect(ab.value, ba.value);
    expect(
      ab.exportChanges().map((change) => change.id).toSet(),
      ba.exportChanges().map((change) => change.id).toSet(),
    );
    final aa = join(a, a);
    expect(aa.toJson(), a.toJson());
    expect(join(ab, c).toJson(), join(a, join(b, c)).toJson());
    expect(join(ab, c).value, containsAll(['x', 'shared', 'y', 'z']));
  });

  test('G-Set snapshot join preserves local sequence after duplicate adds', () {
    final original = GSet('device', crdtId: 'tags')..add('known');
    final restored = GSet.fromJson(original.toJson());
    restored.add('known');
    final target = GSet.fromJson(original.toJson())..mergeState(restored);

    expect(target.add('next').dot.counter, 3);
  });

  test(
    'Replica routes G-Set through delta codec, export, and snapshot restore',
    () {
      final source = Replica('source');
      final first = source.addAllGSet('labels', ['one', 'two']);
      final repeated = source.addGSet('labels', 'one');
      final delta = DeltaCodec.decode(DeltaCodec.encode(source.export()));
      final remote = Replica('remote')..apply(delta);

      expect(delta.changes, contains(first));
      expect(delta.changes, isNot(contains(repeated)));
      expect(repeated.elements, ['one']);
      expect(remote.gSetValue('labels').length, 2);
      expect(remote.gSetValue('labels'), containsAll(['one', 'two']));
      expect(source.toSnapshotJson()['version'], 9);
      final setSnapshot =
          ((source.toSnapshotJson()['gSets'] as Map)['labels'] as Map);
      expect(setSnapshot['changes'], hasLength(1));

      final restored = Replica.fromSnapshotJson(source.toSnapshotJson());
      expect(restored.gSetValue('labels'), containsAll(['one', 'two']));
      final next = restored.addGSet('labels', 'three');
      expect(next.dot.counter, 3);

      final conflicting = Replica('other')..setDelta('shared-address', true);
      final gSetDelta = Replica('gset-source').addGSet('shared-address', 'x');
      expect(
        () => conflicting.apply(Delta([gSetDelta])),
        throwsFormatException,
      );
      expect(conflicting.state.values, {'shared-address': true});
    },
  );

  test('PN-Counter converges across increment and decrement deltas', () {
    final first = PnCounter('first', crdtId: 'shared-balance');
    final second = PnCounter('second', crdtId: 'shared-balance');
    final deltas = [first.increment(5), second.decrement(2)];

    final left = PnCounter('left', crdtId: 'shared-balance');
    final right = PnCounter('right', crdtId: 'shared-balance');
    left.applyDelta(deltas[0]);
    left.applyDelta(deltas[1]);
    right.applyDelta(deltas[1]);
    right.applyDelta(deltas[0]);

    expect(left.value, 3);
    expect(left.positive, right.positive);
    expect(left.negative, right.negative);
  });

  test('PN-Counter state join is associative, commutative, and idempotent', () {
    final first = PnCounter('first', crdtId: 'shared-balance')..increment(5);
    final second = PnCounter('second', crdtId: 'shared-balance')..decrement(2);
    final third = PnCounter('third', crdtId: 'shared-balance')
      ..increment(3)
      ..decrement(1);

    PnCounter merge(PnCounter left, PnCounter right) =>
        PnCounter('join', crdtId: 'shared-balance')
          ..mergeState(left)
          ..mergeState(right);

    final firstSecond = merge(first, second);
    final secondFirst = merge(second, first);
    final leftAssociated = merge(firstSecond, third);
    final rightAssociated = merge(first, merge(second, third));

    expect(firstSecond.toJson(), secondFirst.toJson());
    final empty = PnCounter('empty', crdtId: 'shared-balance');
    expect(merge(first, first).toJson(), merge(first, empty).toJson());
    expect(leftAssociated.toJson(), rightAssociated.toJson());
    expect(leftAssociated.value, 5);
  });

  test('G-Set snapshot reconciliation matches exchanged deltas', () {
    final first = Replica('first')..addAllGSet('tags', ['a', 'shared']);
    final second = Replica('second')..addAllGSet('tags', ['b', 'shared']);
    final exchanged = Replica('receiver')
      ..apply(Delta([...first.export().changes, ...second.export().changes]));
    final reconciled = Replica('receiver')
      ..mergeSnapshotJson(first.toSnapshotJson())
      ..mergeSnapshotJson(second.toSnapshotJson());

    expect(exchanged.gSetValue('tags'), containsAll(['a', 'b', 'shared']));
    expect(reconciled.gSetValue('tags'), exchanged.gSetValue('tags'));
    expect(
      reconciled.export().changes.map((change) => change.id).toSet(),
      exchanged.export().changes.map((change) => change.id).toSet(),
    );
  });

  test('PN-Counter rejects malformed delta without partial component join', () {
    final counter = PnCounter('local', crdtId: 'balance');
    final invalid = PnCounterDelta(
      id: counterDeltaId('pn-counter', 'balance', 'remote', 1),
      replicaId: 'remote',
      crdtId: 'balance',
      positive: 5,
      negative: -1,
      dot: const Dot(replicaId: 'remote', counter: 1, crdtId: 'balance'),
    );

    expect(() => counter.applyDelta(invalid), throwsFormatException);
    expect(counter.positive, isEmpty);
    expect(counter.negative, isEmpty);
    expect(counter.value, 0);
  });

  test('counter deltas survive versioned JSON codec', () {
    final counter = GCounter('device', crdtId: 'cart/quantity')..increment(4);
    final delta = Delta([counter.increment(2)]);

    final decoded = DeltaCodec.decode(DeltaCodec.encode(delta));
    expect(decoded.changes.single, delta.changes.single);
  });

  test('Replica routes addressed counters and LWW in mixed batch', () {
    final local = Replica('device-a');
    final apples = local.incrementGCounter('cart/apples', 2);
    final pears = local.incrementGCounter('cart/pears', 3);
    final balanceUp = local.incrementPnCounter('account/balance', 5);
    final balanceDown = local.decrementPnCounter('account/balance', 2);
    final title = local.setDelta('title', 'draft');
    final delta = Delta([apples, pears, balanceUp, balanceDown, title]);

    expect({apples.id, pears.id}.length, 2);
    expect(apples.dot!.counter, pears.dot!.counter);
    expect(apples.dot!.crdtId, 'cart/apples');
    expect(pears.dot!.crdtId, 'cart/pears');
    expect(local.clock.entries, {'device-a': 1});

    final restored = Replica('device-a')
      ..apply(DeltaCodec.decode(DeltaCodec.encode(delta)));
    expect(restored.state.values, {'title': 'draft'});
    expect(restored.gCounterValue('cart/apples'), 2);
    expect(restored.gCounterValue('cart/pears'), 3);
    expect(restored.pnCounterValue('account/balance'), 3);
    expect(restored.incrementGCounter('cart/apples').dot!.counter, 2);
    expect(restored.incrementPnCounter('account/balance').dot!.counter, 3);
  });

  test('Replica rejects invalid or conflicting counter batch atomically', () {
    final source = Replica('device-a');
    final valid = source.incrementGCounter('items');
    final invalid = GCounterDelta(
      id: 'invalid-change-id',
      replicaId: 'device-a',
      crdtId: 'other-items',
      value: 1,
      dot: valid.dot,
    );
    final target = Replica('target');
    final batch = Delta([
      LwwDelta<Object?>(
        key: 'title',
        id: 'remote:delta:1',
        replicaId: 'remote',
        timestamp: HlcTimestamp(1, 0),
        value: 'must not apply',
      ),
      valid,
      invalid,
    ]);

    expect(() => target.apply(batch), throwsFormatException);
    expect(target.state.values, isEmpty);
    expect(target.gCounterValue('items'), 0);

    final conflicting = GCounterDelta(
      id: valid.id,
      replicaId: valid.replicaId,
      crdtId: valid.crdtId,
      value: valid.value + 1,
      dot: valid.dot,
    );
    expect(
      () => target.apply(Delta([valid, conflicting])),
      throwsFormatException,
    );
    expect(target.gCounterValue('items'), 0);
  });

  test('version 1 counter codec migrates to stable legacy address', () {
    final legacy = {
      'version': 1,
      'delta': {
        'operations': [],
        'crdtChanges': [
          {
            'type': 'g-counter',
            'id': 'device-a:g-counter:1',
            'replicaId': 'device-a',
            'value': 2,
            'dot': {'replicaId': 'device-a', 'counter': 1},
          },
        ],
      },
    };
    final decoded = DeltaCodec.decode(legacy);
    final migrated = decoded.changes.single as GCounterDelta;

    expect(migrated.crdtId, 'legacy/g-counter/device-a');
    expect(migrated.dot!.crdtId, migrated.crdtId);
    final replica = Replica('device-a')..apply(decoded);
    expect(replica.gCounterValue(migrated.crdtId), 2);
    expect(DeltaCodec.encode(decoded)['version'], DeltaCodec.currentVersion);
    expect(
      () => DeltaCodec.decode({...legacy, 'version': 2}),
      throwsFormatException,
    );
    final conflictingLegacy = Map<String, Object?>.from(legacy);
    final legacyDelta = Map<String, Object?>.from(
      conflictingLegacy['delta']! as Map,
    );
    legacyDelta['crdtChanges'] = [
      ...(legacyDelta['crdtChanges']! as List),
      {
        'type': 'g-counter',
        'id': 'device-a:g-counter:1',
        'replicaId': 'device-a',
        'value': 3,
        'dot': {'replicaId': 'device-a', 'counter': 1},
      },
    ];
    conflictingLegacy['delta'] = legacyDelta;
    expect(() => DeltaCodec.decode(conflictingLegacy), throwsFormatException);
  });

  test('restored counters continue causal delta sequence', () {
    final gCounter = GCounter(
      'device',
      crdtId: 'cart/quantity',
      components: {'device': 4},
      sequence: 5,
    )..increment(2);
    final pnCounter = PnCounter(
      'device',
      crdtId: 'account/balance',
      positive: {'device': 4},
      negative: {'device': 1},
      sequence: 6,
    )..increment(2);

    expect(gCounter.increment().dot!.counter, 7);
    expect(pnCounter.increment().dot!.counter, 8);
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

  test('LwwRegister keeps delete as tombstone', () {
    final register = LwwRegister<Object?>();
    final replica = Replica('device-a');
    final set = replica.setDelta('title', 'draft');
    final delete = replica.removeDelta('title');

    register.applyDelta(set);
    register.applyDelta(delete);

    expect(register.value, isNull);
    expect(register.isDeleted, isTrue);
    expect(register.toJson(), {'winner': delete.toJson()});
  });

  test('LwwRegister resolves concurrent operations deterministically', () {
    final first = Replica('first')..setDelta('title', 'first');
    final second = Replica('second')..setDelta('title', 'second');
    final firstDelta = first.setDelta('title', 'first');
    final secondDelta = second.setDelta('title', 'second');

    final left = LwwRegister<Object?>()..applyDelta(firstDelta);
    left.applyDelta(secondDelta);
    final right = LwwRegister<Object?>()..applyDelta(secondDelta);
    right.applyDelta(firstDelta);

    expect(left.value, right.value);
    expect(left.toJson(), right.toJson());
  });

  test('legacy LWW codec migration preserves total old ordering', () {
    final z = Operation(
      id: 'z:1',
      replicaId: 'z',
      type: 'lww.set',
      vectorClock: VectorClock({'z': 1}),
      payload: {'key': 'title', 'value': 'z'},
    );
    final a = Operation(
      id: 'a:1',
      replicaId: 'a',
      type: 'lww.set',
      vectorClock: VectorClock({'z': 1, 'a': 1}),
      payload: {'key': 'title', 'value': 'a'},
    );
    final m = Operation(
      id: 'm:1',
      replicaId: 'm',
      type: 'lww.set',
      vectorClock: VectorClock({'m': 1}),
      payload: {'key': 'title', 'value': 'm'},
    );
    final orders = [
      [z, a, m],
      [z, m, a],
      [a, z, m],
      [a, m, z],
      [m, z, a],
      [m, a, z],
    ];

    for (final order in orders) {
      final migrated = DeltaCodec.decode({
        'version': 2,
        'delta': {
          'operations': [for (final operation in order) operation.toJson()],
          'crdtChanges': [],
        },
      });
      final replica = Replica('receiver')..apply(migrated);
      expect(replica.state.values['title'], 'a');
    }
    expect(migrateLegacyOperation(z).timestamp, HlcTimestamp(1, 0));
    expect(migrateLegacyOperation(a).timestamp, HlcTimestamp(2, 0));
    expect(migrateLegacyOperation(m).timestamp, HlcTimestamp(1, 0));
  });

  test('LWW state converges when concurrent operations arrive reordered', () {
    final first = Replica('first')..setDelta('title', 'first');
    final second = Replica('second')..setDelta('title', 'second');

    final left = Replica('left')
      ..apply(Delta([...first.export().changes, ...second.export().changes]));
    final right = Replica('right')
      ..apply(Delta([...second.export().changes, ...first.export().changes]));

    expect(left.state.values, right.state.values);
  });

  test('LWW Delta-CRDT is idempotent and order independent', () {
    final first = LwwDelta<String>(
      key: 'title',
      id: 'first:1',
      replicaId: 'first',
      timestamp: HlcTimestamp(10, 0),
      value: 'first',
    );
    final second = LwwDelta<String>(
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

  test('LWW state join is associative, commutative, and idempotent', () {
    final firstDelta = LwwDelta<String>(
      key: 'title',
      id: 'first:1',
      replicaId: 'first',
      timestamp: HlcTimestamp(10, 0),
      value: 'first',
    );
    final secondDelta = LwwDelta<String>(
      key: 'title',
      id: 'second:1',
      replicaId: 'second',
      timestamp: HlcTimestamp(10, 0),
      value: 'second',
    );
    final thirdDelta = LwwDelta<String>(
      key: 'title',
      id: 'third:1',
      replicaId: 'third',
      timestamp: HlcTimestamp(10, 0),
      value: 'third',
    );
    final first = LwwRegister<String>()..applyDelta(firstDelta);
    final second = LwwRegister<String>()..applyDelta(secondDelta);
    final third = LwwRegister<String>()..applyDelta(thirdDelta);

    LwwRegister<String> merge(
      LwwRegister<String> left,
      LwwRegister<String> right,
    ) => LwwRegister<String>()
      ..mergeState(left)
      ..mergeState(right);

    final firstSecond = merge(first, second);
    final secondFirst = merge(second, first);
    final leftAssociated = merge(firstSecond, third);
    final rightAssociated = merge(first, merge(second, third));

    expect(firstSecond.toJson(), secondFirst.toJson());
    expect(merge(first, first).toJson(), first.toJson());
    expect(leftAssociated.toJson(), rightAssociated.toJson());
    expect(leftAssociated.value, 'third');
  });

  test('DeltaCrdt contract merges complete LWW state', () {
    final delta = LwwDelta<String>(
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

  test('ReplicaState.copy isolates mutable LWW registers', () {
    final replica = Replica('copy-source');
    replica.setDelta('title', 'before');
    final copy = replica.state.copy();
    replica.setDelta('title', 'after');

    expect(copy.values['title'], 'before');
    expect(replica.state.values['title'], 'after');
  });

  test(
    'versioned replica snapshot restores tombstones and local sequences',
    () {
      final source = Replica('snapshot-source')
        ..setDelta('deleted', 'old')
        ..removeDelta('deleted')
        ..incrementGCounter('items', 2)
        ..incrementPnCounter('balance', 4)
        ..setDelta('legacy', true);
      final restored = Replica.fromSnapshotJson(source.toSnapshotJson());

      expect(restored.id, source.id);
      expect(restored.state.values, {'legacy': true});
      expect(restored.hlcTimestamp, source.hlcTimestamp);
      expect(restored.incrementGCounter('items').dot!.counter, 2);
      expect(restored.incrementPnCounter('balance').dot!.counter, 2);
      expect(restored.setDelta('legacy', false).id, 'snapshot-source:delta:4');
      final versionThree = Map<String, Object?>.of(source.toSnapshotJson())
        ..remove('gSets')
        ..['version'] = 3;
      expect(
        Replica.fromSnapshotJson(versionThree).gSetValue('labels'),
        isEmpty,
      );
      expect(
        () => Replica.fromSnapshotJson({'version': 99}),
        throwsFormatException,
      );
    },
  );

  test('Delta carries native changes and merges them by delta ID', () {
    final first = LwwDelta<String>(
      key: 'title',
      id: 'device:1',
      replicaId: 'device',
      timestamp: HlcTimestamp(20, 0),
      value: 'draft',
    );
    final delta = Delta([first, first]);
    final merged = delta.merge(Delta([first]));

    expect(delta.changes, hasLength(2));
    expect(merged.changes, [first]);
  });

  test('LWW Delta-CRDT retains delete tombstone', () {
    final delta = LwwDelta<String>(
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
    final delta = LwwDelta<String>(
      key: 'title',
      id: 'device:3',
      replicaId: 'device',
      timestamp: HlcTimestamp(30, 0),
      value: 'native',
    );
    final replica = Replica('target')..apply(Delta([delta]));

    expect(replica.state.values, {'title': 'native'});
    expect(replica.export().changes.single.toJson(), delta.toJson());
  });

  test('legacy operations require explicit migration into native LWW', () {
    final delta = LwwDelta<Object?>(
      key: 'title',
      id: 'device:4',
      replicaId: 'device',
      timestamp: HlcTimestamp(40, 0),
      value: 'native',
    );
    final legacy = _operation('legacy:1', 'legacy');
    final register = LwwRegister<Object?>()..applyDelta(delta);
    register.applyDelta(migrateLegacyOperation(legacy));

    expect(register.value, 'native');
    expect(register.toJson()['winner'], delta.toJson());
  });

  test('legacy snapshot winner migrates once to native snapshot shape', () {
    const legacyClock = 7000000000000000;
    final operation = Operation(
      id: 'legacy:7',
      replicaId: 'legacy',
      type: 'lww.set',
      vectorClock: VectorClock({'legacy': legacyClock}),
      payload: {'key': 'title', 'value': 'value'},
    );
    final replica = Replica.fromSnapshotJson({
      'version': 1,
      'replicaId': 'legacy',
      'clock': {'legacy': legacyClock},
      'hlc': const HlcTimestamp(7, 0).toJson(),
      'operationSequence': 7,
      'deltaSequence': 0,
      'lww': {
        'title': {'legacyWinner': operation.toJson()},
      },
      'gCounters': <String, Object?>{},
      'pnCounters': <String, Object?>{},
    });

    expect(replica.state.values, {'title': 'value'});
    expect(replica.toSnapshotJson()['version'], 9);
    final migratedTimestamp = migrateLegacyOperation(operation).timestamp;
    expect(
      replica.setDelta('title', 'new').timestamp.compareTo(migratedTimestamp),
      greaterThan(0),
    );
    expect(replica.state.values, {'title': 'new'});
    expect((replica.state.toSnapshotJson()['title']! as Map).keys, {'winner'});
  });

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

  test('Replica protects nested values, reads, copies and snapshots', () {
    final input = {
      'labels': ['draft'],
      'settings': {'visible': true},
    };
    final replica = Replica('isolation')..setDelta('document', input);
    (input['labels'] as List<Object?>).add('outside');
    (input['settings']! as Map<String, Object?>)['visible'] = false;

    expect(replica.state['document'], {
      'labels': ['draft'],
      'settings': {'visible': true},
    });
    final read = replica.state.values['document'] as Map<String, Object?>;
    expect(
      () => (read['labels'] as List).add('outside'),
      throwsUnsupportedError,
    );
    final snapshot = replica.toSnapshotJson();
    expect(
      () => ((snapshot['lww'] as Map)['document'] as Map).clear(),
      throwsUnsupportedError,
    );

    final detached = replica.state;
    detached.applyDelta(
      LwwDelta<Object?>(
        key: 'document',
        id: 'elsewhere:delta:1',
        replicaId: 'elsewhere',
        timestamp: HlcTimestamp(999, 0),
        value: 'detached',
      ),
    );
    expect(replica.state['document'], {
      'labels': ['draft'],
      'settings': {'visible': true},
    });
  });

  test('Replica fork preserves injected HLC source and compact export', () {
    var physical = 10;
    final replica = Replica(
      'device',
      hlc: HlcClock(nowMilliseconds: () => physical),
    );
    replica
      ..setDelta('title', 'old')
      ..setDelta('title', 'current')
      ..incrementGCounter('items', 5)
      ..incrementGCounter('items', 2);
    final fork = replica.fork();
    physical = 20;
    expect(fork.setDelta('other', true).timestamp.physicalMilliseconds, 20);

    final bootstrap = replica.export();
    expect(bootstrap.changes, hasLength(2));
    final restored = Replica('peer')..apply(bootstrap);
    expect(restored.state.values, {'title': 'current'});
    expect(restored.gCounterValue('items'), 7);
    expect(restored.export().changes, hasLength(2));
    expect(replica.incrementGCounter('items').dot!.counter, 3);
  });

  test('restored current winner rejects divergent reuse of its ID', () {
    final replica = Replica('device')..setDelta('title', 'current');
    final winner = replica.export().changes.single as LwwDelta<Object?>;
    final conflicting = LwwDelta<Object?>(
      key: winner.key,
      id: winner.id,
      replicaId: winner.replicaId,
      timestamp: winner.timestamp,
      value: 'conflicting',
      dot: winner.dot,
    );

    expect(() => replica.apply(Delta([conflicting])), throwsFormatException);
    expect(replica.state['title'], 'current');
  });

  test('snapshot preserves address kind and latest counter identity', () {
    final original = Replica('device')
      ..incrementGCounter('items', 5)
      ..incrementGCounter('items', 2);
    final restored = Replica.fromSnapshotJson(original.toSnapshotJson());

    expect(restored.state.kindAt('items'), CrdtKind.gCounter);
    expect(
      restored.export().changes.single.id,
      original.export().changes.single.id,
    );
    expect(restored.incrementGCounter('items').dot!.counter, 3);
    expect(() => restored.setDelta('items', 'wrong type'), throwsStateError);
  });

  test('legacy counter snapshot does not invent remote dot sequences', () {
    final restored = Replica.fromSnapshotJson({
      'version': 2,
      'replicaId': 'device',
      'clock': <String, Object?>{},
      'hlc': const HlcTimestamp(0, 0).toJson(),
      'deltaSequence': 0,
      'lww': <String, Object?>{},
      'gCounters': {
        'items': {
          'replicaId': 'device',
          'crdtId': 'items',
          'components': {'device': 5, 'peer': 5},
          'sequence': 1,
        },
      },
      'pnCounters': <String, Object?>{},
    });
    expect(() => restored.export(), throwsStateError);

    final stale = GCounterDelta(
      id: counterDeltaId('g-counter', 'items', 'peer', 1),
      replicaId: 'peer',
      crdtId: 'items',
      value: 5,
      dot: const Dot(replicaId: 'peer', counter: 1, crdtId: 'items'),
    );
    restored.apply(Delta([stale]));
    final next = GCounterDelta(
      id: counterDeltaId('g-counter', 'items', 'peer', 2),
      replicaId: 'peer',
      crdtId: 'items',
      value: 7,
      dot: const Dot(replicaId: 'peer', counter: 2, crdtId: 'items'),
    );
    restored.apply(Delta([next]));
    expect(restored.gCounterValue('items'), 12);
    expect(restored.export().changes, hasLength(2));
  });

  test('snapshot winner protects local delta sequence from reuse', () {
    final original = Replica('device')..setDelta('title', 'winner');
    final encoded = original.toSnapshotJson();
    final state = Map<String, Object?>.from(encoded);
    state['deltaSequence'] = 0;
    final winner = (state['lww'] as Map)['title'] as Map;
    final winnerDelta = Map<String, Object?>.from(winner['winner'] as Map);
    winnerDelta['id'] = 'device:delta:10';
    state['lww'] = {
      'title': {'winner': winnerDelta},
    };

    final restored = Replica.fromSnapshotJson(state);
    expect(restored.setDelta('title', 'next').id, 'device:delta:11');
  });

  test('invalid later counter change does not partially apply a batch', () {
    final source = Replica('peer')..incrementGCounter('items', 5);
    final target = Replica('target')..apply(source.export());
    final unrelated = Replica('other').setDelta('title', 'must not appear');
    final regressed = GCounterDelta(
      id: counterDeltaId('g-counter', 'items', 'peer', 2),
      replicaId: 'peer',
      crdtId: 'items',
      value: 4,
      dot: const Dot(replicaId: 'peer', counter: 2, crdtId: 'items'),
    );

    expect(
      () => target.apply(Delta([unrelated, regressed])),
      throwsFormatException,
    );
    expect(target.state.values, isEmpty);
    expect(target.gCounterValue('items'), 5);
  });

  test('snapshot bootstrap merges state without taking peer identity', () {
    final local = Replica('local')
      ..setDelta('local-only', true)
      ..incrementPnCounter('balance', 2);
    final remote = Replica('remote')
      ..setDelta('remote-only', {
        'labels': ['ready'],
      })
      ..incrementGCounter('items', 4)
      ..incrementPnCounter('balance', 5);

    local.mergeSnapshotJson(remote.toSnapshotJson());

    expect(local.id, 'local');
    expect(local.state.values['local-only'], true);
    expect(local.state.values['remote-only'], {
      'labels': ['ready'],
    });
    expect(local.gCounterValue('items'), 4);
    expect(local.pnCounterValue('balance'), 7);
    expect(local.clock.entries['remote'], 1);
    expect(local.setDelta('local-only', false).id, 'local:delta:2');
  });

  test('conflicting snapshot address type leaves replica unchanged', () {
    final local = Replica('local')..setDelta('shared', 'lww');
    final remote = Replica('remote')..incrementGCounter('shared', 3);

    expect(
      () => local.mergeSnapshotJson(remote.toSnapshotJson()),
      throwsFormatException,
    );
    expect(local.state.values, {'shared': 'lww'});
    expect(local.gCounterValue('shared'), 0);
  });
}

Operation _operation(String id, Object? value) => Operation(
  id: id,
  replicaId: id.split(':').first,
  type: 'lww.set',
  vectorClock: VectorClock().tick(id.split(':').first),
  payload: {'key': 'title', 'value': value},
);
