import 'package:deltasync/deltasync.dart';

// Application presentation stays outside core. Domain decoding belongs in the
// PresentField branch, where null remains a legitimate stored value.
String describe(FieldQuery result) => switch (result) {
  AbsentField() => 'not configured',
  DeletedField() => 'removed (LWW tombstone retained)',
  PresentField(:final kind, :final value) => '${kind.wireName}: $value',
};

void main() {
  final replica = Replica('example')
    ..setDelta('nullable', null)
    ..removeDelta('deleted')
    ..incrementPnCounter('zero')
    ..decrementPnCounter('zero')
    ..addOrSet('empty', 'item')
    ..removeOrSet('empty', 'item');
  for (final field in ['missing', 'nullable', 'deleted', 'zero', 'empty']) {
    print('$field: ${describe(replica.query(field))}');
  }
  // These three reads all return null; use query when the distinction matters.
  assert(replica.valueAt('missing') == null);
  assert(replica.valueAt('nullable') == null);
  assert(replica.valueAt('deleted') == null);
}
