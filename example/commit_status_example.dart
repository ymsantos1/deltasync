import 'dart:io';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'field_decoder_example.dart' show render;

/// Consumer flow: a status/model failure must not relabel a completed commit.
///
/// This demo accepts raw JSON to illustrate post-commit model failures. Real apps
/// validate their own edits before writing and remote model values when reading.
Future<void> saveAndRefresh(
  SyncEngine engine,
  Object? profile,
  void Function(String) report,
) async {
  try {
    await engine.setDelta('profile', profile);
  } catch (error) {
    report('local commit failed: $error');
    return;
  }
  report('saved locally');
  try {
    final summary = await engine.pendingSummary(
      recipientPeerId: engine.transport.peerReplicaId,
    );
    report('awaiting ACK: ${summary.totalCount}');
  } catch (error) {
    report('saved locally; pending status unavailable: $error');
  }
  // render handles an invalid model separately from absence/deletion/null.
  report(render(engine.query('profile')));
}

Future<void> main(List<String> arguments) async {
  sqfliteFfiInit();
  final directory = Directory(
    arguments.isEmpty ? '.dart_tool/deltasync-status-demo' : arguments.single,
  );
  await directory.create(recursive: true);
  final storage = SqfliteReplicaStorage(
    databaseFactory: databaseFactoryFfi,
    databasePath: '${directory.path}/profile.sqlite',
  );
  final engine = SyncEngine.withStorage(
    replica: Replica('status-demo-installation'),
    storage: storage,
    transport: OfflinePeer(),
  );
  final updates = engine.commitsFor('profile').listen((_) {
    print('refresh: ${render(engine.query('profile'))}');
  });
  try {
    await engine.start();
    print('restored: ${render(engine.query('profile'))}');
    await saveAndRefresh(engine, {
      'name': 'Ada',
      'tags': ['reader'],
    }, print);
    try {
      await engine.push();
    } catch (error) {
      print('saved locally; peer unavailable: $error');
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

// Deliberately offline. A real adapter owns authentication, TLS and timeouts.
class OfflinePeer implements DeltaTransport {
  @override
  String get peerReplicaId => 'status-demo-peer';
  @override
  Stream<DeltaEnvelope> get incoming => const Stream.empty();
  @override
  Future<void> send(DeltaEnvelope envelope) async =>
      throw StateError('peer offline');
}
