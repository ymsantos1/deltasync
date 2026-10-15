import 'dart:io';

import 'package:deltasync_mobile_consumer/demo_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('conflict, offline edits, retry and durable restart', () async {
    final directory = Directory.systemTemp.createTempSync('deltasync-demo-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final factory = databaseFactoryFfi;
    var session = await DemoSession.open(
      factory: factory,
      directory: directory.path,
    );
    addTearDown(() => session.close());

    await session.editTitle(DemoSide.a, 'Rascunho A');
    await session.editTitle(DemoSide.b, 'Rascunho B');
    await session.incrementItems(DemoSide.a);
    await session.incrementItems(DemoSide.b);
    var state = await session.pushPending();
    expect(state.a.error, contains('offline'));
    expect(state.b.error, contains('offline'));
    expect(state.a.pending, 2);
    expect(state.b.pending, 2);

    await session.editTitle(DemoSide.a, 'Final A');
    await session.incrementItems(DemoSide.b);
    state = await session.snapshot();
    expect(state.a.title, 'Final A');
    expect(state.b.title, 'Rascunho B');
    expect(state.a.pending, 3);
    expect(state.b.pending, 3);
    await session.close();

    session = await DemoSession.open(
      factory: factory,
      directory: directory.path,
    );
    state = await session.snapshot();
    expect(state.a.title, 'Final A');
    expect(state.b.title, 'Rascunho B');
    expect(state.a.pending, 3);
    expect(state.b.pending, 3);

    session.setPeerAvailable(true);
    state = await session.pushPending();
    expect(state.a.error, isNull);
    expect(state.b.error, isNull);
    expect(state.a.confirmation, contains('confirmado'));
    expect(state.b.confirmation, contains('confirmado'));
    expect(state.a.pending, 0);
    expect(state.b.pending, 0);
    expect(state.a.title, state.b.title);
    expect(state.a.winner, state.b.winner);
    expect(state.a.items, 3);
    expect(state.b.items, 3);

    await session.editTitle(DemoSide.a, 'Depois da conexão');
    state = await session.pushPending();
    expect(state.a.title, 'Depois da conexão');
    expect(state.b.title, 'Depois da conexão');
    expect(state.a.winner, contains(DemoSide.a.replicaId));
    expect(state.a.pending, 0);
    expect(state.b.pending, 0);
    await session.close();

    session = await DemoSession.open(
      factory: factory,
      directory: directory.path,
    );
    state = await session.snapshot();
    expect(state.a.title, 'Depois da conexão');
    expect(state.b.title, 'Depois da conexão');
    expect(state.a.items, 3);
    expect(state.b.items, 3);
    expect(state.a.pending, 0);
    expect(state.b.pending, 0);
  });

  test('clear deletes only the two demo databases', () async {
    final directory = Directory.systemTemp.createTempSync('deltasync-clear-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final factory = databaseFactoryFfi;
    final sentinelPath = '${directory.path}/other.sqlite';
    final sentinel = await factory.openDatabase(sentinelPath);
    await sentinel.execute('CREATE TABLE marker (value TEXT NOT NULL)');
    await sentinel.insert('marker', {'value': 'keep'});
    await sentinel.close();

    final session = await DemoSession.open(
      factory: factory,
      directory: directory.path,
    );
    await session.editTitle(DemoSide.a, 'Apagar');
    await session.clearDemoData();

    final restored = await DemoSession.open(
      factory: factory,
      directory: directory.path,
    );
    addTearDown(() => restored.close());
    final state = await restored.snapshot();
    expect(state.a.title, isNull);
    expect(state.a.pending, 0);
    expect(state.b.title, isNull);
    expect(state.b.pending, 0);

    final kept = await factory.openDatabase(sentinelPath);
    expect(await kept.query('marker'), [containsPair('value', 'keep')]);
    await kept.close();
  });
}
