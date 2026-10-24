# deltasync_sync

Pure Dart coordination of local CRDT mutations, atomic storage commits, pending
outbox entries, incoming deltas and remote acknowledgements.
Add `deltasync_sync: ^2.0.0`, `deltasync_core: ^2.0.0`,
`deltasync_storage: ^2.0.0` and your transport adapter's dependencies.
The `deltasync` facade re-exports the four public contracts for convenience.

Construct `SyncEngine.withStorage` with a `Replica`, `ReplicaStorage` and
`DeltaTransport`. Await `start()` to restore state before reading; mutation methods
also await initialization. Use engine methods to edit, preserving atomic snapshot
and outbox commits. `valueAt` reads one address; `observations`, `commits` and
`errors` let the application refresh values and expose failures.

`query(address)` distinguishes `AbsentField`, `PresentField` (including null)
and `DeletedField` (retained LWW tombstone). Like `valueAt`, this synchronous
query requires a started engine and rejects reads after disposal. During storage
or network waits, it reads the last adopted commit; failed commits never expose
their candidate. `LocalBatch.query` instead reads provisional edits and expires
with the editor. Presence/deletion does not depend on outbox entries or ACK.

Use `await engine.batch((batch) { ... })` for related local edits with one atomic
snapshot/outbox commit. The scoped LocalBatch delegates native CRDT mutations and
reads; its callback must finish synchronously without I/O or other engine calls.
Empty/async/failed callbacks abort; the editor expires before storage is awaited.
Storage failure preserves committed state/IDs. Batches still send/ACK per change,
so local atomicity does not promise distributed transactions. See the
[batch example](https://github.com/ymsantos1/deltasync/blob/main/example/local_batch_example.dart).

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
