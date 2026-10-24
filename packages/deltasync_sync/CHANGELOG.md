## Unreleased

- Require ReplicaStorage in SyncEngine and remove store, set and remove aliases.
  Keep withStorage and historical restoration; commit and ACK use one storage path.
- Assemble outbox changes in one pass, preserving ID conflict checks and order
  while avoiding repeated prefix merges for large offline batches.

## 2.0.0

- Integrate durable mutations and reconciliation for all eight CRDTs.
- Separate commits from network waits; restore state/outbox before accepting edits.
- Add receiveEnvelope, addressed valueAt queries and broadcast sync observations.
- Preserve manual retry and fixed-peer ACK semantics without a background scheduler.
