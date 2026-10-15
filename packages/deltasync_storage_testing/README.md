# deltasync_storage_testing

Reusable `ReplicaStorage` contract suite. Adapter package adds this package as
a development dependency, implements `ReplicaStorageContractFixture`, and calls
`replicaStorageContractTests` from its test entry point. This runs the same
snapshot, outbox, remote commit, peer ACK, isolation, concurrency, and failure
checks against each adapter.

Add `deltasync_storage_testing: ^2.0.0` to your adapter's `dev_dependencies`.
The package depends on `test` intentionally: it registers tests for consumers.

`createStorageWithCommitFailure` must arm a failure in the adapter commit path.
Persistent adapters should inject it after transaction writes are staged, so a
failed commit proves rollback of snapshot and outbox together. The in-memory
fixture reports itself as a volatile simulation; passing it says nothing about
process restart or disk durability.

Example adapter test entry point:

```dart
import 'package:deltasync_storage_testing/deltasync_storage_testing.dart';

// SqliteStorageContractFixture is implemented by the adapter under test.
void main() => replicaStorageContractTests(
  name: 'SQLite',
  fixture: SqliteStorageContractFixture(),
);
```

See the [reference SQLite fixture](https://github.com/ymsantos1/deltasync/blob/main/packages/deltasync_storage_sqflite/test/sqflite_replica_storage_test.dart)
and the [project documentation](https://github.com/ymsantos1/deltasync#readme).
