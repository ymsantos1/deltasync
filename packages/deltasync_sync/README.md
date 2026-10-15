# deltasync_sync

Pure Dart coordination of local CRDT mutations, atomic storage commits, pending
outbox entries, incoming deltas and remote acknowledgements.
Add `deltasync_sync: ^1.0.0`, `deltasync_core: ^1.0.0`,
`deltasync_storage: ^1.0.0` and your transport adapter's dependencies.
The `deltasync` facade re-exports the four public contracts for convenience.

Construct `SyncEngine.withStorage` with a `Replica`, `ReplicaStorage` and
`DeltaTransport`. Await `start()` to restore state before reading; mutation methods
also await initialization. Use engine methods to edit, preserving atomic snapshot
and outbox commits. `valueAt` reads one address; `observations`, `commits` and
`errors` let the application refresh values and expose failures.

Local mutation completion means local commit. `pendingDelta()` reports changes
awaiting delivery. `push()` attempts delivery; only an `appliedAndPersisted` ACK
from the expected peer confirms changes and removes their outbox entries.
Network waits do not block local editing. Retry policy belongs to the consumer.

For incoming traffic, `receiveEnvelope()` validates routing, commits remote state
and returns an acknowledgement. With `IncomingAcknowledgingDeltaTransport`, the
engine also sends that ACK through the adapter; otherwise the caller sends the
returned response after success. Dispose
the engine when finished; the consumer also owns storage/transport resources.

MemoryStorage is volatile. Use a durable adapter and stable replica IDs to recover
across process restarts. This package does not provide peer discovery, production
HTTP or authentication. The
[runnable facade example](https://github.com/ymsantos1/deltasync/blob/main/example/deltasync_example.dart)
shows composition without a framework. The
[integration guide](https://github.com/ymsantos1/deltasync/blob/main/docs/guia-integracao.md)
describes application boundaries and extension contracts.
