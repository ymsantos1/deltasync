# Plano de Refatoração — DeltaSync

## 1. Objetivo

Migrar implementação atual, centrada em `Operation`, para arquitetura centrada
em Delta-CRDTs definida em `plano-desenvolvimento.md`, preservando evolução
incremental e compatibilidade temporária.

A refatoração deve terminar com este fluxo:

```text
mutação local
  → CRDT atualiza estado e gera delta
  → estado + delta persistidos atomicamente
  → delta enviado pela outbox
  → réplica remota aplica delta
  → estado persistido
```

`Operation` poderá permanecer como API legada, auditoria ou adaptador interno,
mas não será unidade obrigatória de interoperabilidade.

## 2. Estado atual

- [x] Contrato inicial `DeltaCrdt<V, D>` criado.
- [x] `HlcTimestamp` criado.
- [x] `LwwDelta<T>` criado.
- [x] `LwwRegister` aceita aplicação idempotente de `LwwDelta`.
- [x] Testes iniciais de convergência, duplicação e tombstone.
- [x] `Delta` agora aceita mudanças CRDT e operações legadas em paralelo.
- [x] `Replica` gera/aplica `LwwDelta` com HLC e `Dot`; API `Operation` permanece legada.
- [x] `ReplicaState` materializa estado a partir de operações e deltas.
- [x] `SyncEngine.withStorage` usa `ReplicaStorage` para snapshot e outbox nativo.
- [x] `ReplicaStorage` armazena operações e deltas, com ACK, estado `sent` e retry.
- [~] `PendingDeltaStore` legado ainda está disponível para compatibilidade.

## 3. Regras da migração

1. Não remover API legada antes de existir substituto testado.
2. Cada etapa deve manter `dart analyze` sem issues.
3. Cada mudança de contrato deve incluir teste de compatibilidade ou migração.
4. Correção do CRDT vem antes de storage SQLite, codegen e otimizações.
5. Deduplicação por ID auxilia transporte; correção deve vir do join do CRDT.
6. HLC resolve LWW; `VectorClock` permanece para causalidade e reconciliação.

## 4. Etapas

### Etapa 1 — Delta como unidade de protocolo

- criar `DeltaChange` comum para deltas CRDT;
- permitir `Delta` conter mudanças CRDT e operações legadas;
- deduplicar por identidade de delta sem depender de `OperationId`;
- adicionar codec versionado para mudanças LWW;
- manter transporte antigo funcionando durante transição.

Estado: concluída. Codec e envelope versionados implementados; integração obrigatória no transporte permanece pendente.

### Etapa 2 — Migrar `Replica` e `ReplicaState`

- criar mutação local que produz `LwwDelta`;
- aplicar delta diretamente no `LwwRegister`;
- materializar estado a partir de CRDTs;
- manter adaptador para `Operation` até migração do sync;
- testar reordenação, repetição e concorrência.

Estado: concluída para LWW; `Operation` permanece como adaptador legado.

### Etapa 3 — Migrar `SyncEngine`

- trocar `PendingDeltaStore` por `ReplicaStorage` como caminho principal;
- persistir estado e outbox na mesma operação lógica;
- aplicar deltas remotos e persistir resultado;
- separar enviado de confirmado;
- impedir múltiplos `start()` e fechar lifecycle de `dispose()`.

Estado: concluída no caminho `ReplicaStorage`; atomicidade transacional real continua pendente.

### Etapa 4 — Identidade e causalidade

- formalizar `ReplicaId`, `Dot` e sequência local;
- implementar avanço/restauração de HLC;
- usar `VectorClock` apenas onde causalidade exige;
- definir envelopes e IDs de transporte.

Estado: parcial. `ReplicaId`, `Dot`, sequência local, avanço/restauração de HLC, codec e envelope versionados implementados; contrato de transporte ainda aceita `Delta` diretamente.

### Etapa 5 — CRDTs adicionais

Implementar e testar, nesta ordem:

1. `G-Counter`;
2. `PN-Counter`;
3. `G-Set`;
4. `MV-Register`;
5. `2P-Set`;
6. `OR-Set`;
7. `OR-Map`.

Estado: parcial. `G-Counter` e `PN-Counter` implementados e testados, incluindo
sequência causal após restauração; próximos
na fila: `G-Set`, `MV-Register`, `2P-Set`, `OR-Set` e `OR-Map`.

### Etapa 6 — Composição e persistência

- `ObjectCrdt` com campos identificados por IDs estáveis;
- política add/update-wins;
- snapshots versionados;
- tombstones e compactação conservadora;
- adaptador SQLite opcional;
- testes de recuperação após reinício.

## 5. Primeiro incremento desta refatoração

Implementar `DeltaChange` e lote de deltas CRDT compatível com `Delta` legado.
Critérios:

- mudança CRDT possui ID próprio;
- lote aceita reordenação e repetição;
- merge não exige conhecer tipo concreto do CRDT;
- `Operation` continua funcionando sem alteração imediata no sync;
- tipo da mudança é preservado no payload; codec versionado completo fica na
  próxima subetapa.

Próxima tarefa após esse incremento: migrar mutação `Replica.set/remove` para
produzir `LwwDelta` e adaptar `ReplicaState`.

## 6. Validação final

- `dart analyze` sem issues;
- testes unitários de cada CRDT;
- testes de propriedade para associatividade, comutatividade e idempotência;
- testes de integração com reordenação, duplicação e perda de conexão;
- restauração de snapshot e outbox após reinício;
- nenhuma dependência de banco em `deltasync_core` ou `deltasync_sync`.
