## 1.0.1

**Upgrade review required:** this intentionally breaking patch consolidates the
source previously labeled 2.0.0. Update all DeltaSync packages together and read
the migration guide before upgrading from 1.0.0. Dart ^3.13.0 is required.
Package renumbering does not change JSON/schema or remove historical readers.

- Require Dart ^3.13.0; align formatter with the declared language version.
- Extend the storage contract suite with required pendingSummary behavior,
  peer/status filters, legacy confirmed exclusion, concurrency and commit failure.

### Retained capabilities

These capabilities already existed at the 1.0.0 baseline. They are retained,
not new format changes or new runtime validation performed for this renumbering.

- Provide reusable ReplicaStorage contract tests and fixture interfaces.
- Exercise commits, rollback/failures, isolation, concurrent requests and peer ACKs.
- Distinguish volatile fixtures from persistence/restart guarantees.
