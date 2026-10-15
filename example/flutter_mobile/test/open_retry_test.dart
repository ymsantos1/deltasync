import 'dart:convert';
import 'dart:io';

import 'package:deltasync_mobile_consumer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('failed start releases SQLite and retry restores pending edits', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('deltasync-ui-');
    addTearDown(() => directory.deleteSync(recursive: true));
    Future<String> databaseDirectory() async => directory.path;

    final firstFactory = _RecordingFactory();
    await tester.pumpWidget(
      MobileConsumerApp(
        databaseFactoryOverride: firstFactory,
        databaseDirectory: databaseDirectory,
      ),
    );
    await _pumpUntil(
      tester,
      () => find.text('Estado restaurado').evaluate().isNotEmpty,
    );
    await _enterTitle(tester, 'A', 'Ana');
    await _tapKey(tester, 'save-A');
    await _pumpUntil(
      tester,
      () => find.text('Título: Ana').evaluate().isNotEmpty,
    );
    await _tapKey(tester, 'increment-A');
    await _pumpUntil(tester, () => find.text('Itens: 1').evaluate().isNotEmpty);
    await _tapKey(tester, 'push-pending');
    await _pumpUntil(
      tester,
      () => find
          .text('Falha de envio; commits locais preservados')
          .evaluate()
          .isNotEmpty,
    );
    expect(find.text('Pendentes: 2'), findsOneWidget);
    expect(find.textContaining('Peer shopper-b offline'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpUntil(
      tester,
      () => firstFactory.databases.every((database) => !database.isOpen),
    );
    final before = await tester.runAsync(() => _storedRows(directory.path));

    final retryFactory = _RecordingFactory(failFirst: true);
    await tester.pumpWidget(
      MobileConsumerApp(
        databaseFactoryOverride: retryFactory,
        databaseDirectory: databaseDirectory,
      ),
    );
    await _pumpUntil(
      tester,
      () => find
          .textContaining('Erro: Bad state: falha transitória de abertura')
          .evaluate()
          .isNotEmpty,
    );
    expect(find.byKey(const Key('save-A')), findsNothing);
    expect(_button(tester, 'push-pending').onPressed, isNull);
    expect(_button(tester, 'open-retry').onPressed, isNotNull);
    expect(retryFactory.databases, hasLength(1));
    expect(retryFactory.databases.single.isOpen, isFalse);
    expect(await tester.runAsync(() => _storedRows(directory.path)), before);

    await tester.tap(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await _pumpUntil(
      tester,
      () => find.text('Estado restaurado').evaluate().isNotEmpty,
    );
    expect(find.text('Título: Ana'), findsOneWidget);
    expect(find.text('Itens: 1'), findsOneWidget);
    expect(find.text('Pendentes: 2'), findsOneWidget);
    expect(_button(tester, 'save-A').onPressed, isNotNull);
    expect(retryFactory.opens, 4);
    expect(await tester.runAsync(() => _storedRows(directory.path)), before);

    await _tapKey(tester, 'peer-available');
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<SelectableText>(find.byKey(const Key('demo-status')))
              .data ==
          'Peer disponível',
    );
    await _tapKey(tester, 'push-pending');
    await _pumpUntil(
      tester,
      () => find.text('Envio concluído').evaluate().isNotEmpty,
    );
    expect(find.text('Título: Ana'), findsNWidgets(2));
    expect(find.text('Itens: 1'), findsNWidgets(2));
    expect(find.text('Pendentes: 0'), findsNWidgets(2));
    expect(find.textContaining('delta(s) confirmado(s)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpUntil(
      tester,
      () => retryFactory.databases.every((database) => !database.isOpen),
    );
  });
}

FilledButton _button(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(find.byKey(Key(key)));

Future<void> _tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
}

Future<void> _enterTitle(WidgetTester tester, String side, String title) async {
  final target = find.byKey(Key('input-$side'));
  await tester.ensureVisible(target);
  await tester.enterText(target, title);
  await tester.pump();
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
  }
  fail('Timed out waiting for the mobile consumer state');
}

Future<Map<String, Object?>> _storedRows(String directory) async {
  final result = <String, Object?>{};
  for (final replica in ['shopper-a', 'shopper-b']) {
    final database = await databaseFactoryFfi.openDatabase(
      '$directory/$replica.sqlite',
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      final snapshots = await database.query('deltasync_snapshots');
      result['$replica/snapshot'] = snapshots.map((row) {
        final payload =
            jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        // Restoring a replica can advance its HLC without a user edit.
        (payload['snapshot'] as Map<String, dynamic>).remove('hlc');
        return {...row, 'payload': payload};
      }).toList();
      result['$replica/outbox'] = await database.query(
        'deltasync_outbox',
        orderBy: 'entry_id',
      );
    } finally {
      await database.close();
    }
  }
  return result;
}

class _RecordingFactory implements DatabaseFactory {
  _RecordingFactory({this.failFirst = false});

  final bool failFirst;
  int opens = 0;
  final List<Database> databases = [];

  @override
  Future<Database> openDatabase(
    String path, {
    OpenDatabaseOptions? options,
  }) async {
    if (++opens == 1 && failFirst) {
      throw StateError('falha transitória de abertura');
    }
    final database = await databaseFactoryFfi.openDatabase(
      path,
      options: options,
    );
    databases.add(database);
    return database;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
