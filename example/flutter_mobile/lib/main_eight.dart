import 'dart:async';
import 'dart:convert';

import 'package:deltasync/deltasync.dart';
import 'package:deltasync_storage_sqflite/deltasync_storage_sqflite.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'support/eight_scenario.dart';
import 'support/http_peer_link.dart';

/// Separate technical entry point; existing demo and its banks are preserved.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const id = String.fromEnvironment('REPLICA_ID', defaultValue: 'alpha');
  if (id != 'alpha' && id != 'beta') throw ArgumentError('Use alpha or beta');
  final link = HttpPeerLink(
    peerReplicaId: id == 'alpha' ? 'beta' : 'alpha',
    peerUri: Uri.parse('http://127.0.0.1:8093'),
  );
  final storage = SqfliteReplicaStorage(
    databaseFactory: databaseFactory,
    databasePath: '${await getDatabasesPath()}/eight-$id.sqlite',
  );
  final engine = SyncEngine.withStorage(
    replica: Replica(id),
    storage: storage,
    transport: link,
  );
  final scenario = EightScenario(engine);
  try {
    await engine.start();
    await link.listen(engine, report: scenario.report);
    runApp(MaterialApp(home: EightPage(scenario: scenario)));
  } catch (error) {
    await link.close();
    await engine.dispose();
    await storage.close();
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('$error'))),
      ),
    );
  }
}

class EightPage extends StatefulWidget {
  const EightPage({super.key, required this.scenario});
  final EightScenario scenario;

  @override
  State<EightPage> createState() => _EightPageState();
}

class _EightPageState extends State<EightPage> {
  String _status = 'Restaurado; consulte os bancos/estado antes de agir';
  String _values = '';
  int _pending = 0;
  bool _busy = false;
  StreamSubscription<SyncCommitEvent>? _commits;

  @override
  void initState() {
    super.initState();
    _commits = widget.scenario.engine.commits.listen(
      (_) => unawaited(_refresh()),
    );
    unawaited(_refresh());
  }

  Future<void> _refresh({bool log = false}) async {
    try {
      final report = await widget.scenario.report();
      if (log) debugPrint('VAL16 $_status ${jsonEncode(report)}');
      if (mounted) {
        setState(() {
          _pending = ((report['pending'] as Map)['changes'] as List).length;
          _values = const JsonEncoder.withIndent('  ')
              .convert(report['values']);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _status = 'Consulta falhou: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_commits?.cancel());
    super.dispose();
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _status = '$label concluído';
    } catch (error) {
      _status = '$label falhou: $error';
    } finally {
      await _refresh(log: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Oito CRDTs ${widget.scenario.engine.replica.id}'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final command in <(String, Future<void> Function())>[
          ('Criar base', widget.scenario.seed),
          ('Editar offline', widget.scenario.branch),
          ('Editar após falha', widget.scenario.editAfterFailure),
          (
            'Enviar',
            () async {
              await widget.scenario.engine.push(force: true);
            },
          ),
          ('Resolver MV', widget.scenario.resolve),
        ])
          FilledButton(
            onPressed: _busy ? null : () => _run(command.$1, command.$2),
            child: Text(command.$1),
          ),
        Text(_status),
        Text('Pendentes: $_pending'),
        SelectableText(_values),
      ],
    ),
  );
}
