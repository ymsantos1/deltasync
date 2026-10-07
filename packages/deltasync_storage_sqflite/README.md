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
