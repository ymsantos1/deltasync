import 'package:deltasync/deltasync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deltasync_mobile_consumer/main_eight.dart';
import 'package:deltasync_mobile_consumer/peer_link.dart';
import 'package:deltasync_mobile_consumer/support/eight_scenario.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('technical page refreshes after remote commit and restoration', (
    tester,
  ) async {
    late PeerLink link;
    late PeerLink sourceLink;
    late SyncEngine engine;
    late SyncEngine source;
    await tester.runAsync(() async {
      link = PeerLink('alpha');
      engine = SyncEngine.withStorage(
        replica: Replica('beta'),
        storage: MemoryStorage(),
        transport: link,
      );
      sourceLink = PeerLink('beta');
      source = SyncEngine.withStorage(
        replica: Replica('alpha'),
        storage: MemoryStorage(),
        transport: sourceLink,
      );
      await engine.start();
      await source.start();
    });
    await tester.pumpWidget(
      MaterialApp(home: EightPage(scenario: EightScenario(engine))),
    );
    await tester.pumpAndSettle();
    await _settle(tester);
    expect(find.text('Pendentes: 0'), findsOneWidget);
    late Delta seed;
    await tester.runAsync(() async {
      await EightScenario(source).seed();
      seed = await source.pendingDelta();
    });
    final received = engine.receiveEnvelope(
      DeltaEnvelope(
        senderReplicaId: 'alpha',
        recipientReplicaId: 'beta',
        delta: seed,
      ),
    );
    await tester.pumpAndSettle();
    await _settle(tester);
    await received;
    expect(find.textContaining('"g-counter": 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
    final closing = () async {
      await engine.dispose();
      await source.dispose();
      await link.close();
      await sourceLink.close();
    }();
    await _settle(tester);
    await closing;
  });
}
