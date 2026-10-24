import 'package:deltasync/deltasync.dart';

/// A consumer owns addresses, validation and external I/O. The batch only groups
/// native local changes; MemoryStorage is volatile and no remote ACK is implied.
Future<void> main() async {
  final engine = SyncEngine.withStorage(
    replica: Replica('profile-example'),
    storage: MemoryStorage(),
    transport: _Transport(),
  );
  try {
    // Fetch/validate application data before entering the synchronous callback.
    const name = 'Ada';
    final delta = await engine.batch((batch) {
      batch.setDelta('profile/name', name);
      batch.setDelta('profile/preferences', {'theme': 'dark'});
      batch.incrementGCounter('profile/revisions');
    });
    final summary = await engine.pendingSummary(recipientPeerId: 'peer');
    if (delta.changes.length != 3 ||
        summary.pendingCount != 3 ||
        engine.valueAt('profile/name') != name ||
        engine.valueAt('profile/revisions') != 1) {
      throw StateError('Local batch did not commit the complete profile');
    }
    print(
      'Local commit: ${delta.changes.length} changes; '
      '${summary.totalCount} peer entries still await ACK.',
    );
  } finally {
    await engine.dispose();
  }
}

class _Transport implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
}
