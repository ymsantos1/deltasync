# deltasync_storage_testing

Reusable `ReplicaStorage` contract suite. Adapter package adds this package as
a development dependency, implements `ReplicaStorageContractFixture`, and calls
`replicaStorageContractTests` from its test entry point. This runs the same
snapshot, outbox, remote commit, peer ACK, isolation, concurrency, and failure
checks against each adapter.

`createStorageWithCommitFailure` must arm a failure in the adapter commit path.
Persistent adapters should inject it after transaction writes are staged, so a
failed commit proves rollback of snapshot and outbox together. The in-memory
fixture reports itself as a volatile simulation; passing it says nothing about
process restart or disk durability.

Example adapter test entry point:

```dart
void main() => replicaStorageContractTests(
  name: 'SQLite',
  fixture: SqliteStorageContractFixture(),
);
```
