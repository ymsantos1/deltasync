## Unreleased

- Add typed field queries distinguishing absence, present null and retained LWW
  deletion in Replica, SyncEngine and LocalBatch; preserve valueAt semantics.
- Add scoped local batches with one atomic snapshot/outbox commit, rollback on
  callback/edit/storage failure, and per-change delivery/ACK semantics.
- Add pendingSummary and OutboxSummary for peer-scoped retained-entry counts.
  Custom ReplicaStorage implementations must implement the new query; see migration.
- Remove pending-store APIs and deprecated mutation/delta/outbox aliases; require
  ReplicaStorage in SyncEngine. Source migration is required for 1.0.1.
- Keep historical data readers and serialized formats; Operation conversion is
  internal. See docs/migracao-1.0.1.md for upgrade and rollback limits.

## 2.0.0

- Integrate eight CRDTs with typed deltas, versioned codecs and replica snapshots.
- Coordinate atomic local commits, durable outbox entries and peer-specific ACKs.
- Add SQLite persistence, reusable adapter contract tests and recovery checks.
- Expose addressed queries, incoming envelope handling and sync observations.
- Compact MV causal contexts while reading historical serialized formats.
- Validate example consumers on Android, including concurrent edits across devices.
- Introduce addressed counter identities and compact MV formats that older readers
  cannot consume; see README migration/versioning notes before upgrading data.

## 1.0.0

- Initial version.
