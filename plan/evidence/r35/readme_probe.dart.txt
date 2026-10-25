import 'dart:io';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> editOffline(
  String databasePath,
  String replicaId,
  DeltaTransport transport,
) async {
  sqfliteFfiInit(); // Dart desktop; Flutter fornece a factory do sqflite.
  final storage = SqfliteReplicaStorage(
    databaseFactory: databaseFactoryFfi,
    databasePath: databasePath,
  );
  final engine = SyncEngine.withStorage(
    replica: Replica(replicaId),
    storage: storage,
    transport: transport,
  );
  final updates = engine.commitsFor('profile/name').listen((_) {
    print(engine.valueAt('profile/name')); // Valor atual, não ACK.
  });
  try {
    await engine.start(); // Reabre snapshot e outbox do mesmo banco/ID.
    print(engine.query('profile/name')); // Hidratação: stream não tem replay.
    await engine.setDelta('profile/name', 'Ada');
    print('Salvo localmente');
    try {
      final pending = await engine.pendingSummary(
        recipientPeerId: transport.peerReplicaId,
      );
      print('Aguardando ACK: ${pending.totalCount}');
    } catch (error) {
      print('Salvo localmente; consulta de pendências indisponível: $error');
    }
    try {
      final result = await engine.push(); // O app decide quando tentar.
      print('IDs confirmados pelo peer: ${result.acknowledgedIds}');
    } catch (error) {
      print('Salvo localmente; envio falhou: $error');
    }
  } finally {
    await updates.cancel();
    try {
      await engine.dispose();
    } finally {
      await storage.close();
    }
  }
}

class OfflineDocumentationPeer implements DeltaTransport {
  @override
  String get peerReplicaId => 'documentation-peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async => throw StateError('offline');
}

Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp('deltasync-readme-');
  final path = '${directory.path}/readme.sqlite';
  try {
    await editOffline(path, 'documentation-installation', OfflineDocumentationPeer());
    await editOffline(path, 'documentation-installation', OfflineDocumentationPeer());
    final storage = SqfliteReplicaStorage(databaseFactory: databaseFactoryFfi, databasePath: path);
    try {
      final saved = await storage.loadReplica('documentation-installation');
      if (saved == null || Replica.fromSnapshotJson(saved.snapshot!).valueAt('profile/name') != 'Ada') {
        throw StateError('README snapshot was not restored');
      }
      final entries = await storage.pending('documentation-installation');
      if (entries.length != 2 || entries.map((entry) => entry.entryId).toSet().length != 2) {
        throw StateError('README edits did not retain distinct outbox IDs');
      }
      print('README probe: durable reopen and pending IDs verified');
    } finally {
      await storage.close();
    }
  } finally {
    await directory.delete(recursive: true);
  }
}
