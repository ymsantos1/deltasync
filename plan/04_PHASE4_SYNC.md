# Fase 4 — Fluxo offline e reconciliação

Estado: planejada. Objetivo: fechar fluxo de duas réplicas com transporte abstrato.
Entrada: R-09b para envelopes; R-03 para confirmação; R-05 para integração inicial.
Storage durável e oito tipos são necessários antes do gate completo.
Saída: R-08a a R-08d concluídas com cenário/topologia e limitações declarados.
Riscos: ACK sem incorporação, peer ausente, lacunas causais e processamento remoto.
Exclusões: backend próprio, protocolo HTTP/WebSocket obrigatório, anti-entropy
para topologia arbitrária e GC destrutivo de tombstones.

<a id="r-08a"></a>

## R-08a — Integrar envelopes

Status: planejada
MoSCoW: MUST
Dependências: R-09b

Áreas: packages/deltasync_transport/, packages/deltasync_sync/ e codecs.
Objetivo: conectar mensagem lógica ao fluxo consolidado, hoje baseado diretamente
em Delta; preservar funções necessárias sem wrappers redundantes.

Critérios:

- [ ] Envelope integrado ao sync/transporte ou imposto no contrato do adaptador.
- [ ] Endereço do CRDT, tipo, origem, metadados e payload disponíveis.
- [ ] Versões/tipos incompatíveis rejeitados explicitamente.
- [ ] Serialização não impõe protocolo de rede concreto.
- [ ] Envelope/codec terem uma representação efetivamente usada, com metadados
  comuns de R-09a; remover ou consolidar classes sem função distinta, documentando
  versões e quebras. Transporte ter resultado explícito de envio/ACK conforme contrato.

Validação: round-trip, versões inválidas e transmissão efetiva pelo fluxo de sync.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-08b"></a>

## R-08b — Topologia e confirmação

Status: planejada
MoSCoW: MUST
Dependências: R-03, R-08a

Áreas: contratos de sync/transporte, decisão arquitetural e testes.
Objetivo: definir quem confirma, quem retém informação e como peer offline recupera.

Critérios:

- [ ] Topologia mínima e destinatários documentados em DECISIONS.md.
- [ ] ACK distingue envio, recebimento e incorporação/persistência.
- [ ] Limpeza de outbox não impede destinatário ausente de recuperar mudanças.
- [ ] Escolher retenção/retransmissão, replay ou snapshot compatível para cenário.
- [ ] Contexto causal não trata máximo recebido como ausência de lacunas.
- [ ] Destino de confirmação ser estável no cenário escolhido; troca de transporte
  não ampliar implicitamente garantia para peers que não receberam mudanças.

Validação: cenário demonstrável com peer ausente e confirmação parcial.
Duas réplicas fixas com retransmissão até confirmação durável são opção, não
prescrição de backend ou topologia universal.
MemoryStorage comprova lógica desse contrato; persistência remota real é validada
em R-07d/R-08c. Bootstrap de peer novo deve ter suporte explícito ou limite declarado.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-08d"></a>

## R-08d — Fluxo integrado dos três tipos atuais

Status: planejada
MoSCoW: MUST
Dependências: R-05, R-08a, R-08b

Áreas: core, sync, MemoryStorage, transporte de teste, facade e exemplo executável.
Objetivo: comprovar base consolidada antes da expansão com duas engines reais
usando LWW, G-Counter e PN-Counter sob topologia definida em R-08b.

Critérios:

- [ ] Alteração local atravessar snapshot/outbox, mensagem, aplicação e commit na
  engine remota; transporte de teste devolver ACK somente após commit concluído.
- [ ] Duas engines realizarem push simultâneo sem bloqueio; edição e recepção
  continuarem durante envio/ACK pendente e falha de rede.
- [ ] ACK parcial, duplicação, reordenação e retry preservarem convergência e
  pendências novas criadas durante envio.
- [ ] Falha de commit remoto impedir confirmação; restauração simulada preservar
  identidade, estado, tombstones e sequências dos três tipos.
- [ ] Exemplo e diagrama curtos explicarem caminho de edição e responsabilidades;
  cenário ser reproduzível sem codegen e sem classes sem uso no fluxo.
- [ ] Exemplo consumidor usar API pública para configurar, iniciar, editar,
  consultar e observar pendências/erros; aguardar commit local sem exigir rede.
  Registrar dúvidas do caminho público. Exercício deve usar consumidor genérico;
  se Compass for usado, mapear adaptação necessária no app. Mudar biblioteca apenas
  por defeito ou requisito geral dos oito CRDTs, não por necessidade do Compass.

Validação: testes com duas engines conectadas e commit remoto aguardado, incluindo
falhas controladas; executar exemplo. ACK fabricado sem aplicação remota não
satisfaz critérios. MemoryStorage é simulação, não recuperação entre processos;
mesmos cenários passam a SQLite em R-07d. Checks dos pacotes afetados e facade.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-08c"></a>

## R-08c — Reconciliação offline integrada

Status: planejada
MoSCoW: MUST
Dependências: R-07a, R-07d, R-08d

Áreas: sync, core, storage durável, transporte de teste e integração.
Objetivo: demonstrar reconciliação após períodos offline e reinicializações.

Critérios:

- [ ] Duas réplicas divergem offline e convergem após entrega relevante completa.
- [ ] Duplicação, reordenação, falha/retry e reconexão não perdem alterações.
- [ ] Reinício antes do envio e antes do ACK preserva pendências.
- [ ] Peer ausente recupera informação conforme política R-08b.
- [ ] Aplicação remota confirmada somente conforme semântica definida.
- [ ] Envio simultâneo e edição durante indisponibilidade não bloquearem commits
  locais; regressões de R-08d permanecerem aprovadas com storage durável.

Validação: fluxo com SQLite real e falhas controladas; testes de roteamento cobrem
oito tipos via R-07a. Cenário principal pode usar dois tipos, sem substituir
validação individual dos demais.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.


## Gate da fase

Reconciliação comprovada no cenário declarado. Push de outbox e testes de
serialização isolados não satisfazem este gate.
