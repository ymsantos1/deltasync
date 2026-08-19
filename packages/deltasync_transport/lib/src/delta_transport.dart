import 'package:deltasync_core/deltasync_core.dart';

/// Network-agnostic delta transport. HTTP and WebSocket adapters belong to apps.
abstract interface class DeltaTransport {
  Future<void> send(Delta delta);

  Stream<Delta> get incoming;
}
