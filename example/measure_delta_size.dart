import 'dart:convert';

import 'package:deltasync/deltasync.dart';

const _fixedMilliseconds = 1730000000000;

void main() {
  final measurements = [
    _measure(
      replicaId: 'shopper-a',
      recipientPeerId: 'shopper-b',
      buyerName: 'Ana',
      itemCount: 2,
    ),
    _measure(
      replicaId: 'shopper-b',
      recipientPeerId: 'shopper-a',
      buyerName: 'Beto',
      itemCount: 3,
    ),
  ];

  var deltaBytes = 0;
  var envelopeBytes = 0;
  var snapshotBytes = 0;
  for (final measurement in measurements) {
    deltaBytes += measurement.deltaBytes;
    envelopeBytes += measurement.envelopeBytes;
    snapshotBytes += measurement.snapshotBytes;
    print(
      '${measurement.replicaId}: mutations=2, '
      'delta=${measurement.deltaBytes} B, '
      'envelope=${measurement.envelopeBytes} B, '
      'snapshot=${measurement.snapshotBytes} B',
    );
  }

  final ratio = envelopeBytes / snapshotBytes * 100;
  print(
    'total: mutations=4, delta=$deltaBytes B, '
    'envelope=$envelopeBytes B, snapshot=$snapshotBytes B, '
    'envelope/snapshot=${ratio.toStringAsFixed(1)}%',
  );
}

({String replicaId, int deltaBytes, int envelopeBytes, int snapshotBytes})
_measure({
  required String replicaId,
  required String recipientPeerId,
  required String buyerName,
  required int itemCount,
}) {
  final replica = Replica(
    replicaId,
    hlc: HlcClock(nowMilliseconds: () => _fixedMilliseconds),
  );
  final nameChange = replica.setDelta('buyers/$replicaId', buyerName);
  final countChange = replica.incrementGCounter('cart/items', itemCount);
  final delta = Delta([nameChange, countChange]);
  final encodedDelta = DeltaCodec.encode(delta);
  final envelope = DeltaEnvelope(
    senderReplicaId: replicaId,
    recipientReplicaId: recipientPeerId,
    delta: delta,
  );

  return (
    replicaId: replicaId,
    deltaBytes: _jsonBytes(encodedDelta),
    envelopeBytes: _jsonBytes(envelope.toJson()),
    snapshotBytes: _jsonBytes(replica.toSnapshotJson()),
  );
}

int _jsonBytes(Object value) => utf8.encode(jsonEncode(value)).length;
