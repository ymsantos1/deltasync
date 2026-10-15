# deltasync_storage

Pure Dart `ReplicaStorage` contract and volatile `MemoryStorage` implementation.
Add `deltasync_storage: ^1.0.0` and `deltasync_core: ^1.0.0` to your dependencies.

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

MemoryStorage loses data when its instance/process is discarded. For durable
storage, use `deltasync_storage_sqflite` or implement the public contract and run
`deltasync_storage_testing`. Adapter authors must verify atomicity and process
recovery against their real backend. See the
[project documentation](https://github.com/ymsantos1/deltasync#readme).
