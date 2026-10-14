import 'dart:convert';
import 'dart:io';

import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

// Fixture captured from the implementation preceding R-20 (commit 24ce57c).
Map<String, Object?> fixture() => Map<String, Object?>.from(
  jsonDecode(File('test/fixtures/replica_v9_all_kinds.json').readAsStringSync())
      as Map,
);

Replica seeded() =>
    Replica('fixture', hlc: HlcClock(nowMilliseconds: () => 1000))
      ..setDelta('title', {
        'labels': ['draft'],
      })
      ..incrementGCounter('count', 3)
      ..decrementPnCounter('balance', 2)
      ..addGSet('labels', {'id': 1})
      ..addTwoPSet('removed', 'old')
      ..removeTwoPSet('removed', 'old')
      ..writeMvRegister('versions', 'old')
      ..writeMvRegister('versions', 'new')
      ..addOrSet('members', 'old')
      ..removeOrSet('members', 'old')
      ..addOrSet('members', 'new')
      ..addOrMapKey('profile', 'roles')
      ..addOrMapValue('profile', 'roles', 'reader');

void mutateEveryKind(Replica replica) {
  replica
    ..setDelta('title', {
      'labels': ['changed'],
    })
    ..incrementGCounter('count')
    ..incrementPnCounter('balance')
    ..addGSet('labels', {'id': 2})
    ..addTwoPSet('removed', 'new')
    ..writeMvRegister('versions', 'next')
    ..addOrSet('members', 'next')
    ..addOrMapValue('profile', 'roles', 'writer');
}

void main() {
  test('all eight snapshot sections match the pre-refactor fixture', () {
    final replica = seeded();
    expect(replica.toSnapshotJson(), fixture());
    expect(replica.fork().toSnapshotJson(), fixture());
    final restored = Replica.fromSnapshotJson(fixture());
    expect(restored.toSnapshotJson(), fixture());
    expect(restored.export().toJson(), replica.export().toJson());
  });

  test('fork and adopt isolate every kind and preserve local sequences', () {
    final original = seeded();
    final candidate = original.fork();
    mutateEveryKind(candidate);
    expect(original.toSnapshotJson(), fixture());
    original.adopt(candidate);
    final adopted = original.toSnapshotJson();
    mutateEveryKind(candidate);
    expect(original.toSnapshotJson(), adopted);
    final continuation = Replica.fromSnapshotJson(adopted);
    final expected = original.fork();
    mutateEveryKind(continuation);
    mutateEveryKind(expected);
    // Restore uses a new wall-clock source; compare logical CRDT sections and
    // identities independently of the next LWW physical timestamp.
    final continued = continuation.toSnapshotJson();
    final expectedJson = expected.toSnapshotJson();
    for (final key in [
      'gCounters',
      'pnCounters',
      'gSets',
      'twoPSets',
      'mvRegisters',
      'orSets',
      'orMaps',
      'deltaSequence',
      'clock',
    ]) {
      expect(continued[key], expectedJson[key], reason: key);
    }
  });

  test('adopting the same replica cannot clear its owned state', () {
    final replica = seeded();
    final before = replica.toSnapshotJson();
    replica.adopt(replica);
    expect(replica.toSnapshotJson(), before);
  });

  test(
    'legacy section absence and numeric versions keep their reader contract',
    () {
      final sections = {
        'gSets': 4,
        'twoPSets': 5,
        'mvRegisters': 6,
        'orSets': 7,
        'orMaps': 8,
      };
      for (var version = 1; version <= 9; version++) {
        final legacy = Map<String, Object?>.from(
          Replica('empty').toSnapshotJson(),
        )..['version'] = version;
        for (final entry in sections.entries) {
          if (version < entry.value) legacy.remove(entry.key);
        }
        expect(Replica.fromSnapshotJson(legacy).state.addresses, isEmpty);
        for (final entry in sections.entries) {
          if (version >= entry.value) {
            expect(
              () => Replica.fromSnapshotJson({...legacy}..remove(entry.key)),
              throwsFormatException,
              reason: 'v$version ${entry.key}',
            );
          }
        }
      }
      final numeric = fixture()..['version'] = 9.0;
      expect(Replica.fromSnapshotJson(numeric).toSnapshotJson(), fixture());
    },
  );

  test('failed new-address mutation does not bind an unrelated CRDT kind', () {
    final replica = Replica('local');
    expect(() => replica.addAllGSet('empty', []), throwsArgumentError);
    expect(() => replica.addOrMapKey('map', ''), throwsArgumentError);
    expect(replica.state.addresses, isEmpty);
    replica.setDelta('empty', true);
    replica.setDelta('map', true);
    expect(replica.state.values, {'empty': true, 'map': true});
  });
}
