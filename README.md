# DeltaSync

Biblioteca Dart modular para aplicações offline-first com CRDTs e sincronização incremental por deltas.

## Pacotes

- `deltasync_core`: LWW-Register, MV-Register, G-Counter, PN-Counter, G-Set,
  2P-Set, OR-Set, OR-Map, estado de réplicas e deltas.
- `deltasync_sync`: coordenação de alterações locais, pendências e deltas remotos.
- `deltasync_storage`: contrato de persistência, sem dependência de banco específico.
- `deltasync_storage_testing`: suíte reutilizável de contrato para adapters de storage.
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
final tags = replica.addAllGSet('document/tags', ['draft', 'shared']);
final members = replica.addTwoPSet('document/members', 'device-a');
remote.apply(Delta([apples, balance, tags, members]));
print(remote.gSetValue('document/tags'));
final removal = replica.removeTwoPSet('document/members', 'device-a');
remote.apply(Delta([removal]));
print(remote.twoPSetValue('document/members'));

// MV-Register preserva escritas concorrentes até escrita observar ambas.
final localWrite = replica.writeMvRegister('document/title', 'local');
final concurrentWrite = remote.writeMvRegister('document/title', 'remote');
replica.apply(Delta([concurrentWrite]));
remote.apply(Delta([localWrite]));
print(replica.mvRegisterValue('document/title')); // {'local', 'remote'}
final resolved = replica.writeMvRegister('document/title', 'resolved');
remote.apply(Delta([resolved]));
print(remote.mvRegisterValue('document/title')); // {'resolved'}

final roleTag = replica.addOrSet('document/roles', 'reader');
remote.apply(Delta([roleTag]));
final roleRemoval = replica.removeOrSet('document/roles', 'reader');
remote.apply(Delta([roleRemoval]));
print(remote.orSetValue('document/roles')); // {}

final key = replica.addOrMapKey('document/profile', 'roles');
remote.apply(Delta([key]));
final role = replica.addOrMapValue('document/profile', 'roles', 'reader').single;
remote.apply(Delta([role]));
print(remote.orMapValue('document/profile')); // {'roles': {'reader'}}
```

Cada adaptador de storage ou transporte pertence à aplicação consumidora. SQLite, HTTP e WebSocket não são dependências do núcleo. Execute `dart run example/deltasync_example.dart` para um consumidor mínimo com duas engines conectadas; o link em memória só demonstra o contrato público e não é transporte de produção.

```mermaid
sequenceDiagram
  participant App as Aplicação
  participant A as SyncEngine A
  participant SA as Storage A
  participant T as Adaptador de transporte
  participant B as SyncEngine B
  participant SB as Storage B
  App->>A: mutação pública
  A->>SA: commit snapshot + outbox
  SA-->>A: commit local
  A-->>App: delta da mutação
  App->>A: push()
  A->>T: envelope
  T->>B: entregar delta
  B->>SB: commit remoto
  SB-->>B: commit concluído
  B-->>T: ACK aplicado e persistido
  T-->>A: ACK
  A->>SA: limpar IDs confirmados
```

O fluxo integrado de `Replica`/`SyncEngine` suporta LWW, G-Counter, PN-Counter,
G-Set, 2P-Set, MV-Register, OR-Set e OR-Map com valores G-Set. Testes de
recuperação SQLite via FFI cobrem estado e outbox dos oito tipos.
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
componentes cumulativos, então lacunas de dot não impedem merge. MV-Register e os
tipos observados usam dots explícitos: um contador máximo não prova que dots
anteriores chegaram.

G-Set usa `Replica.addGSet/addAllGSet` ou métodos correspondentes de
`SyncEngine`. Endereço estável identifica o campo; cada delta traz adições JSON
com dot namespaced, e o join une eventos enquanto a consulta deduplica valores
JSON estruturalmente iguais. Não há remoção. G-Set entrou no snapshot interno v4;
leitores atuais aceitam snapshots v1–v8, e o formato atual é v9. Consumidores
antigos não leem snapshot v9. O envelope externo `ReplicaSnapshot` continua v2.
`DeltaCodec` grava v4 e lê v1–v3; leitores antigos rejeitam labels desconhecidos `g-set`,
`2p-set`, `mv-register`, `or-set` e `or-map`.

2P-Set usa `Replica.addTwoPSet/addAllTwoPSet` e
`Replica.removeTwoPSet/removeAllTwoPSet`, com métodos equivalentes em `SyncEngine`.
Adições e tombstones de remoção são conjuntos monotônicos unidos no merge; valor
visível é adições menos remoções. Readição e delta antigo não ressuscitam valor
removido. Não há operação para desfazer tombstone.

MV-Register usa `Replica.writeMvRegister` e `SyncEngine.writeMvRegister`. Cada
delta guarda dot da escrita e contexto causal exato: prefixo contíguo por réplica
mais dots esparsos acima dele. Lacunas continuam explícitas; dot 3 sozinho não
prova que dots 1 e 2 chegaram. Join une contextos sem expandir prefixos. A API
`MvRegisterDelta.context` mantém leitura como `List<Dot>` e expande o prefixo ao
ser consultada. JSON v3 de delta e snapshot interno v8 continuam legíveis; novas
gravações usam DeltaCodec v4 e snapshot interno v9. Sem GC causal, conhecimento
continua preservado após ACK.

OR-Set usa `Replica.addOrSet/removeOrSet` e equivalentes de `SyncEngine`. Cada
adição recebe tag dot exclusivo; remoção carrega exatamente tags já observadas.
Join une adições e tombstones. Adição concorrente e readição recebem tags novas
e sobrevivem; replay de adição removida permanece oculto após restore. Snapshot
v7 introduziu tags/tombstones; leitores atuais aceitam snapshots v1–v7. Sem GC no escopo,
eventos de adição/remoção e tombstones continuam armazenados.

OR-Map usa `Replica.addOrMapKey/removeOrMapKey/addOrMapValue` e equivalentes em
`SyncEngine`. Esta composição concreta usa G-Set por chave: presença é add-wins
por tags observadas; remoção afeta só tags conhecidas; atualizações unem valores
sem substituir adições concorrentes. Recriação recebe nova tag e G-Set vazio;
deltas de valor da chave antiga ficam ocultos. Valores só crescem porque G-Set não
remove elementos; para outro tipo de valor, consumidor compõe seu contrato próprio.
Snapshot v8 preserva tags e valores.

### Compatibilidade de API e formatos

`LwwRegister<T>` e `LwwDelta<T>.fromJson` aceitam `decodeValue` para coleções
JSON tipadas. A cópia JSON interna usa `List<Object?>` e `Map<String, Object?>`;
por isso `T` como `List<int>` ou `Map<String, List<int>>` precisa de conversão
explícita na consulta e na restauração. Exemplo:

```dart
List<int> readScores(Object? json) => List<int>.from(json as List);

final register = LwwRegister<List<int>>(decodeValue: readScores);
register.applyDelta(LwwDelta<List<int>>(
  key: 'scores',
  id: 'device:1',
  replicaId: 'device',
  timestamp: const HlcTimestamp(1, 0),
  value: [1, 2],
  decodeValue: readScores,
));
final restored = LwwDelta<List<int>>.fromJson(
  register.winner!.toJson(),
  decodeValue: readScores,
);
```

Para mapas aninhados, a conversão deve reconstruir também as coleções internas e
preservar exatamente o conteúdo JSON.
`Replica` e `SyncEngine` continuam expondo LWW como `Object?`; seus valores e
snapshots são copiados. Chamadas anteriores com tipos escalares ou `Object?`
continuam válidas, exceto usos `const LwwDelta(...)`: o construtor agora copia
o valor e deixa de ser `const`; troque a declaração por `final` ou criação comum.
`LwwDelta.value` devolve cópia, inclusive de coleções aninhadas. Sem conversão,
uma coleção incompatível com `T` gera
`FormatException` em vez de falha de cast. O JSON, HLC e formato de snapshot não
mudam; consumidores de coleções tipadas adicionam a conversão nos pontos acima.

Esta consolidação altera APIs públicas. `Delta` agora recebe somente
`Iterable<DeltaChange>`; `Delta.changes` contém todas as mudanças nativas. Código
que lia `crdtChanges` pode usar o alias depreciado ou migrar para `changes`.
Adapters próprios de `ReplicaStorage` devem implementar consulta, `markSent` e
confirmação por peer. `OutboxEntry` exige exatamente uma mudança em `delta` e
registra destino;
lotes são montados no envio. Outbox v2 substitui formato v1. Migração v1 exige
informar explicitamente `legacyRecipientPeerId`; alvo desconhecido nunca é
atribuído silenciosamente. `operation:` foi removido. `Replica.set`
e `Replica.remove` continuam como aliases depreciados, mas retornam `LwwDelta`;
código tipado como `Operation` deve migrar para `LwwDelta<Object?>`. `Crdt`,
`CrdtOperation` e `OperationCrdt` foram removidos. Consumidores externos não foram
inventariados; devem compilar contra os contratos públicos acima e adaptar
subclasses próprias de `DeltaChange` para metadados `kind`, `crdtId` e `replicaId`.
`ReplicaSnapshot` atual recebe payload canônico; adaptadores leem objeto antigo
com `ReplicaSnapshot.fromJson` e convertem antes de escrever. Outboxes antigas com
várias mudanças por entrada devem ser divididas em uma entrada por mudança na
migração. `PendingDeltaStore` e `MemoryPendingDeltaStore` seguem depreciados como
ponte; API nova usa `SyncEngine.withStorage`.

Inventário público após consolidação: `deltasync_core` exporta contratos e tipos
de mudança (`DeltaChange`, `CrdtKind`, `Delta`, `DeltaCodec`, `DeltaCrdt`),
`Replica`/`ReplicaState`, LWW/counters, HLC, identidade e clocks; `Operation` e
`migrateLegacyOperation` existem só para converter dados antigos. `deltasync_storage`
exporta `ReplicaStorage`, `ReplicaSnapshot`, `OutboxEntry`, `OutboxStatus`,
`MemoryStorage`, `PendingDeltaStore` e `MemoryPendingDeltaStore`. Os dois últimos
permanecem depreciados como adaptador de migração; fluxo novo usa
`SyncEngine.withStorage` e `ReplicaStorage`. `deltasync_sync`
exporta `SyncEngine` e `SyncRetryPolicy`; `deltasync_transport` exporta
`DeltaTransport`, `AcknowledgingDeltaTransport`, `DeltaEnvelope`,
`DeltaAcknowledgement` e `DeltaAckStage`. A facade `deltasync` reexporta esses
quatro pacotes.

Para consultar um campo após `await engine.start()`, use
`engine.valueAt('endereco')`. A consulta síncrona lê somente o valor já
incorporado por commit; não copia toda a réplica nem aguarda rede. Antes de
restaurar e após dispose, lança StateError. Durante commit em andamento, devolve
o último valor adotado. `Replica.valueAt` oferece a mesma consulta no core.
Endereço ausente, LWW null e tombstone retornam null, como a consulta LWW
anterior; contadores vinculados retornam int, MV/sets retornam Set<Object?> e
OR-Map retorna Map<String, Set<Object?>>. Coleções aninhadas são isoladas e
somente leitura. Consultar não confirma envio; APIs anteriores continuam disponíveis.

`DeltaCodec` grava versão 4 com contexto MV compacto. Lê v3 com listas explícitas
e versões 1 e 2 antigas, convertendo operações LWW em `LwwDelta`: soma dos
componentes de `VectorClock` vira timestamp físico sintético; `replicaId` e ID
preservam desempate antigo. Vetores cuja soma excede o intervalo suportado são
rejeitados. Snapshots internos versões 1 a 8 continuam legíveis, inclusive
`legacyWinner` nos formatos antigos. A gravação atual usa versão 9, guarda
sequências por origem e compacta contextos MV. O envelope externo `ReplicaSnapshot`
continua v2 e o schema SQLite continua v1. Leitores antigos rejeitam v4/v9 sem
apagar dados; novas gravações preservam IDs e metadados de outbox. Conversão fica
no codec/snapshot restore, não no caminho normal de `Replica.apply`.

`DeltaTransport` fica vinculado a um `peerReplicaId` e envia/recebe
`DeltaEnvelope` v2, com remetente, destinatário e payload `DeltaCodec`. Remetente
pode diferir das origens CRDT em mudanças encaminhadas. A API não escolhe protocolo:
adapters serializam `toJson()` e validam `fromJson()`. `DeltaTransport.send`
concluído significa transmissão local; ACK `received` confirma só recebimento;
somente `appliedAndPersisted` do destinatário configurado remove IDs daquela
outbox. Outbox mantém cópia por peer; o consumidor deve chamar `push()` novamente
após reconexão para tentar enviar ao peer que voltou. Trocar adapter para outro
peer não transfere pendências nem amplia confirmação.
`DeltaAcknowledgement.toJson()/fromJson()` centralizam o ACK com
`peerReplicaId`, `stage` e `changeIds`, mantendo o formato já usado pelo
consumidor HTTP. Use `jsonEncode(ack.toJson())` no envio e
`DeltaAcknowledgement.fromJson(json)` após decodificar um objeto JSON.
O decoder rejeita peer/IDs vazios ou com espaços nas extremidades, tipos inválidos
e estágio desconhecido com `FormatException`; aceita lista vazia, deduplica IDs
e ignora campos adicionais. O codec não confirma entrega: vincular peer/lote e
exigir commit remoto durável continuam responsabilidades do fluxo de sync.
Construtores e formatos persistidos anteriores permanecem compatíveis.
Decoder aceita envelope v1 só com `legacyRecipientReplicaId` explícito; adapters
antigos também precisam migrar a assinatura pública.

`Replica.export()` emite bootstrap compacto: vencedor LWW por endereço e
componente cumulativo mais recente por origem para counters. `Replica.mergeSnapshotJson()`
faz bootstrap por snapshot sem trocar identidade; `SyncEngine.applyRemoteSnapshot()`
grava esse merge com `commitRemote`, sem criar pendência local. `export()` não é
log completo, outbox nem histórico de ACK. Use `toSnapshotJson/exportSnapshot()` e
`fromSnapshotJson()` para persistir/restaurar estado completo, inclusive tombstones,
clocks e sequências. ID conflitante é rejeitado enquanto corresponder ao vencedor
retido ou ao último estado conhecido do componente; não há deduplicação ilimitada
de todo ID histórico após restauração. Snapshots internos v1/v2 sem sequências de
origens remotas podem ser mesclados por `mergeSnapshotJson`; `export()` não inventa
dots ausentes. Use transferência direta do snapshot para bootstrap desse estado.

### Onde alterar cada tipo

- **LWW:** `Replica.setDelta/removeDelta` criam mudança e HLC em
  `packages/deltasync_core/lib/src/replica.dart`; `LwwRegister` mantém vencedor e
  tombstone; `ReplicaState` roteia pelo endereço. Join escolhe maior HLC, depois
  `replicaId` e ID. Snapshot passa por `Replica.toSnapshotJson/fromSnapshotJson`.
  Regressões ficam em `crdt_interfaces_test.dart` para tombstone, ordem, migração e
  snapshot, e em `lww_typed_json_test.dart` para coleções tipadas e isolamento.
- **G-Counter:** mutação, componente cumulativo e join por máximo vivem em
  `g_counter.dart`; `Replica` roteia pelo `crdtId` e snapshot restaura componentes
  e sequência. Testes cobrem máximos, lote misto, codec e sequência restaurada.
- **PN-Counter:** positivos, negativos, validação completa e join por máximo vivem
  em `pn_counter.dart`; delta público transporta ambos os componentes. Testes cobrem
  convergência, decremento, delta inválido sem efeito parcial e sequência.
- **G-Set:** `g_set.dart` valida e copia elementos JSON, gera adições incrementais
  e une deltas por ID. `Replica` faz roteamento, isolamento, export e snapshot;
  `SyncEngine` grava mudanças na outbox. Testes cobrem join, ordem, duplicação,
  codec e duas engines.
- **2P-Set:** `two_p_set.dart` mantém adições e tombstones monotônicos; valor é a
  diferença dos conjuntos. `Replica` roteia e versiona snapshot; `SyncEngine`
  comita operações na outbox. A semântica não permite readição após remoção.
- **MV-Register:** `mv_register.dart` mantém versões; `causal/dot_context.dart`
  mantém contexto compacto por prefixo e lacunas esparsas. Pertencimento, união,
  codificação compacta e leitura do formato explícito anterior pertencem a esse
  componente interno, sem acesso à Replica ou ao storage.
  Join elimina versões observadas sem inferir entrega pelo máximo nem descartar
  contexto causal.
  `Replica` roteia, exporta e restaura; `SyncEngine` persiste cada escrita na
  outbox. Testes cobrem concorrência, entrega atrasada, join, JSON e duas engines.
- **OR-Set:** `or_set.dart` mantém adições por tag dot e remoções por conjunto de
  tags observadas. Join une ambos, sem usar contador máximo como prova de entrega.
  `Replica` roteia, exporta e restaura; `SyncEngine` comita adição/remoção na
  outbox. Testes cobrem adição concorrente, readição, replay antigo e duas engines.
- **OR-Map:** `or_map.dart` mantém tags de chave e compõe G-Set independente por
  encarnação. Remoção não apaga valor concorrente de outra tag; recriação não
  reutiliza valor antigo. `Replica` e `SyncEngine` roteiam/commitam mudanças; testes
  mostram API e pontos de manutenção sem framework genérico de objetos.
- **Contrato/wire:** `delta_change.dart` define metadados comuns e labels estáveis;
  `delta.dart` agrupa/mescla mudanças e `delta_codec.dart` versiona serialização.
  `delta_envelope.dart` acrescenta envelope de transporte. Testes pertinentes ficam
  nos pacotes core e transport.

`Replica` coordena identidade, clocks e mutações públicas. Os componentes abaixo
são libraries internas com dependências explícitas; não exigem acesso aos campos
privados do coordenador. Os imports públicos e formatos persistidos permanecem
compatíveis. Cada CRDT continua responsável pela sua própria regra de join.

| Responsabilidade | Dono e ponto de manutenção |
|---|---|
| Instâncias por endereço; cópia, export, restauração e merge comuns | [replica/contents.dart](packages/deltasync_core/lib/src/replica/contents.dart). `ReplicaContents` guarda LWW em `ReplicaState` e as sete coleções tipadas. `CrdtTable` implementa o percurso comum; callbacks explícitos preservam particularidades dos tipos. |
| Versão e envelope de snapshot, validação de entrada e metadados restaurados | [replica/snapshot_codec.dart](packages/deltasync_core/lib/src/replica/snapshot_codec.dart). O codec usa as coleções para restaurar instâncias; não replica seus mapas. |
| Identidades e endereço/tipo de um lote antes da aplicação | [replica/delta_validation.dart](packages/deltasync_core/lib/src/replica/delta_validation.dart). Recebe conteúdo e delta, sem acesso à Replica privada. |
| Contexto observado do MV, incluindo lacunas e formatos antigos | [causal/dot_context.dart](packages/deltasync_core/lib/src/causal/dot_context.dart). Um leitor atende contexto de delta, estado e versão. |
| Regras JSON, cópia mutável/congelada e validação sem copiar | [json/value.dart](packages/deltasync_core/lib/src/json/value.dart). Um percurso define tipos aceitos e ciclos; `json_value.dart` mantém somente o export público de `copyJsonValue`. |
| Lifecycle, admissão de operações, adoção e eventos após commit | [sync_engine.dart](packages/deltasync_sync/lib/src/sync_engine.dart). Commit local simples/em lote compartilha um percurso; delta e snapshot remotos compartilham outro. |
| Restauração e persistência canônica/legada | [sync/replica_persistence.dart](packages/deltasync_sync/lib/src/sync/replica_persistence.dart). Constrói snapshot/outbox e só retorna após o storage concluir; não adota estado nem emite eventos. |
| Seleção de pendências, retry, envio e validação de ACK | [sync/outbound_sync.dart](packages/deltasync_sync/lib/src/sync/outbound_sync.dart). Preparação e confirmação são serializadas; espera de rede fica fora da fila. |
| Ordem dos commits e drenagem, inclusive após falha | [sync/serial_commit_queue.dart](packages/deltasync_sync/lib/src/sync/serial_commit_queue.dart). Não conhece CRDT, banco nem transporte. |

`sync_types.dart` reúne resultados, falhas, lifecycle e política de retry.
`replica_storage_contract.dart` mantém o contrato, snapshot e entradas de outbox;
`memory_storage.dart` implementa o adaptador volátil dependendo apenas desse
contrato. `replica_storage.dart` reexporta ambos, preservando caminhos de importação
sem dependência circular entre implementação e contrato. `sync_engine.dart`
também reexporta seus tipos públicos separados.
SQLite permanece no adaptador `packages/deltasync_storage_sqflite/`.

### Percurso de integração e manutenção

O PDF usa nomes conceituais para operações que hoje pertencem a contratos
distintos. Esta tabela orienta a leitura sem criar aliases na API:

| Conceito no PDF | API atual | Responsabilidade |
|---|---|---|
| `query()` | `value` do CRDT ou consulta da aplicação sobre `Replica` | Leitura de valor; a regra de negócio e o mapeamento de modelos ficam no consumidor. |
| `merge(other)` | `mergeState(other)` | Join de estado entre instâncias compatíveis do mesmo CRDT. |
| `generateDelta()` | Métodos de mutação, como `setDelta()` ou `addOrSet()` | A mutação local produz deltas; `SyncEngine` com storage também os registra na outbox. |
| `applyDelta(delta)` | `applyDelta()` no CRDT; `Replica.apply(Delta)` ou `SyncEngine.applyRemote(Delta)` | Aplicação de mudança; no engine, commit remoto antes de adoção. |
| `toJson()` | `DeltaCodec.encode()` para delta; `Replica.toSnapshotJson()` para estado | Codificações diferentes para mudança e snapshot; não intercambiáveis. |
| `fromJson(...)` | `DeltaCodec.decode()` ou `Replica.fromSnapshotJson()` | Decodificação validada de delta ou restauração de estado, conforme o formato. |

Fluxo de uma edição offline com storage: a aplicação chama a API de mutação;
`SyncEngine` prepara estado candidato e delta, `ReplicaStorage.commit` grava
snapshot e outbox atomicamente, e só então o engine adota o estado. No recebimento,
decodifica-se o envelope/delta, aplica-se o join e `commitRemote` grava o snapshot;
na abertura seguinte, `start()` restaura o snapshot antes das operações.
O delta contém mudanças tipadas; `DeltaEnvelope` acrescenta versão e endereços de
sender/recipient para transporte, sem assumir protocolo de rede.

```mermaid
flowchart LR
  A[App: mutação] --> B[Core: delta + estado candidato]
  B --> C[Storage: commit atômico snapshot + outbox]
  C --> D[Sync: envia delta em envelope]
  D --> E[Peer: aplica delta e faz join]
  E --> F[Storage remoto: commitRemote]
  F --> G[Restore: snapshot antes do uso]
```

Um percurso real para contribuidores é a inclusão do OR-Set: comportamento e
invariantes vivem em `packages/deltasync_core/lib/src/or_set.dart`; a API de mutação
fica em `replica.dart`, e armazenamento/cópia/restauração comuns em
`replica/contents.dart`. Commit vive em `sync/replica_persistence.dart`, com
adoção/eventos coordenados por `sync_engine.dart`.
Comece por `packages/deltasync_core/test/or_set_test.dart`, siga para
`packages/deltasync_sync/test/sync_engine_test.dart` e para os testes do adaptador
SQLite quando mudar persistência. Tags dot identificam adições; remoção só elimina
tags observadas, e join une tags sem inferir entrega pelo contador máximo. Mudanças
de formato devem preservar os codecs/versionamento e snapshots legados documentados
em [compatibilidade](#compatibilidade-de-api-e-formatos).

Para alterar ownership, cópia ou restauração, execute também
`replica_ownership_test.dart`: uma fixture v9 capturada antes da refatoração R-20
cobre os oito tipos, formatos e identidades. Os testes verificam isolamento entre
original/candidata, adoção, continuação das sequências e versões anteriores.
Essa fixture complementa histórias causais e testes de reabertura/rollback SQLite.

Para implementar outro storage, implemente diretamente o contrato público
`ReplicaStorage` em `packages/deltasync_storage/lib/src/replica_storage.dart` e
execute `replicaStorageContractTests` da fixture em
`packages/deltasync_storage_testing`. `commit` deve tornar snapshot e novas entradas
de outbox visíveis juntos, ou manter ambos anteriores quando falhar; `commitRemote`
não apaga outbox local. O adaptador de referência e os testes de recuperação ficam
em `packages/deltasync_storage_sqflite`. Core, sync e contrato não exigem banco ou
Flutter; o consumidor escolhe e fornece o backend ao compor `SyncEngine.withStorage`.

### Storage

`ReplicaStorage` é o contrato oficial para persistência. A aplicação deve fornecer
um adaptador persistente quando precisar recuperar estado após reinício, como um
adaptador SQLite, Hive, Isar ou arquivos.

`MemoryStorage` é apenas uma implementação volátil de referência. Serve para
testes, exemplos e protótipos; todos os dados são perdidos quando o processo
termina e não deve ser usado como storage de produção.

Adaptadores de `ReplicaStorage` devem implementar `commit` para gravar snapshot
canônico e entradas novas da outbox atomicamente, e `commitRemote` para substituir
snapshot após merge remoto. Falha deve preservar estado anterior. Cada entrada
outbox contém uma mudança; `SyncEngine` combina entradas em lote só no envio.
`markSent` grava status, tentativa e horário antes da transmissão para selecionar
retries com backoff na próxima chamada a `push()`; `acknowledge` remove apenas IDs
confirmados do peer. Suíte
compartilhada para validar adapters está em `deltasync_storage_testing`.
Para a mesma réplica, peer e ID de mudança pendente, `commit` e `enqueue`
aceitam conteúdo de delta equivalente sem substituir status, tentativas ou
horários existentes. Conteúdo divergente lança `FormatException`; `commit`
preserva snapshot e outbox anteriores. A suíte compartilhada exercita ambos os
casos em MemoryStorage e SQLite. O schema e o JSON persistido não mudaram.
`ReplicaSnapshot` v2 guarda payload `Replica.toSnapshotJson()` sem duplicar
estado/clock em campos paralelos. O reader aceita snapshot v1 com
`metadata['replicaState']` ou delta reexecutável; estado legado sem dados suficientes
é rejeitado. Snapshots restaurados são regravados no formato atual ao iniciar.
`saveReplica` serve a bootstrap/manutenção sem pendências; `enqueue` importa uma
pendência fora de mutação local. Edições usam commit atômico.
No adaptador SQLite, uma falha transitória ao abrir o banco permite repetir
`SyncEngine.start()` com os mesmos objetos; a restauração termina antes de novas
edições. Erros de schema continuam explícitos e não migram dados automaticamente.

`ReplicaState` exposto por `Replica.state` é cópia isolada; consultas devolvem
coleções aninhadas imutáveis. `SyncEngine` clona a `Replica` recebida e `engine.replica`
devolve visão destacada, então escrita direta não contorna commits. Mutações passam
por preparação, commit e adoção comuns; falha mantém estado/outbox prévios. Forks
preservam fonte de tempo HLC injetada.

### Confirmação e retry

`DeltaTransport.send` concluir significa apenas que transmissão local terminou.
`AcknowledgingDeltaTransport.sendAndAwaitAck` retorna peer e estágio explícitos;
`received` não confirma mudança, `appliedAndPersisted` confirma aplicação e commit
remoto durável. ACK parcial remove apenas IDs confirmados para aquele peer. Sem ACK,
`ReplicaStorage` conserva mudanças para retry. A aplicação decide quando chamar ou
agendar `push()` (por exemplo, após detectar reconexão); `SyncEngine` não cria
timer, worker ou tentativa automática. Com `ReplicaStorage`, toda entrada nova
`pending` do peer configurado participa da próxima chamada. Para entradas já
`sent`, `push()` sem `force` só seleciona as que cumpriram o atraso exponencial
desde `sentAt`. Por padrão, `SyncRetryPolicy.baseDelay` é 1 s e `maxDelay`
limita o atraso a 1 min;
`maxAttempts` opcional impede nova seleção após esse número de tentativas marcadas.
`maxAttempts: null` não impõe limite, mas ainda exige nova chamada do consumidor.
`push(force: true)` ignora atraso e limite para retransmissão manual.
`SyncEngine` aceita ACK somente
para IDs do lote enviado, peer configurado e outbox da réplica local. O legado `PendingDeltaStore`
não armazena tentativas nem ACKs: mudanças enviadas ficam pendentes e cada `push`
pode reenviá-las sem limite; `force` não altera esse comportamento. ACK confirma
entrega, nunca autoriza coleta de tombstones. Topologia coberta é enlace ponto a
ponto de peer fixo; garantias não se estendem a peers além dele. Se o adaptador
remoto não puder provar commit durável, não deve reportar `appliedAndPersisted`.
`pending` significa tentativa zero; `sent` conta tentativa iniciada e exige
`sentAt`. ACK remove entrada; `confirmed` só é lido em registros legados.

`SyncEngine` inicia automaticamente antes da primeira operação; também aceita
`start()` explícito e chamadas repetidas após sucesso. `lifecycle` expõe
`created/starting/started/disposed`; falha de início retorna a `created` e permite
retry. `replica` só fica consultável após restauração. Mutação concluída significa
commit local, não confirmação remota.

Para atualizar a UI, aguarde a mutação pública e consulte `pendingDelta()` após o
commit local; exiba o valor pela réplica restaurada e a pendência separadamente.
Ao reconectar, chame `push()`, trate erro pela `Future`, consulte o resultado e
`pendingDelta()` de novo antes de mostrar confirmação remota. Chamadas diretas de
`applyRemote()` também são aguardáveis. `commits` é um stream broadcast sem replay;
emite `SyncCommitEvent` com origem `local` ou `remote` após commit e adoção da
mutação, delta recebido ou snapshot remoto. Ao receber evento, leia `engine.replica`
para obter estado atual; eventos não carregam snapshot nem garantem ACK. Restauração
inicial e progresso de envio não emitem eventos. `dispose()` fecha o stream após
as operações ativas. `errors` informa falhas de callbacks/stream remoto, não
sucessos de commit ou falhas de chamadas aguardadas. O
[consumidor Flutter](example/flutter_mobile/README.md) atualiza o status após
cada ação; o [exemplo CLI](example/offline_reconciliation.dart) chama
`push(force: true)` explicitamente ao reconectar.

`pendingDelta()` consulta alterações ainda retidas localmente; `push()` retorna
`SyncPushResult` com delta enviado, estágio do ACK (quando existe) e IDs
incorporados/persistidos. `fullyAcknowledged` é falso quando um lote enviado não
recebe ACK durável para todos os IDs. Em um `push()` sem mudanças elegíveis, o
delta é vazio e esse getter é verdadeiro por vacuidade, sem comprovar entrega de
pendências filtradas. Falhas chamadas
diretamente são lançadas ao chamador; `errors` expõe falhas de processamento do
stream remoto e erros emitidos pelo stream de transporte. `dispose()` é terminal,
cancela recepção, aguarda operações já iniciadas e rejeita novas operações.
`PendingDeltaStore` não consegue remover uma mudança, mesmo após ACK remoto;
resultado de push confirma transporte, enquanto `pendingDelta()` revela retenção
local e possível reenvio. Esse adaptador legado não grava destino por peer e serve
somente à migração de um enlace fixo; garantias por peer exigem `ReplicaStorage`.

```dart
final engine = SyncEngine.withStorage(
  replica: Replica('device-a'),
  storage: storage,
  transport: transport,
);
final errors = engine.errors.listen((failure) => print(failure.error));
await engine.start();
await engine.setDelta('title', 'edited offline'); // commit local concluído
final pending = await engine.pendingDelta();
final result = await engine.push(); // estágio em result.acknowledgement?.stage
final confirmed = result.acknowledgedIds; // só aplicado e persistido
final remaining = await engine.pendingDelta(); // ainda retido para envio
await engine.dispose();
await errors.cancel();
```

Para atualizar após commits locais e remotos, assine antes das operações:

```dart
final commits = engine.commits.listen((event) {
  final current = engine.replica;
  print('${event.origin}: ${current.state.values}'); // não representa ACK
});
```

O stream não replay eventos anteriores e não aguarda listeners. Uma mutação em
lote emite um evento após seu commit. Cancele a assinatura quando a tela sair; o
stream termina quando `engine.dispose()` fecha o engine.

### Escopo da persistência

Cada dispositivo persiste somente sua própria réplica. O estado completo das
outras réplicas não é armazenado localmente.

O adaptador [SQLite/sqflite](packages/deltasync_storage_sqflite/README.md)
implementa `ReplicaStorage`. Cada dispositivo persiste seu snapshot canônico e
outbox em tabelas próprias; estado, clocks, tombstones e sequências ficam no
payload versionado do snapshot. Commit local grava snapshot e outbox na mesma
transação. Commit remoto troca snapshot sem apagar pendências locais. Consumidor
fornece factory SQLite compatível com sua plataforma.

O `VectorClock` pode conter identificadores e contadores de outras réplicas.
Isso registra conhecimento causal, não o estado completo delas. Operações
remotas podem aparecer como operação vencedora ou ser resumidas pelo relógio,
sem exigir armazenamento da réplica remota inteira.

Uma tabela adicional de operações pode ser criada futuramente para auditoria,
replay, histórico ou deduplicação explícita. Confirmações por participante
também podem ser persistidas futuramente para orientar compactação segura de
operações e tombstones. Nenhuma dessas extensões armazena estados completos de
outras réplicas.

### Demonstração offline com SQLite

Consumidor pequeno mapeia nomes de compradores para campos LWW e total de itens
para G-Counter. Cada comando abaixo roda em processo separado; edições offline e
outbox sobrevivem no banco entre execuções.

```sh
dart run example/offline_reconciliation.dart reset
dart run example/offline_reconciliation.dart offline
# Processo encerra aqui; iniciar novo processo para reconectar.
dart run example/offline_reconciliation.dart reconnect
```

Resultado esperado: fase offline mostra commit local, duas pendências por réplica
e falha de peer indisponível, sem perder edição. Reconexão restaura snapshots e
outboxes, entrega e confirma deltas; ambas réplicas mostram os dois compradores e
total cinco. Reabertura final confirma estado convergente e outboxes vazias.
Exemplo foi executado em Linux x64 com SQLite real via `sqflite_common_ffi`;
outros desktops e usabilidade com participantes não foram avaliados.

O [consumidor Flutter Android](example/flutter_mobile/README.md) usa a factory do
plugin `sqflite`. Sua UI agora permite editar o mesmo título LWW nas duas
réplicas, incrementar G-Counter, desligar o peer e repetir envios. O percurso CLI
acima mantém seus nomes e valores fixos. VAL-07 executou a versão anterior do
app no Moto G52 com Android 13, incluindo dois reinícios reais, restauração da
outbox e confirmação durável; R-15 repetiu o percurso. VAL-08 executou a UI
interativa no mesmo aparelho: conflito LWW, edição durante falha, retry,
convergência e outbox restaurada antes/depois do ACK. Falha transitória de
abertura e retry da UI foram injetados no teste Flutter com SQLite FFI em Linux,
não no aparelho. O exemplo resolve os pacotes locais em workspace próprio; core,
sync e contrato de storage continuam Dart puro. iOS não foi avaliado.

### Medição de tamanho

`dart run example/measure_delta_size.dart` mede as quatro mutações offline acima
antes da reconexão: cada réplica altera um nome LWW e seu componente G-Counter.
Script fixa IDs, valores, quantidade e relógio HLC. Conta bytes UTF-8 de JSON
compacto: `DeltaCodec` para mudanças, `DeltaEnvelope` v2 para mensagem completa e
`Replica.toSnapshotJson()` para snapshot de cada réplica. Delta inclui metadados das
mudanças; envelope acrescenta versão, remetente e destinatário; snapshot inclui
estado materializado, clocks e metadados de réplica. Não inclui whitespace, gzip,
headers, protocolo ou armazenamento SQLite.

Resultado reproduzido duas vezes em Dart/Linux x64:

| Réplica | Mutações | Delta | Envelope | Snapshot |
|---|---:|---:|---:|---:|
| `shopper-a` | 2 | 454 B | 539 B | 627 B |
| `shopper-b` | 2 | 455 B | 540 B | 628 B |
| Total | 4 | 909 B | 1.079 B | 1.255 B |

Neste cenário, envelopes somam 86,0% dos snapshots separados (14,0% menos bytes).
Isso compara a soma das duas mensagens destinadas ao peer fixo com os dois estados
locais antes da reconexão. Resultado descreve apenas esse JSON, payload, valores e
implementação; não demonstra ganho geral nem estima tráfego comprimido ou de rede.

### Custo de contexto e outbox

`dart run example/measure_crdt_cost.dart` compara poucas mudanças em estado
grande com cargas desfavoráveis de MV-Register e OR-Set. O script fixa IDs,
valores, quantidades e HLC; executa mutações/commits por `SyncEngine` com
`SqfliteReplicaStorage` e SQLite FFI real. Um peer SQLite aplica o lote antes de
retornar ACK `appliedAndPersisted`. O resultado separa bytes JSON do delta,
envelope, snapshot e linhas da outbox com metadados, contagens causais, tamanho
do arquivo SQLite e tempos locais observados. Timestamps de criação da outbox e
tempos são gerados em runtime.

Procedimento reproduzível executado duas vezes em Linux x86_64, Dart 3.13.5,
12 processadores reportados. Cada linha usa banco novo. Tempos abaixo são a faixa
mínima/máxima observada entre as duas execuções, sem aquecimento controlado ou
repetições estatísticas; não são benchmark universal.

| Carga | Estado visível | Estrutura/outbox | Delta | Envelope | Snapshot | SQLite |
|---|---:|---:|---:|---:|---:|---:|
| G-Set: 250 valores existentes + 3 novas mudanças | 253 | outbox 1.176 B | 707 B | 809 B | 56.664 B | — |
| MV, N=4 | 1 versão; 4 context dots; 6 refs | 4 pendentes; outbox 1.807 B | 1.210 B | 1.287 B | 803 B | 24.576 B antes/depois do ACK |
| MV, N=8 | 1 versão; 8 context dots; 28 refs | 8 pendentes; outbox 4.525 B | 3.296 B | 3.373 B | 1.259 B | 32.768 B antes/depois do ACK |
| MV, N=16 | 1 versão; 16 context dots; 120 refs | 16 pendentes; outbox 12.922 B | 10.413 B | 10.492 B | 2.221 B | 40.960 B antes/depois do ACK |
| MV, N=32 | 1 versão; 32 context dots; 496 refs | 32 pendentes; outbox 40.930 B | 35.877 B | 35.956 B | 4.109 B | 86.016 B antes; 90.112 B depois do ACK |
| OR-Set: 8 ciclos add/remove + add final | 1 valor | 9 tags; 17 eventos; 8 refs observadas; outbox 7.305 B | 4.569 B | 4.661 B | 4.851 B | — |

Baseline anterior à R-19: refs MV confirmam `N(N−1)/2`: 6, 28, 120 e 496. O delta
pendente cresce mais rápido que o snapshot neste fluxo sequencial. ACK durável limpa 100% das linhas
da outbox; snapshot e contexto do MV permanecem iguais, pois ACK não apaga
conhecimento causal. OR-Set retém 17 eventos para um valor visível. No caso
favorável, três deltas/envelope custam 809 B diante de snapshot de 56.664 B;
outbox com metadados custa 1.176 B. Custos observados para outros casos seguem
carga e histórico. Esses valores preservam a medição anterior à compactação.

Após R-19, o mesmo comando, entradas, ambiente e SQLite FFI mediram:

| Carga | Dots lógicos/ref. | Unidades compactas | Delta | Outbox | Snapshot | SQLite antes/depois ACK |
|---|---:|---:|---:|---:|---:|---:|
| MV, N=4 | 6 | 3 | 1.112 B | 1.709 B | 542 B | 24.576/24.576 B |
| MV, N=8 | 28 | 7 | 2.220 B | 3.449 B | 542 B | 32.768/32.768 B |
| MV, N=16 | 120 | 15 | 4.525 B | 7.034 B | 552 B | 36.864/36.864 B |
| MV, N=32 | 496 | 31 | 9.085 B | 14.138 B | 552 B | 45.056/45.056 B |

Em N=32, delta caiu 74,7%, outbox 65,5% e snapshot 86,6% contra baseline;
os mesmos 496 dots lógicos continuam representados. Em N=16, delta caiu 56,5%
e outbox 45,6%. Tamanho SQLite inclui páginas e não mede espaço recuperável.

Faixa de `write-us` entre execuções: N=4 1.127–5.005; N=8 1.020–1.402; N=16
998–2.354; N=32 861–1.755. ACK: 16, 11, 18–19 e 29–30 ms, respectivamente.
Essas amostras pequenas variam e não sustentam comparação de desempenho entre
plataformas. O tamanho do arquivo SQLite inclui páginas/índices e pode crescer
após apagar linhas; não equivale a bytes de payload ou espaço imediatamente
recuperável. A execução não mede Android, compressão, rede, concorrência ou
cargas multi-peer.

Conclusão técnica: R-19 reduziu bytes MV nas cargas medidas, mantendo lacunas,
IDs da outbox e recuperação SQLite após fechamento/reabertura. R-19 segue COULD;
não muda o gate MUST. Medição limitada a Linux x86_64, Dart 3.13.5, SQLite FFI e
cargas fixas. VAL-05 foi revalidada após a mudança.

### Custos dos percursos locais

`dart run example/measure_core_paths.dart` executa cargas fixas e limitadas para
validação MV, validação JSON e consulta pontual em `ReplicaState`. O instrumento
conta expansão da view pública de contexto e leituras dos elementos JSON, não
alocações totais do heap. Os imports internos desse medidor servem à manutenção;
consumidores usam os contratos públicos documentados acima.

Em R-21, 20 validações de contexto com prefixo 5.000 e dois dots esparsos deixaram
de materializar 100.040 dots: o construtor de `MvRegisterDelta` já valida e guarda
o contexto isolado. A consulta pública `context` continua expandindo sob solicitação.
Validar 20 vezes um JSON com lista de 5.000 elementos passou de 200.000 para
100.000 leituras; o percurso de validação não constrói cópias JSON nem string
serializada. Cópia e validação compartilham regras de ciclos, chaves e números.

`ReplicaState[key]` agora lê e congela somente o campo solicitado; `values` mantém
a visão completa. Isso não elimina as cópias isoladas de candidata, adoção ou das
visões públicas de `SyncEngine.replica`/`Replica.state`. Tempos e ambiente antes/
depois estão em [execução R-21](plan/TRACEABILITY.md#execucao-r-21-2026-10-13);
as cargas pequenas não sustentam promessa universal de desempenho.

## Validação

Testes da raiz cobrem somente a facade. Validar também cada subpacote:

```shell
dart pub get
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart analyze && dart test) || exit 1
done
```

Histórias geradas ficam em `packages/deltasync_core/test/generated_history_test.dart`:
oito sementes fixas (0, 1, 7, 42, 99, 2026, 10000, 65535), três escritores,
dois endereços por tipo, 48 passos locais aleatórios e casos causais explícitos.
Cada história compara quatro permutações com duplicação, perda temporária/reenvio,
lotes e join de snapshots. Falhas incluem semente e traço de operações/deltas.
Para reproduzir uma história, no pacote core:

```shell
dart test test/generated_history_test.dart --name 'seed=42' --reporter expanded
```

`test/support/snapshot_comparison.dart` concentra a comparação: HLC e sequências
locais podem variar entre peers; contextos, dots, tombstones, timestamps vencedores
e ordem de listas do usuário permanecem. Na equivalência de mutação/delta e no
replay, sequências/identidade locais também são verificadas. Componentes PN ausentes
e zero são equivalentes; versões MV são ordenadas por dot somente para comparação.
A regressão mínima do G-Set garante que repetir valor já observado também aplica
a seleção canônica do evento, sem ampliar estado nem mudar formato persistido.

No pacote SQLite, `test/sync_recovery_test.dart` acrescenta sementes 7, 42 e 2026:
dois engines, oito tipos, payloads/quantidades variados, entrega fora de ordem e
duplicada, banco real fechado/reaberto, outbox preservada, novas escritas sem
colisão de IDs, replay antigo e ACK após commit remoto. Esses testes usam SQLite
FFI/Linux e transporte em processo. Complementam falhas/rollback existentes;
não comprovam rede real ou runtime Android atualizado. Evidências e limites em
[VAL-11](plan/TRACEABILITY.md#execucao-val-11-2026-10-13).
Histórias finitas não são prova universal de convergência.

## Planejamento

Para executar tarefa com leitura, implementação, review, validação e atualização
do plano, pedir `$plan-executor Execute R-01` ou “execute a próxima tarefa do plano”.
Veja [guia de uso](plan/RUNBOOK.md).

- [Contexto atual e relação com o PDF acadêmico](proposta.md).
- [Plano: fases, tarefas, prioridades e gates](plan/README.md).
- [Correções da implementação existente](plan/01_PHASE1_CORRECOES.md).
- [Rastreabilidade e evidências](plan/TRACEABILITY.md).
- [Instruções e procedimentos de trabalho](AGENTS.md).
