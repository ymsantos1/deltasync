## 1.0.0

- Expose the ReplicaStorage contract with atomic snapshot/outbox commits.
- Provide volatile MemoryStorage with peer-specific ACK and conflicting-ID rejection.
- Retain deprecated pending-store migration contracts; MemoryStorage is not durable.
