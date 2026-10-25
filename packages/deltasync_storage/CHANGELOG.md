## 1.0.1

**Upgrade review required:** this intentionally breaking patch consolidates the
source previously labeled 2.0.0. Update all DeltaSync packages together and read
the migration guide before upgrading from 1.0.0. Dart ^3.13.0 is required.
Package renumbering does not change JSON/schema or remove historical readers.

- Require Dart ^3.13.0; align formatter with the declared language version.
- Add required ReplicaStorage.pendingSummary and immutable OutboxSummary counts.
  MemoryStorage queries entry metadata without decoding delta payloads.
- Remove PendingDeltaStore, MemoryPendingDeltaStore and OutboxEntry.operationId.
  Use ReplicaStorage and entryId/changeIds; export old pending data before upgrade.
- Preserve snapshot/outbox readers and formats, including legacy status labels.

### Retained capabilities

These capabilities already existed at the 1.0.0 baseline. They are retained,
not new format changes or new runtime validation performed for this renumbering.

- Expose the ReplicaStorage contract with atomic snapshot/outbox commits.
- Provide volatile MemoryStorage with peer-specific ACK and conflicting-ID rejection.
- Preserve historical data readers; removed pending-store source APIs require
  migration. MemoryStorage remains volatile.
