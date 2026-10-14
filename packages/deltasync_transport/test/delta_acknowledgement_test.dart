import 'dart:convert';

import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  for (final stage in DeltaAckStage.values) {
    test('ACK round-trips stable label for ${stage.wireName}', () {
      final ack = DeltaAcknowledgement(
        peerReplicaId: 'peer',
        stage: stage,
        changeIds: ['one', 'two'],
      );
      final wire = ack.toJson();
      expect(wire, {
        'peerReplicaId': 'peer',
        'stage': stage.wireName,
        'changeIds': ['one', 'two'],
      });
      final restored = DeltaAcknowledgement.fromJson(
        Map<String, Object?>.from(jsonDecode(jsonEncode(wire)) as Map),
      );
      expect(restored.peerReplicaId, ack.peerReplicaId);
      expect(restored.stage, stage);
      expect(restored.changeIds, ack.changeIds);
    });
  }

  test('ACK accepts empty lists and deduplicates IDs without aliasing', () {
    final ids = ['one', 'one'];
    final input = <String, Object?>{
      'peerReplicaId': 'peer',
      'stage': 'received',
      'changeIds': ids,
      'future': true,
    };
    final ack = DeltaAcknowledgement.fromJson(input);
    ids.add('two');
    expect(ack.changeIds, {'one'});
    final encoded = ack.toJson();
    (encoded['changeIds'] as List).add('three');
    encoded['peerReplicaId'] = 'other';
    expect(ack.changeIds, {'one'});
    expect(ack.peerReplicaId, 'peer');
    expect(() => ack.changeIds.add('four'), throwsUnsupportedError);
    input['changeIds'] = <String>[];
    expect(DeltaAcknowledgement.fromJson(input).changeIds, isEmpty);
  });

  test('ACK rejects missing, malformed and unknown known fields', () {
    final valid = <String, Object?>{
      'peerReplicaId': 'peer',
      'stage': 'applied-and-persisted',
      'changeIds': ['one'],
    };
    for (final key in valid.keys) {
      expect(
        () => DeltaAcknowledgement.fromJson({...valid}..remove(key)),
        throwsFormatException,
      );
    }
    for (final peer in [null, 1, '', ' ', ' peer', 'peer ']) {
      expect(
        () => DeltaAcknowledgement.fromJson({...valid, 'peerReplicaId': peer}),
        throwsFormatException,
      );
    }
    for (final stage in [null, 1, '', 'future', 'appliedAndPersisted']) {
      expect(
        () => DeltaAcknowledgement.fromJson({...valid, 'stage': stage}),
        throwsFormatException,
      );
    }
    for (final ids in [
      null,
      1,
      'one',
      {'one'},
      [null],
      [1],
      [''],
      [' '],
      [' one'],
      ['one '],
      ['one', 2],
    ]) {
      expect(
        () => DeltaAcknowledgement.fromJson({...valid, 'changeIds': ids}),
        throwsFormatException,
      );
    }
  });
}
