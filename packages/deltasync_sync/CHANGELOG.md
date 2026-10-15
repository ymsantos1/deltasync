## 2.0.0

- Integrate durable mutations and reconciliation for all eight CRDTs.
- Separate commits from network waits; restore state/outbox before accepting edits.
- Add receiveEnvelope, addressed valueAt queries and broadcast sync observations.
- Preserve manual retry and fixed-peer ACK semantics without a background scheduler.
