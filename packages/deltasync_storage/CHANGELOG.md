## Unreleased

- Add required ReplicaStorage.pendingSummary and immutable OutboxSummary counts.
  MemoryStorage queries entry metadata without decoding delta payloads.
- Remove PendingDeltaStore, MemoryPendingDeltaStore and OutboxEntry.operationId.
  Use ReplicaStorage and entryId/changeIds; export old pending data before upgrade.
- Preserve snapshot/outbox readers and formats, including legacy status labels.

## 2.0.0

- Expose the ReplicaStorage contract with atomic snapshot/outbox commits.
- Provide volatile MemoryStorage with peer-specific ACK and conflicting-ID rejection.
- Retain deprecated pending-store migration contracts; MemoryStorage is not durable.
