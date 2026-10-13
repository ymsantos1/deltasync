import 'package:deltasync_core/deltasync_core.dart';

Map<String, Object?> snapshotWithoutLocalHlc(Map<String, Object?> snapshot) =>
    Map<String, Object?>.of(snapshot)..remove('hlc');

// Replay advances the receiving node's local HLC; compare persisted CRDT state.
Map<String, Object?> normalizedSnapshot(
  Replica replica, {
  bool preserveLocalMetadata = false,
}) {
  // Local owner/sequence fields vary by merge path; causal events remain intact.
  final snapshot = Map<String, Object?>.of(replica.toSnapshotJson())
    ..remove('hlc');
  if (!preserveLocalMetadata) {
    snapshot
      ..remove('replicaId')
      ..remove('deltaSequence');
  }
  for (final key in [
    'gCounters',
    'pnCounters',
    'gSets',
    'twoPSets',
    'mvRegisters',
    'orSets',
    'orMaps',
  ]) {
    final states = snapshot[key] as Map<String, Object?>;
    snapshot[key] = {
      for (final entry in states.entries)
        entry.key: _stateMetadata(entry.value as Map, preserveLocalMetadata),
    };
    if (key == 'pnCounters') {
      // Missing and zero PN components have the same materialized meaning.
      for (final state in (snapshot[key] as Map<String, Object?>).values) {
        final counter = state as Map<String, Object?>;
        for (final component in ['positive', 'negative']) {
          final values = Map<String, Object?>.from(counter[component] as Map)
            ..removeWhere((_, value) => value == 0);
          counter[component] = values;
        }
      }
    }
  }
  final mvRegisters = snapshot['mvRegisters'] as Map<String, Object?>;
  for (final state in mvRegisters.values) {
    final mv = state as Map<String, Object?>;
    final versions = List<Map<String, Object?>>.from(mv['versions'] as List)
      ..sort((first, second) {
        final firstDot = first['dot'] as Map;
        final secondDot = second['dot'] as Map;
        final origin = (firstDot['replicaId'] as String).compareTo(
          secondDot['replicaId'] as String,
        );
        return origin != 0
            ? origin
            : (firstDot['counter'] as int).compareTo(
                secondDot['counter'] as int,
              );
      });
    mv['versions'] = versions;
  }
  return snapshot;
}

Map<String, Object?> _stateMetadata(Map value, bool preserveLocalMetadata) {
  final result = Map<String, Object?>.from(value);
  if (!preserveLocalMetadata) {
    result
      ..remove('replicaId')
      ..remove('sequence');
  }
  return result;
}
