import '../hlc.dart';
import '../json_value.dart';
import '../vector_clock.dart';
import 'contents.dart';

/// Internal codec for the stable v9 snapshot and its v1-v8 readers.
/// It validates into detached contents; storage and commit remain outside core.
class ReplicaSnapshotCodec {
  static const currentVersion = 9;

  static Map<String, Object?> encode({
    required String replicaId,
    required VectorClock clock,
    required HlcTimestamp hlc,
    required int deltaSequence,
    required ReplicaContents contents,
  }) =>
      copyJsonValue({
            'version': currentVersion,
            'replicaId': replicaId,
            'clock': clock.toJson(),
            'hlc': hlc.toJson(),
            'deltaSequence': deltaSequence,
            ...contents.toSnapshotJson(),
          }, freeze: true)
          as Map<String, Object?>;

  static DecodedReplicaSnapshot decode(Map<String, Object?> json) {
    final encodedVersion = json['version'];
    if (!const [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      currentVersion,
    ].contains(encodedVersion)) {
      throw FormatException('Unsupported replica snapshot version');
    }
    final version = (encodedVersion as num).toInt();
    final replicaId = json['replicaId'];
    final clock = json['clock'];
    final hlc = json['hlc'];
    final lww = json['lww'];
    if (replicaId is! String ||
        replicaId.isEmpty ||
        replicaId.trim() != replicaId ||
        clock is! Map ||
        hlc is! Map ||
        lww is! Map) {
      throw FormatException('Invalid replica snapshot');
    }
    final contents = ReplicaContents(replicaId);
    contents.validateSnapshotTables(json, version);
    final restoredClock = VectorClock.fromJson(
      Map<String, Object?>.from(clock),
    );
    final restoredHlc = HlcClock(
      initial: HlcTimestamp.fromJson(Map<String, Object?>.from(hlc)),
    );
    final lwwTimestamp = contents.state.restoreSnapshotJson(
      Map<String, Object?>.from(lww),
    );
    if (lwwTimestamp != null) restoredHlc.restore(lwwTimestamp);
    contents.restoreTables(
      json,
      version,
      allowCompactContext: version == currentVersion,
    );
    return DecodedReplicaSnapshot(
      replicaId,
      restoredClock,
      restoredHlc,
      readReplicaSequence(json['deltaSequence']),
      contents,
    );
  }
}

class DecodedReplicaSnapshot {
  const DecodedReplicaSnapshot(
    this.replicaId,
    this.clock,
    this.hlc,
    this.deltaSequence,
    this.contents,
  );
  final String replicaId;
  final VectorClock clock;
  final HlcClock hlc;
  final int deltaSequence;
  final ReplicaContents contents;
}
