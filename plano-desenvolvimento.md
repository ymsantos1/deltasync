# Plano de Desenvolvimento — DeltaSync

## 1. Objetivo do plano

Este plano organiza o desenvolvimento da DeltaSync, uma biblioteca Dart voltada a aplicações Flutter offline-first, baseada em CRDTs e sincronização incremental por Delta-CRDTs.

A arquitetura deve permitir:

- atualização local sem dependência imediata de rede;
- convergência determinística entre réplicas;
- geração e aplicação incremental de deltas;
- persistência durável do estado local, metadados causais e deltas pendentes;
- retomada após reinicialização ou falha;
- transporte desacoplado da lógica de CRDT;
- suporte a diferentes mecanismos de armazenamento por adaptadores;
- composição de objetos com múltiplos campos CRDT;
- API pública utilizável manualmente e, posteriormente, por geração de código.

O servidor remoto não é autoridade obrigatória. Pode atuar apenas como relay, intermediário de transporte ou persistência remota, conforme a aplicação integradora.

---

## 2. Decisões arquiteturais consolidadas

### 2.1 Delta-CRDT é a abstração central

A biblioteca deve ser orientada a Delta-CRDTs.

A mutação local deve seguir conceitualmente o fluxo:

```text
mutação local
    ↓
atualiza estado local
    +
gera delta
    ↓
persistência local + outbox
    ↓
transporte
    ↓
outra réplica
    ↓
join(state, delta)
```

A semântica fundamental é:

```text
State ∨ Delta → State
```

A correção não deve depender de reproduzir uma sequência de comandos remotos.

`Operation` pode existir como representação interna de intenção, auditoria, API de mutação ou conveniência de implementação, mas não deve ser a unidade fundamental do protocolo de sincronização.

Para cada CRDT baseado em delta devem valer, quando aplicável, as propriedades de join:

- associatividade;
- comutatividade;
- idempotência;
- convergência eventual entre réplicas que recebem o mesmo conjunto de informações.

A aplicação repetida do mesmo delta deve ser segura por construção do CRDT, independentemente de deduplicação externa por identificador.

### 2.2 Separação entre identidade causal e identidade de mensagem

Não utilizar `OperationId` como mecanismo fundamental para garantir correção matemática do CRDT.

Separar:

- identidade causal da alteração, como `Dot(replicaId, counter)`;
- contexto causal conhecido pela réplica;
- identidade do delta/envelope para transporte, retry, ACK, tracing ou auditoria.

`OperationId` ou `DeltaId` pode existir para o protocolo e para a outbox, mas a idempotência do join deve permanecer propriedade do CRDT.

### 2.3 Relógios e causalidade

Não utilizar `VectorClock` como mecanismo de desempate do `LWW-Register`.

Política inicial:

- `LWW-Register`: usar `HlcTimestamp` e `ReplicaId` como desempate determinístico;
- `MV-Register`: usar contexto causal, dots e/ou VectorClock para preservar versões concorrentes;
- `OR-Set`: usar tags/dots únicos e contexto causal;
- `OR-Map`: usar dots/contexto causal e CRDTs aninhados;
- `G-Counter` e `PN-Counter`: componentes indexados por `ReplicaId`;
- `VectorClock`: representar principalmente o conhecimento causal da réplica e apoiar reconciliação, detecção de lacunas e estruturas que exigem causalidade explícita.

O projeto não deve assumir que um único mecanismo de relógio é adequado a todos os CRDTs.

### 2.4 Política de remoção concorrente

Para objetos compostos, a política escolhida é:

```text
add/update-wins
```

Se uma remoção concorrer causalmente com uma criação ou atualização que a remoção ainda não observou, a criação/atualização concorrente prevalece.

Se a remoção observar causalmente a versão atualizada, a remoção prevalece sobre aquela versão.

Essa política deve ser refletida na estrutura externa de existência do objeto, preferencialmente baseada em OR-Set/OR-Map com semântica add-wins.

### 2.5 Persistência desacoplada do banco

`deltasync_core` e `deltasync_sync` não devem depender de `sqflite`, SQL, Hive, Isar, arquivos ou Flutter.

O contrato de persistência deve ser orientado ao domínio da biblioteca.

Implementações previstas:

- `MemoryStorage`: testes, exemplos e protótipos;
- `deltasync_storage_sqflite`: adaptador opcional e persistente.

### 2.6 Estado local da réplica

Cada dispositivo persiste somente sua própria réplica materializada.

Não armazenar cópias completas do estado de todas as outras réplicas.

É permitido persistir conhecimento remoto necessário à causalidade, como:

- componentes de `VectorClock`;
- dots observados;
- tombstones;
- contexto causal;
- resumo de conhecimento necessário ao protocolo.

Isso não representa persistência do estado completo remoto.

### 2.7 Todos os CRDTs previstos permanecem no escopo

Tipos obrigatórios no projeto:

- `LWW-Register`;
- `MV-Register`;
- `G-Counter`;
- `PN-Counter`;
- `G-Set`;
- `2P-Set`;
- `OR-Set`;
- `OR-Map`.

Sequências, como OR-Seq/OR-Seg, permanecem como extensão posterior.

---

## 3. Estado atual verificado

Verificação de referência: 2026-08-30.

### Feito

- [x] Workspace modular com `deltasync_core`, `deltasync_sync`, `deltasync_storage` e `deltasync_transport`.
- [x] Core sem dependências de banco, Flutter ou rede.
- [x] Transporte definido por contrato independente de implementação.
- [x] `VectorClock` com tick, merge, comparação e JSON.
- [x] Estruturas iniciais de `Operation` e `Delta`.
- [x] Implementação inicial de LWW set/remove.
- [x] `SyncEngine` básico para mutação local, deltas pendentes, recebimento remoto e push.
- [x] Testes básicos de relógio, serialização, convergência, remoção e duplicação.
- [x] Contrato inicial `ReplicaStorage` sem dependência de `sqflite`.
- [x] Implementação inicial de `MemoryStorage`.

### Parcial

- [~] O núcleo ainda possui desenho excessivamente orientado a `Operation`; deve ser corrigido para Delta-CRDT.
- [~] `Operation` possui serialização, mas falta codec formal e versionado de delta.
- [~] IDs existem, mas lifecycle de `ReplicaId`, `Dot` e contadores ainda precisa ser formalizado.
- [~] `start()` recupera dados parciais, mas snapshot materializado ainda não fecha o fluxo completo.
- [~] Deltas remotos são aplicados em memória, mas persistência do estado resultante ainda precisa ser fechada.
- [~] Lifecycle completo de `start()`/`dispose()` precisa ser estabilizado.

### Pendente principal

- [ ] contrato formal `DeltaCrdt`;
- [ ] composição de objetos CRDT;
- [ ] lifecycle de identidade da réplica;
- [ ] snapshots completos e versionados;
- [ ] persistência atômica de mutação + outbox;
- [ ] reconciliação causal entre réplicas;
- [ ] semântica definitiva de ACK;
- [ ] política segura de compactação/tombstones;
- [ ] codecs e envelopes versionados;
- [ ] adaptador SQLite;
- [ ] codegen;
- [ ] validação acadêmica completa.

---

## 4. Arquitetura de pacotes

```text
deltasync_core
  Replica
  DeltaCrdt
  CRDTs
  deltas
  metadados causais
  HLC
  VectorClock
  Dot
  snapshots de domínio
  serialização de domínio


deltasync_storage
  ReplicaStorage
  modelos persistíveis
  transações lógicas de persistência
  MemoryStorage
  codecs de storage


deltasync_sync
  SyncEngine
  outbox
  envelopes
  retry
  ACK
  aplicação remota
  reconciliação causal
  compactação coordenada


deltasync_transport
  contrato de envio
  contrato de recebimento
  sem protocolo obrigatório


deltasync_storage_sqflite
  schema SQLite
  migrations
  implementação ReplicaStorage


deltasync_codegen
  anotações
  build_runner
  codecs de modelo
  integração de ObjectCrdt


aplicação Flutter
  escolhe storage
  escolhe transporte
  define autenticação
  define autorização
  define backend/relay
```

---

## 5. Modelo central de Delta-CRDT

### 5.1 Contrato conceitual

O contrato comum deve representar estado e delta como elementos compatíveis com a operação de join.

Exemplo conceitual, sujeito à implementação Dart definitiva:

```dart
abstract interface class DeltaCrdt<V, D> {
  V get value;

  D mutate(/* mutação específica */);

  void applyDelta(D delta);

  void mergeState(covariant DeltaCrdt<V, D> other);

  Map<String, Object?> toJson();
}
```

Não é obrigatório que todos os CRDTs exponham exatamente a mesma assinatura de mutação.

O contrato comum deve padronizar:

- leitura do valor;
- aplicação de delta;
- merge de estado completo;
- geração de representação persistível;
- restauração;
- acesso aos metadados necessários ao tipo.

### 5.2 Relação entre `Operation` e `Delta`

`Operation` não deve ser o elemento recebido obrigatoriamente por todos os CRDTs.

Modelo recomendado:

```text
API de mutação
    ↓
Operation opcional/interna
    ↓
CRDT atualiza estado
    ↓
CRDT produz Delta
    ↓
Delta é persistido/enviado
```

O receptor deve conseguir convergir a partir do delta sem depender da reprodução de comandos em ordem exata.

---

## 6. Composição de objetos CRDT

### 6.1 Objetivo

Permitir que aplicações representem objetos de domínio compostos por campos com diferentes semânticas CRDT.

Exemplo:

```text
Note(123)
├── existência → OR-Map / OR-Set add-wins
├── title      → LWW-Register<String>
├── content    → LWW-Register<String>
├── likes      → G-Counter
└── tags       → OR-Set<String>
```

### 6.2 Estrutura conceitual

Cada objeto deve possuir:

- `objectId` estável;
- tipo lógico do modelo;
- mapa de campos identificados por IDs estáveis;
- CRDT associado a cada campo;
- metadados necessários para existência e causalidade;
- capacidade de gerar deltas endereçados a objeto/campo.

Exemplo de caminho lógico de delta:

```text
model = Note
objectId = 123
fieldId = title
crdtType = lww_register
payload = <delta do campo>
```

### 6.3 Existência de objetos

A existência dos objetos deve ser controlada por uma estrutura observada com semântica add-wins, preferencialmente OR-Map ou composição equivalente.

Não usar simples booleano `deleted` como única fonte de verdade distribuída.

### 6.4 Política add/update-wins

Cenário:

```text
Replica A: remove Note(123)
Replica B: atualiza Note(123).title
```

Se as ações forem concorrentes, a atualização preserva/ressuscita logicamente o objeto conforme a semântica add-wins.

Se A remover depois de já ter observado a atualização de B, a remoção pode prevalecer sobre aquela versão observada.

Essa regra deve ser validada por testes explícitos.

### 6.5 CRDTs aninhados

`OR-Map` deve permitir valores que também sejam CRDTs.

O merge deve ocorrer em dois níveis:

1. existência/identidade da chave;
2. merge do CRDT associado ao valor.

### 6.6 Tarefas de composição

- `COMP-01` — definir `ObjectId` estável;
- `COMP-02` — definir `FieldId` estável e independente da ordem das propriedades;
- `COMP-03` — definir `ObjectCrdt` ou abstração equivalente;
- `COMP-04` — gerar delta endereçado a objeto e campo;
- `COMP-05` — criação e remoção de objetos;
- `COMP-06` — implementar e testar add/update-wins;
- `COMP-07` — CRDTs aninhados;
- `COMP-08` — snapshot/restauração de objetos compostos;
- `COMP-09` — serialização de objetos compostos;
- `COMP-10` — integração da composição com OR-Map.

Gate:

- duas réplicas alteram campos distintos e convergem;
- duas réplicas alteram o mesmo campo e convergem segundo o CRDT daquele campo;
- update concorrente com delete respeita add/update-wins;
- snapshot e restauração preservam a composição completa.

---

## 7. Identidade da réplica e metadados causais

### 7.1 Lifecycle de `ReplicaId`

O melhor momento para criação da réplica será definido na API pública, mas a regra arquitetural deve ser estável:

- `ReplicaId` nasce uma única vez para uma instância persistente da réplica;
- deve ser persistido antes da primeira mutação sincronizável;
- reiniciar a aplicação não cria novo `ReplicaId`;
- limpar os dados locais cria uma nova réplica na próxima inicialização;
- copiar/restaurar uma base em outro dispositivo não deve silenciosamente criar duas réplicas ativas com o mesmo ID.

O comportamento de restore/backup entre dispositivos deve ser documentado como decisão específica antes da fase SQLite.

### 7.2 `Dot`

Modelo recomendado:

```text
Dot = (ReplicaId, counter)
```

O contador local deve:

- ser monotônico;
- sobreviver a reinicializações;
- ser persistido atomicamente com mudanças que dependem dele;
- nunca regredir após restauração normal da mesma réplica.

### 7.3 HLC

`HlcClock` pertence ao estado persistível da réplica.

Usos principais:

- `LWW-Register`;
- ordenação determinística quando semântica LWW for realmente desejada;
- timestamps lógicos de diagnóstico quando útil.

O desempate final do LWW deve ser determinístico, por exemplo:

```text
(HlcTimestamp, ReplicaId)
```

### 7.4 VectorClock

O `VectorClock` deve representar conhecimento causal da réplica.

Usos previstos:

- saber quais eventos/dots já foram observados;
- apoiar reconciliação entre réplicas;
- identificar concorrência em CRDTs que necessitam causalidade;
- permitir detecção de lacunas de conhecimento;
- auxiliar decisões futuras de compactação.

Não usar `VectorClock` para transformar concorrência em uma ordem total artificial no LWW.

---

## 8. Persistência local

### 8.1 Dados persistidos

O storage deve suportar, no mínimo:

- `ReplicaSnapshot`;
- estado dos CRDTs compostos;
- `ReplicaId`;
- contador de dots;
- estado do `HlcClock`;
- `VectorClock`/contexto causal quando necessário;
- tombstones e tags necessários aos tipos;
- outbox durável;
- metadados de versão dos formatos.

### 8.2 Outbox

`OutboxEntry` deve conter, no mínimo:

- identificador do envelope/delta;
- `replicaId` de origem;
- delta serializado;
- destino lógico quando aplicável;
- estado de envio;
- número de tentativas;
- data local de criação;
- dados mínimos necessários para retry/ACK.

Estados possíveis, ainda sujeitos ao protocolo final:

```text
pending
sent
acknowledged
```

`send()` retornar com sucesso não implica automaticamente `acknowledged`.

### 8.3 Atomicidade da mutação local

Uma mutação sincronizável não pode deixar o snapshot atualizado sem o delta correspondente na outbox.

Também não deve deixar uma outbox incompatível com os metadados causais persistidos.

A persistência conceitualmente deve ser atômica sobre:

```text
novo estado/snapshot
+
novo delta/outbox entry
+
novo estado dos clocks/metadados
```

Contrato sugerido:

```dart
abstract interface class ReplicaStorage {
  Future<ReplicaSnapshot?> loadReplica(String replicaId);

  Future<void> persistLocalMutation(LocalMutationCommit commit);

  Future<void> persistRemoteMerge(RemoteMergeCommit commit);

  Future<List<OutboxEntry>> pending(String replicaId);

  Future<void> acknowledge(
    String replicaId,
    Iterable<String> envelopeIds,
  );
}
```

`LocalMutationCommit` pode agrupar:

- snapshot ou alteração persistível;
- outbox entry;
- clocks/metadados atualizados.

A implementação concreta decide como obter atomicidade:

- transação SQL;
- batch atômico;
- mecanismo equivalente do banco escolhido.

### 8.4 Persistência de merge remoto

Receber e aplicar delta remoto também deve persistir atomicamente:

- estado resultante;
- causal context atualizado;
- clocks necessários;
- tombstones/tags gerados ou atualizados.

### 8.5 Contrato orientado ao domínio

Evitar abstrações genéricas como:

```dart
Future<Object?> get(String key);
Future<void> set(String key, Object value);
```

O contrato deve expressar operações da réplica e permitir atomicidade.

---

## 9. Serialização e versionamento

### 9.1 Formatos versionados

Todo formato persistido ou transmitido deve carregar versão suficiente para evolução futura.

Exemplo conceitual:

```json
{
  "schemaVersion": 1,
  "crdtType": "or_set",
  "crdtVersion": 1,
  "payload": {}
}
```

Versionar separadamente, quando necessário:

- envelope;
- delta;
- snapshot;
- estado de CRDT;
- modelo composto.

### 9.2 Regras

- versões desconhecidas não devem ser interpretadas silenciosamente;
- codecs devem falhar de forma explícita e diagnosticável;
- IDs de campos não podem depender da posição das propriedades no código;
- reordenar campos não pode invalidar dados persistidos;
- renomear campo exige estratégia explícita de compatibilidade;
- mudanças de formato devem possuir migration ou quebra de versão documentada.

### 9.3 Tarefas

- `ARCH-09` — versionamento de envelopes;
- `ARCH-10` — versionamento de snapshots;
- `ARCH-11` — versionamento dos codecs de CRDT;
- `ARCH-12` — política de erro para versões incompatíveis;
- `ARCH-13` — estratégia de migração de modelos compostos.

---

## 10. Sincronização e reconciliação

### 10.1 Fluxo mínimo

```text
alteração local
↓
geração de delta
↓
persistência atômica
↓
outbox
↓
envio
↓
recepção
↓
applyDelta / join
↓
persistência remota local
↓
ACK conforme semântica do protocolo
↓
limpeza/compactação quando segura
```

### 10.2 Duplicação e reordenação

O núcleo CRDT deve tolerar:

- delta duplicado;
- chegada fora de ordem;
- retry;
- reconexão.

Não depender da ordenação do transporte para convergência dos tipos cujo modelo matemático não exige essa ordem.

### 10.3 Reconciliação de conhecimento — decisão ainda pendente

Ainda não está fechado como as réplicas descobrirão exatamente quais deltas a outra parte não possui.

Entretanto, o plano deve reservar explicitamente essa responsabilidade.

Direção arquitetural:

- cada réplica mantém um resumo causal do que conhece;
- peers podem trocar esse resumo;
- a diferença de conhecimento permite identificar atualizações ausentes ou necessidade de snapshot.

Exemplo conceitual:

```text
A conhece {A:15, B:8}
B conhece {A:11, B:12}
```

Isso permite detectar que há conhecimento divergente, mas a forma final de mapear esse resumo para deltas armazenados ainda será decidida.

Tarefa:

- `SYNC-11` — definir protocolo de reconciliação causal/anti-entropy.

Acceptance criteria futuros:

- réplica que ficou offline consegue recuperar atualizações ausentes;
- nenhuma réplica depende apenas de mensagens que estavam na outbox no instante da desconexão;
- quando histórico incremental não estiver mais disponível, protocolo pode solicitar snapshot compatível.

### 10.4 Semântica de ACK — decisão ainda pendente

Ainda não definir ACK como "entrega garantida" sem especificar quem confirma o quê.

Possíveis níveis:

- transporte recebeu;
- relay persistiu;
- peer recebeu;
- peer aplicou;
- conjunto de réplicas conhecidas observou.

Nesta etapa, usar o conceito genérico:

```text
DeliveryReceipt / Ack
```

sem fazer compactação destrutiva baseada nele até a semântica ser formalizada.

Tarefa:

- `SYNC-12` — formalizar semântica de ACK para transporte direto e/ou relay.

### 10.5 Tombstones e garbage collection — decisão ainda pendente

Não remover tombstones apenas por idade ou por ACK de envio.

Problema a evitar:

```text
A remove X
B observa remoção
A/B descartam tombstone
C volta após longo período com add antigo de X
→ X pode ressurgir incorretamente
```

Diretriz segura:

- compactação de representação pode existir;
- GC definitivo de informação causal/removal só pode ocorrer quando houver evidência suficiente de que a remoção não pode ser invalidada por uma réplica relevante;
- enquanto essa evidência não estiver formalizada, preservar os metadados necessários.

Tarefas:

- `SYNC-13` — definir pré-condições de GC de tombstones;
- `SYNC-14` — separar compactação lógica de GC causal definitivo.

A implementação acadêmica pode declarar GC completo em topologias arbitrárias como limitação se necessário.

---

## 11. Fases de desenvolvimento

## Fase 1 — Fundação arquitetural

Objetivo: estabilizar conceitos centrais antes de expandir implementação.

### Tarefas

- `ARCH-01` — definir modelos persistíveis completos;
- `ARCH-02` — estabilizar `ReplicaStorage`;
- `ARCH-03` — definir lifecycle inicial da outbox;
- `ARCH-04` — definir codec formal de delta;
- `ARCH-05` — registrar decisões arquiteturais;
- `ARCH-06` — separar compactação de GC de tombstones;
- `ARCH-07` — definir contrato de modelo composto e IDs estáveis;
- `ARCH-08` — manter codegen fora do caminho crítico inicial;
- `ARCH-09` — versionamento de envelope;
- `ARCH-10` — versionamento de snapshot;
- `ARCH-11` — versionamento de codecs;
- `ARCH-12` — comportamento para versões incompatíveis;
- `ARCH-13` — evolução de schema de modelos;
- `ARCH-14` — formalizar Delta-CRDT como abstração central;
- `ARCH-15` — separar identidade causal de identidade de transporte;
- `ARCH-16` — formalizar lifecycle de `ReplicaId` e `Dot`.

### Gate

- contratos documentados;
- core independente de storage/transport;
- modelo Delta-CRDT definido;
- clocks e causalidade com responsabilidades separadas;
- versionamento definido;
- nenhuma decisão destrutiva depende de ACK/GC ainda não formalizados.

---

## Fase 2 — Core CRDT

Objetivo: implementar todos os CRDTs previstos com semântica correta de estado/delta.

### Ordem recomendada

1. `CORE-01` — `ReplicaId`, `Dot`, IDs e metadados;
2. `CORE-02` — `HlcClock` e `VectorClock` com responsabilidades corrigidas;
3. `CORE-03` — contrato comum `DeltaCrdt`;
4. `CORE-04` — LWW-Register;
5. `CORE-05` — G-Counter;
6. `CORE-06` — PN-Counter;
7. `CORE-07` — G-Set;
8. `CORE-08` — MV-Register;
9. `CORE-09` — 2P-Set;
10. `CORE-10` — OR-Set;
11. `CORE-11` — OR-Map;
12. `CORE-12` — serialização versionada;
13. `CORE-13` — snapshot e restauração;
14. `CORE-14` — geração/aplicação de deltas de todos os tipos.

### Requisitos específicos

#### LWW-Register

- HLC como base temporal;
- `ReplicaId` para desempate determinístico;
- não usar VectorClock para criar ordem total;
- delete/tombstone conforme semântica do register.

#### MV-Register

- preservar versões concorrentes;
- remover versões causalmente dominadas;
- usar contexto causal/dots.

#### G-Counter

- componente por réplica;
- incremento apenas do componente local;
- join por máximo por componente;
- valor = soma.

#### PN-Counter

- dois G-Counters lógicos, positivo e negativo;
- join por máximo em cada componente;
- valor = positivo - negativo.

#### G-Set

- apenas adições;
- join por união.

#### 2P-Set

- conjunto de adições;
- conjunto de remoções;
- item removido não retorna.

#### OR-Set

- tags/dots únicos por adição;
- remoção remove apenas adições observadas;
- add concorrente com remove vence.

#### OR-Map

- existência das chaves com semântica observada/add-wins;
- valores são CRDTs aninhados;
- merge preserva estrutura e valores internos.

### Gate

Para todos os tipos aplicáveis:

- convergência;
- associatividade;
- comutatividade;
- idempotência;
- duplicação;
- reordenação;
- serialização/desserialização;
- snapshot/restauração;
- delta repetido não altera resultado;
- merge de estado e aplicação de delta são semanticamente compatíveis.

---

## Fase 2.5 — Composição de objetos

Objetivo: transformar CRDTs individuais em uma base utilizável por modelos de aplicação.

### Tarefas

- `COMP-01` — `ObjectId`;
- `COMP-02` — `FieldId` estável;
- `COMP-03` — `ObjectCrdt`;
- `COMP-04` — delta endereçado a objeto/campo;
- `COMP-05` — criação/remoção;
- `COMP-06` — add/update-wins;
- `COMP-07` — CRDTs aninhados;
- `COMP-08` — snapshot de objeto;
- `COMP-09` — codec de objeto;
- `COMP-10` — integração completa com OR-Map.

### Gate

- modelo composto funciona sem codegen;
- API manual permite criar e alterar objetos;
- duas réplicas convergem com alterações em campos diferentes;
- conflito delete/update respeita add/update-wins;
- modelo sobrevive a snapshot/restauração.

---

## Fase 3 — Storage independente de banco

Objetivo: provar que Core e Sync não dependem de implementação específica.

### Tarefas

- `STORE-01` — estabilizar `MemoryStorage`;
- `STORE-02` — persistência de snapshot;
- `STORE-03` — persistência de outbox;
- `STORE-04` — recuperação após reinício simulado;
- `STORE-05` — suíte de contrato para adaptadores;
- `STORE-06` — documentação para criação de adaptador externo;
- `STORE-07` — persistir/restaurar `ReplicaId`, Dot counter, HLC e contexto causal;
- `STORE-08` — snapshot + deltas recentes após reinício;
- `STORE-09` — persistência atômica de mutação local;
- `STORE-10` — persistência atômica de merge remoto;
- `STORE-11` — testes de falha entre etapas de commit;
- `STORE-12` — persistência de versões de schema/codec.

### Gate

- substituir storage sem alterar core;
- substituir storage sem alterar sync;
- recuperar estado e outbox;
- clocks não regressam após reinício;
- não existe estado local confirmado sem delta necessário para sync;
- falha simulada durante commit não deixa réplica inconsistente.

---

## Fase 4 — Sync robusto

Objetivo: fechar fluxo local, remoto, retry, reconciliação e recuperação.

### Tarefas

- `SYNC-01` — carregar snapshot no `start()`;
- `SYNC-02` — persistir mutação local atomicamente;
- `SYNC-03` — aplicar delta remoto e persistir atomicamente;
- `SYNC-04` — modelo de receipt/ACK sem assumir semântica excessiva;
- `SYNC-05` — retry sem perda de delta;
- `SYNC-06` — duplicação e reordenação;
- `SYNC-07` — lifecycle `start()`/`dispose()`;
- `SYNC-08` — envelopes versionados;
- `SYNC-09` — nunca apagar outbox apenas por sucesso de `send()`;
- `SYNC-10` — compactação sem remover conhecimento ainda necessário;
- `SYNC-11` — protocolo de reconciliação causal/anti-entropy;
- `SYNC-12` — definir semântica final de ACK;
- `SYNC-13` — pré-condições para GC de tombstones;
- `SYNC-14` — separar compactação de GC causal;
- `SYNC-15` — fallback para snapshot quando histórico incremental não for suficiente.

### Gate

Fluxo obrigatório:

```text
alteração local
persistência atômica
reinício
recuperação
envio
falha
retry
recepção remota
aplicação idempotente
persistência remota local
reconciliação
convergência
```

ACK e GC somente entram no gate final quando suas semânticas forem formalizadas.

---

## Fase 5 — Adaptador SQLite opcional

Objetivo: fornecer persistência real sem contaminar a arquitetura principal.

Pacote:

```text
packages/deltasync_storage_sqflite/
```

### Conteúdo

- dependência `sqflite`;
- schema;
- migrations;
- implementação de `ReplicaStorage`;
- transações atômicas;
- codecs;
- testes de integração;
- recuperação após fechamento e reabertura.

### Modelo lógico inicial

Tabelas conceituais:

```text
replicas
state_entries / snapshots
outbox
```

Tabelas adicionais podem surgir para tombstones, índices ou histórico mínimo, desde que permaneçam detalhe do adaptador.

### Gate

- persistência real após reabertura;
- mutação local atômica;
- outbox durável;
- clocks restaurados;
- migração inicial;
- mesma suíte de contrato do `MemoryStorage` passa no SQLite.

---

## Fase 5.5 — Geração de código

Objetivo: melhorar ergonomia depois que composição, storage e sync estiverem estabilizados.

Codegen não é dependência para validar o núcleo da biblioteca.

### API manual primeiro

Antes do codegen, deve ser possível usar:

- CRDTs diretamente;
- `ObjectCrdt`;
- composição de campos;
- storage;
- sync.

### Exemplo futuro

```dart
@CrdtModel()
class Note {
  @CrdtField(type: CrdtFieldType.lwwRegister)
  String title;

  @CrdtField(type: CrdtFieldType.lwwRegister)
  String content;
}
```

### Tarefas

- `GEN-01` — anotações de modelo/campo;
- `GEN-02` — IDs estáveis;
- `GEN-03` — codecs de modelo;
- `GEN-04` — integração com `ObjectCrdt`;
- `GEN-05` — snapshots gerados;
- `GEN-06` — helpers de mutação/delta;
- `GEN-07` — evolução de schema;
- `GEN-08` — exemplo completo.

### Gate

- mudar ordem dos campos não altera IDs;
- modelo gerado é compatível com API manual;
- codegen não introduz dependência de banco ou transporte;
- snapshots antigos possuem tratamento de versão explícito.

---

## Fase 6 — Validação acadêmica e demonstração

Objetivo: produzir evidência experimental do TCC.

### Testes unitários

Para cada CRDT:

- operações locais;
- geração de delta;
- aplicação de delta;
- merge de estados;
- duplicação;
- reordenação;
- serialização;
- snapshot;
- restauração;
- propriedades algébricas aplicáveis.

### Testes de propriedade

Adicionar property-based tests ou testes gerativos equivalentes.

Gerar combinações de:

- réplicas;
- mutações;
- ordens diferentes de entrega;
- deltas duplicados;
- períodos offline;
- retries;
- snapshots intermediários.

Propriedade principal:

```text
Se todas as réplicas recebem eventualmente o mesmo conjunto relevante de deltas,
então convergem para estados equivalentes.
```

Exemplos:

```text
ABC
ACB
BAC
BCA
CAB
CBA
```

### Testes de integração

- alteração local → delta → storage → outra réplica;
- duas réplicas offline e posterior reconciliação;
- três réplicas com alterações concorrentes;
- reinício antes do envio;
- reinício após envio e antes de ACK;
- reinício durante recuperação;
- duplicação de envelope;
- reordenação de deltas;
- delete × update concorrente;
- snapshot seguido de deltas posteriores.

### Testes de falha

Simular falha entre:

```text
mutação
snapshot
outbox
clock update
```

Garantir que a transação local impeça estado impossível.

### Aplicação demonstrativa

Criar aplicação Flutter simples com pelo menos:

- objetos compostos;
- dois ou mais tipos CRDT;
- funcionamento offline;
- persistência SQLite;
- sincronização entre duas réplicas;
- visualização da convergência após reconexão.

### Evidência acadêmica

Manter matriz:

```text
requisito
→ implementação
→ teste
→ resultado/evidência
```

---

## 12. Decisões ainda abertas

Estas decisões não devem ser preenchidas artificialmente antes da implementação fornecer evidência suficiente.

### OPEN-01 — Momento exato de criação da réplica

A regra de lifecycle já está definida, mas a API final ainda precisa decidir se a réplica nasce:

- na criação explícita pelo usuário;
- no primeiro `start()`;
- no primeiro acesso persistente.

Requisito: o ID precisa existir e estar durável antes da primeira mutação sincronizável.

### OPEN-02 — Protocolo de reconciliação

Definir como o resumo causal será transformado em:

- lista de deltas faltantes;
- intervalo de dots;
- solicitação de snapshot;
- outro mecanismo de anti-entropy.

### OPEN-03 — Semântica de ACK

Definir diferença entre:

- recebido pelo transporte;
- persistido pelo relay;
- recebido pelo peer;
- aplicado pelo peer.

Nenhuma limpeza destrutiva deve assumir uma semântica ainda não decidida.

### OPEN-04 — Garbage collection de tombstones

Definir quais evidências causais permitem apagar definitivamente tombstones/tags.

Até lá:

- compactar é permitido;
- perder informação causal necessária não é permitido.

### OPEN-05 — Restore/backup de `ReplicaId`

Definir comportamento ao copiar backup de uma instalação para outro dispositivo para evitar duas réplicas ativas com mesma identidade.

---

## 13. MoSCoW revisado

| Item | Classificação |
|---|---|
| DeltaCrdt correto | MUST |
| LWW-Register | MUST |
| G-Counter | MUST |
| PN-Counter | MUST |
| G-Set | MUST |
| MV-Register | MUST |
| 2P-Set | MUST |
| OR-Set | MUST |
| OR-Map | MUST |
| ObjectCrdt / composição | MUST |
| Add/update-wins | MUST |
| Delta idempotente por join | MUST |
| ReplicaId/Dot persistentes | MUST |
| HLC para LWW | MUST |
| VectorClock/contexto causal | MUST |
| Storage abstrato | MUST |
| MemoryStorage | MUST |
| Persistência de snapshot | MUST |
| Persistência atômica | MUST |
| Outbox durável | MUST |
| Recuperação após reinício | MUST |
| Transporte abstrato | MUST |
| Envelopes versionados | MUST |
| Testes de convergência | MUST |
| Testes de contrato de storage | MUST |
| Property-based/generative tests | MUST |
| Adaptador `sqflite` | MUST |
| Aplicação demonstrativa | MUST |
| Reconciliação causal | MUST |
| Semântica explícita de ACK | SHOULD antes de GC destrutivo |
| GC definitivo de tombstones | SHOULD / pode virar limitação declarada |
| Codegen | SHOULD |
| OR-Seq/OR-Seg | WON'T-YET |
| Backend próprio | WON'T-YET |
| Autenticação | WON'T-YET |
| Autorização | WON'T-YET |
| Protocolo HTTP/WebSocket obrigatório | WON'T-YET |
| Transações distribuídas | WON'T-YET |
| Implementar todos os bancos locais | WON'T-YET |

"Suporte a vários bancos" significa contrato implementável por adaptadores diferentes, não implementação de todos eles.

---

## 14. Ordem de execução revisada

Prioridade recomendada:

1. corrigir abstração central para Delta-CRDT;
2. corrigir uso de HLC/VectorClock;
3. formalizar ReplicaId/Dot;
4. finalizar LWW no modelo corrigido;
5. implementar todos os CRDTs individuais;
6. implementar composição/ObjectCrdt;
7. implementar add/update-wins no modelo composto;
8. fechar snapshot e serialização versionada;
9. estabilizar storage e atomicidade;
10. integrar SyncEngine ao storage;
11. fechar retry/duplicação/reordenação;
12. definir reconciliação causal;
13. implementar SQLite;
14. validar fluxo completo;
15. implementar codegen;
16. executar validação acadêmica final.

Codegen deve ficar depois do mecanismo funcional completo para não estabilizar cedo demais uma API ainda em evolução.

---

## 15. Próximas tarefas recomendadas

Refatoração detalhada e incremental registrada em
`Plano_de_Refatoracao_DeltaSync.md`.

### Próxima tarefa 1 — corrigir `CORE-03` (em andamento)

Substituir o foco atual de `OperationCrdt<T>` por contrato orientado a Delta-CRDT.

Acceptance criteria:

- [x] CRDT recebe/aplica delta como unidade fundamental de sync;
- [x] delta repetido não altera o resultado;
- [x] `Operation` não é requisito de interoperabilidade entre réplicas;
- [x] merge de estado completo continua possível;
- [x] LWW funciona com HLC + ReplicaId;
- [x] contrato não depende de storage/transport.

Implementação inicial adicionada em `deltasync_core`: `DeltaCrdt`, `HlcTimestamp`
e `LwwDelta`. A API baseada em `Operation` permanece temporariamente para
compatibilidade e será migrada nas próximas tarefas.

### Próxima tarefa 2 — revisar `CORE-04` LWW

- [ ] remover VectorClock do critério de desempate;
- [ ] utilizar HLC;
- [ ] usar `ReplicaId` como tie-break determinístico;
- [ ] garantir delta idempotente;
- [ ] persistir posteriormente estado do HLC.

### Próxima tarefa 3 — G-Counter e PN-Counter

Implementar já no contrato Delta-CRDT corrigido.

### Próxima tarefa 4 — demais CRDTs

Completar G-Set, MV-Register, 2P-Set, OR-Set e OR-Map.

### Próxima tarefa 5 — composição

Somente depois dos CRDTs fundamentais estarem corretos, implementar `ObjectCrdt` e política add/update-wins.

---

## 16. Critério de conclusão do TCC

A DeltaSync será considerada validada quando demonstrar, no mínimo:

1. CRDTs previstos implementados e testados;
2. mutações locais gerando deltas incrementais;
3. aplicação idempotente e convergente dos deltas;
4. objetos compostos por múltiplos CRDTs;
5. política add/update-wins documentada e testada;
6. persistência local independente de banco no contrato;
7. adaptador SQLite funcional;
8. snapshot, clocks, contexto causal e outbox restaurados após reinício;
9. persistência atômica evitando perda de mutações sincronizáveis;
10. transporte abstrato;
11. duplicação e reordenação toleradas;
12. mecanismo de reconciliação capaz de recuperar uma réplica que ficou offline;
13. formatos persistidos/transmitidos versionados;
14. testes unitários, integração, recuperação, regressão e propriedade;
15. aplicação Flutter demonstrativa;
16. limitações de ACK, GC e topologia claramente documentadas quando não forem completamente solucionadas.

---

## 17. Síntese das principais correções deste plano

Este plano substitui a orientação excessiva a operações por uma arquitetura explicitamente baseada em Delta-CRDTs.

Também introduz formalmente:

- composição de objetos;
- OR-Map/OR-Set como base para existência observada;
- política add/update-wins;
- separação entre HLC e VectorClock;
- lifecycle de `ReplicaId` e `Dot`;
- separação entre identidade causal e ID de transporte;
- atomicidade entre estado, clocks e outbox;
- versionamento de snapshots, deltas e envelopes;
- reconciliação causal como responsabilidade explícita;
- ACK como decisão protocolar ainda aberta;
- GC de tombstones tratado conservadoramente;
- property-based tests;
- codegen movido para depois da estabilização do fluxo principal.

A arquitetura final deve provar primeiro a correção e a retomada do ciclo:

```text
mutação local
→ delta
→ persistência atômica
→ outbox
→ transporte
→ aplicação remota
→ persistência
→ reconciliação
→ convergência
```

Somente depois disso ergonomia de geração de código e otimizações avançadas devem ser priorizadas.
