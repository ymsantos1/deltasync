# Fase 2 — Completar CRDTs e integração

Estado: ativa. Objetivo: completar os oito tipos previstos no PDF.
Entrada: R-08d concluída, comprovando três tipos atuais sob contratos consolidados.
Saída: três tipos restantes e R-07a concluídos.
Riscos: contexto causal e lacunas, composição observada e crescimento de metadados.
Exclusões: ObjectCrdt obrigatório, gerador de modelos e sequências experimentais.

## Critérios e validação comuns dos tipos

Cada R-06 precisa de operações locais que retornem deltas, consulta do valor,
join de estado, JSON/restauração, duplicação/reordenação e equivalência entre
reconciliar estado e deltas. Testar associatividade, comutatividade e idempotência
do join com permutações ou geração determinística; registrar semente quando houver.
Não confundir essas propriedades com comutatividade de mutações locais.

Cada tipo também entra em codec, roteamento, snapshot, outbox e API de sync na
própria R-06, com fluxo entre duas engines e restauração usando MemoryStorage.
Áreas de cada tarefa incluem consumidores afetados e facade. Persistência real
dos oito tipos é consolidada em R-07a; não adiar integração individual para lá.
Explicar estado, delta, join e metadados restauráveis com exemplo pequeno.
Reusar contratos comuns de R-09a/R-09b; abstração adicional precisa de uso concreto.
Cada tipo integra identificação tipada, metadados comuns e rótulos serializados
estáveis nesses contratos, com rejeição de entrada desconhecida/inválida. Aplicar
[recursos do Dart](../AGENTS.md#uso-adequado-dos-recursos-do-dart) quando simplificarem
a implementação; não criar hierarquia paralela nem exigir um recurso por CRDT.

Definir contexto causal apropriado antes de MV-Register e OR-Set. Observar evento
posterior não comprova recebimento do anterior; preservar lacunas ou estabelecer
pré-condições de entrega com mecanismo que as assegure.

<a id="r-06a"></a>

## R-06a — G-Set

Status: concluída
MoSCoW: MUST
Dependências: R-08d

Áreas: packages/deltasync_core/lib/src/ e teste próprio de G-Set.
Objetivo: conjunto com adições e união de estados.

Critérios:

- [x] União e adições repetidas preservam valor.
- [x] Delta permite troca incremental de elementos adicionados.
- [x] Critérios e validação comuns dos tipos satisfeitos.

Evidência: `GSet` cobre join associativo, comutativo e idempotente, duplicação,
reordenação, JSON estrutural, deltas incrementais e snapshot. `Replica` integra
codec, roteamento, merge, export e snapshot v4; `SyncEngine` grava G-Set na outbox.
Testes cobrem duas engines com `MemoryStorage`, restauração, API da facade e leitura
de snapshots v3 sem G-Set. Detalhes e comandos em
[TRACEABILITY](TRACEABILITY.md#execução-r-06a--2026-10-04).

<a id="r-06b"></a>

## R-06b — 2P-Set

Status: concluída
MoSCoW: MUST
Dependências: R-08d

Áreas: packages/deltasync_core/lib/src/ e teste próprio de 2P-Set.
Objetivo: conjuntos de adições e remoções com remoção definitiva do elemento.

Critérios:

- [x] Elemento removido não retorna por readição ou mensagem antiga.
- [x] Metadados de remoção preservados em merge e restauração.
- [x] Critérios e validação comuns dos tipos satisfeitos.

Evidência de conclusão: ver [TRACEABILITY](TRACEABILITY.md#execução-r-06b--2026-10-04).

<a id="r-06c"></a>

## R-06c — MV-Register

Status: pronta
MoSCoW: MUST
Dependências: R-08d

Áreas: core, identidade/contexto causal e testes de MV-Register.
Objetivo: preservar versões concorrentes, removendo versões observadas dominadas.

Critérios:

- [ ] Escritas concorrentes permanecem visíveis.
- [ ] Escrita posterior observada domina versões anteriores.
- [ ] Contexto e dots sobrevivem à serialização; lacunas não ocultam versões.
- [ ] Critérios e validação comuns dos tipos satisfeitos.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-06d"></a>

## R-06d — OR-Set

Status: pronta
MoSCoW: MUST
Dependências: R-08d

Áreas: core, identidade/contexto causal e testes de OR-Set.
Objetivo: remover adições observadas e permitir adição concorrente/readição.

Critérios:

- [ ] Remoção elimina apenas tags observadas.
- [ ] Adição concorrente vence remoção; readição é permitida.
- [ ] Deltas antigos não ressuscitam tags removidas após restauração.
- [ ] Critérios e validação comuns dos tipos satisfeitos.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-06e"></a>

## R-06e — OR-Map

Status: planejada
MoSCoW: MUST
Dependências: R-06d

Áreas: core, roteamento de valores CRDT e testes de OR-Map.
Objetivo: existência observada das chaves e join dos valores CRDT aninhados.
Dependência adicional: tipos efetivamente usados como valores devem estar prontos.

Critérios:

- [ ] Documentar política de existência das chaves e atualização versus remoção.
- [ ] Atualizações de valores CRDT convergem sem substituir estado concorrente.
- [ ] Remoção observada, recriação e delta antigo são testados.
- [ ] Critérios e validação comuns dos tipos satisfeitos.

Não impor update-wins global a objetos ou registradores; testar semântica escolhida.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-07a"></a>

## R-07a — Integrar oito tipos e codecs

Status: planejada
MoSCoW: MUST
Dependências: R-07d, R-06a, R-06b, R-06c, R-06d, R-06e

Áreas: core, codecs, storage/OutboxEntry, sync, adaptador SQLite e testes.
Objetivo: consolidar conjunto de oito tipos já integrados individualmente,
incluindo lotes mistos e snapshots restauráveis em storage durável.

O fluxo usa `ReplicaStorage`; SQLite é o backend da evidência durável de referência,
conforme o [escopo de storage](README.md#storage-e-adaptadores).

Critérios:

- [ ] Codec, roteamento, estado, snapshot e outbox cobrem todos os tipos.
- [ ] Lotes mistos preservam mudanças; tipos/versões inválidos têm erro explícito.
- [ ] Cada tipo realiza fluxo mutação, storage, envio e aplicação remota.
- [ ] SQLite real restaura snapshots/pendências dos oito tipos; integração
  individual anterior não ser apresentada como durabilidade já comprovada.
- [ ] Nenhuma integração depende de build_runner.

Validação: round-trip e fluxo conjunto de cada tipo, lote misto, snapshot com
tombstones e mudanças posteriores, fechamento/reabertura de SQLite com estado
dos oito tipos. Validar pacotes afetados, facade e plataforma do adaptador.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.


## Gate da fase

R-06a a R-06e e R-07a concluídas com evidências por tipo. Tipos integrados
anteriormente são baseline implementada, não prova de que integração completa já existe.
