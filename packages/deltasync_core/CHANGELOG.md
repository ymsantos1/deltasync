## 1.0.1

**Upgrade review required:** this intentionally breaking patch consolidates the
source previously labeled 2.0.0. Update all DeltaSync packages together and read
the migration guide before upgrading from 1.0.0. Dart ^3.13.0 is required.
Package renumbering does not change JSON/schema or remove historical readers.

- Require Dart ^3.13.0; align formatter with the declared language version.
- Return processed peer bindings from mergeSnapshotJson, including empty CRDTs
  and tombstones; overrides must return Set<String> instead of void.
- Add PresentField.decode<T> over the existing isolated query value. Pass null
  to consumer decoders and propagate failures without defaults or state writes.
- Add closed FieldQuery results and Replica.query for absence, present values
  including null, and LWW tombstones. Preserve valueAt and persisted formats;
  expose ReplicaState.isDeletedAt for payload-free LWW metadata inspection.
- Remove Replica.set/remove and Delta.crdt/crdtChanges aliases. Use
  setDelta/removeDelta, Delta(changes) and changes.
- Stop exporting Operation and migrateLegacyOperation; historical JSON readers
  still convert these records through DeltaCodec and snapshot restoration.
- Remove the unused internal legacy encoder and value equality helpers; keep
  historical parsing, validation and migration unchanged.

### Retained capabilities

These capabilities already existed at the 1.0.0 baseline. They are retained,
not new format changes or new runtime validation performed for this renumbering.

- Integrate LWW/MV registers, G/PN counters, G/2P/OR sets and OR-Map.
- Add scoped identities, causal contexts, ownership-safe state and versioned JSON.
- Compact MV contexts and preserve causal gaps; read supported historical snapshots.
- Keep stable counter addresses and the current versioned formats; supported
  historical readers remain available. This maintenance release does not change them.
