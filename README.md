# DeltaSync

Biblioteca Dart offline-first com oito CRDTs, deltas e sincronização para um peer
fixo por engine. Comece por commit local durável; rede pode falhar sem impedir edição.

## Uso

Para Dart desktop, acrescente `deltasync`, `deltasync_storage_sqflite` e
`sqflite_common_ffi` às dependências. Os sete pacotes estão preparados como
1.0.1; a consolidação inclui **quebras deliberadas de API**, apesar do
número patch. Leia o [guia de migração](https://github.com/ymsantos1/deltasync/blob/main/docs/migracao-1.0.1.md)
antes de atualizar. Metadados preparados não anunciam publicação. O envio manual
pelo autor exige aprovação dos artefatos no gate VAL-17.

O app fornece caminho persistente, identidade única/estável da instalação e
transporte vinculado ao peer. Não copie a identidade entre dispositivos.

```dart
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
```

O chamador fecha seu transporte concreto depois da drenagem da engine. Para
Flutter, use a factory do plugin e o diretório de bancos da plataforma. Veja o
[guia de integração](https://github.com/ymsantos1/deltasync/blob/main/docs/guia-integracao.md)
e o [exemplo SQLite executável](https://github.com/ymsantos1/deltasync/blob/main/example/commit_status_example.dart).

Commit concluído significa salvo localmente. `pendingSummary` conta entradas
pending/sent; sent ainda aguarda ACK. Somente ACK `appliedAndPersisted` do peer
configurado remove seus IDs da outbox. Não comprova entrega a outros participantes.
Falha posterior de consulta, decoder ou rede não desfaz um commit anterior.

`query` distingue ausência, valor presente inclusive null e tombstone LWW;
`valueAt` retorna null nos três casos. Modele esses estados na aplicação.
LWW escolhe o valor inteiro vencedor, sem merge de campos de JSON ou texto.
Use lote local, decoder e eventos seletivos conforme o
[guia](https://github.com/ymsantos1/deltasync/blob/main/docs/guia-integracao.md#3-editar-e-consultar).

## Pacotes

| Pacote | Responsabilidade |
|---|---|
| deltasync | Facade de core, storage, sync e transport |
| deltasync_core | Oito CRDTs, identidade, clocks, estado, deltas e joins |
| deltasync_storage | Contrato Dart puro e MemoryStorage **volátil** |
| deltasync_storage_sqflite | Adaptador SQLite persistente de referência |
| deltasync_storage_testing | Suíte compartilhada para adaptadores de storage |
| deltasync_sync | Candidata, commit/adoção, outbox, restauração e ACK |
| deltasync_transport | Contratos de transporte e codecs de envelope/ACK |

Core, sync e contrato de storage não dependem de Flutter, SQL ou protocolo.
Modelo, identidade da instalação, UI, autenticação/TLS e agendamento de push
pertencem ao consumidor. Não há worker de rede automático.

## Exemplos

Clone o [repositório](https://github.com/ymsantos1/deltasync) para exemplos completos.
O pacote publicado inclui apenas `example/deltasync_example.dart`.

- [SQLite offline/reconexão](https://github.com/ymsantos1/deltasync/blob/main/example/offline_reconciliation.dart): três processos, outbox e ACK durável.
- [Commit e falha posterior de status/modelo](https://github.com/ymsantos1/deltasync/blob/main/example/commit_status_example.dart): SQLite e tratamento separado.
- [Lote local atômico](https://github.com/ymsantos1/deltasync/blob/main/example/local_batch_example.dart).
- [Consulta explícita](https://github.com/ymsantos1/deltasync/blob/main/example/field_query_example.dart), [decoder](https://github.com/ymsantos1/deltasync/blob/main/example/field_decoder_example.dart) e [eventos seletivos](https://github.com/ymsantos1/deltasync/blob/main/example/selective_observation_example.dart).
- [Variante em memória](https://github.com/ymsantos1/deltasync/blob/main/example/deltasync_example.dart): **volátil**, não prova reinício de processo.
- [Flutter Android](https://github.com/ymsantos1/deltasync/blob/main/example/flutter_mobile/README.md): factory sqflite e ownership de recursos.

O [fork do Compass](https://github.com/ymsantos1/samples-for-tcc) ilustra um app
existente; suas regras de notas não pertencem ao core. Não há estudo de usabilidade.

### Compatibilidade de API e formatos

As substituições de APIs, adaptações de storage, switches, snapshots/deltas
versionados e rollback estão no [guia de migração](https://github.com/ymsantos1/deltasync/blob/main/docs/migracao-1.0.1.md).
API de fonte, formato persistido e versão publicada são contratos distintos.

### Onde alterar cada tipo

O [mapa técnico dos oito CRDTs](https://github.com/ymsantos1/deltasync/blob/main/docs/referencia-tecnica.md#onde-alterar-cada-tipo)
localiza estado, mutação, delta, join, codecs, commit e restauração.
Novo tipo integrado exige core/codec/snapshot/testes; não existe registro genérico
de plugins ou ObjectCrdt nesta release.

### Percurso de integração e manutenção

Siga o [guia durável](https://github.com/ymsantos1/deltasync/blob/main/docs/guia-integracao.md)
para consumo e a [referência técnica](https://github.com/ymsantos1/deltasync/blob/main/docs/referencia-tecnica.md)
para detalhes de tipos e manutenção. Extensões usam os contratos públicos;
não sobrescreva implementação interna nem importe `src` no app.

### Storage

Use SQLite ou um adaptador durável que passe a suíte de contrato e recuperação.
MemoryStorage é volátil. Veja [contrato e atomicidade](https://github.com/ymsantos1/deltasync/blob/main/docs/referencia-tecnica.md#storage).

### Confirmação e retry

Commit, tentativa de envio e ACK são estados distintos. O app agenda `push`;
backoff só filtra elegibilidade na próxima chamada. Veja
[ACK, retry e lifecycle](https://github.com/ymsantos1/deltasync/blob/main/docs/guia-integracao.md#5-sincronizar-e-confirmar).

### Escopo da persistência

Cada dispositivo persiste sua réplica e outbox, com conhecimento causal remoto.
ACK não autoriza GC de tombstones. [Detalhes](https://github.com/ymsantos1/deltasync/blob/main/docs/referencia-tecnica.md#escopo-da-persistência).

### Demonstração offline com SQLite

No repositório, rode `dart run example/offline_reconciliation.dart reset`,
`offline` e `reconnect` em processos separados, usando o mesmo diretório.
[Instruções e limites de plataforma](https://github.com/ymsantos1/deltasync/blob/main/docs/referencia-tecnica.md#demonstração-offline-com-sqlite).

### Medição de tamanho

[Cargas, resultados e limites históricos](https://github.com/ymsantos1/deltasync/blob/main/docs/medicoes.md#medição-de-tamanho).

### Custo de contexto e outbox

[Baseline e compactação MV](https://github.com/ymsantos1/deltasync/blob/main/docs/medicoes.md#custo-de-contexto-e-outbox).

### Custos dos percursos locais

[Validação JSON/MV e consultas pontuais](https://github.com/ymsantos1/deltasync/blob/main/docs/medicoes.md#custos-dos-percursos-locais).
São medições locais, sem promessa geral de desempenho.

## Validação

Mínimo declarado: Dart `^3.13.0`; referência executada: 3.13.5.
Na raiz, `python3 -B scripts/ci.py dart` verifica todos os pacotes e exemplos;
`python3 -B scripts/ci.py flutter` verifica o app separadamente. Confira a
[política de CI/advisories](https://github.com/ymsantos1/deltasync/blob/main/docs/ci.md)
e os [testes gerados/recuperação](https://github.com/ymsantos1/deltasync/blob/main/docs/referencia-tecnica.md#validação).
Testes finitos e lint não provam convergência universal ou ausência de vulnerabilidades.

## Releases

Os sete pacotes são preparados separadamente por `python3 scripts/prepare_release.py`.
O `.pubignore` raiz é herdado; não publique diretamente de `packages/`.
Siga o [guia de publicação](https://github.com/ymsantos1/deltasync/blob/main/docs/publicacao.md).
Publicação real permanece com o autor.

## Planejamento

No repositório: [contexto](https://github.com/ymsantos1/deltasync/blob/main/proposta.md),
[plano](https://github.com/ymsantos1/deltasync/blob/main/plan/README.md),
[rastreabilidade](https://github.com/ymsantos1/deltasync/blob/main/plan/TRACEABILITY.md)
e [instruções](https://github.com/ymsantos1/deltasync/blob/main/AGENTS.md).
Peça `$plan-executor Execute a próxima tarefa pronta do plano` para o ciclo
de leitura, implementação, revisão, validação e manutenção.
