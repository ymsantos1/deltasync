import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test('point reads cover eight kinds and survive snapshot restore', () {
    final replica = Replica('query')
      ..setDelta('lww', {
        'items': [1],
      })
      ..incrementGCounter('g', 2)
      ..decrementPnCounter('pn', 3)
      ..addGSet('gs', {
        'items': [1],
      })
      ..addTwoPSet('two', 'two')
      ..writeMvRegister('mv', {
        'items': [1],
      })
      ..addOrSet('os', {
        'items': [1],
      })
      ..addOrMapKey('om', 'key')
      ..addOrMapValue('om', 'key', {
        'items': [1],
      })
      ..setDelta('null', null)
      ..removeDelta('deleted');
    final expected = <String, Object?>{
      'lww': {
        'items': [1],
      },
      'g': 2,
      'pn': -3,
      'gs': {
        {
          'items': [1],
        },
      },
      'two': {'two'},
      'mv': {
        {
          'items': [1],
        },
      },
      'os': {
        {
          'items': [1],
        },
      },
      'om': {
        'key': {
          {
            'items': [1],
          },
        },
      },
      'null': null,
      'deleted': null,
      'absent': null,
    };
    for (final instance in [
      replica,
      Replica.fromSnapshotJson(replica.toSnapshotJson()),
    ]) {
      for (final entry in expected.entries) {
        expect(instance.valueAt(entry.key), entry.value, reason: entry.key);
      }
      expect(instance.state.kindAt('absent'), isNull);
      expect(instance.state.kindAt('null'), CrdtKind.lww);
      expect(instance.state.winnerAt('deleted')!.deleted, isTrue);
      final lww = instance.valueAt('lww') as Map;
      expect(() => lww.clear(), throwsUnsupportedError);
      expect(() => (lww['items'] as List).clear(), throwsUnsupportedError);
      for (final address in ['gs', 'mv', 'os']) {
        final value = instance.valueAt(address) as Set;
        expect(() => value.clear(), throwsUnsupportedError);
        expect(() => (value.single as Map).clear(), throwsUnsupportedError);
        expect(
          () => ((value.single as Map)['items'] as List).clear(),
          throwsUnsupportedError,
        );
      }
      expect(
        () => (instance.valueAt('two') as Set).clear(),
        throwsUnsupportedError,
      );
      final map = instance.valueAt('om') as Map;
      expect(() => map.clear(), throwsUnsupportedError);
      final nested = map['key'] as Set;
      expect(() => nested.clear(), throwsUnsupportedError);
      expect(
        () => ((nested.single as Map)['items'] as List).clear(),
        throwsUnsupportedError,
      );
      final oldSet = instance.valueAt('gs') as Set;
      instance.addGSet('gs', 'later');
      expect(oldSet, {
        {
          'items': [1],
        },
      });
      expect(instance.valueAt('gs'), hasLength(2));
    }
  });
}
