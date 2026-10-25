# deltasync_sync

Version 1.0.1 requires upgrade review despite its patch number. The release
aligns all DeltaSync packages and includes intentional source breaks; see the
[migration guide](https://github.com/ymsantos1/deltasync/blob/main/docs/migracao-1.0.1.md).

Pure Dart coordination of local CRDT mutations, atomic storage commits, pending
outbox entries, incoming deltas and remote acknowledgements.
Add `deltasync_sync: ^1.0.1`, `deltasync_core: ^1.0.1`,
`deltasync_storage: ^1.0.1` and your transport adapter's dependencies.
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

Convert an already present result with `field.decode(Model.fromValue)` or keep
its raw `value`. Conversion uses the isolated query value, performs no engine
write/I/O, and propagates failures to the caller without emitting an engine
error or undoing a prior commit. Handle absent/deleted cases explicitly. A saved
result can still be converted after dispose; obtaining a new query cannot.

Use `commitsFor(address)` to refresh selected fields after a commit. Its events
carry a detached/read-only `addresses` set of processed input bindings, including
replay/losing writes, tombstones and bound empty snapshot CRDTs. This is not a
visible-value diff. Read `query` for current state; hydrate initially because
streams do not replay. Filters never poll, copy the replica or trigger push.
`observations`, `commits` and `errors` now share one asynchronous broadcast source;
ordering is per subscription. Resume/cancel paused subscriptions before awaiting
dispose; paused filters may buffer unrelated source events. Constructors of
`SyncCommitEvent` now require addresses and are no longer const; external
implementations must supply the getter. See the
[selective example](https://github.com/ymsantos1/deltasync/blob/main/example/selective_observation_example.dart).

Use `await engine.batch((batch) { ... })` for related local edits with one atomic
snapshot/outbox commit. The scoped LocalBatch delegates native CRDT mutations and
reads; its callback must finish synchronously without I/O or other engine calls.
Empty/async/failed callbacks abort; the editor expires before storage is awaited.
Storage failure preserves committed state/IDs. Batches still send/ACK per change,
so local atomicity does not promise distributed transactions. See the
[batch example](https://github.com/ymsantos1/deltasync/blob/main/example/local_batch_example.dart).

Local mutation completion means local commit. Use `pendingSummary` to count
pending/sent entries without building a delta; pass the engine's peer ID to count
only that link (no filter counts all peers). Sent entries still await ACK.
Handle a summary/model conversion failure after the save separately: it cannot
undo the completed commit and must not trigger a repeated edit. `pendingDelta()`
remains available to inspect retained payloads. `push()` attempts delivery; only an `appliedAndPersisted` ACK
from the expected peer confirms changes and removes their outbox entries.
Network waits do not block local editing. Retry policy belongs to the consumer.

For incoming traffic, `receiveEnvelope()` validates routing, commits remote state
and returns an acknowledgement. With `IncomingAcknowledgingDeltaTransport`, the
engine also sends that ACK through the adapter; otherwise the caller sends the
returned response after success. Dispose
the engine when finished, after cancelling application listeners. Drain it before
closing concrete transport/storage resources, including when disposal fails.
The engine does not close those resources. Retry start on transient open failure
before disposal; a disposed engine is terminal. New composition with the same
database/identity restores prior state/outbox. See the
[commit/status example](https://github.com/ymsantos1/deltasync/blob/main/example/commit_status_example.dart).

MemoryStorage is volatile. Use a durable adapter and stable replica IDs to recover
across process restarts. This package does not provide peer discovery, production
HTTP or authentication. The
[runnable facade example](https://github.com/ymsantos1/deltasync/blob/main/example/deltasync_example.dart)
shows composition without a framework. The
[integration guide](https://github.com/ymsantos1/deltasync/blob/main/docs/guia-integracao.md)
describes application boundaries and extension contracts.
