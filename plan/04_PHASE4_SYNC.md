# Fase 4 — Fluxo offline e reconciliação

Estado: planejada. Objetivo: fechar fluxo de duas réplicas com transporte abstrato.
Entrada por tarefa: R-02 para envelopes; R-03 para confirmação; storage durável
e integração dos tipos antes do gate completo.
Saída: R-08a a R-08c concluídas com cenário/topologia e limitações declarados.
Riscos: ACK sem incorporação, peer ausente, lacunas causais e processamento remoto.
Exclusões: backend próprio, protocolo HTTP/WebSocket obrigatório, anti-entropy
para topologia arbitrária e GC destrutivo de tombstones.

<a id="r-08a"></a>

## R-08a — Integrar envelopes

Status: planejada
MoSCoW: MUST
Dependências: R-02

Áreas: packages/deltasync_transport/, packages/deltasync_sync/ e codecs.
Objetivo: conectar DeltaEnvelope ao fluxo, hoje baseado diretamente em Delta.

Critérios:

- [ ] Envelope integrado ao sync/transporte ou imposto no contrato do adaptador.
- [ ] Endereço do CRDT, tipo, origem, metadados e payload disponíveis.
- [ ] Versões/tipos incompatíveis rejeitados explicitamente.
- [ ] Serialização não impõe protocolo de rede concreto.

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

Validação: cenário demonstrável com peer ausente e confirmação parcial.
Duas réplicas fixas com retransmissão até confirmação durável são opção, não
prescrição de backend ou topologia universal.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-08c"></a>

## R-08c — Reconciliação offline integrada

Status: planejada
MoSCoW: MUST
Dependências: R-05, R-07a, R-07d, R-08b

Áreas: sync, core, storage durável, transporte de teste e integração.
Objetivo: demonstrar reconciliação após períodos offline e reinicializações.

Critérios:

- [ ] Duas réplicas divergem offline e convergem após entrega relevante completa.
- [ ] Duplicação, reordenação, falha/retry e reconexão não perdem alterações.
- [ ] Reinício antes do envio e antes do ACK preserva pendências.
- [ ] Peer ausente recupera informação conforme política R-08b.
- [ ] Aplicação remota confirmada somente conforme semântica definida.

Validação: fluxo com SQLite real e falhas controladas; testes de roteamento cobrem
oito tipos via R-07a. Cenário principal pode usar dois tipos, sem substituir
validação individual dos demais.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.


## Gate da fase

Reconciliação comprovada no cenário declarado. Push de outbox e testes de
serialização isolados não satisfazem este gate.
