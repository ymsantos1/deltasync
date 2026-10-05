import 'dart:convert';

/// Stable identity of a replica.
class ReplicaId implements Comparable<ReplicaId> {
  ReplicaId(String value) : value = value.trim() {
    if (this.value.isEmpty) throw ArgumentError.value(value, 'value');
  }

  final String value;

  @override
  int compareTo(ReplicaId other) => value.compareTo(other.value);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is ReplicaId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Causal event identity: one replica and one strictly positive counter.
class Dot {
  const Dot({required this.replicaId, required this.counter, this.crdtId})
    : assert(replicaId != ''),
      assert(crdtId == null || crdtId != ''),
      assert(counter > 0);

  final String replicaId;
  final int counter;

  /// CRDT namespace for counters whose sequences are local to one instance.
  ///
  /// Null preserves the legacy replica-wide dot namespace used by LWW.
  final String? crdtId;

  Map<String, Object?> toJson() => {
    'replicaId': replicaId,
    'counter': counter,
    if (crdtId != null) 'crdtId': crdtId,
  };

  factory Dot.fromJson(Map<String, Object?> json) {
    final replicaId = json['replicaId'];
    final counter = json['counter'];
    final crdtId = json['crdtId'];
    if (replicaId is! String ||
        replicaId.isEmpty ||
        counter is! int ||
        counter <= 0 ||
        (crdtId != null &&
            (crdtId is! String || crdtId.isEmpty || crdtId.trim() != crdtId))) {
      throw FormatException('Invalid dot');
    }
    return Dot(
      replicaId: replicaId,
      counter: counter,
      crdtId: crdtId as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Dot &&
      other.replicaId == replicaId &&
      other.counter == counter &&
      other.crdtId == crdtId;

  @override
  int get hashCode => Object.hash(replicaId, counter, crdtId);
}

/// Stable message ID for a counter delta, namespaced by CRDT and replica.
String counterDeltaId(String type, String crdtId, String replicaId, int dot) =>
    '$type:${jsonEncode([crdtId, replicaId, dot])}';
