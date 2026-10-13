import 'dart:io';

import 'package:deltasync_mobile_consumer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('two views keep editing through failure, converge and reset', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('deltasync-ui-');
    addTearDown(() => directory.deleteSync(recursive: true));
    await tester.pumpWidget(
      MobileConsumerApp(
        databaseFactoryOverride: databaseFactoryFfi,
        databaseDirectory: () async => directory.path,
      ),
    );
    await _waitFor(tester, () => _status(tester) == 'Estado restaurado');
    expect(find.byKey(const Key('replica-A')), findsOneWidget);
    expect(find.byKey(const Key('replica-B')), findsOneWidget);

    await _edit(tester, 'A', 'Azul');
    await _waitFor(tester, () => _text(tester, 'title-A') == 'Título: Azul');
    await _edit(tester, 'B', 'Verde');
    await _waitFor(tester, () => _text(tester, 'title-B') == 'Título: Verde');
    await _tap(tester, 'increment-A');
    await _waitFor(tester, () => _text(tester, 'items-A') == 'Itens: 1');
    await _tap(tester, 'increment-B');
    await _waitFor(tester, () => _text(tester, 'items-B') == 'Itens: 1');
    expect(_text(tester, 'pending-A'), 'Pendentes: 2');
    expect(_text(tester, 'pending-B'), 'Pendentes: 2');

    await _tap(tester, 'push-pending');
    await _waitFor(
      tester,
      () => _status(tester) == 'Falha de envio; commits locais preservados',
    );
    expect(_text(tester, 'error-A'), contains('Peer shopper-b offline'));
    expect(_text(tester, 'error-B'), contains('Peer shopper-a offline'));
    await _edit(tester, 'A', 'Azul novo');
    await _waitFor(tester, () => _text(tester, 'pending-A') == 'Pendentes: 3');
    expect(_text(tester, 'pending-B'), 'Pendentes: 2');

    await _tap(tester, 'peer-available');
    await _waitFor(tester, () => _status(tester) == 'Peer disponível');
    await _tap(tester, 'push-pending');
    await _waitFor(tester, () => _status(tester) == 'Envio concluído');
    expect(_text(tester, 'pending-A'), 'Pendentes: 0');
    expect(_text(tester, 'pending-B'), 'Pendentes: 0');
    expect(_text(tester, 'title-A'), _text(tester, 'title-B'));
    expect(_text(tester, 'items-A'), 'Itens: 2');
    expect(_text(tester, 'items-B'), 'Itens: 2');
    expect(_text(tester, 'confirmation-A'), contains('confirmado'));
    expect(_text(tester, 'confirmation-B'), contains('confirmado'));

    await _tap(tester, 'clear-demo');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(_text(tester, 'items-A'), 'Itens: 2');
    await _tap(tester, 'clear-demo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar'));
    await _waitFor(tester, () => _status(tester) == 'Estado restaurado');
    expect(_text(tester, 'title-A'), 'Título: —');
    expect(_text(tester, 'title-B'), 'Título: —');
    expect(_text(tester, 'pending-A'), 'Pendentes: 0');
    expect(_text(tester, 'pending-B'), 'Pendentes: 0');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

String _status(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byKey(const Key('demo-status'))).data!;

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
}

Future<void> _edit(WidgetTester tester, String side, String title) async {
  final input = find.byKey(Key('input-$side'));
  await tester.ensureVisible(input);
  await tester.enterText(input, title);
  await _tap(tester, 'save-$side');
}

Future<void> _waitFor(WidgetTester tester, bool Function() done) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
  }
  fail('Timed out waiting for the interactive demo');
}
