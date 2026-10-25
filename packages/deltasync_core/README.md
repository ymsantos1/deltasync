# deltasync_core

Version 1.0.1 requires upgrade review despite its patch number. The release
aligns all DeltaSync packages and includes intentional source breaks; see the
[migration guide](https://github.com/ymsantos1/deltasync/blob/main/docs/migracao-1.0.1.md).

Pure Dart CRDT state, deltas, clocks and replica identity for DeltaSync.
Supports LWW-Register, MV-Register, G-Counter, PN-Counter, G-Set, 2P-Set, OR-Set
and OR-Map. No Flutter, storage or network dependency.

Add `deltasync_core: ^1.0.1` to your dependencies:

```dart
import 'package:deltasync_core/deltasync_core.dart';

void main() {
  final local = Replica('device-a');
  final remote = Replica('device-b');
  final change = local.incrementGCounter('cart/items', 2);
  remote.apply(Delta([change]));
  print(remote.valueAt('cart/items')); // 2
}
```

`Replica` owns mutable state. Its mutation methods produce typed deltas;
`apply` joins received deltas. Snapshot codecs preserve clocks and causal metadata
for restoration. Keep a stable, unique replica ID per independent installation.
Collections returned by public queries are detached from internal state.

`query(address)` returns a closed `FieldQuery`: `AbsentField` for an unbound
address, `PresentField` with kind/value for a bound value (including null),
or `DeletedField` for the current LWW tombstone. Result constructors are private;
use an exhaustive switch to handle the three cases. All seven other kinds remain
present with zero/empty values. Nested collections are read-only and detached.
`valueAt` keeps returning null for absence, LWW null and deletion. Querying does
not mutate clocks or state and reads only the addressed field. Model conversion
belongs in the application's `PresentField` branch; see the
[field query example](https://github.com/ymsantos1/deltasync/blob/main/example/field_query_example.dart).

Optionally call `field.decode(Model.fromValue)` in the `PresentField` branch.
The consumer supplies `T Function(Object?)`; the method returns T, passes null
as a legitimate input, and propagates decoder failures unchanged. The original
read-only `field.value` remains available. Absent/deleted fields have no decoder
method. Model/schema validation and output mutability belong to the consumer;
see the [decoder example](https://github.com/ymsantos1/deltasync/blob/main/example/field_decoder_example.dart).

This package does not persist or send changes. Use `deltasync` / `SyncEngine`
for atomic local commits, an outbox and remote acknowledgement. Counter IDs and
compact MV formats have compatibility limits described in the
[integration and migration documentation](https://github.com/ymsantos1/deltasync#readme).
Destructive garbage collection and code generation are outside this release.

LWW resolves the whole value, including a JSON object; it does not merge its
attributes or text edits. Choose stable addresses for independently resolved
fields. The eight kinds form a closed integrated catalog: another kind requires
core routing, delta/snapshot codecs, engine entry points and convergence/recovery
tests, not an external plugin registration. Consumer model adapters remain
composition outside the core. See the
[maintenance map](https://github.com/ymsantos1/deltasync/blob/main/docs/referencia-tecnica.md#onde-alterar-cada-tipo).

`mergeSnapshotJson` returns the peer snapshot's processed bound addresses as a
detached/read-only set, including empty CRDTs and tombstones. It does not report
visible-value differences or local-only fields. Existing callers can ignore the
result; overrides must change their return type from void to `Set<String>`.
