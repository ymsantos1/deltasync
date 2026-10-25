import 'dart:async';

import 'package:deltasync/deltasync.dart';

String render(FieldQuery result) => switch (result) {
  AbsentField() => 'not configured',
  DeletedField() => 'removed',
  PresentField(:final value) => '$value',
};

Future<void> main() async {
  final engine = SyncEngine.withStorage(
    replica: Replica('example'),
    storage: MemoryStorage(),
    transport: Offline(),
  );
  final refreshed = Completer<void>();
  var refreshes = 0;
  // This listener only reads one address. It never schedules push or polls.
  final subscription = engine.commitsFor('profile/name').listen((event) {
    refreshes++;
    print(
      'refresh: ${render(engine.query('profile/name'))} (${event.origin.name})',
    );
    if (!refreshed.isCompleted) refreshed.complete();
  });
  try {
    await engine.start();
    // Streams do not replay restoration or earlier commits: hydrate explicitly.
    print('initial: ${render(engine.query('profile/name'))}');
    await engine.setDelta('unrelated', true);
    await engine.batch((batch) {
      batch.setDelta('profile/name', 'Ada');
      batch.incrementGCounter('profile/revisions');
    });
    await refreshed.future;
    print(
      'refreshes: $refreshes; awaiting ACK: ${(await engine.pendingSummary()).totalCount}',
    );
    // Processed addresses may repeat on replay/losing input. Read current state,
    // not a historical value associated with a delayed/paused event.
  } finally {
    await subscription.cancel();
    await engine.dispose();
  }
}

class Offline implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async =>
      throw StateError('offline');
}
