import 'dart:io';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:deltasync_mobile_consumer/support/eight_scenario.dart';
import 'package:deltasync_mobile_consumer/support/http_peer_link.dart';

class _Peer {
  _Peer(this.engine, this.storage, this.link, this.port);
  final SyncEngine engine;
  final SqfliteReplicaStorage storage;
  final HttpPeerLink link;
  final int port;
  EightScenario get scenario => EightScenario(engine);

  static Future<_Peer> open(String id, String path) async {
    final link = HttpPeerLink(
      peerReplicaId: id == 'alpha' ? 'beta' : 'alpha',
      peerUri: Uri.parse('http://127.0.0.1:1'),
    );
    final storage = SqfliteReplicaStorage(
      databaseFactory: databaseFactoryFfi,
      databasePath: path,
    );
    final engine = SyncEngine.withStorage(
      replica: Replica(id),
      storage: storage,
      transport: link,
    );
    await engine.start();
    final port = await link.listen(
      engine,
      port: 0,
      report: EightScenario(engine).report,
    );
    return _Peer(engine, storage, link, port);
  }

  Future<void> close() async {
    await link.close();
    await engine.dispose();
    await storage.close();
  }
}

void _connect(_Peer a, _Peer b) {
  a.link.peerUri = Uri.parse('http://127.0.0.1:${b.port}');
  b.link.peerUri = Uri.parse('http://127.0.0.1:${a.port}');
}

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'eight CRDTs preserve concurrent history over HTTP and SQLite restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('eight-peer-');
      var a = await _Peer.open('alpha', '${directory.path}/a.sqlite');
      var b = await _Peer.open('beta', '${directory.path}/b.sqlite');
      try {
        _connect(a, b);
        await a.scenario.seed();
        await a.engine.push(force: true);
        expect(b.engine.valueAt(EightScenario.address(CrdtKind.gCounter)), 1);
        a.link.peerUri = b.link.peerUri = Uri.parse('http://127.0.0.1:1');
        await expectLater(
          a.engine.push(force: true),
          completes,
        ); // Empty outbox.
        await Future.wait([a.scenario.branch(), b.scenario.branch()]);
        await expectLater(
          a.engine.push(force: true),
          throwsA(isA<SocketException>()),
        );
        await expectLater(
          b.engine.push(force: true),
          throwsA(isA<SocketException>()),
        );
        await Future.wait([
          a.scenario.editAfterFailure(),
          b.scenario.editAfterFailure(),
        ]);
        final pendingA = await a.engine.pendingDelta();
        final pendingB = await b.engine.pendingDelta();
        await a.close();
        await b.close();
        a = await _Peer.open('alpha', '${directory.path}/a.sqlite');
        b = await _Peer.open('beta', '${directory.path}/b.sqlite');
        expect((await a.engine.pendingDelta()).toJson(), pendingA.toJson());
        expect((await b.engine.pendingDelta()).toJson(), pendingB.toJson());
        _connect(a, b);
        await Future.wait([
          a.engine.push(force: true),
          b.engine.push(force: true),
        ]);
        final values = (await a.scenario.report())['values'] as Map;
        expect(values, (await b.scenario.report())['values']);
        expect(values['lww'], anyOf('alpha-retry', 'beta-retry'));
        expect(values['g-counter'], 6);
        expect(values['pn-counter'], 3);
        expect(values['g-set'], ['alpha', 'beta', 'seed']);
        expect(values['2p-set'], ['alpha', 'beta']);
        expect(values['mv-register'], ['alpha', 'beta']);
        expect(values['or-set'], ['alpha', 'beta', 'shared']);
        expect(values['or-map'], {
          'shared': ['beta'],
        });
        expect((await a.engine.pendingDelta()).isEmpty, isTrue);
        expect((await b.engine.pendingDelta()).isEmpty, isTrue);
        // Replay the exact pre-ACK envelopes: joins must remain idempotent.
        await a.link.sendAndAwaitAck(
          DeltaEnvelope(
            senderReplicaId: 'alpha',
            recipientReplicaId: 'beta',
            delta: pendingA,
          ),
        );
        await b.link.sendAndAwaitAck(
          DeltaEnvelope(
            senderReplicaId: 'beta',
            recipientReplicaId: 'alpha',
            delta: pendingB,
          ),
        );
        expect((await a.scenario.report())['values'], values);
        expect((await b.scenario.report())['values'], values);
        await a.scenario.resolve();
        await a.engine.push(force: true);
        expect(b.engine.valueAt(EightScenario.address(CrdtKind.mvRegister)), {
          'resolved',
        });
        final resolved = (await b.scenario.report())['values'];
        await b.close();
        b = await _Peer.open('beta', '${directory.path}/b.sqlite');
        expect((await b.scenario.report())['values'], resolved);
        expect((await b.engine.pendingDelta()).isEmpty, isTrue);
      } finally {
        await a.close();
        await b.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'peer rejects wrong recipient without committing or returning ACK',
    () async {
      final directory = await Directory.systemTemp.createTemp('eight-invalid-');
      final a = await _Peer.open('alpha', '${directory.path}/a.sqlite');
      final b = await _Peer.open('beta', '${directory.path}/b.sqlite');
      try {
        _connect(a, b);
        await expectLater(b.scenario.seed(), throwsStateError);
        await expectLater(a.scenario.branch(), throwsStateError);
        await a.scenario.seed();
        final pending = await a.engine.pendingDelta();
        await expectLater(
          a.link.sendAndAwaitAck(
            DeltaEnvelope(
              senderReplicaId: 'alpha',
              recipientReplicaId: 'intruder',
              delta: pending,
            ),
          ),
          throwsA(isA<HttpException>()),
        );
        expect(
          b.engine.valueAt(EightScenario.address(CrdtKind.gCounter)),
          isNull,
        );
        expect((await a.engine.pendingDelta()).toJson(), pending.toJson());
      } finally {
        await a.close();
        await b.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
