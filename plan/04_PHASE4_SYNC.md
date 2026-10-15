# Fase 4 — Fluxo offline e reconciliação

Estado: R-24 MUST e R-26/R-27 SHOULD concluídas em 2026-10-13.
R-08a a R-08d mantêm conclusão histórica no cenário declarado.
Entrada: R-09b para envelopes; R-03 para confirmação; R-05 para integração inicial.
Storage durável e oito tipos são necessários antes do gate completo.
Saída: R-08a a R-08d concluídas com cenário/topologia e limitações declarados.
Riscos: ACK sem incorporação, peer ausente, lacunas causais e processamento remoto.
Exclusões: backend próprio, protocolo HTTP/WebSocket obrigatório, anti-entropy
para topologia arbitrária e GC destrutivo de tombstones.

<a id="r-08a"></a>

## R-08a — Integrar envelopes

Status: concluída
MoSCoW: MUST
Dependências: R-09b

Áreas: packages/deltasync_transport/, packages/deltasync_sync/ e codecs.
Objetivo: conectar mensagem lógica ao fluxo consolidado, hoje baseado diretamente
em Delta; preservar funções necessárias sem wrappers redundantes.

Critérios:

- [x] Envelope integrado ao sync/transporte ou imposto no contrato do adaptador.
- [x] Endereço do CRDT, tipo, origem, metadados e payload disponíveis.
- [x] Versões/tipos incompatíveis rejeitados explicitamente.
- [x] Serialização não impõe protocolo de rede concreto.
- [x] Envelope/codec têm uma representação efetivamente usada, com metadados
  comuns de R-09a; remover ou consolidar classes sem função distinta, documentando
  versões e quebras. Transporte ter resultado explícito de envio/ACK conforme contrato.

Validação: round-trip, versões inválidas e transmissão efetiva pelo fluxo de sync;
workspace completo.

Evidência de conclusão: execução R-08a em TRACEABILITY.md.

<a id="r-08b"></a>

## R-08b — Topologia e confirmação

Status: concluída
MoSCoW: MUST
Dependências: R-03, R-08a

Áreas: contratos de sync/transporte, decisão arquitetural e testes.
Objetivo: definir quem confirma, quem retém informação e como peer offline recupera.

Critérios:

- [x] Topologia mínima e destinatários documentados em DECISIONS.md.
- [x] ACK distingue envio, recebimento e incorporação/persistência.
- [x] Limpeza de outbox não impede destinatário ausente de recuperar mudanças.
- [x] Escolher retenção/retransmissão, replay ou snapshot compatível para cenário.
- [x] Contexto causal não trata máximo recebido como ausência de lacunas.
- [x] Destino de confirmação é estável no cenário escolhido; troca de transporte
  não ampliar implicitamente garantia para peers que não receberam mudanças.

Validação: cenário demonstrável com peer ausente e confirmação parcial; workspace
completo.
Duas réplicas fixas com retransmissão até confirmação durável são opção, não
prescrição de backend ou topologia universal.
MemoryStorage comprova lógica desse contrato; persistência remota real é validada
em R-07d/R-08c. Bootstrap de peer novo deve ter suporte explícito ou limite declarado.

Evidência de conclusão: execução R-08b em TRACEABILITY.md.

<a id="r-08d"></a>

## R-08d — Fluxo integrado dos três tipos atuais

Status: concluída
MoSCoW: MUST
Dependências: R-05, R-08a, R-08b

Áreas: core, sync, MemoryStorage, transporte de teste, facade e exemplo executável.
Objetivo: comprovar base consolidada antes da expansão com duas engines reais
usando LWW, G-Counter e PN-Counter sob topologia definida em R-08b.

Critérios:

- [x] Alteração local atravessar snapshot/outbox, mensagem, aplicação e commit na
  engine remota; transporte de teste devolver ACK somente após commit concluído.
- [x] Duas engines realizarem push simultâneo sem bloqueio; edição e recepção
  continuarem durante envio/ACK pendente e falha de rede.
- [x] ACK parcial, duplicação, reordenação e retry preservarem convergência e
  pendências novas criadas durante envio.
- [x] Falha de commit remoto impedir confirmação; restauração simulada preservar
  identidade, estado, tombstones e sequências dos três tipos.
- [x] Exemplo e diagrama curtos explicarem caminho de edição e responsabilidades;
  cenário ser reproduzível sem codegen e sem classes sem uso no fluxo.
- [x] Exemplo consumidor usar API pública para configurar, iniciar, editar,
  consultar e observar pendências/erros; aguardar commit local sem exigir rede.
  Registrar dúvidas do caminho público. Exercício deve usar consumidor genérico;
  se Compass for usado, mapear adaptação necessária no app. Mudar biblioteca apenas
  por defeito ou requisito geral dos oito CRDTs, não por necessidade do Compass.

Validação: testes com duas engines conectadas e commit remoto aguardado, incluindo
falhas controladas; executar exemplo. ACK fabricado sem aplicação remota não
satisfaz critérios. MemoryStorage é simulação, não recuperação entre processos;
mesmos cenários passam a SQLite em R-07d. Checks dos pacotes afetados e facade.

Evidência de conclusão: execução R-08d em TRACEABILITY.md.

<a id="r-08c"></a>

## R-08c — Reconciliação offline integrada

Status: concluída
MoSCoW: MUST
Dependências: R-07a, R-07d, R-08d

Áreas: sync, core, storage durável, transporte de teste e integração.
Objetivo: demonstrar reconciliação após períodos offline e reinicializações.

Critérios:

- [x] Duas réplicas divergem offline e convergem após entrega relevante completa.
- [x] Duplicação, reordenação, falha/retry e reconexão não perdem alterações.
- [x] Reinício antes do envio e antes do ACK preserva pendências.
- [x] Peer ausente recupera informação conforme política R-08b.
- [x] Aplicação remota confirmada somente conforme semântica definida.
- [x] Envio simultâneo e edição durante indisponibilidade não bloquearem commits
  locais; regressões de R-08d permanecerem aprovadas com storage durável.

Validação: fluxo com SQLite real e falhas controladas; testes de roteamento cobrem
oito tipos via R-07a. Cenário principal pode usar dois tipos, sem substituir
validação individual dos demais.

Evidência de conclusão: execução R-08c em TRACEABILITY.md.


<a id="r-17"></a>

## R-17 — Notificar commits concluídos pela API Dart

Status: concluída
MoSCoW: COULD
Dependências: R-05, R-08c

Áreas: contrato público de SyncEngine e integração do consumidor.
Objetivo: facilitar atualização de consumidores após commit remoto sem polling.
Lacuna identificada: `errors` informa falhas, mas não sinalizava alteração
incorporada com sucesso. R-17 adiciona evento Dart sem alterar contrato de ACK.

Critérios:

- [x] Justificar um contrato mínimo de notificação para mutações locais e remotas,
  com emissão somente após commit e adoção bem-sucedidos.
- [x] Core/sync continuam Dart puro; sem dependência de Flutter, callbacks que
  governem regras internas ou framework de plugins.
- [x] Erro/rollback não publica sucesso; listener não bloqueia nem invalida commit;
  lifecycle e descarte do stream ficam definidos e testados.
- [x] Documentar consumo para atualizar UI e distinguir evento de estado de ACK;
  exemplos e formato persistido permanecem compatíveis.

Validação: regressões de local/remoto, rollback e dispose no sync/facade;
analyze/test dos consumidores afetados. COULD: só selecionar com MUST resolvidos
e margem antes do congelamento; não condiciona VAL-05 ou VAL-08.
Evidência de motivação: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: [execução R-17 em 2026-10-12](TRACEABILITY.md#execucao-r-17-2026-10-12).

<a id="r-24"></a>

## R-24 — Centralizar codec público de confirmação remota

Status: concluída
MoSCoW: MUST
Dependências: R-08b, VAL-13

Áreas: DeltaAcknowledgement, contrato wire e adaptadores consumidores.
Origem: análise da integração Compass e autorização do autor em 2026-10-13.

Critérios:

- [x] Definir codec JSON público para ACK e validar peer, estágio e IDs na fronteira, reutilizando rótulos estáveis existentes. Descrever regras para entrada inválida.
- [x] Preservar formato usado no Compass e semântica received versus appliedAndPersisted; não alterar envelopes, outbox ou snapshots nem aceitar confirmação de peer divergente.
- [x] Cobrir round-trip, ACK vazio/parcial/duplicado e entradas inválidas; comprovar que erro ou ACK insuficiente não remove pendências indevidas.
- [x] Substituir montagem/decodificação duplicada no percurso consumidor autorizado e demonstrar uso por outro adaptador de teste. Revisar após correções e validar transport/sync/facade e consumidores afetados.

Validação: ciclo plan-executor, checks proporcionais ao contrato/consumidor afetado;
regressões e compatibilidade são obrigatórias na própria tarefa.
Evidência de motivação: [planejamento de ergonomia](TRACEABILITY.md#manutencao-ergonomia-2026-10-13).
Evidência de conclusão: [execução R-24](TRACEABILITY.md#execucao-r-24-2026-10-13).

<a id="r-26"></a>

## R-26 — Simplificar recepção e confirmação durável no consumidor

Status: concluída
MoSCoW: SHOULD
Dependências: R-24, VAL-13

Áreas: SyncEngine e apoio público ao fluxo remoto, independente de HTTP/Flutter.
Origem: análise da integração Compass e autorização do autor em 2026-10-13.

Critérios:

- [x] Comparar fluxo incoming existente e pull do Compass; escolher apoio mínimo com uso concreto nos dois percursos, sem framework de plugins ou protocolo obrigatório.
- [x] Centralizar sequência repetida de validação de envelope, aplicação durável e confirmação; deixar busca/rede configuráveis no adaptador e regras do domínio no consumidor.
- [x] ACK appliedAndPersisted ocorre somente após commit bem-sucedido; peer errado, rollback, falha de rede, duplicação e retry preservam estado/outbox. Edição local continua disponível durante espera de rede.
- [x] Preservar contratos existentes e lifecycle/cancelamento explícitos. Mostrar redução de coordenação no consumidor, revisar após correções e validar sync/transport/SQLite/facade e integração afetada.

Validação: ciclo plan-executor, checks proporcionais ao contrato/consumidor afetado;
regressões e compatibilidade são obrigatórias na própria tarefa.
Evidência de motivação: [planejamento de ergonomia](TRACEABILITY.md#manutencao-ergonomia-2026-10-13).
Evidência de conclusão: [execução R-26](TRACEABILITY.md#execucao-r-26-2026-10-13).

<a id="r-27"></a>

## R-27 — Facilitar acompanhamento público da sincronização

Status: concluída
MoSCoW: SHOULD
Dependências: R-26, R-17

Áreas: API Dart de observação e apresentação no consumidor.
Origem: análise da integração Compass e autorização do autor em 2026-10-13.

Critérios:

- [x] Inventariar commits/errors/pendingDelta/resultados de push; reutilizar contratos e escolher conveniência mínima, sem representações paralelas da mesma informação.
- [x] Distinguir commit local, pendência de envio e confirmação remota; definir estado inicial após restore, falhas, atualização e encerramento. Não inferir ACK de um evento de commit.
- [x] Cobrir commit/rollback, ACK parcial, falha/retry, reabertura e descarte/listeners. Confirmar que observação não bloqueia edição nem invalida commit.
- [x] Mostrar consumo sem polling desnecessário e sem Flutter no sync; documentar compatibilidade, revisar após correções e validar pacotes e consumidor afetados.

Validação: ciclo plan-executor, checks proporcionais ao contrato/consumidor afetado;
regressões e compatibilidade são obrigatórias na própria tarefa.
Evidência de motivação: [planejamento de ergonomia](TRACEABILITY.md#manutencao-ergonomia-2026-10-13).
Evidência de conclusão: [execução R-27](TRACEABILITY.md#execucao-r-27-2026-10-13).

## Gate da fase

R-24 exige codec e regressões antes de novo fechamento em VAL-05.
Reconciliação comprovada no cenário declarado. Push de outbox e testes de
serialização isolados não satisfazem este gate.
