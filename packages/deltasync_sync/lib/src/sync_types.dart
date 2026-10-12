// ignore_for_file: deprecated_member_use

part of 'sync_engine.dart';

enum SyncFailureSource { incomingDelta, incomingStream }

/// Failure delivered by [SyncEngine.errors] from an incoming transport callback.
class SyncFailure {
  const SyncFailure({
    required this.source,
    required this.error,
    required this.stackTrace,
  });

  final SyncFailureSource source;
  final Object error;
  final StackTrace stackTrace;
}

/// Result of one push attempt. A null [acknowledgement] means only local send
/// completed; received ACKs do not populate [acknowledgedIds]. Legacy storage
/// retains changes even when remote ACK is received.
class SyncPushResult {
  SyncPushResult({
    required this.sent,
    required Iterable<String> acknowledgedIds,
    this.acknowledgement,
  }) : acknowledgedIds = Set.unmodifiable(acknowledgedIds);

  static SyncPushResult get empty =>
      SyncPushResult(sent: const Delta.empty(), acknowledgedIds: const []);

  final Delta sent;
  final Set<String> acknowledgedIds;
  final DeltaAcknowledgement? acknowledgement;

  /// True if every change in [sent] was durably acknowledged; also true if empty.
  bool get fullyAcknowledged =>
      sent.changes.every((change) => acknowledgedIds.contains(change.id));
}

/// Eligibility policy for unconfirmed [ReplicaStorage] entries on each push.
///
/// The caller schedules retries; this policy does not start a timer. New pending
/// entries are eligible on the next push. Sent entries wait for the exponential
/// delay and stop being selected once [maxAttempts] is reached, if configured.
/// `push(force: true)` bypasses both filters. The legacy [PendingDeltaStore]
/// path has no attempt metadata; every push retries its retained delta.
class SyncRetryPolicy {
  const SyncRetryPolicy({
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 1),
    this.maxAttempts,
  });

  /// Initial delay after the first attempt; defaults to one second.
  final Duration baseDelay;

  /// Upper bound for exponential delay; defaults to one minute.
  final Duration maxDelay;

  /// Marked attempts allowed for sent entries; null means no attempt cap.
  final int? maxAttempts;

  Duration delayFor(int attempts) {
    if (attempts <= 0) return Duration.zero;
    var delay = baseDelay > maxDelay ? maxDelay : baseDelay;
    for (var index = 1; index < attempts; index++) {
      final doubled = delay * 2;
      delay = doubled > maxDelay ? maxDelay : doubled;
    }
    return delay;
  }
}
