# Análise da arquitetura e aderência à proposta — DeltaSync

Data: 2026-10-03. Escopo: diagnóstico da implementação, das classes e do plano.

Este relatório registra revisão solicitada pelo autor. Em 2026-10-03, autor pediu
incorporação das simplificações ao planejamento e decidiu preservar escopo acadêmico.
Implementação das mudanças será tratada nas tarefas do plano.
Fonte vigente de andamento: [plan/README.md](../plan/README.md).

## Parecer

Preocupação com manutenção tem fundamento. Projeto acumula modelos paralelos,
representações duplicadas e responsabilidades concentradas. Diagnósticos também
reproduziram falhas funcionais no fluxo de sincronização e no isolamento de estado.

Base possui código aproveitável: joins dos tipos atuais, HLC, deltas nativos,
tombstones, separação das camadas e regressões existentes. Refatoração direcionada
pode consolidar esses elementos antes de ampliar integração.

Biblioteca tem 32 classes/interfaces, dois enums e 2.448 linhas em 25 arquivos de
`lib/`. Quantidade isolada não determina qualidade. Evidência de excesso aparece
nas abstrações sobrepostas, caminhos de compatibilidade e custo de adicionar um
tipo ao fluxo completo.

## Fontes e evidências

- [PDF original](<../referencia/Proposta TCC.pdf>), capítulos 6 e 7 (contexto local para os agentes).
- [Contexto arquitetural](../proposta.md).
- Cinco fases, decisões, riscos e evidências em [plan/](../plan/README.md).
- Código dos quatro subpacotes, facade, exemplo e cinco arquivos de testes.
- Diff existente no início da revisão, incluindo alterações de R-04.

Verificação executada em 2026-10-03, Dart SDK 3.13.0, Linux x64:

- `dart analyze` na raiz e nos quatro subpacotes: sem issues.
- `dart test --reporter expanded` em cada pacote: raiz 2, core 26, sync 19,
  storage 6 e transport 2; total de 55 testes aprovados.
- `dart format --output=none --set-exit-if-changed lib test example packages`:
  31 arquivos verificados; nenhuma mudança necessária.
- `python3 scripts/check_plan.py`: 23 tarefas e 80 links locais; aprovação estrutural.
- `git diff --check`: aprovado.
- Diagnósticos exploratórios em `/tmp`: reprodução de bloqueios, perda de estado,
  mutabilidade compartilhada e inconsistências de contratos descritas abaixo.

Diagnósticos usam MemoryStorage e adaptadores de teste. Não comprovam durabilidade
entre processos. Duas engines foram conectadas com ACK condicionado à conclusão de
`applyRemote()`; MemoryStorage simula commit nesse cenário.

Arquivos temporários não integram suíte do projeto. Verificação suplementar foi
interrompida após bloqueio de escrita no cache do SDK; nenhuma conclusão deste
relatório depende dessa execução interrompida.

## Aderência à proposta

| Requisito | Situação observada |
|---|---|
| Módulos com responsabilidades separadas | Quatro subpacotes e facade; core sem Flutter, SQL ou protocolo de rede. |
| Oito CRDTs | LWW, G-Counter e PN-Counter implementados; cinco tipos restantes ausentes. |
| Deltas incrementais | Geração, aplicação e codec disponíveis para três tipos. |
| Serialização e restauração | Deltas e snapshot de réplica disponíveis; contratos e validação ainda apresentam inconsistências. |
| SQLite/sqflite | Adaptador ausente. |
| Outbox e recuperação durável | Contrato e simulação em memória; recuperação entre processos ausente. |
| Comunicação abstrata | Interfaces existem; DeltaEnvelope ainda não participa do fluxo da engine. |
| Reconciliação offline | Fluxo parcial; bloqueio reproduzido entre duas engines enviando simultaneamente. |
| Demonstração | Exemplo troca delta entre objetos Replica; não demonstra storage, reconexão ou reinício. |
| Validação completa | Testes atuais aprovados; faltam durabilidade, cinco tipos e cenários relevantes de integração. |

Entrega atual permanece parcial. Aprovação da suíte não satisfaz critérios completos
da proposta. Diferença entre três módulos internos do PDF e quatro subpacotes pode
ser documentada; adaptador SQLite continua necessário ao recorte vigente.

## Achados funcionais prioritários

### F-01 — Alta: rede ocupa fila de commits

Local: [SyncEngine.push](../packages/deltasync_sync/lib/src/sync_engine.dart),
linhas 162–197; fila compartilhada também atende mutações e `applyRemote()`.

Gatilho: duas engines executam `push()` simultaneamente; cada transporte aguarda
aplicação e commit na engine remota antes de devolver ACK.

Resultado reproduzido: ambas ficam aguardando aplicação remota enfileirada atrás
do próprio envio. ACK pendente também impede nova mutação local de concluir.
Indisponibilidade do canal pode paralisar edição offline.

Correção proposta: selecionar lote e registrar tentativa sob controle local;
aguardar rede fora da fila de commits; processar ACK em etapa curta e serializada.
Manter proteção contra pushes concorrentes sem bloquear mutações e recepção.

### F-02 — Alta: mutação antes da restauração perde snapshot anterior

Local: [SyncEngine](../packages/deltasync_sync/lib/src/sync_engine.dart),
`start()` na linha 40 e mutações a partir da linha 79.

Gatilho: criar engine com réplica vazia e storage que contém snapshot anterior;
executar `setDelta()` antes de `start()`.

Resultado reproduzido: mutação grava novo snapshot e sobrescreve estado anterior.
Restauração subsequente recupera somente novo estado.

Também reproduzidos: mutação após `dispose()` aceita e persistida; falha de
carregamento deixa `_started = true`, impedindo nova tentativa de `start()`.

Correção proposta: inicialização aguardada antes de expor mutações; estados de uso,
falha e descarte definidos. R-05 já contempla parte desses critérios.

### F-03 — Alta: valores aninhados permanecem compartilhados

Locais: [ReplicaState.copy](../packages/deltasync_core/lib/src/replica_state.dart),
linha 9; [LwwDelta.value](../packages/deltasync_core/lib/src/lww_delta.dart), linha 25;
[ReplicaSnapshot](../packages/deltasync_storage/lib/src/replica_storage.dart), linha 4.

Gatilho: fornecer mapa com lista a `setDelta()`; alterar lista original depois do
commit. Cópia recria registrador, mas mantém mesmo delta e valor interno.

Resultado reproduzido: estado local, snapshot em memória e payload da outbox mudam
sem novo ID, HLC ou commit. Réplica remota que recebeu JSON anterior mantém outro
valor. Mapas externos imutáveis não protegem objetos aninhados.

Correção proposta: definir valores serializáveis suportados, propriedade dos dados
e cópia/imutabilidade das entradas e consultas. Isolamento deve alcançar payload.

### F-04 — Alta: réplica pública contorna transação

Local: [SyncEngine.replica](../packages/deltasync_sync/lib/src/sync_engine.dart),
linha 29; [Replica.adopt](../packages/deltasync_core/lib/src/replica.dart), linha 84.

Gatilho: mutação direta em `engine.replica` enquanto commit de candidata está
aguardando storage.

Resultado reproduzido: mutação direta desaparece quando candidata é adotada;
candidata e mutação direta geram mesmo ID para payloads diferentes.

Correção proposta: engine controlar réplica persistida; expor consulta protegida e
mutações coordenadas. Réplicas isoladas podem continuar disponíveis no core.

### F-05 — Média: mutação local gera delta rejeitado remotamente

Local: [Replica._recordDelta](../packages/deltasync_core/lib/src/replica.dart),
linha 281; validação remota a partir da linha 343.

Gatilho e resultado reproduzidos: `setDelta('', value)` altera estado local, mas
outra Replica rejeita delta por endereço vazio.

Correção proposta: mesmas regras de endereço aplicadas antes de mutação local e
durante leitura/aplicação remota.

### F-06 — Média: PN-Counter direto aceita alteração parcial antes de erro

Local: [PnCounter.applyDelta](../packages/deltasync_core/lib/src/pn_counter.dart),
linha 172.

Gatilho: delta direto com componente positivo 5 e negativo -1.

Resultado reproduzido: componente positivo aplicado; negativo lança erro;
contador termina com valor 5. Pré-validação de Replica protege seu próprio fluxo,
mas API pública do tipo continua apresentando efeito parcial.

Correção proposta: validar ambos os componentes antes de aplicar qualquer um.

## Outras inconsistências e limites

- **Endereço/tipo:** LWW e counters usam registros separados. Mesmo endereço aceita
  simultaneamente LWW e G-Counter; conflito entre G-Counter e PN-Counter é
  rejeitado. Unificar regra de vínculo entre endereço e tipo.
- **Relógio injetado:** `Replica.fork()` cria HlcClock sem conservar fonte de tempo
  injetada. Reproduzido relógio controlado abandonado em mutação da SyncEngine.
- **ID conflitante:** payload divergente com mesmo ID rejeitado antes de snapshot;
  após restauração, histórico de validação desaparece e mesmo conflito pode ser
  aceito. Definir alcance da garantia e condição de validade dos IDs.
- **Exportação:** Replica restaurada com estado não vazio pode ter `export()` vazio.
  Limite documentado em R-04: exporta histórico desde restauração. Bootstrap e
  troca de estado completo precisam de contrato próprio se cenário os exigir.
- **Mistura de APIs:** após delta nativo, registrador ignora operações legadas.
  Regra documentada; `set()` pode retornar operação sem alterar campo que já
  recebeu `setDelta()`. API favorece uso incorreto.
- **Histórico:** inspeção mostra listas sem limite durante sessão; ACK limpa outbox,
  sem remover histórico mantido em Replica. Não foi executado benchmark.
- **Erros remotos:** listener usa `unawaited(applyRemote(delta))`; consumidor não
  recebe canal explícito de erro nem confirmação vinculada ao commit nesse fluxo.

## Avaliação do sistema de classes

Há excesso concreto nas trilhas legadas e nas representações sobrepostas.
Classes que representam estado e delta de um CRDT têm responsabilidades distintas
e justificáveis. Classes de clocks e identidade também atendem requisitos do PDF.

| Classes/interfaces | Avaliação e recomendação |
|---|---|
| CrdtOperation | Sem uso no fluxo, além da própria definição. Candidata forte à remoção da API pública. |
| Crdt, OperationCrdt | Contrato/base do caminho por operações. Retirar do fluxo principal ao consolidar DeltaCrdt; eventual compatibilidade precisa de limite. |
| Operation | Mantém ordenação, payload e serialização legados. Migrar explicitamente; evitar sustentar dois modelos permanentes de mutação. |
| PendingDeltaStore, MemoryPendingDeltaStore | Segundo contrato de storage, sem snapshots nem ACK individual. Candidatos à descontinuação em favor de ReplicaStorage/MemoryStorage. |
| Delta | Manter conceito de lote; simplificar duas listas em coleção única de mudanças nativas. |
| DeltaChange | Contrato útil. Tornar identidade, endereço, tipo e origem acessíveis por contrato comum para reduzir reconhecimento de classes em outras camadas. |
| DeltaCodec, DeltaEnvelope | Hoje há wrappers versionados sobrepostos e envelope fora do fluxo. Definir mensagem efetivamente usada e responsabilidade de serialização de cada camada; manter versões que tenham evolução própria. |
| DeltaCrdt | Contrato central alinhado à proposta. Manter mínimo; restauração verificável por tipo deve complementar API. |
| LwwRegister, LwwDelta | Estado e mudança úteis. Simplificar LwwRegister retirando dupla representação de vencedores e herança legada do caminho nativo. |
| GCounter, GCounterDelta | Responsabilidades necessárias; preservar join por máximo de componentes e delta cumulativo. |
| PnCounter, PnCounterDelta | Responsabilidades necessárias. Simplificar implementação interna e validar entrada inteira antes de aplicar. |
| Replica, ReplicaState | Divisão atual espalha estado: ReplicaState guarda somente LWW; Replica guarda counters. Consolidar estado por endereço e limitar coordenação de Replica. |
| ReplicaSnapshot | Necessária. Representação canônica de estado restaurável; remover duplicação entre state/clock e metadata['replicaState']. |
| OutboxEntry | Necessária. Uma mudança por entrada simplifica identidade e ACK parcial; lotes pertencem ao envio. |
| ReplicaStorage, MemoryStorage | Fronteira de infraestrutura e implementação de teste úteis. Contrato com commit atômico central; operações separadas de gravação precisam de propósito explícito. |
| DeltaTransport, AcknowledgingDeltaTransport | Abstração útil; avaliar contrato único com resultado explícito de confirmação. Preservar distinção entre envio concluído e commit remoto confirmado. |
| SyncEngine | Coordenação necessária; consolidar pipeline repetido das mutações, proteger estado e separar espera de rede da fila de commits. |
| SyncRetryPolicy | Política pequena, útil e configurável. Ajustar validação e documentação conforme execução real; classe possui propósito atual. |
| ReplicaId, Dot | Tipos previstos no PDF; identidade e evento causal precisam continuar explícitos. |
| HlcTimestamp, HlcClock | Timestamp e relógio mutável possuem responsabilidades próprias. Preservar fonte de tempo ao copiar contexto. |
| VectorClock, ClockRelation | Preservar onde contexto causal exigir. Máximo por réplica não representa lacunas de entrega; tipos observados precisam de contexto adequado. |
| OutboxStatus | confirmed é filtrado, enquanto ACK normalmente remove entrada. Reavaliar necessidade desse estado conforme contrato escolhido. |

Remoção de API exportada ou alteração de formato exige decisão explícita de
compatibilidade. Existência de consumidores externos não foi verificada. Se houver,
considerar versão incompatível e migração isolada. Nenhuma remoção está autorizada
por este diagnóstico.

### Onde desenho atual amplia manutenção

**Hierarquia híbrida de LWW.** LwwRegister herda OperationCrdt e implementa
DeltaCrdt. Mantém `_winner`, `_value` e `_deltaWinner`, além de deduplicação de
operações. Métodos de consulta, merge e snapshot precisam escolher representação.
Uma representação nativa reduz combinações possíveis de comportamento.

**Contrato comum insuficiente.** DeltaChange expõe somente `id` e `toJson()`.
Storage precisa conhecer LwwDelta, GCounterDelta e PnCounterDelta para descobrir
origem. Novo tipo amplia switches em Replica, Delta e OutboxEntry, além de snapshot
e métodos da engine. Metadados comuns podem eliminar conhecimento repetido.

**Composição interna de PN-Counter.** Componentes precisam de join por máximo.
Hoje PnCounter carrega dois GCounter completos, incluindo endereços e sequências;
mutações produzem deltas internos descartados, enquanto aplicação constrói deltas
artificiais para componentes. Mapas ou auxiliar privado de componentes monotônicos
podem preservar semântica com menos maquinaria de identidade e transporte.

**Pipeline de mutação repetido.** Engine repete fork, mutação, criação de lote,
outbox, commit e adopt para cada método. Auxiliar interno pequeno pode coordenar
esse fluxo sem framework público de comandos ou plugins.

**Cópia carrega histórico.** Fork e adopt copiam estado e históricos; aplicação
remota reconstrói mapas para verificar IDs anteriores e busca listas por ID.
Custo cresce com eventos acumulados. Separar histórico de estado necessário evita
tratar toda edição como cópia de log. Cópia de snapshot pequeno pode continuar
adequada ao TCC; otimização adicional depende de medida.

**Estado persistido possui duas representações.** ReplicaSnapshot.state contém
valores LWW, enquanto estado completo fica em metadata['replicaState']. Adapter
precisa conhecer convenção oculta para restaurar counters, tombstones e sequências.
Snapshot canônico reduz ambiguidade e responsabilidade de infraestrutura.

## Complexidade necessária ao recorte

Preservar:

- Join correto por tipo, com testes de associatividade, comutatividade e idempotência.
- Distinção entre estado completo e delta incremental.
- Endereço estável, identidade de réplica e sequências restauráveis.
- HLC de LWW e contexto adequado aos tipos observados.
- Tombstones e informações necessárias para evitar ressurreição indevida.
- Commit local atômico de estado, metadados e outbox.
- ACK posterior à incorporação/commit remoto; retry de mudanças sem confirmação.
- Persistência SQLite real e recuperação entre sessões.

Oito CRDTs permanecem no escopo. Redução exige revisão explícita do recorte
acadêmico. ObjectCrdt, codegen, backend próprio, GC destrutivo e anti-entropy
arbitrário continuam extensões futuras.

## Limpeza do core e compreensão da implementação

Problema identificado pelo autor é repetição de representações e dificuldade de
entender responsabilidades. Limpeza deve permitir explicar caminho de uma edição e
revisar comportamento de cada tipo. Contagem de classes não será meta de conclusão.

### Consolidação proposta

- Retirar CrdtOperation, sem uso no fluxo, e consolidar DeltaCrdt como contrato
  principal. Crdt, OperationCrdt e Operation saem do caminho normal mediante decisão
  explícita de compatibilidade; conversão antiga, quando necessária, fica isolada.
- LwwRegister manter somente vencedor nativo e tombstone, eliminando herança legada
  e representações paralelas `_winner`, `_value` e `_deltaWinner`.
- Delta representar lote de mudanças nativas. Serialização pode usar funções ou
  responsabilidade do lote; DeltaCodec só permanece como classe pública se tiver
  função distinta. Envelope efetivo atende requisitos do PDF sem wrappers redundantes.
- Replica e ReplicaState compartilhar um único estado materializado por endereço.
  Escolher uma estrutura responsável por esse estado; separar nome ou classe somente
  se houver responsabilidade própria. Evitar maps de LWW e counters como estados
  paralelos em camadas diferentes.
- Histórico completo sair do caminho normal de Replica. Convergência usa estado e
  metadados necessários; alterações não confirmadas ficam na outbox. Definir alcance
  de exportação e validação de IDs sem depender de log ilimitado.
- PnCounter combinar componentes positivos/negativos sem fabricar mensagens de
  GCounter para uso interno. Mapas ou auxiliar privado preservam join por máximo;
  estado e delta público de PN-Counter continuam específicos.
- Metadados comuns de mudança expor endereço, tipo, origem e ID. Aplicar HLC,
  sequências, dots e contexto causal somente onde semântica exigir. Não forçar um
  relógio universal nem contexto com lacunas apagadas para todos os tipos.

### Uso dos recursos do Dart

Base já usa enums, generics, interfaces e switches com padrões; oportunidade é
consolidar seu uso onde o modelo ainda depende de strings ou contratos incompletos.
Rótulos como `lww`, `g-counter` e `pn-counter` podem ter representação interna
tipada com nomes serializados estáveis. Metadados comuns de `DeltaChange` devem
evitar seleção da classe concreta apenas para consultar origem/tipo/endereço.
`OutboxEntry.delta` opcional, apesar de exigido pelo construtor, é exemplo de
nulabilidade que pode expressar melhor uma invariante em R-09b.

Extensions ajudam conversões e conveniências; extension types podem distinguir
IDs em compilação, mas exigem avaliar `ReplicaId` existente e limites em runtime.
`sealed` pode tornar switches exaustivos, porém impõe subtipos na mesma library;
não compensa reorganizar tudo sem simplificação demonstrável. Esses recursos
não substituem os joins, isolamento de dados ou validação nas fronteiras.
Aplicar [orientações e exemplos do Dart](../AGENTS.md#uso-adequado-dos-recursos-do-dart)
às tarefas pertinentes, sem modernizar legado destinado à remoção.

### Responsabilidades que continuam distintas

Estado CRDT e delta representam informações diferentes. Timestamp e relógio mutável
também possuem funções próprias. Tipos de identidade previstos no PDF continuam
explícitos. Eliminar sobreposição deve preservar tipos que tornam invariantes claras.

Cada CRDT precisa de explicação curta e exemplo reproduzível para quatro perguntas:

1. Qual estado guarda?
2. Qual delta mutação local produz?
3. Como faz join de estado e aplica delta recebido?
4. Quais metadados precisam sobreviver à restauração?

Replica coordena estados endereçados e contexto local; SyncEngine coordena commits,
entrega e recuperação; adaptador de storage implementa durabilidade. Diagrama curto
e cenário manual acompanham contratos públicos. Abstração adicional precisa de caso
concreto dentro dos oito tipos; evitar gerador, registry de plugins ou framework de
comandos para substituir classes removidas.

### Decisão sobre proposta

Autor optou por manter oito CRDTs e SQLite/sqflite nesta revisão. Sugestão anterior
de reduzir tipos não foi adotada. Primeiro consolidar implementação e comprovar fluxo
com LWW, G-Counter e PN-Counter; depois integrar cinco tipos restantes, um por tarefa.
Esse cenário inicial é etapa de desenvolvimento, não redução do gate acadêmico.

Limpeza reduz complexidade acidental; MV-Register, OR-Set e OR-Map ainda exigem
semântica e metadados próprios. Viabilidade no prazo permanece desconhecida sem
cronograma e esforço disponível. Reavaliar prazo com evidências de execução, sem
presumir que refatoração elimina custo dos tipos observados.

### Uso real, contribuição e forks

Autor definiu Compass como exemplo de uso real e pediu facilidade tanto para
integrar quanto para modificar a biblioteca. Avaliação considera API do
desenvolvedor, experiência offline e clareza dos pontos de manutenção/contribuição.
O core permanece geral: consumidor adapta modelos e fluxos a contratos públicos;
necessidade específica do Compass não justifica customização da biblioteca.

Direção foi incorporada a [AGENTS.md](../AGENTS.md#uso-real-simplicidade-e-manutenção)
e ao plano: R-08d exercita API pública e VAL-04 documenta percurso de manutenção;
VAL-02 aceita Compass como consumidor ilustrativo ou demonstração independente.
Código enxuto reduz conceitos e duplicações preservando invariantes; quantidade
de classes/linhas não é meta.
Repositório e cenário do Compass ainda precisam ser identificados; nenhum resultado
de integração ou usabilidade no aplicativo foi obtido nesta revisão documental.
Se integrado, mudança fica no app, salvo defeito de contrato ou necessidade geral
dos oito tipos.

## Direção de simplificação incorporada ao plano

1. Consolidar contrato DeltaCrdt e caminho nativo de mutação; migração legada com
   limite documentado.
2. Manter estado materializado por endereço, com tipo vinculado e snapshot único.
3. Manter regras de cada CRDT no próprio tipo; compartilhar metadados realmente
   comuns, usando catálogo fechado dos oito tipos quando necessário.
4. Engine possuir acesso de escrita à réplica persistida; consultas protegidas e
   operações coordenadas para consumidores.
5. Inicialização restaurar estado antes de liberar mutações. Falhas e descarte
   observáveis, com tratamento do trabalho em andamento.
6. Fila local serializar mutações e commits remotos; envio aguardar rede fora dessa
   fila. ACK processado apenas para mudanças do lote efetivamente enviado.
7. Outbox persistir uma mudança por entrada. Snapshot mais outbox expressarem
   recuperação; histórico de auditoria depender de requisito próprio.
8. Cada novo CRDT entrar acompanhado de codec, snapshot e fluxo integrado.

Separação física em quatro pacotes possui dependências coerentes. Consolidar
caminhos de execução e reduzir API pública tem prioridade. Eventual reorganização
de pacotes pode ser avaliada depois que responsabilidades estejam estáveis.

## Avaliação do plano

Plano atual preserva oito tipos e já exclui ampliações como ObjectCrdt e codegen.
Possui requisitos úteis de correção e durabilidade. Revisão inicial identificou:

- [Índice](../plan/README.md) informava integração restrita a LWW, embora
  counters já participem de Replica e SyncEngine.
- R-05 constava como planejada no índice/fase; execução de R-04 registrava pronta.
- Matriz inicial de TRACEABILITY é baseline histórica; leitura como panorama atual
  contradiz correções posteriores. Diferenciar panorama corrente de histórico.
- R-04 foi encerrada com evidências de falhas de commit e serialização; novos
  achados exigem reavaliar alcance de isolamento e estratégia da fila.
- R-02 precisa de regra uniforme de endereço/tipo no caminho dos três CRDTs.
- Checker valida registros, links e dependências; não verifica garantias runtime.
- Testes de ACK devolvem IDs sem aplicar mudanças numa segunda engine. Assim,
  aprovação da suíte não cobre bloqueio da troca simultânea.

Plano revisado introduz R-09a/R-09b para consolidar core e estado/storage, amplia
R-05 com fila e lifecycle, e adiciona R-08d para fluxo real dos três tipos atuais
entre duas engines. Compatibilidade, envelope e topologia entram antes dessa
integração. SQLite e cinco tipos restantes usam contratos consolidados. R-07a passa
a verificar conjunto integrado, sem concentrar toda integração no final.

R-01 a R-04 mantêm evidências históricas. Falhas novas ficam explicitamente
pendentes em tarefas sucessoras; conclusão anterior não comprova base completa.

Simplificar manutenção documental: uma fonte de status por tarefa, panorama atual
curto e evidências ligadas a comportamentos. Preservar histórico e verificações
úteis; reduzir repetição de informações entre registros.

## Direção recomendada

Próxima entrega recomendada: R-09a, consolidação do core nativo com inventário de
compatibilidade. R-09b trata estado/snapshot/outbox e isolamento; R-05 trata fila,
lifecycle e observabilidade; R-08d comprova cenário integrado inicial.
Detalhes, dependências e critérios pertencem às fases do [plano](../plan/README.md).
