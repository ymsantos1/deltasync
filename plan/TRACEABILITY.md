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
