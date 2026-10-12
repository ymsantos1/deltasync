# Rastreabilidade e evidências

Baseline histórica: 2026-09-27. Fontes: [PDF](<../referencia/Proposta TCC.pdf>),
[contexto](../proposta.md) e inspeção/testes da revisão anterior.
A reorganização documental não reexecutou testes Dart nem corrigiu código.

Estado atual — 2026-10-11: [revisão técnica](#revisao-tecnica-2026-10-11)
confirmou três defeitos apesar de 155 testes aprovados. R-11 foi
[concluída em 2026-10-12](#execucao-r-11-2026-10-12); R-10/R-12 são MUST prontas.
VAL-05 segue planejada; VAL-07 é SHOULD para evidência mobile.
Esta [manutenção MoSCoW](#manutencao-moscow-2026-10-11) não corrigiu o produto.

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
| Integração Flutter/sqflite mobile, SHOULD | VAL-07 | build/runtime, reinício de processo e reconciliação no alvo declarado |

### Matriz final de evidências MUST — 2026-10-06

Esta matriz resume implementação e execução de 2026-10-06; a seção de baseline e os
registros por tarefa abaixo preservam história. Os diagnósticos de 2026-10-11
reabrem o fechamento: coleções LWW tipadas, conflito de ID pendente e retry de
abertura ainda exigem correção. Evidências distinguem unidade,
integração em processo, recuperação SQLite após fechamento/reabertura e demo
consumidora entre processos. Uma categoria não substitui outra.

- **Unidade/propriedades:** VAL-01 e testes de `packages/deltasync_core/test/`
  e `test/`; resultados de core e facade registrados em sua execução.
- **Integração:** R-08d exercita duas `SyncEngine` ligadas via API pública;
  R-08c combina divergência offline, reordenação, retry e ACK.
- **Recuperação durável:** R-07d, R-07a e R-08c fecham engines/bancos SQLite
  reais, reabrem e verificam snapshot, outbox, tombstones e entrega. Execução Linux
  x64 via FFI; MemoryStorage não conta como recuperação de processo.
- **Demonstração consumidora:** VAL-02 roda `offline` e `reconnect` em processos
  Dart separados; registra integração, mensagens de pendência/erro/ACK e estado.

| Requisito MUST | Implementação | Evidência executada | Limite declarado |
|---|---|---|---|
| Oito CRDTs, mutações, deltas e joins | `packages/deltasync_core/lib/src/`; OR-Map compõe G-Set; fachada `lib/deltasync.dart` | Testes por tipo em `packages/deltasync_core/test/`; propriedades VAL-01; lote SQLite de oito tipos R-07a | Fixtures algébricas finitas; não constituem prova matemática universal |
| Identidade, dots e roteamento por endereço | `identity.dart`, `replica.dart`, `delta_change.dart` | Testes `ReplicaId and Dot round trip and validate identity`, roteamento misto, conflito de endereço/tipo; R-02/R-09a/R-09b/R-07a | G/PN usam componentes cumulativos; tipos com eventos individuais mantêm contexto explícito |
| JSON, snapshots e restauração | `delta_codec.dart`, `replica.dart`, snapshots canônicos | Testes codec/snapshot core e `sync_recovery_test.dart`; VAL-01/R-07a | Formatos antigos aceitos ou rejeitados conforme migração documentada; consumidores externos desconhecidos em OPEN-07 |
| Core independente e contratos modulares | `deltasync_core`, `deltasync_storage`, `deltasync_sync`, `deltasync_transport`, facade | Analyze/test por pacote; integração pública R-08d e VAL-02 | SQLite fica no adaptador; nenhuma dependência de Flutter no core |
| Storage substituível e `MemoryStorage` | `ReplicaStorage`, `MemoryStorage`, suíte `deltasync_storage_testing` | R-07b e contrato testado; `memory_storage_contract_test.dart` | Memória é volátil e não prova restart |
| SQLite, outbox durável e recuperação | `packages/deltasync_storage_sqflite/lib/` | R-07c/R-07d, R-07a (oito tipos), R-08c, VAL-02; SQLite FFI real com fechamento/reabertura | Execução em Linux x64 via FFI; plugin Flutter mobile não testado |
| Transporte abstrato, roteamento e envelopes | `deltasync_transport`; `SyncEngine` e destino por peer | `delta_envelope_test.dart`, R-08a/R-08b/R-08d | Transporte dos cenários é em processo; protocolo de rede não faz parte do recorte |
| ACK explícito, retry sem perda e commit atômico | `SyncEngine`, `ReplicaStorage.commit/commitRemote`, outbox por mudança | Testes de ACK parcial, retry, falhas e transação em sync/storage/SQLite; R-03/R-04/R-05/R-07d/R-08b/R-08c | Só `appliedAndPersisted` do peer destinatário confirma; legado `PendingDeltaStore` conserva itens após ACK |
| Reconciliação offline na topologia declarada | Outbox direcionada e recuperação em `SyncEngine` | R-08c e consumidor VAL-02, com duas réplicas SQLite | Peer fixo; peer adicional requer cópia de outbox e confirmação independente |
| Testes unitários, integração, recuperação e regressão | Suítes core, facade, sync, storage, adapter SQLite e transporte | VAL-01 cobre oito tipos; R-07d/R-08c cobrem recuperação SQLite; VAL-02 percorre consumidor | Cenários e plataformas estão listados por execução, sem alegação universal |
| Aplicação demonstrativa mínima | `example/offline_reconciliation.dart`; configuração em `README.md` | VAL-02: edição offline, falha visível, restart, reconexão, ACK e convergência | CLI/transport sintético; sem participantes, plugin mobile ou avaliação geral de usabilidade |
| Core nativo, snapshot canônico, fila sem espera de rede | `Replica`, `ReplicaState`, `SyncEngine`, `OutboxEntry` | Regressões R-09a/R-09b/R-05; envio lento com commits locais em `sync_engine_test.dart` | Histórico e deduplicação limitados conforme R-09b; sem benchmark de escala |
| Formatos versionados e compatibilidade explícita | `DeltaCodec`, snapshots e codecs de outbox/envelope | Fixtures de migração/rejeição em core/storage/transport; R-09a/R-09b/R-06/R-07a | Não há inventário de todos consumidores externos (OPEN-07) |

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
- SQLite foi executado com FFI em Linux x64; integração Flutter mobile e backup em dispositivo
  não foram avaliados. VAL-02 usa transporte sintético e CLI, sem participantes.
  VAL-06 é SHOULD concluída, com medição em 2026-10-07; envelopes somam 1.079 B
  contra 1.255 B de snapshots nesse cenário. VAL-07 registra a lacuna mobile.
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
