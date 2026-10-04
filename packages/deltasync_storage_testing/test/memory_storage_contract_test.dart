import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_storage_testing/deltasync_storage_testing.dart';

void main() {
  replicaStorageContractTests(
    name: 'MemoryStorage (volatile simulation; not process-restart proof)',
    fixture: _MemoryStorageFixture(),
  );
}

class _MemoryStorageFixture implements ReplicaStorageContractFixture {
  @override
  ReplicaStorage createStorage() => MemoryStorage();

  @override
  ReplicaStorage createStorageWithCommitFailure() => _FailingMemoryStorage();
}

class _FailingMemoryStorage extends MemoryStorage {
  bool _failNextCommit = true;

  @override
  Future<void> commit(
    ReplicaSnapshot snapshot,
    Iterable<OutboxEntry> entries,
  ) async {
    if (_failNextCommit) {
      _failNextCommit = false;
      throw StateError('injected atomic commit failure');
    }
    await super.commit(snapshot, entries);
  }
}
