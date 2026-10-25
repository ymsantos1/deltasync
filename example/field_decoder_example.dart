import 'package:deltasync/deltasync.dart';

// The consumer owns the model, domain checks and presentation of failures.
class Profile {
  Profile(this.name, this.tags);
  final String name;
  final List<String> tags;

  static Profile? fromValue(Object? value) {
    if (value == null) return null; // This application's explicit null policy.
    if (value is! Map || value['name'] is! String || value['tags'] is! List) {
      throw FormatException('Invalid profile');
    }
    final tags = value['tags'] as List;
    if (tags.any((tag) => tag is! String)) {
      throw FormatException('Invalid profile tags');
    }
    return Profile(value['name'] as String, tags.cast<String>().toList());
  }
}

String render(FieldQuery result) {
  try {
    return switch (result) {
      AbsentField() => 'not configured',
      DeletedField() => 'removed',
      PresentField field => switch (field.decode(Profile.fromValue)) {
        null => 'present null',
        Profile(:final name) => 'profile: $name',
      },
    };
  } on FormatException catch (error) {
    // This is a model error after reading; a previous local commit still stands.
    return 'invalid model: ${error.message}';
  }
}

void main() {
  final replica = Replica('example')
    ..setDelta('valid', {
      'name': 'Ada',
      'tags': ['reader'],
    })
    ..setDelta('null', null)
    ..setDelta('invalid', {'name': 42, 'tags': []})
    ..removeDelta('deleted');
  for (final address in ['missing', 'valid', 'null', 'deleted', 'invalid']) {
    print('$address: ${render(replica.query(address))}');
  }
  // Reading without conversion remains available for inspection and migration.
  print('raw invalid: ${(replica.query('invalid') as PresentField).value}');
}
