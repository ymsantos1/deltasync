import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'peer_link.dart';

const sharedTitleAddress = 'shopping/title';
const sharedItemsAddress = 'shopping/items';

enum DemoSide {
  a('A', 'shopper-a'),
  b('B', 'shopper-b');

  const DemoSide(this.label, this.replicaId);

  final String label;
  final String replicaId;

  DemoSide get other => this == a ? b : a;
}

class DemoReplicaView {
  const DemoReplicaView({
    required this.side,
    required this.title,
    required this.items,
    required this.pending,
    required this.winner,
    required this.error,
    required this.confirmation,
  });

  final DemoSide side;
  final String? title;
  final int items;
  final int pending;
  final String? winner;
  final String? error;
  final String? confirmation;
}

class DemoSnapshot {
  const DemoSnapshot({
    required this.peerAvailable,
    required this.a,
    required this.b,
  });

  final bool peerAvailable;
  final DemoReplicaView a;
  final DemoReplicaView b;
}

/// Owns two durable replicas and the synthetic peer link used by this app.
class DemoSession {
  DemoSession._(
    this._factory,
    this._paths,
    this._engines,
    this._storages,
    this._links,
  );

  final DatabaseFactory _factory;
  final Map<DemoSide, String> _paths;
  final Map<DemoSide, SyncEngine> _engines;
  final Map<DemoSide, SqfliteReplicaStorage> _storages;
  final Map<DemoSide, PeerLink> _links;
  final Map<DemoSide, String?> _errors = {};
  final Map<DemoSide, String?> _confirmations = {};
  bool _peerAvailable = false;
  bool _closed = false;

  static Future<DemoSession> open({
    required DatabaseFactory factory,
    required String directory,
  }) async {
    final paths = {
      for (final side in DemoSide.values)
        side: '$directory/${side.replicaId}.sqlite',
    };
    final storages = {
      for (final side in DemoSide.values)
        side: SqfliteReplicaStorage(
          databaseFactory: factory,
          databasePath: paths[side]!,
        ),
    };
    final links = {
      for (final side in DemoSide.values) side: PeerLink(side.other.replicaId),
    };
    final engines = {
      for (final side in DemoSide.values)
        side: SyncEngine.withStorage(
          replica: Replica(side.replicaId),
          storage: storages[side]!,
          transport: links[side]!,
        ),
    };
    final session = DemoSession._(factory, paths, engines, storages, links);
    try {
      await Future.wait(engines.values.map((engine) => engine.start()));
      return session;
    } catch (error, stackTrace) {
      try {
        await session.close();
      } catch (closeError, closeStackTrace) {
        debugPrint('VAL08 CLOSE ERROR $closeError\n$closeStackTrace');
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void setPeerAvailable(bool available) {
    _peerAvailable = available;
    for (final side in DemoSide.values) {
      _links[side]!.deliver = available
          ? (envelope) => _engines[side.other]!.applyRemote(envelope.delta)
          : null;
    }
  }

  Future<DemoSnapshot> editTitle(DemoSide side, String input) async {
    final title = input.trim();
    if (title.isEmpty) throw ArgumentError('Digite um título');
    await _engines[side]!.setDelta(sharedTitleAddress, title);
    _confirmations[side] = null;
    return snapshot();
  }

  Future<DemoSnapshot> incrementItems(DemoSide side) async {
    await _engines[side]!.incrementGCounter(sharedItemsAddress);
    _confirmations[side] = null;
    return snapshot();
  }

  /// The caller requests every attempt. An offline failure leaves outbox intact.
  Future<DemoSnapshot> pushPending() async {
    for (final side in DemoSide.values) {
      try {
        final result = await _engines[side]!.push(force: true);
        _errors[side] = null;
        _confirmations[side] = result.sent.isEmpty
            ? 'Nenhum delta para enviar'
            : result.fullyAcknowledged
            ? '${result.acknowledgedIds.length} delta(s) confirmado(s)'
            : 'Envio sem confirmação completa';
      } catch (error) {
        _errors[side] = '$error';
        _confirmations[side] = null;
      }
    }
    return snapshot();
  }

  Future<DemoSnapshot> snapshot() async {
    Future<DemoReplicaView> view(DemoSide side) async {
      final engine = _engines[side]!;
      final replica = engine.replica;
      final winner = replica.state.winnerAt(sharedTitleAddress);
      final pending = (await engine.pendingDelta()).changes.length;
      return DemoReplicaView(
        side: side,
        title: winner?.value as String?,
        items: replica.gCounterValue(sharedItemsAddress),
        pending: pending,
        winner: winner == null
            ? null
            : '${winner.replicaId} · ${winner.timestamp.physicalMilliseconds}:${winner.timestamp.logical} · ${winner.id}',
        error: _errors[side],
        confirmation: _confirmations[side],
      );
    }

    final views = await Future.wait(DemoSide.values.map(view));
    return DemoSnapshot(
      peerAvailable: _peerAvailable,
      a: views[0],
      b: views[1],
    );
  }

  /// Deletes only this demonstration's two SQLite files after closing them.
  Future<void> clearDemoData() async {
    await close();
    for (final path in _paths.values) {
      await _factory.deleteDatabase(path);
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await Future.wait(_engines.values.map((engine) => engine.dispose()));
    } finally {
      try {
        await Future.wait(_storages.values.map((storage) => storage.close()));
      } finally {
        await Future.wait(_links.values.map((link) => link.close()));
      }
    }
  }
}
