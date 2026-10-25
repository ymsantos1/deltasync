import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

String describe(FieldQuery result) => switch (result) {
  AbsentField() => 'absent',
  DeletedField() => 'deleted',
  PresentField(:final value) => value == null ? 'null' : 'value',
};

void main() {
  test('typed result separates absent, present null and LWW deletion', () {
    final replica = Replica('query');
    expect(describe(replica.query('field')), 'absent');
    replica.setDelta('field', null);
    expect(describe(replica.query('field')), 'null');
    expect((replica.query('field') as PresentField).kind, CrdtKind.lww);
    replica.removeDelta('field');
    expect(describe(replica.query('field')), 'deleted');
    expect(replica.state.isDeletedAt('field'), isTrue);
    for (final field in ['missing', 'field']) {
      expect(replica.valueAt(field), isNull);
    }
    replica.setDelta('null', null);
    expect(replica.valueAt('null'), isNull);
    replica.setDelta('field', 'restored');
    expect(describe(replica.query('field')), 'value');
    expect(replica.state.isDeletedAt('field'), isFalse);
  });

  test(
    'seven bound empty/zero kinds remain present after snapshot restore',
    () {
      final snapshot = Map<String, Object?>.of(
        Replica('empty').toSnapshotJson(),
      );
      snapshot['gCounters'] = {'g': GCounter('empty', crdtId: 'g').toJson()};
      snapshot['pnCounters'] = {
        'pn': PnCounter('empty', crdtId: 'pn').toJson(),
      };
      snapshot['gSets'] = {'gs': GSet('empty', crdtId: 'gs').toJson()};
      snapshot['twoPSets'] = {'two': TwoPSet('empty', crdtId: 'two').toJson()};
      snapshot['mvRegisters'] = {
        'mv': MvRegister('empty', crdtId: 'mv').toJson(),
      };
      snapshot['orSets'] = {'os': OrSet('empty', crdtId: 'os').toJson()};
      snapshot['orMaps'] = {'om': OrMap('empty', crdtId: 'om').toJson()};
      final replica = Replica.fromSnapshotJson(snapshot);
      for (final field in ['g', 'pn', 'gs', 'two', 'mv', 'os', 'om']) {
        final result = replica.query(field) as PresentField;
        expect(result.kind, replica.state.kindAt(field));
        expect(result.value, replica.valueAt(field));
      }
      expect((replica.query('g') as PresentField).value, 0);
      expect((replica.query('pn') as PresentField).value, 0);
      expect((replica.query('gs') as PresentField).value, isEmpty);
      expect((replica.query('mv') as PresentField).value, isEmpty);
      expect(replica.query('unknown'), isA<AbsentField>());
    },
  );

  test(
    'eight kinds return isolated stable values without changing metadata',
    () {
      final replica = Replica('query');
      replica.setDelta('lww', {
        'items': [1],
      });
      replica.incrementGCounter('g');
      replica.incrementPnCounter('pn');
      replica.decrementPnCounter('pn');
      replica.addGSet('gs', {
        'items': [1],
      });
      replica.addTwoPSet('two', {
        'items': [1],
      });
      replica.writeMvRegister('mv', {
        'items': [1],
      });
      replica.addOrSet('os', {
        'items': [1],
      });
      replica.addOrMapKey('om', 'key');
      replica.addOrMapValue('om', 'key', {
        'items': [1],
      });
      final before = replica.toSnapshotJson();
      final results = <String, PresentField>{};
      for (final field in ['lww', 'g', 'pn', 'gs', 'two', 'mv', 'os', 'om']) {
        results[field] = replica.query(field) as PresentField;
      }
      expect(
        results.values.map((e) => e.kind).toSet(),
        CrdtKind.values.toSet(),
      );
      for (final field in ['lww', 'gs', 'two', 'mv', 'os', 'om']) {
        final value = results[field]!.value;
        final Object? nested = field == 'lww'
            ? value
            : field == 'om'
            ? ((value as Map)['key'] as Set).single
            : (value as Set).single;
        expect(
          () => ((nested as Map)['items'] as List).clear(),
          throwsUnsupportedError,
        );
      }
      expect(replica.toSnapshotJson(), before);
      replica.setDelta('lww', 'new');
      replica.addGSet('gs', 'new');
      expect(results['lww']!.value, {
        'items': [1],
      });
      expect(results['gs']!.value, hasLength(1));
      expect((replica.query('pn') as PresentField).value, 0);
    },
  );

  test('empty observed sets/maps are present and MV null is a set value', () {
    final replica = Replica('query')
      ..addTwoPSet('two', 'a')
      ..removeTwoPSet('two', 'a')
      ..addOrSet('os', 'a')
      ..removeOrSet('os', 'a')
      ..addOrMapKey('om', 'a')
      ..removeOrMapKey('om', 'a')
      ..writeMvRegister('mv', null);
    for (final field in ['two', 'os', 'om']) {
      expect((replica.query(field) as PresentField).value, isEmpty);
    }
    final mv = replica.query('mv') as PresentField;
    expect(mv.kind, CrdtKind.mvRegister);
    expect(mv.value, {null});
  });

  test(
    'concurrent LWW winner determines null/deletion, independent of arrival',
    () {
      final old = Replica('old', hlc: HlcClock(nowMilliseconds: () => 100));
      final newer = Replica('new', hlc: HlcClock(nowMilliseconds: () => 200));
      final last = Replica('last', hlc: HlcClock(nowMilliseconds: () => 300));
      final deletion = old.removeDelta('field');
      final nullValue = newer.setDelta('field', null);
      final finalDelete = last.removeDelta('field');
      for (final order in [
        [deletion, nullValue],
        [nullValue, deletion],
      ]) {
        final replica = Replica('receiver');
        for (final change in order) {
          replica.apply(Delta([change]));
        }
        expect(replica.query('field'), isA<PresentField>());
        expect((replica.query('field') as PresentField).value, isNull);
        replica.apply(Delta([finalDelete, nullValue]));
        expect(replica.query('field'), isA<DeletedField>());
        final before = replica.toSnapshotJson();
        for (var i = 0; i < 20; i++) {
          replica.query('field');
          replica.query('missing');
        }
        expect(replica.toSnapshotJson(), before);
      }
    },
  );

  test('point queries never request full state, fork or snapshot', () {
    final replica = _PointOnlyReplica();
    for (var i = 0; i < 500; i++) {
      replica.setDelta('field/$i', i);
    }
    expect((replica.query('field/0') as PresentField).value, 0);
    expect(replica.valueAt('field/0'), 0);
    expect(replica.query('missing'), isA<AbsentField>());
    replica.removeDelta('field/0');
    expect(replica.query('field/0'), isA<DeletedField>());
  });
}

// Guard against regressions that rebuild the whole replica just to read a field.
class _PointOnlyReplica extends Replica {
  _PointOnlyReplica() : super('point-only');
  @override
  ReplicaState get state => throw StateError('Full state copy');
  @override
  Replica fork() => throw StateError('Full replica copy');
  @override
  Map<String, Object?> toSnapshotJson() => throw StateError('Full snapshot');
}
