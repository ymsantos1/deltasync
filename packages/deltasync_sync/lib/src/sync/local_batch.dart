part of '../sync_engine.dart';

/// Scoped local editor provided only during [SyncEngine.batch].
///
/// Reads see earlier edits in this batch. No live Replica, raw apply, storage or
/// transport is exposed. Methods expire when the callback ends, before commit.
/// Any failed edit poisons the whole batch even if its exception is caught.
/// Mutation rules and delta generation remain owned by Replica and each CRDT.
final class LocalBatch {
  LocalBatch._(this._candidate);

  Replica? _candidate;
  final List<DeltaChange> _changes = [];
  bool _failed = false;

  Replica get _open {
    final candidate = _candidate;
    if (candidate == null) throw StateError('LocalBatch is closed');
    if (_failed) throw StateError('LocalBatch has a failed edit');
    return candidate;
  }

  Object? valueAt(String address) => _open.valueAt(address);

  /// Reads this batch's candidate; the result is isolated and not yet committed.
  FieldQuery query(String address) => _open.query(address);

  void _record(Iterable<DeltaChange> Function(Replica) mutate) {
    final candidate = _open;
    try {
      _changes.addAll(mutate(candidate));
    } catch (_) {
      _failed = true;
      rethrow;
    }
  }

  Delta _finish() {
    _open;
    return Delta(_changes);
  }

  void _close() {
    _candidate = null;
    _changes.clear();
  }

  void setDelta(String key, Object? value) =>
      _record((replica) => [replica.setDelta(key, value)]);
  void removeDelta(String key) =>
      _record((replica) => [replica.removeDelta(key)]);
  void incrementGCounter(String crdtId, [int amount = 1]) =>
      _record((replica) => [replica.incrementGCounter(crdtId, amount)]);
  void incrementPnCounter(String crdtId, [int amount = 1]) =>
      _record((replica) => [replica.incrementPnCounter(crdtId, amount)]);
  void decrementPnCounter(String crdtId, [int amount = 1]) =>
      _record((replica) => [replica.decrementPnCounter(crdtId, amount)]);
  void addGSet(String crdtId, Object? element) =>
      _record((replica) => [replica.addGSet(crdtId, element)]);
  void addAllGSet(String crdtId, Iterable<Object?> elements) =>
      _record((replica) => [replica.addAllGSet(crdtId, elements)]);
  void addTwoPSet(String crdtId, Object? element) =>
      _record((replica) => [replica.addTwoPSet(crdtId, element)]);
  void addAllTwoPSet(String crdtId, Iterable<Object?> elements) =>
      _record((replica) => [replica.addAllTwoPSet(crdtId, elements)]);
  void removeTwoPSet(String crdtId, Object? element) =>
      _record((replica) => [replica.removeTwoPSet(crdtId, element)]);
  void removeAllTwoPSet(String crdtId, Iterable<Object?> elements) =>
      _record((replica) => [replica.removeAllTwoPSet(crdtId, elements)]);
  void writeMvRegister(String crdtId, Object? value) =>
      _record((replica) => [replica.writeMvRegister(crdtId, value)]);
  void addOrSet(String crdtId, Object? element) =>
      _record((replica) => [replica.addOrSet(crdtId, element)]);
  void removeOrSet(String crdtId, Object? element) =>
      _record((replica) => [replica.removeOrSet(crdtId, element)]);
  void addOrMapKey(String crdtId, String key) =>
      _record((replica) => [replica.addOrMapKey(crdtId, key)]);
  void removeOrMapKey(String crdtId, String key) =>
      _record((replica) => [replica.removeOrMapKey(crdtId, key)]);
  void addOrMapValue(String crdtId, String key, Object? value) =>
      _record((replica) => replica.addOrMapValue(crdtId, key, value));
}
