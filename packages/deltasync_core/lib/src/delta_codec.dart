import 'delta.dart';

/// Versioned wire/storage codec for [Delta].
class DeltaCodec {
  static const int currentVersion = 1;

  const DeltaCodec._();

  static Map<String, Object?> encode(Delta delta) => {
    'version': currentVersion,
    'delta': delta.toJson(),
  };

  static Delta decode(Map<String, Object?> json) {
    final version = json['version'];
    final encoded = json['delta'];
    if (version != currentVersion || encoded is! Map) {
      throw FormatException('Unsupported or invalid delta codec version');
    }
    return Delta.fromJson(Map<String, Object?>.from(encoded));
  }
}
