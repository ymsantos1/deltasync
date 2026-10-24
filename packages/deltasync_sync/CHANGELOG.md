## Unreleased

- Expose SyncEngine.query after start and LocalBatch.query during the callback;
  distinguish absent/present/deleted without changing commit, outbox or ACK.
- Add SyncEngine.batch and scoped LocalBatch for all eight CRDTs. Reject empty,
  async or failed callbacks; close escaped editors and preserve rollback.
- Add queued pendingSummary queries with lifecycle and query-error propagation.
- Require ReplicaStorage in SyncEngine and remove store, set and remove aliases.
  Keep withStorage and historical restoration; commit and ACK use one storage path.
- Assemble outbox changes in one pass, preserving ID conflict checks and order
  while avoiding repeated prefix merges for large offline batches.

## 2.0.0

- Integrate durable mutations and reconciliation for all eight CRDTs.
- Separate commits from network waits; restore state/outbox before accepting edits.
- Add receiveEnvelope, addressed valueAt queries and broadcast sync observations.
- Preserve manual retry and fixed-peer ACK semantics without a background scheduler.
