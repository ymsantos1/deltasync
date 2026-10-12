import 'dart:async';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

const _replicaA = 'shopper-a';
const _replicaB = 'shopper-b';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MobileConsumerApp());
}

class MobileConsumerApp extends StatelessWidget {
  /// Uses the platform SQLite database by default; overrides support tests.
  const MobileConsumerApp({
    super.key,
    this.databaseFactoryOverride,
    this.databaseDirectory,
  });

  /// Optional SQLite factory for a host or integration test.
  final DatabaseFactory? databaseFactoryOverride;

  /// Optional database directory provider for a host or integration test.
  final Future<String> Function()? databaseDirectory;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DeltaSync mobile',
    home: _DemoPage(
      openSession: () async => _DemoSession.open(
        factory: databaseFactoryOverride ?? databaseFactory,
        directory: await (databaseDirectory ?? getDatabasesPath)(),
      ),
    ),
  );
}

class _DemoPage extends StatefulWidget {
  const _DemoPage({required this.openSession});

  final Future<_DemoSession> Function() openSession;

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  _DemoSession? _session;
  String _status = 'Abrindo SQLite...';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    if (_busy || _session != null) return;
    setState(() {
      _busy = true;
      _status = 'Abrindo SQLite...';
    });
    _DemoSession? opened;
    try {
      opened = await widget.openSession();
      final restored = await opened.describe();
      debugPrint('VAL07 restored $restored');
      if (!mounted) {
        final closing = opened;
        opened = null;
        await closing.close();
        return;
      }
      setState(() {
        _session = opened;
        _status = 'Restaurado: $restored';
        _busy = false;
      });
      opened = null;
    } catch (error, stackTrace) {
      if (opened != null) {
        try {
          await opened.close();
        } catch (closeError, closeStackTrace) {
          debugPrint('VAL07 CLOSE ERROR $closeError\n$closeStackTrace');
        }
      }
      _fail(error, stackTrace, releaseBusy: true);
    }
  }

  Future<void> _run(Future<String> Function(_DemoSession) action) async {
    final session = _session;
    if (_busy || session == null) return;
    setState(() => _busy = true);
    try {
      final result = await action(session);
      debugPrint('VAL07 $result');
      if (mounted) setState(() => _status = result);
    } catch (error, stackTrace) {
      _fail(error, stackTrace);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fail(Object error, StackTrace stackTrace, {bool releaseBusy = false}) {
    debugPrint('VAL07 ERROR $error\n$stackTrace');
    if (mounted) {
      setState(() {
        _status = 'Erro: $error';
        if (releaseBusy) _busy = false;
      });
    }
  }

  @override
  void dispose() {
    final session = _session;
    if (session != null) unawaited(session.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DeltaSync mobile')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Duas réplicas; LWW e G-Counter; peer fixo.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy || _session == null
                ? null
                : () => _run((s) => s.editOffline()),
            child: const Text('1. Editar offline'),
          ),
          FilledButton(
            onPressed: _busy || _session == null
                ? null
                : () => _run((s) => s.reconnect()),
            child: const Text('2. Reconectar'),
          ),
          if (_session == null)
            FilledButton(
              onPressed: _busy ? null : () => unawaited(_open()),
              child: const Text('Tentar novamente'),
            ),
          const SizedBox(height: 16),
          SelectableText(_status),
          const SizedBox(height: 16),
          const Text(
            'Após editar offline, force o fechamento do app e abra novamente. '
            'Confira a restauração antes de reconectar.',
          ),
        ],
      ),
    ),
  );
}

class _DemoSession {
  _DemoSession(
    this._a,
    this._b,
    this._storageA,
    this._storageB,
    this._linkA,
    this._linkB,
  );

  final SyncEngine _a;
  final SyncEngine _b;
  final SqfliteReplicaStorage _storageA;
  final SqfliteReplicaStorage _storageB;
  final _PeerLink _linkA;
  final _PeerLink _linkB;

  static Future<_DemoSession> open({
    required DatabaseFactory factory,
    required String directory,
  }) async {
    final storageA = SqfliteReplicaStorage(
      databaseFactory: factory,
      databasePath: '$directory/$_replicaA.sqlite',
    );
    final storageB = SqfliteReplicaStorage(
      databaseFactory: factory,
      databasePath: '$directory/$_replicaB.sqlite',
    );
    final linkA = _PeerLink(_replicaB);
    final linkB = _PeerLink(_replicaA);
    final session = _DemoSession(
      SyncEngine.withStorage(
        replica: Replica(_replicaA),
        storage: storageA,
        transport: linkA,
      ),
      SyncEngine.withStorage(
        replica: Replica(_replicaB),
        storage: storageB,
        transport: linkB,
      ),
      storageA,
      storageB,
      linkA,
      linkB,
    );
    try {
      await Future.wait([session._a.start(), session._b.start()]);
      return session;
    } catch (error, stackTrace) {
      try {
        await session.close();
      } catch (closeError, closeStackTrace) {
        debugPrint('VAL07 CLOSE ERROR $closeError\n$closeStackTrace');
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String> editOffline() async {
    if (_view(_a) != '-/-; itens=0' || _view(_b) != '-/-; itens=0') {
      throw StateError(
        'Percurso já iniciado; limpe os dados do app para repetir',
      );
    }
    if ((await _a.pendingDelta()).changes.isNotEmpty ||
        (await _b.pendingDelta()).changes.isNotEmpty) {
      throw StateError('Há pendências; reconecte antes de editar novamente');
    }
    await _a.setDelta('shopper/$_replicaA/name', 'Ana');
    await _a.incrementGCounter('shopping/items', 2);
    await _b.setDelta('shopper/$_replicaB/name', 'Beto');
    await _b.incrementGCounter('shopping/items', 3);

    var failures = 0;
    for (final (engine, peer) in [(_a, _replicaB), (_b, _replicaA)]) {
      try {
        await engine.push(force: true);
      } on StateError catch (error) {
        if (error.message != 'Peer $peer offline') rethrow;
        failures++;
      }
    }
    if (failures != 2) {
      throw StateError('Falha offline esperada em duas réplicas: $failures');
    }
    if ((await _a.pendingDelta()).changes.length != 2 ||
        (await _b.pendingDelta()).changes.length != 2) {
      throw StateError('Falha offline perdeu pendências');
    }
    return 'offline; falha de envio em 2 réplicas; ${await describe()}';
  }

  Future<String> reconnect() async {
    _linkA.deliver = (envelope) => _b.applyRemote(envelope.delta);
    _linkB.deliver = (envelope) => _a.applyRemote(envelope.delta);
    final results = await Future.wait([
      _a.push(force: true),
      _b.push(force: true),
    ]);
    if (results.any((result) => !result.fullyAcknowledged)) {
      throw StateError('Peer não confirmou todos os deltas');
    }
    final a = _view(_a);
    final b = _view(_b);
    if (a != b || a != 'Ana/Beto; itens=5') {
      throw StateError('Réplicas divergiram: A=$a; B=$b');
    }
    if ((await _a.pendingDelta()).changes.isNotEmpty ||
        (await _b.pendingDelta()).changes.isNotEmpty) {
      throw StateError('Outbox não foi confirmada');
    }
    return 'convergente; ${await describe()}';
  }

  Future<String> describe() async {
    final pendingA = (await _a.pendingDelta()).changes.length;
    final pendingB = (await _b.pendingDelta()).changes.length;
    return 'A=${_view(_a)} pendentes=$pendingA; '
        'B=${_view(_b)} pendentes=$pendingB';
  }

  String _view(SyncEngine engine) {
    final values = engine.replica.state.values;
    final a = values['shopper/$_replicaA/name'] ?? '-';
    final b = values['shopper/$_replicaB/name'] ?? '-';
    return '$a/$b; itens=${engine.replica.gCounterValue('shopping/items')}';
  }

  Future<void> close() async {
    try {
      await Future.wait([_a.dispose(), _b.dispose()]);
    } finally {
      try {
        await Future.wait([_storageA.close(), _storageB.close()]);
      } finally {
        await Future.wait([_linkA.close(), _linkB.close()]);
      }
    }
  }
}

class _PeerLink implements AcknowledgingDeltaTransport {
  _PeerLink(this.peerReplicaId);

  @override
  final String peerReplicaId;
  final _incoming = StreamController<DeltaEnvelope>.broadcast();
  Future<void> Function(DeltaEnvelope)? deliver;

  @override
  Stream<DeltaEnvelope> get incoming => _incoming.stream;

  @override
  Future<void> send(DeltaEnvelope envelope) async {
    final handler = deliver;
    if (handler == null) throw StateError('Peer $peerReplicaId offline');
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
