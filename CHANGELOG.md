## 1.0.1

**Upgrade review required:** this intentionally breaking patch consolidates the
source previously labeled 2.0.0. Update all DeltaSync packages together and read
the migration guide before upgrading from 1.0.0. Dart ^3.13.0 is required.
Package renumbering does not change JSON/schema or remove historical readers.

- Raise minimum Dart SDK to ^3.13.0 by author direction; validate CI commands
  with Dart 3.13.5/Flutter 3.47.7, online advisory checks and failure fixtures.
- Add processed commit addresses and commitsFor filters over one observation
  source. SyncCommitEvent now requires addresses and is no longer const;
  Replica.mergeSnapshotJson returns processed snapshot addresses instead of void.
- Add optional PresentField.decode<T> for consumer model conversion, preserving
  raw values, explicit absent/deleted branches and unwrapped decoder failures.
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
- Assemble outbox batches in one pass without changing joins, ID conflicts or order.
- Evaluate Saropa essential in isolation and defer permanent adoption; recommended
  lint and online dependency advisories remain separate from CRDT/recovery tests.
- Simplify durable SQLite integration, consumer models, ownership and source
  migration; exercise post-commit status failures without losing saved edits.

### Retained capabilities

These capabilities already existed at the 1.0.0 baseline. They are retained,
not new format changes or new runtime validation performed for this renumbering.

- Integrate eight CRDTs with typed deltas, versioned codecs and replica snapshots.
- Coordinate atomic local commits, durable outbox entries and peer-specific ACKs.
- Add SQLite persistence, reusable adapter contract tests and recovery checks.
- Expose addressed queries, incoming envelope handling and sync observations.
- Compact MV causal contexts while reading historical serialized formats.
- Validate example consumers on Android, including concurrent edits across devices.
- Retain addressed counter identities and compact MV formats with their existing
  reader compatibility limits; see the migration guide before opening older data.

## 1.0.0

- Initial version.
