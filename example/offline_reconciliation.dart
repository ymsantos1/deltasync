import 'dart:async';
import 'dart:io';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _replicaA = 'shopper-a';
const _replicaB = 'shopper-b';
const _defaultDirectory = '.dart_tool/deltasync-offline-demo';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty ||
      !{'reset', 'offline', 'reconnect'}.contains(arguments[0])) {
    stderr.writeln(
      'Usage: dart run example/offline_reconciliation.dart '
      '<reset|offline|reconnect> [directory]',
    );
    exitCode = 64;
    return;
  }

  final phase = arguments[0];
  final directory = Directory(
    arguments.length > 1 ? arguments[1] : _defaultDirectory,
  );
  final pathA = _databasePath(directory, _replicaA);
  final pathB = _databasePath(directory, _replicaB);

  sqfliteFfiInit();
  if (phase == 'reset') {
    await directory.create(recursive: true);
    await databaseFactoryFfi.deleteDatabase(pathA);
    await databaseFactoryFfi.deleteDatabase(pathB);
    print('Demonstração limpa: ${directory.path}');
    return;
  }

  await directory.create(recursive: true);
  if (phase == 'offline') {
    await _editOffline(pathA, pathB, directory.path);
    return;
  }

  await _reconnect(pathA, pathB, directory.path);
}

Future<void> _editOffline(String pathA, String pathB, String directory) async {
  final linkA = DemoPeerLink(_replicaB);
  final linkB = DemoPeerLink(_replicaA);
  final storageA = _storage(pathA);
  final storageB = _storage(pathB);
  final appA = ShoppingApp(_engine(_replicaA, storageA, linkA));
  final appB = ShoppingApp(_engine(_replicaB, storageB, linkB));

  try {
    await Future.wait([appA.start(), appB.start()]);
    await appA.rename('Ana');
    await appA.addItems(2);
    await appB.rename('Beto');
    await appB.addItems(3);

    await _tryPush(appA);
    await _tryPush(appB);
    await _show('A offline', appA);
    await _show('B offline', appB);
    print(
      'Bancos gravados em $directory. Feche este processo e execute reconnect.',
    );
  } finally {
    await Future.wait([appA.dispose(), appB.dispose()]);
    await Future.wait([storageA.close(), storageB.close()]);
    await Future.wait([linkA.close(), linkB.close()]);
  }
}

Future<void> _reconnect(String pathA, String pathB, String directory) async {
  final linkA = DemoPeerLink(_replicaB);
  final linkB = DemoPeerLink(_replicaA);
  final storageA = _storage(pathA);
  final storageB = _storage(pathB);
  final appA = ShoppingApp(_engine(_replicaA, storageA, linkA));
  final appB = ShoppingApp(_engine(_replicaB, storageB, linkB));

  try {
    await Future.wait([appA.start(), appB.start()]);
    await _show('A restaurado, antes da reconexão', appA);
    await _show('B restaurado, antes da reconexão', appB);

    linkA.deliver = (envelope) => appB.engine.applyRemote(envelope.delta);
    linkB.deliver = (envelope) => appA.engine.applyRemote(envelope.delta);
    final results = await Future.wait([
      appA.engine.push(force: true),
      appB.engine.push(force: true),
    ]);
    if (results.any((result) => !result.fullyAcknowledged)) {
      throw StateError('Peer did not acknowledge every committed change');
    }

    await _show('A confirmado', appA);
    await _show('B confirmado', appB);
    _expectConverged(appA, appB);

    await Future.wait([appA.dispose(), appB.dispose()]);
    await Future.wait([storageA.close(), storageB.close()]);

    final reopenedAStorage = _storage(pathA);
    final reopenedBStorage = _storage(pathB);
    final reopenedLinkA = DemoPeerLink(_replicaB);
    final reopenedLinkB = DemoPeerLink(_replicaA);
    final reopenedA = ShoppingApp(
      _engine(_replicaA, reopenedAStorage, reopenedLinkA),
    );
    final reopenedB = ShoppingApp(
      _engine(_replicaB, reopenedBStorage, reopenedLinkB),
    );
    try {
      await Future.wait([reopenedA.start(), reopenedB.start()]);
      _expectConverged(reopenedA, reopenedB);
      if ((await reopenedA.pendingCount) != 0 ||
          (await reopenedB.pendingCount) != 0) {
        throw StateError('Acknowledged outbox was restored as pending');
      }
      await _show('A após reinício final', reopenedA);
      await _show('B após reinício final', reopenedB);
      print(
        'Convergência e outbox confirmadas após reabrir bancos em $directory.',
      );
    } finally {
      await Future.wait([reopenedA.dispose(), reopenedB.dispose()]);
      await Future.wait([reopenedAStorage.close(), reopenedBStorage.close()]);
      await Future.wait([reopenedLinkA.close(), reopenedLinkB.close()]);
    }
  } finally {
    if (appA.engine.lifecycle != SyncEngineLifecycle.disposed) {
      await appA.dispose();
    }
    if (appB.engine.lifecycle != SyncEngineLifecycle.disposed) {
      await appB.dispose();
    }
    await Future.wait([storageA.close(), storageB.close()]);
    await Future.wait([linkA.close(), linkB.close()]);
  }
}

SyncEngine _engine(
  String replicaId,
  SqfliteReplicaStorage storage,
  DemoPeerLink transport,
) => SyncEngine.withStorage(
  replica: Replica(replicaId),
  storage: storage,
  transport: transport,
);

SqfliteReplicaStorage _storage(String path) => SqfliteReplicaStorage(
  databaseFactory: databaseFactoryFfi,
  databasePath: path,
);

String _databasePath(Directory directory, String replicaId) =>
    '${directory.path}${Platform.pathSeparator}$replicaId.sqlite';

Future<void> _tryPush(ShoppingApp app) async {
  try {
    await app.engine.push(force: true);
  } on StateError catch (error) {
    app.lastFailure = error.message;
  }
}

Future<void> _show(String label, ShoppingApp app) async {
  final view = app.view;
  final pending = await app.pendingCount;
  final status = app.lastFailure != null
      ? 'falha; commit local preservado'
      : pending == 0
      ? 'confirmado pelo peer'
      : 'commit local; envio pendente';
  print(
    '$label: compradores=${view.shopperA}/${view.shopperB}, '
    'itens=${view.itemCount}, status=$status, pendentes=$pending, '
    'falha=${app.lastFailure ?? 'nenhuma'}',
  );
}

void _expectConverged(ShoppingApp first, ShoppingApp second) {
  if (first.view != second.view) {
    throw StateError(
      'Replicas did not converge: ${first.view} != ${second.view}',
    );
  }
}

/// Consumer-owned model mapping and presentation state; DeltaSync owns CRDTs,
/// commits, snapshots, and outbox processing.
class ShoppingApp {
  ShoppingApp(this.engine);

  final SyncEngine engine;
  String? lastFailure;

  Future<void> start() => engine.start();

  Future<void> rename(String value) async {
    await engine.setDelta('shopper/${engine.replica.id}/name', value);
    lastFailure = null;
  }

  Future<void> addItems(int count) async {
    await engine.incrementGCounter('shopping/items', count);
    lastFailure = null;
  }

  ShoppingView get view {
    final replica = engine.replica;
    return ShoppingView(
      shopperA: replica.state.values['shopper/$_replicaA/name'] as String?,
      shopperB: replica.state.values['shopper/$_replicaB/name'] as String?,
      itemCount: replica.gCounterValue('shopping/items'),
    );
  }

  Future<int> get pendingCount async =>
      (await engine.pendingDelta()).changes.length;

  Future<void> dispose() => engine.dispose();
}

class ShoppingView {
  const ShoppingView({
    required this.shopperA,
    required this.shopperB,
    required this.itemCount,
  });

  final String? shopperA;
  final String? shopperB;
  final int itemCount;

  @override
  bool operator ==(Object other) =>
      other is ShoppingView &&
      other.shopperA == shopperA &&
      other.shopperB == shopperB &&
      other.itemCount == itemCount;

  @override
  int get hashCode => Object.hash(shopperA, shopperB, itemCount);

  @override
  String toString() =>
      'ShoppingView(shopperA: $shopperA, shopperB: $shopperB, '
      'itemCount: $itemCount)';
}

class DemoPeerLink implements AcknowledgingDeltaTransport {
  DemoPeerLink(this.peerReplicaId);

  @override
  final String peerReplicaId;
  final _incoming = StreamController<DeltaEnvelope>.broadcast();
  Future<void> Function(DeltaEnvelope)? deliver;

  @override
  Stream<DeltaEnvelope> get incoming => _incoming.stream;

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    final handler = deliver;
    if (handler == null) throw StateError('Peer $peerReplicaId is offline');
    await handler(envelope);
  }

  @override
  Future<DeltaAcknowledgement> sendAndAwaitAck(DeltaEnvelope envelope) async {
    await send(envelope);
    return DeltaAcknowledgement(
      peerReplicaId: peerReplicaId,
      stage: DeltaAckStage.appliedAndPersisted,
      changeIds: envelope.delta.changes.map((change) => change.id),
    );
  }

  Future<void> close() => _incoming.close();
}
