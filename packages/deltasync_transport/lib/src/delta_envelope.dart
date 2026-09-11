import 'package:deltasync_core/deltasync_core.dart';

/// Versioned transport envelope carrying one delta batch.
class DeltaEnvelope {
  const DeltaEnvelope({
    required this.senderReplicaId,
    required this.delta,
    this.version = currentVersion,
  });

  static const int currentVersion = 1;

  final int version;
  final String senderReplicaId;
  final Delta delta;

  Map<String, Object?> toJson() => {
    'version': version,
    'senderReplicaId': senderReplicaId,
    'delta': DeltaCodec.encode(delta),
  };

  factory DeltaEnvelope.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final sender = json['senderReplicaId'];
    final encoded = json['delta'];
    if (version != currentVersion ||
        sender is! String ||
        sender.isEmpty ||
        encoded is! Map) {
      throw FormatException('Unsupported or invalid delta envelope');
    }
    return DeltaEnvelope(
      senderReplicaId: sender,
      delta: DeltaCodec.decode(Map<String, Object?>.from(encoded)),
    );
  }
}
