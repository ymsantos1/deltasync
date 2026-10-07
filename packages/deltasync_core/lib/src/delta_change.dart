/// Protocol-neutral change produced by a Delta-CRDT.
///
/// [id] is useful for transport, retry and tracing. CRDTs must still make
/// repeated application safe without relying on external deduplication.
abstract interface class DeltaChange {
  String get id;

  CrdtKind get kind;

  String get crdtId;

  String get replicaId;

  Map<String, Object?> toJson();
}

enum CrdtKind {
  lww('lww'),
  gCounter('g-counter'),
  pnCounter('pn-counter'),
  gSet('g-set'),
  twoPSet('2p-set'),
  mvRegister('mv-register'),
  orSet('or-set'),
  orMap('or-map');

  const CrdtKind(this.wireName);

  final String wireName;

  static CrdtKind fromWire(String value) {
    for (final kind in values) {
      if (kind.wireName == value) return kind;
    }
    throw FormatException('Unsupported CRDT delta type');
  }
}
