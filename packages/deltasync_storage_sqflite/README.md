# deltasync_storage_sqflite

SQLite adapter for `ReplicaStorage`. Core, sync, and storage keep their Dart
contracts and have no Flutter or SQL dependency.

Consumers pass a compatible sqflite `DatabaseFactory` and a database file path:

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

final storage = SqfliteReplicaStorage(
  databaseFactory: databaseFactory,
  databasePath: p.join(await getDatabasesPath(), 'deltasync.sqlite'),
);
```

The adapter owns two tables: one row per replica snapshot and one row per
replica/peer/change in the outbox. Snapshot payload remains the versioned
`ReplicaSnapshot` JSON contract; clocks and CRDT state stay inside that payload.
Local commit writes snapshot and outbox in one SQLite transaction. Remote commit
replaces snapshot in one transaction and leaves outbox rows intact.
`commit` and `enqueue` key pending entries by replica, recipient peer, and change
ID. Repeating equivalent delta content keeps the existing entry and its send
metadata. Reusing that key with divergent content throws `FormatException`.
In `commit`, the snapshot and all new outbox rows roll back together on conflict.
The comparison uses the public `Delta.merge` rule, including nested JSON values.
This behavior does not change the SQLite schema or persisted JSON format.
If opening the database fails, the adapter reports that error and permits a new
attempt through the same instance. Concurrent callers share one opening attempt.
An incompatible schema still fails on every attempt without deleting data.
`close()` waits for an opening already in progress and reports its error if it
fails; call it before backup as described below. `SyncEngine.start()` can be
retried after a transient open failure, restoring state and outbox before edits.

Schema version starts at 1. Unknown upgrades or downgrades fail explicitly and
preserve the database; add a versioned migration before changing the schema.
Close the adapter before copying its database. Copy the main file and SQLite
WAL/SHM companions together, or use SQLite's backup API. Restore preserves
replica IDs, so do not run two independent replicas with one ID unless they
intentionally share the same state and outbox.

For desktop tests, `sqflite_common_ffi` supplies a real SQLite `DatabaseFactory`.
The package's contract and sync recovery tests run against real SQLite through
FFI on Linux x64. Flutter applications pass the platform `sqflite` factory;
Android/iOS plugin behavior is not exercised by these desktop tests. Other
platforms can use any factory compatible with `sqflite_common` and supported by
their runtime. `MemoryStorage` tests do not prove durability.

The [Flutter Android consumer](../../example/flutter_mobile/README.md) was built
and run with the platform `sqflite` factory on a Moto G52, Android 13/API 33.
VAL-07 verified offline commits, pending outbox after process termination,
retry/reconciliation, and persisted acknowledgements after another restart.
This device evidence does not cover iOS or every Android version.
