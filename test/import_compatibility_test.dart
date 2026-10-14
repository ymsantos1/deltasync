import 'package:deltasync/deltasync.dart' as facade;
import 'package:deltasync_storage/src/replica_storage.dart' as storage;
import 'package:deltasync_sync/src/sync_engine.dart' as sync;
import 'package:test/test.dart';

void main() {
  test(
    'original import paths retain type identity after internal separation',
    () {
      expect(_ExternalCommit(), isA<facade.SyncObservation>());
      expect(storage.MemoryStorage(), isA<facade.MemoryStorage>());
      expect(const sync.SyncRetryPolicy(), isA<facade.SyncRetryPolicy>());
      expect(
        sync.SyncEngineLifecycle.started,
        facade.SyncEngineLifecycle.started,
      );
      expect(
        const sync.SyncCommitEvent(origin: sync.SyncCommitOrigin.local),
        isA<facade.SyncCommitEvent>(),
      );
    },
  );
}

/// Existing event contracts remain implementable outside the sync library.
class _ExternalCommit implements facade.SyncCommitEvent {
  @override
  facade.SyncCommitOrigin get origin => facade.SyncCommitOrigin.local;
}
