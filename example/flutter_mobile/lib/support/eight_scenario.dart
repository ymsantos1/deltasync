import 'dart:convert';

import 'package:deltasync/deltasync.dart';

/// Fixed validation history, using the same public mutations as a consumer.
/// Each mutation commits separately; this is not an atomic eight-type batch.
class EightScenario {
  EightScenario(this.engine);

  final SyncEngine engine;

  static String address(CrdtKind kind) => 'lab/${kind.wireName}';

  Future<void> seed() async {
    if (engine.replica.id != 'alpha' ||
        engine.valueAt(address(CrdtKind.lww)) != null) {
      throw StateError('Create the base once on alpha only');
    }
    await engine.setDelta(address(CrdtKind.lww), 'base');
    await engine.incrementGCounter(address(CrdtKind.gCounter));
    await engine.incrementPnCounter(address(CrdtKind.pnCounter));
    await engine.addGSet(address(CrdtKind.gSet), 'seed');
    await engine.addTwoPSet(address(CrdtKind.twoPSet), 'shared');
    await engine.writeMvRegister(address(CrdtKind.mvRegister), 'base');
    await engine.addOrSet(address(CrdtKind.orSet), 'shared');
    await engine.addOrMapKey(address(CrdtKind.orMap), 'shared');
    await engine.addOrMapValue(address(CrdtKind.orMap), 'shared', 'seed');
  }

  Future<void> branch() async {
    if (engine.valueAt(address(CrdtKind.gCounter)) != 1 ||
        CrdtKind.values.any((kind) => engine.valueAt(address(kind)) == null)) {
      throw StateError(
        'Share the base before branching; branch once per device',
      );
    }
    final id = engine.replica.id;
    if (id != 'alpha' && id != 'beta') throw StateError('Unknown lab replica');
    await engine.setDelta(address(CrdtKind.lww), id);
    await engine.incrementGCounter(
      address(CrdtKind.gCounter),
      id == 'alpha' ? 2 : 3,
    );
    if (id == 'alpha') {
      await engine.incrementPnCounter(address(CrdtKind.pnCounter), 4);
    } else {
      await engine.decrementPnCounter(address(CrdtKind.pnCounter), 2);
    }
    await engine.addGSet(address(CrdtKind.gSet), id);
    await engine.addTwoPSet(address(CrdtKind.twoPSet), id);
    if (id == 'alpha') {
      await engine.removeTwoPSet(address(CrdtKind.twoPSet), 'shared');
      await engine.removeOrSet(address(CrdtKind.orSet), 'shared');
      await engine.removeOrMapKey(address(CrdtKind.orMap), 'shared');
    } else {
      await engine.addTwoPSet(address(CrdtKind.twoPSet), 'shared');
      await engine.addOrSet(address(CrdtKind.orSet), 'shared');
      await engine.addOrMapKey(address(CrdtKind.orMap), 'shared');
      await engine.addOrMapValue(address(CrdtKind.orMap), 'shared', 'beta');
    }
    await engine.addOrSet(address(CrdtKind.orSet), id);
    await engine.writeMvRegister(address(CrdtKind.mvRegister), id);
  }

  Future<void> editAfterFailure() async {
    final versions = engine.valueAt(address(CrdtKind.mvRegister));
    if (versions is! Set ||
        versions.length != 1 ||
        !versions.contains(engine.replica.id)) {
      throw StateError('Complete the isolated branch before this edit');
    }
    await engine.setDelta(address(CrdtKind.lww), '${engine.replica.id}-retry');
  }

  Future<void> resolve() async {
    final versions = engine.valueAt(address(CrdtKind.mvRegister));
    if (versions is! Set || versions.length != 2) {
      throw StateError('Receive both concurrent MV versions before resolving');
    }
    await engine.writeMvRegister(address(CrdtKind.mvRegister), 'resolved');
  }

  Future<Map<String, Object?>> report() async => {
    'replicaId': engine.replica.id,
    'pending': (await engine.pendingDelta()).toJson(),
    'values': {
      for (final kind in CrdtKind.values)
        kind.wireName: _jsonValue(engine.valueAt(address(kind))),
    },
    'snapshot': engine.replica.toSnapshotJson(),
  };

  static Object? _jsonValue(Object? value) {
    if (value is Set) {
      return value.map(_jsonValue).toList()
        ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
    }
    if (value is Map) {
      return {for (final key in value.keys) '$key': _jsonValue(value[key])};
    }
    return value;
  }
}
