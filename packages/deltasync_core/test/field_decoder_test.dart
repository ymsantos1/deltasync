import 'package:deltasync_core/deltasync_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'consumer model conversion keeps raw value and does not write state',
    () {
      final replica = Replica('decoder')
        ..setDelta('profile', {
          'name': 'Ada',
          'tags': ['reader'],
        });
      final before = replica.toSnapshotJson();
      final field = replica.query('profile') as PresentField;
      final Profile model = field.decode(Profile.fromValue);
      expect(model.name, 'Ada');
      model.tags.add('local model edit');
      expect(field.value, {
        'name': 'Ada',
        'tags': ['reader'],
      });
      expect(replica.toSnapshotJson(), before);
      replica.setDelta('profile', 'later');
      expect(field.decode(Profile.fromValue).name, 'Ada');
    },
  );

  test(
    'absent/deleted branches skip decoder; present null invokes it once',
    () {
      final replica = Replica('decoder')
        ..setDelta('null', null)
        ..removeDelta('deleted');
      var calls = 0;
      String describe(String address) => switch (replica.query(address)) {
        AbsentField() => 'absent',
        DeletedField() => 'deleted',
        PresentField field => field.decode((value) {
          calls++;
          expect(value, isNull);
          return 'present null';
        }),
      };
      expect(describe('missing'), 'absent');
      expect(describe('deleted'), 'deleted');
      expect(calls, 0);
      expect(describe('null'), 'present null');
      expect(calls, 1);
      final String? nullable = (replica.query('null') as PresentField)
          .decode<String?>((value) => null);
      expect(nullable, isNull);
      expect(replica.query('null'), isA<PresentField>());
    },
  );

  test(
    'model errors and nested mutation errors propagate without state changes',
    () {
      final replica = Replica('decoder')
        ..setDelta('invalid', {'name': 42, 'tags': []})
        ..setDelta('nested', {
          'items': [1],
        });
      final before = replica.toSnapshotJson();
      final invalid = replica.query('invalid') as PresentField;
      expect(() => invalid.decode(Profile.fromValue), throwsFormatException);
      final nested = replica.query('nested') as PresentField;
      expect(
        () =>
            nested.decode((value) => ((value as Map)['items'] as List).clear()),
        throwsUnsupportedError,
      );
      final failure = StateError('consumer decoder failed');
      expect(
        () => nested.decode<Object?>((value) => throw failure),
        throwsA(same(failure)),
      );
      expect(replica.toSnapshotJson(), before);
      expect(nested.value, {
        'items': [1],
      });
    },
  );

  test('all eight kinds use the same isolated conversion input', () {
    final replica = Replica('decoder')
      ..setDelta('lww', {
        'items': [1],
      })
      ..incrementGCounter('g')
      ..decrementPnCounter('pn')
      ..addGSet('gs', {
        'items': [1],
      })
      ..addTwoPSet('two', {
        'items': [1],
      })
      ..writeMvRegister('mv', {
        'items': [1],
      })
      ..addOrSet('os', {
        'items': [1],
      })
      ..addOrMapKey('om', 'key')
      ..addOrMapValue('om', 'key', {
        'items': [1],
      });
    final before = replica.toSnapshotJson();
    final kinds = <CrdtKind>{};
    for (final address in ['lww', 'g', 'pn', 'gs', 'two', 'mv', 'os', 'om']) {
      final field = replica.query(address) as PresentField;
      kinds.add(field.kind);
      final Object? raw = field.decode((value) {
        expect(identical(value, field.value), isTrue);
        return value;
      });
      expect(raw, replica.valueAt(address));
      if (raw is int) continue;
      final Map nested = switch (field.kind) {
        CrdtKind.lww => raw as Map,
        CrdtKind.orMap => ((raw as Map)['key'] as Set).single as Map,
        _ => (raw as Set).single as Map,
      };
      expect(() => (nested['items'] as List).clear(), throwsUnsupportedError);
    }
    expect(kinds, CrdtKind.values.toSet());
    expect(replica.toSnapshotJson(), before);
  });
}

// A consumer owns the model and its schema. This is not a library model.
class Profile {
  Profile(this.name, this.tags);
  final String name;
  final List<String> tags;
  static Profile fromValue(Object? value) {
    if (value is! Map || value['name'] is! String || value['tags'] is! List) {
      throw FormatException('Invalid profile');
    }
    final tags = value['tags'] as List;
    if (tags.any((tag) => tag is! String)) {
      throw FormatException('Invalid tags');
    }
    return Profile(value['name'] as String, tags.cast<String>().toList());
  }
}
