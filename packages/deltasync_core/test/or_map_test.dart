import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('nested G-Set updates join without replacing concurrent values', () {
    final left = OrMap('left', crdtId: 'profile');
    final right = OrMap('right', crdtId: 'profile');
    final key = left.addKey('roles');
    right.applyDelta(key);
    final leftValue = left.addValue('roles', 'reader').single;
    final rightValue = right.addValue('roles', 'writer').single;

    left.applyDelta(rightValue);
    right.applyDelta(leftValue);
    expect(left.value['roles'], {'reader', 'writer'});
    expect(right.value, left.value);
    expect(
      DeltaCodec.decode(DeltaCodec.encode(Delta([key, leftValue]))).changes,
      [key, leftValue],
    );
  });

  test(
    'observed removal preserves concurrent key add; recreation is fresh',
    () {
      final left = OrMap('left', crdtId: 'profile');
      final right = OrMap('right', crdtId: 'profile');
      final oldKey = left.addKey('roles');
      final oldValue = left.addValue('roles', 'reader').single;
      right.applyDelta(oldKey);
      final removal = left.removeKey('roles');
      final concurrentKey = right.addKey('roles');

      left.applyDelta(concurrentKey);
      right.applyDelta(removal);
      right.applyDelta(oldValue);
      expect(left.value.keys, {'roles'});
      expect(right.value.keys, {'roles'});

      final newValue = right.addValue('roles', 'writer').single;
      left.applyDelta(newValue);
      expect(left.value['roles'], {'writer'});
      expect(right.value['roles'], {'writer'});
    },
  );

  test(
    'old nested delta stays hidden after removal, recreation and restore',
    () {
      final source = OrMap('source', crdtId: 'profile');
      final oldKey = source.addKey('roles');
      final remote = OrMap('remote', crdtId: 'profile')..applyDelta(oldKey);
      final oldValue = remote.addValue('roles', 'reader').single;
      source.removeKey('roles');
      source.addKey('roles');
      final restored = OrMap.fromJson(source.toJson());

      restored.applyDelta(oldValue);
      expect(restored.value, {'roles': <Object?>{}});
      restored.addValue('roles', 'writer');
      expect(restored.value['roles'], {'writer'});
      expect(OrMap.fromJson(restored.toJson()).value['roles'], {'writer'});
    },
  );

  test(
    'join is associative, commutative, idempotent and order independent',
    () {
      final a = OrMap('a', crdtId: 'preferences');
      final key = a.addKey('colors');
      a.addValue('colors', 'red');
      final b = OrMap('b', crdtId: 'preferences')..applyDelta(key);
      b.addValue('colors', 'blue');
      final c = OrMap('c', crdtId: 'preferences')..applyDelta(key);
      c.removeKey('colors');

      final ab = OrMap.fromJson(a.toJson())..mergeState(b);
      final ba = OrMap.fromJson(b.toJson())..mergeState(a);
      expect(ab.value, ba.value);
      final left = OrMap.fromJson(ab.toJson())..mergeState(c);
      final bc = OrMap.fromJson(b.toJson())..mergeState(c);
      final right = OrMap.fromJson(a.toJson())..mergeState(bc);
      expect(left.value, right.value);
      left.mergeState(left);

      final byDeltas = OrMap('receiver', crdtId: 'preferences');
      for (final delta in [
        ...a.exportChanges(),
        ...b.exportChanges(),
        ...c.exportChanges(),
      ].reversed) {
        byDeltas.applyDelta(delta);
        byDeltas.applyDelta(delta);
      }
      expect(byDeltas.value, left.value);
    },
  );

  test('Replica routes codec, snapshot and v7 compatibility', () {
    final source = Replica('source');
    final key = source.addOrMapKey('profile', 'roles');
    final values = source.addOrMapValue('profile', 'roles', 'reader');
    final receiver = Replica('receiver')
      ..apply(DeltaCodec.decode(DeltaCodec.encode(Delta([key, ...values]))));
    expect(receiver.orMapValue('profile'), {
      'roles': <Object?>{'reader'},
    });
    final restored = Replica.fromSnapshotJson(source.toSnapshotJson());
    expect(restored.toSnapshotJson()['version'], 9);
    expect(restored.orMapValue('profile'), receiver.orMapValue('profile'));
    final fromSnapshot = Replica('snapshot-join')
      ..mergeSnapshotJson(source.toSnapshotJson());
    final fromDeltas = Replica('delta-join')..apply(source.export());
    expect(
      fromSnapshot.orMapValue('profile'),
      fromDeltas.orMapValue('profile'),
    );
    final oldSnapshot = Map<String, Object?>.from(source.toSnapshotJson())
      ..['version'] = 7
      ..remove('orMaps');
    expect(
      Replica.fromSnapshotJson(oldSnapshot).orMapValue('profile'),
      isEmpty,
    );
  });

  test('rejects malformed labels, keys and values without binding address', () {
    final replica = Replica('local');
    expect(() => replica.addOrMapKey('profile', ' '), throwsArgumentError);
    expect(
      () => replica.addOrMapValue('profile', 'roles', Object()),
      throwsArgumentError,
    );
    expect(
      () => replica.addOrMapValue('profile', 'roles', 'reader'),
      throwsStateError,
    );
    expect(replica.state.addresses, isEmpty);
    replica.setDelta('profile', 'lww');
    expect(Replica.fromSnapshotJson(replica.toSnapshotJson()).state.values, {
      'profile': 'lww',
    });
    expect(() => OrMapAction.fromWire('future'), throwsFormatException);
    expect(
      () => OrMapDelta.fromJson({
        'type': 'or-map',
        'id': 'bad',
        'replicaId': 'source',
        'crdtId': 'profile',
        'action': 'future',
        'dot': {'replicaId': 'source', 'counter': 1, 'crdtId': 'profile'},
        'key': 'roles',
      }),
      throwsFormatException,
    );
  });

  test('rejects cross-key removal and nested conflicts atomically', () {
    final map = OrMap('source', crdtId: 'profile');
    final key = map.addKey('roles');
    final firstValue = map.addValue('roles', 'reader').single;
    final before = map.toJson();
    final mismatchedRemoval = OrMapDelta(
      id: crdtDeltaId('or-map', 'profile', 'other', 1),
      replicaId: 'other',
      crdtId: 'profile',
      action: OrMapAction.removeKey,
      dot: const Dot(replicaId: 'other', counter: 1, crdtId: 'profile'),
      key: 'permissions',
      observedDots: [key.dot],
    );
    expect(() => map.applyDelta(mismatchedRemoval), throwsFormatException);
    expect(map.toJson(), before);

    final valueSource = OrMap('value-source', crdtId: 'profile');
    final pendingKey = valueSource.addKey('roles');
    final pendingValue = valueSource.addValue('roles', 'reader').single;
    final pendingReceiver = OrMap('pending', crdtId: 'profile')
      ..applyDelta(pendingValue);
    final mismatchedPendingRemoval = OrMapDelta(
      id: crdtDeltaId('or-map', 'profile', 'other', 1),
      replicaId: 'other',
      crdtId: 'profile',
      action: OrMapAction.removeKey,
      dot: const Dot(replicaId: 'other', counter: 1, crdtId: 'profile'),
      key: 'permissions',
      observedDots: [pendingKey.dot],
    );
    expect(
      () => pendingReceiver.applyDelta(mismatchedPendingRemoval),
      throwsFormatException,
    );

    final nested = firstValue.valueChange!;
    final conflictingNested = GSetDelta(
      id: nested.id,
      replicaId: nested.replicaId,
      crdtId: nested.crdtId,
      elements: ['writer'],
      dot: nested.dot,
    );
    final conflictingValue = OrMapDelta(
      id: crdtDeltaId('or-map', 'profile', 'source', 3),
      replicaId: 'source',
      crdtId: 'profile',
      action: OrMapAction.addValue,
      dot: const Dot(replicaId: 'source', counter: 3, crdtId: 'profile'),
      key: 'roles',
      keyDot: key.dot,
      valueChange: conflictingNested,
    );
    expect(() => map.applyDelta(conflictingValue), throwsFormatException);
    expect(map.toJson(), before);
  });

  test('divergent operation identity leaves state merge atomic', () {
    final base = OrMap('same', crdtId: 'profile')..addKey('roles');
    final local = OrMap.fromJson(base.toJson())..addValue('roles', 'reader');
    final remote = OrMap.fromJson(base.toJson())
      ..addKey('other')
      ..addValue('roles', 'writer');
    final before = local.toJson();

    expect(() => local.mergeState(remote), throwsFormatException);
    expect(local.toJson(), before);
  });
}
