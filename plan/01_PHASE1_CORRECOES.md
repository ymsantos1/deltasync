# Fase 1 — Simplificação e correções da base existente

Estado: ativa. Nenhuma tarefa de código em andamento.

Objetivo: consolidar core nativo, estado/storage e corrigir commits e lifecycle.
Entrada: implementação atual, [análise](../docs/analise-arquitetura.md) e
diagnósticos em [TRACEABILITY.md](TRACEABILITY.md).
Saída: R-01 a R-05 e R-09a/R-09b concluídas, com evidências dos critérios.
Áreas: core, storage, sync, transport e seus testes.
Riscos: [RISK-01 a RISK-05, RISK-07 e RISK-13 a RISK-16](RISKS.md).
Exclusões: novos frameworks de objetos, codegen e GC destrutivo.

R-01 a R-04 conservam conclusões históricas. Novos achados de isolamento,
endereçamento e fila serão resolvidos em R-09a/R-09b/R-05. R-09a é próxima pronta.
Fases posteriores usam contratos consolidados e fluxo inicial de R-08d.

<a id="r-01"></a>

## R-01 — LWW nativo e compatibilidade

Status: concluída
MoSCoW: MUST
Dependências: nenhuma

Baseline histórica anterior a R-01: parcial.

Problema reproduzido: operações legadas z={z:1}, a={z:1,a:1}, m={m:1}, todas
sobre a mesma chave. Ordens [z,a,m] e [a,m,z] resultam em m e z.
Operation.compareTo não fornece ordem transitiva ao combinar causalidade e
desempate por replicaId. Testes existentes de duas operações não cobrem o caso.

Critérios:

- [x] Caminho público recomendado produz/aplica LwwDelta com HLC.
- [x] Caso de três operações é coberto por regressão; definir correção ou rejeição
  explícita do caminho legado, sem anunciá-lo como CRDT convergente.
- [x] Documentar migração/compatibilidade de Operation e dados antigos.
- [x] Não misturar políticas causal e HLC como se fossem equivalentes. Atualmente,
  operação legada após primeiro delta nativo é ignorada naquele registrador.
- [x] Atualizar exemplo/README para API escolhida, mantendo quebras explícitas.

Não remover API pública silenciosamente. Compatibilidade temporária precisa de
limites documentados; nomes antigos podem ser wrappers se semântica for definida.

Validação: Regressão das três operações em todas as permutações; LWW nativo com HLC, tombstones e repetição; compatibilidade da facade e exemplo.

Evidência de conclusão: [Execução R-01 — 2026-09-27](TRACEABILITY.md#execução-r-01--2026-09-27).
<a id="r-02"></a>

## R-02 — Identidade e roteamento

Status: concluída
MoSCoW: MUST
Dependências: R-01

Baseline histórica anterior a R-02: parcial.

Problemas reproduzidos: Replica.apply rejeita GCounterDelta; dois GCounter da mesma
réplica produzem o mesmo ID na primeira mutação e Delta.merge perde uma mudança.
OutboxEntry só extrai origem de delta nativo LWW.

Critérios:

- [x] Endereço estável do CRDT acompanha cada mudança.
- [x] IDs não colidem entre instâncias/campos; definir alocação de dots local e
  namespace causal. Sequência por tipo/instância não é relógio global da réplica.
- [x] Replica, codec, OutboxEntry e SyncEngine roteiam LWW e counters sem perda.
- [x] Testar dois counters independentes na mesma réplica, lote misto e restauração.
- [x] Validar origem/endereço/tipo e rejeitar lote inválido sem aplicação parcial.
- [x] Definir semântica para IDs repetidos com payload divergente.
- [x] Planejar contexto que distingue lacunas: observar dot 3 não implica ter
  recebido dot 1/2 de CRDTs independentes.

Integração manual suficiente; não exige ObjectCrdt ou build_runner.

Validação: Dois counters na mesma réplica, lote misto, codec e outbox; ID conflitante, delta inválido e restauração das sequências.

Evidência de conclusão: [Execução R-02 — 2026-09-28](TRACEABILITY.md#execução-r-02--2026-09-28).
<a id="r-03"></a>

## R-03 — ACK e outbox seguros

Status: concluída
MoSCoW: MUST
Dependências: nenhuma

Baseline histórica anterior a R-03: parcial.

Problema reproduzido: enqueue de lote com duas mudanças e ACK só da primeira
deixa zero entradas pendentes. MemoryStorage.acknowledge usa any(ids.contains).

Critérios:

- [x] Definir ACK por mudança ou envelope. ACK parcial preserva parte não
  confirmada, ou lote só é removido após confirmação de todos os IDs.
- [x] ACK externo só confirma IDs do lote enviado e da outbox da réplica local;
  ACK separado por peer aguarda identidade de destino em R-08b.
- [x] Envio sem confirmação mantém pendências; migrar ou restringir caminho
  PendingDeltaStore que atualmente limpa tudo após send.
- [x] Falha de envio, timeout e reinício antes do ACK permitem retry sem perda.
- [x] Retry respeita política documentada; push(force:true) e maxAttempts têm
  comportamento explícito, sem confundir reenvio manual com entrega garantida.
- [x] Documentar quem confirma e se aplicação/persistência remota precedem ACK.

Não usar ACK de envio para GC de tombstones.

Validação: ACK parcial, envio falho, envio sem ACK, timeout e retry; cobrir caminho ReplicaStorage e caminho legado enquanto existir.

Evidência de conclusão: [Execução R-03 — 2026-09-28](TRACEABILITY.md#execução-r-03--2026-09-28).
<a id="r-04"></a>

## R-04 — Commits atômicos e snapshots

Status: concluída
MoSCoW: MUST
Dependências: R-02, R-03

Baseline anterior: primitivas separadas disponíveis; commit atômico pendente.

Na baseline anterior, mutação alterava memória, enqueue e saveReplica separadamente.
Adicionar transação no adaptador não resolve chamadas independentes automaticamente.

Critérios:

- [x] Contrato expressa commit local único de estado + clocks + outbox.
- [x] Commit remoto preserva estado/contexto/clocks e falha sem efeito parcial.
- [x] Falha do commit deixa memória e storage consistentes; sucesso só é retornado
  após commit. Definir preparação isolada, rollback ou estratégia equivalente.
- [x] Não usar ReplicaState.copy como isolamento sem corrigir cópia compartilhada
  de LwwRegister; caso reproduzido altera cópia ao mutar original.
- [x] Serializar mutações/merges que compartilham réplica e storage.
- [x] Snapshot versionado restaura estado, tombstones, identidade e clocks sem
  exigir replay ilimitado de Replica.export().
- [x] Dot/sequências de IDs/HLC não regressam após restauração ou compactação.
- [x] Testes de contrato incluem falhas entre etapas e versão incompatível.

Snapshots novos guardam estado materializado versionado; snapshots legados em
metadata['delta'] continuam legíveis durante migração.

Validação: Falhas de commit local/remoto, isolamento de estado, concorrência e restauração versionada; validar MemoryStorage como contrato, sem alegar durabilidade.

Evidência de conclusão: [Execução R-04 — 2026-10-01](TRACEABILITY.md#execução-r-04--2026-10-01).

Conclusão acima cobre evidências dessa execução. F-01/F-03/F-04 da análise de
2026-10-03 deixam garantias adicionais pendentes em R-09b/R-05; preservação do
registro não representa aprovação atual de todo isolamento ou fluxo entre engines.

<a id="r-09a"></a>

## R-09a — Core nativo e compatibilidade

Status: concluída
MoSCoW: MUST
Dependências: R-01, R-02

Áreas: core, consumidores em sync/storage/transport, facade, exemplos e testes.
Objetivo: eliminar representações sobrepostas e consolidar contratos dos três tipos
atuais, preservando joins e preparando integração dos oito CRDTs.

Critérios:

- [x] Inventariar APIs exportadas e formatos usados no workspace; documentar
  política de remoção, wrappers ou conversão isolada e quebras para consumidores.
- [x] DeltaCrdt ser contrato principal; retirar CrdtOperation sem uso e caminho
  operacional legado da execução normal, incluindo herança de LwwRegister.
- [x] LWW manter vencedor nativo único com tombstone; operações antigas, quando
  suportadas, usar migração explícita sem dois modelos permanentes de vencedor.
- [x] Delta ser lote nativo; contrato comum de mudança expor endereço, tipo, origem
  e ID com tipos adequados, sem switches por classe apenas para ler metadados comuns.
  Serialização e envelope terem funções distintas; avaliar necessidade de DeltaCodec
  como classe pública sem criar registry, codegen ou framework genérico.
- [x] Conjunto fechado de tipos usar enum com rótulo serializado explícito ou
  solução tipada equivalente, evitando strings fixas espalhadas. Preservar rótulos
  e IDs existentes ou versionar mudança; rejeitar tipos desconhecidos. Não usar
  `.index` nem depender de renomeações de `.name` para formatos persistidos.
- [x] Simplificar componentes internos de PN-Counter; validar delta inteiro antes
  de aplicar e manter join por máximo com deltas cumulativos.
- [x] Validar endereços/valores locais antes de mutar; saída válida ser aceita
  por codec e outra Replica. HLC/contexto/dots servirem apenas à semântica aplicável.
- [x] Exemplo e documentação explicarem estado, mutação, delta, join e restauração
  de cada tipo atual e apontarem arquivos/testes para uma alteração localizada;
  preservação de tipos úteis não depender de quota de classes.

Validação: regressões nativas dos três tipos, PN inválido sem efeito parcial,
endereço vazio, lotes, round-trip de tipos/rótulos/IDs e rejeição de desconhecidos,
fixtures de compatibilidade/rejeição e consumidores.
Checks de pacotes afetados e facade; ausência de classes sem uso no fluxo revisado.
Conferir exemplos e correspondência do percurso de alteração com arquivos/testes.

Evidência de conclusão: [Execução R-09a — 2026-10-03 (conclusão)](TRACEABILITY.md#execucao-r-09a-2026-10-03-conclusao).
Status: concluída.

<a id="r-09b"></a>

## R-09b — Estado, snapshots e outbox consolidados

Status: pronta
MoSCoW: MUST
Dependências: R-09a, R-03, R-04

Áreas: estado de Replica, snapshots, contrato de storage, SyncEngine e testes.
Objetivo: manter estado restaurável canônico e isolamento real, com uma pendência
por mudança e pipeline local de commit comum.

Critérios:

- [ ] Unificar estado por endereço, com vínculo de tipo incluindo LWW/counters;
  consolidar Replica/ReplicaState conforme responsabilidade própria de cada uma.
- [ ] Snapshot canônico guardar estado, tombstones, clocks/contexto e sequências;
  eliminar duplicação entre state/clock e metadata['replicaState']; versionar formato
  e definir leitura/conversão ou rejeição explícita de snapshots anteriores.
- [ ] Definir valores serializáveis e proteger entradas, consultas, cópias e
  snapshots contra mutação externa de listas/mapas aninhados. Fork preservar fonte
  de tempo injetada e isolamento necessário para falha de commit.
- [ ] Engine controlar escrita na réplica ativa, inclusive referência originalmente
  fornecida pelo consumidor; mutação externa não produzir perda ou colisão de IDs.
- [ ] Histórico completo sair do caminho normal; outbox conservar somente pendências.
  Definir exportação, bootstrap aplicável e alcance de rejeição de ID conflitante
  após restauração sem prometer deduplicação eterna por log ilimitado.
- [ ] ReplicaStorage ser contrato principal; descontinuar PendingDeltaStore e
  MemoryPendingDeltaStore do fluxo normal com compatibilidade explícita. Consolidar
  gravações em commit atômico; primitivas restantes terem função documentada.
- [ ] Outbox ter uma entrada por mudança, identidade direta e ACK parcial sem perda;
  lotes serem formados no envio. Tentativas e status terem significado consistente.
- [ ] Nulabilidade refletir invariantes: entrada de outbox exigir mudança válida
  no tipo/construtor, sem campo opcional que todo consumidor precisa forçar com `!`.
  Rejeitar entradas inválidas na criação/restauração; ausência legítima continuar
  explícita, sem valores artificiais para esconder estado ausente.
- [ ] Mutações locais compartilharem pipeline interno de preparação/commit/adoção;
  falhas manterem estado e outbox anteriores, sem framework público de comandos.

Validação: payload alterado pelo chamador e por consultas não altera estado/outbox;
referência externa durante commit, relógio controlado, tipo/endereço conflitante,
snapshot/restauração e sequência, falhas locais/remotas, ACK parcial e compatibilidade.
Verificar contrato tipado da outbox, criação/restauração inválida e consumidores.
MemoryStorage simula contrato; durabilidade continua em R-07c/R-07d.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-05"></a>

## R-05 — Lifecycle e processamento remoto

Status: planejada
MoSCoW: MUST
Dependências: R-09b

Baseline: parcial; correções ainda não concluídas.

Mutações antes de start podem sobrescrever snapshot anterior; após dispose também
são aceitas. Falha de start deixa flag iniciada. Listener descarta Future de erro.
Fila de commits aguarda rede em push, bloqueando edição local e aplicação remota.

Critérios:

- [ ] Definir contrato de uso antes de start e após dispose; impedir mutação antes
  da restauração ou depois do descarte, conforme contrato.
- [ ] Falha de start permite recuperação ou estado terminal documentado; _started
  não pode sugerir sucesso após falha de carregamento.
- [ ] Processamento remoto aguardado/serializado; erros observáveis e sem aplicação
  parcial ou confirmação antes do commit.
- [ ] Envio e espera de ACK ocorrerem fora da fila de commits; edição local e
  recepção continuarem enquanto rede estiver lenta ou indisponível. ACK só alcançar
  mudanças do lote enviado, preservando pendências criadas durante envio.
- [ ] API pública permitir distinguir commit local concluído, mudanças pendentes
  e confirmação remota, além de observar falhas e ciclo de vida; consumidor não
  depender de acesso a campos internos nem de framework de estados novo.
- [ ] dispose trata operação em andamento e impede novos trabalhos.
- [ ] Testar start falho, entrada inválida, falha de storage, concorrência e
  cancelamento; guarda isolada não comprova lifecycle completo.

Validação: start falho/repetido, perda de snapshot por uso antes da restauração,
mutação fora do lifecycle, callback remoto com erro, edição/recepção durante envio
pendente, ACK concorrente e dispose com trabalho em andamento. Duas engines e
envio simultâneo são verificados em R-08d antes de expandir tipos.
Resultados de commit/pendência/confirmação e erros devem ser verificáveis pela API pública.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

## Gate da fase

Revisar diff de cada tarefa, executar verificações acima e análise dos pacotes
afetados. Concluir fase somente com evidências de R-01 a R-05 e R-09a/R-09b.
R-09b libera envelopes; R-08d libera expansão dos tipos e contrato durável.
Limpeza documental não conclui correções de código.
