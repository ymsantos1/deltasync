# Integração e manutenção

DeltaSync fornece oito CRDTs, commit local com outbox e sincronização para um
peer fixo por engine. Comece pelo [percurso SQLite](../README.md#uso).
Modelo, instalação, rede e interface pertencem ao consumidor.

## 1. Configurar armazenamento e identidade

Use `package:deltasync/deltasync.dart` e acrescente `deltasync_storage_sqflite`
para durabilidade. Passe DatabaseFactory compatível com o alvo e caminho
persistente do banco. No Flutter, inicialize o binding da plataforma e use
`databaseFactory` do sqflite; no Dart desktop, inicialize sqflite_common_ffi.
Veja o [exemplo Flutter](../example/flutter_mobile/README.md) e a
[CLI SQLite](../example/offline_reconciliation.dart). MemoryStorage é **volátil**;
use-o apenas quando perder dados ao descartar a instância for aceitável.

O mínimo declarado é Dart ^3.13.0; a referência executada é 3.13.5. Os manifests
do checkout estão alinhados em 1.0.1 pela R-36, sem publicação automática.
Não derive compatibilidade da numeração: há
[quebras deliberadas de fonte](migracao-1.0.1.md), incluindo adaptadores próprios.

Escolha replicaId único por instalação independente e estável entre aberturas.
Não clone um banco para criar outra réplica ativa com a mesma identidade.
Escolha também peerReplicaId estável para o transporte; trocar o peer não move
entradas antigas da outbox. A biblioteca cobre um par fixo por engine, sem
roteamento/descoberta de peers nem confirmação de propagação aos demais.

Componha `SyncEngine.withStorage(replica: ..., storage: ..., transport: ...)`.
Aguarde `start()` para leituras síncronas. Mutações também aguardam inicialização.
Falha transitória de abertura permite repetir start nos mesmos objetos enquanto
não descartados; apresente retry na aplicação. Schema desconhecido continua
falhando e preserva dados: não apague o banco para simular recuperação.

## 2. Mapear modelos e escolher CRDT

Defina endereço estável e tipo por campo, compartilhados pelos peers e após
restauração; não inclua versão temporária de tela ou instante local no endereço.
Um endereço vinculado não pode trocar de tipo silenciosamente.

- LWW escolhe **um valor inteiro**, inclusive um objeto JSON. Não faz merge de
  atributos nem edição colaborativa de texto. Separe endereços quando campos
  precisarem de resolução independente.
- MV-Register mantém versões concorrentes até uma escrita observá-las.
- Counters, G/2P/OR-Set e OR-Map têm invariantes próprias. Consulte o
  [mapa dos oito tipos](referencia-tecnica.md#onde-alterar-cada-tipo).

O app valida modelos e regras de negócio antes das próprias edições e depois de
ler dados remotos. JSON estruturalmente aceito pode ser inválido para o domínio:
`{'name': 42, 'tags': []}` é JSON válido, mas não é o Profile do
[exemplo de decoder](../example/field_decoder_example.dart), que exige nome string
e lista de strings. Não há schema de domínio no core nem adaptador gerado.
No Compass, Booking/chave de viagem/calendário e regras de notas pertencem ao app;
o [fork](https://github.com/ymsantos1/samples-for-tcc) é ilustração, não contrato geral.

## 3. Editar e consultar

A mutação pública termina depois do commit atômico de snapshot/outbox e adoção
da candidata. Esse retorno confirma **salvo localmente**, sem confirmar envio.
Use caminhos separados para mutação, consulta de status e conversão de modelo:

```dart
try {
  await engine.setDelta('profile', profileJson);
} catch (error) {
  showSaveFailure(error);
  return;
}
showSavedLocally();
try {
  final summary = await engine.pendingSummary(
    recipientPeerId: engine.transport.peerReplicaId,
  );
  showPending(summary.totalCount);
} catch (error) {
  showStatusUnavailable(error); // Commit anterior continua salvo.
}
```

As funções de apresentação acima pertencem ao app. O
[fluxo executável](../example/commit_status_example.dart) usa a mesma separação.
A [fixture geral SQLite](../test/integration_guide_test.dart) injeta falha só no
resumo após um commit real, verifica sucesso local/evento/outbox, fecha/reabre o
banco e continua editando. Também distingue falha do próprio commit e erro de modelo.
Falha de consulta não deve disparar repetição automática da edição: counters e
outros comandos poderiam produzir uma nova mudança legítima.

`pendingSummary` conta pending/sent sem montar deltas. Sem filtro, inclui todos
os peers; passe o peer da engine para status do enlace atual. `sent` ainda aguarda
ACK; erro na consulta significa status desconhecido, não outbox vazia nem edição
perdida. `pendingDelta` continua disponível para inspecionar o conteúdo pendente,
mas não é necessário para um contador visual. Não mantenha cache paralelo de outbox.

`engine.query(address)` distingue:

| Variante | Significado |
|---|---|
| AbsentField | Endereço sem tipo vinculado |
| PresentField | Valor isolado, inclusive LWW null; demais tipos podem conter zero/vazio |
| DeletedField | Tombstone LWW atual, preservado para merge/restauração |

Use switch exaustivo e converta somente o ramo presente:

```dart
String describe(FieldQuery result) => switch (result) {
  AbsentField() => 'não configurado',
  DeletedField() => 'removido',
  PresentField field => switch (field.decode(Profile.fromValue)) {
    null => 'null presente', // Política explícita do modelo deste app.
    Profile(:final name) => name,
  },
};
```

Profile é o modelo do consumidor demonstrado no exemplo. Trate FormatException
do decoder na camada de apresentação; não converta erro em ausência ou sucesso.
Um erro de leitura após commit não desfaz esse commit. `field.value` preserva a
leitura bruta para inspeção/migração. Valores consultados são isolados; coleções
aninhadas são somente leitura. `valueAt` é a conveniência que retorna null para
ausência, LWW null e tombstone; use query quando essa distinção importar.
Durante um await de commit/rede, consulta lê o último estado **adotado**, não a
candidata. Antes de start e após dispose, query/valueAt lançam StateError.

Para campos relacionados, use um lote local:

```dart
await engine.batch((batch) {
  batch.setDelta('profile/name', 'Ada');
  batch.incrementGCounter('profile/revisions');
  print(batch.query('profile/name')); // Candidata, ainda não persistida.
});
```

Callback é síncrono, sem I/O ou outras chamadas à engine. Lote vazio, callback
async, erro de edição mesmo capturado ou falha de commit abortam o lote. Editor
expira antes do await do storage. Atomicidade é local; ACK/envio seguem por
mudança. Efeitos externos do callback/decoder não são desfeitos. Veja o
[exemplo de lote](../example/local_batch_example.dart).

## 4. Observar falhas e pendências

Assine `engine.commitsFor(address)` para atualizar só campos pertinentes e
`observations` para estado da sessão. Leia query e pendingSummary após eventos,
tratando suas falhas separadamente. Não copie réplica inteira para atualizar um
campo. `SyncCommitEvent.addresses` informa endereços processados, inclusive replay
ou escrita sem efeito visível; leia o valor atual, não um valor histórico do evento.
Veja o [exemplo seletivo](../example/selective_observation_example.dart).

Streams são broadcast assíncronos, sem replay. Assine antes de start para
SyncRestoredEvent; listener tardio deve hidratar valor/status explicitamente.
Commits não notificam restauração ou ACK. Ordem é por assinatura; listeners
distintos não têm ordem relativa garantida e não governam commit. Pausar filtros
pode acumular eventos não selecionados: retome/cancele antes de aguardar dispose.

| Canal/resultado | O que indica |
|---|---|
| Future da mutação | Commit local concluído ou erro da chamada |
| commits / commitsFor | Commit local/remoto e endereços processados |
| observations | Restore, commit, resultado/falha de push e falha de recepção |
| errors | Falha de callback/stream remoto; não substitui catch de chamadas diretas |
| pendingSummary | Contagem atual na outbox, sem prova de envio/ACK |
| SyncPushResult | Lote enviado, ACK e IDs reconhecidos após persistência local do ACK |

Falhas de chamadas diretas são tratadas por suas Futures. Uma falha de rede não
impede nova edição local. Após reinício, recupere estado e outbox; mensagens
transitórias de confirmação da sessão não são persistidas nem repetidas.

## 5. Sincronizar e confirmar

O app decide quando chamar `push()` por ação manual ou reconexão e agenda retry.
Não há timer, worker ou busca de rede automática. A política de backoff filtra
entradas elegíveis na próxima chamada; `push(force: true)` ignora atraso/limite.
Espera de rede fica fora da fila de commits, permitindo editar durante falhas.
O adaptador precisa limitar esperas; dispose drena operações aceitas.

Concluir `send` indica transmissão local. ACK `received` indica recebimento;
somente `appliedAndPersisted` do peer configurado confirma IDs e permite removê-los
da outbox correspondente. ACK parcial só limpa IDs reconhecidos daquele lote/peer.
Sem ACK, pendência permanece para reenvio. Um push vazio pode ter
`fullyAcknowledged == true` por vacuidade; não prova envio de pendências filtradas.
Nada disso confirma propagação a outros participantes ou autoriza GC causal.

Receba envelopes por `receiveEnvelope`, tanto no incoming quanto em pull externo.
O método valida peer/destinatário, faz join, aguarda commit remoto/adoção e retorna
ACK. Se o transporte implementar IncomingAcknowledgingDeltaTransport, a engine
também envia o ACK; sem esse contrato, o chamador o envia após sucesso e o stream
não o envia automaticamente. Falha ao enviar ACK preserva commit e admite replay.

Use os codecs públicos de DeltaEnvelope/DeltaAcknowledgement. Decodificar JSON
não autentica remetente nem comprova persistência. Autenticação, TLS, autorização,
timeouts, endpoint, busca e política de retry pertencem ao adaptador/app. Não
reportar appliedAndPersisted se o peer não puder provar commit durável.

## 6. Encerrar e restaurar

Quem compõe os recursos é responsável por fechá-los. SyncEngine controla sua
assinatura incoming e seus streams; não fecha transporte/storage do consumidor.
Cancele listeners da aplicação, aguarde `engine.dispose()` e então libere os
recursos concretos do transporte e `storage.close()`, usando finally para tentar
liberar os demais mesmo se um encerramento falhar. Não descarte banco/rede durante
um commit ou ACK aceito. O contrato DeltaTransport não exige método close;
o adaptador concreto define sua própria liberação.

Dispose é terminal; falhas de abertura antes dele admitem retry, não reutilização
de uma engine descartada. Para reabrir, crie nova composição com banco e replicaId
anteriores, aguarde start e hidrate as consultas. Não use clear-data como recuperação.
Execute a CLI offline em processos separados para validar persistência real:

```sh
dart run example/offline_reconciliation.dart reset <diretorio-da-demo>
dart run example/offline_reconciliation.dart offline <diretorio-da-demo>
dart run example/offline_reconciliation.dart reconnect <diretorio-da-demo>
```

Reset apaga apenas os bancos dessa demonstração: use diretório próprio.
No percurso normal do app não há reset. SQLite FFI/Linux não comprova runtime
Android/iOS; o exemplo Flutter documenta suas evidências de plataforma.

## Pontos de manutenção e compatibilidade

| Regra | Dono e ponto de alteração |
|---|---|
| Modelo, identidade/endereço, autenticação, agendamento e UI | Consumidor; conveniências por composição/conversões próprias |
| Estado/mutação/delta/join de cada tipo | Core: Replica e CRDT concreto; veja [mapa](referencia-tecnica.md#onde-alterar-cada-tipo) |
| Snapshot/restauração/versão no core | replica/contents.dart e replica/snapshot_codec.dart |
| Codec de delta / envelope e ACK | Core DeltaCodec / deltasync_transport, respectivamente |
| Candidata, adoção, lifecycle, fila e eventos | SyncEngine; sync/serial_commit_queue.dart |
| Construção de snapshot/outbox e restauração durável | sync/replica_persistence.dart; ReplicaStorage |
| Retry/seleção/envio/ACK | sync/outbound_sync.dart; protocolo real no adaptador |
| Transação/rollback, schema e abertura SQLite | deltasync_storage_sqflite |

Implemente os contratos públicos de storage/transport; não importe src nem
sobrescreva internos. Novo storage executa `replicaStorageContractTests` de
deltasync_storage_testing e acrescenta provas de rollback/reabertura no backend
real. Inclua pendingSummary, consistência por peer e semântica de falha; não
simule durabilidade com memória. Para transporte, preserve roteamento, codec e
ACK depois de commit; testes em processo não provam autenticação/rede física.

Os oito tipos são um catálogo integrado fechado, não um registro extensível de
plugins. Um novo CRDT integrado exige contrato/mudança tipada, CrdtKind/labels
estáveis, codec versionado, roteamento/mutação/consulta e snapshot no core,
entrada pública na engine/editor quando pertinente e testes de join/ordem/
duplicação/recuperação. Planeje compatibilidade de leitores, switches e forks.
Isso não autoriza adicionar tipo ao escopo atual. Composição de modelos do app
continua externa; ObjectCrdt, codegen/build_runner e GC destrutivo ficam futuros.

As remoções de fonte, novo membro obrigatório de storage, decoder, lote,
eventos e consulta explícita estão no [guia 1.0.0 para 1.0.1](migracao-1.0.1.md).
A numeração patch deliberadamente não promete compatibilidade. Dados antigos
exigem readers e migração próprios; não altere payloads ou apague banco para
contornar erro. Veja a [referência completa](referencia-tecnica.md#compatibilidade-de-api-e-formatos)
e os [checks locais](ci.md). O piloto Saropa foi adiado; advisories e testes
continuam separados do lint.

## Esforço observado no Compass

As contagens e comparações anteriores foram preservadas em
[medições e histórico](medicoes.md#esforço-observado-no-compass). Elas ilustram
manutenção de um consumidor, sem medir esforço de terceiros ou usabilidade.
