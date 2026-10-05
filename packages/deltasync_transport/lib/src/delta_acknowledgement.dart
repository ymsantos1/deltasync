/// Explicit progress reported by the peer for a set of delta change IDs.
enum DeltaAckStage {
  /// Peer received message, but has not confirmed durable incorporation.
  received('received'),

  /// Peer applied changes and durably committed them.
  appliedAndPersisted('applied-and-persisted');

  const DeltaAckStage(this.wireName);

  /// Stable label for adapters that encode ACK stages.
  final String wireName;

  static DeltaAckStage fromWire(String value) => switch (value) {
    'received' => DeltaAckStage.received,
    'applied-and-persisted' => DeltaAckStage.appliedAndPersisted,
    _ => throw FormatException('Unknown delta ACK stage'),
  };
}

/// Acknowledgement bound to one stable peer and delivery stage.
class DeltaAcknowledgement {
  DeltaAcknowledgement({
    required this.peerReplicaId,
    required this.stage,
    required Iterable<String> changeIds,
  }) : changeIds = Set.unmodifiable(changeIds) {
    if (peerReplicaId.isEmpty || peerReplicaId.trim() != peerReplicaId) {
      throw ArgumentError.value(peerReplicaId, 'peerReplicaId');
    }
    if (this.changeIds.any((id) => id.isEmpty || id.trim() != id)) {
      throw ArgumentError.value(changeIds, 'changeIds');
    }
  }

  final String peerReplicaId;
  final DeltaAckStage stage;
  final Set<String> changeIds;
}
