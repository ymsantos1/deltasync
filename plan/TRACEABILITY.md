# Rastreabilidade e evidências

Baseline histórica: 2026-09-27. Fontes: [PDF](<../referencia/Proposta TCC.pdf>),
[contexto](../proposta.md) e inspeção/testes da revisão anterior.
A reorganização documental não reexecutou testes Dart nem corrigiu código.

Planejamento inicial de 1.0.1: [registro de 2026-10-24](#planejamento-1-0-1-2026-10-24).
Escopo vigente: [todos os pontos na mesma 1.0.1](#escopo-integral-1-0-1-2026-10-24),
conforme esclarecimento posterior do autor que substituiu o adiamento por versões.
R-30 [concluiu a baseline e o mapa de migração](#execucao-r-30-2026-10-24).
R-31 [concluiu a correção da outbox](#execucao-r-31-2026-10-24).
R-39 [concluiu remoções com migração e rollback](#execucao-r-39-2026-10-24).
R-32 [concluiu medição de custos e encaminhamento](#execucao-r-32-2026-10-24).
R-37 [concluiu consulta leve de pendências](#execucao-r-37-2026-10-24).
R-38 [concluiu lote local atômico](#execucao-r-38-2026-10-24).
R-33/R-41/R-42 estão prontas; nenhuma tarefa ativa. Os registros abaixo
preservam as baselines e conclusões nas datas em que foram obtidas.

Estado atual — 2026-10-13: a [revisão técnica](#revisao-tecnica-2026-10-11)
confirmou três defeitos apesar de 155 testes aprovados.
[R-10](#execucao-r-10-2026-10-12),
[R-11](#execucao-r-11-2026-10-12) e
[R-12](#execucao-r-12-2026-10-12) foram concluídas.
[VAL-05](#execucao-val-05-revalidacao-2026-10-12) revalidou o gate técnico após
as correções mais recentes;
[VAL-07](#execucao-val-07-2026-10-12-mobile) concluiu a evidência mobile SHOULD
no Moto G52 Android 13, com plugin sqflite e reinícios reais de processo.
Esta [manutenção MoSCoW](#manutencao-moscow-2026-10-11) não corrigiu o produto.
A [revisão geral posterior](#revisao-geral-2026-10-12) confirmou novos defeitos;
[R-13](#execucao-r-13-2026-10-12), [R-14](#execucao-r-14-2026-10-12),
[R-15](#execucao-r-15-2026-10-12) e [R-18](#execucao-r-18-2026-10-12) foram
concluídas; [R-16](#execucao-r-16-2026-10-12) concluiu a reorganização SHOULD,
e [VAL-08](#execucao-val-08-2026-10-12) executou a demo interativa no Android.
VAL-05 revalidou o gate técnico após correções e refatoração. O autor informou
entrega em 16/11 e pediu [planejamento das correções/refatoração](#manutencao-revisao-refatoracao-2026-10-12).
A [referência C++](#referencia-delta-cpp-2026-10-12) orientou VAL-09/VAL-10 e
R-19 COULD; VAL-09/VAL-10 concluíram. O adiamento anterior foi superado pela
[confirmação de prazo e planejamento R-19](#planejamento-r-19-2026-10-12).
[R-19 concluiu](#execucao-r-19-2026-10-12) compactação causal, compatibilidade,
recuperação SQLite, medição, revalidação VAL-05 e consumidor Android.
[R-20 concluiu](#execucao-r-20-2026-10-13) a refatoração estrutural autorizada,
consolidando ownership e percursos repetidos, com revalidação técnica. Seu build
Flutter passou; runtime Android novo não foi executado, sem dispositivo conectado.
A [revisão e manutenção de 2026-10-13](#manutencao-ajustes-consumidor-2026-10-13)
acrescentou R-21 SHOULD e R-22 COULD prontas; VAL-11/12/13 SHOULD planejadas para
histórias variadas, Android atualizado e integração externa com rede real.
Naquela manutenção, próxima recomendada era R-21. Planejamento não executou essas tarefas; publicação
permanece com o autor.

R-21 [concluiu em 2026-10-13](#execucao-r-21-2026-10-13): validação MV sem expansão,
percurso JSON compartilhado e consulta pontual, com 211 testes Dart e quatro Flutter
aprovados. VAL-11 foi liberada; autor autorizou executar a próxima ação após R-21.
VAL-11 [concluiu](#execucao-val-11-2026-10-13) oito histórias e 32 permutações,
com três sementes duráveis SQLite. Encontrou divergência G-Set, corrigida como
[R-23 MUST](#execucao-r-23-2026-10-13). Gate revalidado: 224 testes Dart e quatro
Flutter. VAL-12 [concluiu](#execucao-val-12-2026-10-13) o runtime atualizado no
Moto G52/API 33, com plugin sqflite e dois reinícios reais. Após a
[tentativa VAL-13](#tentativa-val-13-2026-10-13), autor forneceu Compass;
[VAL-13 concluiu](#execucao-val-13-2026-10-13) notas de viagem no app externo,
SQLite e HTTP/TCP entre Android e servidor Dart, com 72 testes app/13 servidor.
R-22 COULD é opcional; sua preparação atual está registrada abaixo. Publicação permanece com o autor.

[R-24](#execucao-r-24-2026-10-13)/[R-25](#execucao-r-25-2026-10-13)
centralizaram ACK e consulta; [VAL-14](#execucao-val-14-2026-10-13) concluiu guia,
revalidação do workspace e runtime Android das APIs atuais.
O [fechamento atual](#execucao-val-05-ergonomia-2026-10-13)
concluiu VAL-05. [R-26](#execucao-r-26-2026-10-13) concluiu recepção/ACK comuns;
[R-27](#execucao-r-27-2026-10-13) concluiu acompanhamento
da sessão. A [preparação R-22](#preparacao-r-22-2026-10-13) compartilhou o enlace dos exemplos;
a [preparação VAL-15](#preparacao-val-15-2026-10-13) configurou clientes/hub e gerou APKs.
Após a [execução R-22](#execucao-r-22-2026-10-13), R-22 concluiu também o runtime Android.
[VAL-15](#execucao-val-15-2026-10-13) concluiu runtime em dois aparelhos físicos,
com hub HTTP/SQLite e ACK isolado. [VAL-16](#execucao-val-16-2026-10-13) concluiu
os oito CRDTs em peers Android diretos, inclusive MV concorrente/resolução/replay.
Todas as tarefas atuais concluídas; nenhuma tarefa ativa.

## Panorama da análise inicial — 2026-10-03 (histórico)

Este panorama registra o estado inspecionado antes de R-09a/R-09b/R-05 e da
integração dos tipos restantes; não descreve estado atual. Revisão completa em
[análise da arquitetura](../docs/analise-arquitetura.md).
Autor manteve oito CRDTs e adaptador SQLite; autorizou atualização documental
para consolidar estrutura antes da expansão. Implementação das correções pendente.

| Área | Evidência atual | Trabalho restante |
|---|---|---|
| Core | LWW/G/PN integrados por endereço; caminho legado e CrdtOperation ainda exportados | R-09a consolida contratos, compatibilidade e validação nativa |
| Estado/storage | Commit e snapshot versionado em MemoryStorage; valores aninhados e referência de réplica escapam do isolamento | R-09b unifica estado/snapshot/outbox e protege escrita/valores |
| Lifecycle/fila | Mutação antes de start perde snapshot; envio bloqueia fila e duas engines simultâneas | R-05 corrige lifecycle, observabilidade e espera de rede |
| Mensagem/confirmação | DeltaEnvelope fora do fluxo; testes de ACK devolvem IDs sem segunda engine | R-08a/R-08b definem fluxo; R-08d comprova três tipos com duas engines |
| Persistência durável | Adaptador SQLite ausente; restauração em memória é simulação | R-07b/R-07c/R-07d validam contrato e recuperação real |
| Tipos restantes | G-Set, 2P-Set, MV-Register, OR-Set e OR-Map ausentes | Cada R-06 inclui integração; R-07a consolida oito tipos e SQLite |
| Consumo/manutenção | Aplicativo real demonstra consumo; Compass é exemplo opcional. Integração, usabilidade e facilidade de forks ainda sem evidência | R-08d exercita API pública; VAL-02 aceita consumidor geral e VAL-04 orienta alterações |

55 testes aprovados durante análise inicial: raiz 2, core 26, sync 19,
storage 6 e transport 2; análises sem issues em Dart 3.13.0/Linux x64.
Diagnósticos adicionais reproduziram F-01 a F-06, vínculo de tipos inconsistente,
perda da fonte de tempo injetada e validação de ID divergente após restauração.
Não foi executado benchmark nem comprovada durabilidade. Essas evidências
antecedem manutenção documental e não representam execução de R-09a/R-09b/R-08d.

R-01 a R-04 mantêm registros de entregas anteriores. Garantias gerais da base
continuam incompletas até tarefas sucessoras e integração aprovadas.

## Estado verificado na baseline histórica — 2026-09-27

“Implementado” indica código e testes existentes, não conclusão da validação
acadêmica. “Parcial” não satisfaz o gate de entrega.

| Requisito | Implementação/evidência | Estado e lacuna |
|---|---|---|
| Arquitetura modular | `pubspec.yaml`, `lib/deltasync.dart`, quatro subpacotes | Implementada; sem Flutter/banco/rede no core |
| Identidade e clocks | `packages/deltasync_core/lib/src/identity.dart`, `hlc.dart`, `vector_clock.dart` | Tipos implementados; lifecycle durável e lacunas causais pendentes |
| Contrato DeltaCrdt | `packages/deltasync_core/lib/src/crdt.dart` | Implementado; mutação específica por tipo |
| LWW nativo | `lww_register.dart`, `lww_delta.dart`, `Replica.setDelta/removeDelta` | HLC e tombstone implementados; caminho legado ainda ativo |
| G-Counter e PN-Counter | `g_counter.dart`, `pn_counter.dart`, `replica.dart`, `sync_engine.dart` | Roteados por endereço estável; sequência local e restore persistidos no JSON do contador |
| Cinco CRDTs restantes | Sem classes correspondentes | Pendentes |
| Serialização de deltas | `delta.dart`, `delta_codec.dart` | LWW e counters; codec v2 lê v1 com endereço legado; snapshot sem versão própria |
| Envelopes | `packages/deltasync_transport/lib/src/delta_envelope.dart` | Versão 1; transporte/sync ainda usam Delta diretamente |
| Storage | `packages/deltasync_storage/lib/src/replica_storage.dart` | MemoryStorage volátil; sem transação de estado + outbox |
| Recuperação | `packages/deltasync_sync/lib/src/sync_engine.dart`, teste de restauração | Simulada reutilizando MemoryStorage; não prova reinício de processo |
| ACK e retry | SyncEngine, OutboxStatus, SyncRetryPolicy | Parciais; caminho legado limpa fila após send; ACK parcial perde lote |
| Reconciliação | push da outbox e recepção por stream | Parcial; sem recuperação de histórico para peer ausente |
| Demonstração | `example/deltasync_example.dart` | Exemplo Dart local/legado; sem duas réplicas persistentes |
| Validação acadêmica | Testes dos pacotes e facade | Parcial; faltam cinco tipos, falhas, durabilidade e propriedades completas |

Nomes de arquivos do core sem prefixo na tabela pertencem a
`packages/deltasync_core/lib/src/`. As demais camadas estão identificadas pelos
respectivos pacotes.

### Validação executada em 2026-09-27

Dart SDK 3.13.0. `dart analyze` sem issues na raiz e nos quatro subpacotes.
`dart test`: raiz 2, core 20, sync 11, storage 3, transport 2; total 38 testes
aprovados. A suíte atual cobre exemplos finitos, não todas as propriedades do
escopo final. Executar apenas testes da raiz cobre somente dois testes.

Diagnósticos adicionais, fora da suíte, reproduziram:

1. Operações legadas com clocks `z={z:1}`, `a={z:1,a:1}`, `m={m:1}`,
   aplicadas em ordens `[z,a,m]` e `[a,m,z]`, terminam com valores `m` e `z`.
   `Operation.compareTo` combina ordem causal e desempate por ID sem garantir
   transitividade. Caminho legado não pode ser referência de convergência.
2. `Replica.apply` de GCounterDelta lança
   `FormatException: Unsupported CRDT delta type`; codec suportar counters não
   significa integração completa.
3. ACK de apenas uma mudança em lote de duas remove a entrada inteira em
   `MemoryStorage.acknowledge`. A mudança não confirmada perde retry.
4. `ReplicaState.copy()` compartilha registradores; mutação posterior no original
   altera o valor observado na cópia. Não serve como isolamento para rollback.
5. Dois GCounter da mesma réplica geram `device:g-counter:1` na primeira mutação;
   `Delta.merge` reduz os dois deltas a um. Faltam endereço do CRDT e identidade
   de alteração sem colisão entre instâncias.

Outros riscos confirmados por inspeção: mutação em memória antes do commit,
`enqueue` e `saveReplica` separados, callback remoto assíncrono sem fila de
processamento/erro explícito, histórico completo em
`snapshot.metadata['delta']`, API de mutação sem guarda de lifecycle e contador
máximo por réplica sem representação explícita de lacunas.

## Requisitos e tarefas

| Requisito/origem | Tarefas | Componentes e validação necessária |
|---|---|---|
| DeltaCrdt e LWW, PDF §§6.2/6.5 | R-01, R-09a, R-10 | contrato nativo, LwwRegister, Replica; coleções tipadas, compatibilidade explícita e join |
| Identidade/dots e roteamento, PDF §§6.4/6.5 | R-02, R-09a, R-09b | metadados comuns, vínculo por endereço/tipo e contexto adequado |
| Confirmação/outbox, PDF §6.6 | R-03, R-09b, R-08b, R-08d | outbox por mudança, ACK parcial, retry e destino definido |
| Persistência consistente, PDF §6.6 | R-04, R-09b, R-07b, R-07c, R-07d, R-11 | snapshot canônico, isolamento, contrato, SQLite real, conflito de ID e falhas |
| Continuidade do sync, PDF §§6.5/6.9 | R-05, R-08d, R-08c, R-12 | lifecycle/fila; duas engines, edição durante envio, retry de abertura e reconexão |
| G-Set, 2P-Set, MV-Register, OR-Set, OR-Map, PDF §6.2 | R-06a, R-06b, R-06c, R-06d, R-06e | novos tipos no core; operações, deltas, join e restauração |
| Integração/JSON, PDF §§6.5/6.8 | R-06a, R-06b, R-06c, R-06d, R-06e, R-07a, R-08a | integração individual e conjunto de oito tipos com SQLite |
| Testes, PDF §6.9 | VAL-01, R-07d, R-08c | propriedades, regressão, integração e recuperação real |
| Demonstração, contexto atual | VAL-02 | consumidor real, dois tipos, SQLite, duas réplicas, integração e experiência offline; Compass é exemplo opcional |
| Simplicidade, manutenção e forks, orientação do autor | R-09a, R-09b, R-05, R-08d, VAL-04 | responsabilidades localizáveis, API pública, percurso de alteração e compatibilidade |
| Matriz e fechamento técnico | VAL-03, VAL-04, VAL-05 | evidência por requisito, arquitetura/API e gate técnico da biblioteca |
| Motivação incremental, SHOULD | VAL-06 | comparação reproduzível de bytes de delta/estado |
| Integração Flutter/sqflite mobile, SHOULD | VAL-07 | build/runtime, reinício de processo e reconciliação executados no Moto G52 Android 13/API 33 |
| Correção de metadados/restauração, revisão de 2026-10-12 | R-13, R-14 | R-13 concluída com regressões Set/Map; R-14 concluída com regressões core/SQLite |
| Recuperação do consumidor e contrato preciso de retry | R-15, R-18 | R-15 concluída com regressão Flutter FFI e percurso Android; R-18 documentou agendamento pelo consumidor, backoff e limites |
| Organização e evolução da demonstração, pedido do autor | R-16, VAL-08 | R-16 concluiu inventário/extrações; VAL-08 executou UI interativa, conflito, retry e dois reinícios no Moto G52 |
| Validação ampliada e limites de custo | VAL-09, VAL-10 | Ambas concluídas; VAL-10 mede cargas contrastantes e documenta custo/contexto e limites |
| Compactação causal após evidência de custo, referência C++ | R-19 | COULD concluída; VAL-09/VAL-10 passaram, margem confirmada em DEC-33 e compactação/compatibilidade/recuperação/ganho medidos em [execução R-19](#execucao-r-19-2026-10-12) |
| Notificação pública de commits, COULD | R-17 | `SyncEngine.commits` emite origem local/remota após adoção; sem replay ou semântica de ACK; testes sync/facade e documentação |
| Refatoração geral além das extrações de R-16 | R-20 | SHOULD concluída; estado/cópia/restauração e commits consolidados, componentes independentes, fixture anterior e regressões de ownership; [execução R-20](#execucao-r-20-2026-10-13) |
| Custos redundantes e reuso dos exemplos, revisão de 2026-10-13 | R-21, R-22 | R-21 SHOULD concluída, com redução observada de materialização/travessias; R-22 COULD concluída com suporte compartilhado e provas CLI/Flutter/Android |
| Confiança adicional em testes e consumo externo | VAL-11, VAL-12, VAL-13 | VAL-11 concluiu sementes/permutação/SQLite; VAL-12 concluiu runtime da demo; VAL-13 concluiu notas no Compass externo, HTTP/TCP, SQLite e Android. Limites: par fixo, LWW e ambiente de desenvolvimento |
| Duas instalações físicas e confirmação isolada | VAL-15 | Moto G52/G53 com IDs/bancos próprios e hub HTTP/SQLite; falha offline, edição, reinícios, ACK isolado e vencedor LWW comum comprovados; limites em DEC-48 |
| Oito tipos entre peers Android diretos | VAL-16 | História causal compartilhada, ramos offline, SQLite/outbox, join dos oito, MV com duas versões/resolução e replay idempotente; limites em DEC-49 |
| Ergonomia e percurso de integração | R-24, R-25, VAL-14, VAL-05 | Codec ACK e consulta pontual documentados/testados; guia e comparação de esforço; workspace/Compass revalidados, inclusive Android/SQLite/HTTP no APK atual. VAL-05 concluiu fechamento com fontes/APK/evidências conferidos e regressões focadas |
| Equivalência de mutação/delta G-Set, achado em VAL-11 | R-23 | MUST concluída: adição repetida aplica seleção canônica, com regressão mínima e revalidação completa |

### Matriz final de evidências MUST — revalidada em 2026-10-12

Esta matriz resume implementação e execuções até 2026-10-12; a seção de baseline e
os registros por tarefa abaixo preservam história. Os diagnósticos de 2026-10-11
reabriram o fechamento; R-10/R-11/R-12 corrigiram os três defeitos confirmados.
Os novos achados de 2026-10-12 reabriram VAL-05; a matriz preserva execuções
anteriores e registra R-13/R-14/R-15/R-18. Revalidação final ocorreu após as
correções e a refatoração, com suíte da workspace, demo e Flutter Android.
Evidências distinguem unidade,
integração em processo, recuperação SQLite após fechamento/reabertura e demo
consumidora entre processos. Uma categoria não substitui outra.

- **Unidade/propriedades:** VAL-01 e testes de `packages/deltasync_core/test/`
  e `test/`; R-10 acrescenta coleções LWW tipadas e isolamento de deltas.
- **Integração:** R-08d exercita duas `SyncEngine` ligadas via API pública;
  R-08c combina divergência offline, reordenação, retry e ACK.
- **Recuperação durável:** R-07d, R-07a e R-08c fecham engines/bancos SQLite
  reais, reabrem e verificam snapshot, outbox, tombstones e entrega. R-11 cobre ID
  divergente e rollback; R-12 cobre retry de abertura. Execução Linux
  x64 via FFI; MemoryStorage não conta como recuperação de processo.
- **Demonstração consumidora:** VAL-02 roda `offline` e `reconnect` em processos
  Dart separados; VAL-05 repetiu as duas fases após as correções.
  VAL-07 acrescenta consumidor Flutter com plugin sqflite no Moto G52 Android 13,
  falha de peer, outbox restaurada e ACK persistido após dois reinícios de processo.
  R-15 repete o percurso no Android e testa falha de abertura/retry no Flutter test.

| Requisito MUST | Implementação | Evidência executada | Limite declarado |
|---|---|---|---|
| Oito CRDTs, mutações, deltas e joins | `packages/deltasync_core/lib/src/`; OR-Map compõe G-Set; fachada `lib/deltasync.dart` | Testes por tipo; propriedades VAL-01/VAL-09; lote SQLite de oito tipos R-07a; coleções LWW tipadas e isolamento R-10 | Fixtures algébricas finitas; não constituem prova matemática universal; coleções tipadas exigem `decodeValue` |
| Identidade, dots e roteamento por endereço | `identity.dart`, `replica.dart`, `delta_change.dart`, `vector_clock.dart` | Testes `ReplicaId and Dot round trip and validate identity`, roteamento misto, conflito de endereço/tipo; R-02/R-09a/R-09b/R-07a; R-13 cobre igualdade/hash de clocks em Set/Map | G/PN usam componentes cumulativos; tipos com eventos individuais mantêm contexto explícito |
| JSON, snapshots e restauração | `delta_codec.dart`, `replica.dart`, snapshots canônicos | Testes codec/snapshot core e `sync_recovery_test.dart`; VAL-01/R-07a/R-10; R-14 rejeita sequência MV atrasada em core e SQLite FFI; VAL-05 revalidou os pacotes | Formatos antigos conforme migração documentada; consumidores externos desconhecidos |
| Core independente e contratos modulares | `deltasync_core`, `deltasync_storage`, `deltasync_sync`, `deltasync_transport`, facade | Analyze/test por pacote; integração pública R-08d e VAL-02 | SQLite fica no adaptador; nenhuma dependência de Flutter no core |
| Storage substituível e `MemoryStorage` | `ReplicaStorage`, `MemoryStorage`, suíte `deltasync_storage_testing` | R-07b e contrato testado; `memory_storage_contract_test.dart` | Memória é volátil e não prova restart |
| SQLite, outbox durável e recuperação | `packages/deltasync_storage_sqflite/lib/` | R-07c/R-07d, R-07a (oito tipos), R-08c, R-11 (ID divergente e rollback), R-12 (retry de abertura), VAL-02/VAL-05; VAL-07/R-15 e reabertura atual no Moto G52 Android com sqflite | Linux x64 via FFI; Moto G52 Android 13 com LWW/G-Counter; iOS e outros alvos não executados |
| Transporte abstrato, roteamento e envelopes | `deltasync_transport`; `SyncEngine` e destino por peer | `delta_envelope_test.dart`, R-08a/R-08b/R-08d | Transporte dos cenários é em processo; protocolo de rede não faz parte do recorte |
| ACK explícito, retry sem perda e commit atômico | `SyncEngine`, `ReplicaStorage.commit/commitRemote`, outbox por mudança | Testes de ACK parcial, retry, falhas e transação em sync/storage/SQLite; R-03/R-04/R-05/R-07d/R-08b/R-08c/R-11/R-12 | Só `appliedAndPersisted` do peer destinatário confirma; legado `PendingDeltaStore` conserva itens após ACK |
| Reconciliação offline na topologia declarada | Outbox direcionada e recuperação em `SyncEngine` | R-08c e consumidor VAL-02/VAL-05, com duas réplicas SQLite e processos separados | Peer fixo; peer adicional requer cópia de outbox e confirmação independente |
| Testes unitários, integração, recuperação e regressão | Suítes core, facade, sync, storage, adapter SQLite e transporte | VAL-01 cobre oito tipos; R-07d/R-08c cobrem recuperação SQLite; R-10 a R-15/R-18 acrescentam regressões; VAL-05 repetiu format/analyze/test na raiz e seis pacotes, além dos testes Flutter | Cenários e plataformas estão listados por execução, sem alegação universal |
| Aplicação demonstrativa mínima | `example/offline_reconciliation.dart`, `example/flutter_mobile/`; configuração nos READMEs | VAL-02/VAL-05 executaram offline/reconnect em processos separados; VAL-07/R-15 e VAL-08 cobrem Android; VAL-05 reinstalou, abriu e reiniciou processo Android atual | Transporte sintético e peer fixo; sem participantes, rede real ou avaliação geral de usabilidade |
| Novos contratos e recuperação de falhas | `vector_clock.dart`, `mv_register.dart`, consumidor Flutter e README | Revisão geral de 2026-10-12; R-13 validou Set/Map/JSON; R-14 validou rejeição e retry com banco preservado; R-15 validou retry da UI com SQLite FFI; R-18 alinhou README/comentários ao contrato de push existente; VAL-05 revalidou o conjunto | Falha injetada de abertura não executada no Android |
| Core nativo, snapshot canônico, fila sem espera de rede | `Replica`, `ReplicaState`, `SyncEngine`, `OutboxEntry` | Regressões R-09a/R-09b/R-05; envio lento com commits locais em `sync_engine_test.dart` | Histórico e deduplicação limitados conforme R-09b; sem benchmark de escala |
| Formatos versionados e compatibilidade explícita | `DeltaCodec`, snapshots e codecs de outbox/envelope | Fixtures de migração/rejeição em core/storage/transport; R-09a/R-09b/R-06/R-07a/R-10; R-10 documenta migração de `const LwwDelta` sem alterar wire JSON | Não há inventário de todos consumidores externos (OPEN-07) |

### Topologia, confirmação e retenção

- `DeltaTransport` tem um `peerReplicaId` fixo. Outbox é por réplica/peer;
  não existe broadcast nem bootstrap automático para peer novo. DEC-21 e RISK-08
  registram essa fronteira.
- `send()` concluído não é confirmação remota. ACK `received` também não limpa
  outbox; somente IDs em `appliedAndPersisted` do peer destinatário são removidos.
  ACK parcial mantém restante. `PendingDeltaStore` legado não implementa remoção.
- Tombstones OR-Set/OR-Map e remoções de 2P-Set não têm GC no escopo. Contexto
  causal de MV-Register e metadados observados são retidos; podem crescer.
  `Replica.export()` é bootstrap compacto, não histórico. Deduplicação de IDs
  após restore cobre apenas winner/componente mais recente retido, não histórico
  ilimitado (DEC-06/DEC-18).
- SQLite foi executado com FFI em Linux x64 e plugin sqflite no Moto G52 Android 13
  em VAL-07; iOS e backup em dispositivo não foram avaliados.
  VAL-02 usa transporte sintético e CLI, sem participantes.
  VAL-06 é SHOULD concluída, com medição em 2026-10-07; envelopes somam 1.079 B
  contra 1.255 B de snapshots nesse cenário. VAL-07 limita a evidência mobile ao alvo executado.
  Nenhuma afirmação de desempenho ou redução universal de bytes é feita.

<a id="execucao-val-03-2026-10-06"></a>

## Execução VAL-03 — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: VAL-01, VAL-02, R-07d e R-08c concluídas; VAL-03 era próxima MUST pronta.
Revistos escopo MUST, evidências por tarefa, DEC-06/18/21, riscos, baseline e
limites atuais. Worktree estava limpo; nenhum arquivo editável `.doc`, `.docx`,
`.tex` ou `.odt` do TCC foi encontrado.

Implementação: `TRACEABILITY.md` agora distingue unidade/propriedades, integração
em processo, recuperação SQLite após close/open e demo entre processos. Matriz
liga requisitos MUST a código, testes, tarefas e limites; registra oito tipos,
identidade/dots, codecs/snapshots, storage, SQLite, transporte, ACK, atomicidade,
reconciliação, core canônico e demo. Seção transversal explica peer fixo, ACK
`appliedAndPersisted`, outbox, tombstones/contexto causal, deduplicação limitada,
plataforma testada e ausência de benchmark. Panorama de 2026-10-03 foi rotulado
como histórico. `plan/README.md` agora reflete oito tipos, evidência SQLite atual
e limites pendentes sem repetir baseline como situação presente. Nenhuma alteração
de código foi necessária.

Review: aprovado

Review em etapa distinta pelo mesmo agente, não independente. Achados após primeira
leitura: panorama inicial e riscos do README ainda sugeriam tipos/recuperação como
pendentes; matriz não isolava identidade/dots nem categorias de evidência. Corrigido
e diff revisto. Confirmados links/caminhos, topologia/ACK, retenção e claims; nenhum
ganho de desempenho ou correção universal sem evidência foi encontrado.

Achados: correções documentais descritas acima; sem achados impeditivos restantes.
Fonte editável do texto acadêmico não está no workspace; alinhamento textual segue
VAL-04, sem alterar PDF de referência.

Validação: aprovada

Escopo de validação: documentação somente; nenhuma mudança de código.

`python3 scripts/check_plan.py` passou: 26 tarefas, 109 links locais; `git diff
--check` passou. Integridade da matriz conferida contra os registros R-07a/R-07d/
R-08c/VAL-01/VAL-02, código/testes citados e DEC-06/18/21. Suíte Dart não foi
reexecutada: nenhuma mudança de código; evidências runtime mantidas nos registros
das tarefas correspondentes.

Comandos: `python3 scripts/check_plan.py`; `git diff --check`; `rg` nos arquivos
`plan/README.md`, `plan/TRACEABILITY.md`, `plan/DECISIONS.md`, `plan/RISKS.md`,
`packages/deltasync_core`, `packages/deltasync_sync` e
`packages/deltasync_storage_sqflite` para conferir claims e referências.

Critérios: cada requisito MUST da tabela de escopo tem componente e evidência
correspondente na matriz final. Categorias unitária, integração, recuperação real
e demonstração são separadas. Topologia, ACK, retenção e limites estão explícitos.
Medição VAL-06 segue SHOULD pronta; texto não afirma ganho medido nem correção
universal. Fonte editável para alinhamento do relatório acadêmico não existe no
workspace e pertence a VAL-04, fora dos critérios de conclusão desta tarefa.

Manutenção: critérios VAL-03 marcados; tarefa concluída em fase/índice, fase 5
permanece ativa e tarefa ativa limpa. VAL-04 é próxima MUST pronta; VAL-06 SHOULD
também pronta; VAL-05 continua planejada até VAL-03/VAL-04 concluírem. DECISIONS/
RISKS sem mudança. Checker e `git diff --check` aprovados após manutenção.

Limitações: review não independente. Matriz consolida evidência existente, não
reexecuta integrações; plugins Flutter mobile e backup em dispositivo não
validados; consumidores externos em OPEN-07; teste de usabilidade e benchmark
ausentes; fonte acadêmica editável deve ser fornecida para VAL-04.

## Testes existentes da baseline

- `packages/deltasync_core/test/crdt_interfaces_test.dart`: tipos atuais, HLC,
  identidade, deltas/codec, operações legadas e exemplos de convergência.
- `packages/deltasync_storage/test/replica_storage_test.dart`: snapshots/outbox
  em MemoryStorage; não prova atomicidade ou durabilidade.
- `packages/deltasync_sync/test/sync_engine_test.dart`: caminho local/remoto,
  restauração simulada, ACK completo, retry e dispose.
- `packages/deltasync_transport/test/delta_envelope_test.dart`: envelope/versão.
- `test/deltasync_test.dart`: dois testes da facade.

Comandos da baseline: `dart analyze` e `dart test`, executados separadamente
na raiz e em cada um dos quatro subpacotes. Resultado: análise sem issues e
38 testes aprovados. Diagnósticos adicionais foram execução exploratória fora
da suíte; resultados acima são evidência de falhas ainda abertas.

## Registro de conclusões

Nenhuma tarefa de produto foi concluída por esta migração.

## Execução R-01 — 2026-09-27

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-01 era próxima tarefa pronta, sem dependências; selecionada pelos
critérios de HLC nativo, convergência legada, compatibilidade e documentação.

Implementação: `Operation.compareTo` agora ordena legado por soma exata dos
contadores do `VectorClock` (`BigInt`), depois `replicaId` e `id`. A ordem é total,
transitiva e preserva precedência causal. README documenta semântica e replay;
exemplo usa `setDelta` e aplica `Delta.crdt`. Regressão cobre as seis ordens das
três operações reproduzidas. JSON legado mantém formato; replay pode eleger outro
vencedor que versão antiga. Mistura legado/nativo mantém regra existente:
registrador que recebeu HLC ignora operação legada, sem comparar clocks distintos.

Review: aprovado

Achados: nenhum impeditivo restante. Revisão pelo próprio implementador em etapa separada, não independente; conferidos overflow potencial e precedência causal, com peso em `BigInt`.

Validação: aprovada

Comandos: `dart format packages/deltasync_core/lib/src/operation.dart packages/deltasync_core/test/crdt_interfaces_test.dart example/deltasync_example.dart`; `dart format --output=none --set-exit-if-changed packages/deltasync_core/lib packages/deltasync_core/test`; `(cd packages/deltasync_core && dart analyze && dart test)`; `dart analyze`; `dart test`; `dart analyze example/deltasync_example.dart`; `dart run example/deltasync_example.dart`; `python3 scripts/check_plan.py`; `git diff --check`. Formato aprovado; core analyzer sem issues e 21 testes aprovados; facade analyzer sem issues e 2 testes aprovados; exemplo analisado e executado com saída `{message: edited offline}`; checker passou com 23 tarefas e 77 links locais após restauração do PDF; diff sem erros.
`git diff --check` aprovado.

Critérios: HLC de `setDelta/removeDelta` e aplicação nativa cobertos por testes existentes `Replica native mutations use HLC and converge`, `Replica applies and exports native CRDT deltas`, tombstone, duplicação e codec. Regressão nova demonstra mesmo vencedor nas seis permutações legadas e precedência z antes de a. Compatibilidade JSON/replay, separação HLC/VectorClock e API de exemplo documentadas no README; exemplo atualizado.

Manutenção: R-01 concluída no índice/fase; tarefa ativa limpa; R-03 próxima pronta. Checker aprovado após restauração do PDF. Decisões e riscos não mudaram.

Limitações: revisão não independente; compatibilidade de replay preserva leitura do formato, não vencedor histórico.

## Execução R-03 — 2026-09-28

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-03 estava pronta sem dependências; próxima tarefa selecionável por risco de perda de mudanças. Critérios cobrem ACK parcial, escopo de IDs, envio sem ACK, falha/timeout/reinício, retry e contrato de confirmação.

Implementação: `MemoryStorage.acknowledge` remove somente mudanças confirmadas e regrava remanescentes com status, tentativas e timestamps preservados. `SyncEngine` filtra ACK retornado aos IDs do lote enviado e mantém outbox no caminho sem ACK. `PendingDeltaStore` legado conserva mudanças e retransmite em cada `push`; documentados ausência de limite automático, semântica de `force`, persistência remota exigida para ACK e limite de ACK multi-peer. `OutboxEntry` resolve origem em lote legado sem campo singular. README, contratos, testes de storage/sync e `DECISIONS.md`/`RISKS.md` atualizados.

Review: aprovado

Achados: nenhum impeditivo restante. Review pelo próprio implementador em etapa separada, não independente. Confirmado que ACK de ID fora do envio corrente não limpa entrada deferida; ACK de outra réplica não acessa sua outbox. ACK por peer segue pendente até R-08b, pois contrato atual não mantém confirmação por participante.

Validação: aprovada

Comandos: `dart format packages/deltasync_storage/lib/src/replica_storage.dart packages/deltasync_storage/lib/src/pending_delta_store.dart packages/deltasync_transport/lib/src/delta_transport.dart packages/deltasync_sync/lib/src/sync_engine.dart packages/deltasync_storage/test/replica_storage_test.dart packages/deltasync_sync/test/sync_engine_test.dart`; `dart format --output=none --set-exit-if-changed packages/deltasync_storage/lib packages/deltasync_storage/test packages/deltasync_sync/lib packages/deltasync_sync/test packages/deltasync_transport/lib packages/deltasync_transport/test`; para storage, sync, transport e raiz, `dart analyze && dart test`; após última asserção, `dart format packages/deltasync_sync/test/sync_engine_test.dart && (cd packages/deltasync_sync && dart analyze && dart test) && git diff --check`. Formato aprovado; storage análise limpa/4 testes; sync análise limpa/14 testes; transport análise limpa/2 testes; facade análise limpa/2 testes; última suíte sync repetida e aprovada.

Critérios: ACK parcial legado+nativo preserva restante e metadados, coberto em `replica_storage_test.dart` e `sync_engine_test.dart`; ACK de réplica incorreta não altera outra outbox; ACK fora do lote enviado é ignorado e entrada deferida permanece. Envio sem ACK e falha em `PendingDeltaStore` preservam dado; caminho ReplicaStorage cobre timeout, persistência/reinício e ACK posterior. Testes documentam limite de tentativas automáticas, atraso e `force`. README e contrato de transporte definem ACK como mudança aplicada e persistida duravelmente no destino.

Manutenção: R-03 concluída no índice/fase; R-02 passou a pronta pois dependência R-01 está concluída; tarefa ativa limpa. OPEN-02 mantém apenas identidade/ACK por peer para R-08b; RISK-02 mitigado. Próxima tarefa R-02.

Limitações: `PendingDeltaStore` legado pode reenviar sem limite; várias entregas por peer não têm ACK isolado; `MemoryStorage` continua volátil.

## Execução R-07d — 2026-10-04

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-07c e R-08d concluídas; R-07d era a próxima tarefa pronta. Critérios
cobrem restauração durável, continuidade de identidade/HLC/dots/sequências,
tombstones, interrupções, atomicidade, backup/plataforma e fluxo das duas engines
com os três tipos atuais.

Implementação: adicionada integração SQLite real em
`packages/deltasync_storage_sqflite/test/sync_recovery_test.dart`, usando a API
pública SyncEngine + ReplicaStorage em dois bancos SQLite. Testes recriam engine
após fechar banco, repetem entrega antes/depois do ACK, injetam falhas SQL em
commit local/remoto e verificam envio simultâneo, retry e edição com ACK retido
para LWW/G-Counter/PN-Counter. Não foi necessária alteração na implementação de
produção: commit e recuperação existentes satisfizeram as regressões. README do
adaptador registra plataforma executada e limite Android/iOS; dependências sync e
transport adicionadas somente para testes do pacote.

Review: aprovado

Achados: um import redundante e uma asserção insuficiente no harness foram
removidos/corrigidos antes da revisão final. Conferidos fluxo real de close/open,
ACK por IDs, atomicidade SQLite, IDs/dots após restore e os três tipos nas duas
réplicas. Também conferido close/open do receptor após commit remoto sem ACK.
Review pelo próprio implementador; não independente.

Validação: aprovada

Comandos: na raiz, `dart format packages/deltasync_storage_sqflite/test/sync_recovery_test.dart`;
para `.`, `packages/deltasync_core`, `packages/deltasync_sync`,
`packages/deltasync_storage`, `packages/deltasync_storage_testing`,
`packages/deltasync_storage_sqflite` e `packages/deltasync_transport`,
`dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test`;
`git diff --check`. Após remover import redundante, raiz e adaptador foram
reanalisados e retestados; após ampliar o cenário integrado para três tipos,
adaptador foi novamente formatado, analisado e testado; cenário de ACK perdido
repetido com fechamento/reabertura do receptor. Resultado final: formato
aprovado; análise sem issues; 112 testes aprovados no workspace (raiz 2, core 39,
sync 35, storage 12, storage_testing 6, SQLite FFI 12, transport 6); testes finais
repetidos na raiz e no adaptador passaram; diff sem erros. Plataforma real:
Linux 7.2.7-zen1-1-zen x86_64, SQLite nativo por sqflite_common_ffi.

Critérios: reabertura compara identidade, estado, tombstone, pendências, HLC
não regressivo e continuação de dots; retry após falha pré-entrega e após commit
remoto sem ACK confirma recuperação e deduplicação. Trigger de outbox prova que
falha local mantém estado persistido/ativo sem outbox parcial; trigger remoto
prova que falha de commit não confirma outbox do remetente. Duas engines SQLite
trocam LWW e counters nas duas direções, retêm uma edição durante ACK pendente e
convergem após retry; a aplicação remota também sobrevive a close/open antes do
retry idempotente. README documenta fechamento/cópia com WAL/SHM ou backup API,
preservação de IDs e plataforma coberta/não coberta.

Manutenção: critérios R-07d marcados; fase 3 concluída; índice sincronizado e fase
2 ativa com tarefa ativa vazia e R-06a como próxima pronta. DECISIONS/RISKS não
mudaram. Checker e `git diff --check` executados após esta manutenção.

Limitações: integração usa transporte em processo para controlar pontos de falha;
ambos os storages usam SQLite real, mas plugins Flutter Android/iOS não foram
executados. Backup é instruído, não testado como operação do consumidor.

## Execução R-02 — 2026-09-28

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-02 selecionada após R-01/R-03; cobre identidade/endereço estável,
roteamento dos counters existentes, lote atômico, compatibilidade do codec e
lacunas causais.

Implementação: dots e IDs de G-Counter/PN-Counter agora usam endereço estável e
sequência local do CRDT; `Replica` roteia LWW e counters, oferece mutações
endereçadas e rejeita lotes inválidos antes de aplicar qualquer item. Delta merge
rejeita ID repetido com payload divergente. Codec v2 escreve endereço e lê v1
atribuindo namespace `legacy/`; OutboxEntry e SyncEngine encaminham counters.
Snapshots do contador guardam a sequência local. Estados cumulativos G/PN toleram
lacunas; tipos futuros dependentes de dots individuais exigem contexto com
lacunas explícitas ou entrega causal. README registra API/compatibilidade.

Review: aprovado

Achados: nenhum impeditivo restante. Review em etapa separada pelo próprio
implementador, não independente. Conferidos colisão entre campos,
origem/endereço/tipo, semântica de ID duplicado, migração v1 e pré-validação do
lote antes de mutar estado.

Validação: aprovada

Comandos: Dart SDK 3.13.0; `dart format` nos arquivos Dart editados; na raiz e
nos quatro subpacotes, `dart analyze && dart test`; após manutenção,
`python3 scripts/check_plan.py` e `git diff --check`. Resultado: formato
aprovado (um arquivo formatado); análise sem issues; raiz 2, core 24, sync 15,
storage 5, transport 2, total 48 testes aprovados; checker e diff sem erros.

Critérios: testes em `crdt_interfaces_test.dart` cobrem dois G-Counters no mesmo
replica, lote LWW/G/PN misto, codec v2/restauração de sequência, migração v1,
ID conflitante e rejeição atômica de delta inválido. `replica_storage_test.dart`
verifica origem de outbox e origem mista inválida; `sync_engine_test.dart` cobre
roteamento e restauração dos counters.

Manutenção: R-02 concluída no índice/fase; tarefa ativa limpa. R-04, R-06a/b/c/d
e R-08a prontas. OPEN-01 resolvida. RISK-03 mitigado; lacunas em tipos futuros seguem
registradas em DECISIONS/RISK-07.

Limitações: API direta dos construtores de GCounter/PnCounter passa a exigir
`crdtId`; migração v1 atribui endereço legado sintético, sem recuperar distinção
de instâncias já colapsadas por IDs antigos. Codec de snapshots não é versionado.

Ao concluir uma tarefa, adicionar registro com:

- ID, data e requisito/critério coberto.
- Arquivos e testes reais; apontar quais casos demonstram comportamento.
- Comando exato, ambiente/plataforma e resultado.
- Review realizado e achados resolvidos ou limitações explicitadas.
- Evidência ausente; impedimento, quando aplicável.

Manter baseline histórica; adicionar nova evidência sem substituir silenciosamente
resultados antigos. Falha também é evidência e não permite marcar conclusão.

## Execução R-04 — 2026-10-01

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-04 selecionada após R-02/R-03; critérios de commit, rollback isolado,
serialização e snapshots compactos identificados.

Implementação: `ReplicaStorage.commit` grava snapshot+outbox e `commitRemote`
substitui snapshot remoto; `MemoryStorage` valida tudo antes de publicar. `SyncEngine`
aplica mutações/remotos em réplica candidata, persiste antes de adotar e serializa
mutações, merges e push. Snapshots formato 1 restauram identidade, relógios,
sequências, vencedores LWW/tombstones e componentes de G/PN-Counter; leitura
continua compatível com snapshots antigos via `metadata['delta']`. `ReplicaState.copy()`
faz cópia profunda de registradores LWW. README documenta contrato e quebra exigida
para adaptadores externos.

Review: aprovado

Achados: revisão em etapa distinta pelo próprio implementador, não independente.
Auxiliar sem uso removido antes da validação. Sem achado impeditivo restante.
`applyRemote` torna commit remoto aguardável e não adota estado em caso de falha;
observabilidade de erro do listener segue R-05.

Validação: aprovada

Comandos: Dart SDK 3.13.0; `dart format` nos sete arquivos Dart editados; `dart
format --output=none --set-exit-if-changed packages/deltasync_core/lib
packages/deltasync_core/test packages/deltasync_storage/lib
packages/deltasync_storage/test packages/deltasync_sync/lib
packages/deltasync_sync/test`; `for package in . packages/deltasync_core
packages/deltasync_sync packages/deltasync_storage packages/deltasync_transport;
do (cd "$package" && dart analyze && dart test) || exit 1; done`; `git diff
--check`; após manutenção, `python3 scripts/check_plan.py` e `git diff --check`.
Todos passaram: raiz 2, core 26, sync 18, storage 6, transport 2 testes; análises
sem issues. Após acrescentar migração legado, sync revalidado: análise limpa e
19 testes aprovados.

Critérios: testes core verificam isolamento LWW, snapshot com tombstone/HLC e
sequências de counters, rejeição de versão incompatível. Storage verifica validação
pré-publicação. Sync verifica falha local/remota sem alteração da réplica/outbox,
migração de snapshot legado, concorrência de 12 mutações e restauração
snapshot/outbox. MemoryStorage valida
contrato, não durabilidade entre processos.

Manutenção: R-04 concluída no índice/fase; tarefa ativa limpa; R-05 agora pronta.
DEC-05 implementada em contrato e MemoryStorage; risco de persistência durável
permanece para R-07c/R-07d. R-04 encerra mitigação de atomicidade em SyncEngine.

Limitações: `ReplicaStorage` exige `commit` e `commitRemote`, quebra fonte para
adaptadores externos até implementarem ambos. Snapshots novos são compactos, mas
`Replica.export()` após restauração contém histórico desde a restauração, não log
anterior completo. MemoryStorage é volátil. Erros de callback do stream serão
expostos/resolvidos em R-05.

## Verificação da migração documental — 2026-09-27

- Review do conteúdo: critérios da refatoração preservados e tarefas agrupadas
  desmembradas; requisitos acadêmicos e extensões mantêm distinção explícita.
- Cinco skills verificadas com
  `python3 /home/yago/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/NOME`:
  frontmatter e instruções aprovados para cada diretório real.
- Checagem estrutural com script temporário executado via
  `node /tmp/deltasync-plan-structure-Wnod9X/validate.cjs`: 17 arquivos Markdown,
  links/anchors válidos, 23 IDs únicos, índice consistente, dependências sem ciclos
  e todos os MUST alcançáveis pelo gate VAL-05; VAL-06 não bloqueia gate.
- `git diff --check` aprovado. Nenhuma mudança em Dart, dependências ou PDF;
  suíte de código não reexecutada nesta migração.

## Verificação do fluxo de execução — 2026-09-27

Criados plan-executor, RUNBOOK e scripts/check_plan.py a pedido do autor, para
aplicar cinco procedimentos por tarefa e controlar fechamento do plano.
Nenhuma tarefa de produto iniciada ou concluída nesta criação do fluxo.

- Review: ciclo distingue consulta de implementação, respeita escopo por tarefa/
  fase e exige revisão das correções, validação e manutenção antes de conclusão.
  Checker somente lê; registros estruturais não certificam qualidade do código.
- `python3 scripts/check_plan.py`: plano consistente, 23 tarefas e 76 links
  locais; R-01 e R-03 prontas. moscow.md restaurado foi preservado.
- `python3 /tmp/deltasync-executor-check-nDKdhG/test_checker.py`: 12 cenários em
  cópias temporárias aprovados. Incluem leitura sem escrita, registro completo,
  conclusão prematura, review/validação/skill ausentes, ciclo, dependência
  desconhecida, duas tarefas ativas, gate prematuro e link ausente.
- Validador skill-creator aprovado nos seis diretórios de skills.
- `git diff --check` aprovado; código Dart e suíte do produto preservados.

## Revisão do planejamento e simplificação — 2026-10-03

Pedido: salvar observações sobre limpeza do core na análise e atualizar planos,
preservando oito CRDTs e escopo acadêmico. Manutenção documental autorizada;
implementação das tarefas novas não iniciada.

Skills: plan-reader, code-reviewer, plan-validator, plan-maintainer.

Leitura: análise, fases, índice, decisões, riscos, evidências e checker consultados;
alterações já existentes no worktree preservadas. R-01 a R-04 conservam histórico;
achados novos exigem correções sucessoras antes da expansão.

Alterações documentais: análise ampliada com limpeza de classes/contratos, critérios
de compreensão e decisão do autor sobre proposta. R-09a/R-09b adicionadas à fase 1;
R-05 inclui rede fora da fila e lifecycle; R-08d exige duas engines e três tipos
atuais. Dependências das cinco implementações restantes e storage passam por
R-08d; R-07a consolida oito tipos e recuperação SQLite. DEC-12 a DEC-14 e RISK-13
a RISK-16 registram direção e falhas; panorama atual separado da baseline histórica.

Review documental: aprovado pelo mesmo agente, em etapa separada; sem revisão
independente. Diff revisado quanto a escopo, compatibilidade, sequência de entregas,
dependências e preservação de registros históricos. Nenhuma tarefa nova concluída.

Validação documental: aprovada. `python3 scripts/check_plan.py`: 26 tarefas,
86 links locais, IDs/dependências/status e frontmatter consistentes; somente R-09a
pronta. `git diff --check`: aprovado. Verificação adicional de links/anchors da
análise via Python: 15 links válidos e ausência de espaços finais. Comparação
SHA-256 dos 46 arquivos protegidos antes/depois confirmou preservação de fontes
Dart, testes, proposta, instruções, skills, pubspecs, README da raiz e checker.

Limitações: aprovação documental não corrige F-01 a F-06, não prova durabilidade
nem confirma prazo. Resultados Dart acima pertencem à análise inicial; nenhuma
suíte Dart executada nesta manutenção. Código, proposta, skills e checker preservados.

## Orientações de uso real e manutenção — 2026-10-03

Pedido: aplicar ao planejamento facilidade de integração, uso real no Compass e
código compreensível para manutenção, contribuição e forks; orientação permanente
para agentes. Atualização documental autorizada, sem execução de tarefa de produto.

Skills: plan-reader, plan-maintainer, code-reviewer, plan-validator.

Leitura: AGENTS.md, índice, tarefas afetadas, RUNBOOK, decisões, riscos e análise;
worktree inspecionado e alterações anteriores preservadas.

Alterações: orientações transversais em AGENTS.md e referência no índice/RUNBOOK;
DEC-15, OPEN-08 e RISK-17; R-09a explica pontos de alteração, R-05 diferencia
resultados públicos, R-08d exercita consumo e VAL-02 usa Compass. VAL-04 documenta
percurso de manutenção; VAL-05 exige evidências correspondentes. Análise e matriz
atualizadas, sem novos IDs de tarefas ou mudança de status. VAL-04 passou a depender
de VAL-02 para que relato do Compass use resultados efetivamente obtidos.

Review documental: aprovado pelo mesmo agente, em etapa separada; sem revisão
independente. Comparação com conteúdo anterior ao pedido confirmou escopo das
edições. Dependência VAL-04/VAL-02 corrigida; adaptações de domínio distinguidas
de duplicação da lógica de sync para contornar contrato. Nenhuma tarefa de produto
iniciada ou concluída; R-09a permanece próxima tarefa pronta.

Validação documental: aprovada. `python3 scripts/check_plan.py`: 26 tarefas,
88 links locais, IDs/dependências/status/frontmatter consistentes. `git diff
--check`: aprovado. Verificação adicional via Python: análise com 16 links/anchors
válidos e sem espaços finais. Comparação SHA-256 de 45 arquivos protegidos
antes/depois confirmou fontes Dart, testes, exemplos, proposta, README da raiz,
pubspecs, skills e checker sem alterações nesta manutenção. AGENTS.md foi alterado
conforme pedido; nenhuma suíte Dart executada nesta etapa documental.

Limitações: Compass ainda sem checkout/versão/plataforma/cenário identificado;
nenhuma integração, avaliação de usuários ou facilidade de forks comprovada nesta
manutenção. Oito CRDTs e SQLite preservados; código e proposta sem alterações.

## Limite do Compass na arquitetura — 2026-10-03

Pedido: manter Compass apenas como exemplo de consumo real, sem direcionar
implementação/gate. Aplicativos consumidores adaptam modelos e fluxos à API pública
da biblioteca; DeltaSync não recebe customizações específicas do Compass. Mudanças
na biblioteca dependem de requisito geral do escopo ou defeito confirmado.

Skills: plan-reader, code-reviewer, plan-validator, plan-maintainer.

Leitura: AGENTS.md atual, índice, tarefas afetadas, decisões, riscos, análise e
registros anteriores; alterações preexistentes no worktree foram preservadas.

Alterações: AGENTS.md, README do plano, R-08d, VAL-02/04/05, DEC-15, RISK-17,
análise e rastreabilidade. Compass tornou-se exemplo opcional, com adaptação no
app; VAL-02 exige demonstrar consumidor, sem fazer dele requisito do gate. Oito
CRDTs e SQLite continuam avaliados independentemente do Compass. DEC-15 registra
quando justificar mudança na biblioteca; removido OPEN-08. Sem status/tarefas novos.

Consumidor usa contrato público, composição e adaptadores próprios; sem override de
implementações internas ou plugins genéricos.

Review documental: aprovado pelo mesmo agente, etapa separada; sem revisão
independente. Registros anteriores foram mantidos como histórico e direção corrente
acrescentada acima.

Validação documental: aprovada. `python3 scripts/check_plan.py`: 26 tarefas,
88 links locais, IDs/dependências/status/frontmatter consistentes; R-09a segue
única tarefa pronta. `git diff --check`: aprovado. Verificação adicional via
Python: 16 links/anchors da análise válidos e sem espaços finais. Nenhuma suíte
Dart executada; alteração apenas documental, sem editar código, proposta, skills
ou testes nesta atualização.

Limitações: Compass ainda não inspecionado nem integrado; nenhuma evidência de uso
ou usabilidade dele. Código, proposta, escopo de oito CRDTs e SQLite não alterados.

## Uso adequado do Dart no planejamento — 2026-10-03

Pedido: orientar agentes a aproveitar recursos do Dart com simplicidade, exemplos
e limites, incorporando isso ao planejamento e às etapas. Lista adicional do autor
foi discutida como referência opcional; nenhum catálogo ou procedimento novo criado.

Skills: plan-reader, code-reviewer, plan-validator, plan-maintainer.

Leitura: instruções, índice, RUNBOOK, fases 1/2, decisões, análise e evidências;
worktree inicialmente limpo. Diagnóstico anterior já identificava enums/interfaces
existentes, rótulos repetidos, metadados comuns incompletos e nulabilidade da outbox.

Alterações: orientação canônica em AGENTS.md com exemplo de enhanced enum e
rótulos estáveis, contratos tipados/null safety, extensions, extension types e
modificadores/pattern matching. SDK, comportamento em runtime, integração e
compatibilidade são critérios de escolha; não exigir cada recurso nem modernizar
legado previsto para remoção. README e RUNBOOK aplicam orientação ao ciclo;
R-09a explicita tipos/metadados/round-trip, R-09b explicita nulabilidade válida,
fase 2 reusa contratos. DEC-16 e análise registram fundamento. Status, prioridades,
dependências, oito CRDTs e SQLite preservados; nenhuma tarefa concluída.

Review documental: aprovado pelo mesmo agente em etapa separada; sem revisão
independente. Revisados diffs, exemplo e limites técnicos, duplicação de orientação,
compatibilidade e preservação do papel apenas ilustrativo do Compass. Corrigida
separação indevida de linha na tabela de decisões antes da validação.

Validação documental: aprovada. Na raiz, `python3 scripts/check_plan.py` confirmou
26 tarefas e 92 links locais, IDs/dependências/status/frontmatter consistentes;
somente R-09a pronta. `git diff --check`: aprovado. Python adicional, usando helpers
do checker, confirmou 17 links/anchors da análise e ausência de espaços finais.
Comparação SHA-256 de 45 arquivos antes/depois confirmou fontes Dart, testes,
exemplos, proposta, README da raiz, pubspecs, skills e checker sem alterações.
Nenhuma suíte Dart executada: manutenção apenas documental.

Limitações: exemplos orientam implementação futura; nenhuma alteração de API,
classe ou formato entregue, nem melhoria de execução/usabilidade comprovada.

## Revisão e vínculo do guia Dart — 2026-10-03

Pedido: aplicar correções da revisão de `dart_lang_instruction.md` e torná-lo
referência consultável no ciclo do projeto. Skills: code-reviewer, plan-validator,
plan-maintainer. Worktree já continha manutenção anterior e guia criado pelo autor;
alterações preexistentes preservadas.

Leitura: guia, instruções, RUNBOOK, índice/evidências e contratos atuais de
DeltaChange/OutboxEntry. Revisão anterior conferiu limites técnicos na documentação
oficial do Dart; fontes vinculadas no guia.

Alterações: corrigidos SDK mínimo de extension types, alcance/semântica dos
modificadores e validação/runtime de extension types. Records públicos pequenos
e wrappers passaram a ser escolhas justificáveis, sem proibições automáticas.
Incluídos limites de extensions, serialização estável e exemplos ilustrativos de
tipos/metadados e nulabilidade para R-09a/R-09b. Parsing do enum reusa seu catálogo,
sem lista paralela de rótulos. AGENTS.md e RUNBOOK orientam consulta pertinente;
exemplo de enum foi centralizado no guia. Orientações do projeto e critérios da
tarefa prevalecem. Nenhuma tarefa iniciada ou concluída.

Review: aprovado pelo mesmo agente em etapa separada; sem revisão independente.
Guia final e alterações deste turno nas instruções/RUNBOOK revisados quanto a
precisão, simplicidade, limites de exemplos e compatibilidade. Exemplos futuros
distinguem-se dos contratos atuais e não prometem isolamento/durabilidade.

Validação: na raiz, `python3 scripts/check_plan.py` confirmou 26 tarefas e 94 links
locais; IDs, dependências, status e frontmatter consistentes; R-09a única pronta.
`git diff --check`: aprovado. Verificação adicional via Python confirmou links e
anchors nos quatro documentos desta atualização, incluindo o guia não rastreado,
fences fechadas e ausência de espaços finais. Comparação SHA-256 de 54 arquivos
antes/depois confirmou código, testes, proposta, pubspecs, skills, checker, análise
anterior e demais planos sem alterações neste turno.

Limitações: alteração documental; exemplos não compilados/executados e nenhuma
suíte Dart rodada. Não constitui implementação de R-09a/R-09b nem evidência de
melhoria de execução. Escopo, prioridades, dependências e status preservados.

## Execução R-09a — 2026-10-03

Status final: em andamento
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-01 e R-02 concluídas; R-09a era única tarefa pronta. Inspecionados
contratos exportados, codecs, Replica, ReplicaState, storage, consumidores e testes.
Worktree já continha `prompt.txt` não rastreado; preservado.
Implementação: `DeltaChange` passou a expor `CrdtKind`, endereço e origem tipados;
labels estáveis continuam `lww`, `g-counter` e `pn-counter`, com rejeição explícita
de desconhecidos. `OutboxEntry` usa origem comum sem switch por subclasse.
`CrdtOperation` sem uso removido. Mutação LWW local valida chave e valor JSON antes
de avançar clock ou sequência; regressões cobrem metadados, rejeição e round-trip.
Review: etapa separada, aprovado para a mudança delimitada; sem revisão independente.
Correção após review: parsing rejeita tipo não textual com `FormatException`; validação
usa `jsonEncode` sem conversão implícita de objetos arbitrários. Review do delta
corrigido não encontrou novo achado impeditivo na área alterada.
Achados pendentes impeditivos para concluir R-09a: `OperationCrdt` e herança/operações
legadas permanecem no caminho de `LwwRegister`; `Delta` ainda guarda operações e
deltas nativos em listas paralelas; política de compatibilidade das APIs exportadas
não foi documentada; fluxos e exemplos ainda não foram migrados integralmente.
Validação: checks de core, storage, sync, transport e facade aprovados após correção.
Comandos: em `packages/deltasync_core` e `packages/deltasync_storage`,
`dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test`;
em `packages/deltasync_sync`, `packages/deltasync_transport` e raiz,
`dart analyze && dart test`. Todos retornaram código 0 em 2026-10-03.
`python3 scripts/check_plan.py`: aprovado, 26 tarefas e 95 links locais; nenhuma
tarefa pronta enquanto R-09a segue ativa. `git diff --check`: aprovado após
manutenção.
Critérios: evidência cobre metadados comuns, rótulos/round-trip dos três tipos
atuais, rejeição de tipo desconhecido, validação local LWW, armazenamento sem switch
de classe e ausência de `CrdtOperation`. Critérios restantes não têm evidência e
seguem desmarcados na fase.
Manutenção: fase e índice mantêm R-09a em andamento e identificam tarefa ativa;
nenhuma decisão ou risco global alterado. Próximo passo é retomar R-09a e fechar
critérios pendentes.
Limitações: tarefa incompleta; não anunciar core nativo consolidado, política de
compatibilidade, caminho operacional legado removido ou satisfação dos critérios
restantes. Nenhuma suíte final de workspace foi executada como gate de conclusão.

<a id="execucao-r-09a-2026-10-03-conclusao"></a>

## Execução R-09a — 2026-10-03 (conclusão)

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-09a continuava ativa após execução parcial anterior; retomada autorizada.
Revisados critérios, contratos exportados, formatos, fluxo dos consumidores,
referências Dart pertinentes e limites de core/sync/storage/transport.
Implementação: Delta agora contém um lote nativo; metadados comuns tipados e
`CrdtKind` têm labels estáveis. Migração explícita lê Delta v1/v2 e snapshots
legados; gravação usa formato atual versionado. LWW mantém um vencedor/tombstone
nativo; tipos e caminho operacional antigos foram removidos ou delegados por
wrappers depreciados. PN-Counter usa mapas internos e valida lote inteiro antes
de aplicar join cumulativo por máximo. Endereços/valores locais são validados antes
de alterar estado/clock. Outbox exige Delta válido e lê origem sem switch. Pacotes
e facade passaram a 2.0.0. README descreve incompatibilidades, formatos, uso e
arquivos/testes que localizam estado, mutação, delta, join e restauração. DEC-17
formaliza a quebra; OPEN-07 mantém explícito que consumidores externos não foram
inventariados.
Review: aprovado
Diff revisado em etapa separada pelo implementador, sem independência.
Achados: iniciais: ACK de teste lia alias antigo; migração aceitava clock sem
componente da réplica; snapshot legado não avançava HLC restaurado. Correções
aplicadas e delta revisto. Regressão de snapshot revelou inicialmente diferença
de clock; restauração foi ajustada para importar vencedor sem reobservar estado
já restaurado. Review após correções: aprovado; sem achados impeditivos conhecidos.
Validação: aprovada
Todos os critérios R-09a ligados a regressões de nativos, validação
sem mutação parcial, endereços inválidos, lotes, labels/IDs/round-trip, migração
e rejeição; exemplo e README conferidos. Workspace completo aprovado.
Comandos: em cada pacote raiz/core/sync/storage/transport, `dart format --output=none
--set-exit-if-changed lib test`, `dart analyze` e `dart test`; raiz 2 testes,
core 30, sync 19, storage 6, transport 2. `git diff --check`: aprovado.
Critérios: satisfeitos; regressões nativas, validação sem mutação parcial,
endereços inválidos, lotes, labels/IDs/round-trip, migração e rejeição; exemplo
e README conferidos e critérios marcados na fase.
Manutenção: critérios da fase marcados, R-09a concluída no índice, sem tarefa
ativa; próxima pronta recomendada R-09b. Checker do plano executado após esta
manutenção. `prompt.txt` pré-existente preservado.
Limitações: consumidores externos não inventariados (OPEN-07); revisão não foi
independente. Formatos legados cobertos pelos fixtures disponíveis, sem teste
contra aplicativos consumidores externos desconhecidos.

<a id="execucao-r-09b-2026-10-03"></a>

## Execução R-09b — 2026-10-03

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-09b era a próxima tarefa pronta após R-09a. Revisados seus critérios,
os limites entre core/sync/storage/transport, os contratos públicos e trechos
pertinentes do guia Dart. Alterações preexistentes do worktree foram preservadas.

Implementação: ReplicaState registra vínculo de tipo por endereço e Replica mantém
estado LWW/counters consolidado por endereço, remove histórico operacional e exporta
bootstrap compacto; snapshots internos v3 e storage canônico v2 preservam estado,
tombstones, clocks e sequências disponíveis, lendo ou rejeitando formatos antigos
explicitamente. Valores JSON são validados, copiados e congelados nos limites;
fork conserva a fonte de relógio. SyncEngine trabalha em réplica isolada e usa
preparação/commit/adoção comum. ReplicaStorage documenta as primitivas e commit;
PendingDeltaStore e MemoryPendingDeltaStore ficam depreciados como ponte compatível.
OutboxEntry exige uma mudança, identidade direta, wire format versionado e estados
validados; envio forma lotes, ACK parcial remove só IDs confirmados. README e DEC-18
documentam migração, export/bootstrap, limites de deduplicação e localização das
responsabilidades e testes.

Review: aprovado

Review executado pelo mesmo agente em etapa separada; não é revisão independente.
Achados iniciais: testes de sync pressupunham lote guardado numa entrada; snapshots
legados de counters não preservavam sequências remotas conhecidas; Replica.apply
podia aplicar parcialmente lote inválido; leitura da outbox passou a devolver cópia
defensiva, tornando ineficaz o merge antigo de duplicatas. Correções foram aplicadas
e revistas. A validação encontrou também expectativa histórica na facade; teste foi
atualizado para verificar export compacto com tombstone e idempotência. Sem achados
impeditivos conhecidos após rever as correções.

Achados: os itens encontrados durante review e validação foram corrigidos,
revistos e testados; sem achados impeditivos conhecidos.

Validação: aprovada

`dart analyze` sem issues e `dart test` aprovado na raiz (2 testes), core (39),
sync (22), storage (10) e transport (2), total 75 testes.
O workspace completo foi repetido após a correção da facade. `git diff --check`
aprovado; checker do plano executado após manutenção.

Comandos: `dart format packages/deltasync_core packages/deltasync_sync
packages/deltasync_storage`; `dart format test/deltasync_test.dart`; em cada
diretório `.`, `packages/deltasync_core`, `packages/deltasync_sync`,
`packages/deltasync_storage` e `packages/deltasync_transport`, `dart analyze &&
dart test`; `python3 scripts/check_plan.py`; `git diff --check`.

Critérios: todos satisfeitos e marcados em R-09b. Testes cobrem isolamento de
valores e engine, snapshots/migração/sequências/bootstrap, conflitos atômicos,
falhas locais/remotas, endereço/tipo, commit, contrato e codec da outbox, ACK
parcial e compatibilidade. README foi conferido quanto ao percurso de consumo e
manutenção. MemoryStorage continua volátil; não representa durabilidade em disco.

Manutenção: R-09b concluída na fase e no índice; nenhuma tarefa ativa. R-05 passou
a pronta, sem mudança de escopo. DEC-18 registra os contratos; RISK-13 e RISK-16
foram atualizados com os limites ainda pendentes. `OPEN-07` continua aberto para
inventário de consumidores externos. `prompt.txt` do usuário foi preservado.

Limitações: revisão não independente; não há teste contra consumidores externos
desconhecidos nem comprovação de durabilidade. Snapshots antigos sem estado
reexecutável são rejeitados; snapshots legados de counter sem sequências remotas
permitem merge por snapshot, mas `export()` falha em vez de inventar identidade.
Deduplicação após restauração cobre somente winners/componentes retidos, não é
histórico eterno. Durabilidade real segue em R-07c/R-07d; lifecycle completo segue
em R-05.

<a id="execucao-r-05-2026-10-03"></a>

## Execução R-05 — 2026-10-03

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-05 era a próxima tarefa pronta; R-09b e demais dependências estavam
concluídas. Inspecionados SyncEngine, transporte, outbox/storage, consumers/tests,
critérios, DEC-13, RISK-05/14/15 e guia Dart pertinente. Worktree já continha
alterações R-09b não confirmadas; preservadas.

Implementação: primeira operação aguarda restauração; `start()` explícito é
idempotente, compartilha início concorrente e retorna a `created` após falha para
permitir retry. `lifecycle` torna estados públicos e `replica` rejeita leitura
antes de restauração. Mutações locais e aplicação remota seguem serializadas e
transacionais; preparo/marcação de envio e ACK passam pela fila, mas espera do
transporte ocorre fora dela. ACK só confirma IDs do lote enviado. `pendingDelta()`
mostra retenção local; `push()` retorna `SyncPushResult`; `errors` publica falhas de
delta remoto e erros do stream. `dispose()` é terminal, cancela recepção, drena
trabalho aceito e rejeita novas operações. README documenta contrato e caminho de
consumo. O storage legado pode reter uma mudança já confirmada remotamente, pois
`PendingDeltaStore` não define remoção/ACK; comportamento fica explícito e testado.

Review: aprovado

Review em etapa distinta pelo mesmo agente; não é independente.

Achados: ACK remoto com `PendingDeltaStore` não apaga delta local; documentação e
regressão foram adicionadas para separar confirmação remota de retenção local.
Correções de tipo e lint identificadas durante verificação foram aplicadas; diff
final revisto, sem achados impeditivos conhecidos.

Validação: aprovada

Dart SDK 3.13.0, Linux x64. Workspace completo passou `dart format
--output=none --set-exit-if-changed lib test`, `dart analyze` e `dart test` em
raiz/core/sync/storage/transport; facade 2, core 39, sync 27, storage 10 e
transport 2. Depois do teste final de ACK legado, pacote sync repetiu format,
analyze e test: 28 aprovados, análise sem issues. Total final: 81 testes. `git diff
--check` aprovado.

Comandos: `dart format packages/deltasync_sync/lib/src/sync_engine.dart
packages/deltasync_sync/test/sync_engine_test.dart`; para cada pacote, `dart format
--output=none --set-exit-if-changed lib test && dart analyze && dart test`;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: satisfeitos e marcados. Regressões demonstram restauração antes da
primeira mutação, getter protegido antes do restore, retry após falha de storage,
conflito remoto sem aplicação parcial e erros observáveis, edição/aplicação remota
durante envio lento, ACK limitado ao lote preservando novas pendências, visibilidade
de commit/pendência/ACK e descarte com push em voo, cancelamento do listener e
rejeição de operações após dispose. Teste de 12 mutações confirma IDs/commits
serializados; falhas de commit local/remoto cobertas. README orienta uso público.

Manutenção: todos critérios R-05 marcados; R-05 e fase 1 concluídas no índice/fase.
DEC-19 registra contrato; RISK-05/14/15 atualizados. Fase 4 ativada como próxima
seleção; R-08a passou a pronta. Nenhuma tarefa seguinte iniciada.

Limitações: review não independente; `MemoryStorage` não prova persistência real,
que segue R-07c/R-07d. Transporte/Futures não têm cancelamento; `dispose()` aguarda
I/O já iniciado e pode aguardar indefinidamente se adaptador nunca completar.
Coordenação entre engines que compartilham storage segue R-08d; compatibilidade com
consumidores externos permanece limitada pelo inventário em aberto OPEN-07. O
adaptador legado mantém deltas confirmados para retry/entrega ao menos uma vez.

<a id="execucao-r-08a-2026-10-03"></a>

## Execução R-08a — 2026-10-03

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-08a selecionada como próxima tarefa pronta após R-05; contratos
consolidados de R-09a/R-09b, transporte, codec, SyncEngine, adapters de teste,
README, decisões/riscos e trechos pertinentes do guia Dart lidos. Estado inicial
do worktree conferido e alterações de status da tarefa preservadas.

Implementação: `DeltaTransport` agora recebe e publica `DeltaEnvelope`; o
`SyncEngine` encapsula deltas de saída com a identidade local e aplica o payload
recebido. ACK continua distinto da conclusão de envio e confirma IDs via interface
opcional. Construtor e decoder rejeitam envelope inválido, versões incompatíveis e
tipos desconhecidos como erro explícito. Testes cobrem ida e volta de LWW,
G-Counter e PN-Counter, endereço/tipo/origem, remetente relay distinto das origens,
validação e fluxo efetivo do sync. README documenta formato, protocolo neutro e
quebra de assinatura para adapters consumidores.

Review: aprovado

Review em etapa distinta pelo mesmo agente; não é independente.

Achados: primeira análise apontou import core não usado no contrato de transporte;
removido. Referência de documentação ACK atualizada para o nome do parâmetro
envelope. Diff revisado novamente após correções; sem achados impeditivos.

Validação: aprovada

Dart SDK 3.13.0, Linux x64. Workspace passou `dart format --output=none
--set-exit-if-changed lib test`, `dart analyze` e `dart test` na raiz, core, sync,
storage e transport: 2, 39, 28, 10 e 4 testes aprovados (83 total); análises sem
issues. `git diff --check` aprovado antes da manutenção.

Comandos: formatação dos pacotes sync/transport; em cada pacote `.`,
`packages/deltasync_core`, `packages/deltasync_sync`,
`packages/deltasync_storage` e `packages/deltasync_transport`, `dart format
--output=none --set-exit-if-changed lib test && dart analyze && dart test`;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: satisfeitos e marcados em R-08a. A interface e fluxo real usam envelope;
metadados comuns `DeltaChange`/`CrdtKind` e payload codec ficam acessíveis; versões
e tipos desconhecidos são rejeitados; JSON não escolhe protocolo; representação
única e papéis send/ACK documentados, sem classe redundante.

Manutenção: README, R-08a, índice, rastreabilidade e DEC-20 atualizados. RISK-14
permanece aplicável para confirmação/topologia por peer em R-08b; RISK-17 permanece
para validação de consumidor em R-08d. Fase 4 segue ativa, sem tarefa em andamento;
R-08b marcada pronta após confirmar dependências R-03 e R-08a concluídas.

Limitações: revisão não independente; assinatura pública mudou de `Delta` para
`DeltaEnvelope`, exigindo atualização dos adapters existentes. ACK ainda não
identifica destino/peer, escopo mantido em R-08b; storage continua sujeito aos
limites de durabilidade documentados em R-07c/R-07d.

<a id="execucao-r-08b-2026-10-03"></a>

## Execução R-08b — 2026-10-03

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-08b selecionada após R-08a/R-03 concluídas. Critérios de topologia,
ACK parcial, peer offline e lacunas causais; DEC-03/04/20, OPEN-02/04, RISK-07/08/14,
SyncEngine, ReplicaStorage, DeltaTransport, README e guia Dart foram examinados.
Worktree já continha implementação R-08a não confirmada; preservada e estendida.

Implementação: topologia fica explícita como enlace ponto a ponto. `DeltaTransport`
declara peer fixo; `DeltaEnvelope` v2 grava remetente/destinatário e aceita v1 só
com migração explícita do destino. `DeltaAcknowledgement` distingue `received` de
`appliedAndPersisted`, com rótulos wire estáveis; `SyncPushResult` expõe estágio.
Engine rejeita remetente/destinatário/ACK de peer divergente. `OutboxEntry` v2
grava destino; chaves e operações de pending/mark/ack isolam cada peer. Outbox v1
exige `legacyRecipientPeerId`, sem inventar destino. README descreve protocolo,
contratos e limites. Testes cobrem timeout/offline seguido de retry, troca de peer,
recebimento sem incorporação, ACK parcial após commit remoto, rejeição de identidade
e G/PN cumulativos recebidos fora de ordem com lacunas.

Review: aprovado

Review em etapa separada pelo mesmo agente; não é independente.

Achados: revisão inicial pediu rótulos explícitos/estáveis para o enum de estágios
ACK, usados por adapters. Adicionados `wireName`/`fromWire`; removido construtor de
helper sem uso. Delta de correção revisado novamente; sem achados impeditivos.
Primeira execução dos testes revelou configuração incompleta do harness (retry
forçado após backoff e engine remota ainda não iniciada); testes foram corrigidos,
comportamentos de produto mantidos.

Validação: aprovada

Dart SDK 3.13.0, Linux x64. Workspace completo passou formato sem escrita,
`dart analyze` e `dart test` em raiz/facade, core, sync, storage e transport: 2,
39, 33, 12 e 6 testes, total 92; análises sem issues. `git diff --check` passou.

Comandos: `dart format packages/deltasync_transport packages/deltasync_sync
packages/deltasync_storage`; em `.`, `packages/deltasync_core`,
`packages/deltasync_sync`, `packages/deltasync_storage` e
`packages/deltasync_transport`, `dart format --output=none --set-exit-if-changed
lib test && dart analyze && dart test`; `python3 scripts/check_plan.py`;
`git diff --check`.

Critérios: todos satisfeitos e marcados em R-08b. DEC-21 fixa peer/destinatário;
tipos `DeltaAcknowledgement` e `SyncPushResult` distinguem envio, recebimento e
persistência; teste conectado aplica no storage remoto antes de ACK parcial. Peer
offline mantém outbox e retry após reconexão; teste com peer alternativo comprova
que não lê nem confirma entradas do destino anterior. G/PN acumulam componente no
delta e teste recebe sequência alta antes da baixa sem tratar máximo como ausência
de lacuna. Decisão e README limitam garantias a peer fixo e declaram bootstrap de
peer novo/topologia geral fora do escopo.

Manutenção: R-08b, índice, rastreabilidade, DEC-21, OPEN-02/04, RISK-07/08 e README
atualizados. Fase 4 permanece ativa; R-08d passou a pronta após dependências
R-05/R-08a/R-08b concluídas. Checker e `git diff --check` aprovados após manutenção.

Limitações: review não independente. `MemoryStorage` prova comportamento lógico,
não durabilidade entre processos; R-07c/R-07d validam storage real. Topologia é
um peer fixo; peer novo exige bootstrap explícito e vários destinatários exigem
entrada/ACK independentes. `PendingDeltaStore` legado não guarda destinatário nem
garante ACK por peer; garantias novas exigem `ReplicaStorage`. Tipos futuros com
eventos individuais precisam contexto causal com lacunas ou entrega causal.

<a id="execucao-r-08d-2026-10-03"></a>

## Execução R-08d — 2026-10-03

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: selecionada após R-05/R-08a/R-08b concluídas. Critérios exigem fluxo real
entre duas engines, confirmação só após commit remoto, falhas/concorrência,
recuperação dos três tipos atuais e exemplo genérico. Alterações R-08b já presentes
no worktree foram preservadas. Compass não foi usado como alvo de adaptação.

Implementação: `SyncEngine` já fazia commit local antes do push e mantinha I/O fora
da fila; regressões conectaram duas engines e storages em memória para push
simultâneo, ACK parcial, duplicação/reordenação, edição durante envio, falha de
commit remoto sem ACK e retry. `Replica.fromSnapshotJson` agora restaura também os
mapas de sequências por origem de G-Counter/PN-Counter, presentes nos snapshots v3;
teste compara identidade, estado/tombstone, componentes e sequências restaurados.
`example/deltasync_example.dart` mostra consumidor via facade, e README documenta
execução e diagrama do caminho local/remoto.

Review: aprovado

Review em etapa distinta pelo mesmo agente; não independente.

Achados: exercício de recuperação revelou omissão dos mapas `sequences` ao
reconstruir counters. Correção localizada em `Replica.fromSnapshotJson`, revisada
no diff final; nenhum achado impeditivo restante. Adapter de demonstração aguarda
`applyRemote` terminar antes de reportar `appliedAndPersisted`.

Validação: aprovada

Dart SDK 3.13.0, Linux x64. Formatação sem alterações,
análise estática sem issues e 94 testes passaram (raiz/facade 2, core 39, sync 35,
storage 12, transport 6). Exemplo executou e reportou 3 confirmações; `git diff
--check` passou. `MemoryStorage` continua sendo simulação, não durabilidade entre
processos.

Comandos: `dart format --output=none --set-exit-if-changed example
packages/deltasync_core/lib/src/replica.dart packages/deltasync_sync/lib test`;
para cada diretório `.`, `packages/deltasync_core`, `packages/deltasync_sync`,
`packages/deltasync_storage`, `packages/deltasync_transport`, `dart analyze &&
dart test`; `dart run example/deltasync_example.dart`; `python3
scripts/check_plan.py`; `git diff --check`.

Critérios: todos satisfeitos e marcados em R-08d. Integração usa `sendAndAwaitAck`
que chama `receiver.applyRemote`; commit remoto falho lança e mantém outbox. Duas
engines fazem push concorrente; edição e recebimento seguem com envio pendente.
ACK parcial mantém restante, alterações novas ficam pendentes, replay/reordenação
convergem, retry completa entrega. Restauração simulada conserva identidade,
valores, tombstone LWW, valores e sequências G/PN. Exemplo público permite commit
local sem rede, consulta estado/pendências e assina `errors`; no fluxo, mutações
retornam após commit local, falhas diretas de push são lançadas e falhas de stream
remoto são expostas em `errors`. Nenhuma dúvida de API ficou pendente.

Manutenção: fase 4 permanece ativa por R-08c; R-08d concluída. Fase 3 selecionada
como foco seguinte e R-07b, R-06a/b/c/d liberadas como prontas; próxima tarefa
recomendada é R-07b. RISK-14 atualizado: duas engines com outboxes próprias
validadas, armazenamento compartilhado/durável ainda pendente. RISK-17 mitigado
para consumidor genérico mínimo; Compass permanece não exercitado. Nenhuma nova
decisão arquitetural necessária.

Limitações: review não independente. Storage de teste é volátil; SQLite e
recuperação entre processos seguem R-07c/R-07d. Topologia coberta continua sendo
peer fixo; adaptação do Compass não foi necessária nem testada.

<a id="execucao-r-07b-2026-10-04"></a>

## Execução R-07b — 2026-10-04

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-07b selecionada após R-08d concluída. Critérios cobrem suíte
reutilizável, commits, versões, ACK/metadados, isolamento, atomicidade e limite de
MemoryStorage. Worktree já continha alterações anteriores de R-08d; preservadas.

Implementação: criado `deltasync_storage_testing`, pacote de suporte com
`ReplicaStorageContractFixture` e `replicaStorageContractTests`, reutilizável por
adapters via dependência de desenvolvimento. Suíte verifica snapshot v2 opaco e
outbox de uma mudança, commit local/remoto, ACK parcial por peer, status/tentativa/
horário, isolamento de dados retornados, commits concorrentes e falha de commit
sem alterar snapshot/outbox prévios. Suíte é executada em `MemoryStorage` com rótulo
explícito de simulação. `ReplicaStorage.markSent` agora declara contrato abstrato
e documenta metadados necessários para retry; README e guia do pacote explicam
como adapters futuros conectam a mesma suíte.

Review: aprovado

Review em etapa distinta pelo mesmo agente; não independente.

Achados: implementação vazia de `markSent` permitia semântica sem registrar
tentativa/horário. Tornada obrigatória; adapter deve implementar esse comportamento.
Suíte não impõe tipo de exceção do backend e exige fixture de falha para provar
rollback. Delta final revisto; sem achados impeditivos.

Validação: aprovada

Dart SDK 3.13.0, Linux x64. Formatação sem alterações, análises sem issues e 100
testes aprovados: raiz/facade 2, core 39, sync 35, storage 12,
storage_testing 6 e transport 6. `git diff --check` aprovado.

Comandos: `dart pub get`; formatação de `lib test example` na raiz e `lib test`
em core, sync, storage, storage_testing e transport com
`dart format --output=none --set-exit-if-changed`; em cada um desses seis
diretórios, `dart analyze && dart test`; `python3 scripts/check_plan.py`;
`git diff --check`.

Critérios: todos satisfeitos e marcados em R-07b. A mesma função de contrato
recebe fixture, roda sobre `MemoryStorage` e pode ser invocada no teste de adapter
persistent. Testes verificam formato v2, commits local/remoto, retenção outbox,
ACK/peer e metadados sent, sem lógica de storage sobre classes CRDT concretas.
Falha injetada mantém snapshot e outbox anteriores. Memória e documentação deixam
explícito que não comprovam reinício de processo.

Manutenção: R-07b concluída no arquivo da fase e índice; fase 3 segue ativa;
R-07c liberada como pronta e próxima recomendada. R-06a/b/c/d também permanecem
prontas por dependência. DEC-18 atualizada com `markSent` e suíte compartilhada;
nenhum risco adicional aberto. Checker e `git diff --check` executados após
manutenção.

Limitações: review não independente. Não há adapter persistente ainda, então a
mesma suíte não foi executada contra SQLite; R-07c fará isso. Fixture em memória
injeta falha na fronteira do commit; adapters persistentes devem injetar após
preparar escritas para exercitar rollback transacional real. Nenhuma conclusão sobre
durabilidade entre processos.

<a id="execucao-r-07c-2026-10-04"></a>

## Execução R-07c — 2026-10-04

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: selecionada como próxima tarefa pronta após R-07b. Critérios exigem
schema SQLite versionado, transações, identidade/backup, contrato real e isolamento
de dependências. Worktree estava limpo antes desta execução.

Implementação: criado `packages/deltasync_storage_sqflite/`, membro do workspace,
com `SqfliteReplicaStorage` sobre `sqflite_common.DatabaseFactory`. App Flutter pode
passar factory do plugin `sqflite`; suíte Linux usa SQLite real por
`sqflite_common_ffi`. Schema user_version 1 tem tabela de snapshot com payload
canônico e tabela de outbox por réplica/peer/mudança. Commit local grava snapshot
e outbox em transação; merge remoto substitui snapshot transacionalmente. ACK e
metadados de envio persistem; ID de réplica restaura sem clonagem automática.
README documenta integração, schema/migração e backup fechado com arquivos WAL/SHM
quando presentes ou API SQLite de backup.

Review: aprovado

Review em etapa distinta pelo mesmo agente; não independente. Inspecionados pacote,
workspace, semântica de snapshot/outbox e diff de testes. Primeira execução da suíte
revelou fixture instalando trigger de falha antes de inserir outbox de baseline;
fixture foi ajustada para instalar trigger após enqueue. Delta final revisado;
nenhum achado impeditivo restante.

Achados: corrigido setup do trigger de falha para atingir o commit candidato após
preservar snapshot/outbox de baseline. Sem achados impeditivos restantes.

Validação: aprovada

Dart SDK 3.13.0, Linux x64; SQLite real via `sqflite_common_ffi` 2.4.3. Formatação
sem alterações, análises sem issues e 107 testes aprovados: raiz 2, core 39, sync
35, storage 12, storage_testing 6, storage_sqflite 7 e transport 6. Teste fecha e
reabre banco preservando snapshot/replicaId; versão de schema superior causa falha
explícita e mantém linha armazenada. Gatilho SQLite real prova rollback de snapshot
e outbox no commit local. `core`, `sync` e contrato `storage` não declaram
dependência de Flutter, SQL ou sqflite.

Comandos: `dart pub get`; `dart format --output=none --set-exit-if-changed
packages/deltasync_storage_sqflite/lib packages/deltasync_storage_sqflite/test`;
para cada diretório `.`, `packages/deltasync_core`, `packages/deltasync_sync`,
`packages/deltasync_storage`, `packages/deltasync_storage_testing`,
`packages/deltasync_storage_sqflite`, `packages/deltasync_transport`, `dart analyze
&& dart test`; no pacote adapter, repetidos `dart format --output=none
--set-exit-if-changed lib test`, `dart analyze` e `dart test` após a última asserção;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: todos satisfeitos e marcados em R-07c. Schema e formato interno são
versionados separadamente; estado e clocks permanecem no payload de snapshot, sem
colunas/estado paralelos. Falha SQL dentro da transação deixa snapshot/outbox
anteriores intactos; commit remoto preserva outbox. Testes usam a suíte R-07b
compartilhada. Factory injetável mantém integração simples: consumer escolhe plugin
sqflite ou FFI compatível; core/sync/storage seguem Dart puro. Backup/restauração e
ID ficam documentados no README do pacote.

Manutenção: R-07c concluída; R-07d liberada e definida como próxima tarefa pronta.
Fase 3 permanece ativa. DEC-02/05/22 e RISK-04/06/14 atualizados; OPEN-03 resolvida
pela identidade snapshot preservada e política de cópia. Checker e `git diff
--check` executados após manutenção.

Limitações: review não independente. Execução SQLite ocorreu em Linux x64 pela
factory FFI compatível; plugin Flutter `sqflite` não foi executado em Android/iOS.
R-07d ainda deve provar recuperação do SyncEngine, retry e cenários de duas engines
após reabertura de processo.

## Manutenção — Escopo de storage extensível — 2026-10-04

Skill: plan-maintainer.

Autorização: autor pediu registrar o meio termo entre extensibilidade e escopo
reduzido de implementação: contrato abstrato com um adaptador persistente oficial.

Alteração documental: `plan/README.md` centraliza o escopo de storage;
`DECISIONS.md` registra DEC-23 e distingue `ReplicaStorage` da factory SQLite.
Invariantes exigem commit atômico por transação ou mecanismo equivalente validado.
Fases 2/3 distinguem fluxo público, evidência SQLite e adaptadores do consumidor;
VAL-04 explicita guia de implementação e suíte compartilhada, sem exigir outro
backend persistente. RISK-11 registra o limite para ORM, plugins e adaptadores
oficiais adicionais.

Revisão documental: realizada pelo mesmo agente, em etapa distinta da edição.
Escopo, referências e critérios permanecem coerentes: SQLite é a referência
persistente do TCC; consumidores podem implementar outros backends pelo contrato.
Preservadas alterações anteriores de R-07c, pacote SQLite e workspace. Nenhum
status, dependência ou critério de produto foi marcado como satisfeito nesta
manutenção; R-07d continua pronta e próxima recomendada.

Validação documental: aprovada. Na raiz, `python3 scripts/check_plan.py` e
`git diff --check` passaram, com IDs, dependências, status, links/anchors e
frontmatter consistentes. Alteração apenas documental; testes Dart não executados.

Limitações: revisão não independente. A extensibilidade do contrato não constitui
evidência de durabilidade de backends adicionais; esses adaptadores devem validar
as garantias do contrato em sua própria implementação.

## Execução R-06a — 2026-10-04

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-08d concluída e R-06a era a tarefa pronta; escopo comum exige join,
codec, roteamento, snapshot, outbox e fluxo entre engines.

Implementação: `packages/deltasync_core/lib/src/g_set.dart` adiciona G-Set para
valores JSON com igualdade estrutural, delta incremental namespaced por endereço,
join e export determinísticos. `Replica` integra mutação, merge, isolamento,
roteamento e snapshot interno v4; mantém leitura de versões 1–3. `SyncEngine`
persiste a mutação na outbox. Facade e README mostram consumo; formato e locais de
manutenção estão documentados. IDs de counter permanecem iguais via delegação ao
novo helper compartilhado.

Review: aprovado

Achados: review em etapa separada verificou identidade/dot, validação antes de
vincular endereço, compatibilidade de snapshots, sequência em reconciliação e
cópias dos valores. Foi adicionada validação explícita de dot positivo no
roteamento de Replica. Review pelo próprio implementador; não independente.

Validação: aprovada

Dart format sem alterações; `dart analyze` sem issues e testes
aprovados em `packages/deltasync_core` (45), `packages/deltasync_sync` (35) e raiz
(3), total 83. Cobertura inclui join associativo/comutativo/idempotente,
duplicação/reordenação, JSON estrutural, round-trip DeltaCodec, restauração de
snapshot, reconciliação via snapshots versus deltas, outbox e duas engines com
MemoryStorage. Snapshot v3 sem G-Set continua legível.

Comandos: em cada diretório `.`, `packages/deltasync_core` e
`packages/deltasync_sync`, `dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test`; formatação dos caminhos alterados com `dart format`; `git diff --check`. Checker de plano executado após manutenção.

Critérios: os três itens de R-06a marcados. União e duplicação preservam valor;
deltas trocam incrementos; o fluxo cobre API pública, codec, roteamento, snapshot,
outbox e restauração. Snapshot interno v4 é escrito; consumidores antigos não
leem esse formato, enquanto o leitor atual aceita snapshots v1–v3. DeltaCodec
mantém versão 3 e decodificadores antigos rejeitam o label desconhecido `g-set`.

Manutenção: R-06a concluída na fase e no índice; R-06b é a próxima pronta. Fase 2
continua ativa. Nenhuma decisão ou risco alterado. `python3 scripts/check_plan.py`
e `git diff --check` executados após manutenção.

Limitações: MemoryStorage demonstra fluxo e reabertura lógica, não durabilidade
após queda de processo; persistência SQLite dos oito tipos pertence a R-07a. Review
não independente.

## Execução R-06b — 2026-10-04

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-08d concluída, R-06a concluída; R-06b era próxima pronta. Critérios
exigem remoção definitiva contra readição/mensagem antiga, tombstones em merge e
restore, e fluxo comum de integração por tipo.

Implementação: `two_p_set.dart` modela duas operações monotônicas, `add` e
`remove`, em deltas com `CrdtKind.twoPSet`, label estável `2p-set`, endereço e dot.
Join une adições e tombstones; consulta retorna diferença estrutural dos conjuntos.
`json_set_value.dart` centraliza normalização, igualdade JSON e consulta somente
leitura compartilhadas por G-Set/2P-Set. `Replica` integra estado, codec, merge,
export, API e snapshot v5, lendo versões 1–4; `SyncEngine` comita as quatro
operações públicas na outbox. Facade, README e pontos de manutenção atualizados.

Review: aprovado

Achados: revisão do diff incluindo arquivos novos. Identificada consulta `contains`
com valor JSON inválido que podia escapar validação; view passou a validar/copiar
antes de canonicalizar, com regressão. Re-review da correção sem achados pendentes.
Review pelo próprio implementador em etapa distinta; não independente.

Validação: aprovada

Após correção, core passou formatação, análise sem issues e 52 testes; sync passou
análise e 35 testes; facade passou análise e 4 testes. Formatação sem alterações
em todos os pacotes. Total: 91 testes aprovados. Cobertos join associativo,
comutativo e idempotente, remoção antes da adição, readição e mensagem antiga,
codec, igualdade JSON, snapshots v4/v5, reconciliação de snapshot versus deltas,
conflito de endereço, outbox, duas engines e restore lógico com MemoryStorage.

Comandos: no core, sync e raiz, `dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test`; `dart format` nos caminhos alterados; `python3 scripts/check_plan.py`; `git diff --check`. Dart SDK 3.13.0, Linux x64. Validação Dart executada com acesso ao SDK após cache Flutter ser somente leitura no sandbox.

Critérios: elemento removido não retorna após readição ou delta antigo, demonstrado
na classe, Replica e duas engines. Tombstones sobrevivem a join, codec, snapshot e
restart lógico. Critérios comuns cobertos por API que retorna deltas, consulta,
join algébrico, serialização/restauração, duplicação/reordenação, reconciliação,
roteamento, snapshot, outbox e fluxo entre engines. Snapshot v5 é incompatível
com leitores antigos; leitor atual continua lendo v1–v4. SQLite real dos tipos
integrados continua pertencendo a R-07a.

Manutenção: R-06b e critérios marcados; índice/fase sincronizados; fase 2 ativa;
R-06c é próxima recomendada. DECISIONS/RISKS sem alterações. Checker e diff check
executados após manutenção.

Limitações: tombstones são permanentes e crescem com valores removidos; GC fica
fora do escopo. MemoryStorage não comprova queda/reabertura de processo. Review não
independente.

## Execução R-06c — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-08d concluída e R-06c era próxima tarefa pronta. Critérios pedem
concorrência visível, escrita posterior que domina apenas dots observados,
contexto causal com lacunas, serialização e fluxo integrado por duas engines.
Contrato não podia usar máximo de VectorClock como prova de entrega; conjunto de
dots explícitos preserva exatamente o que a escrita observou.

Implementação: `mv_register.dart` adiciona delta imutável com dot/contexto, valor
JSON, join e snapshot local. `Replica` integra leitura, escrita, roteamento, merge,
export e snapshot v6 (lê v1–v5); `DeltaCodec` usa label estável `mv-register`;
`SyncEngine.writeMvRegister` grava cada alteração na outbox. `README.md` documenta
semântica, exemplo público, compatibilidade e crescimento do contexto. Testes core,
sync e facade cobrem concorrência, escrita observada, entrega atrasada, duplicação,
join algébrico, reconciliação por deltas, JSON estrutural, invalidez, codec, snapshot,
outbox, duas engines e restauração com MemoryStorage.

Review: aprovado

Achados: revisão do diff incluindo arquivo novo encontrou comparação de objetos JSON
dependente da ordem de chaves, snapshot aceitando contexto causal de outro endereço,
e endereço sendo vinculado antes de rejeitar valor local inválido. Corrigidos com
canonicalização JSON, validação do snapshot e validação antes da mutação. Re-review
do diff corrigido e adições de teste/documentação sem achados impeditivos. Review
pelo próprio implementador em etapa distinta; não independente.

Validação: aprovada

Comandos: em `packages/deltasync_core`, `packages/deltasync_sync` e raiz,
`dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test`;
em `packages/deltasync_storage`, `packages/deltasync_storage_sqflite` e
`packages/deltasync_transport`, `dart analyze && dart test`. Todos passaram em
2026-10-06, Dart SDK 3.13.0, Linux x64. Tentativas iniciais apontaram formatação
pendente e expectativa legada de snapshot v5; arquivo foi formatado, expectativa
migrou para v6, e validações finais passaram. SQLite executou contrato/recuperação
existentes, mas esses cenários não exercitam MV-Register; durabilidade MV segue para
R-07a.

Critérios: concorrência segue visível em ambas as engines; contexto de escrita
posterior elimina dots anteriores observados e suprime chegada atrasada, sem inferir
recebimento de dot ausente. Deltas e snapshot restauram dots/contexto. Testes verificam
idempotência, comutatividade e associatividade do join, deltas duplicados/reordenados,
reconciliação por deltas igual ao join e valores JSON estruturalmente iguais. A suíte
sync exercita outbox e recuperação lógica em MemoryStorage; não comprova durabilidade
entre processos. Sem GC causal no escopo, contexto completo cresce com dots conhecidos.

Manutenção: critérios R-06c marcados, índice/fase sincronizados e tarefa ativa limpa;
R-06d é próxima tarefa pronta. README atualizado; RISK-07 ajustado; DECISIONS não
mudou. Checker de plano e `git diff --check` executados após manutenção.

Limitações: integração usa MemoryStorage; SQLite dos oito tipos será validado em
R-07a. Review não independente.

## Execução R-06d — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-06d era a próxima tarefa pronta após R-06c. Remoção usa tags dot
explicitamente observadas, pois máximos de sequência não provam que eventos
anteriores chegaram; tags e tombstones ficam no estado restaurável até eventual
GC fora do escopo.

Implementação: `or_set.dart` define ações com labels estáveis, delta tipado,
adições por dot e remoções pelo conjunto exato de dots observados. `Replica`
integra consulta, mutação, codec, join, export e snapshot v7 (leitura v1–v6);
`SyncEngine` persiste as operações na outbox. README explica semântica, consumo,
compatibilidade e responsabilidade de manutenção. Testes cobrem concorrência,
readição, replay antigo após restore, join algébrico, duplicação/reordenação,
reconciliação por deltas, dados inválidos, codec, facade, duas engines e restore
lógico com MemoryStorage.

Review: aprovado

Achados: revisão separada do diff, incluindo arquivo novo, não encontrou defeito
impeditivo; pré-validação core e sync confirmou joins, endereço e restauração.
Review pelo próprio implementador; não independente.

Validação: aprovada

Comandos: `dart format --output=none --set-exit-if-changed lib test`, `dart analyze`
e `dart test` passaram em core, sync, storage, storage_sqflite, transport e raiz.
Total: core 62, sync 37, storage 12, SQLite 13, transport 6, facade 6 testes;
sem issues de análise, formatação sem alterações. SQLite executou os contratos e
recuperação existentes, mas não cobre OR-Set; durabilidade desse tipo segue para
R-07a. Dart SDK 3.13.0, Linux x64.

Critérios: remoção guarda só dots observados e concorrência permanece visível;
readição ganha tag nova; replay da adição removida não retorna após snapshot,
restauração e fluxo SyncEngine. Testes comprovam join associativo, comutativo e
idempotente, envio fora de ordem/duplicado e estado equivalente à reconciliação
por deltas. Codec e label inválido, roteamento, snapshot, outbox e duas engines
foram exercitados; MemoryStorage simula restore lógico, não queda de processo.

Manutenção: critérios da R-06d marcados e índice/fase sincronizados. R-06e é a
próxima pronta: R-06d concluída e tipos disponíveis para valores CRDT já prontos.
RISK-07 atualizado; DECISIONS não mudou. Checker e `git diff --check` executados
após manutenção.

Limitações: eventos/tombstones crescem sem GC causal; SQLite não exercita OR-Set;
review não independente.

## Execução R-06e — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-06d concluída e R-06e pronta. G-Set já pronto em R-06a foi escolhido
como valor composto: união de valores preserva atualizações concorrentes e evita
introduzir catálogo/framework genérico de objetos. Política: chave add-wins por
tags observadas; remoção apaga somente tags conhecidas; update não recria chave;
recriação ganha tag e G-Set vazio. Valores são grow-only por contrato do G-Set.

Implementação: `or_map.dart` define deltas tipados para criar/remover tags de chave
e adicionar valores ao G-Set da encarnação observada. Deltas aninham GSetDelta e
mantêm endereço composto por mapa/chave/tag. `Replica` integra consulta, mutação,
codec, merge, export e snapshot v8 (lê v1–v7); `SyncEngine` grava atualizações
multi-tag em commit atômico com uma entrada por delta. README mostra consumo,
semântica, compatibilidade e limites. Testes cobrem concorrência, união de valores,
remoção/recriação, replay antigo após restore, join algébrico, reconciliação por
snapshot/deltas, conflito de IDs, codec, facade e duas engines com MemoryStorage.

Review: aprovado

Achados: primeira revisão encontrou criação de OR-Map vazio ao rejeitar operação
local inválida, deixando endereço não vinculado que podia quebrar snapshot depois.
Corrigido para só inserir estado após mutação válida; regressão testa nova mutação
LWW e restore após falha. Re-review encontrou tags de remoção/valor cruzando chaves
em mensagens fora de ordem; validação e regressão corrigidas. Review pelo próprio
implementador em etapa separada, não independente.

Validação: aprovada

Comandos: `dart format --output=none --set-exit-if-changed lib test`, `dart analyze`
e `dart test` passaram em core, sync, storage, storage_sqflite, transport e raiz.
Total: core 69, sync 38, storage 11, SQLite 12, transport 6 e facade 7 testes
aprovados; sem issues de análise, formatação sem alterações. SQLite executou
recuperação/contratos existentes, sem exercitar OR-Map; integração durável do tipo
segue para R-07a. Dart SDK 3.13.0, Linux x64.

Critérios: política de chave/update está documentada; updates G-Set concorrentes
se unem sem substituição. Remoção concorrente preserva nova tag; recriação oculta
valor e delta da chave antiga após restauração. Testes cobrem join associativo,
comutativo/idempotente, duplicação/reordenação, equivalência com reconciliação por
deltas e snapshot, codec, roteamento, outbox por mudança e fluxo entre duas engines.
Falha de commit do lote multi-tag preserva estado/outbox e retry grava ambas as
mudanças atomicamente.

Manutenção: R-06e marcada, índice/fase sincronizados. R-07a é próxima pronta:
R-07d e R-06a–R-06e estão concluídas. RISK-07 atualizado; DECISIONS sem mudança.
Checker e `git diff --check` executados após manutenção.

Limitações: valor composto desta entrega é G-Set; não há API genérica para qualquer
tipo de objeto. Valores não removem elementos; remoção é por chave. SQLite de OR-Map
fica para R-07a; tombstones permanecem sem GC. Review não independente.

## Execução R-07a — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-07d e R-06a–R-06e concluídas; R-07a pronta. Codec e roteamento
individual dos oito tipos já tinham cobertura nas tarefas R-06 e testes do core;
faltava comprovar estado/outbox de todos em SQLite real, lote misto e entrega entre
engines após reabertura.

Implementação: `sync_recovery_test.dart` cria oito tipos e tombstones em duas
engines com SQLite FFI, interrompe envio, fecha banco/engine, reabre ambos, verifica
estado/outbox, reenvia adições antigas para provar tombstones preservados e entrega
lote de 12 mudanças com ACK durável. Consumidor usa somente APIs públicas de sync;
nenhuma API de produção ou dependência de codegen foi adicionada.

Review: aprovado

Achados: review inicial observou que valores vazios após reabertura não provavam
persistência dos tombstones. Teste passou a reaplicar deltas antigos de 2P-Set,
OR-Set e OR-Map após restore e confirmar que elementos/chave continuam removidos.
Re-review aprovado. Review do próprio implementador em etapa separada, não
independente.

Validação: aprovada

Comandos: em cada pacote `.`/raiz, `packages/deltasync_core`,
`packages/deltasync_sync`, `packages/deltasync_storage`,
`packages/deltasync_storage_sqflite` e `packages/deltasync_transport`:
`dart format --output=none --set-exit-if-changed lib test`, `dart analyze`,
`dart test`; depois `git diff --check`. Todos passaram; formatação sem alterações,
análise sem issues. Testes aprovados: raiz 7, core 69, sync 38, storage 12,
SQLite FFI 13, transport 6. Dart SDK 3.13.0, Linux x64. SQLite foi real via FFI;
não foi validado em dispositivo Flutter.

Critérios: codec/roteamento/snapshot/outbox cobertos individualmente pelos testes
de R-06a–R-06e e `crdt_interfaces_test.dart`; codec rejeita tipo desconhecido e
versões inválidas. Novo teste cobre fluxo local, storage SQLite, envio, aplicação
remota e ACK de todos os oito tipos no mesmo lote. Outbox mantém 12 IDs após falha
e restart; ACK remove todos. Tombstones sobrevivem ao restore e rejeitam deltas
antigos. Workspace não usa build_runner para integrar tipos.

Manutenção: R-07a concluída em fase/índice; fase 2 encerrada; R-08c liberada como
próxima pronta na fase 4. DECISIONS/RISKS sem mudança. Checker e diff check
executados após manutenção.

Limitações: SQLite validado com FFI/Linux, não dispositivo Flutter; não houve
alteração de produção. Review não independente.

## Execução R-08c — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-07a, R-07d e R-08d concluídas; R-08c era próxima tarefa pronta.
DEC-21 fixa outbox por peer e retry até ACK `appliedAndPersisted`; OPEN-04 limita
bootstrap a peer conhecido. R-07d já cobria falha antes da entrega, ACK perdido,
reabertura SQLite e push simultâneo; faltava um cenário ponta a ponta de duas
réplicas offline divergentes, peer alternativo, reordenação e reconexão após restart.

Implementação: `sync_recovery_test.dart` agora exercita duas engines com bancos
SQLite separados. Ambas editam enquanto offline e mantêm outbox; após restart,
engine A ligada a peer C não consome entradas destinadas a B. Na reconexão com B,
batch invertido aplica remoção OR-Set antes da adição; ACK perdido deixa outbox
pendente. Após novo restart, snapshot de B já contém mudanças duráveis de A e A
mantém suas entradas. Retry duplicado converge; durante ACK bloqueado, A aceita
edição local e B envia simultaneamente; ACK limpa só lote capturado, edição nova
permanece até retry final. Tudo usa API pública `SyncEngine`/`ReplicaStorage`;
nenhuma API de produção ou camada nova foi necessária.

Review: aprovado

Achados: review inicial pediu verificar snapshot receptor e outbox remetente logo
após restart anterior ao retry, para não deixar entrega idempotente mascarar falta
de persistência. Auditoria final pediu também confirmar outbox ainda pendente no
instante entre commit remoto e ACK liberado. Asserção foi adicionada dentro da
janela de ACK retido; re-reviews aprovados. Review pelo próprio implementador em
etapas distintas, não independente.

Validação: aprovada

Comandos: `dart format --output=none --set-exit-if-changed lib test`,
`dart analyze`, `dart test` em raiz, `packages/deltasync_core`,
`packages/deltasync_sync`, `packages/deltasync_storage`,
`packages/deltasync_storage_sqflite` e `packages/deltasync_transport`; `git diff
--check`. Todos passaram após formatar um ajuste final que inicialmente fez o
check de formatação parar antes da suíte SQLite. Formatação final sem alterações,
análises sem issues. Testes: raiz 7, core 69, sync 38, storage 12, SQLite FFI 14,
transport 6; total 146. Após asserção adicional da janela de ACK, suíte SQLite
reexecutada: 14 testes aprovados. SDK 3.13.0, Linux x64, SQLite real via FFI.
Regressões R-08d/R-07d executadas junto com a suíte completa.

Critérios: cenários e evidências acima cobrem divergência offline/convergência,
falhas pré-entrega e pós-commit, duplicação/reordenação, restart antes do envio
e antes do ACK, recuperação de peer ausente pela mesma outbox endereçada, ACK só
após `applyRemote` persistir (outbox continua pendente durante ACK retido), e
edição/push simultâneo sem bloquear commits locais.
Tombstone OR-Set mantém `from-a` removido após entrega fora de ordem e restart;
ambos convergem para estados LWW, G-Counter e OR-Set iguais. R-07a cobre roteamento
individual dos oito tipos; este cenário integrado usa dois tipos como permitido.

Manutenção: R-08c concluída; fase 4 encerrada. Fase 5 ativa; VAL-01 e VAL-02
liberadas como prontas; VAL-01 é próxima selecionada. RISK-04/06/08/13/14
atualizados; DECISIONS sem mudança. Checker e `git diff --check` executados após
manutenção.

Limitações: SQLite via FFI/Linux, sem dispositivo Flutter; topologia continua
limitada a peer fixo. Concorrência de múltiplas engines sobre mesma outbox SQLite
compartilhada não foi testada. Review não independente.

<a id="execucao-val-01-2026-10-06"></a>

## Execução VAL-01 — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-07a estava concluída; VAL-01 e VAL-02 estavam prontas. VAL-01 foi
selecionada por ordem do plano. Revisados os critérios, testes dos oito CRDTs,
regressões e limites documentados em R-09a/R-09b/R-05/R-08d, além do guia Dart
pertinente. Worktree estava limpo.

Implementação: `packages/deltasync_core/test/crdt_interfaces_test.dart` agora
verifica associatividade, comutatividade e idempotência do join de estado para
LWW, G-Counter e PN-Counter em fixtures fixos de três réplicas. LWW usa timestamps
iguais para exercer desempate determinístico; PN mistura incremento/decremento.
Comparações de counters normalizam identidade local ao comparar estado replicado.
Nenhuma API ou formato mudou.

Review: aprovado

Review em etapa distinta pelo mesmo agente, não independente. A revisão detectou
que `toJson()` de counters inclui identidade/sequência local, além do estado
replicado. A idempotência foi corrigida para comparar joins normalizados sob a
mesma identidade; diff revisto após correção, sem achados impeditivos.

Achados: somente o problema de comparação de identidade/sequência local descrito
acima; correção aplicada e re-revisada. Sem achados impeditivos restantes.

Validação: aprovada

Dart SDK 3.13.0, Linux x64. Para raiz e pacotes `deltasync_core`, `deltasync_sync`,
`deltasync_storage`, `deltasync_storage_sqflite` e `deltasync_transport`,
`dart format --output=none --set-exit-if-changed lib test`, `dart analyze` e
`dart test` passaram; `git diff --check` passou antes da manutenção. Testes
aprovados: raiz 7, core 72, sync 38, storage 12, SQLite FFI 14, transport 6
(149 no total). Formatação sem alterações; análises sem issues. SQLite foi
validado em Linux via FFI, sem dispositivo Flutter.

Comandos: em cada diretório `.`, `packages/deltasync_core`,
`packages/deltasync_sync`, `packages/deltasync_storage`,
`packages/deltasync_storage_sqflite` e `packages/deltasync_transport`, executar
`dart format --output=none --set-exit-if-changed lib test && dart analyze &&
dart test`; `git diff --check`; após manutenção, `python3 scripts/check_plan.py`
e `git diff --check`.

Critérios: cobertura dos oito tipos vem dos testes unitários e de join em
`crdt_interfaces_test.dart`, `two_p_set_test.dart`, `mv_register_test.dart`,
`or_set_test.dart` e `or_map_test.dart`; codecs/snapshots dos tipos são verificados
nesses testes e por `SQLite sync recovery restores all eight CRDTs and mixed
outbox before SQLite peer delivery`. Concorrência, duplicação, reordenação e
tombstones têm regressões em core/sync e na recuperação SQLite R-07d/R-08c.
F-01 a F-06 têm regressões em R-08d/R-05 (push e commit), R-05 (restore/lifecycle),
R-09b (isolamento e transação), R-09a/R-05 (validação local) e core
(`PN-Counter rejects malformed delta without partial component join`). Outras
inconsistências aplicáveis têm correção ou limite explícito nos registros R-09a,
R-09b, R-05 e R-08d: endereço/tipo, relógio injetado, identidade conflitante,
export após restore, APIs legadas, histórico sem benchmark e canal de erro remoto.
As fixtures são determinísticas e enumeradas manualmente; não há RNG nem semente
(N/A). Convergência exige igualdade do estado serializado/canônico após juntar o
mesmo conjunto de estados; casos com remoção exigem tombstone preservado após
replay/restauração. Limites de consumidores externos (OPEN-07), histórico sem
benchmark e topologia de peer fixo permanecem documentados; não são alegados como
garantias universais.

Manutenção: todos critérios VAL-01 marcados; fase 5 permanece ativa; VAL-01
concluída no índice/fase, tarefa ativa limpa e VAL-02 segue próxima pronta.
DECISIONS/RISKS sem mudança. Checker do plano e `git diff --check` executados após
manutenção.

Limitações: review não independente; FFI/Linux não valida dispositivo Flutter.
Fixtures algébricas são determinísticas e finitas, sem geração aleatória nem
semente. Compatibilidade de consumidores externos desconhecidos continua OPEN-07.

<a id="execucao-val-02-2026-10-06"></a>

## Execução VAL-02 — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: VAL-01 e R-08c concluídas; VAL-02 era próxima MUST pronta. Compass não
está disponível no checkout; o repositório tinha apenas exemplo com MemoryStorage.
Critérios pedem consumidor reproduzível e SQLite real, então escolhi demo CLI
desktop com SQLite FFI, sem adaptação do core.

Implementação: `example/offline_reconciliation.dart` é consumidor pela facade
pública. `ShoppingApp` mapeia nomes de compradores para campos LWW e itens para
G-Counter; `ShoppingView` consulta estado; app apresenta commit local, pendências,
erro de peer offline e confirmação. `DemoPeerLink` adapta fluxo ao contrato de
transporte. Comandos `reset`, `offline` e `reconnect` permitem duas execuções de
processo: primeira grava duas réplicas divergentes com SQLite real e outboxes
pendentes; segunda reabre bancos, conecta peers, entrega/ACK, compara ambos os
modelos, fecha e reabre bancos uma vez mais. Root `pubspec.yaml` inclui SQLite
FFI e adaptador como dependências de desenvolvimento. README documenta configuração,
comandos, resultado esperado, plataforma e limites; corrigiu descrições antigas
que diziam que adaptador SQLite e cobertura dos oito tipos ainda não existiam.
Nenhuma falha geral de API foi observada; nenhuma mudança de produção necessária.

Review: aprovado

Review em etapa separada pelo mesmo agente; não independente. Revisados ciclo de
vida/fechamento de engines e DBs, isolamento de identidades, commit antes de push,
ACK só após commit remoto, destino por peer e comparação de estado. Sem achados
impeditivos; código não mudou após review.

Achados: README continha descrição desatualizada de SQLite/cobertura; corrigida.
Compass não disponível. Nenhum problema de contrato público apareceu no cenário.

Validação: aprovada

Dart SDK 3.13.0, Linux x64, SQLite real via `sqflite_common_ffi`; raiz, core, sync,
storage, storage_sqflite, storage_testing e transport passaram format check,
`dart analyze` e `dart test`. Testes: 7, 72, 38, 12, 14, 6 e 6 (155 total), sem
issues de análise e sem alterações de formatação. A execução de demonstração em
processos separados passou: offline gravou Ana/2 itens e Beto/3 itens, cada uma
com duas pendências; push offline informou `Peer ... is offline` sem perda.
Processo `reconnect` restaurou estado/outbox, convergiu ambos para Ana/Beto e
5 itens, recebeu ACK e limpou pendências. Reabertura final confirmou estado
convergido/outbox vazia. Uma reexecução adicional de `reconnect` foi idempotente.
Plugins sqflite Android/iOS não foram exercitados.

Comandos: `dart pub get`; `dart format example/offline_reconciliation.dart`;
`dart analyze`; em cada diretório `.`, `packages/deltasync_core`,
`packages/deltasync_sync`, `packages/deltasync_storage`,
`packages/deltasync_storage_sqflite`, `packages/deltasync_storage_testing` e
`packages/deltasync_transport`, `dart format --output=none --set-exit-if-changed
lib test && dart analyze && dart test`; em invocações Dart separadas, `dart run
example/offline_reconciliation.dart reset`, `offline`, `reconnect`; depois, nova
execução de `reconnect`; `git diff --check`; `python3 scripts/check_plan.py`.

Critérios: dois CRDTs, duas réplicas, edições offline, erro, consulta, pendência,
commit local, ACK remoto e convergência demonstrados. Dois arquivos SQLite
persistiram snapshot e outbox após fim do processo; segundo processo restaurou
ambos antes de conectar. Modelo e status pertencem ao consumidor; sem dependência
de codegen/framework de objetos. Experiência limitada a saída de terminal e a
cenário sintético; nenhum participante avaliou usabilidade.

Manutenção: critérios VAL-02 marcados, fase 5 ativa, VAL-02 concluída. VAL-03 e
VAL-04 (MUST) e VAL-06 (SHOULD) passaram a prontas; VAL-03 selecionada como próxima
MUST por posição no plano. DECISIONS/RISKS sem mudança. Checker e `git diff --check`
aprovados após manutenção.

Limitações: transporte conectado é um adaptador em memória, não protocolo/rede;
SQLite FFI validado em Linux x64, não plugin Flutter mobile; demo demonstra fluxo
e mensagens, não avaliação de usabilidade por usuários. Compass não está disponível.

<a id="execucao-val-04-2026-10-06"></a>

## Execução VAL-04 — 2026-10-06

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: VAL-03 era a última MUST concluída; VAL-04 era próxima MUST pronta e
VAL-06 SHOULD também pronta. Revistos critérios, storage, oito CRDTs, contratos,
PDF acadêmico e contexto. Worktree já continha mudanças não commitadas de VAL-03
em `plan/05_PHASE5_VALIDACAO.md`, `plan/README.md` e `plan/TRACEABILITY.md`; foram
preservadas. Busca não encontrou fonte editável `.doc`, `.docx`, `.tex` ou `.odt`;
PDF mantido sem alteração.

Implementação: README agora lista os oito CRDTs e facades/subpacotes, mapeia
operações conceituais do PDF para API real e distingue delta de snapshot. Diagrama
e texto mostram mutação, delta, commit atômico, envelope, aplicação/join remoto,
commit remoto e restauração. Guia aponta implementação/invariantes de OR-Set,
arquivos e testes core/sync/SQLite; explica implementação direta de `ReplicaStorage`,
suíte `replicaStorageContractTests`, rollback, preservação de outbox e escolha do
backend pelo consumidor. `proposta.md` contém lista por seções §6.3–§6.9 e conclusão
para atualização futura da fonte, incluindo limites e extensões. Compass não foi
usado; demo CLI VAL-02 e suas adaptações já estão separadas da evidência geral.
Plan README aponta o guia atual, sem modificar os contratos de produção.

Review: aprovado

Review documental em etapa distinta pelo mesmo agente; não independente. Conferidos
nomes de API contra `replica.dart`, `sync_engine.dart`, `delta_codec.dart` e
`delta_envelope.dart`; testes/caminhos citados existem. Primeira leitura detectou
nome incorreto de mutação OR-Set na tabela, corrigido para `addOrSet()`. Releitura
confirmou distinção `Replica.apply`/`applyDelta`, `DeltaCodec.encode/decode`, e
semântica de commit antes de adoção. Sem achados impeditivos após correção.

Achados: nenhuma fonte editável acadêmica no checkout; lista de alterações e guia
geral produzidos, sem sobrescrever o PDF. Nenhuma mudança de código foi necessária.

Validação: aprovada

Validação somente documental: revisão manual de assinaturas, contratos, referências,
links e requisitos; `python3 scripts/check_plan.py` reportou plano consistente,
26 tarefas e 114 links locais; `git diff --check` passou. Nenhum teste Dart foi
executado, pois implementação não mudou. A evidência de durabilidade, recuperação
SQLite e demonstração permanece nos registros R-07a/R-07d/VAL-02, não foi inferida
do diagrama ou do MemoryStorage.

Comandos: buscas `rg` em API, contratos e testes citados; inspeção de
`packages/deltasync_core/lib/src/replica.dart`,
`packages/deltasync_sync/lib/src/sync_engine.dart`,
`packages/deltasync_transport/lib/src/delta_envelope.dart`,
`packages/deltasync_core/lib/src/delta_codec.dart`, contrato e fixture de storage;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: quatro subpacotes/facade, contrato e adaptador SQLite descritos; tabela
conceito/API, diagrama e fluxo documentam mutação, deltas, join, commits e restore;
guia oferece rota real de manutenção OR-Set e integração de adapter com invariantes,
compatibilidade e suíte compartilhada. Oito tipos e extensões futuras preservados.
Compass é N/A nesta demonstração, conforme VAL-02; não foram atribuídos requisitos
ao core a partir de adaptações específicas. Resultado/limites da demo correspondem
à execução documentada: CLI/Linux com SQLite FFI; sem plugin móvel, protocolo real,
benchmark, usabilidade avaliada ou claim universal. A edição do texto acadêmico
final aguarda fonte editável, expressamente permitida como dependência pelo critério.

Manutenção: VAL-04 concluída no índice/fase, tarefa ativa limpa, VAL-05 liberada
como pronta após VAL-03/VAL-04; VAL-06 segue pronta (SHOULD). `DECISIONS.md` e
`RISKS.md` sem alteração. Checker e diff check executados após atualização de status.

Limitações: revisão pelo próprio implementador, não independente. Lista preparada
não substitui edição/revisão final do relatório acadêmico quando o fonte for
fornecido. Compass, plugin Flutter mobile, protocolo de rede real, usuários e
benchmarks não foram avaliados nesta tarefa.

<a id="execucao-val-05-2026-10-06"></a>

## Execução VAL-05 — 2026-10-06

Status final: em validação

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: VAL-03/VAL-04 concluídas; VAL-05 era próxima MUST pronta. Critérios,
matriz final, registros de R-09a/R-09b/R-05/R-08d/R-07a/b/c/d/R-08a/b/c e
VAL-01/02/03/04, decisões e riscos foram conferidos. Worktree já continha edições
documentais não commitadas de VAL-03/VAL-04; preservadas.

Implementação: nenhuma mudança de código. Revisão encontrou frase antiga em
DEC-05 dizendo que recuperação R-07d ainda estava pendente; corrigida para apontar
R-07d e R-08c. Data de revisão de DECISIONS atualizada. VAL-05 foi registrada em
validação; critérios demonstrados marcados, texto acadêmico final permanece aberto.
OPEN-05 e RISK-10 agora incluem a dependência no gate VAL-05, mantendo o PDF
inalterado.

Review: aprovado com ressalva de gate incompleto

Review em etapa separada pelo mesmo agente; não independente. Conferidos status
MUST, links de evidência e claims da matriz. ACK parcial/retry/reordenação e peer
ausente estão cobertos por R-08b/R-08c; R-07a cobre oito tipos em SQLite;
R-07d/R-08c cobrem recuperação/atomicidade; R-09a/R-09b/R-05/R-08d documentam
limpeza e responsabilidades. DEC-05 desatualizada foi corrigida e re-revista.
Nenhum achado técnico restante nestes itens.

Achados: critérios 1–5 e 7 satisfeitos por evidências existentes e pela demo
VAL-02/documentação VAL-04. Critério 6 permanece aberto: demo e matriz existem,
mas o relatório acadêmico final ainda descreve estrutura/API/SQLite divergentes;
somente PDF está disponível e VAL-04 preparou lista, não editou relatório. Critério
8 permanece aberto até alinhamento e aprovação do relatório. Fonte editável é
dependência concreta em OPEN-05/RISK-10. Não alegar conclusão do TCC.

Validação: parcial; checks passaram, gate não satisfeito

Workspace completo (raiz, core, sync, storage, storage_sqflite,
storage_testing e transport): `dart format --output=none --set-exit-if-changed
lib test` sem alterações, `dart analyze` sem issues e `dart test` passou em todos
os seis pacotes. SQLite FFI executado em Linux; testes do adaptador e recuperação
durável incluídos. `git diff --check` e checker do plano serão executados após
esta manutenção. Nenhum teste substituiu a revisão do texto ausente.

Comandos: `for package in . packages/deltasync_core packages/deltasync_sync
packages/deltasync_storage packages/deltasync_storage_sqflite
packages/deltasync_storage_testing packages/deltasync_transport; do (cd "$package"
&& dart format --output=none --set-exit-if-changed lib test && dart analyze &&
dart test) || exit 1; done`; `python3 scripts/check_plan.py`; `git diff --check`.

Critérios: oito CRDTs e propriedades/deltas estão ligados a VAL-01/R-07a;
durabilidade, clocks, outbox e commit atômico a R-07c/R-07d; ACK, retry,
reordenação e peer ausente a R-08b/R-08c; transporte/versionamento a R-08a/R-09a/
R-09b. Fluxo R-09a/R-09b/R-05/R-08d foi revisto; VAL-02 demonstra consumidor
real genérico após restart e VAL-04 fornece guia geral. Resultado limitado a
Linux/SQLite FFI, peer fixo e demo CLI sintética; sem plugin móvel, Compass,
avaliação de usabilidade ou benchmark. Texto acadêmico final não foi alinhado.

Manutenção: VAL-05 fica em validação, ativa no índice; critérios 1–5 e 7 marcados,
6 e 8 abertos. OPEN-05/RISK-10 apontam dependência da fonte editável. Nenhuma
decisão técnica nova. Próxima SHOULD VAL-06 continua pronta, sem ser iniciada.

Limitações: revisão não independente. Gate depende de fonte editável do relatório
acadêmico; PDF de referência não foi alterado. VAL-05 não concluída; teste de
esforço/prazo OPEN-06 também permanece fora das evidências disponíveis.

## Retomada VAL-05 — 2026-10-07

Status final: bloqueada

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: VAL-05 estava em validação desde 2026-10-06; fonte editável ainda não
estava no checkout. Worktree iniciou limpo. Busca por `.doc`, `.docx`, `.tex`,
`.odt` e nomes de relatório encontrou somente `proposta.md`, que declara ser
contexto, não texto integral do TCC.

Implementação: nenhum conteúdo acadêmico inventado e PDF preservado. VAL-05
marcada bloqueada por impedimento externo registrado em OPEN-05; tarefa ativa
limpa. VAL-06 permanece selecionável por dependência independente.

Review: aprovado para estado documental

Review separado pelo mesmo agente, não independente. Confirmado que critérios
6/8 dependem de texto final alinhado; VAL-04 só pôde preparar lista de alterações.
Nenhuma evidência nova removeu essa lacuna.

Achados: bloqueio concreto é ausência da fonte editável. Não existe adaptação de
código que satisfaça o critério sem inventar/substituir o relatório acadêmico.

Validação: aprovada para manutenção do bloqueio

Busca local confirmou ausência da fonte; links, status e dependências serão
verificados após manutenção por checker e `git diff --check`. Nenhum check Dart
necessário: sem alteração de código desde suítes completas aprovadas em 2026-10-06.

Comandos: `git status --short --branch`; busca `find` por extensões editáveis e
nomes relacionados a TCC/relatório; `python3 scripts/check_plan.py`;
`git diff --check`.

Critérios: 1–5 e 7 permanecem satisfeitos conforme registro de 2026-10-06; 6 e 8
seguem abertos. VAL-05 não concluída.

Manutenção: fase 5 ativa, VAL-05 bloqueada, tarefa ativa limpa; VAL-06 SHOULD
segue pronta. OPEN-05/RISK-10 já registram dependência. Não houve mudança em
DECISIONS/RISKS neste registro.

Limitações: bloqueio persiste até autor fornecer arquivo editável; revisão não
independente. A tarefa independente VAL-06 pode avançar sem alegar conclusão do TCC.

<a id="execucao-val-06-2026-10-07"></a>

## Execução VAL-06 — 2026-10-07

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: VAL-05 permanece bloqueada por OPEN-05; VAL-06 SHOULD estava pronta e
depende apenas de VAL-02, já concluída. Critérios pedem bytes do estado/delta,
metadados/serialização explícitos e conclusão limitada ao cenário. Preservado
bloqueio do gate final; medição não o substitui.

Implementação: `example/measure_delta_size.dart` cria `shopper-a` e `shopper-b`,
cada uma com mutação LWW de nome e incremento G-Counter, usando IDs/valores fixos e
relógio HLC injetado. Conta bytes UTF-8 de JSON compacto para `DeltaCodec`,
`DeltaEnvelope` v2 e `Replica.toSnapshotJson()`. README documenta execução,
metadados contados/excluídos, dados e resultado. Nenhuma dependência ou API de
produção foi alterada.

Review: aprovado

Review em etapa distinta pelo mesmo agente, não independente. Conferidos o cenário
contra a demo offline, HLC determinístico, codec/envelope reais e comparação de
duas mensagens destinadas a peers fixos com snapshots locais pré-reconexão.
Medida não inclui compressão, transporte, headers nem custo SQLite; claim delimitado
ao JSON/payload medidos. Sem achados impeditivos.

Achados: nenhuma correção necessária. Volume pequeno de estado faz envelope ficar
próximo do snapshot; resultado não sustenta ganho geral.

Validação: aprovada

`dart format --output=none --set-exit-if-changed example/measure_delta_size.dart`
passou sem mudanças; `dart analyze example/measure_delta_size.dart` sem issues;
`dart run example/measure_delta_size.dart` passou e foi repetido com saída idêntica.
Resultados: A delta 454 B/envelope 539 B/snapshot 627 B; B 455/540/628 B;
totais 909/1.079/1.255 B. Envelopes/snapshots = 86,0% neste caso.

Comandos: `dart format example/measure_delta_size.dart`;
`dart format --output=none --set-exit-if-changed example/measure_delta_size.dart`;
`dart analyze example/measure_delta_size.dart`;
`dart run example/measure_delta_size.dart` (duas execuções, depois uma terceira
após review); `python3 scripts/check_plan.py`; `git diff --check`.

Critérios: README e exemplo mostram mutações, metadados e serialização JSON UTF-8;
script mede delta, envelope e snapshot reais com entradas reproduzíveis. O total
comparou duas mensagens locais com os dois snapshots pré-sync. A conclusão registra
14,0% menos bytes para envelope neste cenário e proíbe extrapolar para compressão,
rede ou payloads gerais.

Manutenção: VAL-06 concluída em fase/índice, fase 5 ativa, tarefa ativa limpa.
VAL-05 continua bloqueada por OPEN-05/RISK-10; não há próxima tarefa selecionável
até chegar fonte editável. `DECISIONS.md` sem mudança. Checker e `git diff --check`
executados após manutenção.

Limitações: medição sintética, dois CRDTs, quatro mutações, JSON sem whitespace,
SQLite e transporte não medidos. Review não independente. VAL-05 continua bloqueada;
esta medição SHOULD não conclui o TCC.

<a id="execucao-val-05-2026-10-11"></a>

## Execução VAL-05 — 2026-10-11

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Escopo: revisão do plano técnico, sem editar código, `proposta.md` ou texto do TCC.
Escrita e revisão acadêmicas ficam com o autor e fora do plano DeltaSync.

Leitura: VAL-05 estava bloqueada por exigir fonte editável e alinhamento do
relatório acadêmico. VAL-06 e demais tarefas técnicas MUST estavam concluídas.
Critérios e evidências de VAL-01/02/03/04, R-07a/b/c/d e R-08a/b/c/d foram
conferidos; limites de plataforma, topologia e usabilidade seguem documentados.

Implementação: plano ajustado para separar fechamento técnico da escrita do TCC.
VAL-03/04 foram renomeadas conforme suas entregas no repositório; VAL-05 foi
redefinida como gate técnico. `DECISIONS.md` e `RISKS.md` não tratam mais fonte,
relatório ou prazo acadêmico como pendências do plano técnico. `proposta.md` e o
TCC não foram alterados.

Review: aprovado

Review documental em etapa distinta; não independente. A matriz e a documentação
do repositório cobrem o cenário e a arquitetura entregues. Nenhum critério técnico
MUST depende de edição do relatório acadêmico.

Achados: o bloqueio de VAL-05 era uma dependência acadêmica fora do foco DeltaSync.
Evidências técnicas já cobrem todos os requisitos MUST; nenhum achado técnico
impeditivo permanece.

Validação: aprovada

Mudança documental. O checker confirma tarefas e links; `git diff --check` confirma
o diff. Testes Dart não foram repetidos: código não mudou e evidências de runtime
permanecem nos registros das tarefas correspondentes.

Comandos: `python3 scripts/check_plan.py`; `git diff --check`.

Critérios: demonstração, matriz e documentação técnica correspondem aos resultados
registrados em VAL-01/02/03/04; tarefas técnicas MUST concluídas; limitações de
plataforma, topologia e usabilidade explicitadas. Escrita e revisão acadêmicas
foram excluídas do gate, sem declarar conclusão do TCC.

Manutenção: VAL-03 passou a “Matriz de evidências e rastreabilidade”; VAL-04,
“Documentação de arquitetura e integração”; VAL-05, “Fechamento técnico da
biblioteca”. VAL-05 concluída, fase 5 concluída, tarefa ativa limpa. OPEN-05/06 e
RISK-10 removidos como pendências acadêmicas externas ao escopo técnico. Histórico
anterior permanece preservado nesta rastreabilidade. Não há próxima tarefa técnica
selecionável.

Limitações: esta conclusão fecha somente o escopo técnico da biblioteca. Não
declara conclusão, revisão ou alinhamento do TCC.

<a id="revisao-tecnica-2026-10-11"></a>

## Revisão técnica — 2026-10-11

Escopo: implementação, plano e PDF de referência, antes do pedido de manutenção
MoSCoW. Revisão sem correção de código ou escrita do TCC. Ambiente: Dart 3.13.5,
Linux x64, SQLite real via sqflite_common_ffi.

Validação executada na revisão: analyze sem issues e 155 testes aprovados:
raiz 7, core 72, sync 38, storage 12, storage_sqflite 14, storage_testing 6,
transport 6. Aprovação da suíte existente não cobriu os três casos abaixo.

Comando da suíte:

```bash
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && /opt/flutter/bin/dart analyze && /opt/flutter/bin/dart test --reporter expanded) || exit 1
done
```

Diagnósticos adicionais, reproduzidos em script temporário pela API pública:

1. **R-11 — conflito de ID pendente.** Criar duas Replica('a') separadas, cada
   uma com HlcClock(nowMilliseconds: () => 100). setDelta('name', 'old') e
   setDelta('name', 'new') produzem mesmo ID a:delta:1 com conteúdo diferente.
   Commit do snapshot/entrada old e depois new, ambos destinados ao peer b:
   MemoryStorage rejeita o segundo com FormatException; SQLite retorna sucesso,
   loadReplica recupera name=new e pending conserva name=old. Causa localizada
   em ConflictAlgorithm.ignore de commit; enqueue usa a mesma política, mas esse
   caminho não foi reproduzido separadamente. Não indica colisão em geração
   normal de IDs únicos; comprova divergência do contrato diante de ID reutilizado.
2. **R-12 — retry de abertura.** Factory injetada lança StateError na primeira
   openDatabase e usaria SQLite real na segunda. Duas loadReplica consecutivas
   falham, com apenas uma chamada à factory. Após close explícito, capturando
   seu erro, nova loadReplica funciona e total de aberturas passa a dois.
   _opening guarda Future falho; integração de start/retry precisa regressão
   permanente, além do caso direto do adaptador já reproduzido.
3. **R-10 — LWW tipado.** LwwRegister<List<int>> recebe LwwDelta<List<int>>
   com value=[1, 2], timestamp=HlcTimestamp(100, 0), origem a e ID a:delta:1.
   applyDelta lança `type 'List<Object?>' is not a subtype of type 'List<int>?'`.
   A cópia JSON muda o tipo runtime; value/winner e factory JSON contêm casts
   semelhantes que precisam ser avaliados pela tarefa, sem alegar reprodução
   individual de todos eles.

Localização: `packages/deltasync_storage_sqflite/lib/src/sqflite_replica_storage.dart`
(_database, commit, enqueue), `packages/deltasync_core/lib/src/lww_register.dart`
(applyDelta, value, winner) e `lww_delta.dart` (fromJson). Script diagnóstico
temporário não constitui suíte permanente; R-10/R-11/R-12 exigem essas regressões.

Comando do diagnóstico:
`/opt/flutter/bin/dart --packages=/projetos/tcc/deltasync/.dart_tool/package_config.json /tmp/deltasync-review-probes.dart`.
Resultados essenciais e entradas foram preservados acima, sem depender da retenção
do arquivo temporário como evidência de conclusão.

Demonstração reexecutada em processos separados: modo offline preservou duas
pendências por réplica e erro de peer indisponível; reconnect restaurou estado,
convergiu para Ana/Beto com contador 5, esvaziou outboxes e confirmou reabertura.
Comandos: `/opt/flutter/bin/dart run example/offline_reconciliation.dart offline /tmp/deltasync-review-demo.eUncZH`
e `/opt/flutter/bin/dart run example/offline_reconciliation.dart reconnect /tmp/deltasync-review-demo.eUncZH`.
Medição repetida com `/opt/flutter/bin/dart run example/measure_delta_size.dart`:
909 B de deltas, 1.079 B de envelopes e 1.255 B de snapshots; resultado restrito
ao cenário, sem promessa geral de desempenho.

Conclusão da revisão: arquitetura e oito tipos preservados; três defeitos
confirmados impedem manter fechamento técnico. Mobile não foi executado.
Correções e regressões ainda pendentes; escrita do TCC fica com o autor.

<a id="manutencao-moscow-2026-10-11"></a>

## Manutenção MoSCoW — 2026-10-11

Pedido: incorporar correções da revisão ao planejamento segundo MoSCoW.
Skill aplicada: plan-maintainer; validação documental com plan-validator.

Leitura: diagnósticos da revisão, índice, fases 1/3/5, decisões, riscos e checker.
Worktree já continha alterações autorizadas em cinco documentos do plano;
essas alterações foram preservadas.

Alteração: R-10/R-11/R-12 são MUST prontas, com critérios e evidências futuras
definidos nas fases. Prioridade recomendada R-11, R-12, R-10, VAL-05; dependências
entre correções independentes não foram inventadas. VAL-07 é SHOULD planejada,
dependente das correções; adiamento exige justificativa e não bloqueia VAL-05.
Não foram adicionadas funcionalidades COULD ou ampliadas extensões WON'T-YET.

Manutenção: fases 1/3/5 reabertas; VAL-05 planejada com dependências novas e
critérios de revalidação. Índice, matriz, DEC-24 e RISK-18 a RISK-21 atualizados.
Histórico de fechamento anterior preservado, com diagnóstico posterior explícito.
Descrições antigas de integração/restauração e VAL-06 foram atualizadas.
Nenhuma tarefa de produto iniciada; próxima recomendada R-11.

Review: aprovado

Revisão documental em etapa distinta, pelo mesmo agente; não independente.
Critérios de VAL-05 reabertos para coleções tipadas, atomicidade/recuperação,
documentação e regressões finais. Conferidos escopo técnico, correspondência
índice/fases, dependências, prioridade e limites dos diagnósticos. Review ajustou
contagem do workspace e evitou declarar reproduzidos todos os casts/caminhos.

Validação: aprovada

Checks documentais: `python3 scripts/check_plan.py` aprovou 30 tarefas e 127 links
locais, sem ciclos ou divergência de status/dependências; prontas R-10/R-11/R-12.
`git diff --check` passou. Conferidos diff, anchors e frontmatter das skills.
Não foram repetidos testes Dart nesta manutenção: código não mudou; os resultados
de runtime acima pertencem à revisão anterior, sem validar futuras correções.

Comandos: `python3 scripts/check_plan.py`; `git diff --check`; `git diff --stat`;
`git diff -- plan/01_PHASE1_CORRECOES.md plan/03_PHASE3_PERSISTENCIA.md`;
`git diff -- plan/README.md plan/05_PHASE5_VALIDACAO.md`;
`git diff -- plan/DECISIONS.md plan/RISKS.md`; `git diff -- plan/TRACEABILITY.md`.

Limitações: manutenção documental não corrige bugs, não comprova mobile e não
conclui novamente VAL-05. TCC e proposta de referência não foram editados.

<a id="execucao-r-11-2026-10-12"></a>

## Execução R-11 — 2026-10-12

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-11 era a próxima tarefa recomendada e estava pronta; R-07b/R-07c/R-07d
concluídas. Diagnóstico de 2026-10-11 demonstrou snapshot novo e outbox antiga
para mesmo ID pendente divergente no SQLite. Contrato MemoryStorage já rejeitava
pela regra `Delta.merge`. Worktree tinha sete documentos do plano modificados;
foram preservados. Fluxo de consumo usa `ReplicaStorage.commit` em edição local,
`enqueue` em importação e `pending`/`markSent` para envio; regra vive no contrato
e nos adaptadores, sem mudança em core ou sync.

Implementação: `SqfliteReplicaStorage.commit` e `enqueue` chamam uma verificação
compartilhada dentro da transação SQLite. Chave é réplica, peer e ID. Entrada já
existente é decodificada; `Delta.merge` compara conteúdo estrutural do delta.
Equivalência preserva status, tentativas, criação e envio; divergência lança
`FormatException` antes de confirmar transação. Snapshot e entradas já inseridas
no lote voltam ao estado anterior. Contrato público documentado em
`packages/deltasync_storage/lib/src/replica_storage.dart`; caminho de consumo em
`README.md` e limite do adaptador em
`packages/deltasync_storage_sqflite/README.md`. Nenhum schema, formato JSON ou
assinatura pública mudou.

Review: aprovado

Achados: primeira revisão detectou que a regressão de duplicata reutilizava o
mesmo objeto e não demonstrava equivalência estrutural. Teste ajustado para
duas réplicas com o mesmo ID/HLC e mapas JSON equivalentes em ordens distintas.
Diff corrigido revisado novamente, inclusive rollback, isolamento por peer,
compatibilidade persistida e custo de consulta por entrada. Sem achado impeditivo
restante. Review feito pelo implementador em etapa distinta; não independente.

Validação: aprovada

Ambiente: Dart 3.13.5, Linux x64, SQLite real via sqflite_common_ffi.
Format de `lib test` nos três pacotes afetados: zero mudanças. Analyze sem issues
e 160 testes aprovados no workspace: raiz 7, core 72, sync 38, storage 12,
storage_sqflite 17, storage_testing 8, transport 6. A suíte compartilhada roda
em MemoryStorage e SQLite real. Testes novos cobrem duplicatas equivalentes com
JSON aninhado e metadados enviados, conflito em enqueue e commit com entrada
inserida antes do conflito, e rollback após fechar/reabrir banco. Erro
`FormatException` é observado pelo consumidor da Future pública. Teste existente
de schema incompatível passou sem alteração destrutiva.
Após manutenção, `python3 scripts/check_plan.py` passou: 30 tarefas, 129 links
locais e próximas prontas R-10/R-12. `git diff --check` passou.

Comandos: `/opt/flutter/bin/dart format` nos quatro arquivos Dart editados;
`/opt/flutter/bin/dart format --output=none --set-exit-if-changed` nos mesmos
arquivos; para `packages/deltasync_storage`,
`packages/deltasync_storage_sqflite` e `packages/deltasync_storage_testing`,
`/opt/flutter/bin/dart format --output=none --set-exit-if-changed lib test`;
`/opt/flutter/bin/dart --version`; em `.`, `packages/deltasync_core`,
`packages/deltasync_sync`, `packages/deltasync_storage`,
`packages/deltasync_storage_sqflite`, `packages/deltasync_storage_testing` e
`packages/deltasync_transport`: `/opt/flutter/bin/dart analyze` e
`/opt/flutter/bin/dart test --reporter expanded`;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: 1) commit/enqueue rejeitam divergência na mesma chave por `Delta.merge`;
2) equivalência idempotente preserva metadados, inclusive com mapas em ordens
distintas; 3) transação desfaz snapshot, clocks e outbox após conflito tardio;
4) suíte compartilhada passou em memória e SQLite; 5) SQLite real recuperou
snapshot, valor e metadados originais após reabertura; 6) contrato/documentação
explicam comportamento e compatibilidade sem histórico ilimitado ou migração.

Manutenção: R-11 concluída na fase e índice; fase 3 ainda pendente de R-12.
DEC-25 fixa equivalência por chave/Delta.merge; RISK-18 foi mitigado para SQLite
FFI/Linux x64. R-10/R-12 permanecem prontas; R-12 é próxima recomendada.
VAL-05 continua planejada até os MUST restantes, sem conclusão do TCC.

Limitações: plugin Flutter mobile não foi executado; VAL-07 continua SHOULD.
Teste de persistência usa SQLite FFI/Linux x64. R-10 e R-12 permanecem sem
correção. O checker verifica estrutura do plano, não semântica do código.

<a id="execucao-r-12-2026-10-12"></a>

## Execução R-12 — 2026-10-12

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-12 era a próxima tarefa recomendada e estava pronta; R-05/R-07c/R-07d
concluídas. Diagnóstico de 2026-10-11 reproduziu duas falhas de `loadReplica`
após uma única falha de `openDatabase`. Inspecionados `_database`, `close`,
`SyncEngine.start`, testes de recuperação SQLite e decisões DEC-19/22.
Worktree continha mudanças autorizadas de planejamento e R-11, preservadas.
Responsabilidade local: adaptador mantém abertura; engine controla lifecycle e
restauração; estado, delta e commit continuam nos contratos existentes.

Implementação: `_database` reaproveita Future em curso/bem-sucedido; falha limpa
`_opening` apenas se ele ainda aponta para aquela tentativa. `catchError` repassa
erro com stack original. `close` continua limpando referência e aguardando a
abertura capturada. Não houve mudança em schema, JSON, API pública, core ou sync.
`packages/deltasync_storage_sqflite/README.md` e `README.md` explicam retry,
restauração antes da edição e limite de schema. Quatro regressões novas em
`packages/deltasync_storage_sqflite/test/sync_recovery_test.dart` usam factory
controlada para a falha inicial e SQLite FFI real para persistência e reabertura.

Review: aprovado

Achados: diff revisado após implementação. Nenhum achado impeditivo; conferidos
erro original, compartilhamento de tentativa, proteção contra falha antiga,
interação com `close`, lifecycle, outbox e preservação de dados em schema
incompatível. Revisão feita pelo implementador em etapa distinta; não independente.
Testes com falha injetada isolam abertura; a recuperação usa SQLite real.

Validação: aprovada

Ambiente: Dart 3.13.5, Linux x64, sqflite_common_ffi com SQLite real. No pacote
`packages/deltasync_storage_sqflite`, format de `lib test` sem mudanças, analyze
sem issues e 21 testes aprovados. `SyncEngine.start` falhou de forma observável,
voltou a `created` e iniciou na segunda tentativa do mesmo adapter; snapshot e
outbox antigos foram recuperados antes de nova mutação. Duas chamadas simultâneas
usaram uma abertura falha; retry seguinte abriu o banco. Falha antiga após
`close` não limpou conexão posterior bem-sucedida. Schema v2 incompatível falhou
duas vezes e manteve snapshot no banco. Testes prévios de recuperação/contrato
do pacote também passaram. Os outros pacotes não foram repetidos porque o código
alterado pertence apenas ao adaptador; a integração com SyncEngine foi executada
na suíte SQLite.

Comandos: `/opt/flutter/bin/dart format` nos dois arquivos Dart editados;
em `packages/deltasync_storage_sqflite`,
`/opt/flutter/bin/dart format --output=none --set-exit-if-changed lib test`,
`/opt/flutter/bin/dart analyze` e
`/opt/flutter/bin/dart test --reporter expanded`;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: 1) Future falho sai do cache e a mesma instância abre novamente;
2) concorrentes compartilham tentativa e erro antigo não invalida sucesso novo;
3) `SyncEngine.start` retry recupera snapshot/outbox antes de nova edição;
4) regressões cobrem falha, concorrência, `close` e recuperação SQLite real;
5) schema incompatível permanece rejeitado e os dados continuam presentes;
6) consumo e limites documentados sem dependência nova em core/sync.

Manutenção: R-12 concluída na fase e índice; fase 3 concluída. DEC-26 registra
semântica do cache e RISK-15/19 foram atualizados para o cenário validado.
Tarefa ativa limpa; R-10 é próxima MUST pronta. VAL-05 continua planejada até
R-10 concluída. A escrita do TCC permanece com o autor.

Limitações: validação SQLite FFI/Linux x64; plugin Flutter mobile não foi
executado e VAL-07 segue SHOULD. R-10 permanece pendente. Review não independente.

<a id="execucao-r-10-2026-10-12"></a>

## Execução R-10 — 2026-10-12

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-10 era a próxima MUST pronta após R-09a/R-09b e R-11/R-12.
Diagnóstico prévio de 2026-10-11 reproduziu cast de `List<Object?>` para
`List<int>` em `LwwRegister.applyDelta`. Leitura de core, Replica, SyncEngine,
README, DEC-16/18 e critério da fase confirmou perda de tipos também em
`fromJson`/consultas. Worktree inicial estava limpa. SDK: Dart 3.13.5.

Implementação: `LwwDelta` agora copia JSON na construção e devolve cópia em
`value`; `LwwRegister` guarda vencedor JSON canônico e converte na borda pública.
`decodeValue` explicita reconstrução de listas/mapas tipados e preserva conteúdo
JSON; ausência de conversão compatível gera `FormatException`. `Replica.setDelta`
entrega delta isolado da entrada mutável. HLC, desempate, tombstone, wire JSON e
snapshots ficaram com formato anterior. `const LwwDelta` foi removido por exigir
cópia na construção; README documenta a troca por `final`/construção comum e o
uso da conversão em delta, register e restauração. Não houve framework de codecs.

Review: aprovado

Achados: primeira revisão achou conversão capaz de alterar conteúdo JSON; correção passou
a exigir equivalência estrutural. Segunda revisão achou `LwwDelta` direto ligado
à coleção fornecida; construtor foi alterado para capturar cópia e getter para
devolver cópia. Revisão final conferiu tipos, nulidade, join, ordem LWW, JSON,
compatibilidade pública, testes novos e diff, sem achado impeditivo remanescente.
Review pelo próprio implementador em etapa distinta, não independente.

Validação: aprovada

Ambiente Linux x64, Dart 3.13.5. Regressões novas em
`packages/deltasync_core/test/lww_typed_json_test.dart` cobrem lista, mapa
aninhado, isolamento de entrada/delta/consulta, JSON/restauração, conversão
inválida, nulidade, HLC/desempate e tombstone. Teste em
`packages/deltasync_sync/test/sync_engine_test.dart` cobre `Object?`, outbox e
restauração por MemoryStorage; core cobre Replica/snapshot. Na raiz e nos seis
subpacotes, `dart analyze` ficou sem issues e `dart test --reporter expanded`
passou. Formatação de `lib test` da raiz, core e sync passou após ajuste no teste
novo; teste focado core foi repetido após esse ajuste. Suíte SQLite FFI real
permaneceu verde, mas não foi adicionada prova mobile nesta tarefa.

Comandos: `/opt/flutter/bin/dart format` nos arquivos Dart editados;
`/opt/flutter/bin/dart format --output=none --set-exit-if-changed lib test`
na raiz, core e sync; `/opt/flutter/bin/dart analyze` e
`/opt/flutter/bin/dart test --reporter expanded` na raiz e nos seis subpacotes;
`/opt/flutter/bin/dart test test/lww_typed_json_test.dart` no core após ajuste;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: 1) contrato tipado via `decodeValue` e rejeição de JSON inválido;
2) apply, value/winner, join, JSON e restauração exercitados; 3) entrada e saída
isoladas, HLC/desempate/tombstones preservados; 4) regressões core, Replica e
SyncEngine permanentes; 5) consumo, formato e migração de `const` documentados.

Manutenção: R-10 e fase 1 concluídas; DEC-27 registra contrato, RISK-20 mitigado.
VAL-05 e VAL-07 liberadas por dependências; VAL-05 é próxima MUST recomendada.
Escrita e revisão do TCC permanecem com o autor.

Limitações: review não independente; VAL-07 ainda precisa de evidência
Flutter/mobile. A validação de restore nesta tarefa usa MemoryStorage; recuperação
durável SQLite permanece coberta nas tarefas anteriores e será reavaliada em
VAL-05.

<a id="execucao-val-05-2026-10-12"></a>

## Execução VAL-05 — 2026-10-12

Status final: concluída

Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: VAL-05 era a próxima MUST pronta, com VAL-03/VAL-04/R-10/R-11/R-12
concluídas e worktree limpa. Critérios, matriz, decisões e riscos foram
confrontados com os testes e com os registros das correções. O recorte é o
fechamento técnico da biblioteca; texto acadêmico pertence ao autor.

Implementação: `plan/TRACEABILITY.md` atualiza a matriz MUST com R-10/R-11/R-12 e
separa unidade, integração, recuperação SQLite e demo entre processos. `README.md`
corrige versão atual do snapshot de `Replica` para 8 e aponta regressões LWW
tipadas; `plan/README.md` atualiza prioridade técnica. Nenhum código, wire JSON,
schema ou API foi alterado nesta tarefa.

Review: aprovado

Achados: revisão do diff documental encontrou versão de snapshot desatualizada,
estado de VAL-05 inconsistente no índice durante o ciclo e matriz sem referência
explícita às correções. Ajustados e revistos novamente. Links, IDs, limites de
plataforma, contrato público e correspondência com testes conferidos. Sem achado
impeditivo restante. Review pelo próprio agente, não independente.

Validação: aprovada

Ambiente: Dart 3.13.5, Linux x64, SQLite real via `sqflite_common_ffi`.
`dart analyze` sem issues e `dart test --reporter expanded` aprovado na raiz e
nos seis subpacotes. A suíte SQLite incluiu recuperação dos oito CRDTs,
rollback de ID pendente divergente e retry após falha de abertura. A regressão
core incluiu listas/mapas LWW tipados, nulidade e isolamento; sync incluiu outbox,
ACK parcial e reordenação. A execução do exemplo usou dois processos separados:
`offline` registrou Ana/2 itens e Beto/3 itens, falha visível de peer e duas
pendências por réplica. `reconnect` restaurou ambas antes do envio, convergiu
para Ana/Beto e cinco itens, confirmou ACK, zerou pendências e reabriu os dois
bancos mantendo esse estado. Os arquivos SQLite finais tinham 24.576 bytes cada.
`python3 scripts/check_plan.py` verificou links, IDs, dependências e status;
`git diff --check` passou após a revisão.

Comandos: `/opt/flutter/bin/dart --version`; na raiz e nos seis subpacotes,
`/opt/flutter/bin/dart analyze` e `/opt/flutter/bin/dart test --reporter expanded`;
na raiz, `/opt/flutter/bin/dart run example/offline_reconciliation.dart offline /tmp/deltasync-val05.DsEW2I`
e, em outro processo,
`/opt/flutter/bin/dart run example/offline_reconciliation.dart reconnect /tmp/deltasync-val05.DsEW2I`;
`stat -c '%n %s bytes'` nos dois bancos;
`python3 scripts/check_plan.py`; `git diff --check`.

Critérios: 1) oito tipos e LWW tipado por testes core e SQLite; 2) commit,
clocks/outbox e restauração por SQLite real, R-11/R-12 e demo; 3) ACK/retry,
transporte e formatos por suítes sync/storage/transport; 4) documentação e
matriz alinhadas; 5) R-10/R-11/R-12 com review/regressões, suíte final e demo
executadas após as correções; 6) todos os MUST técnicos concluídos no escopo
declarado. A evidência é de cenários executados, não prova universal.

Manutenção: VAL-05 e fase 5 concluídas; índice e matriz atualizados. VAL-07 é
próxima tarefa pronta e SHOULD. Ela permanece separada do gate porque a execução
atual usa CLI/FFI Linux, e nenhum alvo mobile foi validado. DEC-24/27 e RISK-18/19/20
mantêm as correções; RISK-21 mantém a lacuna mobile. Escrita do TCC segue com o autor.

Limitações: review não independente; integração Flutter mobile e plugin sqflite
em dispositivo não executados. Demo usa transporte sintético em processo e peer
fixo; não demonstra protocolo de rede, topologia geral, usabilidade com
participantes nem desempenho universal. Adaptadores externos não inventariados.

<a id="execucao-val-07-2026-10-12"></a>

## Execução VAL-07 — 2026-10-12

Status final: bloqueada (SHOULD); critérios mobile 1–4 não demonstrados.

Leitura: VAL-07 foi selecionada após VAL-05 e suas dependências concluídas.
Critérios exigem consumidor Flutter com factory do plugin `sqflite`, duas réplicas
e dois tipos, falha/retry, convergência e recuperação SQLite após encerrar e
reabrir o processo em alvo mobile. A demo CLI/FFI Linux de VAL-05 não substitui
essa execução. DEC-24 permite adiamento justificado de SHOULD sem reabrir VAL-05.

Implementação: não realizada. O host não oferece alvo mobile no qual verificar
build/runtime; não foi introduzido consumidor Flutter sem possibilidade de
executar os critérios. O código da biblioteca não foi alterado.

Review: revisão do próprio agente sobre o escopo, a evidência VAL-05 e o diff
documental. Confirmado que o registro distingue Linux/FFI de plugin mobile e
não declara integração mobile validada. Não é revisão independente.

Validação: `flutter doctor -v` informou Flutter 3.47.6,
Dart 3.13.5, Linux x64 e `Unable to locate Android SDK`;
`flutter devices` listou somente Linux desktop;
`flutter emulators` informou ausência de fontes de emulador.
O autor confirmou não possuir Android SDK neste host. Build e runtime Android,
offline/reconexão e reinício de processo mobile não foram executados; iOS exige
ambiente Apple indisponível neste host Linux. Nenhum check desktop foi contado
como evidência mobile.

Manutenção: critério 5 registrado, VAL-07 bloqueada na fase e no índice,
RISK-21 atualizado. Os quatro critérios de execução seguem abertos; fases 1–5
permanecem concluídas nos MUST. Retomar quando houver SDK Android e dispositivo
ou emulador, ou ambiente iOS com alvo. Ainda será preciso criar e executar o
consumidor Flutter, revisar seu diff e registrar build/runtime e recuperação.

<a id="execucao-val-07-2026-10-12-mobile"></a>

## Execução VAL-07 — 2026-10-12 — Android físico

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: retomada de VAL-07 após o autor instalar Android SDK. Dependências
VAL-02/R-10/R-11/R-12 estavam concluídas. `flutter doctor -v` confirmou SDK em
`/home/yago/Android/Sdk`, licenças aceitas e toolchain Android disponível.
AVD foi iniciado e encerrado antes de qualquer validação, pois o autor escolheu
seu celular físico. ADB detectou Moto G52 autorizado. O impedimento anterior
permanece no registro histórico, sem converter evidência desktop em mobile.

Implementação: consumidor mínimo em `example/flutter_mobile/`, com scaffold
Android gerado pelo Flutter. `lib/main.dart` compõe duas `SyncEngine`, duas
instâncias de `SqfliteReplicaStorage`, LWW para nomes e G-Counter para itens.
`getDatabasesPath()` e `databaseFactory` vêm do plugin `sqflite`; não há FFI
no app. Cada réplica usa um arquivo SQLite próprio. Botões editam offline e
reconectam o peer fixo; logs/tela mostram valores, falha, pendência e confirmação.
Factory, estado, mutação, delta, join, commit e restauração usam contratos públicos.
Modelo, valores, mapeamento e enlace sintético permanecem no consumidor.
Workspace próprio e paths/overrides resolvem os pacotes locais sem adicionar
Flutter ao workspace Dart da biblioteca. Lockfile do app mantido para reprodução.
READMEs descrevem instalação, reinício, repetição, manutenção e limites.

Review: aprovado
Revisão realizada pelo próprio agente em etapa distinta; não independente.
Achados: repetir edição após reconectar somava novamente e deixava o link online;
o guard agora rejeita percurso já iniciado antes de mutações. Catch genérico
contava qualquer `StateError` como falha offline; agora exige mensagem do peer
esperado e verifica duas pendências em cada engine. Ambos corrigidos e revisados
novamente antes da validação. Nenhum achado impeditivo restante no escopo.
Não houve alteração de API, schema, JSON, core, sync ou contrato de storage.

Validação: aprovada
Ambiente: host Garuda Linux x64; Flutter 3.47.7 stable,
Dart 3.13.5, Android SDK/build-tools 36.0.0, compileSdk 36, JDK 25.0.3,
Gradle 9.3.1 e AGP 9.1.0. Alvo físico Motorola Moto G52, Android 13/API 33.
Plugin `sqflite` 2.4.4+1, `sqflite_android` 2.4.4 e `sqflite_common` 2.5.13+1.
APK debug compilado em 243,5 s; instalação via ADB retornou `Success`.
`flutter analyze`, format check e `dart analyze` na raiz passaram sem issues.

Percurso observado no aparelho:

| Processo/etapa | Resultado no log `VAL07` |
|---|---|
| PID 26048, abertura inicial | A e B sem nomes, itens=0, pendentes=0 |
| PID 26048, edição offline | Falha de envio em duas réplicas; A=Ana/-, itens=2, pendentes=2; B=-/Beto, itens=3, pendentes=2 |
| `am force-stop` | `pidof` vazio, exit 1; processo encerrado |
| PID 26365, restauração antes de enviar | Mesmos valores offline e duas pendências por réplica |
| PID 26365, reconexão/retry | A=B=Ana/Beto, itens=5, pendentes=0; ACK de deltas restaurados |
| Segundo `am force-stop` | `pidof` vazio, exit 1; segundo processo encerrado |
| PID 26810, restauração final | A=B=Ana/Beto, itens=5, pendentes=0 |
| PID 26810, tentativa de repetir edição | Rejeitada com `Percurso já iniciado`; reconexão posterior manteve itens=5 e pendentes=0 |

`run-as` confirmou `shopper-a.sqlite` e `shopper-b.sqlite` no diretório privado
do app, com 32.768 bytes cada. A UI foi conferida por hierarquia Android e captura
da tela final; o status convergente ficou visível. Reinícios usaram processos
distintos, sem hot reload/restart e sem substituir SQLite por memória.

Comandos: na raiz, `flutter doctor -v` e `dart analyze`; em
`example/flutter_mobile`, `flutter pub get`, `dart format lib/main.dart`,
`dart format --output=none --set-exit-if-changed lib`, `flutter analyze` e
`flutter build apk --debug`. A primeira resolução falhou porque os subpacotes
locais não estão no pub.dev; paths/overrides corrigiram e a resolução passou.
Um format check inicialmente falhou ao gravar telemetria fora do sandbox;
reexecução autorizada passou. ADB foi chamado pelo caminho
`/home/yago/Android/Sdk/platform-tools/adb`, selecionando Moto G52 com `-s` nas
primeiras operações: `devices -l`, `install -r build/app/outputs/flutter-apk/app-debug.apk`,
`shell getprop ro.build.version.release`, `shell getprop ro.build.version.sdk`,
`shell am start -n com.example.deltasync_mobile_consumer/.MainActivity`,
`shell pidof com.example.deltasync_mobile_consumer`, `logcat -d --pid=<PID> -s flutter:I`,
`shell uiautomator dump /sdcard/deltasync-val07.xml`, `shell input tap 540 445`,
`shell input tap 540 565`, `shell am force-stop com.example.deltasync_mobile_consumer`
e `shell run-as com.example.deltasync_mobile_consumer ls -l databases`.
Coordenadas foram obtidas da hierarquia da tela neste aparelho, não são universais.

Critérios: 1) APIs públicas, factory mobile e alvo/SDKs registrados;
2) LWW/G-Counter, duas réplicas, edição offline, erro visível, pendências e
convergência comprovados no aparelho; 3) primeiro reinício preservou estado/outbox
para retry, segundo preservou confirmação; 4) configuração, build/runtime e
instruções de consumo/manutenção registradas; 5) impedimento anterior justificado
no histórico e resolvido com instalação do SDK e uso do celular físico.

Manutenção: cinco critérios marcados na fase; índice, matriz, READMEs e RISK-21
atualizados. VAL-07 concluída; nenhuma tarefa ativa ou próxima tarefa pronta.
VAL-05 permanece concluída nos MUST, sem expansão do escopo acadêmico.
`python3 scripts/check_plan.py` passou: 30 tarefas, 140 links locais e nenhuma
tarefa pronta. A primeira checagem exigiu valores exatos nos campos Review/Validação;
a redação foi corrigida e revista, sem mudar a evidência. `git diff --check` passou.

Limitações: um aparelho Android 13, build debug, dois CRDTs e duas réplicas no
mesmo app com enlace sintético e peer fixo. Não valida iOS, todos os aparelhos,
rede/protocolo real, oito CRDTs no plugin mobile, desempenho ou usabilidade com
participantes. Suítes gerais de oito tipos e falhas continuam na evidência VAL-05;
não foram reexecutadas por esta mudança no consumidor. Escrita do TCC fica com o autor.

<a id="revisao-geral-2026-10-12"></a>

## Revisão geral — 2026-10-12

Escopo: implementação, consumidor Flutter, testes, planejamento e PDF capítulos
6/7; procedimento code-reviewer, leitura e diagnóstico sem correções de produto.
A arquitetura modular, os oito tipos e o adaptador SQLite permanecem coerentes
com o recorte. Execução Android anterior é evidência real de persistência do
percurso fixo, não comprova toda a experiência de consumo ou ausência de bugs.

Achados e encaminhamentos:

| Achado | Evidência e impacto | Encaminhamento |
|---|---|---|
| Gravidade média: igualdade/hash de VectorClock | [Código](../packages/deltasync_core/lib/src/vector_clock.dart): relógios vazio e `{a: 0}` comparam iguais, têm hashes diferentes e ambos permanecem em Set | R-13 MUST; regressão de Set/Map e compatibilidade de zeros |
| Gravidade média: sequência MV inválida aceita | [Restauração](../packages/deltasync_core/lib/src/mv_register.dart): snapshot de dot próprio 1 com sequence 0 é aceito; próxima escrita falha | R-14 MUST; rejeição anterior à publicação do estado e integração de restore/start |
| Gravidade média, por inspeção: UI sem retry após falha inicial | [Consumidor](../example/flutter_mobile/lib/main.dart): catch de _open não libera estado ocupado nem oferece nova tentativa | R-15 MUST; ainda falta reprodução Flutter da falha e regressão |
| Contrato de retry impreciso | [README](../README.md) chama retries de automáticos; [sync](../packages/deltasync_sync/lib/src/sync_engine.dart) filtra pendências quando push é chamado, sem agendador | R-18 MUST; corrigir descrição, sem exigir scheduler |
| Demonstração estreita | Nomes são escritos em endereços distintos, valores são fixos, edição se limita a um percurso e enlace é sintético no mesmo app | VAL-08 SHOULD; campo compartilhado, duas visões e continuidade offline |
| Cobertura algébrica com fixtures pequenas | Testes inspecionados, inclusive [MV](../packages/deltasync_core/test/mv_register_test.dart), comparam valores visíveis em vários joins; cobertura anterior é finita e manual | VAL-09 SHOULD; histórias, metadados normalizados e operações posteriores |
| Limite de bytes e custo local | 100 escritas LWW pendentes no mesmo campo: envelope 20.117 B, snapshot 452 B; pipeline copia réplica e persiste snapshot integral | VAL-10 SHOULD; cargas favoráveis/desfavoráveis e custo medido, sem otimização prematura |
| Notificação de sucesso ausente | SyncEngine.errors informa falhas, sem stream público de commits concluídos para consumidores | R-17 COULD; evento Dart mínimo, se houver margem |

Reprodução local executada com Dart 3.13.5, Linux x64, APIs públicas, sem rede,
sem banco e sem editar arquivos de produto. Script temporário:
`dart --packages=/projetos/tcc/deltasync/.dart_tool/package_config.json /tmp/deltasync-review-2026-10-12.dart`.
Trecho reproduzível dos dois defeitos, com import de `package:deltasync/deltasync.dart`:

```dart
final empty = VectorClock();
final zero = VectorClock({'a': 0});
print(empty == zero); // true
print(empty.hashCode == zero.hashCode); // false na execução observada
print({empty, zero}.length); // 2 na execução observada

final original = MvRegister('a', crdtId: 'field')..write('old');
final encoded = original.toJson()..['sequence'] = 0;
final restored = MvRegister.fromJson(encoded); // aceita entrada inconsistente
restored.write('next'); // ArgumentError: Invalid MV-Register delta identity or context
```

A terceira reprodução criou Replica('a'), executou 100 setDelta('title',
'version-$i'), agrupou todos em DeltaEnvelope com destinatário 'b' e contou bytes
UTF-8 de jsonEncode(envelope.toJson()) e jsonEncode(replica.toSnapshotJson()).
Usou relógio padrão, não fixture temporal fixa. O snapshot foi contado sem wrapper
de transporte; números são observação de uma carga, não comparação universal de
protocolos. Não houve compactação de outbox nem alteração de causalidade.

Para R-14, a entrada foi tornada inconsistente deliberadamente; não foi encontrada
essa sequência nos bancos produzidos pelo exemplo. Para R-15, impacto foi inferido
do fluxo de UI, sem simular a falha no celular nesta revisão. Suíte completa não
foi reexecutada. As reproduções não são regressões permanentes; tarefas de correção
devem acrescentar testes e rever mudanças antes de validar.

Inventário inicial para refatoração: Replica tem 1.098 linhas; SyncEngine, 611;
replica_storage.dart, 425; main.dart do consumidor, 279. Linhas não são meta de
qualidade: interesse é separar snapshot/validação, contratos/políticas/execução
e UI/sessão/enlace quando reduzir esforço de mudança. Uma divisão proposta para
o core agrupa CRDTs, metadados, réplica e serialização; layout final deve ser
justificado na implementação de R-16, sem criar registry/framework novo.
Operation participa de migração em Delta/ReplicaState e testes. PendingDeltaStore
é exportado e usado no caminho legado de SyncEngine e suas regressões. Nenhum
desses símbolos foi comprovado morto. Arquivos manifest/Kotlin do app são scaffold
Android com uso no build. Remover arquivos por contagem ou depreciação seria inadequado.

Limites do parecer: manter arquitetura; corrigir defeitos localizados, melhorar
demonstração e evidência, refatorar com preservação. OR-Map segue composto por
G-Set; core sem Flutter; oito tipos, transporte abstrato, peer fixo, versões e
limites de plataforma são preservados. Review pelo próprio agente não é independente.

<a id="manutencao-revisao-refatoracao-2026-10-12"></a>

## Manutenção da revisão e planejamento da refatoração — 2026-10-12

Pedido: documentar correções da revisão geral e avaliar divisão de pastas/arquivos,
remoção de código morto e prazo de 16/11. Autor mantém escrita do TCC sob sua responsabilidade.
Procedimento: plan-maintainer; safe-refactor aplicado à delimitação do planejamento.

Alterações: criadas R-13/R-14/R-15/R-18 MUST, R-16 e VAL-08/09/10 SHOULD e R-17 COULD.
Critérios/checks vivem nas fases; índice espelha metadados. Reabertas fase 1 e
VAL-05; adicionadas dependências dos novos MUST, sem incluir SHOULD/COULD no gate.
Histórico de VAL-05/VAL-07 e demais conclusões preservado. Matriz identifica as
lacunas novas; RISK-09 e RISK-22 a RISK-26, DEC-28/29/30 e janelas de prazo atualizados.

Prazo: 16/11 interpretado como 2026; 35 dias desde 12/10. Sequência proposta:
correções até 18/10, refatoração delimitada até 25/10, demonstração/experimentos
até 01/11, congelamento estrutural em 02/11, validação até 08/11 e margem até 15/11.
Sem disponibilidade/estimativas, não há promessa de viabilidade. MUST precede
melhorias; adiamento SHOULD preserva critérios e evidências, sem falsa conclusão.

Review documental: IDs, dependências, prioridades, evidências e status conferidos;
refatoração preserva APIs/formato/semântica, com mesmas provas antes/depois;
nenhuma remoção pública ou novo backend/protocolo foi autorizada aqui.
Validação documental: `python3 scripts/check_plan.py` aprovado, com 39 tarefas,
170 links locais e dependências/status consistentes; `git diff --check` aprovado.
Revisão posterior corrigiu apresentação da tabela de riscos e atualizou resumo
dos gates para os novos IDs; checagens repetidas após essas correções.
Não há implementação nem novos testes Dart/Flutter nesta manutenção.

Próxima tarefa recomendada: R-14. R-13/R-15/R-18 também prontas; R-16/VAL-08/VAL-09
aguardam correções. R-17 e VAL-10 já têm dependências satisfeitas, mas não antecedem
os MUST por prioridade/risco. Tarefa ativa: nenhuma.

<a id="execucao-r-14-2026-10-12"></a>

## Execução R-14 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer

Leitura: R-06c/R-07a concluídas; R-14 pronta, MUST. O `MvRegister.fromJson`
aceitava `sequence` inferior a um dot da própria réplica em `context`, inclusive
dot cuja versão já fora substituída. O próximo `write` reutilizava a identidade e
falhava. `Replica.fromSnapshotJson` e `SyncEngine.start` propagavam essa aceitação.
Consultados contrato do snapshot, fluxo de restauração, testes existentes e guia
Dart para validação de JSON; nenhuma nova abstração foi necessária.

Implementação: `mv_register.dart` rejeita sequência inferior a dot local observado
antes de retornar o registro. `fromJson` também rejeita IDs de réplica/endereço
vazios, com espaços ou endereço legado, sem normalizar a entrada. JSON, versão,
política causal e banco não mudaram; snapshots válidos seguem aceitos. Regressões
em `mv_register_test.dart` cobrem sequência 0/1 contra dots 1/2, versão substituída,
ID inválido, dot remoto sem consumir contador local, restauração válida, próxima
escrita e rejeição via `Replica`. `sync_recovery_test.dart` grava dois valores em
SQLite real, altera deliberadamente a sequência no payload, fecha/reabre banco e
testa duas falhas de `start`, estado indisponível, payload intacto, reparo da fixture,
retry e nova escrita com dot 3.

Review: aprovado
Achados: normalização de ID e conexão compartilhada da fixture foram corrigidas; nenhum impeditivo restante.
Review feito pelo próprio implementador; não independente.
Primeiro review encontrou normalização silenciosa do ID de réplica no parser JSON;
foi corrigida e re-revisada. A primeira validação SQLite expôs que a conexão de
inspeção da fixture fechava a conexão compartilhada pelo adapter; foi isolada com
`singleInstance: false`, re-revisada e revalidada. Sem achado impeditivo restante.

Validação: aprovada
Ambiente: Linux x64, Dart 3.13.5, SQLite via sqflite_common_ffi.
Antes da implementação, `dart test test/mv_register_test.dart --reporter expanded`
falhou nas duas regressões de sequência/Replica; a regressão SQLite falhou porque
`start()` aceitava o snapshot inválido. Após correção, comandos com
`/home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart`:

Comandos: format, analyze e test executados nos pacotes afetados, com resultados abaixo.

- `format --output=none --set-exit-if-changed lib test`: core e SQLite adapter,
  0 arquivos alterados.
- `analyze`: raiz, core, sync e SQLite adapter, sem issues.
- `test --reporter compact`: raiz, core e sync aprovados; SQLite executado após
  revisão da fixture com `test --reporter expanded`, 22 testes aprovados.
- `test test/sync_recovery_test.dart --plain-name 'invalid MV sequence fails start without overwriting SQLite' --reporter expanded`:
  regressão durável aprovada após correção da fixture.

Critérios: (1) o contexto inteiro é verificado, incluindo dots sem versão ativa;
(2) `FormatException` explícita evita reutilização/normalização e preserva formato
válido; (3) testes core cobrem sequência atrasada, dot remoto e escrita posterior;
(4) teste SQLite comprova falha antes de adoção/publicação, bytes do payload sem
alteração e retry bem-sucedido após reparo. `SyncEngine.replica` permanece
indisponível enquanto o início falha; não houve sobrescrita do banco.

Manutenção: critérios e status de R-14 marcados na fase e índice; matriz e
RISK-23 atualizados. Fase 1 e VAL-05 continuam reabertas por R-13/R-15/R-18;
R-16/VAL-09 ainda aguardam R-13. Próxima tarefa recomendada: R-13. Sem mudança
de decisão arquitetural.
Limitações: entrada inválida injetada no teste; não observada no banco do app Android.
Validação mobile de R-14 não foi exigida, pois core/API/formato válido e plugin
Flutter não mudaram.

<a id="execucao-r-13-2026-10-12"></a>

## Execução R-13 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-02 concluída; R-13 pronta e MUST. `VectorClock.compare` considera
componente ausente igual a zero, mas `hashCode` incluía entradas zero. `entries`
é imutável, `toJson` conserva os valores fornecidos, e Replica/sync consomem o
clock pela API pública. Consultados tarefa, risco, código, testes e guia Dart.
Implementação: `VectorClock.hashCode` ignora entradas de valor zero antes de
`Object.hashAllUnordered`. A igualdade, `entries`, `compare`, `tick`, `merge`,
JSON e validação de entrada não mudaram. Novo `vector_clock_test.dart` verifica
zeros ausentes/presentes, múltiplas réplicas, ordem distinta de inserção,
deduplicação/consulta/atualização em Set e Map, clock diferente, round trip JSON
com zero, operações causais e rejeição de valores inválidos.
Review: aprovado
Achados: nenhum impeditivo; formatação posterior apenas quebrou linhas do teste e foi re-revisada.
Review feito pelo próprio implementador, não independente. Foi conferido o arquivo
novo não rastreado, contrato de igualdade/hash, compatibilidade de JSON e uso na
Replica e no caminho legado de sync. Nenhum tipo, camada ou formato foi criado.
Validação: aprovada
Comandos: Dart 3.13.5 em Linux x64; comandos e diretórios abaixo.

- Antes da mudança, em `packages/deltasync_core`:
  `/home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart test test/vector_clock_test.dart --reporter expanded`
  falhou nos dois testes de hash/coleções previstos; teste de JSON/causalidade passou.
- Após a mudança, no core:
  `/home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart format test/vector_clock_test.dart`
  formatou o teste; `format --output=none --set-exit-if-changed lib test` passou
  com zero arquivos alterados; `analyze` sem issues; `test --reporter expanded`
  aprovou 83 testes.
- Em `packages/deltasync_sync`, `analyze` sem issues e `test --reporter expanded`
  aprovou 39 testes. Na raiz, `analyze` sem issues e `test --reporter expanded`
  aprovou 7 testes pela facade pública.

Critérios: (1) testes verificam hash igual com ausência/zero, ordem e réplicas
múltiplas; (2) Set/Map deduplicam e recuperam chaves equivalentes; (3) compare,
tick, merge, JSON com zeros e entradas inválidas preservados e testados; (4)
facade e sync analisados/testados sem alteração de contrato ou relógio novo.
Zeros continuam presentes em `entries` e JSON; só o hash os desconsidera.
Manutenção: R-13 concluída na fase/índice; RISK-22 e matriz atualizados.
VAL-09 passou a pronta por dependências R-13/R-14 concluídas. R-16 ainda aguarda
R-18; fase 1 e VAL-05 seguem reabertas por R-15/R-18. Próxima recomendada: R-15.
Limitações: hash não prova convergência dos CRDTs; suíte cobre casos finitos e não altera plataforma Android.

<a id="execucao-r-15-2026-10-12"></a>

## Execução R-15 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: VAL-07 concluída; R-15 pronta e MUST. O consumidor Flutter ficava
ocupado após falha de `_open`, sem retry, e os botões não verificavam se a
sessão existia. Inspecionados abertura, `SyncEngine.start/dispose`, storage SQLite,
guia Dart, critérios, README e risco. Estado, mutação, delta, join e commit
continuam na biblioteca; sessão, enlace, valores fixos e UI pertencem ao app.
Implementação: `MobileConsumerApp` aceita factory/diretório SQLite opcionais para
teste; `_open` bloqueia reentrada, fecha sessão parcial e libera a UI em erro.
Editar/reconectar exigem sessão restaurada; **Tentar novamente** reabre os mesmos
bancos. `_DemoSession.open/close` tenta liberar engines, storages e links mesmo
quando uma etapa falha. `open_retry_test.dart` usa SQLite FFI real: primeira sessão
edita offline, segunda falha na abertura, retry duplo não cria sessão duplicada,
dados/outbox são restaurados e reconexão confirma ambos. README descreve uso e
regressão. Nenhuma API da biblioteca, formato persistido ou regra de CRDT mudou.
Review: aprovado
Achados: antes da validação, o próprio review encontrou possível reentrada por
dois toques no mesmo frame; guarda e teste adicionados, depois revistos. A primeira
validação apontou import redundante no teste; foi removido e revisto. A comparação
literal do snapshot falhou porque `start()` pode avançar HLC ao restaurar; o teste
passou a excluir apenas HLC da comparação de snapshots, mantendo estado, clock,
sequência e linhas brutas da outbox na comparação. Essa correção também foi revista.
Nenhum achado impeditivo restante. Review pelo implementador, não independente.
Validação: aprovada
Comandos: no `example/flutter_mobile`, Flutter 3.47.7/Dart 3.13.5 em Linux x64:

- Baseline `flutter test test/open_retry_test.dart --reporter expanded` falhou
  como esperado por ausência de **Tentar novamente** após erro injetado.
- `dart format --output=none --set-exit-if-changed lib test`: 0 alterações;
  `flutter analyze`: sem issues; `flutter test test/open_retry_test.dart
  --reporter expanded`: 1 teste aprovado após as correções e novo review.
- `flutter build apk --debug`: APK gerado. `adb install -r
  build/app/outputs/flutter-apk/app-debug.apk`: sucesso no Moto G52, Android
  13/API 33. `adb shell pm clear com.example.deltasync_mobile_consumer` limpou
  apenas os dados do app de demonstração para repetir o percurso.
- Após `adb shell am start -n
  com.example.deltasync_mobile_consumer/.MainActivity`, PID 16564 mostrou
  `A=-/-; itens=0 pendentes=0; B=-/-; itens=0 pendentes=0`; toque offline mostrou
  `A=Ana/-; itens=2 pendentes=2; B=-/Beto; itens=3 pendentes=2`.
- `adb shell am force-stop com.example.deltasync_mobile_consumer` deixou
  `adb shell pidof` sem PID. Novo processo 16970 restaurou os mesmos valores e
  duas pendências por réplica; após reconectar, exibiu
  `A=Ana/Beto; itens=5 pendentes=0; B=Ana/Beto; itens=5 pendentes=0`.
  Outro force-stop/restart gerou PID 17132 e restaurou convergência com zero
  pendências. Evidência: `adb logcat -d --pid=<PID> -s flutter:I`.

Critérios: (1) regressão confirma erro visível, botão de retry e ações sem engine
desativadas; (2) handle SQLite adquirido é fechado, dois toques fazem uma abertura,
linhas de estado/outbox não são apagadas e a reconexão confirma deltas uma vez;
(3) falha transitória seguida de sucesso restaura ambas as réplicas antes de
permitir ação, sem edição antecipada; (4) build e três processos Android mostram
outbox pendente e confirmação duráveis. Modelo/UI permanecem no consumidor.
Manutenção: R-15 concluída na fase e índice; VAL-08 tornou-se pronta; matriz,
RISK-24 e README atualizados. Fase 1 e VAL-05 seguem reabertas por R-18, próxima
tarefa recomendada. Sem nova decisão arquitetural.
Limitações: falha de abertura foi injetada no Flutter test/Linux, não no Android.
O cenário Android usa duas réplicas no mesmo app e peer sintético; iOS, rede real
e participantes não foram avaliados. Restauração pode avançar HLC sem edição.

<a id="execucao-r-18-2026-10-12"></a>

## Execução R-18 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-08c e VAL-04 concluídas; R-18 pronta e MUST. Conferidos README,
comentários públicos de `SyncEngine`/`SyncRetryPolicy`, seleção em `_prepareOutbound`,
`markSent`, testes de backoff/limite, exemplos CLI/Flutter, guia Dart, decisões e
riscos. `push()` só tenta enviar quando chamado; o consumidor é dono do agendamento.
Implementação: README e comentários públicos esclarecem `push()` explícito,
backoff desde `sentAt`, `maxAttempts`, `force`, ACK durável e caso de lote vazio.
README descreve atualização da UI após mutação e envio sem prometer stream de
commits. README Flutter distingue retry de abertura do envio por reconexão.
Limites de peer fixo, enlace sintético, OR-Map com G-Set, Android validado,
falha injetada só no teste Linux e ausência de economia universal permanecem
explícitos. Não houve alteração de lógica, API, schema ou formato persistido.
Review: aprovado
Achados: primeiro review identificou duas imprecisões: seleção apenas para o peer
configurado e valores de atraso como padrões configuráveis. Texto corrigido.
Também foi ajustada a descrição do status Flutter em erro de envio; segundo
review não encontrou achado impeditivo. Review pelo implementador, não independente.
Validação: aprovada
Comandos: em `packages/deltasync_sync`, Dart 3.13.5/Linux x64,
`dart format --output=none --set-exit-if-changed lib` passou com 0 alterações e
`dart analyze` passou sem issues. O diff documental foi comparado com
`SyncEngine._prepareOutbound`, `SyncRetryPolicy.delayFor`, `ReplicaStorage.markSent`
e os exemplos; links e status foram conferidos no checker do plano após manutenção.
Não foram executados testes Dart: só README e comentários mudaram, sem semântica.
Critérios: (1) contrato público e README dizem quem chama `push()`, elegibilidade,
atraso exponencial, teto de tentativas e bypass por `force`; (2) commit local,
pendência, ACK, falhas aguardadas/stream e atualização da UI foram distinguidos,
sem stream de sucesso inventado; (3) limites da topologia, composição OR-Map,
plataforma e medição permanecem delimitados; (4) APIs e exemplos foram conferidos
contra código atual e links locais preservados. Escrita do TCC permaneceu com o
autor.
Manutenção: R-18 concluída na fase e índice; R-16 e VAL-05 tornaram-se prontas.
Fase 1 mantém R-16 SHOULD na sequência proposta; VAL-05 fica para revalidar a
entrega após opcionais executados ou adiados. Matriz e RISK-22/25 atualizados.
Próxima tarefa recomendada: R-16. Sem nova decisão arquitetural.
Limitações: documentação descreve contrato existente; não há scheduler interno,
stream de commits ou nova execução de runtime nesta tarefa. Evidência Android
continua limitada a Moto G52/Android 13 de VAL-07/R-15.

<a id="execucao-r-16-2026-10-12"></a>

## Execução R-16 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimento adicional: safe-refactor, com baseline e prova após cada extração.
Leitura: R-13/R-14/R-18 concluídas; R-16 pronta e SHOULD. Inventário identificou
`Replica` com estado, mutação, snapshot e validação dos oito deltas; `SyncEngine`
com execução e tipos de resultado/política; `replica_storage.dart` com contrato,
DTOs e `MemoryStorage`. Core já separava os oito CRDTs, metadados, identidade,
clocks e codec. Testes core já estavam por tipo/comportamento; sync, storage,
SQLite e facade tinham suítes por contrato/fluxo, sem fixture duplicada que
justificasse movimentação. Guia Dart, DEC-29, RISK-26 e imports públicos conferidos.
`Operation` serve migração/fixture; `PendingDeltaStore` e aliases depreciados
continuam em contratos e regressões. Nenhuma remoção ficou comprovada.

Baseline anterior às extrações: Dart 3.13.5/Linux x64; `dart analyze` sem issues
nos sete pacotes/fachada; `dart test --reporter expanded` passou com 83 core, 39
sync, 12 storage, 8 storage_testing, 22 storage_sqflite, 6 transport e 7 raiz
(177). `flutter analyze` sem issues e `flutter test --reporter expanded` passou
1 teste em `example/flutter_mobile`.

Implementação: (1) `MemoryStorage` e auxiliares saíram de `replica_storage.dart`
para `memory_storage.dart`; análise e testes passaram em storage (12),
storage_testing (8), storage_sqflite (22), sync (39) e facade (7). (2)
`SyncFailureSource`, `SyncFailure`, `SyncPushResult` e `SyncRetryPolicy` saíram
de `sync_engine.dart` para `sync_types.dart`; testes passaram em sync (39),
SQLite (22) e facade (7). O analyzer apontou somente o uso depreciado no link
`PendingDeltaStore` do novo arquivo; a diretiva de lint local corrigiu isso,
e sync/facade foram analisados novamente sem issues. (3) Validação de lote,
identidade e vínculo endereço/tipo saiu de `Replica` para a extensão privada
em `replica_delta_validation.dart`; core analisou sem issues e passou 83 testes.
Cada extração usa `part` da library anterior, mantendo imports/exports públicos,
acesso privado, corpos de algoritmo e formatos. Estado, mutação, snapshot e
restauração continuam em `replica.dart`; join em cada CRDT; delta/codec nos
arquivos existentes; commit, envio/ACK e lifecycle em `sync_engine.dart`;
contrato/outbox em `replica_storage.dart`; SQLite no adaptador próprio.
README registra esse mapa. Exports e exemplos foram conferidos; usam os mesmos
imports e contratos, portanto não exigiram edição. O consumidor Flutter será
dividido em VAL-08, fora de R-16. Nenhum teste ou fixture foi movido sem ganho
concreto, e nenhum código foi removido.

Review: aprovado
Achados: inspeção do diff real, inclusive arquivos novos fora de `git diff`,
confirmou que os corpos movidos, assinaturas públicas, `part` e exports seguem
coerentes; não houve alteração de JSON/schema, ordem de commit, causalidade,
ACK/retry ou lifecycle. A diretiva de lint foi corrigida antes desta revisão.
Sem achado impeditivo restante. Review pelo implementador, não independente.

Validação: aprovada
Comandos: `dart format --output=none --set-exit-if-changed lib test` passou com
zero alterações nos sete pacotes/fachada e no consumidor Flutter. `dart analyze`
passou sem issues nos sete pacotes/fachada; `flutter analyze` passou sem issues.
`dart test --reporter expanded` repetiu os mesmos 177 testes (83/39/12/8/22/6/7)
com sucesso; `flutter test --reporter expanded` passou 1 teste de recuperação
SQLite FFI. `git diff --check` passou antes da manutenção. As suítes incluem
regressões de lote inválido sem efeito parcial, snapshots, integração de engines,
ACK, retry, rollback e reabertura SQLite. Como a integração Android não mudou,
build/runtime mobile não foram repetidos; VAL-07/R-15 continuam sendo a evidência
do Moto G52, não prova de novos alvos.

Critérios: (1) inventário e referências acima distinguem API/migração/fixtures
de código morto não demonstrado; (2) três fronteiras têm dono concreto sem
hierarquias/pastas artificiais; (3) disposição atual dos testes foi mantida após
avaliação; (4) baseline e checks por fronteira/finais preservam estados
verificáveis; (5) nenhuma API, label/versão JSON ou schema mudou e testes cobrem
invariantes relevantes; (6) nenhuma remoção sem prova ocorreu; (7) README mapeia
estado, mutação, delta, join, commit e restauração, com exports/exemplos estáveis.
Manutenção: R-16 concluída na fase e índice; RISK-26 atualizado; nenhuma nova
decisão arquitetural além de DEC-29. Próxima tarefa recomendada: VAL-08; VAL-05
segue pronta para revalidar a entrega após os SHOULD executados ou adiados.
Limitações: review não independente; testes são cenários finitos. Esta tarefa
não mede custo, não reexecuta dispositivo e não altera o consumidor Flutter.

<a id="execucao-val-08-2026-10-12"></a>

## Execução VAL-08 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-15 e VAL-07 concluídas; VAL-08 pronta e SHOULD. A versão anterior
concentrava entrada, UI, sessão e enlace em `lib/main.dart`, com botões de percurso
único, títulos fixos em endereços distintos e bloqueio de novas edições. A
baseline recente de R-16 aprovou análise e um teste Flutter; VAL-07/R-15
comprovavam plugin Android e retry da abertura. O guia Dart e DEC-15/29 orientaram
enum para lados fechados e divisão apenas por responsabilidades reais.

Implementação: `main.dart` ficou como entrada e reexporta `MobileConsumerApp`;
`demo_page.dart` apresenta A/B, título, contador, pendências, último erro,
confirmação e metadados do vencedor; `demo_session.dart` coordena duas
`SyncEngine.withStorage`, snapshots para UI e a limpeza restrita aos dois bancos;
`peer_link.dart` mantém ACK sintético só após `applyRemote` concluir. A e B editam
`shopping/title`, incrementam `shopping/items`, controlam o peer e solicitam
`push(force: true)` explicitamente. Edição local continua permitida offline,
com outbox pendente, após falha de envio e depois da reconexão. A limpeza pede
confirmação; testes verificam que outro banco no mesmo diretório permanece intacto.
READMEs descrevem fluxo, pontos de manutenção e diferença entre commit local,
tentativa, ACK e restauração. Nenhuma API, formato ou algoritmo da biblioteca mudou.

Review: aprovado
Achados: primeira revisão achou mensagem `Envio concluído` ambígua quando ainda
restassem pendências sem ACK e dois acessores públicos sem uso. Correção passou a
exibir `Envio sem confirmação completa`, removeu acessores e mostrou ID junto ao
HLC/origem do vencedor. Segunda revisão do delta corrigido não encontrou achado
impeditivo. O `PeerLink` confirma somente após commit remoto; a limpeza chama
`deleteDatabase` apenas para os dois caminhos da demo. Review pelo implementador,
não independente.

Validação: aprovada
Comandos: no `example/flutter_mobile`, Flutter 3.47.7/Dart 3.13.5,
`dart format --output=none --set-exit-if-changed lib test` passou com zero
alterações; `flutter analyze` passou sem issues; `flutter test --reporter expanded`
passou 4 testes. `demo_session_test.dart` cobre conflito, edição durante falha,
retry, dois estados após reabertura SQLite FFI e limpeza que preserva `other.sqlite`.
`open_retry_test.dart` injeta falha de abertura, verifica fechamento dos handles,
restauração de snapshot/outbox e reconciliação. `interactive_demo_test.dart` cobre
duas visões, erro, edição com pendência, ACK e limpeza cancelada/confirmada.
Falhas transitórias dos testes de UI durante implementação decorreram de busca em
widgets fora da viewport e animação do diálogo; controles/testes foram ajustados,
e a suíte completa passou após as correções. `flutter build apk --debug` gerou
`build/app/outputs/flutter-apk/app-debug.apk`; `adb install -r` retornou `Success`.

Runtime: Moto G52, Android 13/API 33, plugin `sqflite`, 2026-10-12. Após
`adb shell pm clear com.example.deltasync_mobile_consumer`, só dados da demo foram
limpos. PID 18985 abriu com A/B vazios; edições manuais geraram A=Alpha, B=Beta,
itens=1 e pendentes=2 em cada. `Enviar pendências` offline mostrou falha sem perder
outbox. Nova edição A=Gamma elevou pendentes A a 3 enquanto B manteve 2.
`adb shell am force-stop` deixou `pidof` sem PID; novo PID 20072 registrou
`VAL08 restored A=Gamma itens=1 pendentes=3; B=Beta itens=1 pendentes=2`.
Após ativar peer e enviar, log/UI mostraram A=B=Gamma, itens=2, pendentes=0;
vencedor LWW `shopper-a`, mesmo HLC/ID nas duas visões, e confirmação de 3/2 deltas.
Outra edição A=Delta gerou pendentes A=1 com B ainda Gamma; novo envio mostrou
A=B=Delta, itens=2, pendentes=0. Segundo force-stop deixou `pidof` vazio; PID
20397 restaurou A=B=Delta, itens=2, pendentes=0. Comandos usados: `adb shell
input` para controles, `adb logcat -d --pid=<PID> -s flutter:I` para estados e
`adb shell uiautomator dump`/captura para inspecionar as duas visões.

Critérios: (1) cards e teste UI mostram valores/pendências/erro/ACK separados e
switch do peer; (2) duas escritas LWW no mesmo endereço convergem pelo vencedor
HLC visível, com G-Counter nas duas réplicas; (3) FFI e Android mostram edições
durante pendência e após reconexão sem valores embutidos; (4) quatro arquivos têm
donos claros e usam API pública sem duplicar join/commit; (5) diálogo e teste de
banco sentinela limitam reset, com force-stop real documentado; (6) quatro testes,
APK e três PIDs comprovam falha, retry, convergência e restauração antes/depois
do ACK no Android. `git diff --check` passou antes da manutenção.
Manutenção: VAL-08 concluída na fase e índice; READMEs, matriz e RISK-21/24
atualizados. DEC-15/29 continuam suficientes, sem nova decisão arquitetural.
Próxima tarefa recomendada: VAL-10; VAL-05 segue pronta para revalidação final.
Limitações: A e B são réplicas no mesmo app e enlace sintético; teste FFI de
falha de abertura não foi repetido por injeção no Android. iOS, rede real,
participantes e outros aparelhos não foram avaliados. A mensagem de confirmação
é local à sessão de UI; snapshot/outbox persistem. Bancos de VAL-07 contêm
endereços de título antigos e pedem limpeza explícita para o novo percurso.

<a id="referencia-delta-cpp-2026-10-12"></a>

## Referência delta-crdts C++ e atualização do planejamento — 2026-10-12

Escopo autorizado: incorporar ao planejamento os ajustes úteis identificados na
referência fornecida pelo autor. Procedimentos: plan-reader, plan-maintainer e
plan-validator para checagem documental; análise anterior com code-reviewer.
Alterações existentes de VAL-08 foram preservadas. Esta manutenção não executa
R-19, VAL-09 ou VAL-10 e não modifica implementação nem escrita do TCC.

Fonte: clone em `/projetos/tcc/referencias/delta-crdts-c++`, origin
`https://github.com/CBaquero/delta-enabled-crdts.git`, commit
`cdbb909a53cb3ebc51f339b75bf5f42fc3555d15`. Inspecionados README, `delta-crdts.cc`,
`delta-tests.cc` e slides `KaiserslauternDeltaCPP2015.pdf`, extraídos com
`pdftotext`. As referências abaixo fixam o commit; o clone externo não é arquivo
necessário para build/test de DeltaSync.

Constatações estáticas:

- [DotContext](https://github.com/CBaquero/delta-enabled-crdts/blob/cdbb909a53cb3ebc51f339b75bf5f42fc3555d15/delta-crdts.cc#L166)
  combina prefixos causais contíguos com dots esparsos. Compactação absorve somente
  dots contíguos, mantendo lacunas; DotKernel une dados/contexto e remove payloads
  sem esquecer a observação causal. No DeltaSync, dots também têm `crdtId`, que
  deve acompanhar qualquer representação compacta.
- As mutações C++ retornam estados parciais do tipo do CRDT, com join de estado
  e delta no mesmo domínio. DeltaSync usa DTOs tipados separados; isso exige
  demonstrar equivalência da mutação com aplicação do delta e join do estado,
  não copiar a representação C++. `Delta.merge` apenas agrega/deduplica por ID.
- [MvRegister.write](../packages/deltasync_core/lib/src/mv_register.dart) passa
  todo `_context` observado ao delta. Em N escritas sequenciais locais desde
  contexto vazio, sem confirmação da outbox, os N deltas acumulam
  0+1+…+(N−1) = N(N−1)/2 referências a dots. Essa derivação não é medição de
  bytes, memória runtime ou latência. OR-Set guarda adições/remoções por evento;
  poucos valores visíveis não implicam poucos metadados retidos.
- O [LWW C++](https://github.com/CBaquero/delta-enabled-crdts/blob/cdbb909a53cb3ebc51f339b75bf5f42fc3555d15/delta-crdts.cc#L1328)
  só troca o valor com timestamp maior. Usar timestamp escalar igual e valores
  diferentes deixa o resultado dependente da ordem, salvo desempate incluído
  pelo chamador no timestamp. DeltaSync já compara HLC, replicaId e ID; não há
  justificativa para substituir essa política.
- README declara estágio experimental; testes C++ predominantemente imprimem
  exemplos, com poucas asserções. O OR-Map genérico tem composição diferente do
  OR-Map com G-Set entregue pelo DeltaSync. A referência serve para conceitos e
  cenários, sem funcionar como oráculo de todos os contratos atuais ou evidência
  de desempenho, persistência, ACK ou recuperação Android.

Manutenção: VAL-09 SHOULD recebeu critérios explícitos de lei de delta-mutação,
equivalência delta/lote/estado, lacunas, namespaces e empate LWW. VAL-10 SHOULD
recebeu cargas de MV/OR-Set, contagem causal/outbox antes/depois de ACK e decisão
fundamentada sobre ganho/margem. R-19 COULD foi criada como planejada, dependente
de VAL-09/VAL-10, com escopo inicial MV, compatibilidade/migração, preservação de
outbox e recuperação SQLite. Sua entrada exige ganho e margem antes de 02/11.
DotKernel compartilhado continua condicionado a uso concreto; port integral e
OR-Map genérico ficam WON'T-YET. DEC-31, RISK-25/27, índice e orientação de prazo
foram atualizados. VAL-05 conserva dependências MUST; nenhuma tarefa de produto
foi concluída por esta edição. Próxima recomendada permanece VAL-09.

Review documental: conferidos IDs/dependências, prioridades, condições de entrada,
gate final e preservação das conclusões anteriores. Ganho estrutural inferido foi
distinguido de medição; compressão de representação não permite esquecer dots,
descartar IDs pendentes ou inferir observação pelo máximo. Revisão pelo mesmo
agente, não independente.
Validação: aprovada. Checker confirmou 40 tarefas e 191 links locais, sem
inconsistências de IDs, status, dependências ou gates; `git diff --check` passou.
Comandos de validação: `python3 scripts/check_plan.py` e `git diff --check` na raiz.
Limitações: análise estática da referência; nenhum teste C++/Dart/Flutter ou
benchmark foi executado nesta manutenção documental. Uso da referência não
comprova implementação futura nem amplia o escopo acadêmico obrigatório.

<a id="execucao-val-09-2026-10-12"></a>

## Execução VAL-09 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: VAL-09 pronta; R-13/R-14 concluídas; lacunas eram lei mutação/delta, histórias multi-tipo e normalização causal explícita.
Implementação: `packages/deltasync_core/test/crdt_history_properties_test.dart` adiciona 11 casos para os oito tipos, três origens, entrega variada, snapshots, concorrência, substituição, tombstones, lacunas, namespaces e HLC empatado; sem mudança de produto/API/formato.
Review: aprovado
Achados: nenhum impeditivo; corrigidos e reavaliados normalizadores de snapshots após falhas dos próprios testes. Review pelo executor, não independente.
Validação: aprovada
Comandos: em `packages/deltasync_core`, `dart format --output=none --set-exit-if-changed lib test` passou sem mudanças; `dart analyze` sem issues; `dart test --reporter compact` aprovou 94 testes.
Critérios: fixtures existentes e novas cobrem oito tipos, propriedades algébricas finitas, operações/replay após restore, mutação/delta, lote/estado, lacuna MV 1/3 sem inventar 2, dots distintos por endereço e desempate LWW por origem; história sem RNG, ordem explícita, HLC fixo.
Manutenção: fase/índice marcados; matriz ampliada; tarefa ativa encerrada; DECISIONS/RISKS sem mudança; próxima recomendada VAL-10 e VAL-05 segue pronta como gate MUST. Após manutenção, checker passou: 40 tarefas e 192 links locais; `git diff --check` passou.
Limitações: fixtures finitas não provam joins universalmente nem medem desempenho; review próprio não é independente. Nenhuma plataforma mobile foi necessária para mudança restrita aos testes do core.

<a id="execucao-val-10-2026-10-12"></a>

## Execução VAL-10 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: VAL-10 pronta após VAL-06; cenário favorável precisava comparar poucas mutações com snapshot grande; MV/OR-Set precisavam medir retenção causal e custo SQLite.

Implementação: `example/measure_crdt_cost.dart` usa IDs, dados, HLC e quantidades fixos. SQLite FFI recebe snapshots e commits locais reais; peer separado aplica delta com `commitRemote` antes do ACK `appliedAndPersisted`. Conta bytes UTF-8 de delta/envelope/snapshot/outbox JSON, referências causais, versões, tags/eventos, arquivo SQLite e tempo local. Sem mudança em core, CRDT, join, formato ou protocolo. README documenta comando, cargas, resultados, limites e manutenção do script.

Resultados repetidos duas vezes em Linux x86_64, Dart 3.13.5, ABI linux_x64, 12 processadores reportados. Estado favorável: 3 mudanças G-Set custaram 707 B delta/809 B envelope/1.176 B outbox com metadados frente a snapshot de 56.664 B. MV N=4/8/16/32 acumulou 6/28/120/496 referências, confirmando N(N−1)/2; um valor ativo e N context dots permaneceram depois do ACK. Delta foi 1.210/3.296/10.413/35.877 B; snapshot, 803/1.259/2.221/4.109 B. ACK removeu todas as entradas da outbox sem alterar snapshot/contexto. OR-Set reteve 9 tags e 17 eventos para 1 valor visível (4.569 B delta, 4.661 B envelope, 7.305 B outbox e 4.851 B snapshot). SQLite local variou de 24.576 B (N=4) a 86.016 B (N=32) antes do ACK; N=32 chegou a 90.112 B depois de limpar linhas. O arquivo inclui páginas e não mede bytes recuperáveis.

Review: aprovado
Achados: nenhum impeditivo; revisão confirmou dados fixos, payload integral por linha da outbox, ACK só após commit remoto e distinção entre bytes estruturais, SQLite e duração. Review pelo executor, não independente.

Validação: aprovada
`dart format --output=none --set-exit-if-changed example/measure_crdt_cost.dart` passou; `dart analyze example/measure_crdt_cost.dart` sem issues; `dart run example/measure_crdt_cost.dart` reproduziu contagens/bytes em duas execuções finais. Análise e testes passaram na raiz e nos seis pacotes da workspace, inclusive SQLite FFI. Checker e `git diff --check` passaram após manutenção.
Comandos: `dart format --output=none --set-exit-if-changed example/measure_crdt_cost.dart`; `dart analyze example/measure_crdt_cost.dart`; `dart run example/measure_crdt_cost.dart` (duas execuções); loop aprovado de `dart analyze` + `dart test --reporter expanded` na raiz e nos seis pacotes; `python3 scripts/check_plan.py`; `git diff --check`.
Variação local de `write-us`: N=4 1.127–5.005; N=8 1.020–1.402; N=16 998–2.354; N=32 861–1.755. ACK variou 16, 11, 18–19 e 29–30 ms. Amostras pequenas, sem aquecimento ou inferência universal.

Critérios: carga favorável e desfavorável comparadas; metadata da outbox incluída; bytes, context dots, tags, eventos, versões e arquivo SQLite contados; duas execuções confirmam a fórmula estrutural e o limite de custo local. Cargas não medem rede, Android, compressão, concorrência ou multi-peer.

Decisão: há ganho potencial verificável em reduzir contexto repetido de deltas MV, sem descartar contexto causal. R-19 COULD fica adiada para esta entrega: em 12/10 não há estimativa de esforço nem margem comprovada antes de 02/11 para implementação, migração, review e validação SQLite. VAL-05 permanece próxima e MUST; R-19 requer novo plano com margem explícita. DEC-32 e RISK-25 registram decisão e custo. Próxima recomendada: VAL-05.

Manutenção: fase/índice marcados; nenhuma tarefa ativa; R-19 preservada como COULD planejada e explicitamente adiada; README, DECISIONS, RISKS e plano sincronizados. Nenhuma escrita do TCC alterada.
Limitações: execução restrita a Linux x86_64 com SQLite FFI; tempo amostral e tamanho do arquivo SQLite não estimam outras plataformas, throughput de rede ou espaço recuperável. Review pelo executor não é independente.

<a id="execucao-val-05-revalidacao-2026-10-12"></a>

## Execução VAL-05 — revalidação 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: VAL-05 era próxima tarefa pronta MUST; VAL-03/VAL-04 e R-10/R-11/R-12/R-13/R-14/R-15/R-18 estavam concluídas. R-17 COULD ficou pronta após o gate; R-19 permanece adiada por falta de margem comprovada.
Implementação: sem alteração de código de produto. Matriz final, limites, status e rastreabilidade foram alinhados às correções, à refatoração e às evidências novas. Proposta/TCC não alterados.
Review: aprovado
Achados: matriz anterior ainda dizia que VAL-05 aguardava validação; corrigida. Checker detectou depois divergência entre fase e índice no fechamento; status sincronizado e checker repetido. Sem achado técnico impeditivo. Review pelo executor, não independente.
Validação: aprovada
Comandos: na raiz, loop `for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do (cd "$package" && /home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart format --output=none --set-exit-if-changed lib test && /home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart analyze && /home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart test --reporter expanded) || exit 1; done` passou nos sete diretórios. Em `example/flutter_mobile`: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test --reporter expanded` e `flutter build apk --debug` passaram. APK instalado no Moto G52 Android 13; app abriu e reiniciou em novo processo; log após restart: `VAL08 restored A=Delta itens=2 pendentes=0; B=Delta itens=2 pendentes=0`. `example/offline_reconciliation.dart reset`, `offline` e `reconnect` rodaram em três processos Dart separados, no diretório isolado `/tmp/deltasync-val05-final-2026-10-12`; ambas réplicas restauraram 2 pendências, convergiram para Ana/Beto e 5 itens, receberam ACK e reabriram com 0 pendências. Os três exemplos passaram format/analyze. Checker e `git diff --check` passaram após manutenção.
Critérios: oito tipos e propriedades cobertos pela suíte core e histórias VAL-09; SQLite/atomicidade/IDs/retry/snapshot inválido cobertos por regressões R-07/R-11/R-12/R-14 e suíte SQLite; ACK/reordenação/réplica ausente e formatos/versionamento cobertos pelas suítes sync/storage/transport e registros R-03/R-06/R-08; limpeza e responsabilidades conferidas em R-09a/R-09b/R-08d; demo CLI reexecutada após mudanças, Flutter testado/buildado/instalado/reiniciado, matriz e documentação revisadas; integração pública e manutenção documentadas em VAL-02/VAL-04; R-10/R-11/R-12/R-13/R-14/R-15/R-18 têm regressões e reviews registrados; limitações Android/iOS, topologia, consumidores externos, participantes e R-19 estão explícitas.
Manutenção: critérios VAL-05 marcados; fase 5 e índice sincronizados como concluídos; tarefa ativa limpa; matriz e limites revalidados; R-19 COULD preservada como adiada; R-17 COULD selecionada como próxima pronta. DECISIONS/RISKS sem alteração. Checker e diff final aprovados.
Limitações: Android runtime desta execução comprovou build, instalação, abertura e restauração em novo processo; percurso interativo Android completo permanece na evidência VAL-08. Falha injetada de abertura foi validada no Flutter FFI, não no Android. iOS, rede real, consumidores externos e usabilidade com participantes não foram avaliados. Review pelo próprio executor não é independente.

<a id="execucao-r-17-2026-10-12"></a>

## Execução R-17 — 2026-10-12

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-17 era única tarefa COULD pronta após VAL-05 concluir o gate MUST. Dependências R-05/R-08c satisfeitas; havia margem antes do congelamento de 02/11.
Implementação: `SyncEngine.commits` é broadcast Dart assíncrono e não replay, com `SyncCommitEvent.origin` (`local`/`remote`). Emite após commit e adoção em mutação local, lote, delta remoto e snapshot remoto; rollback não emite. `dispose()` fecha o stream. Evento sinaliza estado disponível, não ACK; consumidor consulta `engine.replica`. README atualizado com limites e exemplo. Sem Flutter no core/sync e sem mudança de formato persistido, CRDT, transporte ou ACK.
Review: aprovado
Achados: fixture inicial de teste reutilizava ID de delta com payload diferente; o merge remoto rejeitou a entrada, não a notificação. A fixture passou a continuar a mesma réplica, com sequência válida; checks repetidos. Sem achado de produto impeditivo. Review pelo executor, não independente.
Validação: aprovada
Comandos: em Linux x64/Dart 3.13.5, raiz e `packages/deltasync_sync`: `dart format --output=none --set-exit-if-changed lib test`, `dart analyze` e `dart test --reporter expanded`; os oito testes da facade e 42 testes sync passaram, sem issues e sem alterações de formatação. Checker e `git diff --check` passaram após manutenção.
Critérios: evento local/remoto só após commit e adoção, incluindo delta de transporte e snapshot; testes cobrem rollback de commit local/remoto, listener assíncrono demorado e erro no listener, fechamento por dispose e export pela facade. Dependências puras Dart preservadas. README mostra atualização por leitura da réplica e distingue evento de ACK; formatos persistidos permanecem iguais.
Manutenção: critérios marcados; fase 4 e índice sincronizados como concluídos; tarefa ativa limpa; matriz atualizada. DECISIONS/RISKS não mudaram. Checker final indicou nenhuma tarefa pronta; R-19 segue adiada, sem iniciar tarefa adicional.
Limitações: stream broadcast perde eventos sem assinantes e não reenvia eventos passados; consumidores leem a visão mais recente, que pode incluir commits posteriores ao evento. App Flutter não passou a assinar o stream; cobertura pública veio da facade Dart e dos testes sync. Review pelo próprio executor não é independente.

<a id="planejamento-r-19-2026-10-12"></a>

## Planejamento R-19 — 2026-10-12

Escopo autorizado: planejar R-19; autor confirmou que prazo está adequado e que
a tarefa pode ser feita agora. Essa direção supera o adiamento registrado em
VAL-10/DEC-32. Estado inicial do worktree: limpo. Implementação não iniciada.
Skills: plan-reader, plan-maintainer, code-reviewer, plan-validator.

Leitura: VAL-09/VAL-10 e gate MUST concluídos; custo histórico MV de 496
referências/35.877 B de delta para N=32. Inspecionados contexto do estado, versões
e deltas em `mv_register.dart`, DeltaCodec v3, snapshot Replica v8, wrappers
storage v2, medição existente e diretrizes de Dart sobre responsabilidade local
e compatibilidade. Esses resultados sustentam planejamento, sem validar código
compacto ainda inexistente.

Manutenção: fase 1 detalha seis passos, do inventário à documentação/manutenção,
com redução verificável de bytes de delta/outbox em N=16/N=32. R-19 passa de
planejada/adiada a pronta no índice e na fase; nenhuma tarefa ativa. DEC-33
registra confirmação de prazo, RISK-25/27 refletem estado e riscos causais/de
migração; fase 5 exige revalidação após implementação. Critérios permanecem
abertos, prioridade COULD e dependências VAL-09/VAL-10 preservadas.

Review: aprovado após correções, pelo mesmo agente em etapa distinta; não independente.
Achados e correções: explicitar que unidades compactas não reduzem dots lógicos;
equivalência de payload pendente deve sobreviver à conversão de formato; rollback
por backup anterior não cobre commits novos. Esses limites foram incorporados ao
plano e o diff foi revisto após as correções. Registros históricos de adiamento
e fechamento técnico preservados.

Validação: aprovada para planejamento em Linux; checker confirmou 40 tarefas,
203 links locais e R-19 pronta; `git diff --check` passou. Primeira passagem do
checker apontou links para a âncora deste registro ainda não adicionada; registro
criado e nova checagem aprovada. Sem execução Dart: mudança restrita ao planejamento.
Comandos: `python3 scripts/check_plan.py`; `git diff --check`; revisão de
`git diff -- plan/` e busca de referências R-19 para consistência documental.

Limitações: nenhum ganho implementado ou medido nesta manutenção. Números de
versão novos serão definidos pelo inventário; compatibilidade, migração, provas
causais e recuperação SQLite seguem exigidas para conclusão. Próxima tarefa
pronta: R-19; primeiro passo executável é reproduzir baseline e inventariar
consumidores/formatos antes de alterar código.

<a id="execucao-r-19-2026-10-12"></a>

## Execução R-19 — 2026-10-12

Status final: concluída
Review: aprovado
Validação: aprovada
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Autorização: pedido para executar a próxima tarefa pronta. Escrita/revisão do
TCC não foi alterada. Também aplicado o procedimento plan-executor.

Leitura: R-19 COULD estava pronta, com VAL-09/VAL-10 concluídas. Inspecionados
contratos e implementações de MV-Register, DeltaCodec, snapshots, outbox, SQLite,
facade, consumidor Flutter, benchmark, decisões, riscos e guia Dart. Baseline
reproduzida antes da edição: Linux x86_64, Dart 3.13.5, SQLite FFI; N=4/8/16/32
produziram 6/28/120/496 referências MV, deltas de 1.210/3.296/10.413/35.877 B,
outboxes de 1.807/4.525/12.922/40.930 B e snapshots de 803/1.259/2.221/4.109 B.

Implementação: `mv_register.dart` agora guarda prefixo contíguo e dots esparsos
por réplica e `crdtId`, usado no estado, versões e deltas. Join mantém lacunas;
contexto público `MvRegisterDelta.context` continua `List<Dot>` e expande sob
consulta. DeltaCodec v4 e snapshot interno Replica v9 gravam contexto compacto e
leem formatos explícitos anteriores; `ReplicaSnapshot` v2, outbox v2 e schema
SQLite v1 permanecem. Próximo commit atômico regrava formato legado. Medidor e
README explicam contagem lógica, bytes, fluxo e limites. Regressões incluem
equivalência de join contra união explícita em 64×64 pares de contextos, lacunas,
namespace, leitura de snapshot v8/outbox v3, reabertura, escrita seguinte,
preservação de IDs/peer/tentativas/horário e rollback em falha de inserção.

Achados: diff revisto em etapa separada pelo mesmo implementador, não independente.
Nenhum achado bloqueante restou. A revisão
conferiu causação, lacunas, namespace, replay, aliasing, versões, compatibilidade,
migração atômica, outbox/ACK e rollback. Correções foram aplicadas antes da
validação abrangente; testes direcionados e suíte completa passaram depois delas.

Comandos: `dart format --output=none --set-exit-if-changed lib test` nos pacotes
core, sync e SQLite; formatter do exemplo; `dart analyze` e `dart test --reporter
expanded` na raiz, core, sync, storage, SQLite, storage-testing e transport;
Flutter analyze/test/build no consumidor; medidor executado duas vezes; instalação
e abertura via adb; `python3 scripts/check_plan.py`; `git diff --check`.

Validação e evidências:

- Formatação sem alterações pendentes, análise estática e testes passaram em
  raiz, core, sync, storage, SQLite, storage-testing e transport. Comando:
  `for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do (cd "$package" && /opt/flutter/bin/dart analyze && /opt/flutter/bin/dart test --reporter expanded) || exit 1; done`.
- Flutter mobile: `flutter analyze`, quatro testes Flutter e
  `flutter build apk --debug` passaram em `example/flutter_mobile`. APK instalado
  no Moto G52, Android 13/API 33; app iniciou com PID e sem erro de Flutter ou
  AndroidRuntime no logcat.
- Medição pós-mudança executada duas vezes com os mesmos parâmetros e bytes.
  N=4/8/16/32: referências lógicas 6/28/120/496; unidades compactas 3/7/15/31;
  delta 1.112/2.220/4.525/9.085 B; outbox 1.709/3.449/7.034/14.138 B;
  snapshot 542/542/552/552 B. SQLite mediu 24.576/32.768/36.864/45.056 B antes
  do ACK. Em N=32, delta caiu 74,7%, outbox 65,5%, snapshot 86,6% ante baseline;
  as 496 referências lógicas foram preservadas. SQLite inclui páginas e não prova
  melhoria de latência.
- VAL-05 foi revalidada pela suíte completa, integração SQLite durável e build,
  instalação e abertura Android. A evidência anterior de gate foi preservada;
  esta execução não afirma cobertura de iOS ou de outros dispositivos.

Critérios: todos os sete marcados na fase 1 e demonstrados acima. A representação
compacta não elimina causalidade; não há GC nem agregação de IDs/ACK. Formatos
anteriores são legíveis e conversão ocorre em commit atômico. Leitor antigo pode
rejeitar v4/v9; banco e pendências não são apagados. O ganho foi demonstrado para
cargas sequenciais medidas, não para toda carga ou plataforma. Consulta da API
legada de contexto expande dots e custa proporcional ao tamanho lógico.

Manutenção: R-19 marcada concluída na fase e índice; tarefa ativa limpa;
VAL-05 registra revalidação. DEC-34 documenta representação e versões; RISK-25/27
registram mitigação e limites; README atualiza algoritmo, consumo, mapa de
manutenção e baseline/resultados. `python3 scripts/check_plan.py` e
`git diff --check` passaram após manutenção.

Limitações: evidência de execução cobre Linux x86_64/Dart 3.13.5/SQLite FFI e
Moto G52 Android 13/API 33. iOS e outros dispositivos não foram medidos. Os bytes
e tamanhos SQLite não provam latência universal; formatos antigos podem ser
rejeitados por leitores anteriores a v4/v9. A API pública expande dots ao ler
context, com custo proporcional às referências lógicas.

<a id="execucao-r-20-2026-10-13"></a>

## Execução R-20 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimentos adicionais: plan-executor e safe-refactor, em um agente.

Leitura: autor pediu refatoração geral após considerar R-16 insuficiente; escopo
autorizado abrange responsabilidades, duplicação e acoplamento. R-16/R-19 concluídas;
worktree inicial limpo, HEAD 24ce57c. Inspecionados Replica, oito tipos, codecs,
validação, storage/sync, testes, consumidor, plano/decisões/riscos e guia Dart.
Inventário: sete mapas repetiam cópia, restauração, export e merge; validação era
extension privada da Replica; commits locais simples/em lote e remotos delta/
snapshot repetiam preparação/persistência/adoção; tipos e MemoryStorage eram parts.
Não houve prova de API depreciada morta; Operation/PendingDeltaStore/maxOf continuam.
Baseline em Linux x64/Dart 3.13.5: analyze sem issues e 197 testes Dart aprovados
(8 raiz, 98 core, 42 sync, 12 storage, 23 SQLite, 8 storage-testing, 6 transport).
Flutter analyze e quatro testes passaram antes da refatoração. Execução iniciada
em 12/10 e concluída em 13/10 após retomada solicitada pelo autor.

Implementação: `replica/contents.dart` é dono das instâncias e da mecânica comum
das sete coleções tipadas, com LWW em ReplicaState. Um CrdtTable implementa o
percurso compartilhado; callbacks fixos descrevem particularidades reais dos
tipos, sem plugin/registro público. Replica coordena identidade/metadados/API e
troca conteúdo isolado. `replica/snapshot_codec.dart` lê versões 1–9 e codifica
v9; `replica/delta_validation.dart` recebe lote e conteúdo, sem acessar privados
da Replica. A antiga extension part foi substituída e seu arquivo removido.
`causal/dot_context.dart` possui operações causais e leitor único usado por delta,
estado e versões MV. Sync passou a usar `sync/replica_persistence.dart`,
`sync/outbound_sync.dart` e `sync/serial_commit_queue.dart`; local simples/em lote
compartilha commit, assim como remoto delta/snapshot. Envio continua fora da fila;
adoção/eventos continuam depois de commit. `sync_types.dart` é independente do
engine. Contrato/DTOs storage ficam em `replica_storage_contract.dart`; MemoryStorage
depende desse contrato, e entrypoints anteriores reexportam tipos para compatibilidade.
Os sete percursos copiados e os commits duplicados foram substituídos; algoritmos
dos CRDTs, APIs, aliases, formatos v4/v9/v2 e schema SQLite v1 permanecem.

Review: aprovado
Achados: review em etapa separada pelo próprio implementador, não independente.
Revisados arquivos modificados e novos, dependências, tipos, lacunas, codec,
ordem de commit, aliasing, ACK e lifecycle. Autoadoção `replica.adopt(replica)`
apagava LWW no código anterior: reprodução via arquivo original do commit 24ce57c
retornou `self-adopt preserved snapshot: false` e título null. Cópia antes da troca
corrigiu o defeito, com regressão específica. Leitura inicial do codec refatorado
rejeitava versão numérica 9.0 aceita anteriormente; permissividade anterior foi
restaurada e testada. Analyzer detectou import ausente de ACK e um caminho alterado
na transformação; ambos corrigidos antes dos checks finais. Review também retirou
ciclos de dependência entre tipos/engine e contrato/adaptador. Diff das correções
revisto; contrato/DTOs e corpos de MemoryStorage comparados ao original sem diferenças;
operações de DotContext diferem apenas por nomes internos/formatação e novo leitor.
Não restou achado bloqueante.

Validação: aprovada
Comandos: baseline na raiz, `for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do (cd "$package" && /home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart analyze && /home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart test --reporter compact) || exit 1; done`.
Após cada fronteira, format/analyze/test do core ou sync/storage passaram.
Validação final na raiz: mesmo loop com `dart format --output=none --set-exit-if-changed lib test`,
`dart analyze` e `dart test --reporter expanded`, usando o mesmo SDK. Todos passaram,
sem alterações de formato: 203 testes (9/103/42/12/23/8/6). Em
`example/flutter_mobile`: `/home/yago/.cache/flutter_sdk/bin/flutter analyze`,
`flutter test --reporter expanded` (quatro testes) e `flutter build apk --debug`
passaram. APK gerado em `build/app/outputs/flutter-apk/app-debug.apk` nesse consumidor.
Na raiz, `dart run example/offline_reconciliation.dart reset /tmp/deltasync-r20-final-2026-10-12`,
seguido de `offline` e `reconnect` no mesmo diretório, passou: duas réplicas mantiveram
commits offline, reabriram bancos, convergiram para Ana/Beto e cinco itens, confirmaram
outbox vazia e repetiram restauração final. `dart run example/measure_crdt_cost.dart`
preservou bytes pós-R-19: N=4/8/16/32, delta 1.112/2.220/4.525/9.085 B, outbox
1.709/3.449/7.034/14.138 B, snapshot 542/542/552/552 B e 6/28/120/496 refs lógicas.
Primeiras tentativas da baseline/demo foram bloqueadas pela escrita de telemetria
do SDK fora do sandbox; repetições autorizadas fora do sandbox passaram. Essas
falhas de ambiente não foram contadas como aprovação. `adb devices` não listou aparelho.
Após manutenção: `python3 scripts/check_plan.py` e `git diff --check` passaram.

Critérios: (1) baseline/inventário acima; (2) cópia/export/restauração/merge
compartilhados em conteúdo/tabelas; (3) codec e validador recebem entradas explícitas,
com regressão de versões/ausência de seções e fixture v9 dos oito tipos capturada
do código anterior; (4) commits consolidados e colaboradores independentes,
com testes existentes de envio lento, concorrência, ACK parcial, dispose, retry,
falhas locais/remotas e lote OR-Map; (5) leitor causal único, contratos storage
independentes e remoção dos percursos substituídos; (6) cinco novas regressões
core de fixture/isolamento/autoadoção/legado/falha de mutação e um teste de identidade
de tipos por imports antigos, além da suíte SQLite real com reabertura/rollback;
(7) README mapeia donos, consumo e testes, decisões/riscos/status mantidos e gate
VAL-05 revalidado pela suíte final, demonstração durável e consumidor Flutter.

Manutenção: R-20 e sete critérios concluídos na fase e índice; tarefa ativa limpa.
DEC-35 documenta fronteiras e compatibilidade; RISK-28 registra autoadoção corrigida.
Matriz/síntese e README atualizados; registros históricos R-16/R-19 preservados.
Nenhuma tarefa pronta permanece. Escrita do TCC segue com o autor.

Limitações: review não independente; provas são cenários finitos. FFI em Linux
comprova recuperação dos bancos testados, sem equivaler ao runtime sqflite Android.
Flutter build/test passaram; runtime Android não foi repetido porque não havia
aparelho conectado e a integração de plataforma não mudou. Evidência Android de
R-19 é histórica; iOS/outros aparelhos não foram medidos. Refatoração não promete
melhoria universal de tempo; bytes medidos foram preservados.

<a id="manutencao-ajustes-consumidor-2026-10-13"></a>

## Revisão geral e manutenção dos ajustes/consumidor — 2026-10-13

Status final: planejamento atualizado
Skills: plan-maintainer, code-reviewer, plan-validator
Escopo autorizado: incorporar ao planejamento os ajustes pontuais e a validação
com consumidor externo recomendados na análise. Pedido somente documental; código
R-20 e demais alterações existentes foram preservados. Publicação continua com o autor.

Leitura: proposta PDF §6.9 conferida diretamente; unitários, integração, recuperação
e regressão existem nos pacotes e registros de execução. As 203 verificações Dart
e quatro Flutter de R-20 são evidência histórica, não suíte reexecutada nesta revisão.
Inspecionados organização após R-20, exemplos, testes, entradas públicas e pubspecs.
Revisão identificou em `replica/delta_validation.dart` expansão de `change.context`
na validação MV e cópia seguida de JSON encode em `validateJsonInput`; em
`replica_state.dart`, `operator[]` constrói `values` inteiro. Enlaces CLI/Flutter
repetem comportamento comum. O cenário de histórias chamado shuffled usa ordem
invertida fixa. Exemplos exercitam comunicação em processo, sem consumidor externo
ou rede real; Android pós-R-20 permanece sem runtime novo. São melhorias de custo
e confiança, sem novo defeito de correção demonstrado nem categoria acadêmica ausente.

Manutenção: criadas R-21 SHOULD e R-22 COULD prontas, dependentes de R-20 concluída.
VAL-11 depende de R-21/VAL-09; VAL-12 de R-21/VAL-11; VAL-13 de R-21/VAL-11/VAL-12.
Critérios completos ficam somente nas fases. Índice, síntese/matriz, janelas até
16/11, DEC-36 e RISK-29/30/31 foram alinhados. Ordem recomendada: R-21, VAL-11,
VAL-12, VAL-13; R-22 é opcional e independente. Nenhuma tarefa ativa nem implementação
iniciada. Gate MUST e registros anteriores mantidos; ampliações SHOULD/COULD não
viram requisitos acadêmicos. Entrada de VAL-13 inclui acesso a app/repositório e
canal real; adaptações específicas ficam no consumidor.

Review: aprovado
Achados: revisados escopo, dependências/entradas, prioridades e garantias de
isolamento, causalidade e confirmação. Títulos abreviados no índice divergiam
dos títulos completos de quatro tarefas; corrigidos após primeira checagem.
VAL-13 permite path/Git com overrides explícitos antes da publicação. R-22 exige
repetir runtime afetado se modificar app após VAL-12. O diff foi revisto depois
dessas correções; não restou achado impeditivo. Publicação e escrita do TCC
permanecem com o autor; nenhuma execução de produto foi iniciada.

Validação: aprovada
Comandos: `python3 scripts/check_plan.py`; `git diff --check`; leitura do diff
documental para conferir IDs/anchors, status, sequência e critérios. Não executar
testes Dart/Flutter por atualização documental. Checker final confirmou 46
tarefas e 234 links locais, R-21/R-22 prontas; diff sem erros de whitespace.
Limitações: melhorias ainda não implementadas nem medidas; novo runtime Android
e consumidor externo ainda não executados. Prazo e acesso precisam ser avaliados
na execução; cronograma não é estimativa de esforço ou garantia. Review pelo mesmo
agente não é independente.

<a id="execucao-r-21-2026-10-13"></a>

## Execução R-21 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimentos adicionais: plan-executor e safe-refactor, em um agente.

Leitura: R-21 SHOULD era próxima recomendada, com R-20 concluída; R-22 COULD
também estava pronta. Critérios/DEC-36/RISK-29 e guia Dart sobre responsabilidade
local e tipos fechados conferidos. Worktree continha R-20 e manutenção anteriores;
preservados. Cópias dos quatro arquivos afetados em `/tmp/deltasync-r21-before`
delimitaram o diff desta tarefa. Baseline nova: analyze e 203 testes Dart aprovados
na raiz e seis pacotes (9/103/42/12/23/8/6), Linux x64/Dart 3.13.5.
Inventário confirmou expansão da view MV, duas travessias JSON e consulta da visão
inteira de valores. Fonte do contexto é privada/isolada e validada no construtor.

Implementação: `json/value.dart` reúne regras JSON de cópia/congelamento/validação,
com enum privado para três modos; o modo validate não constrói cópias de containers
JSON nem string serializada. `json_value.dart` preserva export público de
`copyJsonValue`, e MV/validador usam validação interna. O lote MV verifica metadados
sem chamar `.context`, cuja view pública permanece disponível e imutável. Getter
de ReplicaState consulta/congela somente o campo; `values` permanece completo.
Cópias de fork/adopt/visões públicas, formatos/joins/IDs/ACK/schema não foram
alterados. Medidor `example/measure_core_paths.dart` fixa entradas e registra
materialização/leituras/tempo; oito testes novos em `core_paths_test.dart` cobrem
expansão, lacunas, codec/restore, JSON inválido/DAG/erro de leitura e consulta isolada.

Review: aprovado
Achados: diff comparado às cópias de entrada, incluindo arquivos novos. Review
pelo implementador em etapa separada, não independente. O primeiro alias de
validação deixou de converter UnsupportedError/JsonUnsupportedObjectError de
leituras customizadas; conversão antiga restaurada, com regressão, antes dos
checks finais. Lints de blocos for corrigidos. Diff das correções revisto; sem
achado bloqueante restante. Namespace/contexto MV continuam protegidos no
construtor, e a validação interna não depende de getter expansivo sobrescrito.

Validação: aprovada
Comandos: na raiz, baseline `for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do (cd "$package" && dart analyze && dart test --reporter expanded) || exit 1; done`.
Final: mesmo loop acrescentando `dart format --output=none --set-exit-if-changed lib test`
antes de analyze/test. Todos passaram: 211 testes (9/111/42/12/23/8/6); nenhuma
alteração pendente de formato. Checks intermediários no core também passaram;
regressões direcionadas: `dart test test/core_paths_test.dart --reporter expanded`
(oito testes). No consumidor: `flutter analyze` e `flutter test --reporter expanded`
(quatro testes) passaram. Demonstração: `dart run example/offline_reconciliation.dart`
com `reset`, `offline` e `reconnect` em `/tmp/deltasync-r21-final-2026-10-13` passou
em processos distintos, restaurando Ana/Beto/cinco itens e outboxes confirmadas
após reabrir SQLite. SDK do PATH: Dart 3.13.5/Flutter 3.47.7; tentativas bloqueadas
por cache fora do sandbox foram repetidas com autorização, sem contá-las como sucesso.
Medidor: `dart run example/measure_core_paths.dart before` antes da alteração e
`dart run example/measure_core_paths.dart after` duas vezes depois.

Cargas: 20 iterações, contexto com prefixo 5.000 e sparse 5.002/5.010 (5.002 dots
lógicos); lista JSON com 5.000 elementos e estrutura aninhada; consulta de um campo
entre 1.000, cada campo com 16 elementos. Entradas/IDs/endereço/relógio fixos.

| Métrica | Antes | Depois 1 | Depois 2 |
|---|---:|---:|---:|
| Dots materializados pela view MV | 100.040 | 0 | 0 |
| Leituras de elementos da lista JSON | 200.000 | 100.000 | 100.000 |
| Validação MV, µs | 38.340 | 7.108 | 8.066 |
| Validação JSON, µs | 13.342 | 8.868 | 10.344 |
| Consulta pontual, µs | 245.081 | 1.800 | 2.544 |

Consulta retornou 320 elementos nas três execuções. Contagens observam expansão
e leituras, não alocações totais de heap. JSON de validação deixou de construir
grafo copiado/string por inspeção do percurso compartilhado. Tempos incluem
condições locais/JIT; poucas execuções não constituem benchmark universal.

Critérios: (1) baseline/cargas acima; (2) regressão de getter instrumentado mostra
zero expansão e contexto público preservado, com lacuna após codec/restore;
(3) regras compartilhadas rejeitam ciclos/chaves/números/objetos e preservam classe/
primeiro erro/ausência de mutação; (4) consulta mantém ausente/null/tombstone e
coleções congeladas; (5) fixture v9, histórias existentes e suites de isolamento/
rollback/IDs continuam aprovadas; (6) review após correções, suíte completa,
SQLite durável e consumidor passaram; (7) mapa/medidor/decisão/risco/status/evidências
mantidos, gate técnico revalidado e VAL-11 pronta.

Manutenção: critérios R-21 marcados e índice/fase sincronizados; tarefa ativa
limpa, DEC-37 e RISK-29 atualizados, README explica dono JSON e limites do medidor.
Após manutenção, `python3 scripts/check_plan.py` e `git diff --check` passaram.
Próxima recomendada: VAL-11; sua execução foi autorizada pelo pedido posterior
do autor para fazer a próxima ação. R-22 permanece COULD independente.

Limitações: review não independente; provas finitas. O medidor consulta
ReplicaState diretamente, sem eliminar cópias completas de `SyncEngine.replica`
ou `Replica.state`. Nenhuma alegação de heap/latência universal. Runtime Android
novo permanece em VAL-12; R-21 validou Flutter test/Linux, sem alterar integração
de plataforma. Publicação e escrita do TCC continuam com o autor.

<a id="execucao-r-23-2026-10-13"></a>

## Execução R-23 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimento: plan-executor, um agente; correção necessária descoberta em VAL-11.

Leitura: histórias com sementes 7/42/99/2026/10000 expuseram diferença na lei de
mutação/delta. Inspeção de GSet.addAll/applyDelta confirmou seleção por menor ID,
não diferença de ordem da lista. Regressão reduzida: a recebe valor de b, adiciona
mesmo valor e compara com cópia anterior que aplica delta de a. Antes da correção,
`dart test test/generated_history_test.dart --name 'duplicate G-Set' --reporter expanded`
falhou: representante local b:1, representante após delta a:1. DEC-36 exige MUST;
R-23 foi formalizada durante o ciclo VAL-11, após início da correção e antes de
seu fechamento. Critérios/compatibilidade foram conferidos na leitura própria
da tarefa; etapas já executadas no ciclo não são anunciadas como novas execuções.

Implementação: GSet.addAll sempre chama applyDelta(delta), incluindo lote sem
valores novos. Usa a mesma regra existente de representante canônico; quantidade
de valores mantida, sequência/IDs não reutilizados. API e formatos v4/v9/v2/schema1
permanecem. Banco antigo permanece legível; representante pode mudar como já
mudava ao aplicar delta remoto. Sem migração ou GC adicional.

Review: aprovado
Achados: revisão própria do diff e regressão, em etapa distinta, não independente.
A otimização anterior pulava seleção canônica em adições redundantes. Correção
revisada: mantém filtro de elementos novos e validação, altera somente aplicação
local do delta retornado. Testes gerados/SQLite preservam dots, contextos, IDs,
sequências e outbox; nenhuma normalização de evento G-Set ocultou a divergência.

Validação: aprovada
Comandos: regressão acima falhou antes e passou depois; repetida após formalização
e review próprio de R-23, um teste aprovado. Gate compartilhado com VAL-11:
format/analyze/test da raiz e seis pacotes, 224 testes (9/121/42/12/26/8/6);
Flutter analyze/test, quatro testes. Comandos completos e ambiente no registro
VAL-11 abaixo. Reabertura SQLite real, repetição de deltas e sequências posteriores
incluídas. Nenhuma mudança de produto ocorreu entre o gate e a formalização.

Critérios: (1) regressão mínima antes/depois; (2) regra única de aplicação, valor/
sequências/IDs/formatos preservados; (3) review, 32 permutações, restauração/replay,
SQLite e consumidor aprovados; (4) DEC-38/RISK-32, compatibilidade e gate registrados.

Manutenção: tarefa MUST adicionada ao índice/fase; VAL-11 passou a depender de
R-23 para seu fechamento. R-23 concluída e gate revalidado; registros históricos
não apagados. Checker do plano e diff limpo executados ao final da manutenção
conjunta abaixo.

Limitações: review não independente; casos finitos. Android final e rede real
dependem de VAL-12/13. Esta correção não certifica publicação.

<a id="execucao-val-11-2026-10-13"></a>

## Execução VAL-11 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimento: plan-executor em um agente; próxima ação autorizada após R-21.

Leitura: R-21/VAL-09 concluídas liberaram a tarefa SHOULD recomendada. Catálogo
de oito tipos, propriedades existentes e suporte SQLite examinados; baseline
R-21 recém-validada tinha 111 testes core/23 SQLite, sem confundir essa baseline
com resultados posteriores. Guia Dart orientou switch exaustivo sobre CrdtKind;
nenhum enum/contrato/dependência novo necessário. Worktree R-20/R-21 preservado.

Implementação: generated_history_test.dart fixa HLC=1000 e sementes
0/1/7/42/99/2026/10000/65535; três escritores, dois endereços por tipo, 48 passos
locais aleatórios após bootstrap/casos explícitos. Cada operação compara mutação
com delta após codec; testa JSON aninhado, concorrência, tombstone LWW, remoção/
readição OR, 2P, MV com dots 1/3 sem 2, restauração/continuação e IDs únicos.
Oito histórias emitiram respectivamente 114/116/115/111/114/111/113/114 deltas,
908 no total; quantidade varia porque atualização OR-Map emite por encarnação.
Cada história compara lote agregado, join dos três snapshots e quatro ordens
embaralhadas com duplicação/perda temporária e reenvio completo. Além disso,
verifica associatividade/comutatividade/idempotência, restore intermediário e
nove mudanças novas após restore, com replay antigo sem alterar estado causal.

Suporte de comparação extraído de VAL-09 para test/support/snapshot_comparison.dart,
mantendo seus testes. Remove HLC local; no join entre peers também dono/sequências
locais, mas retém esses campos na equivalência/replay. PN zero e ausência são
equivalentes, versões MV ordenadas por dot. Dots/contextos/timestamps vencedores/
tombstones e listas do usuário não são apagados; teste específico protege isso.

SQLite: sync_recovery_test.dart reusa transport/storage/dispose existentes, com
sementes 7/42/2026, HLC fixo e dois engines/bancos reais FFI. Cada writer faz três
rodadas dos oito tipos antes e depois do restore; payloads e quantidades variam.
Entrega fora de ordem/duplicada, reabertura no meio e após entrega, snapshot/
outbox conservados, novas IDs disjuntas, replay antigo, ACK após commit remoto e
reabertura final sem pendências. Comparação entre peers usa todos os eventos
exportados por ID; na reabertura preserva snapshot/outbox exceto HLC local, cujo
avanço deve ser monotônico. Não usa MemoryStorage como prova de durabilidade.

Review: aprovado
Achados: revisão pelo implementador, não independente. Falha real de G-Set
recebeu regressão mínima/correção e tarefa MUST R-23. Correções do harness:
garantir restore mesmo quando evento do meio é atrasado; registrar ordem antes
da entrega; garantir adição compartilhada antes da remoção e tombstone explícito;
comparar HLC local conforme contrato de replay/start; copiar map congelado antes
da normalização; contar IDs emitidas pelo OR-Map sem pressupor uma por chamada.
Lints corrigidos e HLC SQLite injetado para reprodução. Diff revisto após correções;
nenhum achado bloqueante restante. Regras de normalização não escondem eventos.

Validação: aprovada
Comandos: no core, `dart format lib test`, `dart analyze` e
`dart test test/generated_history_test.dart --reporter expanded`: dez testes finais.
No SQLite, mesmos format/analyze e
`dart test test/sync_recovery_test.dart --name 'generated durable history' --reporter expanded`:
três casos. Gate final na raiz:
`for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1; done`.
224 testes passaram: raiz9/core121/sync42/storage12/SQLite26/testing8/transport6;
análises sem issues e formato sem alterações. No example/flutter_mobile,
`flutter analyze` e `flutter test --reporter expanded`: quatro testes aprovados.
Dart 3.13.5/Flutter 3.47.7 do PATH, Linux x64; cache SDK exigiu execução autorizada.
Gate core terminou em cerca de cinco segundos, SQLite três e Flutter seis;
tempos da suíte não são benchmark. Logs locais em /tmp/deltasync-val11-workspace.log,
/tmp/deltasync-val11-flutter.log e históricos direcionados core/SQLite; /tmp não
é arquivo durável de entrega. Este registro, fontes e comandos permitem reprodução.

Critérios: (1) sementes/cargas/traços limitados sem dependências; (2) oito tipos,
múltiplos writers/endereços, JSON e casos causais explícitos; (3) 32 permutações,
lote/join e convergência somente após reenvio; (4) leis, valores e metadados
preservados com normalização justificada; (5) codec/restore, novas IDs/replay e
SQLite real, falha mínima R-23; (6) correções revistas e gate completo aprovado.

Manutenção: índice/fase/critério concluídos; DEC-38 e RISK-30/32 atualizados,
README documenta suporte/sementes/reprodução e inclui storage_testing no loop.
Matriz e gate refletem revalidação após R-23; VAL-12 liberada, VAL-13 planejada e
R-22 COULD permanece pronta. `python3 scripts/check_plan.py` e `git diff --check`
passaram após manutenção conjunta: 47 tarefas, 253 links locais, R-22/VAL-12
prontas e diff sem erros de whitespace. Checker não substitui análise das evidências.

Limitações: oito histórias/32 permutações são cobertura finita, não prova
universal. SQLite FFI reabre bancos no mesmo processo; regressões anteriores
com processos separados/Android permanecem evidência histórica própria.
Transporte em processo não comprova rede real. Não executado runtime Android novo;
VAL-12 exige alvo disponível. VAL-13 exige consumidor externo e rede real.
Review não independente; escrita do TCC e publicação permanecem com o autor.

<a id="execucao-val-12-2026-10-13"></a>

## Execução VAL-12 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimento: plan-executor, em um agente; sem revisão independente.

Leitura: VAL-12 SHOULD pronta e recomendada, R-21/VAL-11 concluídas, com R-23
MUST já corrigida. Cinco skills/AGENTS/RUNBOOK, critérios, DEC-36/38, RISK-21/31,
percurso VAL-08 e guia Dart sobre contratos/nulabilidade consultados. Worktree
inicial limpo; HEAD 75f03ef0bf50d0c4d9c628c5dff788fa248269db inclui os ajustes
anteriores. Moto G52 conectado, Android 13/API 33, serial 0081889739, USB autorizado
e tela desbloqueada. Usada autorização anterior do autor para este dispositivo.

Implementação: tarefa de runtime; nenhuma alteração de produto/teste/API/formato.
Reusado percurso interativo público da demo, sem emulador, reset ou pm clear.
Instalação com -r preservou bancos, inicialmente A=B=Delta, itens=2, outboxes vazias.
Backend sqflite 2.4.4+1; schema1, snapshot Replica v9/wrapper2, delta v4/outbox2.
Build pelo Flutter do PATH produziu APK debug da revisão acima, instalado com
Success. SHA-256: 422bd2a5d99e36d713db10e07a71e31cb5ec0ee78339da511421729748c536c4.
Somente documentação/plano foram alterados durante VAL-12.

Review: aprovado
Achados: revisão em etapa própria do diff documental e fluxo existente:
DemoSession usa duas engines/storages separadas, estado da UI deriva das APIs
públicas; start restaura antes de editar; commit precede adoção. PeerLink aguarda
applyRemote antes de confirmar appliedAndPersisted; outbound restringe ACK ao
peer/IDs enviados; SQLite acknowledge filtra réplica/peer/entry_id. Disponibilidade
do peer e mensagem de confirmação são locais à sessão. Nenhum achado impeditivo
ou correção de produto necessária. Evidências de UI/log/banco revistas depois
do percurso: contagens/IDs/vencedor/clock consistentes; sem crash nos logs filtrados.
Não houve correção que exigisse novo ciclo de testes. Review pelo executor não
é independente.

Validação: aprovada
Comandos: em example/flutter_mobile, `flutter --version`, `flutter analyze`,
`flutter test --reporter expanded`, `flutter build apk --debug` e
`sha256sum build/app/outputs/flutter-apk/app-debug.apk`. Flutter 3.47.7/Dart 3.13.5,
host Linux x64. Análise sem issues, quatro testes aprovados, APK gerado;
avisos Gradle sobre acesso nativo não impediram build. Tentativas iniciais de
ADB/Flutter no sandbox falharam por USB/socket/cache; repetidas com execução
autorizada. Nenhuma falha de ambiente foi contada como aprovação.

ADB do PATH: `adb devices -l`; demais comandos com `adb -s 0081889739`:
`shell getprop ro.build.version.release`, `shell getprop ro.build.version.sdk`,
`install -r build/app/outputs/flutter-apk/app-debug.apk`,
`shell am start -n com.example.deltasync_mobile_consumer/.MainActivity`,
`shell pidof com.example.deltasync_mobile_consumer`,
`shell am force-stop com.example.deltasync_mobile_consumer`,
`logcat -d --pid=<PID> -s flutter:I AndroidRuntime:E`,
`exec-out screencap -p`, `shell uiautomator dump /sdcard/deltasync-val12-ui.xml`,
`shell input tap <x> <y>`, `shell input text <título>`, `shell input keyevent 4`
e `shell input swipe <coordenadas> 500`. Controles localizados por captura/UI;
aguardado término das ações antes de verificar estado. Sem hot reload/restart.

Runtime, logs VAL08 preservados como rótulo da instrumentação existente:

| Etapa | PID | A: título/itens/pendências | B: título/itens/pendências |
|---|---:|---|---|
| Instalação preserva banco e restaura | 32696 | Delta/2/0 | Delta/2/0 |
| Escritas concorrentes e incrementos offline | 32696 | VAL12_A/3/2 | VAL12_B/3/2 |
| Envio falha, peer offline | 32696 | VAL12_A/3/2 | VAL12_B/3/2 |
| Nova edição após falha | 32696 | VAL12_C/3/3 | VAL12_B/3/2 |
| Primeiro force-stop/reabertura | 1364 | VAL12_C/3/3 | VAL12_B/3/2 |
| Peer ativado, envio e ACK | 1364 | VAL12_C/4/0 | VAL12_C/4/0 |
| Nova edição após reconciliação | 1364 | VAL12_D/4/1 | VAL12_C/4/0 |
| Novo envio confirmado | 1364 | VAL12_D/4/0 | VAL12_D/4/0 |
| Segundo force-stop/reabertura | 2541 | VAL12_D/4/0 | VAL12_D/4/0 |

Nos dois force-stops, pidof retornou vazio antes do novo am start. UI confirmou
3 deltas de A e 2 de B após o primeiro envio bem-sucedido; último envio removeu
a nova pendência de A. Peer voltou offline ao reabrir, conforme contrato da demo.

Bancos lidos após encerramento do processo via `exec-out run-as
com.example.deltasync_mobile_consumer cat databases/shopper-a.sqlite` e arquivo
equivalente de B, somente para cópias locais. Python sqlite3 abriu cópias com
`mode=ro`, consultou deltasync_snapshots/deltasync_outbox e conferiu asserts.
Antes do ACK: A guardava shopper-a:delta:4, shopper-a:delta:5 e
g-counter:["shopping/items","shopper-a",2], todos destinados a shopper-b;
B guardava shopper-b:delta:2 e g-counter:["shopping/items","shopper-b",2],
destinados a shopper-a. Quatro entradas enviadas tinham attempts=1/status=sent;
nova escrita A:5 permanecia pending/attempts=0. Nada foi apagado pela falha.
Depois: ambas outboxes vazias; vencedor id shopper-a:delta:6, valor VAL12_D,
HLC 1791918365292:0; clocks a=6/b=2, componentes G a=2/b=2. Nova sequência A=6,
B=2, sem reutilizar IDs após restauração. Essas verificações complementam UI/logs.

Critérios: (1) revisão/SDK/alvo/plugin/hash/build/install registrados; (2) conflito
offline, falha/retry e nova edição com pendências executados; (3) dois reinícios
reais, outbox antes/depois, ACK só após commit e nova abertura aprovados;
(4) ações/logs/bancos/limites acima; (5) review de evidências sem bloqueios e gate
de runtime atualizado. Gate Dart de 224 testes permanece evidência de VAL-11/R-23,
não foi reexecutado nesta tarefa sem alteração de produto.

Manutenção: critérios VAL-12 marcados, fase/índice/matriz/RISK-21/31 e README
do consumidor atualizados; VAL-13 liberada, R-22 COULD permanece pronta, tarefa
ativa limpa. DEC-36/38 continuam suficientes, sem decisão arquitetural nova.
`python3 scripts/check_plan.py` e `git diff --check` executados após manutenção
e conferidos antes de concluir.

Limitações: duas réplicas no mesmo app, enlace sintético, dois tipos no percurso
Android (LWW/G-Counter); demais seis continuam cobertos pelas suítes gerais.
Nenhuma alegação de rede real, iOS, outro aparelho, participantes ou injeção de
falha de abertura no Android. SDK/build/host tests não substituem esses cenários.
Logs/capturas/cópias locais em /tmp/deltasync-val12-* são temporários; esta tabela,
IDs/hash/fontes e comandos preservam a evidência textual no repositório.
App ficou instalado e aberto com os dados finais da demo. Escrita do TCC e
publicação seguem sob responsabilidade do autor.

<a id="tentativa-val-13-2026-10-13"></a>

## Tentativa VAL-13 — 2026-10-13

Status final: bloqueada
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimento: plan-executor, um agente; cinco skills lidas integralmente.

Leitura: VAL-13 era SHOULD pronta/recomendada, com R-21/VAL-11/VAL-12 concluídas.
AGENTS/RUNBOOK, critérios completos, DEC-36/OPEN-07/RISK-31 e referência Dart de
contratos externos consultados. HEAD ebf88aa9db89325567977f87c9706410bfa5b9d3,
worktree inicial limpa. Critérios exigem app existente fora do workspace,
SQLite e canal real; exemplo sintético interno não satisfaz essa entrada.

Inventário: rg --files em /projetos/tcc e depois /projetos e /home/yago,
buscando pubspec.yaml com exclusões de caches/build/dependências. Rechecagem
--hidden --no-ignore em /home/yago/Projetos, /home/yago/TCC e /projetos para não
confundir arquivos ignorados com ausência de app. Somente raiz/pacotes/exemplo
da própria DeltaSync encontrados. /home/yago/Projetos vazio; /home/yago/TCC contém
referências acadêmicas, sem consumidor Dart localizado. Não se afirma inexistência
de app em outros caminhos ou remotos. Pergunta assíncrona pediu caminho de Compass
ou outro app e canal de rede existente, se disponível. Entrada ainda não recebida.

Implementação: não realizada; consumidor/revisão/caso de uso ainda não identificados.
Procedimento plan-implementer aplicado para preservar limites: nenhum app substituto
criado, nenhuma alteração no core, nenhuma escrita em TCC ou publicação. Alterações
limitadas ao registro de impedimento e sincronização dos quatro arquivos do plano.

Review: não realizado para integração: não há diff de consumidor.
Achados: falta concreta de entrada impede critérios 1–7; dependências concluídas
não fornecem repositório/app. Revisão documental em etapa própria conferiu status,
preservação histórica e ausência de alegação de integração validada. Sem correções
de código ou achados gerais da biblioteca; review documental não é review do app
nem revisão independente.

Validação: não realizada para integração: sem consumidor, instalação/build/runtime
ou rede real. Plan-validator manteve os sete critérios desmarcados. Nenhuma suíte
Dart/Flutter executada nesta tentativa exclusivamente documental; evidências de
VAL-11/12 continuam históricas, sem reapresentá-las como validação externa.
Comandos: `git status --short`, `git log -1 --format='%H %s'`,
`rg --files /projetos/tcc | rg '(AGENTS.md|pubspec.yaml)$'`,
`ls -ld /home/yago/Projetos /home/yago/TCC /projetos/tcc`,
`ls /home/yago/Projetos /home/yago/TCC`, buscas rg acima, leituras pertinentes e
`python3 scripts/check_plan.py`/`git diff --check` após manutenção. Checks finais
conferidos antes da entrega; controlam documentos, não satisfazem VAL-13.

Critérios: nenhum concluído; retomada exige informar caminho/repositório de app
existente, inspecionar suas instruções/estado, escolher recorte pequeno e canal
real, então implementar/revisar/validar instalação, SQLite, reinícios e rede.
Path/Git/overrides explícitos continuam permitidos; upload não é pré-requisito.

Manutenção: índice/fase/sinopse/matriz/RISK-31 registram VAL-13 bloqueada;
dependências/escopo preservados, tarefa ativa nenhuma. R-22 COULD permanece pronta,
sem execução automática nesta tentativa. OPEN-07 permanece aberto; nenhuma nova
decisão arquitetural. Nenhuma conclusão ou adiamento foi atribuído ao autor.

Limitações: busca limitada aos diretórios indicados; falta de consumidor impede
execução, não evidencia defeito da biblioteca. Plan-executor exige evidência real
e proíbe concluir com etapa ausente. Aguardando informação solicitada ao autor;
TCC e publicação continuam fora deste trabalho.

<a id="execucao-val-13-2026-10-13"></a>

## Execução VAL-13 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Procedimentos: plan-executor e lean-build, em um agente; review não independente.

Leitura: autor forneceu /projetos/tcc/samples_test_lib/compass_app após tentativa
bloqueada acima. R-21/VAL-11/VAL-12 concluídas; cinco skills, AGENTS/RUNBOOK,
critérios, DEC-15/36/38, OPEN-07/RISK-31 e guia Dart consultados. Compass é sample
existente, com modelos/repositories/providers/rotas e servidor próprios. Nenhum
AGENTS adicional encontrado em seus diretórios ancestrais. Revisão base externa:
5541c59ab8e9d7e74c1a35ef22bd43a487fc596c, worktree externa inicialmente limpa;
biblioteca ebf88aa9db89325567977f87c9706410bfa5b9d3. Quatro documentos do plano
já continham tentativa bloqueada; preservada como histórico. Baseline nova externa:
flutter pub get/analyze e 67 testes existentes do app aprovados.

Implementação: recorte de notas em uma reserva existente, não substituição do
Compass por outro exemplo. main_deltasync compõe providers locais com repositório
de notas e SQLite. Booking/destino/datas mapeiam endereço, sem alterar IDs locais
ou classes geradas; valor LWW {text}. A chave usa datas de calendário para manter
identidade independente de fuso; viagens iguais compartilham nota no usuário único.
Card de notas mostra valor salvo, pendências globais de notas, erro e confirmação
da sessão; edição permanece disponível enquanto sincroniza ou após falha.
Entrada antiga/local/staging segue disponível, com provider opcional no BookingBody.

Consumidor usa somente facade/adapter públicos, com path e quatro overrides no
workspace de flutter/samples; configuração independente do workspace DeltaSync.
Todos os pacotes DeltaSync resolvidos em 2.0.0; Compass app0.1.0/server1.0.0,
sqflite2.4.4+2, sqflite_common_ffi2.4.4/sqlite3 3.7.1. Sem upload ou dry-run pub.dev.
Versões efetivas: Flutter3.47.7/Dart3.13.5/Linux x64; mínimo da biblioteca Dart3.12.

HTTP/TCP: compass-device (Android, sqflite no diretório privado) e compass-peer
(Dart separado no host, SQLite FFI). adb reverse tcp:8091 encaminha conexão USB;
nenhum callback de objetos substitui rede. HttpNotesTransport implementa contrato
público e decodifica ACK; repository faz push/pull manual. /sync/push retorna
applied-and-persisted após commit remoto; /sync/pull mantém outbox até /sync/ack,
que cliente envia após seu próprio commit e servidor filtra por peer/IDs pendentes.
Backend bin/notes_server.dart usa loopback; /notes permite edição independente
do peer, /state permite inspecionar estado. Bancos/identidades permanecem distintos.

Build precisou alinhar Gradle9.3.1/AGP9.1.0/Kotlin2.4.0 com Java25 do Android Studio
do host. Flutter adicionou flags de compatibilidade de DSL/Kotlin; manifest debug
permite HTTP de desenvolvimento. Nenhum arquivo Kotlin novo, API/formato/algoritmo
de DeltaSync ou requisito acadêmico foi alterado. SDK Platform34 foi instalado
pelo build dos plugins; avisos de Java8/share_plus não impediram o resultado.

Review: aprovado
Achados: review do diff real, incluindo todos os arquivos externos novos e etapas
de runtime. Corrigidos no consumidor: chave inicialmente convertia datas para UTC,
podendo separar mesma viagem; regressão calendário/ID protege mapeamento. Card
passou a usar key da viagem para separar rascunhos e explicitar pendência de notas.
Depois do runtime, texto que sugeria falta de ACK histórico com outbox vazia foi
trocado por Nenhum envio nesta sessão/Aguardando confirmação remota. Teste UI
protege ambos os estados; APK final reinstalado/restauração reconferida.
Lint do servidor corrigido com inferência de map tipado. Harness inicial executado
da raiz não carregou assets nativos FFI/caminho do backend; corrigido para cwd app.
Widget test precisou criar engine/SQLite e fazer IO em tester.runAsync, fora do
FakeAsync; runners próprios travados foram interrompidos e checks repetidos.
Essas falhas não foram contadas como sucesso. Deltas de todas as correções revistos;
nenhum achado impeditivo restante ou defeito geral da biblioteca identificado.

Validação: aprovada
Comandos: em compass_app/app, flutter pub get, flutter analyze,
flutter test --reporter expanded e flutter build apk --debug --target lib/main_deltasync.dart.
Baseline67, suíte intermediária71 e final72 testes aprovados (cinco novos).
Direcionados: flutter test test/trip_notes_integration_test.dart --reporter expanded
(quatro casos finais) e flutter test test/trip_notes_card_test.dart --reporter expanded
(um caso após correção de harness). Em server, dart analyze e dart test --reporter expanded:
análise sem issues/13 testes aprovados; HTTP das notas também exercitado pelos
novos testes do app contra processo Dart real. Checks de formato nos oito arquivos
Dart afetados passaram com zero alterações. Não foram repetidos 224 testes da
biblioteca: nenhuma API/código da biblioteca mudou; evidência anterior é histórica.

Teste HTTP/SQLite novo reusa Booking de testing/models: encerra servidor real,
mantém edição/outbox após conexão perdida, reabre cliente e peer com mesmas IDs,
gera nota concorrente e a atrasa durante reinício. Proxy HTTP entrega ao servidor
e descarta resposta do primeiro push após commit (502 controlado); cliente retém
duas IDs e reenvia por HTTP duplicado. Depois de pull/commit/ACK, valores/metadados
LWW iguais, outboxes vazias, nova escrita sem colisão e novos restarts aprovados.
ACK com peer errado não limpa cliente ou servidor; estágio/IDs inválidos rejeitados.
Perda de ACK injetada em teste não é alegada como falha física de pacote no Android.

Runtime: Moto G52 Android13/API33, com autorização anterior. adb devices -l,
install -r, reverse tcp:8091 tcp:8091, shell am start/force-stop, shell pidof,
input tap/text/keyevent/swipe e exec-out screencap -p operaram o Compass existente.
Sem pm clear, emulador, hot reload ou alteração de bancos alheios. SDK/build pelo
PATH; backend dart run bin/notes_server.dart --db /tmp/compass-val13-runtime/peer.sqlite
--port 8091. API local /notes foi chamada via HTTP, não por acesso ao objeto Replica.

| Etapa | PID Android | Nota local | Pendências device/peer |
|---|---:|---|---|
| Reserva Alaska existente; backend encerrado | 10237 | vazia | 0/0 |
| Commit offline e falha HTTP | 10237 | Mobile_offline | 1/0 |
| Edição após falha | 10237 | Mobile_after_failure | 2/0 |
| Primeiro force-stop/reabertura; peer edita independentemente | 11946 | Mobile_after_failure | 2/1 |
| Push/pull/ACK por HTTP | 11946 | Peer_concurrent | 0/0 |
| Nova escrita e novo envio confirmado | 11946 | Mobile_final | 1/0 e depois 0/0 |
| Segundo force-stop/reabertura | 13626 | Mobile_final | 0/0 |
| APK final com correção de texto; abertura e UI reconferidas | 15128 | Mobile_final | 0/0 |

Nos dois force-stops, pidof retornou vazio antes do novo processo. No primeiro
envio offline, UI mostrou HttpException: Connection closed before full header
was received e preservou edição. Cliente confirmou duas mudanças ao reconciliar,
e uma na escrita posterior. Banco device lido por exec-out run-as
com.example.compass_app cat databases/compass-notes.sqlite depois de force-stop;
Python sqlite3 mode=ro conferiu snapshot/outbox. Antes: compass-device:delta:1
sent/attempts1 e :delta:2 pending/attempts0, destinatário compass-peer. Depois:
:delta:3, valor Mobile_final, HLC1791920033606:0, clocks device3/peer1, outboxes
vazias em ambos. Peer concorrente era compass-peer:delta:1/HLC1791919933334:0.
LWW do Android igual ao do servidor, sem remover sequências/dots da comparação.
Backend final foi fechado e banco conferido; túnel criado foi removido. Autor
reconectou celular durante fechamento; mesmo aparelho/PID15128 confirmado.

APK final SHA-256: 01e09127e9280b2ae02734c3b0b9700b053c48be26e875f475f396a597560bfc.
Percurso de dados acima foi executado antes da correção final exclusivamente
textual; APK final manteve notas/outbox e sua UI corrigida foi validada de novo.

Critérios: (1) Compass/revisão/SDKs/versões/resolução externa e install/build/runtime;
(2) composição e chave do modelo local, sem internos; (3) duas réplicas/bancos/
processos, HTTP e ACK durável; (4) offline/conflito/atraso/restart/conexão perdida,
duplicação/ACK perdido em teste e retry/convergência no aparelho; (5) observação
de configuração/consulta/notificação/erro/estado de UI e pontos de manutenção;
(6) achados locais corrigidos/revistos/retestados, nenhum defeito geral ocultado;
(7) roteiro, patch, estado, limites e plano mantidos, sem publicação.

Avaliação: integração exigiu adapter HTTP/ACK próprio e overrides explícitos;
contratos públicos permitiram commit/restore sem adaptar core ao Compass. Queries
ficam no repository e UI acompanha ChangeNotifier; falhas aguardáveis e contagem
de pendências distinguem editar de enviar. Datas e nomes/status se alteram no app,
protocolo no adapter/backend, join/commit/restore continuam na biblioteca. Há cinco
arquivos de produção novos para essas responsabilidades, sem framework de plugins.
Fotos originais do sample retornaram HTTP403 no aparelho, prejudicando apresentação;
classificado como recurso do consumidor, sem impedir o recorte de notas. Reservas
originais em memória continuam voláteis. Nenhum estudo com participantes foi feito.

Manutenção: critérios/índice/fase/sinopse/matriz atualizados; DEC-39, OPEN-07 e
RISK-17/31 mantidos; README_DELTASYNC.md no Compass explica comandos, ownership e
limites. Tarefa ativa limpa; única pronta restante R-22 COULD opcional. Snapshot
reproduzível em [patch Compass](evidence/val13-compass.patch), 17 arquivos, e
[estados de runtime](evidence/val13-runtime.json). Patch sem contexto aplica com
git apply --unidiff-zero na raiz de samples no commit5541c59; --check passou e
aplicação em cópia temporária reproduziu os 17 arquivos byte a byte. Fonte externa
continua em seu repositório; não houve commit automático em nenhum repositório.
Checker do plano passou depois da manutenção: 47 tarefas, 265 links locais,
somente R-22 pronta. diff --check passou nos dois repositórios.

Limitações: um par fixo/usuário único/notas LWW, HTTP local via USB e ambiente de
desenvolvimento. Não é Wi-Fi, serviço público autenticado, bootstrap após perda
de banco, sincronização de todos os modelos do Compass, prova dos oito tipos no
Android, iOS ou benchmark. Provas gerais dos oito tipos permanecem nas suites da
biblioteca. Logs/capturas/bancos /tmp são temporários; patch/JSON/registro preservam
reprodução no repositório. Review pelo implementador não é independente. App ficou
instalado com Mobile_final; backend/túnel de teste encerrados. TCC/pub.dev com autor.

<a id="manutencao-ergonomia-2026-10-13"></a>

## Manutenção — Ergonomia após integração Compass — 2026-10-13

Pedido: autor autorizou acrescentar melhorias da análise ao planejamento e retirar
codegen do escopo atual. Aplicada skill plan-maintainer; manutenção documental,
sem execução de implementação, sem alteração no consumidor e sem escrita do TCC.

Leitura: índice, fases 1/4/5, decisões/riscos e evidências VAL-13; worktree já
continha mudanças de VAL-13, preservadas. Contagem da análise: 503 linhas de
produção (362 app, 141 servidor) e 410 de testes; inclui imports/comentários/vazios,
não é mínimo obrigatório de integração. Caso cobre somente notas de viagens.
Fontes: main_deltasync.dart, TripNotesRepository, HttpNotesTransport,
TripNotesCard, BookingBody e notes_server.dart no consumidor externo.

Achados: ACK exige codec manual; consulta engine.replica.state copia visões
intermediárias; push/pull e confirmação após persistência são coordenados no app;
status reúne APIs separadas. Isso motiva ergonomia geral, sem defeito impeditivo
novo comprovado nem estudo de usabilidade com participantes.

Mudanças: R-24/R-25 MUST prontas; VAL-14 MUST planejada. R-26/R-27/VAL-15 SHOULD
planejadas pelas dependências. Testes/compatibilidade são critérios das tarefas,
sem tarefa genérica paralela. R-22 COULD continua opcional. Adaptador HTTP e
conveniências de mapeamento ficam para avaliação COULD posterior; codegen permanece
WON'T-YET e não exige remoção do build_runner já usado pelo Compass.
VAL-05 reaberta para os novos MUST, preservando histórico. DEC-40 e RISK-33/34
registram limites. Nenhuma tarefa de implementação foi iniciada ou concluída.

Review documental: conferir IDs/dependências/status e critérios nas fases,
prioridade antes de R-22, compatibilidade dos formatos/isolamento, separação de
protocolo e domínio, e topologia explícita antes de usar dois aparelhos.
Reviewer é o próprio mantenedor; não é revisão independente.

Validação: checker do plano e diff --check após manutenção; resultados registrados
abaixo. Testes Dart/Flutter não executados nesta alteração somente documental.

Correções após review: sinopse distingue fechamento histórico do atual; tabela do
índice mantida contínua; texto de prazo distingue ampliações anteriores SHOULD/COULD
dos MUST novos. Dependências sem ciclos, tarefas prontas com entradas satisfeitas,
nenhuma implementação ativa. Critérios de conclusão da reabertura permanecem abertos.

Resultado: python3 scripts/check_plan.py aprovado, 53 tarefas e 278 links locais;
prontas R-22 COULD, R-24 MUST e R-25 MUST. git diff --check aprovado.
Próxima seleção recomendada R-24; execução não autorizada por este pedido documental.

<a id="execucao-r-24-2026-10-13"></a>

## Execução R-24 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-08b/VAL-13 concluídas; R-24 próxima MUST recomendada e autorizada. Lidos executor, cinco skills, AGENTS, RUNBOOK, índice, critérios da fase, DEC-40/RISK-33, baseline Compass e guia Dart §§enums/nulabilidade. Alterações existentes preservadas; base observada dde18a2, sem commit automático.
Implementação: DeltaAcknowledgement.toJson/fromJson, teste de codec no transport e adaptador JSON independente via facade. README documenta formato/validação/limites. Compass app/server usam codec público nos dois sentidos; removido decodeNotesAck local. Teste HTTP ampliado e guia consumidor atualizado. Sem mudança de core, envelopes, snapshots, outbox ou schema.
Review: aprovado
Achados: nenhum impeditivo restante. Revisados código e testes novos, consumo app/server, aliases/cópias e manutenção. Ampliada regressão HTTP para peer com espaço, received e IDs inválidos: resposta 400 preserva outbox. Revisão posterior dessa alteração aprovada e check pertinente repetido. Review pelo implementador não é independente.
Validação: aprovada
Comandos: dart/flutter do PATH; Dart 3.13.5, Flutter 3.47.7, Linux x64. Format/analyze/test na raiz, transport, sync e storage_sqflite aprovados: 10/10/42/26 testes (88). Compass flutter analyze/flutter test aprovados (72); servidor dart analyze/dart test aprovados (13). Após ampliação, flutter analyze e quatro testes de trip_notes_integration_test passaram novamente. Format dos três Dart externos limpo; build APK main_deltasync --debug --no-pub aprovado. git diff --check nos dois repositórios e git apply --check do patch incremental aprovados.
Critérios: (1) testes de codec verificam dois estágios, rótulos, campos ausentes/inválidos, lista vazia, duplicatas e isolamento; (2) formato Compass preservado, destinatário validado no sync/server e persistência não alterada; (3) teste facade sequencia erro de codec, peer errado, received, vazio, parcial/duplicado/ID externo e retry final, preservando pendências; (4) app/server removem JSON manual, segundo adaptador usa facade e HTTP/SQLite real cobre falha, perda de ACK após commit, replay e reabertura de ambos os bancos.
Manutenção: quatro critérios marcados, fase/índice atualizados, DEC-41 e RISK-33 registrados; R-26 liberada, próxima recomendada R-25 MUST. VAL-14 e VAL-05 continuam planejadas. Patch incremental externo preservado; checker e diff finais abaixo.
Limitações: codec não autentica peer nem comprova commit remoto sozinho. Prova HTTP/SQLite executada no Linux; APK compilado, sem nova instalação/runtime Android nesta tarefa. Formato/fluxo/lifecycle não mudaram; não reutilizar VAL-13 como prova de execução do APK novo. Warnings Gradle/Kotlin de compatibilidade futura permanecem no consumidor; build atual passou. MemoryStorage no teste facade não comprova durabilidade, complementada por SQLite/HTTP. Sem codegen, publicação ou escrita acadêmica.

### Comandos e reprodução

Na raiz DeltaSync:

```sh
dart format packages/deltasync_transport/lib/src/delta_acknowledgement.dart packages/deltasync_transport/test/delta_acknowledgement_test.dart test/ack_codec_integration_test.dart
for package in . packages/deltasync_transport packages/deltasync_sync packages/deltasync_storage_sqflite; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done
python3 scripts/check_plan.py
git diff --check
```

No Compass app: flutter analyze; flutter test --reporter expanded; após ampliar
regressão, flutter test test/trip_notes_integration_test.dart --reporter expanded.
Build: flutter build apk --debug --target lib/main_deltasync.dart --no-pub.
No servidor: dart analyze e dart test --reporter expanded. Na raiz Compass:
dart format --output=none --set-exit-if-changed app/lib/data/services/notes/http_notes_transport.dart
app/test/trip_notes_integration_test.dart server/bin/notes_server.dart, executado
do diretório compass_app; git diff --check executado da raiz samples.

Primeira tentativa format/versões falhou por escrita do launcher no cache SDK
fora do sandbox. Reexecutada com permissão de ferramenta, mantendo comandos do
PATH; todos os checks acima realmente executados. Escrita no consumidor externo
também usou permissão de ferramenta, dentro do escopo R-24 autorizado.

[Patch incremental Compass](evidence/r24-compass.patch) modifica quatro arquivos.
Aplicar após [patch VAL-13](evidence/val13-compass.patch), sobre base samples
5541c59; patch incremental usa contexto normal. git apply --check passou contra
a cópia reproduzida de VAL-13 em /tmp/compass-val13-patch-check. Não modificar
patch histórico para substituir evidência já registrada.

Ganho de manutenção observado: transporte 83 para 72 linhas; servidor 141 para
137. Menos 15 linhas de produção no consumidor; codec adiciona 33 na biblioteca
com validação reutilizável. Quantidade de linhas não é meta: regras de parsing
passam a ter um dono comum. Identidade/domínio/UI continuam no consumidor.

Checks finais após manutenção: python3 scripts/check_plan.py aprovado, 53 tarefas
e 283 links locais; prontas R-22 COULD, R-25 MUST e R-26 SHOULD. git diff --check
aprovado no DeltaSync e no samples. Tarefa ativa nenhuma; próxima R-25.

<a id="execucao-r-25-2026-10-13"></a>

## Execução R-25 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-21/VAL-13 concluídas, R-25 próxima MUST pronta e autorizada. Lidos cinco procedimentos, índice/RUNBOOK, critérios da fase, AGENTS, guia Dart sobre switches exaustivos/nulabilidade, DEC-40/41 e RISK-33; código de estado/valores, commits e baseline R-21/Compass inspecionados. Base observada e338843; trabalho anterior preservado, sem commits automáticos.
Implementação: Replica.valueAt e SyncEngine.valueAt oferecem consulta pública por endereço; switch fechado reutiliza oito consultas isoladas. Engine lê somente quando started e não faz fork. Testes core/sync/facade/SQLite e carga fixa reproduzível adicionados. Compass TripNotesRepository usa valueAt; README e guia externo documentam consumo/lifecycle/limites.
Review: aprovado
Achados: primeira validação encontrou preparo incompleto OR-Map nos novos testes (chave não criada), dois avisos de HTML no dartdoc e nome do script fora de convenção. Corrigidos nos três testes, comentário e nome r25_query_cost.dart; revisão das correções aprovada e suíte afetada repetida. Sem achados impeditivos restantes; review pelo implementador não é independente.
Validação: aprovada
Comandos: Dart 3.13.5/Flutter 3.47.7 do PATH, Linux x64. Format/analyze/test raiz/core/sync/storage_sqflite aprovados após correções: 11/122/45/27 testes (205), análise sem issues. Compass flutter analyze e 72 testes aprovados, incluindo processos separados/HTTP real/SQLite/reabertura/perda de ACK; APK debug main_deltasync compilado. Comparação fixa de consulta executada e snapshot inalterado. diff --check nos dois repositórios e check do patch incremental aprovados; checker final após manutenção abaixo.
Critérios: (1) testes core/sync/facade cobrem ausência, LWW null/tombstone, tipos e consultas antes/durante restauração e após dispose; (2) inspeção confirma lookup por endereço sem fork/state.copy, cópias transacionais intactas; (3) oito tipos após snapshot e SQLite reaberto, coleções aninhadas imutáveis/destacadas, falha de rede e leitura durante commit/rollback cobertas; carga fixa preserva snapshot; (4) consumo Compass/guia atualizados, APIs anteriores e formatos preservados, revisão e checks repetidos após correções.
Manutenção: quatro critérios marcados, índice/fase atualizados, DEC-42 e RISK-33 registrados; VAL-14 liberada e próxima recomendada. VAL-05 continua planejada até VAL-14. Resultados/patch externo reproduzíveis preservados; nenhuma tarefa SHOULD iniciada.
Limitações: Object? exige interpretação pelo consumidor conforme tipo CRDT; ausência/LWW null/tombstone compartilham retorno null, como API anterior, sem perda de metadados internos. Consulta não implica ACK. Comparação não mede heap nem garante latência universal. SQLite/HTTP provados no Linux; APK compilado, sem instalação/runtime novo Android. Warnings Gradle/Kotlin futuros do consumidor permanecem. MemoryStorage não comprova durabilidade; teste SQLite dedicado complementa. Sem codegen, publicação ou escrita do TCC.

### Comandos e evidência reproduzível

Na raiz DeltaSync:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage_sqflite; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done
dart run plan/evidence/r25_query_cost.dart
python3 scripts/check_plan.py
git diff --check
```

No Compass app: flutter analyze; flutter test --reporter expanded;
flutter build apk --debug --target lib/main_deltasync.dart --no-pub.
Escrita externa e comandos SDK usaram permissões da ferramenta para os caminhos
fora do sandbox; autorização de R-25 já fornecida. Falha inicial de validação
permanece registrada acima; não foi tratada como aprovação.

[Carga fixa](evidence/r25_query_cost.dart) e [resultado](evidence/r25_query_cost.json):
500 campos LWW, dez itens por campo, dez leituras de aquecimento e cinco amostras
de cem leituras. Medianas: engine.replica.state[] 756.267 microsegundos;
engine.valueAt 990 microsegundos. Resultados equivalentes e snapshot completo
inalterado; valores refletem somente esta entrada/host/execução, sem threshold.

[Patch incremental Compass](evidence/r25-compass.patch) altera repositório e guia.
Aplicar após patches VAL-13/R-24; git apply --check passou em cópia temporária
reproduzida dessas baselines. Fonte externa ainda possui alterações não commitadas;
patch mantém reprodução até existir referência Git equivalente acessível.
Regras de chave/UI/domínio continuam no consumidor; estado, delta, join, commit
e restore continuam nos contratos da biblioteca. Nenhuma nova camada/classe de
produção foi criada; a manutenção da consulta reside em Replica.valueAt.

Checks após manutenção: python3 scripts/check_plan.py aprovado, 53 tarefas e
288 links locais; prontas R-22 COULD, R-26 SHOULD e VAL-14 MUST.
git diff --check aprovado no DeltaSync e no samples. Tarefa ativa nenhuma;
próxima recomendada VAL-14, sem iniciar execução neste pedido.

<a id="execucao-val-14-2026-10-13"></a>

## Execução VAL-14 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-24/R-25/VAL-13 concluídas, VAL-14 próxima MUST pronta. Cinco skills, RUNBOOK, AGENTS, critérios/índice, DEC-41/42, guia Dart sobre contratos/parsing e consumo Compass inspecionados. Mudanças anteriores R-25 preservadas; revisão 3532a32 observada durante execução, sem commit automático.
Implementação: docs/guia-integracao.md cobre seis etapas do consumo, contratos, ownership e compatibilidade. README aponta guia, atualiza query conceitual e leitura após eventos para valueAt. Comparação separa produção/testes/configuração. Sem mudar código de produção ou escrever TCC; somente documentação/evidências/plano nesta tarefa.
Review: aprovado
Achados: corrigidas formulações de consulta/parsing no guia; tabela/contagens e snippets conferidos contra API e consumidor. Review posterior da comparação/apresentação aprovado; nenhum achado impeditivo restante. Review do implementador não é independente. CLI sem argumentos retornou usage; execução correta reset/offline/reconnect passou. USB caiu durante runtime; cópias vazias descartadas como evidência, usuário reconectou/estabilizou ADB e percurso foi retomado até conclusão.
Validação: aprovada
Comandos: Dart 3.13.5/Flutter 3.47.7 do PATH, Linux x64. Format/analyze/test raiz e seis pacotes aprovados: 11/122/45/12/27/8/10 testes (235). Exemplo Flutter analyze/quatro testes aprovados. Compass analyze/72 testes/build APK aprovados; servidor analyze/13 testes aprovados. CLI reset/offline/reconnect em processos distintos aprovado com SQLite/outboxes. Runtime Moto G52 Android 13/API 33 aprovado no APK atual, sem clear-data, com reinício real e HTTP/TCP/USB. Checker/diff finais abaixo.
Critérios: (1) guia configura storage/identidade/modelos e cobre edição/query/falhas/pendências/ACK/close; (2) ACK público/valueAt e mapa de donos/contratos aparecem sem gerador; (3) workspace e consumidor realmente reexecutados, SQLite/rede/reinícios e leitura atual no Android comprovados; (4) mesma funcionalidade: produção Compass 503 para 488, testes 410 para 435, biblioteca mais 65 linhas de produção documentadas, sem meta de LOC; (5) compatibilidade/limites, matriz/índice/decisões/riscos atualizados, VAL-05 liberada e SHOULD pendentes explícitos.
Manutenção: cinco critérios marcados, fase/índice/sinopse/matriz atualizados; DEC-43 e RISK-21/33 registrados, tarefa ativa limpa. VAL-05 pronta é próxima MUST; R-26 SHOULD e R-22 COULD continuam opcionais quanto ao gate. Nenhuma próxima implementação iniciada.
Limitações: runtime cobre notas LWW, um Android e peer fixo em processo Dart separado; não prova dois celulares, iOS, produção/autenticação, publicação ou estudo com participantes. Custos/LOC são da entrada e implementação observadas. Fotos originais retornam 403 e warnings Gradle/Kotlin futuros permanecem; não impedem notas. Backend/túnel criados foram encerrados; app instalado conserva VAL14_peer. Escrita TCC/publicação com autor.

### Validação e runtime

Na raiz, para cada pacote de pubspec.workspace e facade:
dart format --output=none --set-exit-if-changed lib test; dart analyze;
dart test --reporter expanded. Saída por pacote guardada em /tmp/val14-*.log
durante execução; todos passaram. No exemplo Flutter: flutter analyze/flutter test.
No Compass: flutter analyze; flutter test --reporter expanded;
flutter build apk --debug --target lib/main_deltasync.dart --no-pub.
Servidor: dart analyze; dart test --reporter expanded.
CLI: dart run example/offline_reconciliation.dart reset/offline/reconnect
/tmp/deltasync-val14-cli, uma execução por etapa. Valores Ana/Beto e contador 5
convergiram; outboxes vazias após reabertura final.

APK SHA-256 9858de9ce114f58ab481886ccc77ee8f30a7916d31208aee5ae14626fc24921c
instalado com adb install -r no dispositivo 0081889739, preservando banco.
PID 23645 exibiu Mobile_final/pending 0 após atualização. Sem reverse, edição
VAL14_offline foi salva e envio falhou; banco fechado/copied válido comprova
compass-device:delta:4, status sent, tentativa 1 e pendência retida.
Primeiras cópias com USB ausente tinham zero bytes e não foram usadas.
Usuário reconectou e ajustou USB; PID 25661 leu VAL14_offline/pending 1 após restore.
Peer recebeu POST /notes VAL14_peer, compass-peer:delta:2. Túnel 8091 ativado;
push/pull confirmaram após commit, UI mostrou VAL14_peer/pending 0/uma mudança
confirmada. Cópia de banco com processo encerrado e GET /state comprovaram
LWW/clock iguais e outboxes vazias. Reinício final PID 27333 leu VAL14_peer,
pending 0 e Nenhum envio nesta sessão.

[Evidência durável do runtime](evidence/val14-runtime.json) preserva snapshots,
outbox anterior/final e peer final. Capturas inspecionadas ficam em /tmp;
o JSON permite conferir IDs/valores/clock e ausência de pendências sem depender
dessas capturas. Banco Android não foi apagado nem substituído.
Backend de teste encerrado por SIGTERM (PID 54857); somente reverse 8091 criado
pela tarefa foi removido. Permissões de ferramenta permitiram SDK, USB e execução
autorizada do consumidor fora do sandbox. Nenhuma mensagem enviada a terceiros.

Checks finais: python3 scripts/check_plan.py aprovado, 53 tarefas e 295 links
locais; prontas VAL-05 MUST, R-26 SHOULD e R-22 COULD. git diff --check aprovado;
links/anchors, IDs/dependências/status e frontmatter conferidos pelo checker.
VAL-05 não concluída por antecipação; tarefa ativa nenhuma.

<a id="execucao-val-05-ergonomia-2026-10-13"></a>

## Execução VAL-05 — ergonomia 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: todas as dependências MUST concluídas, inclusive R-24/R-25/VAL-14; VAL-05 próxima pronta autorizada. Lidos cinco procedimentos, RUNBOOK, critérios/índice, AGENTS, DEC-41/42/43 e evidências atuais; guia Dart sobre parsing/switches consultado. Worktree inicial apenas r25_query_cost.json não rastreado, preservado; base e591507f5a4fe17096027e7cce4a276297bf1eb9.
Implementação: fechamento documental com correção do mapa AGENTS, que ainda dizia storage sem SQLite. Contrato MemoryStorage, adaptador sqflite e suíte de contrato agora descritos separadamente. Nenhuma mudança de produto/API/formato nem teste novo acrescentado. Artefato de vínculo das evidências gerado.
Review: aprovado
Achados: descrição antiga de SQLite corrigida e diff revisado após correção. Codec ACK mantém formato/rótulos e isolamento; remoção exige peer/lote/estágio durável no fluxo. Query usa lookup dos oito tipos sem fork e respeita lifecycle/commit. Testes de malformed/ACK parcial/rollback/restore e guia conferidos. Sem achados impeditivos; review do implementador não é independente.
Validação: aprovada
Comandos: git diff --exit-code 3532a32 HEAD -- lib packages example pubspec.yaml pubspec.lock confirmou ausência de mudanças de produto desde o runtime. Reprodução de patches VAL-13/R-24/R-25 comparou os 17 arquivos Compass byte a byte ao consumidor atual. sha256sum do APK corresponde ao runtime VAL-14. Logs do workspace conferidos: 235 testes e análise limpa; resultados Compass 72/13, exemplo Flutter quatro, CLI/reinícios e runtime Android vinculados ao código atual. Executados novamente 19 testes focados, todos aprovados; checker e diff após manutenção abaixo.
Critérios: dez critérios satisfeitos. Oito tipos/propriedades e metadados cobertos no core/fixtures/histórias; SQLite/atomicidade/outbox/rollback/reabertura no storage; ACK parcial/retry/peer nos testes sync/facade/HTTP; formatos e contratos preservados; responsabilidade/manutenção no guia/mapa. R-24/R-25/VAL-14 encerradas e evidências conferidas por fonte/APK; novos checks focados comprovam fronteiras alteradas. Demonstração CLI e Android atuais já executadas em VAL-14, com limite explícito de reutilização.
Manutenção: último critério marcado, fase/índice/matriz/sinopse atualizados, DEC-44 registrada e riscos revisados sem ampliar claims. VAL-05 e MUST completos; próxima R-26 SHOULD. R-27/VAL-15 ainda planejadas, R-22 COULD pronta; não iniciadas. Tarefa ativa limpa e histórico preservado.
Limitações: não houve novo runtime Android nem repetição integral de 235 testes nesta tarefa documental; houve conferência de identidade dos fontes/APK e das evidências reais de VAL-14 executadas nesta sessão. Testes focados novos são 19, não 235. Não certifica produção, iOS, dois celulares, participantes ou distribuição publicada. Review não independente; TCC e pub.dev com autor. JSON de custo R-25 não rastreado foi preservado, sem commit automático.

### Checks focados executados

```sh
dart test test/ack_codec_integration_test.dart test/deltasync_test.dart --reporter expanded
(cd packages/deltasync_core && dart test test/replica_query_test.dart --reporter expanded)
(cd packages/deltasync_sync && dart test test/point_query_test.dart --reporter expanded)
(cd packages/deltasync_storage_sqflite && dart test test/point_query_recovery_test.dart --reporter expanded)
(cd packages/deltasync_transport && dart test test/delta_acknowledgement_test.dart --reporter expanded)
python3 scripts/check_plan.py
git diff --check
```

Dart 3.13.5/Linux x64 do PATH; permissões de ferramenta necessárias ao cache SDK.
Resultados 10/1/3/1/4, total 19. SQLite dedicado reabriu banco real e preservou
oito tipos/IDs pendentes. [Vínculo verificável](evidence/val05-ergonomia-verificacao.json)
registra revisão, hash APK e contagens do workspace de VAL-14.
O [runtime VAL-14](evidence/val14-runtime.json) confere pendência offline,
LWW/clock iguais e outboxes finais vazias; não representa topologia genérica.

Checks finais aprovados: python3 scripts/check_plan.py, 53 tarefas e 300 links
locais; somente R-26 SHOULD e R-22 COULD prontas. git diff --check limpo.
Comparação adicional contra worktree atual (git diff --exit-code 3532a32 --
lib packages example pubspec.yaml pubspec.lock) também vazia, incluindo mudanças
não commitadas. Todos os MUST concluídos; nenhuma implementação ativa.

<a id="execucao-r-26-2026-10-13"></a>

## Execução R-26 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-24/VAL-13 concluídas; R-26 próxima SHOULD pronta autorizada. Cinco skills, AGENTS/RUNBOOK, critérios/índice, guia Dart sobre contratos/parsing, fluxo incoming e pull Compass inspecionados. Worktree inicial com JSONs anteriores não rastreados preservados; revisão a2084d2 observada, sem commit automático.
Implementação: SyncEngine.receiveEnvelope valida sender/recipient, aguarda commit/adoção e retorna ACK; IncomingAcknowledgingDeltaTransport permite envio opcional pelo adaptador. Incoming usa mesmo método e reporta falhas pelo stream errors. Compass substitui sequência manual por receiveEnvelope e seu HTTP envia ACK tipado. README/guia atualizados; tests sync/facade e recuperação SQLite ampliados.
Review: aprovado
Achados: corrigido acesso ao modelo de snapshot no novo teste durante revisão inicial; ampliada prova SQLite para ACK depois de snapshot persistido e leitura após reabertura, revisada e check afetado repetido. Corrigida ligação de frases no guia externo e revista novamente. Sem achados impeditivos restantes; revisão pelo implementador não é independente.
Validação: aprovada
Comandos: Dart 3.13.5/Flutter 3.47.7 do PATH, Linux x64. Format/analyze/test raiz/sync/transport/storage_sqflite aprovados, 12/48/10/27 (97). Compass analyze/72 testes e build APK debug main_deltasync aprovados; exemplo Flutter analyze/quatro testes aprovados. Após ampliação SQLite, format/analyze e teste point_query_recovery_test executados novamente e aprovados. Patch incremental aplicável, diff/checker finais abaixo.
Critérios: (1) stream e pull chamam um método público com contrato opcional, sem framework; (2) peer/commit/ACK ficam na engine, HTTP/modelos no consumidor; (3) regressões cobrem peer/destinatário errado, rollback sem ACK, duplicação, falha de ACK observável, replay, local outbox preservada, edição durante ACK e dispose que drena; SQLite e HTTP real com perda de ACK/reabertura aprovados; (4) contratos/formatos antigos intactos, fallback sem sender provado pela facade, docs de lifecycle/timeouts explícitas, redução no Compass demonstrada e correções revisadas/revalidadas.
Manutenção: quatro critérios marcados, fase/índice/guias atualizados, DEC-45 e RISK-33/21 mantidos com limites; R-27 liberada e próxima recomendada. Tarefa ativa limpa. MUST históricos permanecem concluídos; nenhuma tarefa nova iniciada.
Limitações: nenhum runtime Android novo nesta tarefa; APK compilado, SQLite/HTTP real executados no Linux. VAL-14 mantém prova histórica do APK anterior e não é prova do fluxo R-26 no dispositivo. Topologia segue par fixo; ACK não autentica peer. Dispose pode esperar até timeout do adaptador, sem cancelamento forçado. MemoryStorage nos testes unitários é volátil, complementado pelo SQLite real. Sem alteração de core, codegen, publicação ou escrita TCC.

### Comandos, fluxo e evidência

Format/analyze/test executados em ., packages/deltasync_sync,
packages/deltasync_transport e packages/deltasync_storage_sqflite. Logs da execução
em /tmp/r26-*.log. No consumidor Compass: flutter analyze, flutter test --reporter
expanded, flutter build apk --debug --target lib/main_deltasync.dart --no-pub.
No exemplo Flutter: flutter analyze e flutter test --reporter expanded.
Após corrigir/ampliar teste SQLite: dart format --output=none --set-exit-if-changed
lib test; dart analyze; dart test test/point_query_recovery_test.dart --reporter expanded.
Permissões de ferramenta permitiram cache SDK e edição autorizada no consumidor
externo. SDK sempre pelo PATH; nenhuma instalação Android feita.

No stream, errors recebe falha de ACK como incomingDelta mesmo após commit; não
inferir rollback. No pull, Future devolve erro ao chamador. Em ambos, recepção
aceita mantém atividade até terminar ACK, e dispose aguarda drenagem. Call após
dispose falha. Rede/fetch e política de retry são do adaptador/consumidor.

Repositório Compass 106 para 101 linhas, transporte 72 para 68; nove linhas
de produção removidas, além de validação/ordenação deixarem de viver no app.
Uma interface opcional é justificada pelo HTTP Compass e adaptador de stream
nos testes, sem catálogo de plugins ou API específica de Booking.
[Patch incremental](evidence/r26-compass.patch) cobre três arquivos externos,
aplicável após VAL-13/R-24/R-25; git apply --check passou contra baseline
reproduzida em /tmp. Dados/modelos/backend permanecem no consumidor.

Checks finais após manutenção: python3 scripts/check_plan.py aprovado,
53 tarefas e 304 links locais; prontas R-27 SHOULD e R-22 COULD.
git diff --check aprovado no DeltaSync e samples; nenhuma tarefa ativa.

<a id="execucao-r-27-2026-10-13"></a>

## Execução R-27 — 2026-10-13

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-26/R-17 concluídas; R-27 próxima SHOULD pronta autorizada. Cinco skills, AGENTS/RUNBOOK, tarefa/índice, DEC-45/RISK-33, guia Dart sobre sealed/contratos e consumo Compass inspecionados. Inventariados commits/errors/pendingDelta/SyncPushResult: objetos existentes reutilizáveis, sem motivo para cache de pendências. Worktree inicial apenas JSONs anteriores não rastreados, preservados; revisão f1864fa observada.
Implementação: observations publica família fechada SyncObservation, com três tipos existentes e dois eventos específicos de restauração/falha de push. Publicação assíncrona após restore/commit/ACK; nenhuma outbox/snapshot paralela. Streams anteriores intactos. Compass usa assinatura única para reagir a eventos, mantendo atualização aguardável das ações e estilo de UI próprio. Docs e regressões sync/facade/SQLite/consumidor ampliadas.
Review: aprovado
Achados: sem defeitos impeditivos reproduzidos. Revisão ampliou cobertura de implementação externa dos eventos antigos e de atualização no consumidor sem chamar ações do repositório; deltas revistos e checks correspondentes repetidos. Objetos de commit/falha/push compartilhados entre APIs sem copiar dados; sealed restringe somente a família nova, variantes antigas continuam implementáveis. Sem review independente.
Validação: aprovada
Comandos: Dart 3.13.5/Flutter 3.47.7 do PATH, Linux x64. Format/analyze/test raiz/sync/transport/storage_sqflite aprovados, 13/51/10/27 (101). Compass analyze/suíte de 72 e build APK main_deltasync aprovados; após ampliar prova, analyze e cinco testes de integração aprovados (inclui um caso novo, 73 casos distintos aprovados nas execuções). Exemplo Flutter analyze/quatro testes aprovados. Após ampliar compatibilidade externa, analyze da raiz e import_compatibility_test aprovados. Patch/checker/diff finais abaixo.
Critérios: (1) stream publica mesmos commits/falhas/resultados sem manter estado derivado; (2) restored/commit/result/failure separados, outbox consultada e ACK não inferido de commit/vazio/received; (3) rollback não emite commit, ACK parcial preserva restante, falha/retry e stream failure cobertos, observações após SQLite reaberto sem ACK fictício, listeners pausados/throwing não invalidam escrita e fechamento testado; (4) Compass recebe atualização local/remota fora de suas ações sem polling, sync permanece Dart puro, contratos externos/formatos preservados e deltas revisados/revalidados.
Manutenção: quatro critérios marcados, índice/fase/guias atualizados, DEC-46 e riscos registrados; VAL-15 liberada com entrada runtime explícita. Próxima VAL-15 SHOULD; R-22 COULD continua opcional. MUST mantêm conclusões históricas; nenhuma tarefa seguinte iniciada.
Limitações: sem novo runtime Android nesta tarefa; APK compilado e integração SQLite/HTTP executada no Linux. Prova Android VAL-14 é histórica. Stream sem replay exige consulta inicial para assinante tardio; assinaturas pausadas precisam cancelar antes de dispose. Erros diretos diferentes de push continuam nas Futures. Não há contador duplicado, histórico persistido de ACK, agendador ou estudo com participantes. Segundo aparelho/topologia ainda precisam ser identificados para VAL-15. Sem codegen, publicação, TCC ou commits automáticos.

### Contrato, testes e reprodução

Comandos nos quatro pacotes afetados: dart format --output=none
--set-exit-if-changed lib test; dart analyze; dart test --reporter expanded.
Logs em /tmp/r27-*.log. No Compass: flutter analyze; flutter test --reporter
expanded; flutter build apk --debug --target lib/main_deltasync.dart --no-pub.
Após prova adicional: flutter analyze e flutter test
test/trip_notes_integration_test.dart --reporter expanded. Root compatibilidade:
dart analyze e dart test test/import_compatibility_test.dart --reporter expanded.
Permissões da ferramenta permitiram cache SDK e edição externa autorizada.

SyncRestoredEvent publica somente após adoção inicial. Consulta pendingDelta
continua fonte de pendência real; não publica resultado push ao restaurar.
SyncPushResult é observado após confirmação local de IDs da outbox e é o mesmo
objeto retornado pela Future; SyncPushFailure mantém erro/stack e erro da Future.
SyncFailure mantém sua origem/objeto no stream errors. Commit e observação não
mudam política de retry nem indicam confirmação remota por si sós.
Outras falhas aguardadas ficam com o chamador, incluindo busca de rede no app.

Testes provam late/no replay, local commit/rollback, received/ACK parcial, falha
e retry, reabertura, erro recebido compartilhado, assinatura pausada/throwing
e fechamento. Caso Compass com SQLite verifica que commits feitos diretamente
pela engine atualizam nota e contagem do repositório sem polling, inclusive remoto.
Caso de compatibilidade implementa SyncCommitEvent em library consumidora.

Repositório Compass passou de 101 para 125 linhas. O aumento de 24 linhas
implementa atualização reativa, sem alegar redução de código. Guia registra
produção total 479 após R-26 e 503 após R-27, com mesma UI/rede e capacidade nova.
[Patch incremental](evidence/r27-compass.patch) preserva três arquivos externos;
git apply --check aprovado sobre VAL-13/R-24/R-25/R-26 reproduzidos em /tmp.

Checks finais: python3 scripts/check_plan.py aprovado, 53 tarefas e 308 links
locais; prontas VAL-15 SHOULD e R-22 COULD. git diff --check aprovado no DeltaSync
e samples. Tarefa ativa nenhuma; segundo dispositivo não foi presumido disponível.

<a id="preparacao-r-22-2026-10-13"></a>

## Preparação R-22 — 2026-10-13

Status final: bloqueada
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-20 concluída; autor autorizou R-22/preparação VAL-15 e depois retirou celular. Cinco skills e safe-refactor aplicados. Baseline antes de editar: Flutter analyze/quatro testes e CLI reset/offline/reconnect com SQLite aprovados.
Implementação: PeerLink Dart puro compartilhado em example/flutter_mobile/lib/support; shims mantêm imports e DemoPeerLink derivado preserva mensagem exata. Um dono send/ACK/close; doubles especializados intactos, sem pacote novo ou mudança de core.
Review: aprovado
Achados: export inicial fora do lib Flutter falhou por package URI. Corrigidos local do suporte/export CLI e super parameter; deltas revistos e checks repetidos. Exceção pontual do lint para export Dart puro, sem dependência Flutter. Sem impeditivo de código; review não independente.
Validação: parcial, runtime Android pendente
Comandos: Dart/Flutter do PATH. Format/analyze limpos; dois testes de enlace aprovados; CLI reset/offline/reconnect /tmp/r22-after-cli reproduziu baseline, inclusive diagnósticos e reabertura SQLite. Flutter analyze/quatro testes/build APK aprovados após correções. Runtime não realizado por direção do autor.
Critérios: 1/2/3/5 satisfeitos; 4 parcial. Mensagens preservadas, ACK espera handler de commit, falha não ACKa, stream fecha. Dois donos send/ACK/close reduzidos a um; wrapper CLI só preserva diagnóstico.
Manutenção: bloqueada no índice/fase, runtime aberto, sem conclusão. Próximo trabalho autorizado: preparação VAL-15, um ativo por vez.
Limitações: suporte dentro do lib Flutter mantém package URIs; CLI export usa exceção de lint local. Clone completo já exigido pelos paths. Build/FFI não provam Android. Retomar runtime quando primeiro celular voltar.

<a id="preparacao-val-15-2026-10-13"></a>

## Preparação VAL-15 — 2026-10-13

Status final: bloqueada
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-26/R-27/VAL-13 concluídas. Autor autorizou preparação sem aparelhos. Cinco skills reaplicadas por etapa; fonte/hub/ID/outbox e guia de contratos conferidos. Alterações anteriores R-27 preservadas; nenhuma implementação da biblioteca alterada nesta preparação.
Implementação: NotesConfiguration no consumidor permite IDs/endpoint por dart-define e nomes de banco estáveis/isolados, preservando defaults. HTTP pull envia destinatário explícito. Backend opcional com dois clientes/notes-hub exporta estado LWW materializado, sem outbox global; cliente mantém outbox para hub e confirma commit daquele peer. Roteiro técnico, testes e APKs alpha/beta preparados. Modo legado permanece padrão.
Review: aprovado
Achados: testes expuseram IDs com espaços aceitos por normalização ReplicaId sem refletir configuração do transporte. Corrigida validação estrita no consumidor/hub, sem alterar core; expectativa temporária de FormatException descartada ao conferir contrato real ArgumentError. Revisadas correções e reexecutados checks. Startup do hub também rejeita banco com outbox local/dados fora de LWW trip-notes, com regra em um helper. Sem review independente.
Validação: parcial, runtime físico pendente
Comandos: Flutter/Dart do PATH, Linux x64. Compass analyze e 77 testes aprovados após correção; servidor analyze/13 testes aprovados. Após ampliar concorrência, analyze e nove testes de config/integração passaram novamente. Depois de limitar dados existentes do hub, analyze e teste pareado HTTP/SQLite passaram novamente. Dois builds APK com IDs alpha/beta e peer notes-hub aprovados; nenhum install/adb/runtime realizado.
Critérios: 1/2 satisfeitos no host: configuração sem editar fonte, destinatário explícito, clientes/bancos/outboxes/ACK isolados, hub sem remoção global por ACK, requests simultâneas/retry/reabertura testados. Critérios 3/4/5 permanecem abertos pela execução física ausente. Valores/winners LWW convergem, sem alegar equivalência de todo histórico causal no bootstrap.
Manutenção: dois critérios marcados, bloqueio/índice/fase/decisões/riscos atualizados; tarefa ativa limpa. R-22 também aguarda runtime do primeiro celular. Nenhuma tarefa concluída por testes de host/build. Roteiro e artefatos preservados para retomada.
Limitações: hub LWW é composição do consumidor para este cenário, não fanout genérico da biblioteca. ACK confirma hub, não recepção pelo outro celular; somente após pulls relevantes ambos convergem. Não há auth de produção, delta incremental no pull do hub ou prova de oito tipos nessa topologia. Dois clientes no Linux não substituem dois Androids. IDs/configuração fixos por artefato devem permanecer iguais na reinstalação. App original ainda tem limites de reservas/imagens registrados em VAL-13.

### Reprodução e artefatos

No Compass: flutter analyze, flutter test --reporter expanded.
No servidor: dart analyze, dart test --reporter expanded.
Check corrigido: flutter test test/notes_configuration_test.dart
test/trip_notes_integration_test.dart --reporter expanded. Check após regra
de dados do hub: flutter test test/trip_notes_integration_test.dart
--name 'two configured clients' --reporter expanded.
Builds: flutter build apk --debug --target lib/main_deltasync.dart --no-pub
--dart-define=REPLICA_ID=alpha/beta --dart-define=PEER_ID=notes-hub, uma execução
por ID. Saída copiada para /tmp/val15-apks/compass-alpha.apk e compass-beta.apk.

[Metadados/hashes](evidence/val15-preparacao.json) e
[patch incremental de sete arquivos](evidence/val15-preparacao-compass.patch)
preservam preparação. Aplicar patch após VAL-13/R-24/R-25/R-26/R-27; check passou
na baseline reproduzida. APKs em /tmp são temporários; comandos e hashes
permitem reprodução. [Roteiro físico](../docs/val15-dois-dispositivos.md) define
seriais/canal, reinstalação, edição offline, falha, reinícios, pulls e inspeção.

Teste local comprovou: confirmação alpha não remove outbox beta; ACK beta não
remove pendência alpha; pull falta destinatário/ID desconhecido e envelope com
destinatário errado são rejeitados; received não confirma; edições permanecem
disponíveis durante falha; clientes e hub reabrem mesmos bancos/IDs; requests
concorrentes e pulls posteriores convergem em winners LWW. Processos/bancos
temporários de testes encerrados pelos fixtures.

Uma revisão automática de permissão para check do servidor expirou sem avaliar
a ação. Retry único permitido foi aprovado e os checks executados; não tratada
como defeito ou risco do servidor. Permissões de ferramenta usadas somente
para SDK/cache e consumidor externo autorizados. Escrita do TCC/pub.dev com autor.

Checks finais da manutenção R-22/VAL-15: python3 scripts/check_plan.py aprovado,
53 tarefas e 317 links locais; nenhuma pronta. git diff --check aprovado no
DeltaSync e no repositório externo samples_test_lib. Status bloqueados e tarefa
ativa vazia refletem os critérios de runtime ainda abertos.

## Retomada R-22 — 2026-10-13 — autorização ADB pendente

Status final: bloqueada
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: dependência R-20 concluída; critérios da R-22, preparação anterior, RUNBOOK e guia Dart conferidos. Autor autorizou prosseguir com um aparelho conectado; VAL-15 continua exigindo dois aparelhos.
Implementação: nenhuma mudança de produto necessária. Preservadas alterações anteriores; gerado novamente o APK a partir do código atual. Safe-refactor aplicado à conferência do comportamento e dos caminhos de import.
Review: aprovado
Achados: diff CLI/Flutter, suporte novo e testes revistos, sem novo impeditivo de código. Herança do wrapper preserva diagnóstico e contrato sem modificadores que impeçam seu uso. Review pelo mesmo agente, não independente.
Validação: parcial, runtime não realizado
Comandos: flutter build apk --debug --no-pub em example/flutter_mobile aprovado. SHA-256 do APK atual: 8b0425dad01ece8a52ce31b1f17143d6e8d9ae1114da67bb7f66cb8ca50dc2f6. adb devices -l repetido identificou serial 0081889739 como unauthorized; solicitação de autorização enviada ao autor. Nenhuma instalação, edição ou inspeção de banco no aparelho realizada nesta retomada.
Critérios: host/build anteriores preservados e build atual aprovado; critério 4 ainda aberto pelo runtime Android ausente. Identidade/modelo/API Android do aparelho não confirmados enquanto unauthorized.
Manutenção: bloqueio atualizado na fase/índice, tarefa ativa limpa; não concluída. VAL-15 permanece bloqueada no runtime com dois aparelhos. Não reapresentar baseline como prova física atual.
Limitações: conexão USB detectada não equivale a autorização ADB. Retomar instalação e percurso offline/reinício/ACK após aceite da depuração USB no celular.

<a id="execucao-r-22-2026-10-13"></a>

## Execução R-22 — 2026-10-13 — fechamento Android

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: tarefa/dependência R-20, preparação e critérios conferidos; autor confirmou autorização USB do único aparelho. Cinco skills lidas integralmente; safe-refactor aplicado à preservação de comportamento. Alterações anteriores do workspace preservadas.
Implementação: suporte compartilhado já preparado, sem nova alteração de produto nesta retomada. APK atual instalado com -r, preservando bancos existentes; sem limpar dados. README corrigiu mapa do enlace e registra runtime atualizado.
Review: aprovado
Achados: diff CLI/Flutter e arquivos novos de suporte/teste revistos, sem impeditivos. Imports, wrapper e mensagens preservados; ACK somente após handler remoto, mesma falha/fechamento. Correções de package URI/super parameter da preparação permanecem validadas. Review do próprio agente, não independente.
Validação: aprovada
Comandos: flutter build apk --debug --no-pub aprovado na retomada imediatamente anterior; APK SHA-256 8b0425dad01ece8a52ce31b1f17143d6e8d9ae1114da67bb7f66cb8ca50dc2f6. adb devices -l autorizou Moto G52 serial 0081889739; adb install -r, am start, input, logcat --pid, am force-stop e exec-out run-as cat executados. Android 13/API 33; sqflite real. PIDs 16300, 24688 e 25090, sem PID após cada force-stop. Host: analyze, dois testes do enlace, quatro Flutter, CLI reset/offline/reconnect e build aprovados na preparação, sem mudanças de código posteriores; não apresentados como nova execução nesta retomada.
Critérios: 1/2/3/5 satisfeitos pelas provas e review da preparação; 4 fechado com runtime atual. Estado inicial preservado VAL12_D/contador 4/outboxes zero. A/B editaram R22_A/R22_B e incrementaram offline: contador 5 cada, duas pendências cada; envio falhou sem perda. A editou R22_C após falha: três pendências, B duas, restauradas no primeiro reinício. Após restore A editou R22_D, gerando shopper-a:delta:9 depois de delta:8. Reconexão/envio convergiu em R22_D e contador 6; outboxes zero. Segundo reinício restaurou mesmo resultado. Cópias SQLite confirmam vencedor completo igual, componentes/IDs/peers e remoção durável das pendências.
Manutenção: todos os critérios marcados, fase/índice/matriz/mapa/DEC-47 atualizados; autorização pendente resolvida sem apagar histórico. Nenhuma tarefa ativa/pronta. VAL-15 continua bloqueada por exigir dois aparelhos físicos.
Limitações: enlace sintético entre duas réplicas no mesmo app; não rede real ou duas instalações físicas. Runtime cobre LWW/G-Counter e adaptador Android, sem ampliar prova a oito tipos/iOS. Sem nova API/formato de produção. Evidências de host permanecem vinculadas à preparação e runtime à execução atual.

[Artefato de runtime e bancos inspecionados](evidence/r22-runtime.json) preserva
hash do APK, IDs/peers, snapshots resumidos e logs dos dois reinícios. Cópias
completas dos bancos/telas ficam em /tmp/r22-runtime; não necessárias para ler
o artefato persistido. Nenhum banco do consumidor foi apagado.

Checks finais desta manutenção: python3 scripts/check_plan.py aprovado, 53 tarefas
e 321 links locais, nenhuma pronta; git diff --check aprovado. Sem mudanças no
Compass nesta retomada e sem atribuir seu runtime à validação do exemplo R-22.

<a id="execucao-val-15-2026-10-13"></a>

## Execução VAL-15 — 2026-10-13 — dois Androids físicos

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-26/R-27/VAL-13 concluídas; tarefa/roteiro/DEC-48/RISK-34 e preparação anterior conferidos. Cinco skills lidas integralmente, RUNBOOK e guia Dart consultados. Autor disponibilizou ambos aparelhos; ADB autorizado nos seriais 0081889739 (alpha, Moto G52 Android 13/API 33) e 0085287528 (beta, Moto G53 5G Android 14/API 34). Topologia/canal definidos antes de runtime: clientes com bancos privados, peer fixo notes-hub, hub consumidor LWW materializado, HTTP/TCP via reverse USB por serial.
Implementação: nenhuma mudança de produto na retomada; configurações/adaptadores/testes da preparação reaproveitados. APK alpha/beta instalados com -r nos aparelhos respectivos, sem clear-data ou clone de banco. Hub usou /tmp/val15-runtime/notes-hub.sqlite dedicado. Preservadas alterações anteriores do workspace/consumidor. Roteiro atualizado com execução real.
Review: aprovado
Achados: configuração/main/repositório/transporte/backend e teste pareado revisados, incluindo novos arquivos do consumidor. Correções da preparação sobre normalização de ReplicaId, ArgumentError e domínio LWW/outbox do hub permanecem validadas. Sem novo impeditivo de código ou alteração de formato/API. Biblioteca mantém par fixo por cliente; ACK confirma hub, não recepção pelo outro aparelho. Review pelo próprio agente, não independente.
Validação: aprovada
Comandos: adb devices -l, install -r, am start/force-stop, pidof, input, uiautomator dump, exec-out screencap e run-as cat executados por serial. flutter analyze aprovado no Compass; flutter test --no-pub test/notes_configuration_test.dart test/trip_notes_integration_test.dart test/trip_notes_card_test.dart --reporter expanded: dez testes aprovados. dart analyze aprovado no servidor. dart run bin/notes_server.dart --replica notes-hub --clients alpha,beta --snapshot-pull --port 8091 --db /tmp/val15-runtime/notes-hub.sqlite executado e reiniciado com mesmo banco. GET /state/pull validou estado/recipientes. Inspeção Python/sqlite3 das cópias fechadas confirmou valores, IDs e outboxes. Dart/Flutter do PATH; builds/hashes da preparação conferidos, sem novo build nesta execução.
Critérios: 1/2 mantidos pelas provas de preparação e conferidos na topologia física. 3 satisfeito: ambos salvaram nota OFFLINE, tentaram envio sem reverse e receberam SocketException Connection refused, depois salvaram nova nota RETRY durante falha. Force-stop/reabertura preservou notas e pendências. 4 satisfeito: cada banco tinha IDs próprios :delta:1/:delta:2, duas entradas destinadas a notes-hub. Após somente alpha.sync, alpha outbox vazia e beta manteve exatamente suas duas entradas. Beta.sync seguido de alpha.sync convergiu para VAL15_BETA_RETRY, vencedor completo beta:delta:2 com mesmo HLC/dot/value nos dois clientes/hub, todas outboxes vazias. Novo reinício dos apps e do hub preservou resultado; snapshot completo do hub igual antes/depois do restart. Nova sincronização de ambos manteve igualdade/ACK durável. 5 satisfeito por review, regressões de identidade/roteamento/falhas/ACK perdido/duplicação/SQLite/UI, análise app/backend e percurso físico sem correção de produto necessária.
Manutenção: critérios, índice/fase/matriz/DEC-48/RISK-34/roteiro e artefato atualizados; nenhuma tarefa ativa/pronta ou incompleta no plano atual. Backend de teste e apps encerrados, somente reverses tcp:8091 criados removidos. Stay-on temporário restaurado ao valor original 0 nos dois aparelhos. Preferência de tempo de bloqueio ajustada pelo autor permaneceu intacta. Nenhum banco apagado; apps instalados conservam nota confirmada.
Limitações: dois Androids via USB, notas LWW e backend de desenvolvimento. Não extrapolar a iOS/Wi-Fi, oito CRDTs nessa topologia, multiparty genérico, autenticação de produção, histórico causal completo ou entrega incremental no pull. Reserva/catálogo/imagens do sample mantêm limites de VAL-13; fotos 403 não impediram notas. UI observada pelo desenvolvedor, sem estudo com participantes. TCC/publicação permanecem com autor.

Provas persistidas: [dispositivos/APKs/bancos/IDs/PIDs e hub](evidence/val15-runtime.json).
Snapshots resumidos de quatro checkpoints por aparelho incluem estado offline,
ACK alpha isolado, convergência e reconciliação após reinícios. PIDs alpha
7186/9203/10380/11512 e beta 3898/5398/5903/6777 encerrados em cada checkpoint;
sem PID após force-stop. Hub 91358/93044 conforme artefato, com mesmo banco.
Hashes de APKs: alpha 058230c4b987617ce1d2cae34ed748cc479f653d20e828a9e8f42bdb47ea6a2e;
beta 9eccc5414c1ce87bcea661d1f105a4a18931b29e434913a667688af326d56602.
Cópias completas de bancos/telas/logs permanecem temporárias em /tmp/val15-runtime.

Falhas de ambiente preservadas: primeira revisão automática da permissão adb
devices expirou; repetição única autorizada passou, sem interpretar timeout como
rejeição por risco. Tela beta bloqueada interrompeu navegação e produziu dumps
vazios/StopIteration; autor desbloqueou e ajustou timeout. Com tela acessível,
restauração e runtime foram observados antes de concluir. Não houve alteração
do produto para contornar esses eventos nem teste ausente declarado aprovado.

Checks finais da manutenção: python3 scripts/check_plan.py aprovado, 53 tarefas
e 325 links locais, nenhuma pronta; git diff --check aprovado no DeltaSync e no
repositório externo samples_test_lib. Todas as tarefas atuais concluídas;
extensões futuras e limitações documentadas não foram convertidas em tarefas novas.

<a id="preparacao-val-16-2026-10-13"></a>

## Preparação VAL-16 — 2026-10-13 — oito CRDTs entre peers Android

Status final: bloqueada
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: autor autorizou executar ampliação após discutir teste físico dos oito tipos. VAL-15/R-07a/R-26 concluídas; índice/fase, RUNBOOK, contratos/guia Dart e cinco skills conferidos. Lean-build aplicado ao escopo concreto, investigate-first ao bloqueio do fixture. Aparelhos ADB autorizados, IDs/bancos próprios e topologia definidos antes de agir. Worktrees anteriores preservados; um agente, sem delegação.
Implementação: entrada main_eight.dart no projeto Flutter existente, EightScenario para história pública e HttpPeerLink loopback para par direto. Sem novo pacote/dependência ou mudança da biblioteca/Compass. Envelopes passam por receiveEnvelope e ACK é retornado após commit SQLite. Oito tipos consultados por valueAt com catálogo CrdtKind/wireName; JSON ordena sets para inspeção. UI mostra estado/pendências e acompanha commits. HTTP cleartext habilitado somente no manifest debug. Dois testes HTTP/SQLite e teste de widget separados; README/roteiro/mapa adicionados. Seed/branch têm commits por mutação, sem promessa de transação global; resolução MV exige observar duas versões.
Review: aprovado
Achados: corrigidos imports relativos sinalizados pelo analyzer, refresh inicial/remoto/contagem de pendências, guard de base incompleta e comando de edição durante falha. Fixture de widget esperava no fechamento com zonas fake/real; checkpoints demonstraram que recepção passou e dispose ficou esperando. Corrigidos construção/runAsync e bombeamento da drenagem, removidos prints temporários. Misturar testWidgets e HTTP no mesmo isolate ativou HttpOverrides e retornou 400 falso; separação dos arquivos manteve testes HTTP reais. Deltas das correções revistos, sem impeditivo de código; review não independente. Helper novo justificado por I/O HTTP concreto, distinto do enlace sintético R-22; sem framework genérico.
Validação: parcial, runtime beta/reconciliação pendente
Comandos: dart format --output=none --set-exit-if-changed lib test: 13 arquivos sem mudança. flutter analyze --no-pub aprovado; flutter test --no-pub --reporter expanded: sete testes aprovados após todas correções, quatro anteriores e três novos. Teste geral dos oito cobriu base, ramos isolados, envio falho, edição posterior, reabertura SQLite, requisições concorrentes, resultados semânticos, replay idempotente e resolução MV/restauração; segundo rejeitou destinatário errado sem ACK/commit; widget acompanhou commit remoto. flutter build apk --debug --no-pub --target lib/main_eight.dart --dart-define=REPLICA_ID=alpha/beta: dois builds aprovados, Dart/Flutter do PATH. adb install -r, forward/reverse, am start/force-stop, input, uiautomator, GET /state, exec-out run-as cat e inspeção sqlite3 executados por serial.
Critérios: 1/2 satisfeitos pela implementação/review/testes e base nativa recebida. Moto G52 Android 13/API 33 alpha e Moto G53 5G Android 14/API 34 beta carregaram oito tipos em bancos próprios pelo plugin sqflite. Alpha criou base e recebeu ACK de beta; ambos tinham os mesmos oito valores e outbox zero. Removidos reverses para isolar ramificações. Alpha aplicou todos os oito ramos, tentou envio e recebeu Connection refused; editou novamente LWW para alpha-retry, mantendo 11 entradas com peer beta. Force-stop/reabertura (PIDs 21742/22786) preservou exatamente valores/pending/contextos/versões/sequências; só HLC local avançou. Nova cópia SQLite fechada confirmou estado e 11 entradas. Beta conserva base recebida e outbox zero, PID 12765 fechado. Critérios 3/4/5 permanecem parciais: falta desbloquear G53, ramificar beta, restaurar/reconciliar ambos, repetir envelopes e resolver MV no Android, com prova final dos bancos.
Manutenção: VAL-16 criada SHOULD com dependências satisfeitas, depois bloqueada no keyguard do G53; dois critérios marcados, demais abertos. DEC-49/RISK-35/índice/fase/mapa/artefato atualizados. Solicitação de desbloqueio enviada, sem resposta nesta execução. Apps técnicos encerrados, forwards 18092/28092 e reverses 8093 criados removidos; stay-on original 0 restaurado sem alterar timeout do autor. Nenhum banco apagado/clonado. Não recriar base nem repetir branch alpha na retomada; começar pelo ramo beta sobre base preservada.
Limitações: build/host/base compartilhada não substituem conflito e convergência físicos completos. Erro inicial de comparação de snapshot inteiro revelou somente avanço legítimo do HLC no restore; comparação corrigida exige todos os demais campos/valores/pending idênticos. Não alegar igualdade de clocks locais. Helpers loopback de desenvolvimento sem auth/limite de payload, para roteiro técnico. AppId reutilizado substitui entrada da demo, preservando shopper-a/b e usando eight-alpha/beta novos; Compass permanece instalado separadamente. TCC/pub.dev com autor.

[Artefato parcial](evidence/val16-preparacao.json) contém hashes dos dois APKs,
valores da base e snapshots/outboxes dos bancos fechados, PIDs e prova de restore
alpha. Código/roteiro em [oito CRDTs](../example/flutter_mobile/EIGHT_CRDTS.md).
Cópias completas/telas/logs em /tmp/val16-runtime, sem requisito de mantê-los para
ler o artefato persistido. APKs temporários /tmp/eight-alpha.apk e /tmp/eight-beta.apk
são reproduzíveis pelos comandos documentados; reinstalar sempre a mesma identidade.

Checks finais desta manutenção: python3 scripts/check_plan.py aprovado, 54 tarefas
e 330 links locais, nenhuma pronta; git diff --check aprovado. VAL-16 permanece
bloqueada, não concluída; evidência de host não foi apresentada como runtime completo.

<a id="execucao-val-16-2026-10-13"></a>

## Execução VAL-16 — 2026-10-13 — fechamento físico dos oito tipos

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: cinco skills lidas integralmente; dependências/tarefa/índice/roteiro/DEC-49/RISK-35 e último registro conferidos. Autor autorizou retomar após desbloquear telas. Ambos ADB autorizados; G53 agora mostrou controles técnicos, resolvendo impedimento observado. Mantidos bancos/IDs e ramo alpha existente; beta ainda tinha base causal completa. RUNBOOK e guia Dart consultados. Sem delegação.
Implementação: nenhuma alteração de produto ou novos builds nesta retomada. Peers/listeners reabertos com mesmas identidades/bancos e apenas forwards de inspeção inicialmente; reverses continuaram ausentes até ambos ramificarem. Beta executou fases restantes, sem recriar base nem repetir alpha. Documentação/artefato registram resultado final; mudanças anteriores preservadas.
Review: aprovado
Achados: suporte HTTP/EightScenario revistos; mudanças/correções da preparação conferidas, sem novo impeditivo. ACK continua após receiveEnvelope/commit, fora de envio local, sem alteração da biblioteca. Auditoria inicialmente comparou PN positivo/negativo com ausência versus componente zero, apesar de representarem mesmo estado; corrigido comparador de evidência, preservando componentes não zero, sequências e contextos. Primeiro replay manual omitiu wrapper DeltaCodec e recebeu HTTP 400; corrigido fixture para envelope v2/delta codec v4 após leitura do contrato, sem mudar aplicativo. Review não independente.
Validação: aprovada
Comandos: adb devices, forward/reverse por serial, am start/force-stop, input/uiautomator, GET /state, POST /delta, exec-out run-as cat e sqlite3 executados. Moto G52 alpha Android 13/API 33, serial 0081889739; Moto G53 5G beta Android 14/API 34, serial 0085287528. Sete testes Flutter/analyze/format e dois APKs aprovados na preparação após correções, sem mudanças de fonte posteriores; não repetidos por ritual nem apresentados como novos nesta retomada. APKs/hashes no artefato persistido. Canais: host 18092/28092 encaminham listeners 8092; reverse de cada 8093 aponta ao outro host forward; HTTP/TCP entre aparelhos por USB, sem hub.
Critérios: 1/2 preservados pelas provas de implementação/testes/review. 3 fechado: ramos partem da base compartilhada e não receberam alterações do outro antes de editar; alpha com 11 pendências, beta com 13. Ambos tiveram envio falho sem rede, nova edição LWW e force-stop/restauração com mesmas entradas/contextos/versões. Após reconectar, alpha enviou e beta manteve exatamente seus 13 IDs; beta enviou e ambos zeraram outbox. 4 fechado: SQLite fechado de cada aparelho coincide com estado consultado, IDs/peers e contextos conferidos, valores dos oito iguais às expectativas abaixo, ACK após commit. Resolver MV em alpha observou as duas versões; envio produziu apenas resolved nos dois. Após reinício, replay dos envelopes originais (11/13 mudanças) recebeu ACK applied-and-persisted com todos os IDs, sem ressuscitar versões removidas ou alterar contadores/conjuntos/mapa. Bancos finais fechados mantêm resolução e outboxes vazias. 5 fechado: review/correções e host/build da preparação, runtime completo nesta retomada, docs/índice/fase/decisões/riscos e artefato consistentes.
Manutenção: todos os critérios marcados, VAL-16 concluída; nenhuma tarefa ativa/pronta ou incompleta no plano atual. Forwards/reverses criados removidos, stay-on original 0 restaurado, timeout do usuário intacto; apps técnicos encerrados, bancos preservados. TCC/publicação continuam com autor.
Limitações: uma história concreta dos oito CRDTs em dois Androids e canal USB, complementando propriedades/permutação das suítes. Sem iOS/Wi-Fi/produção, autenticação, topologia arbitrária ou transação de oito mutações. Comparação causal exclui owner/sequence locais; ausência de componente PN zero equivale a zero. HLC local avança em restore/recepção, sem perda de versões/contextos. Replay usa fixture host para reenviar conteúdo dos envelopes aos receivers Android; não simula perda de ACK nessa execução física. Sem claim de independência do review.

### Resultados físicos por tipo

| Tipo | Resultado comprovado |
|---|---|
| LWW | beta-retry; vencedor beta:delta:2 e HLC/dot iguais, ranking conferido contra ambos ramos |
| G-Counter | 6; componentes/sequências equivalentes, sem duplicação no replay |
| PN-Counter | 3; positivos alpha 5, negativos beta 2; zeros locais equivalentes |
| G-Set | alpha, beta, seed; mudanças/dots convergentes |
| 2P-Set | alpha, beta; shared permanece removido apesar da adição concorrente |
| MV-Register | alpha/beta concorrentes; depois somente resolved, sem ressuscitar versões no replay |
| OR-Set | alpha, beta, shared; nova tag concorrente sobrevive à remoção observada |
| OR-Map | shared contém beta; encarnação removida não ressuscita seed |

[Artefato completo](evidence/val16-runtime.json) preserva estados offline e antes
da resolução, snapshots finais dos dois bancos, IDs/peers/PIDs/hashes, receipts de
replay, auditoria e limpeza. Ramo beta: PID 14053 antes e 14312 depois do reinício;
resolução: alpha 24617/beta 14312; final após novo restart: alpha 25815/beta 15340.
Nenhum PID após force-stop. Snapshot/contexto/outbox foram preservados em cada
restore, exceto avanço legítimo de HLC local. Logs/telas/bancos completos em
/tmp/val16-runtime complementam o artefato persistido. Histórico da preparação
bloqueada permanece acima, sem substituir seu resultado por aprovação retroativa.

Checks finais da manutenção: python3 scripts/check_plan.py aprovado, 54 tarefas
e 334 links locais, nenhuma pronta; git diff --check aprovado. Artefato final
reconferido: oito valores comuns, MV resolvido, outboxes vazias, ACKs de replay
com 11/13 IDs e pendências beta intactas após ACK alpha. Nenhuma tarefa ativa.

## Manutenção da distribuição e evidências — 2026-10-13

Pedido: autor autorizou criar .pubignore e corrigir .gitignore, mantendo exemplos
consultáveis no repositório e excluindo-os do download da biblioteca. Aplicado
plan-maintainer; nenhuma tarefa de produto reaberta ou publicação autorizada.

Alterações: .pubignore da raiz usa lista explícita de inclusão: lib, README,
CHANGELOG, LICENSE, pubspec, analysis_options e exemplo mínimo deltasync_example.
Demais exemplos, medições, subpacotes do monorepo, planos/evidências e ferramentas
ficam fora do arquivo da facade. Regras adicionais excluem build/cache/coverage,
locks e APK/AAB mesmo dentro de diretórios incluídos. .gitignore preserva regras
anteriores e acrescenta exclusões de gerados; exceções estreitas permitem versionar
patches e runtime JSON de plan/evidence. README fornece link completo ao repositório
para consultar/clonar exemplos e documentos excluídos do pacote.

Review: aprovado para o escopo de filtragem, pelo mesmo agente. Sem remoção de
arquivos, staging ou commit; trabalho anterior preservado. O exemplo mínimo é
independente dos helpers Flutter/SQLite excluídos. As inclusões da facade usam
dependências públicas dos subpacotes, sem copiar fontes do monorepo para seu pacote.

Validação: dart pub publish --dry-run, Dart do PATH, gerou lista esperada e
arquivo comprimido de 19 KB. Incluiu somente os arquivos acima; não incluiu
Flutter, medições, plan/evidence ou binários. Processo terminou com código 65
por três avisos: README modificado no Git, ausência de homepage/repository no
pubspec e CHANGELOG sem entrada para versão 2.0.0. Não são falhas de filtragem;
preparação final de publicação permanece com o autor. Nenhum upload executado.
git check-ignore --no-index confirmou 11 patches/runtime JSON disponíveis para
Git e build/APK/coverage ignorados. Testes Dart não repetidos: mudança de regras
de distribuição/documentação, sem alterar código da biblioteca ou consumidores.

Limitações: dry-run da facade não substitui validação/publicação de cada subpacote,
disponibilidade das versões dependentes ou prova de consumo instalado do pub.dev.
Link do repositório é estável; exemplos/evidências novos precisam ser commitados
e enviados pelo autor para ficarem disponíveis remotamente. Nenhuma tarefa ativa;
conclusões técnicas anteriores preservadas, sem confundir filtros com pacote publicado.

Checks finais: python3 scripts/check_plan.py aprovado, 54 tarefas e 334 links
locais; git diff --check aprovado. Status e critérios técnicos preservados.

<a id="execucao-r-28-2026-10-15"></a>

## Execução R-28 — Distribuição dos sete pacotes, 2026-10-15

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: VAL-16 concluída; critérios de R-28 e achados de distribuição verificados.
Implementação: metadados/documentos/licenças e preparação independente dos sete releases, detalhados abaixo.
Review: aprovado
Achados: correções de filtros, referências e semântica documental revistas; nenhum impeditivo restante. Review não independente.
Validação: aprovada
Comandos: preparação, format/analyze/test, sete dry-runs, consumidor hosted e conferência de hashes detalhados abaixo e no JSON.
Critérios: distribuição/licença provadas por arquivos/hashes; metadados/docs por review; sete dry-runs sem avisos; consumo externo com nove testes; workspace com 243 testes e manutenção registrada.
Manutenção: critérios/índice/fase concluídos; DEC-50, OPEN-07 e RISK-36 atualizados; nenhuma próxima tarefa pronta.
Limitações: sem upload/commits/merges/tags, sem instalação real do pub.dev ou runtime novo de plataforma; publicação pelo autor dos diretórios preparados.

Autorização: autor pediu corrigir os achados de prontidão para pub.dev. Aplicados
plan-reader, plan-implementer, code-reviewer, plan-validator e plan-maintainer no
mesmo agente. Worktree inicialmente limpa, branch develop, base b3a6ed2. Publicação,
commits, tags e merges continuam com o autor; nenhuma escrita do TCC executada.
Tarefa SHOULD depende de VAL-16 concluída. Índice/fase percorreram andamento,
revisão e validação antes da conclusão.

### Leitura e diagnóstico

Dry-runs iniciais: facade com arquivo válido de 19 KB, mas sem repository e sem
entrada 2.0.0 no changelog. Seis subpacotes geravam arquivos vazios, pubspec oculto
e licença ausente. README/changelog também faltavam em parte dos pacotes. Não era
defeito nos CRDTs: o pub aplica filtros desde a raiz Git, onde `.pubignore` exclui
`packages/`. Tentativa de whitelist local confirmou que ela não recupera o
diretório ancestral ignorado; os filtros locais tentados foram removidos.

### Implementação

Sete manifests receberam repository/issue_tracker; sete changelogs descrevem
2.0.0, preservando o histórico 1.0.0 da facade. Seis licenças são cópias idênticas
do BSD existente, conferidas por bytes/SHA-256. Quatro READMEs novos explicam
contratos/consumo/limites; READMEs SQLite e testing receberam dependências,
import e links consultáveis fora do monorepo. Facade aponta para o
[guia de publicação](../docs/publicacao.md), mantendo links de exemplos/Compass.

`scripts/prepare_release.py` exporta sete diretórios fora do Git, sem sobrescrever
destinos. Copia fontes/documentos públicos e apenas o exemplo Dart mínimo na
facade; gera inventário SHA-256 e filtros de cache/build/lockfile. Remove somente
workspace/resolution dos manifests exportados. Comparação por parsing YAML dos
sete manifests confirma todos os outros campos preservados. Fontes `lib` e testes
existentes não mudaram; nenhum formato persistido/API foi alterado.

DEC-50 explica a escolha: preservar layout/filtro da facade e preparar releases
independentes. Publicação direta de subpacotes dentro do Git continua excluída
pelo filtro ancestral; o guia exige os diretórios preparados. Lista explícita de
cópia deve ser atualizada quando houver novos recursos distribuíveis. Ordem:
core; storage/transport; sync/storage_testing; storage_sqflite; facade.

### Review e correções

Review pelo próprio implementador, em etapa separada; não independente.
Inspecionados diff e arquivos novos, filtros, manifests, licenças, documentação,
script e fixture do consumidor. Corrigidos stream inexistente `events` para
`commits`, ressalva do ACK automático via IncomingAcknowledgingDeltaTransport,
link da fixture SQLite e clareza sobre leitores antigos no changelog. Guarda do
script distingue marcador Git real de diretório `.git` vazio do host temporário.
Correções revistas antes da rodada final. Fixture externa também foi formatada
após alteração de rótulo; o gate de formato inicialmente falho passou na repetição.
Peer remoto da integração final usa SQLite real e verifica snapshot reaberto.
Sem achado impeditivo pendente; review não certifica produção ou plataformas novas.

### Validação

Ambiente: Dart 3.13.5 stable do PATH, Python 3.15.0, Linux x86_64. Constraint
permanece ^3.12.0; o SDK mínimo não foi executado. Resultados detalhados e hashes:
[registro R-28](evidence/r28-release-validation.json). Consumidor reproduzível:
[fixture externa](evidence/r28-consumer.patch), aplicada em diretório vazio fora
do workspace, com pubspec normal e sem overrides.

- Script: sintaxe aprovada; três guardas de destino e cinco casos de manifesto
  aprovados, além de preparação com destino explícito e destino padrão.
- Nos sete pacotes do workspace: `dart format --output=none --set-exit-if-changed
  lib test`, `dart analyze`, `dart test --reporter expanded`. Todos aprovados:
  facade 13, core 122, storage 12, transport 10, sync 51, testing 8, SQLite 27.
  Total **243 testes**. Não confundir suíte da raiz com workspace inteiro.
- Preparação final: `python3 scripts/prepare_release.py --output
  /tmp/deltasync-r28-final`. Sete dry-runs com exit 0 e **zero avisos**; tamanhos
  comprimidos informados pelo pub: core 31 KB, storage 6 KB, transport 3 KB,
  sync 9 KB, testing 4 KB, SQLite 5 KB, facade 20 KB. Todos incluem lib, pubspec,
  README, changelog e licença. Facade só inclui seu exemplo mínimo, sem planos,
  evidências, exemplos completos, testes ou fontes dos outros pacotes.
- Registro hosted local somente leitura em loopback serviu sete tar.gz dos
  arquivos preparados, sem `.pubignore`; metadados externos passaram por GET ao
  pub.dev, mantendo URLs de download originais. Nenhum POST. Compressão/tar dessa
  fixture difere do pub; conferência usa conteúdo dos arquivos e hashes do
  artefato servido, sem alegar igualdade binária com upload do pub.
- Cache novo em `/tmp/r28-final-pub-cache`; sete downloads locais registrados.
  Consumer `/tmp/r28-consumer`: `dart pub get` resolveu sete versões 2.0.0 como
  hosted, sem workspace, path ou dependency_overrides. Hashes dos sete archives
  coincidem com pubspec.lock; package_config aponta apenas para cache temporário.
  Todos os arquivos instalados conferem com o inventário e cada fonte lib com
  seu original. Licença idêntica, sem mudança nas restrições de dependência.
- Consumidor: format/analyze e **nove testes aprovados**. Oito da suíte pública
  de contrato no SQLite FFI, incluindo falha transacional/rollback, isolamento,
  concorrência e ACK por peer. Integração facade executa commit offline LWW/G,
  fecha/reabre SQLite local, restaura duas pendências, recebe/confirma no peer
  SQLite, reabre peer com valores preservados e reabre local com outbox vazia.
  Transporte em processo; fechamento/reabertura não equivale a kill de processo.
- `dart analyze` dos sete diretórios preparados aprovado. Exemplo mínimo
  distribuído executado: três pendências e três confirmações, valor remoto certo.
- Dry-run adicional da facade na worktree: arquivo válido de 20 KB, exit 65 por
  **um aviso Git** dos três arquivos distribuídos modificados (README, changelog,
  pubspec). Avisos anteriores de metadados/changelog desapareceram. Diretórios
  preparados não possuem Git; isso não dispensa revisar/commitar fontes finais.
- Seis links de arquivos GitHub dos READMEs/guia conferidos contra caminhos locais.
  Disponibilidade remota em main depende dos merges/pushes do autor.

### Manutenção e limites

R-28 concluída; 55 tarefas concluídas, nenhuma próxima selecionável. Índice/fase,
DEC-50, OPEN-07 e RISK-36 registram conteúdo, fluxo e limites. Não houve upload,
tag, commit ou merge. Antes de publicar, autor confere propriedade/disponibilidade
dos nomes, dependências já publicadas, autenticação e checks do servidor. Depois
dos envios, repete instalação em consumidor novo contra pub.dev. Registro local
não prova essa etapa. Novo Android/iOS não foi executado: fontes de runtime iguais
às evidências anteriores. Não extrapolar para segurança/topologia de produção.

Checks após manutenção: `python3 scripts/check_plan.py` aprovado, 55 tarefas e
343 links locais; `git diff --check` aprovado. Campos obrigatórios do registro
foram completados após a primeira checagem estrutural. JSON validado, patch do
consumidor aprovado por `git apply --check` em diretório vazio e novos arquivos
sem erros de whitespace. Servidor local de validação encerrado.
Após o dry-run adicional da raiz, `dart pub get` restaurou registro/cache normais
da worktree. Conferidos sete membros locais, sem URLs/paths temporários no
lockfile/package_config. Format/analyze e os 243 testes passaram novamente nos
sete pacotes após essa restauração, sem depender do servidor local encerrado.

<a id="execucao-r-29-2026-10-15"></a>

## Execução R-29 — Versão pública 1.0.0, 2026-10-15

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: autor confirmou alteração nos pubspec.yaml; R-28 concluída, worktree inicialmente limpa. Escopo limitado a versão/consumo/documentação de release; guia Dart consultado, SDK preservado.
Implementação: sete version 1.0.0, 17 dependências internas ^1.0.0, seis READMEs e sete changelogs alinhados. Facade ficou com uma única seção 1.0.0, consolidando o placeholder Initial version nos detalhes entregues. Guia explica numeração atual e prova histórica de R-28.
Review: aprovado
Achados: diff revisado pelo mesmo agente, não independente. Removida linha vazia extra no fim do changelog, detectada por git diff --check; correção revista e conferida. Nenhum impeditivo restante. Formatos JSON, snapshots, schema, fontes e contratos não foram renumerados.
Validação: aprovada
Comandos: dart pub get --offline aprovado; dart pub deps --json > /tmp/deltasync-r29-deps.json confirmou sete membros em 1.0.0. python3 scripts/prepare_release.py > /tmp/deltasync-r29-release-path gerou sete releases novos; checks Python de manifests/exports/changelogs e git diff --check aprovados.
Critérios: sete manifests diferem da base apenas pela troca literal 2.0.0 para 1.0.0, com SDK/dependências externas intactos; 17 constraints internas conferidas. Sete manifests exportados em 1.0.0 sem workspace/resolution, documentos/licenças iguais aos fontes e lib copiada byte a byte. Changelogs têm exatamente uma seção 1.0.0; sem diff em lib/test dos pacotes. Exemplo Flutter usa paths e permanece compatível com os manifests locais.
Manutenção: índice/fase/checkboxes concluídos; DEC-51 substitui apenas numeração de DEC-17, OPEN-07 e nota de RISK-36 atualizadas. Evidências 2.0.0 anteriores preservadas. Nenhuma próxima tarefa pronta.
Limitações: sem upload, commit, tag, merge, dry-run público ou novo teste de runtime. Testes Dart não repetidos para alteração de metadados/documentação. Disponibilidade/propriedade de nomes e versões no pub.dev continuam com o autor; prova hosted de R-28 conserva sua numeração histórica.

Exportação final validada em `/tmp/deltasync-release-parent-ikhy2_g5/release`.
Exports anteriores não são atualizados pela mudança dos fontes; gerar novos antes
de publicar. A renumeração não torna formatos antigos compatíveis automaticamente;
permanecem as migrações e limites documentados. Checks de manutenção:
`python3 scripts/check_plan.py` aprovado com 56 tarefas e 345 links locais;
`git diff --check` aprovado.

<a id="planejamento-1-0-1-2026-10-24"></a>

## Planejamento de manutenção 1.0.1 — 2026-10-24

Tipo: manutenção documental autorizada; nenhuma tarefa nova implementada.
Skills aplicadas: plan-reader e plan-maintainer, com leitura integral e consulta
ao RUNBOOK e aos trechos pertinentes do guia Dart sobre contratos e enums.
Pedido: autor solicitou planejar todos os encaminhamentos da análise geral
para 1.0.1, mantendo foco exclusivo na biblioteca. Não pediu alterações no app.

### Origem e evidências disponíveis

Antes desta edição documental, HEAD era
`1e969182e8e172a8858a48ecf83a1feb2c21a455`, com worktree limpa. Sete pacotes em
1.0.0. Na revisão da mesma sessão, Dart 3.13.5 stable/Linux x86_64 executou
análise sem issues e 243 testes: facade 13, core 122, sync 51, storage 12,
SQLite 27, storage_testing 8 e transport 10. Comando na raiz:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart analyze && dart test --reporter expanded) || exit 1
done > /tmp/deltasync-general-review-20261024.log 2>&1
```

A primeira tentativa encontrou cache Flutter fora da área gravável; execução
autorizada posterior terminou com exit 0. Esse log é temporário e não é fixture
de release. R-30 exige baseline reexecutável; esses resultados não concluem
nenhuma tarefa da fase 6 nem validam código 1.0.1 ainda inexistente.

Inspeção de [mergeOutbox](../packages/deltasync_sync/lib/src/sync/replica_persistence.dart)
e [Delta.merge](../packages/deltasync_core/lib/src/delta.dart) confirma remontagem
de prefixos, com trabalho quadrático para entradas distintas. Impacto temporal
não medido nesta revisão. Cópias de candidata/adoção e snapshots protegem
isolamento e precisam de medição antes de outras mudanças.

O consumidor externo em `/projetos/tcc/samples_test_lib/compass_app` confirmou
uso público de valueAt, observations, receiveEnvelope e ReplicaStorage. Dez
testes focados passaram, incluindo HTTP com servidor separado e SQLite FFI.
Três diagnósticos temporários, fora dos repositórios, reproduziram: tipo de nota
incompatível com JSON válido, edição que lança erro de consulta após commit
durável e duas consultas de pendências por edição. São evidências de fronteira
de consumo e custo, não três defeitos novos dos joins/commits da biblioteca.
Sem nova execução Android e sem alterações no app. A fase nova exige exemplos
e regressões gerais na própria lib, sem depender de caminhos externos.

### Decisões de planejamento

- Criada [fase 6](06_PHASE6_MANUTENCAO_1_0_1.md), integrada ao índice canônico,
  com R-30 a R-36 e VAL-17 para 1.0.1. Cada tarefa tem áreas, critérios,
  dependências e verificações; nenhuma está em execução ou concluída.
- R-30 está pronta e é a próxima selecionável. Demais tarefas de release
  aguardam dependências. R-37/R-38/R-39 são WON'T-YET, fora do gate 1.0.1,
  sem autorização de execução mesmo após suas dependências serem concluídas.
- A análise previa funcionalidades novas e remoções públicas. DEC-52 aplica
  [SemVer](https://semver.org/): consulta leve e ampliações compatíveis pertencem
  à linha minor; remoções/quebras à major. Novos métodos obrigatórios em
  interfaces também podem quebrar adaptadores e não entram como minor compatível.
- DEC-53 preserva VAL-05 histórico e cria gate específico VAL-17 para os
  artefatos novos. SHOULD expressa prioridade acadêmica; completar a release
  planejada exige todas as dependências de VAL-17, inclusive avaliar o piloto.
- DEC-54 mantém papéis de core/sync/storage/transport, mede custos e separa
  ferramentas de segurança/correção. Saropa será avaliado isoladamente; adoção
  não foi decidida. Conferidas referências oficiais de
  [Saropa](https://pub.dev/packages/saropa_lints),
  [advisories Dart](https://dart.dev/tools/pub/security-advisories) e
  [versionamento Dart](https://dart.dev/tools/pub/versioning).
- Índice, decisões abertas e RISK-37 a RISK-40 registram os encaminhamentos.
  Não alterados manifests, fontes, testes de produto ou contratos. Nenhum
  pacote renumerado/publicado e nenhuma ferramenta instalada neste planejamento.

### Review e validação documental

Review: realizado pelo próprio agente, em etapa distinta; não independente.
Verificados cobertura da análise, compatibilidade patch/minor/major, prioridades
relativas ao TCC, dependências e separação entre planejar e executar.
Validação documental: aprovada. `python3 scripts/check_plan.py` confirmou 67
tarefas, 367 links locais e somente R-30 pronta; `git diff --check` aprovado.
Índice/fase, status, anchors, dependências sem ciclos e metadados das skills
foram conferidos. A fase 6 não altera os critérios concluídos das fases antigas.
Testes Dart/Flutter não repetidos nesta edição somente documental; resultados
anteriores acima são baseline contextual, não aprovação de implementação futura.
Limitações: duração/esforço não estimados; publicação e ativação externa de CI
permanecem fora deste pedido. R-30 define baseline e a execução posterior exige
o ciclo completo de cinco skills por tarefa, sem subagentes.

<a id="escopo-integral-1-0-1-2026-10-24"></a>

## Ajuste de escopo integral para 1.0.1 — 2026-10-24

Tipo: revisão documental do planejamento por direção explícita do autor.
Skills: plan-reader e plan-maintainer, lidas integralmente; sem implementação.
Pedido: autor reconhece que parte das mudanças deveria chegar a outra versão,
mas deseja todos os pontos planejados na mesma 1.0.1. Isso resolve a escolha
de versão e substitui a separação anterior entre patch/minor/major. O registro
anterior permanece histórico; suas restrições de adiamento não são vigentes.

### Alterações de planejamento

- R-37/R-38/R-39 passam de WON'T-YET a SHOULD, integrando o gate 1.0.1.
  R-37 entrega pendências leves; R-38 passa de avaliação a lote público atômico;
  R-39 remove storage/aliases legados com readers e migração de dados preservados.
- Criadas R-40, R-41 e R-42 para decoder opcional, eventos seletivos com emissão
  consolidada e consulta de ausente/null/tombstone. Todas têm critérios próprios
  de implementação, falhas, isolamento, consumo e validação; não apenas avaliação.
- R-30 fixa baseline e mapa de migração. R-35 documenta todas as APIs e quebras;
  R-36 exige os sete artefatos em 1.0.1 com aviso de upgrade incompatível;
  VAL-17 verifica dados 1.0.0, consumidores migrados e toda a entrega nova.
- Dependências foram reordenadas para retirar legado antes das novas APIs e
  alcançar R-30 a R-42 pela VAL-17, sem ciclos. Nenhum desses itens fica para
  outra versão. R-30 permanece a única tarefa pronta e nenhuma está iniciada.
- DEC-55/56 substituem as restrições de DEC-52/53, preservando seu histórico.
  OPEN-08, RISK-38/40/41, índice e gate refletem a decisão do autor.
- Manter oito CRDTs, invariantes, SDK, formatos/readers e foco exclusivo na lib.
  A decisão não autoriza descartar dados, publicar pacotes ou editar o Compass.
  Saropa continua com piloto e decisão fundamentada, conforme pedido de análise.

### Review e validação

Review: realizado pelo mesmo agente em etapa distinta, sem revisão independente.
Conferidos direção do autor, cobertura de todos os pontos, quebras de API,
preservação dos dados, dependências e limites entre planejar e implementar.
Validação documental: aprovada. `python3 scripts/check_plan.py` confirmou 70
tarefas, 372 links locais e somente R-30 pronta; `git diff --check` aprovado.
Conferência adicional da árvore de dependências demonstrou que VAL-17 alcança
todas as tarefas R-30 a R-42, sem itens WON'T-YET. Fase nova conferida quanto
a whitespace e newline final. Índice, títulos, prioridades e dependências
espelham as definições da fase, sem ciclos nem tarefa nova marcada concluída.
Nenhuma mudança em fontes, manifests ou testes de produto; os manifests continuam
1.0.0 até a tarefa de release. Testes Dart/Flutter não repetidos para estas edições
documentais. Nenhuma implementação, instalação de ferramenta ou publicação feita.

<a id="recuperacao-stash-2026-10-24"></a>

## Recuperação de conflitos do stash — 2026-10-24

Pedido: resolver conflitos sem perder análise e planejamento da 1.0.1.
Procedimento: plan-maintainer; inspeção dos três estágios Git e do stash,
resolução manual por apply_patch e validação documental. Nenhuma implementação.

O stash foi aplicado sobre HEAD 6b7016a, cuja árvore mantém manifests 2.0.0.
A base do stash, 1e969182e8e172a8858a48ecf83a1feb2c21a455, já tinha R-29 e
manifests 1.0.0. Os conflitos atingiam README, DECISIONS e TRACEABILITY; RISKS
foi recuperado sem conflito e a fase 6 permaneceu como arquivo novo fora do índice.

Preservados integralmente escopo 1.0.1, R-30 a R-42, VAL-17, decisões, riscos e
evidências das análises anteriores. Reposto o registro histórico R-29 na fase 1
e no índice, pois dependências/links recuperados o referenciam. Sua conclusão é
histórica; não afirma que a branch atual já foi renumerada. DEC-57 e a entrada
da fase 6 deixam essa diferença explícita. Manifests, código e alterações da
branch atual foram preservados; a resolução não reaplica renumeração de pacotes.

Backup dos documentos antes da resolução e referências do índice/stash:
`/tmp/deltasync-stash-recovery-hanaswca`. Stash original conservado. A fase 6
também foi incluída no índice para que sua preservação não dependa de um arquivo
não rastreado ao repetir stash/commit. Nenhum commit ou descarte de stash realizado.

Review: realizado pelo mesmo agente, em etapa distinta, sem revisão independente.
Validação documental: aprovada. `python3 scripts/check_plan.py` confirmou 70
tarefas, 372 links locais e R-30 pronta; `git diff --check` e
`git diff --cached --check` aprovados. `git ls-files -u` e lista de arquivos
em conflito vazios. Conferidos alcance R-30 a R-42 pela VAL-17, identidade do
stash original e alterações restritas a plan/. Testes Dart não repetidos;
resolução limitada a documentos de planejamento e ao índice de conflitos Git.

<a id="execucao-r-30-2026-10-24"></a>

## Execução R-30 — Baseline e mapa de migração, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-30 era a única pronta, dependente de R-29 histórica concluída; worktree inicialmente limpa em 400161283e741d62dddf01cfc314629968a93828. Conferidos cinco critérios, DEC-55/56/57, riscos e guia Dart sobre contratos/enums. Identificada divergência apenas de versões/documentação entre baseline 1.0.0 e manifests atuais 2.0.0; execução limitada a R-30.
Implementação: adicionados inventário público, captura reproduzível, fixture JSON dos oito tipos, consumidor independente, medidor da outbox e mapa de migração em plan/evidence/r30. Captura exporta o Git histórico e resolve suas dependências offline, sem alterar produção, SDK ou manifests. Tarefa/índice passaram por em andamento, em revisão e em validação, com retornos para correção.
Review: aprovado
Achados: revisão do próprio implementador, não independente. Corrigidos lint no extrator, fonte antiga sob análise recursiva, possibilidade de sobrescrever fixtures via --report, flags contraditórias, registro fixo de SDK e variação de formato fora do workspace. Fontes históricas viraram .dart.txt com @dart=3.12; guardas, correções e delta final foram revisados antes de repetir os checks afetados. Nenhum impeditivo restante para os critérios de R-30.
Validação: aprovada
Comandos: loop de analyze/test dos sete pacotes no SDK Dart 3.13.5; após pedido de usar dart no PATH, python3 plan/evidence/r30/capture.py --dart dart --test-consumers --report plan/evidence/r30/baseline.json; dart format --output=none --set-exit-if-changed lib test packages plan/evidence/r30; dart analyze; dart --packages=.dart_tool/package_config.json plan/evidence/r30/measure_outbox.dart; formato dos dois fontes materializados; cinco casos negativos da CLI. Resultados/logs e detalhes abaixo e em validation.json/baseline.json.
Critérios: C1 coberto por 47 hashes de fontes, inventário das sete superfícies, 243 testes e fixtures do writer histórico; C2 por matriz de versões, igualdade completa de snapshot/outbox e readers de fronteira; C3 pelas quatro cargas com oito tipos/dois peers; C4 pelo mapa de substitutos e impacto nas interfaces/eventos; C5 pela matriz executável de SDK mínimo/referência e consumidores históricos/atuais. Definir a execução mínima não equivale a executá-la.
Manutenção: cinco critérios marcados, evidência ligada à fase, índice/fase atualizados, DEC-58 e RISK-37/42 registrados; R-31 e R-33 prontas, próxima recomendada R-31, nenhuma tarefa ativa. Fase 6 permanece aberta; não executadas tarefas seguintes.
Limitações: SDK 3.12.x não executado, apenas execução definida conforme o critério; R-33/VAL-17 devem realizá-la. SQLite FFI/Linux com fechamento/reabertura, sem kill de processo, novo Android, rede real ou instalação hosted. ACK do consumidor é controlado. API nova e remoções ainda não implementadas; versões atuais permanecem 2.0.0, alvo futuro 1.0.1. Sem commit, tag, push ou publicação.

### Leitura e delimitação

As cinco skills foram lidas integralmente antes da implementação e aplicadas
nas etapas correspondentes pelo mesmo agente. Dependência histórica R-29 e
direção de incluir tudo na 1.0.1 foram preservadas; não reaplicada renumeração.
O [mapa de migração](evidence/r30/README.md#mapa-de-migração-para-a-101)
distingue substitutos públicos existentes das assinaturas que as tarefas
R-37/R-38/R-40/R-41/R-42 ainda devem definir. Uso/manutenção continuam locais:
estado e join no core, commit/restauração em sync/storage, SQL no adaptador e
domínio/rede/UI no consumidor. Nenhuma abstração adicionada ao fluxo de produto.

### Implementação e proveniência

- [baseline.json](evidence/r30/baseline.json) conserva revisões, hashes dos
  47 arquivos lib, versões/SDK dos sete manifests, resolução histórica real
  por `dart pub get --offline` e origem dos imports nos consumidores.
- [api_1_0_0.json](evidence/r30/api_1_0_0.json) fixa assinaturas públicas
  alcançadas pelos exports, incluindo construtores, membros, enums e aliases.
  O extrator respeita show/hide; validateJsonValue e tabelas internas não vazam
  pelo inventário. A facade alcança 62 símbolos, com sobreposição de reexports.
- [fixture_1_0_0.json](evidence/r30/fixture_1_0_0.json) foi gerada exclusivamente
  com package_config das fontes 1e969182e8e172a8858a48ecf83a1feb2c21a455.
  Contém 23 mudanças locais, 46 entradas para dois peers, snapshot dos oito
  tipos, LWW null/tombstone, MV concorrente/compacto, lacuna OR-Set e recriação
  OR-Map. Hash SHA-256 dos dados:
  `088e79d45c05bc2e8f2da0fb99981333f2dcf4fb3a2a036bd58fe6a3ea737325`.
  Regeneração determinística pelo writer antigo conferida byte a byte;
  regressões futuras leem a fixture congelada, sem gerar expectativas no writer novo.
- Fontes de consumidor/gerador são assets explícitos, para que remoção de API
  não quebre análise recursiva de um arquivo antigo. O consumidor implementa
  ReplicaStorage, PendingDeltaStore, contratos de transporte/ACK e a fixture
  da suíte pública sem importar src; somente o medidor acessa mergeOutbox interno.
- [outbox_baseline.json](evidence/r30/outbox_baseline.json) registra 32/128/512/
  1024 entradas, oito tipos e dois peers. Cinco amostras após dois aquecimentos;
  construção das entradas fora do cronômetro, heap não medido. Visitas aos
  prefixos são estimativa analítica do algoritmo histórico, não instrumentação.

### Review, correções e revalidação

O review verificou independência entre writer histórico e leitura atual,
imutabilidade das expectativas, publicação dos contratos e preservação da
causalidade, IDs, tentativas e destinos após restauração. O script não altera
fontes de produto para satisfazer o procedimento. O SDK de referência é
3.13.5 stable/Linux x86_64; instrumentos usam a dependência analyzer 14.5.0
já selecionada no desenvolvimento, sem adicioná-la ao runtime.

Correções proporcionais verificadas depois de cada delta:

1. `use_null_aware_elements` no novo instrumento foi corrigido; a análise final
   da raiz ficou sem issues. Os testes de produto não foram repetidos porque
   nenhuma fonte de produto ou teste desses pacotes mudou.
2. Fontes antigos ficaram como assets materializados; o consumidor ganhou
   verificação de Isolate.resolvePackageUri para demonstrar qual árvore usa.
3. Cinco guardas rejeitam saída de relatório sobre dados/API/fontes congelados
   e flags incompatíveis com exit 2, mantendo hashes intactos.
4. O registro de SDK mínimo passou a depender do SDK real e checks executados;
   não registra resultado de runtime inexistente.
5. O check de formato do consumidor isolado inicialmente variou pela linguagem
   padrão fora do workspace. `@dart=3.12` fixa a linguagem declarada da biblioteca;
   os dois assets passaram no formato e os 14 checks por árvore foram repetidos.
   Isso não substitui executar um binário SDK 3.12.x.

### Validação executada

[validation.json](evidence/r30/validation.json) retém saídas e contagens reais.
O loop inicial dos sete pacotes usou o executável do SDK já disponível, antes
do pedido posterior de usar o comando `dart`. Comando efetivamente executado:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && /home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart analyze && /home/yago/.cache/flutter_sdk/bin/cache/dart-sdk/bin/dart test --reporter expanded) || exit 1
done > /tmp/deltasync-r30-workspace.log 2>&1
```

Resultado: **243 testes** aprovados, facade 13, core 122, sync 51, storage 12,
SQLite 27, testing 8 e transport 10. A análise inicial apontou um info do
instrumento novo, corrigido antes da análise final. Tentativas em sandbox
encontraram gravação de telemetria/cache fora da área gravável; execução
autorizada posterior passou. A interrupção do usuário não foi tratada como falha
de produto; conferidos logs/processos antes de retomar usando `dart`.

Comandos finais com `dart`:

```sh
python3 plan/evidence/r30/capture.py --dart dart --test-consumers --report plan/evidence/r30/baseline.json
dart format --output=none --set-exit-if-changed lib test packages plan/evidence/r30
dart analyze
dart --packages=.dart_tool/package_config.json plan/evidence/r30/measure_outbox.dart
```

- Formato: 76 arquivos, nenhuma alteração necessária; dois fontes históricos
  materializados também aprovados com linguagem 3.12.
- Análise final da raiz: sem issues; demais seis análises do loop aprovadas.
- Consumidor histórico: **14 checks** aprovados; consumidor atual: os mesmos
  **14 checks**, total de 28 execuções de cenários, não 28 cenários diferentes.
  Incluem 8 checks da suíte de contrato, origem real dos imports, snapshots/
  outbox/envelope/ACK, readers legados, aliases, SQLite reaberto e ACK parcial
  que preserva o peer não confirmado. Próxima escrita usa ID novo; dots 1/2
  entregues depois do 3 continuam visíveis quando não foram observados/removidos.
- Baseline de custo: faixas 1816–2974 µs (32), 3783–6719 µs (128),
  19779–25048 µs (512) e 67486–82999 µs (1024) nas cinco amostras do host.
  Fórmula do percurso histórico: 528, 8256, 131328 e 524800 visitas a prefixos.
  Sem afirmação de ganho universal ou comparação de heap/I/O.
- Sintaxe Python e cinco guardas CLI aprovadas; fixture/API e os fontes
  conferidos por SHA-256. JSONs e escopo dos arquivos revisados.

### Manutenção

R-30 satisfaz os cinco critérios: baseline reproduzível; dados/API/formato
preservados; cargas de custo; mapa de migração; matriz de execução por SDK.
O último critério exige definir a execução mínima, não alegar tê-la realizado:
[matriz e comandos](evidence/r30/README.md#matriz-de-sdk) ficam com execução real
pendente de R-33/VAL-17. DEC-58 e RISK-42 tornam esse limite explícito.
R-31 é a próxima recomendada, R-33 também pronta; nenhuma iniciada. A fase 6 e
o gate VAL-17 seguem abertos. Após manutenção, `python3 scripts/check_plan.py`
e `git diff --check` foram aprovados; conferidos também arquivos novos,
hashes/JSONs e ausência de alterações em produção.

<a id="execucao-r-31-2026-10-24"></a>

## Execução R-31 — Montagem linear da outbox, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: R-30 concluída, R-31 recomendada e pronta, worktree limpa em b792dc5e8312202e7a981c941d30d585b64e771b. Conferidos critérios completos, DEC-58, RISK-37 e guia Dart. Scope restrito ao helper sync e regressões; manter core/joins, contratos, formatos, filas e ACK.
Implementação: mergeOutbox agora coleta mudanças uma vez e executa uma única Delta.merge; regras de conflito/ordem permanecem no core. Adicionadas seis regressões em sync e nota Unreleased no changelog; nenhuma classe ou dependência de produção nova. R-30 e suas fixtures foram preservadas.
Review: aprovado
Achados: revisão do próprio agente, não independente. Confirmados equivalência das duplicatas com ordem de chaves JSON diferente, rejeição de listas divergentes e preservação dos IDs cumulativos. Ajustados teste para conflito entre peers, acesso nullable local e formato do helper de falha; revisão do delta repetida após correção do gate de formato. Nenhum impeditivo restante.
Validação: aprovada
Comandos: dart test test/outbox_merge_test.dart --reporter expanded antes/depois no pacote sync; loop de dart format/analyze/test nos sete pacotes, retomado de sync após ajuste de formato; dart --packages=.dart_tool/package_config.json plan/evidence/r30/measure_outbox.dart antes/depois; python3 plan/evidence/r30/capture.py --dart dart --prepare-only --test-consumers; extrator API da R-30 contra a árvore atual. Logs, contagens e amostras reais em r31-validation.json; comandos completos abaixo.
Critérios: C1 demonstrado pelo percurso único e regressão estrutural que falhou no código antigo; C2 pelas seis regressões, suíte de contrato/ACK e inventário público idêntico; C3 por 249 testes dos sete pacotes e 14 checks em cada consumidor, incluindo SQLite reaberto, oito tipos, falhas, concorrência e ACK parcial/perdido; C4 pelo mesmo medidor/cargas R-30 antes/depois no mesmo host, com limites explícitos.
Manutenção: quatro critérios marcados, índice/fase/decisão/risco atualizados e evidência ligada; R-32/R-33/R-39 prontas, próxima recomendada R-39 pela ordem da fase. Nenhuma iniciada; gate VAL-17 e fase 6 continuam abertos.
Limitações: Dart 3.13.5/Linux x86_64 e SQLite FFI; sem SDK 3.12.x, novo runtime Android ou medição de heap. Tempos medem helper sem construção das entradas, I/O de storage ou rede; não certificam latência universal. Sem mudança de API/formatos/versões, publicação, commit ou próxima tarefa executada.

### Leitura e implementação

As cinco skills foram lidas integralmente e aplicadas por um agente em etapas
distintas. A causa era o loop de mergeOutbox: cada entrada reconstruía o prefixo
completo por Delta.merge. A correção fica em
[replica_persistence.dart](../packages/deltasync_sync/lib/src/sync/replica_persistence.dart),
sem duplicar comparação JSON, mexer em estado/join ou expor outro contrato.

A implementação percorre entries.expand uma vez, materializa o lote isolado e
consolida IDs por uma Delta.merge. Ordem de primeira aparição e substituição
pela última duplicata equivalente seguem o Map do core. Deltas cumulativos com
IDs distintos permanecem no lote; não foi implementado GC ou agregação de ACK.
O snapshot e a outbox continuam nos mesmos contratos; seleção por peer e
markSent permanecem em OutboundSync, e rede continua fora da fila de commits.

### Regressão antes da correção

[outbox_merge_test.dart](../packages/deltasync_sync/test/outbox_merge_test.dart)
foi executado com o código antigo. Cinco casos funcionais passaram e a prova de
crescimento falhou: para 64 entradas, observadas 4160 leituras de ID, acima do
limite 3168 correspondente a três vezes o caso de 32 entradas. Não foi usado
limiar de tempo. Após a correção, observadas 64 leituras para 32 entradas e
128 para 64; leitura de cada entrada ocorre uma vez.

Os seis casos cobrem lote vazio; iterable de consumo único com oito tipos e
duas mudanças cumulativas do mesmo counter; duplicata equivalente entre peers
com ordem JSON diferente; conflito aninhado entre peers sem mutação da entrada;
crescimento estrutural; e falha de preparação que não marca enviado, não envia
nem remove o commit/outbox existentes. O wrapper contador pertence somente ao
teste interno, sem alterar o codec ou ser oferecido como padrão de consumidor.

### Review e correções

Review após implementação verificou diff de produção e arquivo de teste novo,
incluindo impacto em consumidor/mantenedor. Nenhuma API pública mudou; o
inventário AST dos sete entry points coincide semanticamente com api_1_0_0.json.
Dados e fontes de fixture R-30 não foram regenerados. Foram mantidas as mesmas
regras profundas de comparação, incluindo ordem de listas e equivalência de mapas.

Depois de remover um null assertion no helper de falha do teste, o gate de
formato detectou uma linha em branco pendente. A tarefa voltou a implementação;
o arquivo foi formatado, o delta revisado e a validação retomada do pacote sync.
Raiz/core já estavam aprovados e não foram repetidos por alteração apenas de
formato no teste. A seleção de peer do teste de conflito foi revisada antes da
rodada final. Changelog registra a correção sem antecipar a renumeração R-36.

### Validação e comparação

Evidência: [r31-validation.json](evidence/r31-validation.json), com logs do
vermelho/verde, execuções dos pacotes, consumers e amostras brutas antes/depois.
Ambiente: Dart 3.13.5 stable, Linux x86_64; comandos usam `dart` pelo PATH.

Primeira rodada, na raiz:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done > /tmp/deltasync-r31-workspace.log 2>&1
```

Raiz: 13 testes; core: 122. Formato do teste novo interrompeu a rodada ao entrar
em sync. Após a correção e revisão do delta, retomada real:

```sh
for package in packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done > /tmp/deltasync-r31-workspace-resumed.log 2>&1
```

Sync 57, storage 12, SQLite 27, testing 8 e transport 10 testes aprovados;
total **249 testes**, com formato e análise sem issues nos sete pacotes.
Suítes existentes cobrem ACK parcial, timeout/perda de ACK, retry, edição durante
envio, falha transacional local/remota, três histórias duráveis geradas e
restauração dos oito CRDTs antes de entrega SQLite. Testes novos cobrem falha
antes de markSent; testes de storage garantem retenção/rollback no backend real.

Consumidores e dados congelados:

```sh
python3 plan/evidence/r30/capture.py --dart dart --prepare-only --test-consumers > /tmp/deltasync-r31-consumers.json
dart --packages=.dart_tool/package_config.json plan/evidence/r30/api_inventory.dart /projetos/tcc/deltasync > /tmp/deltasync-r31-api.json
```

**14 checks por árvore**, histórica e atual, aprovados. Mantidas origem dos
imports, snapshot/outbox/IDs, tentativas, readers legados, reabertura SQLite,
escrita posterior e ACK parcial por peer. Esses são os mesmos cenários em duas
árvores, não 28 cenários distintos. Superfícies públicas coincidem com a baseline.

O medidor R-30 foi executado antes de editar produção e depois da correção,
sem mudar seu código ou o JSON histórico. Duas rodadas de aquecimento e cinco
amostras por carga, oito tipos e dois peers, usando:

```sh
dart --packages=.dart_tool/package_config.json plan/evidence/r30/measure_outbox.dart
```

| Entradas | Mediana antes (µs) | Mediana depois (µs) | Razão observada |
|---|---:|---:|---:|
| 32 | 1990 | 1818 | 1,09 |
| 128 | 3931 | 3512 | 1,12 |
| 512 | 17946 | 5954 | 3,01 |
| 1024 | 58646 | 8834 | 6,64 |

Razão é mediana anterior dividida pela posterior, específica destas execuções.
Ganhos pequenos nas menores cargas não sustentam promessa. A prova estrutural
é o percurso e o crescimento das leituras de ID; tempos incluem validação/cópia
do payload de cada entry, mas excluem sua construção inicial, SQLite e rede.
Heap não medido; nenhuma conclusão de redução de memória foi anunciada.

### Manutenção

R-31 concluída com os quatro critérios demonstrados; DEC-59 e RISK-37 registram
implementação/limites. R-32/R-33/R-39 prontas e nenhuma ativa. Próxima recomendada
R-39 pela sequência autorizada da fase. Não iniciada; esta autorização executa
uma tarefa. Após manutenção, `python3 scripts/check_plan.py` aprovou 70 tarefas
e 402 links locais; `git diff --check` passou. Artefatos novos também tiveram
JSON, whitespace e hashes de fonte/teste conferidos.

<a id="execucao-r-39-2026-10-24"></a>

## Execução R-39 — Remoção de APIs legadas com migração, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em 97f8f45, R-30/R-31 concluídas e R-39 pronta/recomendada. Lidos AGENTS, RUNBOOK, cinco skills completas, fase, baseline/mapa R-30, DEC-55 a DEC-59, RISK-26/38 e trechos de SDK, contratos e null safety do guia Dart. Confirmados consumidores públicos, readers e ramos legados antes de editar.
Implementação: removidos PendingDeltaStore/MemoryPendingDeltaStore, parâmetro/campo store e ramificações de persistência/envio; storage obrigatório e não nullable nos dois construtores da engine. Removidos aliases set/remove de Replica/SyncEngine, Delta.crdt/crdtChanges e OutboxEntry.operationId. Retirados Operation/migrateLegacyOperation dos exports; DTO/parser e readers continuam. Migrados sete testes de sync; testes do reader no próprio core usam seu arquivo interno explicitamente. Acrescentados guia, changelogs e provas isoladas de migração/rollback, sem classe ou dependência nova em produção.
Review: aprovado
Achados: revisão do próprio agente, não independente. Corrigida fixture de restauração com dono da outbox errado; documentado entryId após retirar operationId; mantidas regressões de envio sem ACK/falha e descarte. A prova negativa passou a exigir diagnósticos do analyzer por linha porque o compilador parava antes de todas as mensagens; comparação de inventário separa mudanças documentais exatas das assinaturas. Review repetido após correções/formatação, incluindo arquivos novos. Nenhum impeditivo restante.
Validação: aprovada
Comandos: loop de dart format/analyze/test dos sete pacotes e python3 plan/evidence/r39/validate.py --dart dart --report /tmp/deltasync-r39-consumers.json, executados da raiz; comandos completos e subprocessos nos artefatos abaixo. 249 testes do workspace, 14 checks históricos e 15 migrados aprovados; falha esperada de compilação do consumidor antigo na árvore atual e 12 probes negativos de API. Inventário dos sete exports restringe diferenças às previstas. SQLite executado em três processos, antigo/atual/antigo, sobre o mesmo banco.
Critérios: C1 demonstrado por diff, inventário externo e rejeição estática das APIs removidas; C2 pelos dados congelados R-30 intactos, readers legados, oito tipos e recuperação SQLite; C3 por guia de fonte/dados/rollback, exemplo do guia compilado/testado, contratos implementados externamente, suíte de storage e rollback com escritas novas/ACK parcial. Nenhum join, versão de formato, schema ou manifesto alterado.
Manutenção: três critérios marcados, índice/fase/trace atualizados, DEC-60 e RISK-26/38 revisados. R-38/R-42 liberadas; R-32/R-33 seguem prontas. Nenhuma ativa, próxima recomendada R-32; fase 6/VAL-17 continuam abertos.
Limitações: Dart 3.13.5 stable/Linux x86_64, SQLite FFI e dependências por path no consumidor isolado. Sem SDK 3.12.x, Android novo, publicação hosted ou compilação de Compass; SDK mínimo fica em R-33/VAL-17. Rollback cobre apenas a revisão 1.0.0 fixada e mudanças de R-39, sem prometer versões anteriores ou APIs futuras. MemoryStorage não comprova durabilidade. Sem commit/publicação ou início de outra tarefa.

### Leitura e implementação

[workspace.json](evidence/r39/workspace.json) registra revisão inicial, hashes de
fontes/testes/guia/ferramentas, review e testes. Todos os arquivos R-30 permanecem
intactos. A remoção elimina o segundo contrato de persistência e a escolha
inválida de nenhum/dois stores. Storage obrigatório expressa a invariante no tipo,
sem enum, wrapper, plugin ou camada nova. withStorage usa o mesmo construtor.

Estado, mutação, delta e join continuam no core; candidata, commit, adoção e
restauração no sync; atomicidade no backend; seleção por peer/tentativas no
outbound. Rede fica fora da fila de commits. Operation e seu conversor permanecem
em src/operation.dart, fora dos exports públicos, usados pelos readers de delta
e snapshot. ReplicaSnapshot.legacy e OutboxStatus.confirmed foram mantidos por
compatibilidade de dados/adaptadores; nenhum join ou formato mudou.

O [guia](../docs/migracao-1.0.1.md) mapeia remoções/substitutos, pontos de
manutenção, importação e rollback. O exemplo de importação exige checkpoint
completo e peer explícito: pendências não recuperam estado já confirmado. A prova
extrai esse exemplo do Markdown, compila e testa commit falho, dono incorreto,
destino ocupado, importação correta e ACK parcial. Não impõe importador ao core.

### Review e correções

Primeira rodada de sync: 56 testes passaram e uma fixture migrada falhou.
Enfileirava uma mudança de source e restaurava device-a; o storage suportado
separa por origem. Corrigidos dono/destino da fixture, a regressão focada passou.
Diff revisto após correções; rodada completa posterior aprovada. Log inicial e
final permanecem em workspace.json. Envio sem ACK, falha de envio, restauração
antes do uso e descarte continuam testados no caminho suportado.

A primeira prova negativa exigia todas as mensagens do compilador; ele parou
nas primeiras. Corrigida para incluir 12 linhas independentes com diagnósticos
machine do analyzer. A comparação AST inicial também sinalizou comentários de
retry/pending/entryId. O comparador agora verifica exatamente essas três mudanças
documentais, separadas das assinaturas, sem alterar a baseline. Fixtures e
comparador foram revistos após correção e reexecutados com sucesso.

### Validação

Na raiz, comando completo dos sete pacotes:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done > /tmp/deltasync-r39-workspace.log 2>&1
python3 plan/evidence/r39/validate.py --dart dart --report /tmp/deltasync-r39-consumers.json
```

Resultado do workspace: **249 testes**, respectivamente 13/122/57/12/27/8/10;
sete análises sem issues e sete gates de formato sem mudanças. Inclui oito tipos,
falhas transacionais, rollback, ACK parcial/perdido, retries, edição concorrente,
contextos causais e recuperação SQLite. Logs completos estão em workspace.json.

[validation.json](evidence/r39/validation.json) conserva comandos, diretórios,
resolução offline própria, SDK, logs, diferenças de API e hashes de R-30.
Consumidor antigo: **14 checks** na revisão histórica. O
[migrado](evidence/r39/consumer_test.dart.txt): **15 checks**, análise limpa e
origem dos imports conferida, em projeto fora do workspace. São cenários
correspondentes e um adicional, não 29 cenários inteiramente distintos. Os
consumers implementam contratos por composição, sem imports de src.

Consumidor antigo falha na árvore atual por APIs removidas, como esperado.
Doze probes também falham com erros nas linhas esperadas; isso é prova de remoção,
não reprovação do gate. Inventário dos sete entry points não encontrou mudanças
fora das remoções/assinaturas previstas e dos ajustes documentais conferidos.
Contratos de adaptadores/transporte e suíte de storage permaneceram iguais.

O [programa de rollback](evidence/r39/rollback.dart.txt) rodou em três processos:
1.0.0 gravou SQLite; atual reabriu, escreveu LWW/counter e recebeu ACK de três
IDs; 1.0.0 reabriu e verificou novas escritas, 45 pendências e 23 entradas do
outro peer com payload/metadados preservados. Consumer migrado também reabre
SQLite após novos commits/ACK. Prova vale para essa referência e FFI/Linux,
sem extrapolar a Android ou readers anteriores à revisão fixada.

### Manutenção

R-39 concluída com três critérios demonstrados; R-38/R-42 prontas por dependência.
R-32 recomendada conforme sequência vigente; nenhuma próxima tarefa iniciada.
DEC-60 registra internalização dos leitores e limite do rollback; RISK-26/38
distinguem remoções verificadas do restante da release. Numeração intacta até
R-36; gate integral continua VAL-17. Após manutenção,
`python3 scripts/check_plan.py` aprovou 70 tarefas e 416 links locais;
`git diff --check` passou. JSON, hashes e whitespace dos artefatos novos também
foram conferidos.

<a id="execucao-r-32-2026-10-24"></a>

## Execução R-32 — Custos de mutação, restauração e pendências, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em 2e1b9f5a97cb99b50c6ec770b2b12c19914afab6; R-31 e R-39 concluídas, R-32 pronta/recomendada. Lidos AGENTS/RUNBOOK, cinco skills completas, fase, instrumentos existentes, DEC-58/59/60, RISK-25/37 e guia Dart (SDK, simplicidade, records, contratos). Conferidos fork/adopt, snapshots, replay e preparação real com os limites core/sync/storage.
Implementação: estendido example/measure_crdt_cost.dart com --paths, preservando modo anterior e reutilizando factories, transporte controlado e helpers existentes. Cargas independentes de campos, valores e pendências, oito tipos, dois peers e statuses pending/sent; MemoryStorage e SQLite FFI. Acrescentados medição de 12 percursos, verificações runtime, bytes JSON separados, RSS de processo e arquivos fechados SQLite. Nenhuma fonte de produção, API, dependência, manifesto ou formato mudou.
Review: aprovado
Achados: revisão do próprio agente, não independente. Corrigidos dois avisos de estilo e comparação de valores que dependia da ordem de mapas/sets; listas preservam ordem. Conferidas exclusão de setup/checks dos cronômetros, HLC monotônico na restauração, scopes global/peer distintos e limites de RSS/JSON/SQLite. Explicados overwrite do mesmo valor, caches/JIT, etapas isoladas e ausência de rede no preparo. Review repetido após correções e nos artefatos/documentação; nenhum impeditivo restante.
Validação: aprovada
Comandos: dart run example/measure_crdt_cost.dart --paths > /tmp/deltasync-r32-paths.json 2> /tmp/deltasync-r32-paths.err; dart format --output=none --set-exit-if-changed example/measure_crdt_cost.dart lib test && dart analyze && dart test --reporter expanded; dart run example/measure_crdt_cost.dart > /tmp/deltasync-r32-legacy.log 2>&1, todos da raiz. JSON conferido por Python para contagens, medianas, métricas, equivalência entre backends e tamanhos; hashes/outputs preservados nos artefatos.
Critérios: C1 pelas sete configurações por backend e 12 métricas, incluindo mutação, snapshot, restauração/outbox, preparo e consultas repetidas; C2 pela equivalência de estado/IDs/metadados, projeções separadas e fechamento/reabertura SQLite, sem confundir memória/arquivo; C3 por seed, ambiente, dois aquecimentos e cinco amostras por carga, RSS identificado como processo e ausência explícita de heap/alocações; C4 por gargalos/encaminhamentos no README da evidência e DEC-61: R-37 antes da release, novas otimizações de replay/cópias/SQL para avaliação posterior, sem relaxar isolamento ou retirar requisitos da fase.
Manutenção: quatro critérios marcados, índice/fase/trace atualizados; DEC-61, RISK-37 e novo RISK-43 registram custos e decisão. R-37 liberada por R-32/R-39 e próxima recomendada; R-33/R-38/R-42 seguem prontas. Nenhuma ativa, nenhuma próxima iniciada; fase 6 e VAL-17 continuam abertos.
Limitações: Dart 3.13.5 stable/Linux x86_64, SQLite FFI e payload ASCII compartilhado por carga. Sem SDK 3.12.x, novo Android, rede real, profiling de heap/alocações ou SLA universal. Timings não são monotônicos em todas as cargas; JIT/GC/caches e ordem fixa permanecem. RSS não mede alocação por operação; bytes SQLite pós-escrita não são JSON pré-operação ou espaço recuperável. Sem mudança de lib, Compass, commit ou publicação.

### Implementação e revisão após correções

O [medidor](../example/measure_crdt_cost.dart) ganhou um modo de análise, sem
alterar APIs ou introduzir camadas em produção. Records privados descrevem
cargas; o preparo chama OutboundSync.prepare real. Modelos, regras de negócio e
adaptação do app continuam no consumidor; estes imports internos são instrumentos,
não um mecanismo de extensão sugerido aos aplicativos.

Primeira análise encontrou dois infos de chaves em fluxo, corrigidos. A primeira
execução de --paths saiu com 255 em `restored values`: snapshot equivalente, mas
ordem do mapa de valores mudou na restauração. Corrigida a normalização de
Map/Set, mantendo ordem de List, o instrumento passou. HLC pode avançar no replay;
a prova exige monotonicidade e preserva comparação dos demais metadados. Nenhum
achado exigiu mudar a biblioteca. Correções e limites dos cronômetros foram
revistos antes da execução final; review não independente.

### Validação e resultados

[Método/resultados](evidence/r32/README.md) detalha comandos, parâmetros,
escopos, tabelas e encaminhamentos. [Amostras](evidence/r32/measurements.json)
registram 14 cargas, 28 aquecimentos e 70 amostras medidas. Cada execução verifica
fork/adopt, snapshot, valores, IDs/clocks/contextos, outbox, seleção/ordem por peer,
tentativas e commit final. Seed 20261024 e relógio fixo; 16/64/256 campos,
64/256/1024 B ASCII e 16/64/256 pendências, variando um parâmetro por eixo.

O JSON foi conferido separadamente: sete configurações com os dois backends,
cinco amostras e 12 métricas por carga, oito tipos, todas as verificações
aprovadas, medianas recalculadas e tamanhos/contagens de fixture iguais entre
MemoryStorage/SQLite. Main/WAL/SHM foram registrados após fechar cada SQLite;
todo main existia com tamanho positivo. RSS e máximo são do processo inteiro,
incluindo runtime/SQLite; não contam heap, alocações ou cópias por operação.

[validation.json](evidence/r32/validation.json) guarda revisão base, hashes do
instrumento/dados/lock, falha inicial, execução final e modo anterior. Este último
manteve quatro cargas MV com ACK esvaziando pendências, 253 itens no estado grande
e 17 eventos retidos OR-Set. Seus tempos não foram comparados aos do modo novo.
[Checks da raiz](evidence/r32/root-checks.json): formato sem mudanças, análise
sem issues e **13 testes da facade** aprovados. Não reapresentar 249 testes de
R-39 como execução desta tarefa; nenhuma fonte em lib/packages foi modificada.

Com 256 entradas, cinco contagens pela engine levaram 5110 µs em memória e
28681 µs no SQLite; start com outbox, 153115/168325 µs. Preparar 128 entradas do
peer levou 1610/28568 µs. Código confirma payloads materializados para contagem,
replay por entrada com fork/adopt e markSent com consulta/escrita por ID.
As etapas e escopos diferem: não somar cronômetros nem atribuir toda diferença
ao SQL. SQLite fechado de pending-256 tinha 233472 B, versus 106950 B de outbox
JSON inicial; não são o mesmo objeto/instante nem medida de espaço recuperável.

R-37 segue antes da release. Novas otimizações de replay/cópias/SQL ficam para
avaliação posterior por DEC-61; não foi demonstrado defeito de dados ou definido
SLA que imponha outra refatoração agora. Orçamento de consumidor mais estrito
exige reavaliar essa decisão. Consulta pontual de string não mostrou crescimento
consistente com campos/backlog; isso não se estende a coleções/modelos arbitrários.

### Manutenção

R-32 concluída com critérios demonstrados; R-37 pronta e recomendada, sem iniciar
outra implementação. Registro de performance preserva garantias e todo o escopo
de 1.0.1. Após manutenção, `python3 scripts/check_plan.py` aprovou 70 tarefas e
431 links locais; `git diff --check` passou. JSON, hashes e whitespace dos
artefatos novos foram conferidos.

<a id="execucao-r-37-2026-10-24"></a>

## Execução R-37 — Resumo público de pendências, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em f2edf0f4da878dd785c1240536b4537aa081e9d4; R-32/R-39 concluídas e R-37 pronta/recomendada. Lidos AGENTS/RUNBOOK, cinco skills completas, fase, DEC-61, riscos, contrato/storage/sync e guia Dart sobre contratos, null safety e records. Confirmado custo de materialização nas evidências R-32 e status dentro do payload SQLite schema v1.
Implementação: pendingSummary obrigatório em ReplicaStorage, referências MemoryStorage/SQLite e consulta enfileirada pela SyncEngine/facade. OutboxSummary contém pendingCount/sentCount e total derivado, sem cache. SQLite agrega status, com fallback restrito à ausência da função JSON; nenhuma mudança de schema/formato. Suíte pública de contrato ampliada; regressões de storage, sync, SQLite e facade; migração, changelogs, consumidor externo e medidor estendido com duas consultas adicionais.
Review: aprovado
Achados: revisão do próprio agente, não independente. Primeira análise/compilação SQLite detectou getResultCode ausente no helper DatabaseException; implementado e revisto. Corrigidos infos/formatação. Conferidos escopo global por peer/ID, confirmed excluído, ausência de payload no caminho otimizado, limites do fallback, propagação de erro e fila sem bloqueio por rede. Review repetido após correções, incluindo arquivos novos e documentos; nenhum impeditivo restante.
Validação: aprovada
Comandos: loop de dart format/analyze/test dos sete pacotes; python3 -B plan/evidence/r37/validate_consumer.py --dart dart --report /tmp/deltasync-r37-consumer-smoke.json; dart run example/measure_crdt_cost.dart --paths > /tmp/deltasync-r37-paths.json 2> /tmp/deltasync-r37-paths.err. Execuções da raiz, comandos/logs completos nos artefatos. Benchmark sem suítes Dart paralelas disparadas pelo agente.
Critérios: C1 demonstrado pela API sem cache e provas estruturais de ausência de decodificação de deltas, com 14 cargas/70 amostras equivalentes; C2 pelo membro obrigatório mínimo, implementações de referência, suíte de contrato, guia e adaptador externo antigo rejeitado/migrado aprovado; C3 por filtros/status/ACK parcial, falha de consulta, edição durante rede, leitura concorrente com commit/rollback, lifecycle e SQLite fechado/reaberto preservando estado/outbox. 266 testes do workspace, 18 checks externos e sete inventários aprovados.
Manutenção: três critérios marcados, índice/fase/trace atualizados, DEC-62 e RISK-37 revisados. Nenhuma ativa; próxima recomendada R-38, com R-33/R-42 também prontas. Fase 6/VAL-17 seguem abertas; nenhuma próxima implementação iniciada.
Limitações: Dart 3.13.5/Linux x86_64, SQLite FFI; sem SDK 3.12.x, Android novo ou hosted artifacts. Ausência de JSON1 simulada em wrapper sobre banco real; fallback funcional, não benchmarkado. Agregação ainda processa JSON no SQLite, sem custo constante ou validação do corpo dos deltas. Heap/alocações não medidos. Sem alteração de core/joins/formatos/manifests, Compass, publicação ou commit.

### Evidências por etapa

[Contrato, migração, resultados e reprodução](evidence/r37/README.md) descrevem
o consumo público e os limites. A leitura selecionou um único membro obrigatório,
evitando capacidade opcional mais dispatch na engine. DTO valida contagens e
deriva total; o estado continua no core, commit/adoção/restauração no sync e a
outbox no backend. Resumo lê essa fonte, sem outra representação mutável.

[validation.json](evidence/r37/validation.json) contém hashes, análise/review,
falha inicial do helper e log completo do workspace: 14/122/62/14/34/10/10 testes,
total **266**, sete análises limpas e formato aprovado. Novos testes cobrem
metadata sem ler delta, empty/peer/réplica/status, ACK parcial, erros sem zero
falso, fila durante commit/rollback, rede que não bloqueia edição/consulta,
retry de inicialização e disposal. SQLite reabre após commit/envio/ACK e mantém
snapshot/contagens; agregação não transfere payloads para Dart. O fallback também
evita instanciar deltas, mas carrega JSON; erros distintos não ativam fallback.

[consumer-validation.json](evidence/r37/consumer-validation.json) registra
**18 checks** em projeto externo com resolução por path e origem conferida.
O adaptador antigo não compila por pendingSummary ausente. O
[migrado](evidence/r37/consumer_test.dart.txt) implementa o membro por delegação,
sem src/herança interna. Dados congelados dos oito tipos, readers e contrato
continuam exercitados. Sete inventários contra a revisão inicial confirmam
somente OutboxSummary e pendingSummary como adições; R-30/R-39 permanecem intactos.

[measurements.json](evidence/r37/measurements.json) reutiliza cargas R-32 com
semente/aquecimentos e mede caminhos antigos/novos na mesma execução. Em SQLite,
cinco contagens globais de 256 entradas levaram 31537 µs via pendingDelta e
3157 µs via resumo; por peer, 12977/1552 µs para 128 entradas. Cada amostra
verifica equivalência dos resultados. Em memória, a carga pequena por peer teve
40/73 µs: fila/DTO têm custo fixo e não há promessa de ganho em todo cenário.
Não extrapolar para redes, heap, outras plataformas ou fallback sem JSON1.

### Manutenção

R-37 concluída com critérios e evidências; R-38 recomendada e não iniciada.
Guia separa falha de consulta de sucesso do commit local, descreve quebra do
adaptador externo e limites de metadata/JSON. Após manutenção,
`python3 scripts/check_plan.py` aprovou 70 tarefas e 446 links locais;
`git diff --check` passou. Hashes, JSON, sintaxe do instrumento Python, whitespace
e unicidade dos IDs de risco foram conferidos. Correções finais documentais
revistas sem mudanças adicionais de código.

<a id="execucao-r-38-2026-10-24"></a>

## Execução R-38 — Lote local atômico, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em ae1eefe7321da59b9fb420d17eb233dda6903cdc; R-39 concluída e R-38 pronta/recomendada. Lidos AGENTS/RUNBOOK, cinco skills completas, fase, decisões/riscos, guia Dart (contratos, class modifiers e records) e pipeline de mutação/fork/adopt/commit. Confirmado que um editor de escopo limitado pode reutilizar candidata e commit sem expor Replica ou alterar joins.
Implementação: SyncEngine.batch retorna Delta depois de um commit/adopção; LocalBatch final de construtor privado delega aos oito CRDTs, coleta mudanças e expira no fim do callback. Erros de edição invalidam o lote mesmo capturados; vazio/Future retornado abortam. Contexto Zone impede chamadas reentrantes e continuações async rejeitadas. Adicionados testes, exemplo público, documentação/changelog e extrator canônico de APIs com suporte a parts; sem novos contratos de storage/transport ou formatos.
Review: aprovado
Achados: revisão do próprio agente, não independente. Flag síncrona inicial foi substituída por contexto Zone para impedir chamadas diretas à engine em continuações de callbacks rejeitados. Matcher SQL foi restringido ao erro do trigger para comprovar falha após escrita parcial. Após matriz completa, reforçado teste de rollback para os oito tipos simultâneos e dots/IDs de retry; delta revisto e oito testes focados aprovados. Conferidos arquivos novos, lifetime do editor, eventos, reentrância, callback void nomeado e limites de I/O externo. Nenhum impeditivo restante.
Validação: aprovada
Comandos: loop de dart format/analyze/test dos sete pacotes; dart test test/local_batch_test.dart --reporter expanded no pacote sync após reforço; python3 -B plan/evidence/r38/validate_consumer.py --dart dart --report /tmp/deltasync-r38-consumer-smoke.json; dart run example/local_batch_example.dart. Comandos completos, diretórios e logs nos artefatos. Matriz 278 testes, oito focados adicionais sem somar ao total, dois checks externos e sete inventários aprovados; exemplo confirma três mudanças/pendências.
Critérios: C1 pelo editor sem Replica, candidato/commit únicos, encerramento antes do await e teste com commit bloqueado; C2 por contrato explícito de retorno/vazio/throw/Future/reentrância e bloqueio de continuações, sem schemas/comandos de domínio; C3 por rollback dos oito tipos em memória, falha de segunda inserção em transação SQLite, preservação de snapshot/outbox/IDs, reabertura e edição concorrente; C4 por exemplo de perfil com campos relacionados e regressão de ACK parcial por mudança, com limites de transação distribuída documentados.
Manutenção: quatro critérios marcados, índice/fase/trace atualizados; DEC-63 e RISK-41 registram decisões/limites. R-41 liberada por R-37/R-38; próxima recomendada R-42 conforme sequência, com R-33 também pronta. Nenhuma ativa ou próxima implementação iniciada; fase 6/VAL-17 continuam abertos.
Limitações: Dart 3.13.5/Linux x86_64, SQLite FFI; sem runtime SDK 3.12.x, Android novo, kill de processo ou rede física. ACK controlado não prova persistência remota. Contrato proíbe I/O/trabalho async separado e chamadas fora do editor no callback; biblioteca não desfaz efeitos externos do app. Consumidor externo usa path, não hosted. Sem alteração de core/joins, contratos de adaptadores, JSON/schema/versões, Compass, commit ou publicação.

### Leitura, implementação e review

O [contrato e reprodução](evidence/r38/README.md) aponta código, guia e logs.
LocalBatch justifica uma classe pelo lifetime/estado de falha do recurso; não é
outro modelo de estado. Usa part na library de SyncEngine para compartilhar
construtor/encerramento privados. final impede construção/implementação forjada
por consumidor; métodos delegam validações/joins ao core e não criam regras
paralelas. _record controla falha/coleta; _close libera a candidata. A engine
continua usando _commitLocalResult, fila e commit local existentes.

Review examinou código e testes novos, incluindo exceções capturadas e editor
guardado para depois. A primeira flag protegia apenas o callback em execução;
Zone foi adotado para que uma continuação async rejeitada também não possa
chamar a engine diretamente. Teste específico aprovou rejeição sem erro órfão
nem commit. Documentação explicita que efeitos externos iniciados pelo app não
são transacionais. O exemplo usa dados preparados antes do callback.

O [extrator atual](../scripts/api_inventory.dart) acrescenta parts ao algoritmo
de inventário sem alterar a ferramenta congelada R-30. Contra as fontes da
revisão inicial, seus sete inventários coincidem com os do extrator histórico;
contra a árvore nova identifica somente LocalBatch e SyncEngine.batch como
adições. Isso evita omitir API pública definida em part na manutenção seguinte.

### Validação

[validation.json](evidence/r38/validation.json) guarda hashes de código/testes/
instrumentos, lock/versão do analyzer e logs da execução. Comando da matriz:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done > /tmp/deltasync-r38-workspace.log 2>&1
```

Resultado: **278 testes**, respectivamente 15/122/70/14/37/10/10, com formato e
sete análises limpas. Depois, só o teste de rollback em memória foi fortalecido
para oito tipos simultâneos: arquivo formatado, delta revisto, análise e oito
testes de lote aprovados. Checks não afetados da matriz foram preservados;
produção não mudou após a matriz. Não somar essas repetições ao total.

Cobertura específica: 22 mutações dos oito tipos com um commit/evento; valores
isolados; callback vazio, inválido/capturado, throw e Future; editor fechado antes
de await; engine reentrante e continuação rejeitada; commit falho preservando
snapshot/IDs e retry com dots iniciais; edição concorrente na fila; rede falha e
ACK parcial. SQLite injeta trigger no segundo INSERT, após snapshot/primeiro
INSERT, verifica erro exato e reabre sem estado/outbox parcial. Outro lote dos
oito tipos reabre intacto e ACK de uma mudança deixa sete entradas sent.

[consumer-validation.json](evidence/r38/consumer-validation.json) registra dois
testes externos por facade com callback nomeado void, três campos e rollback de
validação do app. Compilação negativa rejeita construtor e implementação forjada
do editor. Os sete inventários e a equivalência do extrator antigo também passam.
O [exemplo](../example/local_batch_example.dart) verifica três mudanças e três
pendências após commit; não envia dados nem sugere ACK automático.

### Manutenção

R-38 concluída, R-41 pronta por dependência e R-42 recomendada sem iniciar outra
tarefa. DEC-63/RISK-41 distinguem escopo local, side effects externos e ACK por
mudança. Gate integral continua VAL-17. Após manutenção,
`python3 scripts/check_plan.py` aprovou 70 tarefas e 463 links locais;
`git diff --check` passou. Hashes, JSON, sintaxe Python, whitespace e unicidade
dos IDs foram conferidos. Revisão documental final sem achados impeditivos.

<a id="execucao-r-42-2026-10-24"></a>

## Execução R-42 — Consulta explícita de campo, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em 754c763d5a90bdc95b10cc55fcf36b929890b47b; R-39 concluída, R-42 pronta e recomendada. Lidos AGENTS/RUNBOOK, cinco skills completas, critérios da fase, decisões/riscos pertinentes e guia Dart sobre enums, null safety, sealed/final e library/part. Conferidos dono canônico, consultas dos oito tipos, pipeline de commit/adoção, lifecycle e lifetime do editor. Escopo limitado a R-42, sem antecipar R-40 ou adaptar Compass.
Implementação: Replica.query, SyncEngine.query e LocalBatch.query retornam FieldQuery sealed com AbsentField, PresentField(kind/value) e DeletedField para tombstone LWW. Outros sete tipos vinculados são presentes com zero/coleção vazia. ReplicaState.isDeletedAt inspeciona metadados sem copiar payload; valor compartilha percurso com valueAt, que preserva semântica anterior. Resultados isolados/read-only, variantes final e construtores privados na library de Replica via part. Adicionados testes, exemplo, guia, READMEs/changelogs e prova de consumidor/inventários; nenhum schema, join ou contrato de adaptador mudou.
Review: aprovado
Achados: revisão do próprio agente, não independente. Evitada cópia de vencedor/valor LWW apenas para consultar tombstone por accessor canônico. Corrigidos fixture que tentava alterar snapshot imutável, getter inexistente label no exemplo e comparação de inventário que incluía Dartdoc no offset do AST. Após correções, revistos código, testes, novos arquivos e instrumento; preservados semântica de valueAt, lifecycle, isolamento e compatibilidade de dados. Nenhum impeditivo restante.
Validação: aprovada
Comandos: loop completo de dart format/analyze/test nos sete pacotes; python3 -B plan/evidence/r42/validate_consumer.py --dart dart --report /tmp/deltasync-r42-consumer.json; dart run example/field_query_example.dart. Matriz: 291 testes, respectivamente 16/128/73/14/40/10/10, sete formatos sem alterações e sete análises limpas. Dois testes externos, compilação negativa e sete inventários aprovados. Comandos completos, diretórios, saídas, falhas corrigidas e hashes nos artefatos; focados repetidos não somam ao total.
Critérios: C1 por três variantes fechadas, oito tipos, sete tipos vinculados vazios/zero, MV {null} e coleções aninhadas imutáveis; C2 por kindAt/isDeletedAt canônicos, percurso pontual sem fork/snapshot/state e tombstone preservado após outbox esvaziada; C3 por valueAt inalterado, exemplo e guia indicando decoder somente no ramo presente inclusive null, sem implementar R-40; C4 por ordens concorrentes/replay LWW, consulta durante commit bloqueado, candidata no editor, falha de commit, lifecycle, facade e três testes SQLite de reabertura/rollback.
Manutenção: quatro critérios marcados, índice/fase/trace atualizados; DEC-64 e RISK-41 registram contrato e limites. R-40 liberada e recomendada; R-33/R-41 também prontas. Nenhuma tarefa ativa ou próxima implementação iniciada; fase 6/VAL-17 permanecem abertos. Conferência estrutural e diff executados após manutenção.
Limitações: Dart 3.13.5/Linux x86_64 e SQLite FFI; sem runtime SDK 3.12.x, Android novo, kill de processo ou rede física. ACK controlado não prova persistência remota; consumidor externo usa path, não hosted. Query não valida modelos do app; conveniência de decoder permanece em R-40. Sem mudanças de formatos, SDK, versões, Compass, commit ou publicação. Variantes são fechadas; futura expansão exige migrar switches e subclasses externas devem conferir conflito com método próprio chamado query.

### Evidências e recuperação

O [contrato e reprodução](evidence/r42/README.md) liga APIs, testes e caminhos de
manutenção. [validation.json](evidence/r42/validation.json) contém logs e hashes
de produção, testes, exemplo, guia e instrumentos. A falha inicial da fixture
permanece registrada: toSnapshotJson é imutável; Map.of cria o mapa externo para
preenchê-lo com snapshots públicos dos sete CRDTs. O exemplo passou após usar
CrdtKind.wireName. O comparador aceita Dartdoc no prefixo da assinatura sem
relaxar a lista de símbolos/membros esperados; extrator canônico não mudou.

Core verifica ausência/null/remoção/ressurreição, tipos vazios e preenchidos,
isolamento profundo e estabilidade; duas ordens de chegada de eventos LWW
concorrentes e replay antigo preservam o vencedor. Guarda de teste numa réplica
de 500 campos rejeita acesso aos caminhos públicos de cópia completa. Consulta
usa somente metadados/valor do endereço e mantém snapshot/clocks intactos.
Sync confronta candidata visível no editor com estado adotado enquanto commit
aguarda, rejeita editor fechado e mantém estado anterior após falha. Consultas
antes/durante start, após falha de carga e após dispose respeitam lifecycle.

SQLite fecha e reabre banco real com os oito tipos, ausência, null, tombstone,
sete tipos vazios/zero e coleções aninhadas. Um trigger aborta inserção da outbox
depois da tentativa de snapshot; erro exato é exigido. Engine/banco mantêm
snapshot/outbox/null anteriores; reabertura preserva null, retry remove e outra
reabertura mantém tombstone. ACK controlado esvazia pendências sem apagar estado.
MemoryStorage é evidência complementar volátil, não prova durável.

O [consumidor externo](evidence/r42/consumer_test.dart.txt) compila switch
exaustivo pela facade e consulta engine/editor sem importar internos. Dois testes
aprovados; compilação negativa rejeita construtor e implementações de resultados
sealed/final. [consumer-validation.json](evidence/r42/consumer-validation.json)
confirma sete inventários contra HEAD inicial: quatro tipos adicionados no
core/facade, query em Replica/SyncEngine/LocalBatch e isDeletedAt em ReplicaState.
Nenhuma assinatura antiga removida/modificada, nem mudança em storage/transport.
Evidências congeladas R-30 a R-38 permanecem intactas.

### Manutenção

R-42 concluída; próxima recomendada R-40 sem iniciá-la. Leitura/commit/ACK
continuam separados; aplicação mantém modelos e conversões. O
[guia de migração](../docs/migracao-1.0.1.md#consulta-explícita-de-campo--r-42)
documenta os três casos, coleções vazias, decoder futuro, classes fechadas e
pontos únicos de manutenção. Gate da release continua VAL-17.

Após manutenção, `python3 scripts/check_plan.py` aprovou 70 tarefas e 478 links
locais; `git diff --check` passou. Conferidos 20 hashes, lock inalterado, dois
relatórios JSON, sintaxe Python, whitespace dos arquivos novos, IDs únicos e
âncora da execução. Evidências anteriores preservadas. Revisão documental final
sem achados impeditivos; nenhum código mudou após a matriz aprovada.

<a id="execucao-r-40-2026-10-24"></a>

## Execução R-40 — Decoder opcional, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em 0e17a2a964b7adb8fcb0974dd6301e1168cfcc8d; R-42 concluída e R-40 pronta/recomendada. Lidos AGENTS/RUNBOOK, cinco skills completas, critérios da fase, DEC-64/RISK-40/41 e guia Dart sobre null safety, padrões, class modifiers/extensions e SDK. Conferidos FieldQuery, valor isolado, ciclo de query/start/dispose e editor. Selecionada conveniência no resultado presente para reutilizar percurso canônico e manter os ramos de ausência/remoção.
Implementação: PresentField.decode<T> invoca T Function(Object?) uma vez sobre value já isolado, inclusive null, retorna T e propaga erro sem wrapping/default. Valor bruto permanece disponível; ausente/removido não oferecem decode. Mesmo resultado atende Replica/SyncEngine/LocalBatch sem novos métodos de engine, tipos, variantes, schema ou cache. Adicionados testes core/sync/facade, modelo/exemplo público, guia/READMEs/changelogs e fixture externa/inventários. Modelos e validação continuam no consumidor.
Review: aprovado
Achados: revisão do próprio agente, não independente, incluindo arquivos novos e instrumento. Corrigidos lint de bloco if no modelo de teste e expectativa externa de quatro pendências para três mutações locais; falha preservada e fixture corrigida sem mudar produto. Guia complementado com precedência de membro de instância sobre extension decode do consumidor. Após correções, revistos deltas, comportamento de null/erro, mutabilidade de saída, lifecycle e rollback do lote; nenhum impeditivo restante.
Validação: aprovada
Comandos: loop de dart format/analyze/test em raiz, packages/deltasync_core e packages/deltasync_sync; python3 -B plan/evidence/r40/validate_consumer.py --dart dart --report /tmp/deltasync-r40-consumer.json; dart run example/field_decoder_example.dart. 225 testes, respectivamente 17/132/76, três formatos sem mudanças e três análises limpas. Dois testes externos e análise aprovados; prova negativa rejeita decode em ausente/removido. Sete inventários confirmam somente PresentField.decode como adição em core/facade. Comandos completos, saídas, falha corrigida, ambiente e hashes nos artefatos; focados repetidos não somam ao total.
Critérios: C1 pelo membro opcional no resultado existente, T Function(Object?) para T, valor bruto preservado e modelo/schema no app; C2 por ramos explícitos de ausência/remoção, null passado ao decoder, retorno nullable e exceção original propagada; C3 por oito tipos, tentativa de mutação aninhada, modelo mutável de saída e snapshots/clocks/outbox intactos em sucesso/falha, sem eventos de commit/erro da engine; C4 por Profile válido/JSON incompatível, erro tratado no exemplo/consumidor, query antes/durante start e após dispose, resultado retido, editor e facade.
Manutenção: critérios marcados, índice/fase/trace atualizados; DEC-65 e RISK-40/41 registram contrato e limites. R-41 recomendada, R-33 também pronta; nenhuma tarefa ativa ou próxima implementação iniciada. Fase 6/VAL-17 continuam abertos. Checker estrutural e diff executados após manutenção.
Limitações: Dart 3.13.5/Linux x86_64; sem SDK mínimo 3.12.x ou Android novo. Validação proporcional de core/sync/facade, não gate completo da release; sem nova prova SQLite porque persistência/formatos não mudaram e recuperação durável não é critério R-40. Consumidor externo usa path/resolução independente offline, não hosted. Callback pode capturar efeitos externos que a biblioteca não desfaz; modelo/validação/mutabilidade de saída pertencem ao app. Sem mudanças de variantes/query/valueAt, joins, commit/ACK, adaptadores, dados, SDK/versões, Compass, commit ou publicação.

### Contrato, falhas e consumo

O [contrato e reprodução](evidence/r40/README.md) apresenta os pontos únicos de
manutenção. [validation.json](evidence/r40/validation.json) contém logs reais,
hashes e correções. Preferido um membro em PresentField, tipo final já controlado
pela biblioteca: a conveniência trabalha sobre a consulta feita e seu Object?
isolado, sem estado nem despacho adicional. Isso preserva switches e permite
aplicações escolherem converter ou inspecionar o bruto em cada leitura.

Core exercita inferência de T, resultado nullable, null legítimo e ramos explícitos
de ausência/remoção sem invocar decoder. Profile valida seu próprio schema; modelo
mutável copia tags sem alterar entrada. Exceção de domínio, erro de tentativa de
mutar lista aninhada e erro arbitrário propagam; a exceção arbitrária preserva
identidade. Conversão dos oito tipos mantém snapshot/clocks e valor bruto.

Sync confere snapshot ativo/persistido e outbox intactos após sucesso/erro,
sem notificação de commit ou errors. Push falho não impede converter resultado
retido nem editar depois. Lifecycle é aplicado ao obter consulta; resultado
retido não segura engine/editor e permanece convertível após dispose/fechamento.
Decoder que falha e escapa do callback aborta a candidata do lote pelo mecanismo
existente; resultado válido lê edições provisórias. Não há tradução de erro de
modelo em sucesso de edição nem rollback de commit anterior por falha de leitura.

O [exemplo](../example/field_decoder_example.dart) mostra missing, valid, null,
deleted e invalid, captura erro de modelo e preserva JSON bruto. O
[consumidor externo](evidence/r40/consumer_test.dart.txt) usa somente facade,
modelo próprio, retorno inferido e cópia mutável; sua primeira expectativa de
contagem estava incorreta. Após correção de quatro para três, dois testes
passaram. A falha anterior permanece no relatório, sem ocultar histórico.
[consumer-validation.json](evidence/r40/consumer-validation.json) registra
compilação negativa e sete inventários com única adição esperada; nenhuma
assinatura anterior removida/modificada ou classe/variante nova. Evidências
congeladas anteriores permanecem intactas.

### Manutenção

R-40 concluída; R-41 recomendada sem iniciá-la. O
[guia de migração](../docs/migracao-1.0.1.md#decoder-opcional-no-resultado-presente--r-40)
explica entrada/retorno, modelo inválido, resultado retido, efeitos externos e
precedência do novo membro sobre extension do consumidor. DEC-65/RISK-40/41
distinguem conversão, commit e falha de sync. Gate integral permanece VAL-17.

Após manutenção, `python3 scripts/check_plan.py` aprovou 70 tarefas e 494 links
locais; `git diff --check` passou. Conferidos 14 hashes, lock/HEAD inalterados,
dois relatórios JSON, sintaxe Python, whitespace dos arquivos novos, IDs únicos e
âncora da execução. Evidências anteriores preservadas. Revisão documental final
sem achados impeditivos; produção/testes não mudaram após a matriz aprovada.

<a id="execucao-r-41-2026-10-24"></a>

## Execução R-41 — Eventos seletivos, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em bc65f4a2658b75141953477c6281c12eebf11f07; R-37/R-38 concluídas e R-41 pronta/recomendada. Lidos AGENTS/RUNBOOK, cinco skills completas, critérios da fase, DEC-63/64/65, riscos de integração/eventos e guia Dart sobre class modifiers, padrões e extensions. Inspecionados DeltaChange.crdtId, parse/join canônico de snapshot, pipelines de commit/adoção/ACK e os três controllers/listeners existentes. Escopo limitado a R-41.
Implementação: SyncCommitEvent.addresses guarda conjunto isolado/read-only de endereços processados; commitsFor filtra endereço exato. Lote deduplica, replay/perdedor pode notificar; snapshot usa bindings remotos, inclusive vazios/zero/tombstone. Replica.mergeSnapshotJson retorna Set<String> do parse existente. Um controller assíncrono de SyncObservation e _emit produzem observações; commits/errors são filtros tipados. Eventos preparados antes do I/O só são emitidos após adoção. Adicionados testes core/sync/facade, exemplo, guia, fixture/inventários e migração de construtor/implementação/retorno; variantes e formatos preservados.
Review: aprovado
Achados: revisão do próprio agente, não independente, incluindo arquivos novos e instrumento. Identificada lacuna de teste do filtro errors pausado após unificação; teste adicionado. Preparação do evento movida para antes do await, eliminando cópia intermediária de metadados remotos; emissão continua após adoção. Documentados matching exato/OR-Map, buffering de pausa e ordem por subscription. Após correções, revistos deltas e dez testes focados aprovados; nenhum impeditivo restante.
Validação: aprovada
Comandos: loop completo de dart format/analyze/test dos sete pacotes; python3 -B plan/evidence/r41/validate_consumer.py --dart dart --report /tmp/deltasync-r41-consumer-final.json; dart run example/selective_observation_example.dart. Matriz: 309 testes, respectivamente 18/134/83/14/40/10/10, sete formatos sem alterações e sete análises limpas. Dois testes externos, prova negativa das APIs antigas e sete inventários aprovados. Exemplo confirma uma atualização e três pendências sem push. Comandos, diretórios, saídas, correções operacionais e hashes nos artefatos; focados repetidos não somam ao total.
Critérios: C1 por metadados dos oito tipos, lote deduplicado, replay/perdedor LWW, delta vazio e snapshot com bindings vazios/tombstone isolados; C2 por commitsFor, query pontual no exemplo/consumidor e nenhum envio disparado pelo listener; C3 por um controller e _emit, filtros com identidade comum e outbox como fonte única; C4 por commit bloqueado/adoção, rollback local/remoto sem sucesso, ACK parcial/falho, listeners tardios/pausados/com erro, ordem e drenagem/done no dispose; C5 por guia/fixture de cinco casos exaustivos, construtor não const com addresses obrigatório, getter externo e retorno Set<String> de mergeSnapshotJson, inventariados contra HEAD inicial.
Manutenção: cinco critérios marcados, índice/fase/trace atualizados; DEC-66 e RISK-40/41 registram semântica e limites. R-33 próxima pronta; nenhuma ativa ou próxima implementação iniciada. Fase 6/VAL-17 permanecem abertos. Checker e diff executados após manutenção.
Limitações: Dart 3.13.5/Linux x86_64 e SQLite FFI real nas suítes existentes; sem SDK mínimo 3.12.x ou Android novo. ACKs controlados não provam rede/persistência remota real. Endereços processados não são diff visível ou valor histórico; pausa pode reter eventos não selecionados e atrasar dispose. Ordem é por subscription; consumidor retoma/cancela pausadas. Fixture externa usa path/resolução própria offline, não hosted. Sem novos formatos, joins, contratos de adaptadores, SDK/versões, Compass, CI/serviços externos, commit ou publicação.

### Metadados, revisão e validação

O [contrato e reprodução](evidence/r41/README.md) liga APIs, testes e pontos de
manutenção. [validation.json](evidence/r41/validation.json) guarda logs reais e
hashes. Endereços de deltas vêm do contrato comum; snapshot devolve bindings do
peer já decodificado, sem segundo parser ou cópia completa de valores para
metadados. Isso inclui CRDTs vazios que export de deltas pode não representar.
Snapshots inválidos preservam estado/clocks; somente inputs adotados notificam.

Revisão viu buffering como limite relevante da fonte unificada: errors pausado
agora pode reter eventos comuns que descartará ao retomar. Teste novo confere
que só falhas chegam, na ordem e com identidade preservada. Commit seletivo
pausado não impede escritas; sua retomada entrega eventos/done e permite dispose.
Listener com erro usa Zone e não desfaz commit; tardio consulta estado sem replay.
Commit aceito e bloqueado é drenado antes do fechamento; trabalho novo é rejeitado.

Memória verifica lote dos oito tipos, inputs remotos repetidos/perdedores,
snapshot com binding vazio, falhas local/remota e ACK. Erro no storage de ACK
preserva pendências; retry parcial não gera commit novo. Falha de envio de ACK
após merge mantém estado/evento; callback incoming também produz SyncFailure
com a mesma instância em errors/observations. Matriz completa reexecutou SQLite
FFI, histórias duráveis, rollback e reabertura existentes; não extrapolar a Android.

### Consumo e compatibilidade

O [exemplo seletivo](../example/selective_observation_example.dart) hidrata estado
após start, reage por query a um endereço e não inicia push. O
[consumidor externo](evidence/r41/consumer_test.dart.txt) passa dois testes com
nenhum envio automático, contador de pendências, evento externo e switch
exaustivo dos cinco tipos existentes. Metadados são somente leitura e isolados.
[consumer-validation.json](evidence/r41/consumer-validation.json) confirma sete
inventários: commitsFor novo; addresses e construtor obrigatório não const em
SyncCommitEvent; retorno Set<String> de mergeSnapshotJson. Nenhum símbolo ou
variante novo/removido. Prova negativa rejeita construtor const anterior,
implementação sem addresses e override void. Evidências anteriores congeladas
permanecem intactas; quebras de fonte estão no
[guia](../docs/migracao-1.0.1.md#eventos-seletivos-e-fonte-comum--r-41).

### Manutenção

R-41 concluída, R-33 recomendada sem iniciar CI ou ativar serviços externos.
DEC-66/RISK-40/41 distinguem input processado, estado atual, commit e ACK.
Emissão tem um ponto comum; variantes, dados e joins mantêm contratos anteriores.
Gate integral da release permanece VAL-17.

Após manutenção, `python3 scripts/check_plan.py` aprovou 70 tarefas e 510 links
locais; `git diff --check` passou. Conferidos 18 hashes, lock/HEAD inalterados,
dois relatórios JSON, sintaxe Python, whitespace dos arquivos novos, IDs únicos,
âncora da execução e uma única fonte/emissão interna. Evidências anteriores
preservadas. Revisão documental final sem achados impeditivos; produção/testes
não mudaram após a matriz aprovada.

<a id="execucao-r-33-2026-10-24"></a>

## Execução R-33 — CI, advisories e SDK 3.13, 2026-10-24

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em c803825f98c7e05c7770c1d287187fe2c91fdb9b; R-30 concluída e R-33 pronta/recomendada. Lidos AGENTS/RUNBOOK, cinco skills completas, critérios da fase, baseline/matriz R-30, riscos de advisories/SDK e guia Dart. Consultadas fontes oficiais Dart/OSV/actions. Autor pediu evitar Dart 3.12 e autorizou alinhar para 3.13: critério e manifests passaram a ^3.13.0, referência stable 3.13.5. Nenhuma execução 3.12/3.13.0 alegada; baseline histórica preservada.
Implementação: workflow com jobs Dart/Flutter/policy e runner scripts/ci.py compartilhado, permissões contents:read e actions por SHA. Lista canônica de pacotes vem do SDK; erro de qualquer etapa encerra job. App tem resolução/lockfile próprios e dois builds debug. Scanner consulta OSV/Pub online sobre versões resolvidas, paginação completa, exceções exatas com motivo/expiração e falha de rede/resposta sempre não zero. Onze testes controlados sem pacote vulnerável em manifest. Mínimo ^3.13.0 nos sete pacotes/exemplo; formato ajustado em 19 arquivos com AST canônica idêntica. Documentados política, migração e atualização periódica; nenhum dado/join/formato/runtime de lint novo.
Review: aprovado
Achados: revisão do próprio agente, não independente. Corrigidos nome Pub com underscore inicial, invocação da CLI offline e diferenças de formato sob nova language version. Reforçados schema/paginação/erro de serviço, paths do workspace e propagação de saída. Checkout limpo revelou 452 diagnósticos ao analisar app Flutter sem resolução própria; raiz passou a excluir apenas esse app e os dois jobs foram reexecutados em checkouts/caches independentes. Delta revisto após correções; fluxo Flutter continua integral. Sem impeditivos restantes.
Validação: aprovada
Comandos: python3 -B scripts/ci.py dart; python3 -B scripts/ci.py flutter, cada um em clone/cache Pub distintos e sem package_config prévio; python3 -B scripts/ci.py policy; actionlint 1.7.7 .github/workflows/ci.yml; prova AST via dart --packages com baseline explícita. Resultado: 309 testes dos sete pacotes (18/134/83/14/40/10/10), dois do enlace, sete Flutter, onze da política, análises/formatos e dois APKs debug aprovados. Cinco exemplos e CLI em três processos/reset-offline-reconnect passaram. Consultas online: 60/46 pacotes hospedados, nenhum achado, nenhuma exceção ativa. Comandos/diretórios/saídas, versões resolvidas, falhas e hashes nos artefatos; repetições não somadas.
Critérios: C1 por lista canônica, sete pacotes/SQLite FFI e resolução/cache próprios na família mínima 3.13.x/stable selecionada conforme nova orientação; C2 por jobs/contextos separados, checker/diff, exemplos Dart e Flutter com análise/testes/dois builds e limites explícitos; C3 por consulta online pós-resolução, códigos 1/2, exceção exata/expiração, paginação e política semanal/mensal, sem scanner outdated; C4 por actionlint/checksum, fixtures de pub com aviso/exit 0, falha de pacote/teste Flutter/rede e respostas inválidas, sem vulnerável em produção, sem autofix/credenciais/uploads; C5 por registro local separado e ausência explícita de execução remota autorizada/disponível.
Manutenção: cinco critérios marcados, índice/fase/trace atualizados; DEC-67 e RISK-39/42 registram autorização de SDK e limites. R-34 liberada e recomendada sem iniciar piloto Saropa; nenhuma tarefa ativa. Fase 6/VAL-17 seguem abertos. Checker e diff executados após manutenção.
Limitações: Dart 3.13.5/Flutter 3.47.7/Linux, sem runtime 3.12 ou patch 3.13.0. Host usa OpenJDK 25/Python 3.15; runner configura Ubuntu 24.04/Temurin 21, não executado remotamente. Tests/builds Flutter não provam runtime Android ou rede física. OSV cobre vulnerabilidades conhecidas Pub, não segurança integral de SDK/SO/código/Gradle/Maven. Toolchain/Gradle podem ter cache; resolução Pub/configuração e consultas finais foram independentes. Sem piloto/instalação Saropa, mudanças de API funcional/formatos, Compass, publicação, ativação de serviços, uploads, commit ou run remoto de Actions.

### Evidências, correções e isolamento

O [contrato e reprodução](evidence/r33/README.md) e a [política de CI](../docs/ci.md)
explicam comandos, owners e limites. [validation.json](evidence/r33/validation.json)
guarda saídas reais aprovadas, trechos decisivos/hashes das falhas anteriores,
fontes oficiais, revisão e hashes dos arquivos. [resolutions.json](evidence/r33/resolutions.json)
fixa os grafos resolvidos em cada checkout, sem reutilizar package_config/lock
da biblioteca na árvore de trabalho. O app preserva seu lockfile e o exige na
resolução; fontes/names/versions dos pacotes consultados são verificáveis.

Execução na árvore já resolvida passou, mas o primeiro checkout limpo revelou
dependência acidental da resolução Flutter para o analyzer da raiz. Não se
aprovou essa execução: raiz exclui só o app independente, cuja análise integral
permanece no job Flutter. Novos clones/cache distintos passaram sem depender
da ordem dos jobs. O clone Dart terminou sem package_config Flutter. Falhas de
formato e CLI também interromperam os jobs, confirmando a propagação de saída.

O [instrumento AST](evidence/r33/format_ast.dart.txt) compara os 19 arquivos com
a revisão inicial explícita; programas parseados são iguais. Mudanças de SDK
e formatter não alteraram regra CRDT, payload, commit ou restauração. SDK/ranges
de dependências externos dos manifests só mudaram no mínimo Dart autorizado;
novas resoluções compatíveis foram exercitadas sem copiar lockfile da biblioteca.

### Controles e execução remota

Fixtures do runner verificam erro de pacote com exit 9, Flutter com exit 7,
advisory com exit 1 e rede/resposta/configuração com exit 2, mesmo após pub get
terminar com aviso e sucesso. Exceções exigem pacote/versão/ID exatos, motivo e
expiração; vazias/expiradas/duplicadas/inutilizadas reprovam. Paginação, resposta
contraditória e workspace malformado não ficam verdes. Dados sintéticos não
entram nos manifests. Lints/recommended permanece; Saropa é avaliação R-34.

Workflow usa SHAs verificados, token somente leitura, checkout sem persistir
credenciais e checksum do actionlint; sem upload/publicação ou autofix. Não foi
ativado serviço nem acionado workflow remoto. Logs locais e APKs não são prova
de GitHub Actions aprovado ou runtime Android. Política semanal consulta rede;
revisão mensal atualiza pins/exceções. Release integral continua em VAL-17.

Após manutenção, policy completo passou com onze testes, checker de 70 tarefas
e 525 links locais, diff local/último commit e actionlint. Conferidos 46 hashes,
oito manifests com alteração somente de SDK, lock Flutter só com metadata SDK,
19 programas canônicos equivalentes, JSON/sintaxe/whitespace, IDs únicos e
âncora da execução. HEAD/evidências anteriores preservados. Revisão documental
final sem impeditivos; código dos jobs corresponde aos checkouts validados.

<a id="execucao-r-34-2026-10-25"></a>

## Execução R-34 — Piloto Saropa essential, 2026-10-25

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: worktree limpa em 2a42a0b9f2143fc36e2b793d4e86867d5217623a; R-33 concluída e R-34 pronta. Lidos AGENTS/RUNBOOK, cinco skills completas, critérios da fase, DEC-67/OPEN-09, RISK-39/42 e trechos de SDK/contratos/matriz do guia Dart. Escopo restrito ao piloto e decisão; preservar recommended e Dart 3.13. Sem delegação.
Implementação: runner Saropa 16.7.0 exato em /tmp com cache próprio e dois clones descartáveis. Trinta e duas análises medidas em sete pacotes e exemplo Flutter; 116 arquivos rastreados, 166 alertas idênticos nas duas passagens. Fixtures de resolução exata/flexível e defeitos deliberados; integração nativa em três configurações e controle de exclusão. Relatório, coordenadas, métricas, inventário/hashes, versões, manifests/instrumento e logs resumidos em plan/evidence/r34; docs/ci.md aponta a decisão proposta de adiar. Nenhuma mudança permanente de código, manifests, configuração ou política de advisories.
Review: aprovado
Achados: revisão do próprio agente em etapa distinta, não independente. Conferidos diff e arquivos novos, amostra de 19 nomes de regra, invariantes/cardinalidade/SQL/dispose, resolução e limites das medições. Corrigidos whitespace em logs novos e classificação UTC: o construtor já normaliza inclusive parâmetros externos. Reexaminado o delta dessas correções; não há achado impeditivo restante. Divergência nativa Flutter permanece limitação explícita que fundamenta adiamento, sem aprovar cobertura inexistente.
Validação: aprovada
Resultados: dezesseis análises de baseline terminaram com zero e dezesseis scans resolvidos com exit 1 por alertas. Hashes dos 116 fontes preservados, dois resultados idênticos, sem markers de skip/falha/parada nos stderr; JSON, códigos, coordenadas, grafos e instrumento Python conferidos. Ver validation.json e instrumento validate.py.txt. Nova checagem não repete nem alega os testes runtime/builds históricos de R-33.
Comandos: em clones/runner separados, PUB_CACHE próprio, dart pub get; flutter pub get --enforce-lockfile; dart analyze nos sete pacotes e flutter analyze --no-pub no app, duas vezes cada; dart run saropa_lints:scan <alvo> --tier essential --resolve --format json --files-from-stdin, duas vezes por alvo. Integração adicional com blocos nativos essential, lane full e dart run saropa_lints:init --tier essential --reset --target <clone>; prova negativa retirando exclusão ancestral não resolveu divergência Flutter. Fixtures exata/flexível resolvidas e controle positivo analisado por ambas as ferramentas. Comandos/saídas resumidas e hashes originais nos artefatos. python3 /tmp/deltasync-r34-validate.py aprovou 472 verificações de evidência antes da manutenção; checker/diff aprovados. /usr/bin/time ausente motivou wait4 antes das medidas; exporter inicialmente excedeu saída e foi dividido, sem perder dados. Checagem encontrou whitespace em arquivo novo e caminho de log duplicado no validador temporário; corrigidos e revisados antes da aprovação.
Critérios: C1 por runner/versão/hash/SDK, resolução test/analyzer, CLI em sete pacotes e Flutter e comparação nativa sem alegar equivalência; C2 por duas medidas wall/CPU/RSS, amostra dos 19 nomes de regra, sobreposição e controle positivo/negativo; C3 por DEC-68 e adiamento sem mudanças na resolução/configuração permanente; C4 por revisão contextual de SQL/cardinalidade/UTC/streams e ausência de defeito funcional bloqueador confirmado na amostra, sem autofix/supressão/refatoração nem regressão artificial; C5 por limites explícitos e manutenção dos checks de advisories/CRDT/recuperação separados.
Manutenção: cinco critérios marcados; índice/fase/trace atualizados, DEC-68 e OPEN-09 resolvem adoção, RISK-39 registra custo/cobertura e decisão. R-35 pronta/recomendada sem iniciá-la; nenhuma tarefa ativa. Fase 6/VAL-17 permanecem abertos. Nenhum achado real fora do escopo identificado que exija nova tarefa.
Limitações: medições locais Linux com duas passagens e parte do probe nativo concorrente, sem SLA/energia/runtime Android/CI remoto. Nomes essential correspondem a conjuntos diferentes em CLI/YAML/inicializador; plugin Flutter retornou zero apesar de 25 alertas CLI, causa não estabelecida, portanto integração não foi aprovada. Amostra não audita exaustivamente os 166 alertas e fixture também contém defeito não detectado. Nenhuma nova consulta OSV, suíte runtime/build ou execução 3.12/patch 3.13.0 alegada. Sem mudança funcional/API/persistência, Compass, instalação permanente, commit, publicação ou ativação de serviço.

### Evidências e decisão

O [relatório](evidence/r34/README.md) contém amostra, critérios de reavaliação,
reprodução e limites para consumidores/contribuidores/forks. Os artefatos
[pilot.json](evidence/r34/pilot.json), [metrics.json](evidence/r34/metrics.json),
[diagnostics.json](evidence/r34/diagnostics.json),
[inventory.json](evidence/r34/inventory.json) e
[resolutions.json](evidence/r34/resolutions.json) registram versão exata, comandos,
32 medidas, 166 alertas, 116 hashes e grafos efetivos. Os
[logs](evidence/r34/logs.txt) preservam resultados decisivos e coordenadas, com
hashes dos originais antes de normalizar caminhos/whitespace e omitir mensagens
longas/progresso. [validation.json](evidence/r34/validation.json) registra checks;
[validate.py.txt](evidence/r34/validate.py.txt) é instrumento histórico somente
leitura ligado aos inputs temporários desta execução, não requisito novo de CI.

Adiar Saropa atende à tarefa de avaliação, sem declarar o plugin aprovado ou
resolver o conflito por downgrade. Test 1.33.0/analyzer 14.6.0 permaneceram no
workspace dos clones; o runner usa analyzer 12.1.0 e aceita Dart 3.13.5. Root e
Flutter mantêm recommended/flutter_lints e a consulta OSV independente da R-33.
Os 166 alertas não equivalem a 166 bugs ou vulnerabilidades; controle positivo
mostra sinais adicionais e sobreposição, e também um controller não detectado.

Após manutenção, o checker exigiu os campos Review/Validação em linhas próprias
e o campo Achados no registro final. Ajustada apenas a estrutura do registro,
sem flexibilizar o checker. Revisão final das correções documentais e do
checksum sem autorreferência aprovada. `python3 plan/evidence/r34/validate.py.txt`
aprovou 474 verificações de evidência; `python3 scripts/check_plan.py` aprovou
70 tarefas e 554 links locais, com R-35 pronta; `git diff --check` passou.
Hashes, códigos de saída, whitespace dos arquivos novos, decisão e status foram
conferidos novamente após correções. Fonte, manifests/configurações, HEAD e
evidências históricas permanecem intactos. Nenhuma tarefa subsequente iniciada.
