import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'snapshot merge reports peer bindings including empty kinds and tombstone',
    () {
      final peer = Replica('peer')
        ..setDelta('null', null)
        ..removeDelta('deleted');
      final snapshot = Map<String, Object?>.of(peer.toSnapshotJson());
      snapshot['gCounters'] = {'g': GCounter('peer', crdtId: 'g').toJson()};
      snapshot['pnCounters'] = {'pn': PnCounter('peer', crdtId: 'pn').toJson()};
      snapshot['gSets'] = {'gs': GSet('peer', crdtId: 'gs').toJson()};
      snapshot['twoPSets'] = {'two': TwoPSet('peer', crdtId: 'two').toJson()};
      snapshot['mvRegisters'] = {
        'mv': MvRegister('peer', crdtId: 'mv').toJson(),
      };
      snapshot['orSets'] = {'os': OrSet('peer', crdtId: 'os').toJson()};
      snapshot['orMaps'] = {'om': OrMap('peer', crdtId: 'om').toJson()};
      final local = Replica('local')..setDelta('local-only', true);
      final processed = local.mergeSnapshotJson(snapshot);
      expect(processed, {
        'null',
        'deleted',
        'g',
        'pn',
        'gs',
        'two',
        'mv',
        'os',
        'om',
      });
      expect(() => processed.clear(), throwsUnsupportedError);
      expect(local.query('deleted'), isA<DeletedField>());
      expect((local.query('null') as PresentField).value, isNull);
      expect(local.valueAt('g'), 0);
      expect(local.valueAt('local-only'), isTrue);
      expect(local.mergeSnapshotJson(snapshot), processed);
      local.setDelta('later', true);
      expect(processed, isNot(contains('later')));
    },
  );

  test(
    'invalid snapshot merge does not return metadata or alter local state',
    () {
      final local = Replica('local')..setDelta('field', true);
      final before = local.toSnapshotJson();
      expect(
        () => local.mergeSnapshotJson({'version': -1}),
        throwsFormatException,
      );
      expect(local.toSnapshotJson(), before);
    },
  );
}
