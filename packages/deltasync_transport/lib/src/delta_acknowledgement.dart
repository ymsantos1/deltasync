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

  /// Encodes the existing ACK wire format with stable stage labels.
  /// The returned map and ID list are detached from this acknowledgement.
  Map<String, Object?> toJson() => {
    'peerReplicaId': peerReplicaId,
    'stage': stage.wireName,
    'changeIds': changeIds.toList(),
  };

  /// Decodes an ACK, rejecting malformed peers, stages and IDs.
  ///
  /// Empty ID lists are valid; repeated IDs are deduplicated. Unknown additional
  /// fields are ignored. Invalid known fields throw [FormatException].
  /// Decoding alone does not authorize outbox removal: the caller must bind the
  /// peer to the sent batch and require [DeltaAckStage.appliedAndPersisted].
  factory DeltaAcknowledgement.fromJson(Map<String, Object?> json) {
    final peer = json['peerReplicaId'];
    final stage = json['stage'];
    final ids = json['changeIds'];
    if (peer is! String ||
        peer.isEmpty ||
        peer.trim() != peer ||
        stage is! String ||
        ids is! List ||
        ids.any((id) => id is! String || id.isEmpty || id.trim() != id)) {
      throw const FormatException('Invalid delta acknowledgement');
    }
    return DeltaAcknowledgement(
      peerReplicaId: peer,
      stage: DeltaAckStage.fromWire(stage),
      changeIds: ids.cast<String>(),
    );
  }
}
