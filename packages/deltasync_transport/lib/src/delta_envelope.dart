import 'package:deltasync_core/deltasync_core.dart';

/// Versioned transport envelope carrying one [Delta] batch.
///
/// [senderReplicaId] identifies the current sender. It may differ from the
/// origin replicas in [delta], for example when forwarding changes.
/// [recipientReplicaId] binds delivery and ACKs to one stable peer.
class DeltaEnvelope {
  DeltaEnvelope({
    required this.senderReplicaId,
    required this.recipientReplicaId,
    required this.delta,
    this.version = currentVersion,
  }) {
    if (version != currentVersion) {
      throw ArgumentError.value(version, 'version');
    }
    if (senderReplicaId.isEmpty || senderReplicaId.trim() != senderReplicaId) {
      throw ArgumentError.value(senderReplicaId, 'senderReplicaId');
    }
    if (recipientReplicaId.isEmpty ||
        recipientReplicaId.trim() != recipientReplicaId) {
      throw ArgumentError.value(recipientReplicaId, 'recipientReplicaId');
    }
  }

  static const int currentVersion = 2;

  final int version;
  final String senderReplicaId;
  final String recipientReplicaId;
  final Delta delta;

  /// Encodes envelope version 2 with the current [DeltaCodec] representation.
  Map<String, Object?> toJson() => {
    'version': version,
    'senderReplicaId': senderReplicaId,
    'recipientReplicaId': recipientReplicaId,
    'delta': DeltaCodec.encode(delta),
  };

  factory DeltaEnvelope.fromJson(
    Map<String, Object?> json, {
    String? legacyRecipientReplicaId,
  }) {
    final version = json['version'];
    final sender = json['senderReplicaId'];
    final encodedRecipient = json['recipientReplicaId'];
    final recipient = version == 1
        ? legacyRecipientReplicaId
        : encodedRecipient;
    final encoded = json['delta'];
    if ((version != 1 && version != currentVersion) ||
        sender is! String ||
        sender.isEmpty ||
        sender.trim() != sender ||
        recipient is! String ||
        recipient.isEmpty ||
        recipient.trim() != recipient ||
        encoded is! Map) {
      throw FormatException('Unsupported or invalid delta envelope');
    }
    try {
      return DeltaEnvelope(
        senderReplicaId: sender,
        recipientReplicaId: recipient,
        delta: DeltaCodec.decode(Map<String, Object?>.from(encoded)),
      );
    } on TypeError {
      throw FormatException('Unsupported or invalid delta envelope');
    }
  }
}
