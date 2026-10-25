// ignore_for_file: deprecated_member_use

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_transport/deltasync_transport.dart';

enum SyncFailureSource { incomingDelta, incomingStream }

enum SyncCommitOrigin { local, remote }

/// Session events for observing sync without duplicating durable state.
/// Query pendingDelta/valueAt for current data; events are not replayed.
sealed class SyncObservation {
  const SyncObservation();
}

/// Initialization finished; restored outbox may still contain pending changes.
class SyncRestoredEvent extends SyncObservation {
  const SyncRestoredEvent();
}

/// A push failed. Committed state/outbox remain available for retry.
/// Other directly awaited failures still belong to their calling Future.
class SyncPushFailure extends SyncObservation {
  const SyncPushFailure({required this.error, required this.stackTrace});
  final Object error;
  final StackTrace stackTrace;
}

/// Notification after a local mutation or remote merge is committed and adopted.
/// It signals state availability, not remote acknowledgement.
class SyncCommitEvent extends SyncObservation {
  SyncCommitEvent({required this.origin, required Iterable<String> addresses})
    : addresses = Set.unmodifiable(addresses);

  final SyncCommitOrigin origin;

  /// Unique addresses processed by this committed input, not visible changes.
  /// Includes replay/losing LWW input, tombstones and empty bound snapshot CRDTs.
  /// Snapshot metadata includes peer addresses only. Detached and read-only.
  final Set<String> addresses;
}

/// Failure delivered by `SyncEngine.errors` from an incoming transport callback.
class SyncFailure extends SyncObservation {
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
class SyncPushResult extends SyncObservation {
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
/// `push(force: true)` bypasses both filters.
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

/// Public lifecycle of a `SyncEngine`. A failed start returns to [created] and
/// may be retried; [disposed] is terminal.
enum SyncEngineLifecycle { created, starting, started, disposed }
