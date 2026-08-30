# Plano de Desenvolvimento — DeltaSync

## Diagnóstico

## Estado verificado

Verificação realizada em 2026-08-30:

### Feito

- [x] Workspace modular com `deltasync_core`, `deltasync_sync`, `deltasync_storage` e `deltasync_transport`.
- [x] Core sem dependências de banco, Flutter ou rede.
- [x] Transporte definido por contrato independente de implementação.
- [x] `VectorClock` com tick, merge, comparação e JSON.
- [x] `Operation` e `Delta` com deduplicação por identificador.
- [x] Réplica com operações LWW de set/remove e aplicação idempotente.
- [x] `SyncEngine` básico para mutação local, recuperação de deltas pendentes, recebimento remoto e push.
- [x] Testes básicos de relógio, serialização de operação, convergência, remoção, duplicação e lifecycle.

### Parcial

- [~] `ARCH-04`: `Operation` possui `toJson`/`fromJson`, mas não há codec formal de `Delta` nem envelope de transporte.
- [~] `CORE-01`: identificadores e operações existem, mas geração, persistência e política de IDs ainda não estão formalizadas.
- [~] `SYNC-01`: `start()` restaura outbox como operações aplicadas; snapshot materializado ainda não existe.
- [~] `SYNC-03`: deltas remotos são aplicados em memória, sem persistência.
- [~] `SYNC-07`: cancelamento da assinatura existe; lifecycle completo e segurança contra múltiplos `start()` ainda não foram definidos.

### Pendente

- [ ] `ARCH-01`: modelos persistíveis completos e codec de storage.
- [ ] `ARCH-03`: ciclo de vida de outbox, estados enviados e confirmação.
- [ ] `ARCH-06` a `ARCH-08`: política de snapshots/tombstones e contrato de geração de código.
- [ ] `CORE-02` a `CORE-14`, exceto relógio/operações básicos já listados acima.
- [ ] `STORE-01` a `STORE-08`: `MemoryStorage` orientado a réplica, snapshots, metadados, recuperação e testes de contrato.
- [ ] `SYNC-02`, `SYNC-04` a `SYNC-06`, `SYNC-08` a `SYNC-10`: persistência completa, confirmação explícita, retry, envelopes e compactação segura.
- [ ] Fases 4.5, 5 e 6: geração de código, adaptador SQLite e validação acadêmica.

### Validação

- `dart analyze`: passou sem issues.
- `dart test`: não concluiu no ambiente atual; processo ficou sem saída por mais de 12 segundos. Execução também encontrou tentativa do SDK de gravar telemetria em `/home/yago/.dart-tool`, caminho somente leitura.

`ARCH-02` possui implementação inicial, mas persistência fica temporariamente
adiada. Próximo task definido: `CORE-03`.

Nota de escopo: `MemoryStorage` é implementação volátil para testes, exemplos e
protótipos. Não fornece persistência após reinício. Produção exige adaptador
persistente que implemente `ReplicaStorage`.

Decisão de persistência: cada dispositivo persiste somente sua própria réplica.
Não armazenar estados completos de outras réplicas. O modelo lógico inicial
possui três tabelas: `replicas`, `state_entries` e `outbox`. `VectorClock` pode
conter IDs e contadores remotos para preservar causalidade, mas isso não
representa o estado remoto completo. Histórico de operações e confirmações por
participante são extensões opcionais para auditoria, replay e compactação
segura.

Repriorização: não integrar `ReplicaStorage` ao `SyncEngine` nem criar adaptador
SQLite antes de fechar formato de snapshot, tombstones e deduplicação após
reinício. O contrato atual deve ser tratado como baseline revisável.

Nova prioridade: estabilizar primeiro estrutura, operações e regras de merge dos
CRDTs. Persistência, outbox durável e adaptadores ficam depois que o núcleo
conseguir demonstrar convergência, idempotência, comutatividade e restauração
em memória.

Escopo inicial de CRDTs: `LWW-Register`, `G-Counter` e `PN-Counter`. Esses tipos
cobrem registro com conflito determinístico, incremento distribuído e contador
com incremento/decremento. Depois, entram `G-Set`, `MV-Register`, `2P-Set`,
`OR-Set` e `OR-Map`, todos com metadados necessários para merge, causalidade,
deduplicação e, quando aplicável, deleção.

### Confirmado

- Workspace Dart com pacotes:
  - `deltasync_core`
  - `deltasync_sync`
  - `deltasync_storage`
  - `deltasync_transport`
- Core sem dependência de Flutter, banco ou rede.
- Transporte já está desacoplado.
- Storage não depende de `sqflite`.
- CRDT atual é apenas LWW por chave.
- `SyncEngine` já coordena réplica, outbox e transporte.
- Testes atuais cobrem convergência simples, remoção e duplicação.

### Lacunas principais

- Storage persiste apenas `Delta` pendente.
- Estado consolidado não é persistido.
- Metadados da réplica não são persistidos.
- Deltas remotos aplicados não são persistidos.
- Recuperação após reinício ainda não existe.
- `push()` limpa outbox imediatamente após `send()`.
- Não há confirmação explícita de entrega.
- Não há serialização formal.
- Não há envelopes de delta.
- Core implementa somente LWW.
- Não há estratégia definida para snapshots, compactação e tombstones.
- Não há geração de código para modelos CRDT.
- Não há testes contra múltiplos adaptadores.
- Não há `sqflite`, nem deve ser dependência obrigatória.

## Decisão arquitetural recomendada

Separar contrato de storage de implementação de banco.

```text
deltasync_core
  Replica
  CRDTs
  Delta
  metadados
  serialização de domínio

deltasync_codegen
  anotações de modelo
  geração via build_runner
  serialização e integração de CRDTs

deltasync_storage
  contratos de persistência
  modelos persistíveis
  MemoryStorage para testes

deltasync_storage_sqflite
  adaptador opcional
  dependência sqflite isolada

deltasync_sync
  SyncEngine
  outbox
  aplicação remota
  confirmação de entrega

deltasync_transport
  contrato de envio e recebimento

aplicação
  escolhe banco
  escolhe transporte
  define autenticação e backend
```

### Dados persistidos

Storage não deve guardar somente deltas. Modelo recomendado:

- `ReplicaSnapshot`: estado materializado atual da réplica;
- deltas recentes e ainda necessários para sync ou recuperação;
- outbox durável para operações locais não confirmadas;
- metadados da réplica, como `actorId`, `operationId`, relógio lógico ou HLC;
- tombstones, quando deleções precisarem ser lembradas.

O storage local não precisa guardar estados completos das demais réplicas.
Metadados remotos no `VectorClock`, operações vencedoras e tombstones bastam
para reconstruir e continuar a réplica local. Histórico completo de operações
é opcional e depende do protocolo de sincronização.

Deltas antigos podem ser compactados em novo snapshot após retenção e confirmação adequadas. Objetivo: recuperar estado sem replay infinito, sem perder informação necessária para convergência.

### Modelagem e geração de código

Usuário deve declarar modelos e escolher tipos CRDT conhecidos; biblioteca gera boilerplate:

```dart
@CrdtModel()
class Note {
  @CrdtField()
  String title;

  @CrdtField()
  String content;
}
```

`build_runner` é recomendado para gerar serialização, desserialização, IDs estáveis de campos, aplicação de operações, merge e snapshots. Não é obrigatório: API manual deve existir para modelos dinâmicos ou casos avançados.

IDs de campos devem ser estáveis e não depender da ordem ou posição das propriedades. Renomear ou reordenar código não pode invalidar dados persistidos.

Tipos iniciais previstos: `CrdtRegister`, `CrdtCounter`, `CrdtSet` e `CrdtMap`. Usuário não deve implementar manualmente clocks, merge ou resolução de conflito para tipos suportados.

### Contrato sugerido

Substituir `PendingDeltaStore` por algo próximo de:

```dart
abstract interface class ReplicaStorage {
  Future<ReplicaSnapshot?> loadReplica(String replicaId);

  Future<void> saveReplica(ReplicaSnapshot snapshot);

  Future<void> enqueue(OutboxEntry entry);

  Future<List<OutboxEntry>> pending(String replicaId);

  Future<void> acknowledge(
    String replicaId,
    Iterable<String> operationIds,
  );
}
```

Modelos mínimos:

- `ReplicaSnapshot`
  - identificador da réplica;
  - estado serializado;
  - relógio lógico;
  - metadados necessários para recuperação.
- `OutboxEntry`
  - identificador da operação;
  - delta;
  - estado: pendente, enviado ou confirmado;
  - tentativas;
  - timestamp local.
- `StorageCodec`
  - conversão entre objetos da biblioteca e `Map<String, Object?>`.

Contrato não deve conhecer:

- `Database`;
- `sqflite`;
- tabelas;
- SQL;
- Hive;
- Isar;
- arquivos;
- Flutter.

Cada adaptador traduz esses modelos para seu mecanismo.

Storage e transporte são extensões do usuário; engine CRDT e regras de merge permanecem na biblioteca. Fornecer `MemoryStorage` e transporte fake para testes. Adaptadores SQLite, HTTP, WebSocket ou outro backend ficam em pacotes separados.

## Regra importante sobre storage

Não criar uma abstração genérica demais, como:

```dart
Future<Object?> get(String key);
Future<void> set(String key, Object value);
```

Isso empurra toda lógica para `SyncEngine`, dificulta atomicidade e reduz clareza acadêmica.

Melhor contrato orientado ao domínio:

- carregar réplica;
- salvar snapshot;
- enfileirar delta;
- listar pendências;
- confirmar entrega.

Assim, SQLite, Hive, Isar, arquivos ou outro banco podem implementar o mesmo contrato.

## Fases de desenvolvimento

### Fase 1 — Fundação arquitetural

Objetivo: estabilizar contratos antes de adicionar CRDTs.

Tarefas:

- `ARCH-01` — definir modelos persistíveis.
- `ARCH-02` — definir contrato `ReplicaStorage`.
- `ARCH-03` — definir ciclo de vida de outbox.
- `ARCH-04` — definir serialização de delta.
- `ARCH-05` — registrar decisões arquiteturais.
- `ARCH-06` — definir política de snapshot, retenção, compactação e tombstones.
- `ARCH-07` — definir contrato de modelos CRDT e IDs estáveis de campos.
- `ARCH-08` — decidir escopo inicial de geração via `build_runner` e API manual.

Gate:

- contratos documentados;
- sem dependência de banco;
- testes compilando;
- decisão sobre confirmação de entrega registrada.

Status: `IN_PROGRESS` — contrato inicial de storage criado; modelo persistível e
ciclo completo de outbox ainda pendentes.

### Fase 2 — Core CRDT e metadados

Objetivo: tornar núcleo correto e extensível.

Ordem recomendada:

1. `CORE-01` — identificadores e operações.
2. `CORE-02` — relógio lógico ou HLC.
3. `CORE-03` — contrato comum de CRDT.
4. `CORE-04` — LWW Register.
5. `CORE-05` — G-Counter.
6. `CORE-06` — PN-Counter.
7. `CORE-07` — G-Set.
8. `CORE-08` — MV-Register.
9. `CORE-09` — 2P-Set.
10. `CORE-10` — OR-Set.
11. `CORE-11` — OR-Map.
12. `CORE-12` — serialização.
13. `CORE-13` — snapshot materializado e restauração.
14. `CORE-14` — compactação de deltas e retenção de tombstones.

Sequências ficam depois desse conjunto inicial.

Metadados obrigatórios por implementação:

- `LWW-Register`: timestamp lógico ou `VectorClock`, `replicaId`, `operationId`
  e tombstone quando houver remoção.
- `MV-Register`: versões concorrentes, causalidade e identificadores das
  operações mantidas.
- `G-Counter` e `PN-Counter`: componentes por réplica e identificadores de
  operação quando necessários para deduplicação.
- `G-Set`: elementos adicionados e metadados de origem/operação.
- `2P-Set`: conjunto de adições, conjunto de remoções e metadados de operação.
- `OR-Set`: tags únicas por adição, conjunto de remoções e causalidade.
- `OR-Map`: chaves, valores CRDT aninhados, identificadores e tombstones.

Gate:

- testes de convergência;
- idempotência;
- associatividade;
- comutatividade quando aplicável;
- duplicação;
- reordenação;
- serialização e desserialização.

## Próximo task aprovado

`CORE-03 — Definir contrato comum de CRDT`.

Objetivo: definir estrutura comum para CRDTs, operações e aplicação de merge
antes de introduzir persistência.

Escopo:

- revisar interface `Crdt<T>` e ciclo `apply(operation)`;
- separar operação comum de regras específicas de cada CRDT;
- definir registro de operações já aplicadas em memória;
- definir comportamento para operação duplicada, atrasada e concorrente;
- definir como `Replica` registra operações locais e aplica remotas;
- preparar estrutura para `LWW Register`, sem implementar todos os CRDTs ainda.

Acceptance criteria:

- [ ] contrato comum documentado;
- [ ] operação carrega identidade, origem, causalidade e payload;
- [ ] CRDT ignora operação duplicada sem alterar resultado;
- [ ] operações concorrentes têm resolução determinística quando aplicável;
- [ ] testes de aplicação em ordens diferentes definidos;
- [ ] contrato não depende de storage ou transporte.

Depois de `CORE-03`:

1. executar `CORE-04` para LWW Register;
2. executar `CORE-05` para G-Counter;
3. executar `CORE-06` para PN-Counter;
4. validar propriedades do núcleo e dos counters;
5. voltar a `ARCH-01` para definir snapshot baseado no modelo real.

Critérios específicos dos counters:

- `CORE-05` — `G-Counter`: cada réplica incrementa somente seu componente;
  merge usa máximo por réplica; valor é soma dos componentes; operações são
  idempotentes e independem da ordem.
- `CORE-06` — `PN-Counter`: usa componentes positivos e negativos; incremento
  altera componente positivo; decremento altera componente negativo; merge usa
  máximo por componente; valor é `positive - negative`.

### Fase 3 — Storage independente de banco

Objetivo: provar que Sync e Core não dependem de implementação específica.

Tarefas:

- `STORE-01` — `MemoryStorage`.
- `STORE-02` — persistência de snapshot.
- `STORE-03` — persistência de outbox.
- `STORE-04` — recuperação após reinício simulado.
- `STORE-05` — testes de contrato para qualquer adaptador.
- `STORE-06` — documentação para criação de adaptador externo.
- `STORE-07` — persistir e restaurar metadados da réplica.
- `STORE-08` — testar snapshot mais deltas recentes após reinício.

Gate:

- substituir storage sem alterar `deltasync_core`;
- substituir storage sem alterar `deltasync_sync`;
- recuperar estado e pendências;
- executar mesma suíte contra adaptador em memória.

### Fase 4 — Sync robusto

Objetivo: fechar fluxo local, remoto e recuperação.

Tarefas:

- `SYNC-01` — carregar snapshot no `start()`.
- `SYNC-02` — salvar mutação local.
- `SYNC-03` — aplicar delta remoto e persistir.
- `SYNC-04` — controlar confirmação de entrega.
- `SYNC-05` — evitar perda de delta em falha de envio.
- `SYNC-06` — tratar duplicação e reordenação.
- `SYNC-07` — lifecycle de `start()` e `dispose()`.
- `SYNC-08` — envelopes de transporte.
- `SYNC-09` — sincronizar deltas sem descartar outbox antes de confirmação.
- `SYNC-10` — executar compactação sem remover operações ainda necessárias.

### Fase 4.5 — Geração de código

Objetivo: permitir que usuário declare modelos e execute `build_runner` para gerar integração CRDT.

Tarefas:

- `GEN-01` — anotações de modelo e campo;
- `GEN-02` — IDs estáveis e compatibilidade com evolução de schema;
- `GEN-03` — gerar codecs, snapshots e adaptadores de modelo;
- `GEN-04` — manter API manual para casos avançados;
- `GEN-05` — exemplo completo com modelo anotado.

Gate:

- modelo gerado converte para snapshot e operações;
- operações geradas são idempotentes;
- mudança de ordem dos campos não altera IDs;
- API gerada não exige dependência de banco ou transporte.

Gate:

```text
alteração local
persistência
reinício
recuperação
envio
falha
reenvio
confirmação
aplicação remota
convergência
```

Ponto crítico: `push()` não deve apagar pendência apenas porque `send()` terminou. Isso só é seguro quando `send()` representa confirmação de entrega. Caso contrário, manter delta até confirmação explícita.

### Fase 5 — Adaptador SQLite opcional

Objetivo: fornecer implementação prática sem contaminar arquitetura.

Criar pacote separado:

```text
packages/deltasync_storage_sqflite/
```

Esse pacote conteria:

- dependência `sqflite`;
- schema;
- migrações;
- implementação de `ReplicaStorage`;
- testes de integração específicos.

`sqflite` não entra em:

- `deltasync_core`;
- `deltasync_sync`;
- contrato principal de storage;
- facade obrigatória, caso isso force dependência Flutter.

Gate:

- testes do adaptador;
- recuperação após reabertura;
- persistência de snapshot;
- outbox;
- migração inicial documentada.

### Fase 6 — Validação acadêmica e demonstração

Objetivo: produzir evidência para o TCC.

Tarefas:

- aplicação de demonstração;
- teste com duas réplicas;
- teste offline;
- teste com transporte em memória;
- teste de recuperação;
- teste de duplicação;
- teste de reordenação;
- relatório de limitações;
- documentação da API;
- matriz requisito, código, teste e evidência.

## MoSCoW inicial

| Item | Classificação |
|---|---|
| LWW Register correto | MUST |
| Delta idempotente | MUST |
| Storage abstrato | MUST |
| MemoryStorage | MUST |
| Persistência de snapshot | MUST |
| Outbox durável | MUST |
| Recuperação após reinício | MUST |
| Transporte abstrato | MUST |
| Testes de convergência | MUST |
| Testes de contrato de storage | MUST |
| G-Counter | MUST |
| PN-Counter | SHOULD |
| G-Set | SHOULD |
| OR-Set | SHOULD |
| OR-Map | SHOULD |
| Adaptador `sqflite` | SHOULD |
| MV-Register | COULD |
| 2P-Set | COULD |
| OR-Seq/OR-Seg | WON'T-YET |
| Backend próprio | WON'T-YET |
| Autenticação | WON'T-YET |
| Protocolo HTTP/WebSocket | WON'T-YET |
| Transações distribuídas | WON'T-YET |
| Todos os bancos locais | WON'T-YET |

“Vários bancos” significa “contrato implementável por vários bancos”, não implementação de todos os bancos existentes.

## RICE adaptado

Escalas:

- Reach: 1–5, impacto no núcleo do TCC.
- Impact: 1–5, valor técnico e acadêmico.
- Confidence: `0,5`, `0,75` ou `1`.
- Effort: número estimado de tarefas equivalentes.

Fórmula:

```text
RICE = Reach × Impact × Confidence / Effort
```

Prioridade inicial:

1. contrato de storage;
2. persistência de snapshot;
3. outbox confiável;
4. testes de convergência;
5. serialização;
6. recuperação;
7. sync completo;
8. CRDTs adicionais;
9. adaptador SQLite;
10. funcionalidades experimentais.

RICE não pode ultrapassar dependências. Exemplo: `STORE-06` pode ter score alto, mas depende de `ARCH-02`.

## Agentes recomendados

- `architect`: contratos, limites de pacote, decisões públicas.
- `planner`: fases, MoSCoW, RICE, dependências e escopo.
- `implementer`: uma tarefa aprovada por vez.
- `reviewer`: revisão de diff, compatibilidade e riscos.
- `validator`: testes, análise estática e gates.
- `plan-maintainer`: status, rastreabilidade, decisões e riscos.
- `crdt-specialist`: propriedades matemáticas, metadados e convergência.
- `storage-adapter`: contratos, adaptadores e recuperação.
- `sync-reliability`: outbox, confirmação, retries e lifecycle.
- `documentation`: API pública, exemplo e evidências do TCC.

## Arquivos planejados

Não criar esses arquivos antes de aprovação explícita.

```text
AGENTS.md

plan/
├── README.md
├── 01_SCORING.md
├── 02_PHASE1_ARCHITECTURE.md
├── 03_PHASE2_CORE_CRDT.md
├── 04_PHASE3_STORAGE.md
├── 05_PHASE4_SYNC.md
├── 06_PHASE5_SQLITE_ADAPTER.md
├── 07_PHASE6_VALIDATION.md
├── TRACEABILITY.md
├── DECISIONS.md
└── RISKS.md

.agents/
├── agents/
│   ├── architect.md
│   ├── planner.md
│   ├── implementer.md
│   ├── reviewer.md
│   ├── validator.md
│   ├── plan-maintainer.md
│   ├── crdt-specialist.md
│   ├── storage-adapter.md
│   ├── sync-reliability.md
│   └── documentation.md
└── skills/
    ├── plan-reader/SKILL.md
    ├── plan-implementer/SKILL.md
    ├── plan-validator/SKILL.md
    ├── plan-maintainer/SKILL.md
    ├── code-reviewer/SKILL.md
    ├── crdt-validation/SKILL.md
    ├── storage-adapter-validation/SKILL.md
    └── sync-recovery-validation/SKILL.md
```

## Task anterior — `ARCH-02`

Contrato inicial de storage orientado ao domínio.

Acceptance criteria atendidos na implementação inicial:

- [x] contrato não importa `sqflite`;
- [x] contrato não conhece SQL;
- [x] snapshot pode ser salvo e carregado;
- [x] outbox pode ser enfileirada;
- [x] pendências podem ser consultadas;
- [x] operações podem ser confirmadas;
- [x] `MemoryStorage` implementa contrato;
- [x] testes de contrato criados;
- [x] decisão registrada neste plano: storage orientado ao domínio, com adaptadores externos.

Depois:

`STORE-02`, `STORE-03`, `SYNC-01`, `SYNC-03`.

A maior correção em relação à proposta original é trocar “persistência SQLite” por “contrato de persistência com adaptadores”. SQLite vira evidência prática, não fundamento arquitetural.
