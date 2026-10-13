import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  group('local mutation and returned delta', () {
    test('G-Counter mutation equals applying its delta', () {
      _expectMutationLaw((replica) => [replica.incrementGCounter('count', 3)]);
    });

    test('PN-Counter mutation equals applying its delta', () {
      _expectMutationLaw(
        (replica) => [
          replica.incrementPnCounter('count', 4),
          replica.decrementPnCounter('count', 2),
        ],
      );
    });

    test('LWW-Register mutation equals applying its delta', () {
      _expectMutationLaw((replica) => [replica.setDelta('title', 'draft')]);
    });

    test('G-Set mutation equals applying its delta', () {
      _expectMutationLaw(
        (replica) => [
          replica.addAllGSet('labels', ['reader', 'writer']),
        ],
      );
    });

    test('2P-Set mutation equals applying its delta', () {
      _expectMutationLaw(
        (replica) => [
          replica.addTwoPSet('members', 'reader'),
          replica.removeTwoPSet('members', 'reader'),
        ],
      );
    });

    test('MV-Register mutation equals applying its delta', () {
      _expectMutationLaw(
        (replica) => [
          replica.writeMvRegister('title', 'old'),
          replica.writeMvRegister('title', 'new'),
        ],
      );
    });

    test('OR-Set mutation equals applying its deltas', () {
      _expectMutationLaw(
        (replica) => [
          replica.addOrSet('members', 'reader'),
          replica.removeOrSet('members', 'reader'),
          replica.addOrSet('members', 'reader'),
        ],
      );
    });

    test('OR-Map mutation equals applying its deltas', () {
      _expectMutationLaw(
        (replica) => [
          replica.addOrMapKey('profile', 'roles'),
          ...replica.addOrMapValue('profile', 'roles', 'reader'),
        ],
      );
    });
  });

  test('eight CRDT histories converge by shuffled deltas and snapshots', () {
    Replica peer(String id) =>
        Replica(id, hlc: HlcClock(nowMilliseconds: () => 1000));

    final a = peer('a');
    final b = peer('b');
    final c = peer('z');

    a.incrementGCounter('g-count', 2);
    a.incrementGCounter('g-count');
    b.incrementGCounter('g-count', 5);
    c.incrementGCounter('g-count');

    a.incrementPnCounter('pn-count', 4);
    a.decrementPnCounter('pn-count');
    b.decrementPnCounter('pn-count', 3);
    c.incrementPnCounter('pn-count', 2);

    a.setDelta('title', 'from-a');
    b.setDelta('title', 'from-b');
    c.setDelta('title', 'from-z');

    a.addAllGSet('labels', ['reader', 'writer']);
    b.addGSet('labels', {
      'b': [1, 2],
    });
    c.addGSet('labels', {
      'b': [1, 2],
    });

    final twoPAdd = a.addTwoPSet('members', 'shared');
    b.apply(Delta([twoPAdd]));
    b.removeTwoPSet('members', 'shared');
    c.addTwoPSet('members', 'shared');
    a.addTwoPSet('members', 'permanent');

    final oldMvWrite = a.writeMvRegister('field', 'old');
    b.apply(Delta([oldMvWrite]));
    b.writeMvRegister('field', 'observed replacement');
    c.writeMvRegister('field', 'concurrent');
    a.writeMvRegister('field', 'local replacement');

    final oldOrTag = a.addOrSet('tags', 'shared');
    b.apply(Delta([oldOrTag]));
    final observedRemoval = b.removeOrSet('tags', 'shared');
    a.apply(Delta([observedRemoval]));
    a.addOrSet('tags', 'shared');
    c.addOrSet('tags', 'shared');

    final oldKey = a.addOrMapKey('profile', 'roles');
    b.apply(Delta([oldKey]));
    c.apply(Delta([oldKey]));
    b.addOrMapValue('profile', 'roles', 'reader');
    c.addOrMapKey('profile', 'roles');
    c.addOrMapValue('profile', 'roles', 'writer');
    a.removeOrMapKey('profile', 'roles');
    a.addOrMapKey('profile', 'roles');
    a.addOrMapValue('profile', 'roles', 'owner');

    final sources = [a, b, c];
    final changes = sources
        .expand((source) => source.export().changes)
        .toList();
    var aggregate = const Delta.empty();
    for (final change in changes) {
      aggregate = aggregate.merge(Delta([change]));
    }

    final batched = peer('receiver')..apply(aggregate);
    final shuffled = peer('receiver');
    for (final change in changes.reversed) {
      shuffled
        ..apply(Delta([change]))
        ..apply(Delta([change]));
    }
    final snapshotted = peer('receiver');
    for (final source in sources.reversed) {
      snapshotted.mergeSnapshotJson(source.toSnapshotJson());
    }

    expect(_normalizedSnapshot(shuffled), _normalizedSnapshot(batched));
    expect(_normalizedSnapshot(snapshotted), _normalizedSnapshot(batched));
    expect(batched.gCounterValue('g-count'), 9);
    expect(batched.pnCounterValue('pn-count'), 2);
    expect(batched.state.values['title'], 'from-z');
    expect(batched.gSetValue('labels'), {
      'reader',
      'writer',
      {
        'b': [1, 2],
      },
    });
    expect(batched.twoPSetValue('members'), {'permanent'});
    expect(batched.mvRegisterValue('field'), {
      'local replacement',
      'observed replacement',
      'concurrent',
    });
    expect(batched.orSetValue('tags'), {'shared'});
    expect(batched.orMapValue('profile'), {
      'roles': {'writer', 'owner'},
    });
  });

  test('MV-Register keeps a real dot gap without inventing its middle', () {
    MvRegisterDelta write(int sequence, String value) => MvRegisterDelta(
      id: crdtDeltaId('mv-register', 'field', 'origin', sequence),
      replicaId: 'origin',
      crdtId: 'field',
      dot: Dot(replicaId: 'origin', counter: sequence, crdtId: 'field'),
      value: value,
      context: const [],
    );

    final first = write(1, 'first');
    final third = write(3, 'third');
    final register = MvRegister('origin', crdtId: 'field')
      ..applyDelta(first)
      ..applyDelta(third);

    expect(register.value, {'first', 'third'});
    final beforeNextWrite = register.toJson();
    expect(beforeNextWrite['context'], {
      'crdtId': 'field',
      'replicas': {
        'origin': {
          'prefix': 1,
          'sparse': [3],
        },
      },
    });
    final fourth = register.write('after gap');
    expect(fourth.dot.counter, 4);
    expect(fourth.context, containsAll([first.dot, third.dot]));
    expect(
      fourth.context,
      isNot(contains(Dot(replicaId: 'origin', counter: 2, crdtId: 'field'))),
    );
    register
      ..applyDelta(first)
      ..applyDelta(third);
    expect(register.value, {'after gap'});
  });

  test('same replica sequence stays distinct across CRDT addresses', () {
    final replica = Replica('same-replica');
    final first = replica.addOrSet('left', 'x');
    final second = replica.addOrSet('right', 'y');

    expect(first.dot.replicaId, second.dot.replicaId);
    expect(first.dot.counter, second.dot.counter);
    expect(first.dot.crdtId, 'left');
    expect(second.dot.crdtId, 'right');
    expect(first.dot, isNot(second.dot));
    expect(first.id, isNot(second.id));
    final restored = Replica.fromSnapshotJson(replica.toSnapshotJson());
    expect(restored.orSetValue('left'), {'x'});
    expect(restored.orSetValue('right'), {'y'});
  });
}

void _expectMutationLaw(
  Iterable<DeltaChange> Function(Replica replica) mutate,
) {
  final state = Replica('local', hlc: HlcClock(nowMilliseconds: () => 1000));
  final before = state.fork();
  final changes = mutate(state).toList();
  expect(changes, isNotEmpty);

  final reconstructed = before.fork()..apply(Delta(changes));
  expect(
    _withoutLocalHlc(reconstructed.toSnapshotJson()),
    _withoutLocalHlc(state.toSnapshotJson()),
  );
}

Map<String, Object?> _withoutLocalHlc(Map<String, Object?> snapshot) =>
    Map<String, Object?>.of(snapshot)..remove('hlc');

// Replay advances the receiving node's local HLC; compare persisted CRDT state.
Map<String, Object?> _normalizedSnapshot(Replica replica) {
  // Local owner/sequence fields vary by merge path; causal events remain intact.
  final snapshot = Map<String, Object?>.of(replica.toSnapshotJson())
    ..remove('replicaId')
    ..remove('deltaSequence')
    ..remove('hlc');
  for (final key in [
    'gCounters',
    'pnCounters',
    'gSets',
    'twoPSets',
    'mvRegisters',
    'orSets',
    'orMaps',
  ]) {
    final states = snapshot[key] as Map<String, Object?>;
    snapshot[key] = {
      for (final entry in states.entries)
        entry.key: Map<String, Object?>.from(entry.value as Map)
          ..remove('replicaId')
          ..remove('sequence'),
    };
    if (key == 'pnCounters') {
      // Missing and zero PN components have the same materialized meaning.
      for (final state in (snapshot[key] as Map<String, Object?>).values) {
        final counter = state as Map<String, Object?>;
        for (final component in ['positive', 'negative']) {
          final values = Map<String, Object?>.from(counter[component] as Map)
            ..removeWhere((_, value) => value == 0);
          counter[component] = values;
        }
      }
    }
  }
  final mvRegisters = snapshot['mvRegisters'] as Map<String, Object?>;
  for (final state in mvRegisters.values) {
    final mv = state as Map<String, Object?>;
    final versions = List<Map<String, Object?>>.from(mv['versions'] as List)
      ..sort((first, second) {
        final firstDot = first['dot'] as Map;
        final secondDot = second['dot'] as Map;
        final origin = (firstDot['replicaId'] as String).compareTo(
          secondDot['replicaId'] as String,
        );
        return origin != 0
            ? origin
            : (firstDot['counter'] as int).compareTo(
                secondDot['counter'] as int,
              );
      });
    mv['versions'] = versions;
  }
  return snapshot;
}
