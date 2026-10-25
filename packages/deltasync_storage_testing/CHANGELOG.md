## Unreleased

- Require Dart ^3.13.0; align formatter with the declared language version.
- Extend the storage contract suite with required pendingSummary behavior,
  peer/status filters, legacy confirmed exclusion, concurrency and commit failure.

## 2.0.0

- Provide reusable ReplicaStorage contract tests and fixture interfaces.
- Exercise commits, rollback/failures, isolation, concurrent requests and peer ACKs.
- Distinguish volatile fixtures from persistence/restart guarantees.
