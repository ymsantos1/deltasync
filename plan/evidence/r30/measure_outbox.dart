// Internal-path instrumentation only; application adapters use public imports.
import 'dart:convert';
import 'dart:io';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_sync/src/sync/replica_persistence.dart'
    show mergeOutbox;

/// Fixed workloads for comparing the unchanged algorithm with R-31 later.
void main() {
  final results = <Object?>[];
  for (final count in [32, 128, 512, 1024]) {
    final replica = Replica(
      'cost',
      hlc: HlcClock(nowMilliseconds: () => 1730000000000),
    );
    final changes = <DeltaChange>[];
    for (var index = 0; index < count; index++) {
      changes.add(switch (index % 8) {
        0 => replica.setDelta('lww', index),
        1 => replica.incrementGCounter('g'),
        2 => replica.incrementPnCounter('pn'),
        3 => replica.addGSet('g-set', index),
        4 => replica.addTwoPSet('2p-set', index),
        5 => replica.writeMvRegister('mv', index),
        6 => replica.addOrSet('or-set', index),
        _ => replica.addOrMapKey('or-map', 'key-$index'),
      });
    }
    final time = DateTime.utc(2024);
    final entries = [
      for (var index = 0; index < changes.length; index++)
        OutboxEntry(
          delta: Delta([changes[index]]),
          recipientPeerId: index.isEven ? 'peer-a' : 'peer-b',
          createdAt: time,
        ),
    ];
    // Construction and JSON cloning of OutboxEntry happen before timing.
    final workload = entries
        .where((e) => e.recipientPeerId == 'peer-a')
        .toList();
    final samples = <int>[];
    for (var run = -2; run < 5; run++) {
      final watch = Stopwatch()..start();
      final merged = mergeOutbox(entries);
      watch.stop();
      if (merged.changes.length != count ||
          merged.changes.map((e) => e.id).join('|') !=
              changes.map((e) => e.id).join('|')) {
        throw StateError('Outbox contents/order changed');
      }
      if (run >= 0) samples.add(watch.elapsedMicroseconds);
    }
    if (mergeOutbox(workload).changes.length != workload.length) {
      throw StateError('Peer subset changed');
    }
    results.add({
      'entries': count,
      'peerAEntries': workload.length,
      'kinds': changes.map((change) => change.kind.wireName).toSet().toList(),
      'samplesMicroseconds': samples,
      'baselineReferencePrefixVisits': count * (count + 1) ~/ 2,
      'visitCountEvidence':
          'analytical reference for historical loops, not an instrumented count',
    });
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'sdk': Platform.version,
      'os': Platform.operatingSystem,
      'warmupRuns': 2,
      'measuredRuns': 5,
      'includesEntryConstruction': false,
      'heapMeasured': false,
      'workloads': results,
    }),
  );
}
