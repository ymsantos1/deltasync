part of '../replica.dart';

/// Detached point-query result from [Replica.query].
///
/// Variants are closed and constructed by Replica. They describe current local
/// materialized state, not delivery, ACK, synchronization or domain validity.
sealed class FieldQuery {
  const FieldQuery._();
}

/// Address has no bound CRDT. Empty collections/zero of a bound kind are present.
final class AbsentField extends FieldQuery {
  const AbsentField._() : super._();
}

/// Bound field with its current isolated value, including a legitimate null.
///
/// Runtime value types follow Replica.valueAt. Nested collections returned by
/// the library are detached/read-only and do not change after later edits.
final class PresentField extends FieldQuery {
  const PresentField._(this.kind, this.value) : super._();
  final CrdtKind kind;
  final Object? value;
}

/// Current LWW winner is a tombstone. No value is exposed or garbage collected.
/// Other CRDTs retain presence when their visible collection becomes empty.
final class DeletedField extends FieldQuery {
  const DeletedField._() : super._();
}
