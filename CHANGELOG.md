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
