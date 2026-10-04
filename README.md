# DeltaSync

Biblioteca Dart modular para aplicações offline-first com CRDTs e sincronização incremental por deltas.

## Pacotes

- `deltasync_core`: LWW, G-Counter, PN-Counter, estado de réplicas e deltas.
- `deltasync_sync`: coordenação de alterações locais, pendências e deltas remotos.
- `deltasync_storage`: contrato de persistência, sem dependência de banco específico.
- `deltasync_transport`: contrato de transporte, sem dependência de HTTP ou WebSocket.
- `deltasync`: facade que exporta APIs dos subpackages.

## Uso

```dart
import 'package:deltasync/deltasync.dart';

final replica = Replica('device-a');
final delta = replica.setDelta('message', 'edited offline');
final remote = Replica('device-b')..apply(Delta([delta]));
print(remote.state.values);
final apples = replica.incrementGCounter('cart/apples', 2);
final balance = replica.decrementPnCounter('account/balance', 1);
remote.apply(Delta([apples, balance]));
```

Cada adaptador de storage ou transporte pertence à aplicação consumidora. SQLite, HTTP e WebSocket não são dependências do núcleo.

O fluxo integrado de `Replica`/`SyncEngine` suporta LWW, G-Counter e PN-Counter;
demais tipos previstos e persistência SQLite ainda não foram implementados.
`setDelta/removeDelta` produzem `LwwDelta` ordenado por HLC. `Replica.set/remove`,
`SyncEngine.set/remove` e `Delta.crdt/crdtChanges` são wrappers depreciados que encaminham ao lote nativo;
podem ser removidos na próxima versão principal. `Operation`, `Crdt`,
`CrdtOperation` e `OperationCrdt` não formam mais caminho operacional. `Operation`
fica como DTO depreciado para migração versionada.

G-Counter e PN-Counter agora entram em `Replica`/`SyncEngine` por métodos de
mutação com `crdtId` estável, como `incrementGCounter('cart/apples')` e
`incrementPnCounter('account/balance')`. Endereço identifica campo/modelo e deve
ser igual entre réplicas e após restauração. Construtores diretos `GCounter` e
`PnCounter` exigem novo argumento nomeado `crdtId`; essa quebra evita colisão
silenciosa entre instâncias. Deltas v2 carregam endereço e dot namespaced; codec
continua lendo formato v1 e atribui endereço legado por tipo/réplica. Dados v1
com IDs conflitantes não podem ser separados automaticamente e são rejeitados.
Endereços iniciados por `legacy/` são reservados. G-Counter e PN-Counter carregam
componentes cumulativos, então lacunas de dot não impedem merge; CRDTs futuros
que dependam de eventos individuais precisam de contexto causal por endereço com
lacunas explícitas ou entrega causal garantida.

### Compatibilidade de API e formatos

Esta consolidação altera APIs públicas. `Delta` agora recebe somente
`Iterable<DeltaChange>`; `Delta.changes` contém todas as mudanças nativas. Código
que lia `crdtChanges` pode usar o alias depreciado ou migrar para `changes`.
`OutboxEntry` exige `delta` não vazio; `operation:` foi removido. `Replica.set`
e `Replica.remove` continuam como aliases depreciados, mas retornam `LwwDelta`;
código tipado como `Operation` deve migrar para `LwwDelta<Object?>`. `Crdt`,
`CrdtOperation` e `OperationCrdt` foram removidos. Consumidores externos não foram
inventariados; devem compilar contra os contratos públicos acima e adaptar
subclasses próprias de `DeltaChange` para metadados `kind`, `crdtId` e `replicaId`.

Inventário público após consolidação: `deltasync_core` exporta contratos e tipos
de mudança (`DeltaChange`, `CrdtKind`, `Delta`, `DeltaCodec`, `DeltaCrdt`),
`Replica`/`ReplicaState`, LWW/counters, HLC, identidade e clocks; `Operation` e
`migrateLegacyOperation` existem só para converter dados antigos. `deltasync_storage`
exporta `ReplicaStorage`, `ReplicaSnapshot`, `OutboxEntry`, `OutboxStatus`,
`MemoryStorage`, `PendingDeltaStore` e `MemoryPendingDeltaStore`. `deltasync_sync`
exporta `SyncEngine` e `SyncRetryPolicy`; `deltasync_transport` exporta
`DeltaTransport`, `AcknowledgingDeltaTransport` e `DeltaEnvelope`. A facade
`deltasync` reexporta esses quatro pacotes.

`DeltaCodec` grava versão 3 (`delta.changes`). Lê versões 1 e 2 antigas, convertendo
operações LWW em `LwwDelta`: soma dos componentes de `VectorClock` vira timestamp
físico sintético; `replicaId` e ID preservam desempate antigo. Vetores cuja soma
excede o intervalo suportado são rejeitados. Snapshots internos versão 1 continuam
legíveis, inclusive `legacyWinner`; gravação atual usa versão 2. Conversão fica no
codec/snapshot restore, não no caminho normal de `Replica.apply`.

### Onde alterar cada tipo

- **LWW:** `Replica.setDelta/removeDelta` criam mudança e HLC em
  `packages/deltasync_core/lib/src/replica.dart`; `LwwRegister` mantém vencedor e
  tombstone; `ReplicaState` roteia pelo endereço. Join escolhe maior HLC, depois
  `replicaId` e ID. Snapshot passa por `Replica.toSnapshotJson/fromSnapshotJson`.
  Regressões ficam em `crdt_interfaces_test.dart` nos testes de tombstone, ordem,
  migração e snapshot.
- **G-Counter:** mutação, componente cumulativo e join por máximo vivem em
  `g_counter.dart`; `Replica` roteia pelo `crdtId` e snapshot restaura componentes
  e sequência. Testes cobrem máximos, lote misto, codec e sequência restaurada.
- **PN-Counter:** positivos, negativos, validação completa e join por máximo vivem
  em `pn_counter.dart`; delta público transporta ambos os componentes. Testes cobrem
  convergência, decremento, delta inválido sem efeito parcial e sequência.
- **Contrato/wire:** `delta_change.dart` define metadados comuns e labels estáveis;
  `delta.dart` agrupa/mescla mudanças e `delta_codec.dart` versiona serialização.
  `delta_envelope.dart` acrescenta envelope de transporte. Testes pertinentes ficam
  nos pacotes core e transport.

### Storage

`ReplicaStorage` é o contrato oficial para persistência. A aplicação deve fornecer
um adaptador persistente quando precisar recuperar estado após reinício, como um
adaptador SQLite, Hive, Isar ou arquivos.

`MemoryStorage` é apenas uma implementação volátil de referência. Serve para
testes, exemplos e protótipos; todos os dados são perdidos quando o processo
termina e não deve ser usado como storage de produção.

Adaptadores de `ReplicaStorage` devem implementar `commit` para gravar snapshot
e entradas novas da outbox atomicamente, e `commitRemote` para substituir snapshot
após merge remoto. Falha deve preservar estado anterior. Esses métodos novos
exigem atualização de implementações externas. Snapshots atuais usam formato 1,
com estado materializado em `metadata['replicaState']`; estado LWW inclui
tombstones e contadores guardam componentes/sequências. O reader ainda aceita
snapshots antigos com `metadata['delta']` e os regrava no formato atual ao iniciar.

### Confirmação e retry

`DeltaTransport.send` concluir significa apenas que envio terminou. Só
`AcknowledgingDeltaTransport.sendAndAwaitAck` confirma mudanças; transporte deve
retornar cada ID depois de aplicação e persistência durável no destino. ACK parcial
remove apenas IDs confirmados. Sem ACK, `ReplicaStorage` conserva mudanças para
retry. `SyncRetryPolicy.maxAttempts` limita retries automáticos; `push(force: true)`
ignora atraso e limite para retransmissão manual. `SyncEngine` aceita ACK somente
para IDs do lote enviado e da outbox da réplica local. O legado `PendingDeltaStore`
não armazena tentativas nem ACKs: mudanças enviadas ficam pendentes e cada `push`
pode reenviá-las sem limite; `force` não altera esse comportamento. ACK confirma
entrega, nunca autoriza coleta de tombstones. ACK separado por múltiplos peers
depende de identidade de destino e permanece fora do contrato atual.

### Escopo da persistência

Cada dispositivo persiste somente sua própria réplica. O estado completo das
outras réplicas não é armazenado localmente.

O adaptador persistente ainda não existe. O modelo lógico planejado prevê três
responsabilidades, cujas tabelas serão definidas na implementação:

- `replicas`: identidade, `VectorClock`, contador local e metadados;
- `state_entries` ou snapshots: estado dos CRDTs e tombstones;
- `outbox`: deltas locais ainda não confirmados conforme o contrato de entrega.

O `VectorClock` pode conter identificadores e contadores de outras réplicas.
Isso registra conhecimento causal, não o estado completo delas. Operações
remotas podem aparecer como operação vencedora ou ser resumidas pelo relógio,
sem exigir armazenamento da réplica remota inteira.

Uma tabela adicional de operações pode ser criada futuramente para auditoria,
replay, histórico ou deduplicação explícita. Confirmações por participante
também podem ser persistidas futuramente para orientar compactação segura de
operações e tombstones. Nenhuma dessas extensões armazena estados completos de
outras réplicas.

## Validação

Testes da raiz cobrem somente a facade. Validar também cada subpacote:

```shell
dart pub get
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_transport; do
  (cd "$package" && dart analyze && dart test) || exit 1
done
```

## Planejamento

Para executar tarefa com leitura, implementação, review, validação e atualização
do plano, pedir `$plan-executor Execute R-01` ou “execute a próxima tarefa do plano”.
Veja [guia de uso](plan/RUNBOOK.md).

- [Contexto atual e relação com o PDF acadêmico](proposta.md).
- [Plano: fases, tarefas, prioridades e gates](plan/README.md).
- [Correções da implementação existente](plan/01_PHASE1_CORRECOES.md).
- [Rastreabilidade e evidências](plan/TRACEABILITY.md).
- [Instruções e procedimentos de trabalho](AGENTS.md).
