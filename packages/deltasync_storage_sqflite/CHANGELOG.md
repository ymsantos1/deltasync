## 2.0.0

- Implement atomic SQLite snapshot/outbox commits with peer-specific entries.
- Reject divergent content for existing pending IDs without partial writes.
- Support retry after opening failures and recovery with clocks/causal metadata.
- Validate SQLite FFI and consumer Android scenarios; iOS has no runtime evidence.
