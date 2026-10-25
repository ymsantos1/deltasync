## 1.0.1

**Upgrade review required:** this intentionally breaking patch consolidates the
source previously labeled 2.0.0. Update all DeltaSync packages together and read
the migration guide before upgrading from 1.0.0. Dart ^3.13.0 is required.
Package renumbering does not change JSON/schema or remove historical readers.

- Require Dart ^3.13.0; align formatter with the declared language version.
- Add commitsFor and isolated processed-address metadata for local/batch/remote
  commits. Require addresses in non-const SyncCommitEvent; external event
  implementations must add its getter. Keep existing observation variants and
  derive commits/errors from the same asynchronous broadcast source.
- Expose SyncEngine.query after start and LocalBatch.query during the callback;
  distinguish absent/present/deleted without changing commit, outbox or ACK.
- Add SyncEngine.batch and scoped LocalBatch for all eight CRDTs. Reject empty,
  async or failed callbacks; close escaped editors and preserve rollback.
- Add queued pendingSummary queries with lifecycle and query-error propagation.
- Require ReplicaStorage in SyncEngine and remove store, set and remove aliases.
  Keep withStorage and historical restoration; commit and ACK use one storage path.
- Assemble outbox changes in one pass, preserving ID conflict checks and order
  while avoiding repeated prefix merges for large offline batches.

### Retained capabilities

These capabilities already existed at the 1.0.0 baseline. They are retained,
not new format changes or new runtime validation performed for this renumbering.

- Integrate durable mutations and reconciliation for all eight CRDTs.
- Separate commits from network waits; restore state/outbox before accepting edits.
- Add receiveEnvelope, addressed valueAt queries and broadcast sync observations.
- Preserve manual retry and fixed-peer ACK semantics without a background scheduler.
