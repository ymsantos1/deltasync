import 'dart:convert';
import 'package:deltasync/deltasync.dart';

/// Fixed workload comparison, not a universal benchmark or test threshold.
Future<void> main() async {
  final replica = Replica('measure');
  for (var i = 0; i < 500; i++) {
    replica.setDelta('field-$i', {'items': List<int>.generate(10, (n) => n)});
  }
  final engine = SyncEngine.withStorage(
    replica: replica,
    storage: MemoryStorage(),
    transport: _Transport(),
  );
  await engine.start();
  final snapshot = engine.replica.toSnapshotJson();
  final results = <String, List<int>>{};
  for (final optimized in [false, true]) {
    Object? read() => optimized
        ? engine.valueAt('field-250')
        : engine.replica.state['field-250'];
    for (var i = 0; i < 10; i++) {
      read();
    }
    final samples = <int>[];
    for (var sample = 0; sample < 5; sample++) {
      final watch = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        final value = read() as Map;
        if ((value['items'] as List).length != 10) {
          throw StateError('Different query result');
        }
      }
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
    }
    results[optimized ? 'valueAt' : 'replica.state[]'] = samples;
  }
  if (jsonEncode(engine.replica.toSnapshotJson()) != jsonEncode(snapshot)) {
    throw StateError('Query changed replica snapshot');
  }
  print(
    jsonEncode({
      'fields': 500,
      'itemsPerField': 10,
      'readsPerSample': 100,
      'warmupReads': 10,
      'unit': 'microseconds',
      'samples': results,
      'snapshotUnchanged': true,
    }),
  );
  await engine.dispose();
}

class _Transport implements DeltaTransport {
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async {}
}
