import 'delta_acknowledgement.dart';
import 'delta_envelope.dart';

/// Network-agnostic transport for versioned DeltaSync messages.
/// HTTP and WebSocket adapters belong to apps.
abstract interface class DeltaTransport {
  /// Stable identity of the single remote peer this transport is bound to.
  String get peerReplicaId;

  /// Sends an envelope. Completion means transport send finished, not remote ACK.
  Future<void> send(DeltaEnvelope envelope);

  /// Incoming envelopes preserve sender and encoded delta metadata.
  Stream<DeltaEnvelope> get incoming;
}

/// Optional transport contract that reports the remote peer's ACK stage.
///
/// Receipt alone never permits outbox cleanup. The sync engine removes IDs only
/// from an [DeltaAcknowledgement] at [DeltaAckStage.appliedAndPersisted] from
/// the configured peer. A normal [DeltaTransport.send] completion means local
/// transmission finished, not receipt or remote application.
abstract interface class AcknowledgingDeltaTransport implements DeltaTransport {
  /// Sends [envelope] and returns the peer's latest explicit ACK stage.
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope);
}
