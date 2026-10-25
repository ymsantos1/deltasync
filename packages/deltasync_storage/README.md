# deltasync_storage

Version 1.0.1 requires upgrade review despite its patch number. The release
aligns all DeltaSync packages and includes intentional source breaks; see the
[migration guide](https://github.com/ymsantos1/deltasync/blob/main/docs/migracao-1.0.1.md).

Pure Dart `ReplicaStorage` contract and volatile `MemoryStorage` implementation.
Add `deltasync_storage: ^1.0.1` and `deltasync_core: ^1.0.1` to your dependencies.

```dart
import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';

Future<void> main() async {
  final storage = MemoryStorage();
  final replica = Replica('device-a');
  final change = replica.setDelta('title', 'Offline');
  await storage.commit(ReplicaSnapshot.fromReplica(replica), [
    OutboxEntry(delta: Delta([change]), recipientPeerId: 'device-b'),
  ]);
  print((await storage.pending(replica.id)).length); // 1
}
```

`commit` atomically stores the candidate snapshot and outgoing changes.
`commitRemote` stores received state while preserving local pending changes.
Acknowledgements remove only changes addressed to the confirming peer. A local
commit does not imply remote delivery. `SyncEngine` coordinates these operations
for application consumers.

Implement `pendingSummary(replicaId, recipientPeerId: ...)` in custom adapters.
Return `OutboxSummary` with non-negative pending/sent counts from a consistent
outbox read; null peer means all peers, legacy confirmed records are excluded.
Use backend metadata/aggregation to avoid decoding CRDT payloads. Query failures
must propagate and must not change committed data. See the
[migration guide](https://github.com/ymsantos1/deltasync/blob/main/docs/migracao-1.0.1.md).

The application owns adapter resources. Drain/dispose its engine before closing
the concrete storage; the engine does not close it. Summary failure after a local
commit means unknown status, not an empty outbox or a lost edit. Keep state/outbox
as the single source of truth and handle status reads separately from saves.

MemoryStorage loses data when its instance/process is discarded. For durable
storage, use `deltasync_storage_sqflite` or implement the public contract and run
`deltasync_storage_testing`. Adapter authors must verify atomicity and process
recovery against their real backend. See the
[project documentation](https://github.com/ymsantos1/deltasync#readme).
