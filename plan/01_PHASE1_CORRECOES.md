# Fase 1 — Correções da base existente

Estado: ativa. Nenhuma tarefa de código em andamento nesta migração documental.

Objetivo: fechar perda de deltas, divergência legada, identidade, commits e lifecycle.
Entrada: implementação atual e diagnósticos em [TRACEABILITY.md](TRACEABILITY.md).
Saída: R-01 a R-05 concluídas, com regressões e evidências dos critérios.
Áreas: core, storage, sync, transport e seus testes.
Riscos: [RISK-01 a RISK-05 e RISK-07](RISKS.md).
Exclusões: novos frameworks de objetos, codegen e GC destrutivo.

R-01 e R-03 são selecionáveis agora; ordem recomendada: R-01, R-03, R-02,
R-04, R-05. R-03 não precisa esperar R-01. Fases posteriores podem iniciar seus
contratos quando as dependências específicas estiverem satisfeitas.

<a id="r-01"></a>

## R-01 — LWW nativo e compatibilidade

Status: concluída
MoSCoW: MUST
Dependências: nenhuma

Baseline: parcial; correções ainda não concluídas.

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

Status: planejada
MoSCoW: MUST
Dependências: R-01

Baseline: parcial; correções ainda não concluídas.

Problemas reproduzidos: Replica.apply rejeita GCounterDelta; dois GCounter da mesma
réplica produzem o mesmo ID na primeira mutação e Delta.merge perde uma mudança.
OutboxEntry só extrai origem de delta nativo LWW.

Critérios:

- [ ] Endereço estável do CRDT acompanha lote/envelope ou cada mudança.
- [ ] IDs não colidem entre instâncias/campos; definir alocação de dots local e
  namespace causal. Sequência por tipo/instância não é relógio global da réplica.
- [ ] Replica, codec, OutboxEntry e SyncEngine roteiam LWW e counters sem perda.
- [ ] Testar dois counters independentes na mesma réplica, lote misto e restauração.
- [ ] Validar origem/endereço/tipo e rejeitar lote inválido sem aplicação parcial.
- [ ] Definir semântica para IDs repetidos com payload divergente.
- [ ] Planejar contexto que distingue lacunas: observar dot 3 não implica ter
  recebido dot 1/2 de CRDTs independentes.

Integração manual suficiente; não exige ObjectCrdt ou build_runner.

Validação: Dois counters na mesma réplica, lote misto, codec e outbox; ID conflitante, delta inválido e restauração das sequências.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.
<a id="r-03"></a>

## R-03 — ACK e outbox seguros

Status: pronta
MoSCoW: MUST
Dependências: nenhuma

Baseline: parcial; correções ainda não concluídas.

Problema reproduzido: enqueue de lote com duas mudanças e ACK só da primeira
deixa zero entradas pendentes. MemoryStorage.acknowledge usa any(ids.contains).

Critérios:

- [ ] Definir ACK por mudança ou envelope. ACK parcial preserva parte não
  confirmada, ou lote só é removido após confirmação de todos os IDs.
- [ ] ACK externo não confirma indevidamente mudança de outro destino/réplica.
- [ ] Envio sem confirmação mantém pendências; migrar ou restringir caminho
  PendingDeltaStore que atualmente limpa tudo após send.
- [ ] Falha de envio, timeout e reinício antes do ACK permitem retry sem perda.
- [ ] Retry respeita política documentada; push(force:true) e maxAttempts têm
  comportamento explícito, sem confundir reenvio manual com entrega garantida.
- [ ] Documentar quem confirma e se aplicação/persistência remota precedem ACK.

Não usar ACK de envio para GC de tombstones.

Validação: ACK parcial, envio falho, envio sem ACK, timeout e retry; cobrir caminho ReplicaStorage e caminho legado enquanto existir.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.
<a id="r-04"></a>

## R-04 — Commits atômicos e snapshots

Status: planejada
MoSCoW: MUST
Dependências: R-02, R-03

Baseline: primitivas separadas disponíveis; commit atômico pendente.

Hoje mutação altera memória, enqueue e saveReplica ocorrem separadamente.
Adicionar transação no adaptador não resolve chamadas independentes automaticamente.

Critérios:

- [ ] Contrato expressa commit local único de estado + clocks + outbox.
- [ ] Commit remoto preserva estado/contexto/clocks e falha sem efeito parcial.
- [ ] Falha do commit deixa memória e storage consistentes; sucesso só é retornado
  após commit. Definir preparação isolada, rollback ou estratégia equivalente.
- [ ] Não usar ReplicaState.copy como isolamento sem corrigir cópia compartilhada
  de LwwRegister; caso reproduzido altera cópia ao mutar original.
- [ ] Serializar mutações/merges que compartilham réplica e storage.
- [ ] Snapshot versionado restaura estado, tombstones, identidade e clocks sem
  exigir replay ilimitado de Replica.export().
- [ ] Dot/sequências de IDs/HLC não regressam após restauração ou compactação.
- [ ] Testes de contrato incluem falhas entre etapas e versão incompatível.

Snapshot atual guarda values e histórico em metadata['delta']; restauração aplica
histórico/outbox, não reconstrói registradores apenas de snapshot.state.

Validação: Falhas de commit local/remoto, isolamento de estado, concorrência e restauração versionada; validar MemoryStorage como contrato, sem alegar durabilidade.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.
<a id="r-05"></a>

## R-05 — Lifecycle e processamento remoto

Status: planejada
MoSCoW: MUST
Dependências: R-04

Baseline: parcial; correções ainda não concluídas.

start repetido e dispose repetido têm guardas, mas set/remove/setDelta/removeDelta
e push não exigem engine iniciada nem rejeitam engine descartada. Listener usa
callback async sem fila ou canal explícito de erro.

Critérios:

- [ ] Definir contrato de uso antes de start e após dispose; impedir mutação antes
  da restauração ou depois do descarte, conforme contrato.
- [ ] Falha de start permite recuperação ou estado terminal documentado; _started
  não pode sugerir sucesso após falha de carregamento.
- [ ] Processamento remoto aguardado/serializado; erros observáveis e sem aplicação
  parcial ou confirmação antes do commit.
- [ ] dispose trata operação em andamento e impede novos trabalhos.
- [ ] Testar start falho, entrada inválida, falha de storage, concorrência e
  cancelamento; guarda isolada não comprova lifecycle completo.

Validação: Start falho/repetido, mutação fora do lifecycle, callback remoto com erro, concorrência e dispose com trabalho em andamento.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

## Gate da fase

Revisar diff de cada tarefa, executar verificações acima e análise dos pacotes
afetados. Concluir fase somente com evidências de R-01 a R-05. Contrato de identidade
libera fase 2; commit atômico libera fase 3; envelope pode ser trabalhado após R-02.
