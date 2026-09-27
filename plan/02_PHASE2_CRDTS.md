# Fase 2 — Completar CRDTs e integração

Estado: planejada. Objetivo: completar os oito tipos previstos no PDF.
Entrada por tarefa: R-02 concluída; R-04 é necessária para integração persistível.
Saída: cinco tipos restantes e R-07a concluídos.
Riscos: contexto causal e lacunas, composição observada e crescimento de metadados.
Exclusões: ObjectCrdt obrigatório, gerador de modelos e sequências experimentais.

## Critérios e validação comuns dos tipos

Cada R-06 precisa de operações locais que retornem deltas, consulta do valor,
join de estado, JSON/restauração, duplicação/reordenação e equivalência entre
reconciliar estado e deltas. Testar associatividade, comutatividade e idempotência
do join com permutações ou geração determinística; registrar semente quando houver.
Não confundir essas propriedades com comutatividade de mutações locais.

Definir contexto causal apropriado antes de MV-Register e OR-Set. Observar evento
posterior não comprova recebimento do anterior; preservar lacunas ou estabelecer
pré-condições de entrega com mecanismo que as assegure.

<a id="r-06a"></a>

## R-06a — G-Set

Status: planejada
MoSCoW: MUST
Dependências: R-02

Áreas: packages/deltasync_core/lib/src/ e teste próprio de G-Set.
Objetivo: conjunto com adições e união de estados.

Critérios:

- [ ] União e adições repetidas preservam valor.
- [ ] Delta permite troca incremental de elementos adicionados.
- [ ] Critérios e validação comuns dos tipos satisfeitos.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-06b"></a>

## R-06b — 2P-Set

Status: planejada
MoSCoW: MUST
Dependências: R-02

Áreas: packages/deltasync_core/lib/src/ e teste próprio de 2P-Set.
Objetivo: conjuntos de adições e remoções com remoção definitiva do elemento.

Critérios:

- [ ] Elemento removido não retorna por readição ou mensagem antiga.
- [ ] Metadados de remoção preservados em merge e restauração.
- [ ] Critérios e validação comuns dos tipos satisfeitos.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-06c"></a>

## R-06c — MV-Register

Status: planejada
MoSCoW: MUST
Dependências: R-02

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

Status: planejada
MoSCoW: MUST
Dependências: R-02

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
Dependências: R-04, R-06a, R-06b, R-06c, R-06d, R-06e

Áreas: core/Replica/DeltaCodec, storage/OutboxEntry, sync/SyncEngine e testes.
Objetivo: integrar os oito tipos por endereço estável, com snapshot restaurável.

Critérios:

- [ ] Codec, roteamento, estado, snapshot e outbox cobrem todos os tipos.
- [ ] Lotes mistos preservam mudanças; tipos/versões inválidos têm erro explícito.
- [ ] Cada tipo realiza fluxo mutação, storage, envio e aplicação remota.
- [ ] Nenhuma integração depende de build_runner.

Validação: round-trip e fluxo conjunto de cada tipo, lote misto, snapshot com
tombstones e mudanças posteriores. Validar pacotes afetados e facade.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.


## Gate da fase

R-06a a R-06e e R-07a concluídas com evidências por tipo. Três tipos atuais são
baseline implementada, não prova de que integração completa já existe.
