## Unreleased

- Remove Replica.set/remove and Delta.crdt/crdtChanges aliases. Use
  setDelta/removeDelta, Delta(changes) and changes.
- Stop exporting Operation and migrateLegacyOperation; historical JSON readers
  still convert these records through DeltaCodec and snapshot restoration.

## 2.0.0

- Integrate LWW/MV registers, G/PN counters, G/2P/OR sets and OR-Map.
- Add scoped identities, causal contexts, ownership-safe state and versioned JSON.
- Compact MV contexts and preserve causal gaps; read supported historical snapshots.
- Require explicit counter addresses; older readers cannot consume current formats.
