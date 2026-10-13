import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'demo_session.dart';

class MobileConsumerApp extends StatelessWidget {
  /// Uses platform SQLite by default; overrides support host tests.
  const MobileConsumerApp({
    super.key,
    this.databaseFactoryOverride,
    this.databaseDirectory,
  });

  final DatabaseFactory? databaseFactoryOverride;
  final Future<String> Function()? databaseDirectory;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DeltaSync mobile',
    home: _DemoPage(
      openSession: () async => DemoSession.open(
        factory: databaseFactoryOverride ?? databaseFactory,
        directory: await (databaseDirectory ?? getDatabasesPath)(),
      ),
    ),
  );
}

class _DemoPage extends StatefulWidget {
  const _DemoPage({required this.openSession});

  final Future<DemoSession> Function() openSession;

  @override
  State<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<_DemoPage> {
  final _titles = {
    for (final side in DemoSide.values) side: TextEditingController(),
  };
  DemoSession? _session;
  DemoSnapshot? _snapshot;
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
    DemoSession? opened;
    try {
      opened = await widget.openSession();
      final restored = await opened.snapshot();
      debugPrint('VAL08 restored ${_summary(restored)}');
      if (!mounted) {
        final closing = opened;
        opened = null;
        await closing.close();
        return;
      }
      setState(() {
        _session = opened;
        _snapshot = restored;
        _status = 'Estado restaurado';
        _busy = false;
      });
      opened = null;
    } catch (error, stackTrace) {
      if (opened != null) {
        try {
          await opened.close();
        } catch (closeError, closeStackTrace) {
          debugPrint('VAL08 CLOSE ERROR $closeError\n$closeStackTrace');
        }
      }
      _fail(error, stackTrace, releaseBusy: true);
    }
  }

  Future<void> _run(
    Future<DemoSnapshot> Function(DemoSession) action,
    String Function(DemoSnapshot) status,
  ) async {
    final session = _session;
    if (_busy || session == null) return;
    setState(() => _busy = true);
    try {
      final snapshot = await action(session);
      final message = status(snapshot);
      debugPrint('VAL08 $message ${_summary(snapshot)}');
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _status = message;
        });
      }
    } catch (error, stackTrace) {
      _fail(error, stackTrace);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fail(Object error, StackTrace stackTrace, {bool releaseBusy = false}) {
    debugPrint('VAL08 ERROR $error\n$stackTrace');
    if (mounted) {
      setState(() {
        _status = 'Erro: $error';
        if (releaseBusy) _busy = false;
      });
    }
  }

  Future<void> _clearDemo() async {
    final session = _session;
    if (_busy || session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar dados da demo?'),
        content: const Text(
          'Apaga somente os dois bancos SQLite deste exemplo. '
          'Edições e pendências locais serão perdidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await session.clearDemoData();
      if (!mounted) return;
      setState(() {
        _session = null;
        _snapshot = null;
        _busy = false;
        _status = 'Dados da demo apagados';
      });
      for (final controller in _titles.values) {
        controller.clear();
      }
      await _open();
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _session = null;
          _snapshot = null;
        });
      }
      _fail(error, stackTrace, releaseBusy: true);
    }
  }

  @override
  void dispose() {
    final session = _session;
    if (session != null) unawaited(session.close());
    for (final controller in _titles.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('DeltaSync mobile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edite o mesmo título nas duas réplicas. Offline, ambas guardam '
                'as mudanças. Após o envio, LWW escolhe por HLC, replicaId e ID.',
              ),
              const SizedBox(height: 12),
              SelectableText(_status, key: const Key('demo-status')),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('peer-available'),
                title: const Text('Peer disponível'),
                subtitle: const Text('Enlace sintético entre A e B neste app'),
                value: snapshot?.peerAvailable ?? false,
                onChanged: _busy || _session == null
                    ? null
                    : (available) => _run((session) async {
                        session.setPeerAvailable(available);
                        return session.snapshot();
                      }, (_) => available ? 'Peer disponível' : 'Peer offline'),
              ),
              FilledButton(
                key: const Key('push-pending'),
                onPressed: _busy || _session == null
                    ? null
                    : () => _run((session) => session.pushPending(), (next) {
                        if (next.a.error != null || next.b.error != null) {
                          return 'Falha de envio; commits locais preservados';
                        }
                        if (next.a.pending > 0 || next.b.pending > 0) {
                          return 'Envio sem confirmação completa';
                        }
                        return 'Envio concluído';
                      }),
                child: const Text('Enviar pendências'),
              ),
              if (snapshot != null) ...[
                _replicaCard(snapshot.a),
                _replicaCard(snapshot.b),
                OutlinedButton(
                  key: const Key('clear-demo'),
                  onPressed: _busy ? null : _clearDemo,
                  child: const Text('Limpar dados da demo'),
                ),
              ],
              if (_session == null)
                FilledButton(
                  key: const Key('open-retry'),
                  onPressed: _busy ? null : () => unawaited(_open()),
                  child: const Text('Tentar novamente'),
                ),
              const SizedBox(height: 12),
              const Text(
                'Para provar restauração, force o fechamento do processo e abra '
                'novamente. Reconexão e envio são ações separadas.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _replicaCard(DemoReplicaView view) {
    final side = view.side;
    return Card(
      key: Key('replica-${side.label}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Réplica ${side.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Título: ${view.title ?? '—'}',
              key: Key('title-${side.label}'),
            ),
            Text('Itens: ${view.items}', key: Key('items-${side.label}')),
            Text(
              'Pendentes: ${view.pending}',
              key: Key('pending-${side.label}'),
            ),
            Text('Vencedor LWW: ${view.winner ?? '—'}'),
            Text(
              'Erro: ${view.error ?? 'nenhum'}',
              key: Key('error-${side.label}'),
            ),
            Text(
              'Confirmação: ${view.confirmation ?? (view.pending > 0 ? 'aguardando ACK' : 'sem envio nesta sessão')}',
              key: Key('confirmation-${side.label}'),
            ),
            TextField(
              key: Key('input-${side.label}'),
              controller: _titles[side],
              decoration: const InputDecoration(labelText: 'Novo título'),
            ),
            FilledButton(
              key: Key('save-${side.label}'),
              onPressed: _busy || _session == null
                  ? null
                  : () => _run((session) async {
                      final next = await session.editTitle(
                        side,
                        _titles[side]!.text,
                      );
                      _titles[side]!.clear();
                      return next;
                    }, (_) => 'Commit local ${side.label} concluído'),
              child: Text('Salvar título ${side.label}'),
            ),
            OutlinedButton(
              key: Key('increment-${side.label}'),
              onPressed: _busy || _session == null
                  ? null
                  : () => _run(
                      (session) => session.incrementItems(side),
                      (_) => 'Commit local ${side.label} concluído',
                    ),
              child: Text('+1 item ${side.label}'),
            ),
          ],
        ),
      ),
    );
  }
}

String _summary(DemoSnapshot snapshot) =>
    'A=${snapshot.a.title ?? '-'} itens=${snapshot.a.items} pendentes=${snapshot.a.pending}; '
    'B=${snapshot.b.title ?? '-'} itens=${snapshot.b.items} pendentes=${snapshot.b.pending}';
