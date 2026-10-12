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
      () => find
          .textContaining('Restaurado: A=-/-; itens=0 pendentes=0')
          .evaluate()
          .isNotEmpty,
    );
    await tester.tap(find.text('1. Editar offline'));
    await _pumpUntil(
      tester,
      () => find
          .textContaining('offline; falha de envio em 2 réplicas')
          .evaluate()
          .isNotEmpty,
    );
    expect(find.textContaining('A=Ana/-; itens=2 pendentes=2'), findsOneWidget);
    expect(
      find.textContaining('B=-/Beto; itens=3 pendentes=2'),
      findsOneWidget,
    );

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
    expect(_button(tester, '1. Editar offline').onPressed, isNull);
    expect(_button(tester, '2. Reconectar').onPressed, isNull);
    expect(_button(tester, 'Tentar novamente').onPressed, isNotNull);
    expect(retryFactory.databases, hasLength(1));
    expect(retryFactory.databases.single.isOpen, isFalse);
    expect(await tester.runAsync(() => _storedRows(directory.path)), before);

    await tester.tap(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await _pumpUntil(
      tester,
      () => find
          .textContaining('Restaurado: A=Ana/-; itens=2 pendentes=2')
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.textContaining('B=-/Beto; itens=3 pendentes=2'),
      findsOneWidget,
    );
    expect(_button(tester, '1. Editar offline').onPressed, isNotNull);
    expect(retryFactory.opens, 4);
    expect(await tester.runAsync(() => _storedRows(directory.path)), before);

    await tester.tap(find.text('2. Reconectar'));
    await _pumpUntil(
      tester,
      () => find
          .textContaining('convergente; A=Ana/Beto; itens=5 pendentes=0')
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.textContaining('B=Ana/Beto; itens=5 pendentes=0'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpUntil(
      tester,
      () => retryFactory.databases.every((database) => !database.isOpen),
    );
  });
}

FilledButton _button(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

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
