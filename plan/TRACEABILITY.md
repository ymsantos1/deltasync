# Rastreabilidade e evidências

Baseline: 2026-09-27. Fontes: [PDF](<../referencia/Proposta TCC.pdf>),
[contexto](../proposta.md) e inspeção/testes da revisão anterior.
A reorganização documental não reexecutou testes Dart nem corrigiu código.

## Estado verificado

“Implementado” indica código e testes existentes, não conclusão da validação
acadêmica. “Parcial” não satisfaz o gate de entrega.

| Requisito | Implementação/evidência | Estado e lacuna |
|---|---|---|
| Arquitetura modular | `pubspec.yaml`, `lib/deltasync.dart`, quatro subpacotes | Implementada; sem Flutter/banco/rede no core |
| Identidade e clocks | `packages/deltasync_core/lib/src/identity.dart`, `hlc.dart`, `vector_clock.dart` | Tipos implementados; lifecycle durável e lacunas causais pendentes |
| Contrato DeltaCrdt | `packages/deltasync_core/lib/src/crdt.dart` | Implementado; mutação específica por tipo |
| LWW nativo | `lww_register.dart`, `lww_delta.dart`, `Replica.setDelta/removeDelta` | HLC e tombstone implementados; caminho legado ainda ativo |
| G-Counter e PN-Counter | `g_counter.dart`, `pn_counter.dart` | Implementados isoladamente; sem roteamento em Replica/SyncEngine |
| Cinco CRDTs restantes | Sem classes correspondentes | Pendentes |
| Serialização de deltas | `delta.dart`, `delta_codec.dart` | LWW e counters; codec versão 1; snapshot sem versão própria |
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
| DeltaCrdt e LWW, PDF §§6.2/6.5 | R-01 | core/crdt, LwwRegister, Replica; regressão legada e join nativo |
| Identidade/dots e roteamento, PDF §§6.4/6.5 | R-02 | Replica, Delta, OutboxEntry; counters independentes, lotes mistos, lacunas |
| Confirmação/outbox, PDF §6.6 | R-03, R-08b | storage/sync/transport; ACK parcial e retry, política de recuperação |
| Persistência consistente, PDF §6.6 | R-04, R-07b, R-07c, R-07d | commits/snapshots; contrato, SQLite real e falhas |
| Continuidade do sync, PDF §§6.5/6.9 | R-05, R-08c | lifecycle/recepção; concorrência, falhas e reconexão |
| G-Set, 2P-Set, MV-Register, OR-Set, OR-Map, PDF §6.2 | R-06a, R-06b, R-06c, R-06d, R-06e | novos tipos no core; operações, deltas, join e restauração |
| Integração/JSON, PDF §§6.5/6.8 | R-07a, R-08a | codecs, snapshots, roteamento/envelopes de oito tipos |
| Testes, PDF §6.9 | VAL-01, R-07d, R-08c | propriedades, regressão, integração e recuperação real |
| Demonstração, contexto atual | VAL-02 | aplicação mínima, dois tipos, SQLite e duas réplicas |
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

Ao concluir uma tarefa, adicionar registro com:

- ID, data e requisito/critério coberto.
- Arquivos e testes reais; apontar quais casos demonstram comportamento.
- Comando exato, ambiente/plataforma e resultado.
- Review realizado e achados resolvidos ou limitações explicitadas.
- Evidência ausente; impedimento, quando aplicável.

Manter baseline histórica; adicionar nova evidência sem substituir silenciosamente
resultados antigos. Falha também é evidência e não permite marcar conclusão.

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
