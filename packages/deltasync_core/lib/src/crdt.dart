/// Common contract for CRDTs whose synchronization unit is a delta.
///
/// Concrete CRDTs define the shape of [D]. Applying the same delta more than
/// once must produce the same state as applying it once.
abstract interface class DeltaCrdt<V, D> {
  V get value;

  void applyDelta(D delta);

  void mergeState(covariant DeltaCrdt<V, D> other);

  Map<String, Object?> toJson();
}
