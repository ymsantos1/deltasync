# Rastreabilidade e evidências

Baseline histórica: 2026-09-27. Fontes: [PDF](<../referencia/Proposta TCC.pdf>),
[contexto](../proposta.md) e inspeção/testes da revisão anterior.
A reorganização documental não reexecutou testes Dart nem corrigiu código.

## Panorama atual — 2026-10-03

Revisão completa em [análise da arquitetura](../docs/analise-arquitetura.md).
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
| DeltaCrdt e LWW, PDF §§6.2/6.5 | R-01, R-09a | contrato nativo, LwwRegister, Replica; compatibilidade explícita e join |
| Identidade/dots e roteamento, PDF §§6.4/6.5 | R-02, R-09a, R-09b | metadados comuns, vínculo por endereço/tipo e contexto adequado |
| Confirmação/outbox, PDF §6.6 | R-03, R-09b, R-08b, R-08d | outbox por mudança, ACK parcial, retry e destino definido |
| Persistência consistente, PDF §6.6 | R-04, R-09b, R-07b, R-07c, R-07d | snapshot canônico, isolamento, contrato, SQLite real e falhas |
| Continuidade do sync, PDF §§6.5/6.9 | R-05, R-08d, R-08c | lifecycle/fila; duas engines, edição durante envio, falhas e reconexão |
| G-Set, 2P-Set, MV-Register, OR-Set, OR-Map, PDF §6.2 | R-06a, R-06b, R-06c, R-06d, R-06e | novos tipos no core; operações, deltas, join e restauração |
| Integração/JSON, PDF §§6.5/6.8 | R-06a, R-06b, R-06c, R-06d, R-06e, R-07a, R-08a | integração individual e conjunto de oito tipos com SQLite |
| Testes, PDF §6.9 | VAL-01, R-07d, R-08c | propriedades, regressão, integração e recuperação real |
| Demonstração, contexto atual | VAL-02 | consumidor real, dois tipos, SQLite, duas réplicas, integração e experiência offline; Compass é exemplo opcional |
| Simplicidade, manutenção e forks, orientação do autor | R-09a, R-09b, R-05, R-08d, VAL-04 | responsabilidades localizáveis, API pública, percurso de alteração e compatibilidade |
| Relatório/texto e fechamento | VAL-03, VAL-04, VAL-05 | evidência por requisito, arquitetura/API e gate final |
| Motivação incremental, SHOULD | VAL-06 | comparação reproduzível de bytes de delta/estado |

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
