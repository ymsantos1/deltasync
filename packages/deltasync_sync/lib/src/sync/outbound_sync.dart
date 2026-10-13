// ignore_for_file: deprecated_member_use

import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_transport/deltasync_transport.dart';
import '../sync_types.dart';
import 'replica_persistence.dart';

/// Internal outbound flow. prepare mutates attempt metadata and must be queued;
/// send only performs transport I/O. ACK persistence is queued by SyncEngine.
class OutboundSync {
  OutboundSync({
    required this.replicaId,
    required this.persistence,
    required this.transport,
    required this.retryPolicy,
  });
  final String replicaId;
  final ReplicaPersistence persistence;
  final DeltaTransport transport;
  final SyncRetryPolicy retryPolicy;

  Future<SyncPushResult> send(
    ({Delta delta, List<String> ids}) outbound,
  ) async {
    final envelope = DeltaEnvelope(
      senderReplicaId: replicaId,
      recipientReplicaId: transport.peerReplicaId,
      delta: outbound.delta,
    );
    final acknowledgement = transport is AcknowledgingDeltaTransport
        ? await (transport as AcknowledgingDeltaTransport).sendAndAwaitAck(
            envelope,
          )
        : await _sendWithoutAck(envelope);
    if (acknowledgement != null &&
        acknowledgement.peerReplicaId != transport.peerReplicaId) {
      throw StateError('ACK peer does not match configured transport peer');
    }
    final acceptedIds =
        acknowledgement?.stage == DeltaAckStage.appliedAndPersisted
        ? acknowledgement!.changeIds
              .where(outbound.ids.toSet().contains)
              .toSet()
        : <String>{};
    return SyncPushResult(
      sent: outbound.delta,
      acknowledgedIds: acceptedIds,
      acknowledgement: acknowledgement,
    );
  }

  Future<({Delta delta, List<String> ids})> prepare({
    required bool force,
  }) async {
    if (persistence.storage == null) {
      final pending = await persistence.store!.read(replicaId);
      return (
        delta: pending,
        ids: pending.changes.map((change) => change.id).toList(),
      );
    }
    final allEntries = await persistence.storage!.pending(
      replicaId,
      recipientPeerId: transport.peerReplicaId,
    );
    final now = DateTime.now().toUtc();
    final entries = allEntries.where((entry) {
      if (force || entry.status == OutboxStatus.pending) return true;
      final maxAttempts = retryPolicy.maxAttempts;
      if (maxAttempts != null && entry.attempts >= maxAttempts) return false;
      final sentAt = entry.sentAt;
      return sentAt == null ||
          now.difference(sentAt) >= retryPolicy.delayFor(entry.attempts);
    }).toList();
    if (entries.isEmpty) {
      return (delta: const Delta.empty(), ids: const <String>[]);
    }
    final pending = mergeOutbox(entries);
    final ids = entries.expand((entry) => entry.changeIds).toList();
    await persistence.storage!.markSent(
      replicaId,
      transport.peerReplicaId,
      ids,
    );
    return (delta: pending, ids: ids);
  }

  Future<DeltaAcknowledgement?> _sendWithoutAck(DeltaEnvelope envelope) async {
    await transport.send(envelope);
    return null;
  }
}
