import 'package:deltasync_core/deltasync_core.dart';

/// Network-agnostic delta transport. HTTP and WebSocket adapters belong to apps.
abstract interface class DeltaTransport {
  Future<void> send(Delta delta);

  Stream<Delta> get incoming;
}

/// Optional transport contract that confirms accepted change IDs.
///
/// Return an ID only after the remote side has applied and durably persisted
/// that change. A normal [DeltaTransport.send] completion means transmission
/// completed; it does not confirm remote application or persistence.
abstract interface class AcknowledgingDeltaTransport implements DeltaTransport {
  /// Sends [delta] and returns IDs durably accepted by the remote side.
  Future<Iterable<String>> sendAndAwaitAck(Delta delta);
}
