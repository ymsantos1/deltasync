# Migração de fonte e dados para 1.0.1

A consolidação planejada para 1.0.1 remove APIs públicas. Por escolha expressa
do autor, esse número inclui quebras normalmente reservadas a uma versão major.
Não considere o upgrade compatível apenas pelo número. Os manifests ainda serão
ajustados em R-36; esta mudança não publica nem renumera pacotes ou dados.

## Substituições de fonte

| Antes | Depois | Adaptação |
|---|---|---|
| `PendingDeltaStore`, `MemoryPendingDeltaStore` | `ReplicaStorage`, `MemoryStorage` ou SQLite | Snapshot e outbox devem participar do mesmo commit; memória continua volátil |
| `SyncEngine(store: ...)`, `engine.store` | `SyncEngine.withStorage(storage: ...)`, `engine.storage` | Storage é obrigatório e não nullable; construtor sem nome também aceita `storage:` obrigatório |
| `Replica.set/remove`, `SyncEngine.set/remove` | `setDelta/removeDelta` | Engine retorna Future; aguarde commit local antes de indicar sucesso |
| `Delta.crdt(changes)` | `Delta(changes)` | Lote de mudanças nativas |
| `delta.crdtChanges` | `delta.changes` | Mesma ordem e conteúdo |
| `entry.operationId` | `entry.entryId` ou `entry.changeIds` | ID singular ou coleção, sem gerar outro ID |
| `Operation`, `migrateLegacyOperation` exportados | Métodos nativos e `DeltaCodec.decode` para registros históricos versionados | Não importar `src`; o DTO/conversor histórico são detalhes internos |

`DeltaChange`, `ReplicaStorage` e os contratos de transporte continuam
implementáveis pelos consumidores. Seus membros não mudaram nesta tarefa.
Adaptadores de storage devem implementar `loadReplica`, `saveReplica`, `commit`,
`commitRemote`, `enqueue`, `pending`, `pendingSummary`, `markSent` e `acknowledge`. Execute a suíte
de `deltasync_storage_testing`, além de provas de rollback/reabertura no seu banco.
O [consumidor migrado](../plan/evidence/r39/consumer_test.dart.txt) implementa os
contratos públicos por composição, sem herdar ou importar implementação interna.

## Consulta explícita de campo — R-42

`Replica.query(String address)`, `SyncEngine.query(String address)` e
`LocalBatch.query(String address)` retornam `FieldQuery`, uma hierarquia sealed
com três variantes construídas pela biblioteca. O consumidor lê por pattern
matching; não cria nem implementa variantes ou importa arquivos `src`.

```dart
String describe(FieldQuery result) => switch (result) {
  AbsentField() => 'Endereço sem CRDT vinculado',
  DeletedField() => 'Removido; tombstone LWW preservado',
  PresentField(:final kind, :final value) => '${kind.wireName}: $value',
};
```

| Resultado | Semântica |
|---|---|
| `AbsentField` | Endereço sem tipo vinculado; não equivale a coleção vazia |
| `PresentField` | `kind` é `CrdtKind`; `value` é o valor isolado, inclusive null legítimo de LWW |
| `DeletedField` | Vencedor LWW atual é tombstone; não expõe valor nem executa GC |

Nos outros sete CRDTs, todo endereço vinculado é presente, mesmo com zero ou
coleção vazia. Counters retornam int; G/2P/OR-Set e MV-Register retornam
`Set<Object?>`; OR-Map retorna `Map<String, Set<Object?>>`. MV escrito com null
retorna `{null}`, um conjunto presente. Remover elemento de set ou chave de
OR-Map não remove o campo inteiro. Coleções, inclusive aninhadas, são somente
leitura, isoladas do estado e estáveis após edições posteriores.

`valueAt` não muda: ausência, LWW null e tombstone continuam retornando null.
Adote `query` apenas onde a distinção importa. `PresentField.value` continua
`Object?`; o resultado tipado descreve presença, não o schema do aplicativo.
Conversão e validação do modelo pertencem ao consumidor. Execute o decoder
apenas no ramo presente, passando também null legítimo; trate ausência e remoção
nos próprios ramos e propague falhas do decoder, sem convertê-las em ausência ou
sucesso. A conveniência de R-40 é `PresentField.decode<T>`; consulte o contrato
abaixo. A consulta bruta e suas três variantes permanecem disponíveis.

Na engine, aguarde `start()` antes da consulta síncrona; antes disso, durante
inicialização ou após `dispose`, a leitura lança `StateError`. Durante await de
storage/rede, a consulta lê o último estado adotado; uma candidata só aparece
após commit local bem-sucedido. No callback de lote, `batch.query` lê edições
provisórias; seu editor expira antes do await do commit. Um resultado presente
não confirma envio ou ACK. Outbox vazia não significa ausência nem remove
tombstones. Leituras não alteram clocks, snapshot, outbox ou formatos.

Para manutenção, `ReplicaState.kindAt/isDeletedAt` consultam metadados canônicos;
`Replica` centraliza os valores dos oito tipos no mesmo percurso de `valueAt`.
`isDeletedAt` retorna false para endereço ausente ou tipo não LWW, sem copiar
payload; aplicações devem preferir `query` para distinguir todos os casos.
As variantes ficam em part da mesma library de Replica para manter construtores
privados; não há cache de presença nem segundo modelo de estado. A engine e o
editor delegam a consulta ao core. Não mudaram joins, mutações, commit,
restauração, contratos de adaptadores ou formatos persistidos. API adicionada;
quem herda Replica/SyncEngine deve conferir conflitos com um método próprio
chamado `query`. Adicionar uma variante futura exigirá migrar switches exaustivos.

Veja o [exemplo executável](../example/field_query_example.dart). As provas de
core, facade, commit falho e reabertura SQLite ficam no
[registro R-42](../plan/TRACEABILITY.md#execucao-r-42-2026-10-24).

## Decoder opcional no resultado presente — R-40

A conversão é opcional por leitura: use `field.value` para o valor bruto ou
`field.decode<T>(T Function(Object? value) decoder)` para obter o modelo do app.
O tipo T é inferido pelo retorno do decoder ou indicado pelo consumidor. A mesma
conveniência serve aos resultados de Replica, SyncEngine e LocalBatch; não há
novo percurso de consulta, hierarquia de resultados, schema ou estado em cache.

```dart
Profile? readProfile(SyncEngine engine, String address) {
  return switch (engine.query(address)) {
    AbsentField() => null, // Política do app para endereço ainda não configurado.
    DeletedField() => throw StateError('Perfil removido'),
    PresentField field => field.decode(Profile.fromValue),
  };
}
```

`Profile` e `Profile.fromValue(Object?)` pertencem ao consumidor. O
[exemplo completo](../example/field_decoder_example.dart) implementa o modelo,
rejeita JSON incompatível, trata a falha e define política explícita para null.
Um JSON válido para a biblioteca pode ser inválido para esse modelo.

| Caso | Conversão |
|---|---|
| Ausente | `AbsentField` não oferece decode; consumidor trata seu ramo |
| Tombstone LWW | `DeletedField` não oferece decode; consumidor trata seu ramo |
| Presente, inclusive null | Decoder recebe o valor exatamente uma vez; null não é ignorado |
| Retorno nullable | Retorno null legítimo é devolvido; resultado original continua presente |
| Erro no decoder | Exceção propaga sem wrapping, valor padrão ou conversão em ausência/sucesso |

O método invoca o callback sincronamente sobre o valor já isolado da consulta,
sem novo acesso à réplica, ao storage ou à rede. Coleções de entrada continuam
somente leitura, inclusive aninhadas. Para produzir modelo mutável, copie os
dados no decoder; mutabilidade/validação do resultado T pertencem ao consumidor.
O resultado de consulta retido continua estável e pode ser convertido depois
de novas edições, fechamento do editor ou dispose da engine. Já obter nova
consulta continua sujeito ao lifecycle e ao escopo do editor definidos em R-42.

Conversão não grava nem confirma nada, não altera clocks/outbox e não emite
evento de commit ou erro da engine. Capture a falha no chamador; ela não desfaz
um commit anterior. Se um decoder lançar dentro de callback de lote e o erro
escapar, aplicam-se as regras existentes de abortar o lote por exceção do
callback. Preferir preparar/validar os dados do modelo antes de iniciar edições.
Não execute I/O ou mutações capturadas pelo decoder: efeitos externos do callback
pertencem ao app e não podem ser desfeitos pela biblioteca.

API adicionada somente a `PresentField`; assinaturas de query/valueAt,
variantes de FieldQuery e formatos permanecem. `PresentField` já era final e
tinha construtor privado. Switches R-42 não precisam de novos casos. Um membro
de instância tem precedência sobre uma extension chamada decode do consumidor;
renomeie essa conveniência ou use invocação explícita da extension. Para
manutenção, a conversão vive em `PresentField.decode` na library de Replica;
estado, delta/join, commit e restauração mantêm seus donos anteriores. Veja as
[evidências R-40](../plan/TRACEABILITY.md#execucao-r-40-2026-10-24).

## Eventos seletivos e fonte comum — R-41

`SyncCommitEvent.addresses` é um `Set<String>` isolado e somente leitura com os
endereços processados pelo input de um commit adotado. Não é uma comparação de
valores visíveis: replay, escrita LWW perdedora e remoção também podem notificar.
Um lote gera um evento com endereços únicos dos seus deltas, inclusive quando
edita o mesmo campo mais de uma vez. Delta remoto vazio pode gerar commit com
conjunto vazio. Em snapshot remoto, são os endereços vinculados do peer,
incluindo tombstones e CRDTs vazios/zero; endereços apenas locais ficam de fora.

```dart
final subscription = engine.commitsFor('profile/name').listen((event) {
  final current = engine.query('profile/name');
  // Atualize a apresentação usando current e os ramos de FieldQuery.
});
await engine.start();
final initial = engine.query('profile/name'); // Hidratação inicial explícita.
// Ao encerrar a tela, cancele a subscription antes do dispose da engine.
```

`commitsFor(address)` filtra `commits`; não consulta estado, faz polling, copia
réplica ou dispara sync. O [exemplo executável](../example/selective_observation_example.dart)
mostra uma atualização por lote, ignora endereço não observado e mantém
pendências locais sem iniciar envio. Leia query/valueAt para o valor atual: um
evento atrasado/pausado não guarda o valor histórico daquele commit.
Filtro compara endereço exato, sem prefixo; OR-Map informa seu endereço CRDT,
não o nome de uma chave interna.

Internamente há uma fonte broadcast assíncrona de `SyncObservation` e um emissor.
`observations` expõe essa fonte; `commits` e `errors` são filtros tipados que
preservam as mesmas instâncias de evento. Não há novo registro persistido nem
cache de pendências. Eventos de commit são emitidos somente após persistência
e adoção; rollback não emite sucesso. Falha de envio de ACK após commit remoto
não desfaz o estado nem seu evento. Push/ACK continuam eventos distintos de
commit; falha de método aguardado pertence ao Future, e falhas de callbacks
incoming também aparecem como `SyncFailure` em observations/errors.

Canais são broadcast, sem replay. Assine antes de start para observar restore
em observations; um listener tardio faz sua consulta inicial. Ordem é preservada
por subscription, sem garantia de ordem relativa de execução entre listeners de
canais diferentes. Listeners são assíncronos, não governam a transação e suas
exceções seguem a Zone do consumidor. Dispose drena trabalho aceito e fecha
todos os canais derivados; novos trabalhos são rejeitados.

Pausa não bloqueia commits, mas pode acumular eventos na subscription. Como os
filtros compartilham a fonte, uma subscription pausada pode reter também eventos
que depois serão descartados pelo filtro. Cancele ou retome subscriptions
pausadas antes de aguardar dispose; o fechamento aguarda a entrega de done aos
listeners ativos. Não pause indefinidamente uma subscription de longa duração.

### Migração de fonte e switches

`SyncCommitEvent` passa a exigir `addresses` e deixa de ter construtor const:

```dart
final event = SyncCommitEvent(
  origin: SyncCommitOrigin.local,
  addresses: {'profile/name'},
);
```

Implementações externas de SyncCommitEvent devem fornecer também
`Set<String> get addresses`. Não retornar um conjunto mutável compartilhado.
Subclasses devem passar addresses ao super e adaptar construtores const.
Nenhuma variante de SyncObservation foi adicionada/removida: switches exaustivos
existentes mantêm seus casos. Para consumir metadados, amplie o padrão de commit
para `SyncCommitEvent(:final origin, :final addresses)`; os outros quatro casos
continuam iguais. A [fixture migrada](../plan/evidence/r41/consumer_test.dart.txt)
compila os cinco casos e uma implementação externa do evento.

`Replica.mergeSnapshotJson` agora retorna `Set<String>` dos endereços do snapshot
processado, em vez de void. Chamadas que ignoram o retorno continuam válidas.
Quem implementa Replica ou sobrescreve esse método deve atualizar o retorno e
preservar a semântica dos endereços processados. A engine usa esse resultado do parse
canônico, sem decodificar o snapshot outra vez ou manter parser de endereços.
Construtor antigo const, implementação sem addresses e override com retorno void
exigem adaptação de fonte; a versão 1.0.1 não implica compatibilidade SemVer.

Estado/delta/join continuam no core; commit/adoção em SyncEngine; formato e
transações nos adaptadores. Endereços de deltas usam DeltaChange.crdtId;
snapshots retornam metadados do estado remoto já restaurado. Emissão passa por
`_emit` em SyncEngine; seleção é um filtro público. Não mudaram variantes,
envelopes, snapshot/outbox JSON, SQL, ACK ou clocks. Veja as
[evidências R-41](../plan/TRACEABILITY.md#execucao-r-41-2026-10-24).

## Resumo de pendências em adaptadores — R-37

`ReplicaStorage` ganha um membro obrigatório; implementações externas devem
adicioná-lo antes de compilar com esta versão:

```dart
Future<OutboxSummary> pendingSummary(
  String replicaId, {
  String? recipientPeerId,
});
```

Retorne `OutboxSummary(pendingCount: ..., sentCount: ...)`, com inteiros não
negativos obtidos em uma leitura consistente da outbox. `totalCount` soma os
dois grupos. `sent` continua sem confirmação; ignore `confirmed` histórico.
Filtro null inclui todos os peers; um mesmo ID para dois peers conta duas vezes.
Consulta não marca envio, não remove registros e não confirma entrega.
Erros devem ser lançados, nunca convertidos em contagem zero.

Use agregação/metadata do backend quando disponível. Um adaptador pode começar
contando os status de `await pending(replicaId, recipientPeerId: ...)`, mas isso
mantém o custo de materializar payloads; não cria uma contagem eficiente. A suíte
de contrato verifica filtros, pending/sent, ACK parcial, concorrência e rollback.
Não é necessário implementar outra interface opcional nem manter cache de status.
O [consumidor migrado R-37](../plan/evidence/r37/consumer_test.dart.txt) demonstra
o membro novo por delegação e continua usando somente imports públicos.

MemoryStorage lê somente status/destino das entradas existentes. SQLite agrupa
status no SQL e devolve pequenos grupos de contagem, sem instanciar deltas em
Dart; ainda lê/processa o texto JSON no banco, sem promessa de custo constante.
Não há mudança de schema nem cópia de status para outra coluna. Como funções
JSON podem faltar em uma build SQLite, o adaptador usa leitura de metadata JSON
em Dart somente ao receber `no such function: json_extract`; outros erros
propagam. Esse fallback preserva compatibilidade, com custo maior. A disponibilidade
das funções depende da [compilação SQLite](https://www.sqlite.org/json1.html#compiling_in_json_support).
Resumo consulta metadata e não valida o corpo do delta: uma contagem positiva
não certifica que payload corrompido possa ser enviado. A validação continua nos
readers/mutações/envio existentes. Limites de parsing SQL também podem causar
falha de consulta, mesmo após commit local bem-sucedido.

Na aplicação:

```dart
await engine.setDelta('title', 'Salvo localmente');
try {
  final summary = await engine.pendingSummary(
    recipientPeerId: engine.transport.peerReplicaId,
  );
  print('${summary.totalCount} mudanças aguardando ACK');
} catch (error) {
  // A edição já foi salva; a consulta de status falhou. Permita novas edições.
  print('Status indisponível: $error');
}
```

A consulta pela engine aguarda restauração e a fila de commits, incluindo ACK
local; não aguarda rede em andamento. O resultado descreve o instante da leitura,
podendo mudar após o Future concluir. Chamada após dispose falha. Sem filtro,
o escopo é global, como pendingDelta. Não substitua detalhes de payload por esse
resumo quando precisar efetivamente enviar ou inspecionar mudanças.

## Lote local atômico — R-38

`SyncEngine.batch(FutureOr<void> Function(LocalBatch) mutate)` retorna
`Future<Delta>` com todas as mudanças emitidas, somente após commit local e adoção.
É uma API adicional; métodos individuais e contratos de adaptadores continuam
iguais. Agrupe os campos relacionados pela API pública:

```dart
final changes = await engine.batch((batch) {
  batch.setDelta('profile/name', 'Ada');
  batch.setDelta('profile/preferences', {'theme': 'dark'});
  batch.incrementGCounter('profile/revisions');
});
```

LocalBatch oferece mutações de LWW, G/PN-Counter, G/2P/OR-Set, MV-Register e
OR-Map, incluindo métodos de múltiplos elementos e valor OR-Map. valueAt lê a
candidata com edições anteriores do lote; coleções são isoladas/read-only conforme
o core. Métodos do editor retornam void; o Delta do Future concluído contém os
IDs/deltas comprometidos. Não há schema de domínio, comandos paralelos ou Replica
exposta. Regras de negócio continuam no consumidor.

O callback deve terminar sincronamente, sem I/O, awaits ou outras operações da
engine. Prepare dados externos antes; use batch.valueAt para ler a candidata.
FutureOr<void> permite detectar e rejeitar um Future retornado; não autoriza
callback assíncrono. Esse caso causa ArgumentError e rollback da candidata sem
aguardar operação externa. Suas continuações não podem usar o editor fechado nem
chamar operações da engine no contexto do lote rejeitado. Falhas posteriores
desse Future são observadas internamente para não gerar erro órfão adicional;
o chamador recebe a rejeição do callback assíncrono.

Lote vazio falha com StateError sem commit/evento. Exceção no callback propaga;
mutação inválida propaga seu erro e invalida o lote inteiro, mesmo capturada.
Chamada reentrante a mutação/lote, start, push, consulta enfileirada ou dispose
também invalida o lote com StateError. O editor fecha quando o callback termina,
antes de aguardar storage; guardá-lo para depois ou usá-lo durante commit pendente
gera StateError. Chamadas após dispose falham pelo lifecycle.

Não agende trabalho assíncrono separado nem escreva diretamente no storage no
callback. A biblioteca não desfaz I/O, alterações de variáveis do app ou outros
efeitos externos iniciados pelo usuário. Essas restrições integram o contrato;
o editor governa apenas as mutações nativas rastreadas no lote.

Uma candidata passa pelo commit local existente, com snapshot e uma entrada por
mudança para o peer configurado. Após sucesso, a engine adota a candidata e emite
uma notificação de commit local. Falha preserva estado vivo, outbox e sequências;
chamadas futuras continuam possíveis. Edições concorrentes usam a mesma fila e
veem o resultado adotado completo; espera de rede permanece fora dessa fila.

Atomicidade é local, não uma transação distribuída. Envelope/schema/ACK não
mudam: peer pode confirmar apenas parte das mudanças e recebê-las em momentos
diferentes. Não prometa invariantes de domínio atômicas em todos os dispositivos.
MemoryStorage é volátil; persistência exige backend com commit atômico real.

Manutenção: regras, mutações e joins ficam em Replica/CRDTs. LocalBatch delega e
coleta mudanças; _record centraliza falha e _close encerra o recurso. É um final
class com construtor privado na library de SyncEngine via part: consumidores não
constroem nem implementam editores próprios. A engine controla contexto do
callback, candidata, commit e adoção no pipeline existente. O inventário atual
usa scripts/api_inventory.dart, que segue parts; ferramenta e fixtures congeladas
de R-30 permanecem como evidência histórica.

Execute `dart run example/local_batch_example.dart` para um perfil com nome,
preferências e revisão. O exemplo verifica commit e pendência pela facade;
não simula persistência remota. Ver [registro R-38](../plan/TRACEABILITY.md#execucao-r-38-2026-10-24).

## Migração do antigo pending store

Antes de atualizar o código, interrompa novas edições e envios e aguarde operações
em andamento. Ainda com a biblioteca antiga, exporte `await store.read(replicaId)`
com `DeltaCodec.encode`, além de um checkpoint completo obtido por
`replica.toSnapshotJson()`. Preserve réplica, IDs e clocks originais. O store
antigo guarda somente pendências: sozinho não recupera dados já confirmados ou
remotos. Se não houver checkpoint completo, obtenha um bootstrap confiável antes
de migrar. Não considere um delta pendente um backup de toda a réplica.

Escolha explicitamente o peer de destino; o store antigo não o registrava.
Valide o export pelo codec versionado, restaure o checkpoint, aplique pendências
e crie uma `OutboxEntry` por mudança, sem reemitir mutações ou gerar IDs novos.
Os antigos stores não tinham tentativas persistidas; as entradas importadas
começam `pending`. Não derive peer ou clocks de suposições sobre o aplicativo.

Exemplo de função pertencente ao consumidor, para um destino ainda vazio:

```dart
Future<void> importPending({
  required ReplicaStorage target,
  required Map<String, Object?> checkpoint,
  required Map<String, Object?> encodedPending,
  required String recipientPeerId,
}) async {
  final candidate = Replica.fromSnapshotJson(checkpoint);
  final pending = DeltaCodec.decode(encodedPending);
  if (pending.changes.any((change) => change.replicaId != candidate.id)) {
    throw FormatException('Pending batch belongs to another replica');
  }
  if (await target.loadReplica(candidate.id) != null ||
      (await target.pending(candidate.id)).isNotEmpty) {
    throw StateError('Import target must be empty');
  }
  candidate.apply(pending);
  await target.commit(ReplicaSnapshot.fromReplica(candidate), [
    for (final change in pending.changes)
      OutboxEntry(delta: Delta([change]), recipientPeerId: recipientPeerId),
  ]);
}
```

O chamador garante exclusividade durante essa importação; consulta seguida de
commit não implementa exclusão entre processos. No destino persistente, feche e
reabra o banco, restaure pela engine e confira valores, metadados e IDs antes de
trocar o aplicativo. Preserve export, checkpoint e origem até verificar o novo
fluxo. Uma falha de importação não autoriza apagar ou confirmar a origem.
`MemoryStorage` serve para testes/sessões voláteis; não comprova migração durável.

O importador é uma operação de manutenção da aplicação. Não há novo framework
de migração nem adaptação automática de regras de negócio na biblioteca.
Ao migrar um backend que já implementa `ReplicaStorage`, mantenha o banco e use
os readers existentes; não execute esse importador sobre dados já presentes.

## Formatos, restauração e manutenção

R-39 mantém DeltaCodec v4, snapshot interno v9, ReplicaSnapshot/outbox/envelope
v2 e SQLite schema v1. Os readers anteriores continuam disponíveis: codec v1/v2
com migração explícita e v3/v4; snapshots internos v1 a v9; storage v1/v2;
outbox/envelope v1 com peer/destinatário explícito e v2. Continuam rejeitando
payload inválido, destino ausente e identidade conflitante.

`ReplicaSnapshot.legacy` e `OutboxStatus.confirmed` permanecem depreciados para
compatibilidade de dados/adaptadores. Não são outro caminho operacional de sync.
O writer de snapshot continua canônico; converta um wrapper antigo por restauração
antes de escrever. ACK continua removendo somente IDs confirmados pelo peer.
Nenhum join, tombstone, contexto causal ou dado persistido foi descartado.

| Regra | Ponto de manutenção |
|---|---|
| DTO e conversão de operação antiga | Core, `src/operation.dart`, usado somente pelos readers de delta e snapshot |
| Seleção da versão do delta | Core, `DeltaCodec`; `Delta.fromJson` valida/converte payload |
| Estado, mutação, delta e join dos oito tipos | Core, `Replica` e cada CRDT; não mudaram com a remoção das APIs |
| Candidata, commit e adoção | Sync, `SyncEngine` e `ReplicaPersistence`; agora um caminho obrigatório de storage |
| Snapshot/outbox e transação | Contrato `ReplicaStorage`; implementação no backend escolhido |
| Restauração de wrapper antigo | Sync, `ReplicaPersistence`, e readers públicos de storage/core |
| Seleção por peer, tentativas e ACK | `OutboundSync` e `ReplicaStorage`; envio fora da fila de commits |

Não copie o parser histórico para o aplicativo. A remoção do export não altera
o reader usado por `DeltaCodec` ou `Replica.fromSnapshotJson`.

## Rollback

Antes do upgrade, feche conexões e preserve um backup consistente do backend,
incluindo seu procedimento para WAL. Arquive código, versões, checkpoint e
exports. Não copie apenas o arquivo principal de um SQLite em uso.

A referência 1.0.0 fixada em R-30 lê os mesmos formatos desta tarefa. A prova
executa três processos sobre o mesmo SQLite: biblioteca antiga grava; atual
restaura, edita e recebe ACK parcial; antiga reabre e verifica dados novos,
45 pendências e isolamento das 23 entradas do outro peer. Isso valida rollback
de biblioteca para essa revisão, sem restaurar um backup que apagaria edições.

Pare e feche a instância atual antes de voltar ao código anterior. Recompile o
consumidor para a API escolhida e mantenha a mesma identidade e banco. Nunca
execute simultaneamente versões com a mesma identidade de réplica. Aplicativos
que usavam somente `PendingDeltaStore` precisam manter o adaptador `ReplicaStorage`
na versão de rollback ou exportar também o estado novo e suas pendências. Voltar
apenas ao store antigo não transporta automaticamente dados gravados no SQLite.

Leitores anteriores a essa referência podem não entender formatos causais mais
recentes, como o contexto MV compacto. Nenhuma garantia adicional de downgrade
foi introduzida. Outras tarefas desta release ainda exigem VAL-17 antes da
distribuição; R-39 não certifica antecipadamente seus formatos ou artefatos.

## Prova reproduzível

Na raiz, com dependências do SDK de referência disponíveis no cache:

```sh
python3 plan/evidence/r39/validate.py --dart dart --report /tmp/r39-validation.json
```

O script preserva os fontes/dados congelados de R-30, testa o consumidor antigo
com sua revisão, exige falha de compilação das APIs removidas na árvore atual,
analisa/testa o consumidor migrado fora do workspace e verifica rollback SQLite.
Compara também os sete inventários de API com uma lista explícita de remoções.
Usa dependências por path e resolução offline própria; não prova publicação
hosted, execução Android ou SDK mínimo. As evidências e limites reais da execução
ficam no [registro R-39](../plan/TRACEABILITY.md#execucao-r-39-2026-10-24).
