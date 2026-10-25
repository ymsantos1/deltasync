## Unreleased

- Require Dart ^3.13.0; align formatter with the declared language version.
- Aggregate pending/sent counts in SQLite without materializing deltas in Dart.
  Keep schema v1; builds without JSON functions use a metadata-reading fallback.

## 2.0.0

- Implement atomic SQLite snapshot/outbox commits with peer-specific entries.
- Reject divergent content for existing pending IDs without partial writes.
- Support retry after opening failures and recovery with clocks/causal metadata.
- Validate SQLite FFI and consumer Android scenarios; iOS has no runtime evidence.
