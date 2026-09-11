/// Protocol-neutral change produced by a Delta-CRDT.
///
/// [id] is useful for transport, retry and tracing. CRDTs must still make
/// repeated application safe without relying on external deduplication.
abstract interface class DeltaChange {
  String get id;

  Map<String, Object?> toJson();
}
