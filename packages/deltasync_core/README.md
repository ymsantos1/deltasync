# deltasync_core

Pure Dart CRDT state, deltas, clocks and replica identity for DeltaSync.
Supports LWW-Register, MV-Register, G-Counter, PN-Counter, G-Set, 2P-Set, OR-Set
and OR-Map. No Flutter, storage or network dependency.

Add `deltasync_core: ^1.0.0` to your dependencies:

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

This package does not persist or send changes. Use `deltasync` / `SyncEngine`
for atomic local commits, an outbox and remote acknowledgement. Counter IDs and
compact MV formats have compatibility limits described in the
[integration and migration documentation](https://github.com/ymsantos1/deltasync#readme).
Destructive garbage collection and code generation are outside this release.
