# Planejamento — DeltaSync

Revisão: 2026-09-27. Fonte principal de tarefas, escopo e andamento.

## Navegação

- [Contexto arquitetural](../proposta.md) e [PDF acadêmico](<../referencia/Proposta TCC.pdf>).
- [Fase 1: correções](01_PHASE1_CORRECOES.md).
- [Fase 2: CRDTs](02_PHASE2_CRDTS.md).
- [Fase 3: persistência](03_PHASE3_PERSISTENCIA.md).
- [Fase 4: sync](04_PHASE4_SYNC.md).
- [Fase 5: validação](05_PHASE5_VALIDACAO.md).
- [Rastreabilidade e evidências](TRACEABILITY.md).
- [Decisões e invariantes](DECISIONS.md).
- [Riscos](RISKS.md).
- [Instruções de trabalho](../AGENTS.md).
- [Como executar tarefas com ciclo completo](RUNBOOK.md).

## Situação e referência acadêmica

A proposta é coerente como biblioteca modular de CRDTs com sincronização
incremental e persistência local. A implementação atual ainda não satisfaz esse
escopo: há três dos oito CRDTs, integração restrita a LWW e armazenamento apenas
em memória. A viabilidade no prazo não pode ser confirmada sem datas, esforço
disponível e estimativas das tarefas restantes; OR-Set, OR-Map, recuperação durável
e integração são os maiores riscos.

Os planos anteriores acrescentavam obrigações não presentes no texto acadêmico:
`ObjectCrdt`, política global add/update-wins para objetos, geração de código,
schema de modelos e anti-entropy genérico. Também repetiam tarefas concluídas e
tratavam persistência/lifecycle parciais como concluídos. Esta revisão separa
requisitos acadêmicos, decisões técnicas de execução e extensões.

### Divergências que precisam constar no texto final do TCC

- PDF §§6.3 e 6.6 vincula storage a Flutter/`sqflite`; contexto atual pede contrato
  independente de banco. Compatibilização: contrato Dart puro mais adaptador
  SQLite/`sqflite` de referência. O adaptador é substituível, mas sua entrega
  continua prevista no TCC.
- PDF §6.3 descreve três módulos internos (`crdt_core`, `crdt_storage`,
  `crdt_sync`); repositório usa quatro subpacotes e facade. Atualizar nomes e
  diagrama; transporte separado preserva a responsabilidade já prevista.
- PDF §§6.5 e 6.8 exemplifica `query()`, `generateDelta()` e conversões JSON.
  API atual usa `value`, `mergeState()`, `applyDelta()` e mutações que retornam
  deltas. Documentar correspondência; não implementar assinaturas apenas para
  copiar a tabela. Restauração de estado ainda precisa de contrato verificável.
- PDF §6.9 exige testes de integração e recuperação; aplicação de exemplo é
  apresentada como possibilidade. O contexto atual em proposta.md inclui
  demonstração na validação: mantida como MUST por esse contexto, com cenário
  pequeno, sem gerador de modelos.
- `build_runner`/codegen não aparecem no PDF nem nas dependências atuais. Não são
  requisito para validar a proposta.

Não reduzir silenciosamente os oito CRDTs previstos. Se o prazo exigir recorte,
registrar a alteração da proposta e justificá-la academicamente.

## Modelo de trabalho

Um agente executa etapas distintas: leitura da tarefa, implementação, review,
validação e manutenção do plano. Review pelo mesmo agente ajuda a detectar erros,
mas não é revisão independente. Pedido apenas de análise/review não autoriza
implementar correções nem alterar status automaticamente.

Fase ativa: **1 — correções**. Tarefa ativa: **nenhuma**.
Próxima tarefa recomendada: **R-04 — commits atômicos e snapshots**.

Após concluir tarefa, selecionar próxima autorizada e sem dependências pendentes.
Fases organizam entregas; não são barreiras artificiais: fase 2 pode começar com
R-02 concluída, fase 3 com R-04, e R-08a com R-02. Registrar mudança da fase ativa
se selecionar trabalho de outra fase. Não relaxar gate final por esse motivo.

MoSCoW define escopo: MUST obrigatório, SHOULD importante e dispensável com
justificativa, COULD opcional, WON'T-YET fora desta entrega. Sem RICE ou
01_SCORING.md nesta versão: dependências e risco de correção orientam prioridade.

Estados:

- `planejada`: critérios definidos, ainda não selecionável por dependência/entrada.
- `pronta`: dependências satisfeitas e escopo executável.
- `em andamento`: uma tarefa de implementação ativa por vez.
- `em revisão`: mudança preparada, diff ainda precisa de review.
- `em validação`: review realizado, evidências exigidas ainda pendentes.
- `bloqueada`: impedimento concreto externo ou decisão necessária; registrar causa.
- `concluída`: critérios satisfeitos, review e validação adequados registrados.

Fluxo habitual: pronta, em andamento, em revisão, em validação, concluída.
Achado relevante devolve tarefa para em andamento; falha/lacuna de validação
impede conclusão. Dependência planejada não é bloqueio externo.
Baseline parcial descreve implementação existente, não tarefa em andamento.

Pedidos de implementação usam plan-executor e suas cinco skills obrigatórias.
Registros por tarefa seguem [RUNBOOK.md](RUNBOOK.md). Checker de consistência:
`python3 scripts/check_plan.py`, executado da raiz após manutenção.

## Índice de tarefas

Critérios detalhados pertencem somente ao arquivo da fase. Este índice espelha
status, prioridade e dependências; atualizar ambos na manutenção.

| Tarefa | Entrega | Status | MoSCoW | Dependências |
|---|---|---|---|---|
| [R-01](01_PHASE1_CORRECOES.md#r-01) | LWW nativo e compatibilidade | concluída | MUST | — |
| [R-02](01_PHASE1_CORRECOES.md#r-02) | Identidade e roteamento | concluída | MUST | R-01 |
| [R-03](01_PHASE1_CORRECOES.md#r-03) | ACK e outbox seguros | concluída | MUST | — |
| [R-04](01_PHASE1_CORRECOES.md#r-04) | Commits atômicos e snapshots | pronta | MUST | R-02, R-03 |
| [R-05](01_PHASE1_CORRECOES.md#r-05) | Lifecycle e processamento remoto | planejada | MUST | R-04 |
| [R-06a](02_PHASE2_CRDTS.md#r-06a) | G-Set | pronta | MUST | R-02 |
| [R-06b](02_PHASE2_CRDTS.md#r-06b) | 2P-Set | pronta | MUST | R-02 |
| [R-06c](02_PHASE2_CRDTS.md#r-06c) | MV-Register | pronta | MUST | R-02 |
| [R-06d](02_PHASE2_CRDTS.md#r-06d) | OR-Set | pronta | MUST | R-02 |
| [R-06e](02_PHASE2_CRDTS.md#r-06e) | OR-Map | planejada | MUST | R-06d |
| [R-07a](02_PHASE2_CRDTS.md#r-07a) | Integrar oito tipos e codecs | planejada | MUST | R-04, R-06a, R-06b, R-06c, R-06d, R-06e |
| [R-07b](03_PHASE3_PERSISTENCIA.md#r-07b) | Suíte de contrato de storage | planejada | MUST | R-04 |
| [R-07c](03_PHASE3_PERSISTENCIA.md#r-07c) | Adaptador SQLite/sqflite | planejada | MUST | R-07b |
| [R-07d](03_PHASE3_PERSISTENCIA.md#r-07d) | Recuperação durável e falhas | planejada | MUST | R-05, R-07c |
| [R-08a](04_PHASE4_SYNC.md#r-08a) | Integrar envelopes | pronta | MUST | R-02 |
| [R-08b](04_PHASE4_SYNC.md#r-08b) | Topologia e confirmação | planejada | MUST | R-03, R-08a |
| [R-08c](04_PHASE4_SYNC.md#r-08c) | Reconciliação offline integrada | planejada | MUST | R-05, R-07a, R-07d, R-08b |
| [VAL-01](05_PHASE5_VALIDACAO.md#val-01) | Propriedades e regressão completas | planejada | MUST | R-07a |
| [VAL-02](05_PHASE5_VALIDACAO.md#val-02) | Demonstração mínima | planejada | MUST | R-08c |
| [VAL-03](05_PHASE5_VALIDACAO.md#val-03) | Relatório e rastreabilidade finais | planejada | MUST | VAL-01, VAL-02, R-07d, R-08c |
| [VAL-04](05_PHASE5_VALIDACAO.md#val-04) | Alinhar texto acadêmico | planejada | MUST | R-07a, R-07d, R-08c |
| [VAL-05](05_PHASE5_VALIDACAO.md#val-05) | Gate final do TCC | planejada | MUST | VAL-03, VAL-04 |
| [VAL-06](05_PHASE5_VALIDACAO.md#val-06) | Medir tamanho dos deltas | planejada | SHOULD | VAL-02 |

## Escopo e prioridades

| Entrega | Prioridade | Origem |
|---|---|---|
| LWW-Register, MV-Register, G-Counter, PN-Counter, G-Set, 2P-Set, OR-Set, OR-Map | MUST | PDF §6.2 |
| Mutações que retornam deltas; join idempotente, comutativo e associativo | MUST | PDF §§6.2, 6.5 |
| Estado/delta serializável e restaurável | MUST | PDF §§6.5, 6.8 |
| Core independente de Flutter; separação de storage e sync | MUST | PDF §6.3 |
| Contrato de storage substituível e MemoryStorage de referência | MUST | Contexto arquitetural atual |
| Adaptador SQLite/sqflite, outbox durável e recuperação entre sessões | MUST | PDF §6.6 |
| Transporte abstrato, roteamento e envelopes lógicos | MUST | PDF §§6.5, 6.7 |
| Semântica de confirmação explícita e retry sem perda | MUST | PDF §6.6; decisão técnica |
| Reconexão e reconciliação no cenário/topologia documentados | MUST | PDF §§6.5, 6.9 |
| Testes unitários, integração, recuperação e regressão | MUST | PDF §6.9 |
| Propriedades algébricas com permutações/testes gerativos reproduzíveis | MUST | PDF §6.9; método técnico |
| Commits atômicos e formatos versionados | MUST | Decisões técnicas para durabilidade/evolução |
| Aplicação demonstrativa mínima | MUST | Contexto atual; PDF §6.9 a apresenta como possibilidade |
| Medição de bytes de deltas versus estado completo | SHOULD | Evidência da motivação incremental |
| ObjectCrdt, anotações, build_runner, codegen e migração de modelos | WON'T-YET | Extensões dos planos antigos |
| Anti-entropy genérico, ACK por participante e GC destrutivo de tombstones | WON'T-YET | Extensões além do cenário mínimo |
| OR-Seq/ORSeg, backend próprio, autenticação, autorização, protocolo de rede obrigatório e transações distribuídas | WON'T-YET | Limitações da proposta |

OR-Map continua obrigatório, incluindo valores CRDT e semântica de existência
documentada. Isso não exige um framework separado de objetos arbitrários.
Add-wins de OR-Set/OR-Map não impõe automaticamente update-wins a todo objeto ou
registrador. LWW mantém sua própria política.

## Gates e critérios de conclusão

Cada fase define entrada, saída e validações específicas. Concluir TCC requer
VAL-05: oito CRDTs integrados, deltas/joins corretos, formatos restauráveis,
SQLite real, commits atômicos, outbox/ACK sem perda, reconciliação na topologia
declarada, testes, demonstração e texto acadêmico alinhado.

VAL-06 é SHOULD e não bloqueia entrega. Codegen, ObjectCrdt, backend próprio,
GC destrutivo e anti-entropy genérico não são gates do TCC.
Prazo, esforço disponível e cronograma ainda não foram fornecidos.

## Evidência e validação

Registrar em TRACEABILITY.md: tarefa/requisito, arquivos, testes, comandos, data,
ambiente, resultado, limitações e critérios ainda sem evidência.
Não reaproveitar baseline antiga como validação de código novo.
Review avalia diff e semântica; validação executa checks adequados ao critério.

Para tarefa localizada, analisar/testar pacote alterado e consumidores afetados;
quebra de API ou integração entre camadas exige também facade e integração.
Antes do gate final, cobrir workspace inteiro e novos pacotes presentes.
Comandos Dart estão em [AGENTS.md](../AGENTS.md).

Mudança apenas documental: verificar links, IDs/dependências, consistência de
status, frontmatter das skills e `git diff --check`; sem nova alegação de
aprovação de testes de código. SQLite exige execução real e plataforma registrada.

## Manutenção e migração

Migrados os planos da raiz para estes arquivos, preservando diagnóstico e
escopo da revisão anterior. R-01 a R-05 mantêm IDs. R-06 virou R-06a a R-06e;
R-07 foi dividido em integração/contrato/adaptador/recuperação; R-08 em
envelopes/topologia/fluxo. VAL-* explicita demonstração, relatório e gates.

Não manter cópia concorrente dos planos antigos. Fonte de escopo: este README;
tarefas: fases; evidências: TRACEABILITY; escolhas: DECISIONS; riscos: RISKS.
Mudança de escopo registra origem, justificativa e impacto no prazo.

`moscow.md` foi restaurado pelo autor como referência histórica. Não é plano
concorrente nem impõe multiagentes, RICE ou novas aprovações ao fluxo vigente.
