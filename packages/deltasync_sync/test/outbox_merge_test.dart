import 'package:deltasync_core/deltasync_core.dart';
import 'package:deltasync_storage/deltasync_storage.dart';
import 'package:deltasync_sync/deltasync_sync.dart';
import 'package:deltasync_sync/src/sync/replica_persistence.dart'
    show mergeOutbox;
import 'package:deltasync_transport/deltasync_transport.dart';
import 'package:test/test.dart';

void main() {
  test('empty outbox produces an empty batch', () {
    expect(mergeOutbox(const []).toJson(), const Delta.empty().toJson());
  });

  test('mixed outbox is consumed once without dropping cumulative changes', () {
    final replica = _replica();
    final changes = <DeltaChange>[
      replica.setDelta('lww', {
        'nested': [1, true, null],
      }),
      replica.incrementGCounter('g'),
      replica.decrementPnCounter('pn'),
      replica.addGSet('g-set', 'value'),
      replica.addTwoPSet('2p-set', 'value'),
      replica.writeMvRegister('mv', 'value'),
      replica.addOrSet('or-set', 'value'),
      replica.addOrMapKey('or-map', 'key'),
      replica.incrementGCounter('g'),
    ];
    final entries = [for (final change in changes) _entry(change)];
    var traversals = 0;
    Iterable<OutboxEntry> readOnce() sync* {
      if (++traversals > 1) throw StateError('Outbox read more than once');
      yield* entries;
    }

    final merged = mergeOutbox(readOnce());
    expect(traversals, 1);
    expect(
      merged.changes.map((change) => change.kind).toSet(),
      CrdtKind.values.toSet(),
    );
    expect(merged.toJson(), Delta(changes).toJson());
    expect(merged.changes.whereType<GCounterDelta>(), hasLength(2));
  });

  test('equivalent duplicate keeps first ID position and latest equivalent payload', () {
    final replica = _replica();
    final first = replica.setDelta('json', {
      'a': [
        1,
        {'flag': true},
      ],
      'b': 2,
    });
    final middle = replica.incrementGCounter('g');
    final equivalent = LwwDelta<Object?>.fromJson({
      ...first.toJson(),
      'value': {
        'b': 2,
        'a': [
          1,
          {'flag': true},
        ],
      },
    });
    final entries = [
      _entry(first),
      _entry(middle),
      _entry(equivalent, peer: 'other-peer'),
    ];
    final merged = mergeOutbox(entries);

    expect(merged.changes.map((change) => change.id), [first.id, middle.id]);
    final value = (merged.changes.first as LwwDelta<Object?>).value as Map;
    expect(value.keys.toList(), ['b', 'a']);
    expect(entries, hasLength(3));
    expect(entries.last.recipientPeerId, 'other-peer');
  });

  test('conflicting nested payload is rejected without changing input', () {
    final first = _replica().setDelta('json', {
      'items': [1, 2],
    });
    final divergent = LwwDelta<Object?>.fromJson({
      ...first.toJson(),
      'value': {
        'items': [2, 1],
      },
    });
    final entries = [_entry(first), _entry(divergent, peer: 'other-peer')];
    final before = entries.map((entry) => entry.toJson()).toList();

    expect(() => mergeOutbox(entries), throwsFormatException);
    expect(entries.map((entry) => entry.toJson()).toList(), before);
  });

  test('doubling outbox size keeps ID access growth below quadratic', () {
    int readsFor(int count) {
      final accesses = _Accesses();
      final replica = _replica();
      final entries = [
        for (var index = 0; index < count; index++)
          _MeasuredEntry(replica.setDelta('field-$index', index), accesses),
      ];
      expect(mergeOutbox(entries).changes, hasLength(count));
      expect(accesses.entryReads, count);
      return accesses.idReads;
    }

    final small = readsFor(32);
    final large = readsFor(64);
    print('Outbox ID reads: n=32 reads=$small; n=64 reads=$large');
    expect(small, greaterThan(0));
    expect(large, lessThanOrEqualTo(small * 3));
  });

  test('invalid prepared batch cannot mark sent, send, or discard committed outbox', () async {
    final storage = _PreparationStorage();
    final transport = _RecordingTransport();
    final engine = SyncEngine.withStorage(
      replica: _replica(),
      storage: storage,
      transport: transport,
    );
    try {
      final first = await engine.setDelta('json', {
        'items': [1, 2],
      });
      final before = engine.replica.toSnapshotJson();
      final retained = (await storage.pending('writer')).single.toJson();
      final divergent = LwwDelta<Object?>.fromJson({
        ...first.toJson(),
        'value': {
          'items': [2, 1],
        },
      });
      storage.invalidEntries = [_entry(first), _entry(divergent)];

      await expectLater(engine.pendingDelta(), throwsFormatException);
      await expectLater(engine.push(force: true), throwsFormatException);
      expect(storage.markSentCalls, 0);
      expect(transport.sendCalls, 0);
      expect(engine.replica.toSnapshotJson(), before);
      storage.invalidEntries = null;
      expect((await storage.pending('writer')).single.toJson(), retained);
      expect((await engine.pendingDelta()).changes.single.id, first.id);
    } finally {
      await engine.dispose();
    }
  });
}

Replica _replica() =>
    Replica('writer', hlc: HlcClock(nowMilliseconds: () => 1000));

OutboxEntry _entry(DeltaChange change, {String peer = 'peer'}) => OutboxEntry(
  delta: Delta([change]),
  recipientPeerId: peer,
  createdAt: DateTime.utc(2024),
);

class _Accesses {
  int idReads = 0;
  int entryReads = 0;
}

// Only the internal merge sees this wrapper. Entry construction still validates
// a native delta, so counting does not depend on codec implementation details.
class _MeasuredEntry extends OutboxEntry {
  _MeasuredEntry(DeltaChange change, this.accesses)
    : measured = _MeasuredChange(change, accesses),
      super(delta: Delta([change]), recipientPeerId: 'peer');
  final _MeasuredChange measured;
  final _Accesses accesses;
  @override
  Delta get delta {
    accesses.entryReads++;
    return Delta([measured]);
  }
}

class _MeasuredChange implements DeltaChange {
  _MeasuredChange(this.change, this.accesses);
  final DeltaChange change;
  final _Accesses accesses;
  @override
  String get id {
    accesses.idReads++;
    return change.id;
  }

  @override
  CrdtKind get kind => change.kind;
  @override
  String get crdtId => change.crdtId;
  @override
  String get replicaId => change.replicaId;
  @override
  Map<String, Object?> toJson() => change.toJson();
}

class _PreparationStorage extends MemoryStorage {
  List<OutboxEntry>? invalidEntries;
  int markSentCalls = 0;
  @override
  Future<List<OutboxEntry>> pending(
    String replicaId, {
    String? recipientPeerId,
  }) {
    final invalid = invalidEntries;
    return invalid == null
        ? super.pending(replicaId, recipientPeerId: recipientPeerId)
        : Future.value(invalid);
  }

  @override
  Future<void> markSent(String replicaId, String peer, Iterable<String> ids) {
    markSentCalls++;
    return super.markSent(replicaId, peer, ids);
  }
}

class _RecordingTransport implements DeltaTransport {
  int sendCalls = 0;
  @override
  String get peerReplicaId => 'peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async => sendCalls++;
}
