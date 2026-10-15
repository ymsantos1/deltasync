import 'dart:convert';
import 'dart:math';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

import 'support/snapshot_comparison.dart';

// Eight fixed seeds, 48 random local steps, three writers, two addresses per kind
// and four delivery permutations per history. Failures include the entire trace.
const seeds = [0, 1, 7, 42, 99, 2026, 10000, 65535];

void main() {
  test('comparison retains causal metadata and ordered user JSON', () {
    final a = peer('a')..setDelta('list', [1, 2]);
    final b = peer('a')..setDelta('list', [2, 1]);
    expect(normalizedSnapshot(a), isNot(normalizedSnapshot(b)));
    final first = peer('a')..writeMvRegister('mv', 'same');
    final second = first.fork()..writeMvRegister('mv', 'same');
    expect(normalizedSnapshot(first), isNot(normalizedSnapshot(second)));
    final once = peer('a')..addGSet('set', 'same');
    final twice = once.fork()..addGSet('set', 'same');
    expect(normalizedSnapshot(once), normalizedSnapshot(twice));
    expect(
      normalizedSnapshot(once, preserveLocalMetadata: true),
      isNot(normalizedSnapshot(twice, preserveLocalMetadata: true)),
    );
  });
  test(
    'duplicate G-Set add matches emitted delta after remote observation',
    () {
      final a = peer('a');
      final b = peer('b');
      a.apply(Delta([b.addGSet('set', 'shared')]));
      final replay = a.fork();
      final change = a.addGSet('set', 'shared');
      replay.apply(Delta([change]));
      expect(a.toSnapshotJson(), replay.toSnapshotJson());
    },
  );
  for (final seed in seeds) {
    test('generated eight-kind history seed=$seed', () {
      final history = _History(seed);
      try {
        history.generate();
        history.verify();
        print('seed=$seed emitted=${history.changes.length} permutations=4');
      } catch (error, stack) {
        fail('seed=$seed\ntrace=${history.trace.join("\n")}\n$error\n$stack');
      }
    });
  }
}

Replica peer(String id) =>
    Replica(id, hlc: HlcClock(nowMilliseconds: () => 1000));
Replica restore(Replica source) =>
    peer(source.id)..adopt(Replica.fromSnapshotJson(source.toSnapshotJson()));

class _History {
  _History(this.seed) : random = Random(seed);
  final int seed;
  final Random random;
  final writers = [peer('a'), peer('b'), peer('c')];
  final changes = <DeltaChange>[];
  final trace = <String>[];

  void record(
    int writer,
    String operation,
    List<DeltaChange> Function(Replica) mutate,
  ) {
    final actor = writers[writer];
    final before = actor.fork();
    trace.add('$writer begin $operation');
    final delta = mutate(actor);
    trace.add(
      '$writer $operation ${jsonEncode(DeltaCodec.encode(Delta(delta)))}',
    );
    expect(delta, isNotEmpty);
    expect(delta.map((change) => change.id).toSet().length, delta.length);
    final known = changes.map((change) => change.id).toSet();
    expect(delta.any((change) => known.contains(change.id)), isFalse);
    final replay = before
      ..apply(DeltaCodec.decode(DeltaCodec.encode(Delta(delta))));
    expect(
      normalizedSnapshot(replay, preserveLocalMetadata: true),
      normalizedSnapshot(actor, preserveLocalMetadata: true),
      reason: operation,
    );
    changes.addAll(delta);
  }

  void generate() {
    for (var writer = 0; writer < writers.length; writer++) {
      for (final kind in CrdtKind.values) {
        mutate(writer, kind, 0);
        mutate(writer, kind, 1);
      }
    }
    // Explicit causal observation, removal/recreation and a real MV 1/3 gap
    // supplement the random catalogue, so every seed exercises these conditions.
    record(
      0,
      'LWW before tombstone',
      (actor) => [actor.setDelta('tombstone', 'removed')],
    );
    record(0, 'LWW tombstone', (actor) => [actor.removeDelta('tombstone')]);
    record(
      0,
      'OR shared before remove',
      (actor) => [actor.addOrSet('or/0', 'shared')],
    );
    record(
      0,
      '2P shared before remove',
      (actor) => [actor.addTwoPSet('two/0', 'shared')],
    );
    final gapStart = changes.length;
    for (var i = 0; i < 3; i++) {
      record(0, 'gap write $i', (actor) => [actor.writeMvRegister('gap', i)]);
    }
    writers[1].apply(Delta([changes[gapStart + 2], changes[gapStart]]));
    trace.add('b receives gap dots 3/1, leaving 2 unseen');
    writers[1] = restore(writers[1]);
    record(
      1,
      'gap replacement',
      (actor) => [actor.writeMvRegister('gap', 'observed')],
    );
    writers[1].apply(writers[0].export());
    trace.add('b observes a snapshot-export before removals');
    record(
      1,
      'observed OR remove',
      (actor) => [actor.removeOrSet('or/0', 'shared')],
    );
    record(
      1,
      'observed 2P remove',
      (actor) => [actor.removeTwoPSet('two/0', 'shared')],
    );
    record(
      1,
      'observed map remove',
      (actor) => [actor.removeOrMapKey('map/0', 'roles')],
    );
    writers[0].apply(Delta(changes));
    record(0, 'OR read-add', (actor) => [actor.addOrSet('or/0', 'shared')]);
    record(0, 'map recreate', (actor) => [actor.addOrMapKey('map/0', 'roles')]);
    record(
      0,
      'map nested update',
      (actor) => actor.addOrMapValue('map/0', 'roles', {
        'roles': ['new'],
      }),
    );

    for (var step = 0; step < 48; step++) {
      final writer = random.nextInt(3);
      mutate(
        writer,
        CrdtKind.values[random.nextInt(CrdtKind.values.length)],
        random.nextInt(2),
      );
      if (step % 7 == 0) {
        final target = random.nextInt(3);
        final change = changes[random.nextInt(changes.length)];
        writers[target].apply(
          DeltaCodec.decode(DeltaCodec.encode(Delta([change]))),
        );
        trace.add('$target receives ${change.id}');
      }
      if (step % 11 == 0) {
        final snapshot = writers[writer].toSnapshotJson();
        writers[writer] = restore(writers[writer]);
        expect(writers[writer].toSnapshotJson(), snapshot);
        trace.add('$writer restores before the next local write');
      }
    }
    expect(
      changes.map((change) => change.kind).toSet(),
      CrdtKind.values.toSet(),
    );
  }

  void mutate(int writer, CrdtKind kind, int address) {
    final item = random.nextBool()
        ? 'shared'
        : {
            'seed': seed,
            'items': [random.nextInt(4), true],
          };
    record(writer, '${kind.wireName}/$address', (actor) {
      switch (kind) {
        case CrdtKind.lww:
          return [
            random.nextInt(4) == 0
                ? actor.removeDelta('title/$address')
                : actor.setDelta('title/$address', item),
          ];
        case CrdtKind.gCounter:
          return [actor.incrementGCounter('g/$address', random.nextInt(4) + 1)];
        case CrdtKind.pnCounter:
          return [
            random.nextBool()
                ? actor.incrementPnCounter('pn/$address', 2)
                : actor.decrementPnCounter('pn/$address', 1),
          ];
        case CrdtKind.gSet:
          return [actor.addGSet('g-set/$address', item)];
        case CrdtKind.twoPSet:
          return [
            random.nextBool()
                ? actor.addTwoPSet('two/$address', item)
                : actor.removeTwoPSet('two/$address', item),
          ];
        case CrdtKind.mvRegister:
          return [actor.writeMvRegister('mv/$address', item)];
        case CrdtKind.orSet:
          return [
            random.nextBool()
                ? actor.addOrSet('or/$address', item)
                : actor.removeOrSet('or/$address', item),
          ];
        case CrdtKind.orMap:
          final key = 'roles';
          if (!actor.orMapValue('map/$address').containsKey(key) ||
              random.nextInt(4) == 0) {
            return [actor.addOrMapKey('map/$address', key)];
          }
          if (random.nextInt(4) == 0) {
            return [actor.removeOrMapKey('map/$address', key)];
          }
          return actor.addOrMapValue('map/$address', key, item);
      }
    });
  }

  void verify() {
    final aggregate = changes.fold(
      const Delta.empty(),
      (delta, change) => delta.merge(Delta([change])),
    );
    final batched = peer('receiver')
      ..apply(DeltaCodec.decode(DeltaCodec.encode(aggregate)));
    final expected = normalizedSnapshot(batched);
    final snapshotJoin = peer('receiver');
    for (final actor in writers.reversed) {
      snapshotJoin.mergeSnapshotJson(actor.toSnapshotJson());
    }
    expect(
      normalizedSnapshot(snapshotJoin),
      expected,
      reason: 'delta versus snapshot join',
    );

    for (var permutation = 0; permutation < 4; permutation++) {
      final delivery = List<DeltaChange>.of(changes)
        ..shuffle(Random(seed * 100 + permutation));
      trace.add(
        'permutation=$permutation order=${delivery.map((change) => change.id).join(",")}',
      );
      var receiver = peer('receiver');
      final delayed = <DeltaChange>[];
      for (var index = 0; index < delivery.length; index++) {
        if (index == delivery.length ~/ 2) {
          receiver = restore(receiver);
        }
        final change = delivery[index];
        if (index % 3 == 0) {
          delayed.add(
            change,
          ); // Temporary loss: full information arrives later.
          continue;
        }
        final encoded = DeltaCodec.decode(DeltaCodec.encode(Delta([change])));
        receiver
          ..apply(encoded)
          ..apply(encoded);
      }
      delayed.shuffle(Random(seed + permutation));
      for (final change in delayed) {
        receiver.apply(Delta([change]));
      }
      trace.add(
        'permutation=$permutation delivered ${delivery.map((change) => change.id).join(",")}',
      );
      expect(
        normalizedSnapshot(receiver),
        expected,
        reason: 'permutation $permutation after complete resend',
      );
      final beforeReplay = normalizedSnapshot(
        receiver,
        preserveLocalMetadata: true,
      );
      receiver.apply(aggregate);
      expect(
        normalizedSnapshot(receiver, preserveLocalMetadata: true),
        beforeReplay,
      );
    }

    final a = writers[0], b = writers[1], c = writers[2];
    final ab = a.fork()..mergeSnapshotJson(b.toSnapshotJson());
    final ba = b.fork()..mergeSnapshotJson(a.toSnapshotJson());
    expect(
      normalizedSnapshot(ab),
      normalizedSnapshot(ba),
      reason: 'commutative',
    );
    final left = ab.fork()..mergeSnapshotJson(c.toSnapshotJson());
    final bc = b.fork()..mergeSnapshotJson(c.toSnapshotJson());
    final right = a.fork()..mergeSnapshotJson(bc.toSnapshotJson());
    expect(
      normalizedSnapshot(left),
      normalizedSnapshot(right),
      reason: 'associative',
    );
    final before = normalizedSnapshot(left, preserveLocalMetadata: true);
    left.mergeSnapshotJson(left.toSnapshotJson());
    expect(
      normalizedSnapshot(left, preserveLocalMetadata: true),
      before,
      reason: 'idempotent',
    );

    final restored = restore(batched);
    final oldIds = changes.map((change) => change.id).toSet();
    final next = [
      restored.setDelta('title/0', 'after restore'),
      restored.incrementGCounter('g/0'),
      restored.decrementPnCounter('pn/0'),
      restored.addGSet('g-set/0', 'after restore'),
      restored.removeTwoPSet('two/0', 'shared'),
      restored.writeMvRegister('mv/0', 'after restore'),
      restored.removeOrSet('or/0', 'shared'),
      restored.addOrMapKey('map/0', 'after'),
      ...restored.addOrMapValue('map/0', 'after', 'after restore'),
    ];
    expect(next.any((change) => oldIds.contains(change.id)), isFalse);
    final after = normalizedSnapshot(restored, preserveLocalMetadata: true);
    restored.apply(aggregate);
    expect(
      normalizedSnapshot(restored, preserveLocalMetadata: true),
      after,
      reason: 'old replay after new local writes',
    );
  }
}
