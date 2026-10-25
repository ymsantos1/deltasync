## 1.0.1

**Upgrade review required:** this intentionally breaking patch consolidates the
source previously labeled 2.0.0. Update all DeltaSync packages together and read
the migration guide before upgrading from 1.0.0. Dart ^3.13.0 is required.
Package renumbering does not change JSON/schema or remove historical readers.

- Require Dart ^3.13.0; align formatter with the declared language version.
- Aggregate pending/sent counts in SQLite without materializing deltas in Dart.
  Keep schema v1; builds without JSON functions use a metadata-reading fallback.

### Retained capabilities

These capabilities already existed at the 1.0.0 baseline. They are retained,
not new format changes or new runtime validation performed for this renumbering.

- Implement atomic SQLite snapshot/outbox commits with peer-specific entries.
- Reject divergent content for existing pending IDs without partial writes.
- Support retry after opening failures and recovery with clocks/causal metadata.
- Validate SQLite FFI and consumer Android scenarios; iOS has no runtime evidence.
