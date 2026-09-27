# Fase 3 — Persistência durável de referência

Estado: planejada. Objetivo: comprovar durabilidade mantendo contrato Dart puro.
Entrada: R-04 concluída; não depende de finalizar todos os CRDTs.
Saída: contrato validado, adaptador sqflite e recuperação real com falhas testadas.
Riscos: commit parcial, regressão de identidade/clocks, backup com ID duplicado.
Exclusões: suporte simultâneo a todos os bancos e persistência de réplicas remotas
inteiras. Tabelas são detalhes do adaptador, não contrato obrigatório do core.

<a id="r-07b"></a>

## R-07b — Suíte de contrato de storage

Status: planejada
MoSCoW: MUST
Dependências: R-04

Áreas: packages/deltasync_storage/lib/src/ e testes de contrato compartilhados.
Objetivo: verificar contrato de commits/snapshots/outbox em adaptadores.

Critérios:

- [ ] Mesma suíte executável em MemoryStorage e adaptadores persistentes.
- [ ] Commit local/remoto, versões, ACK e metadados verificáveis.
- [ ] Falha injetada não deixa estado/outbox parcialmente confirmados.
- [ ] Testes de memória identificados como simulação, não reinício de processo.

Validação: suíte de contrato em MemoryStorage, incluindo falha e concorrência.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-07c"></a>

## R-07c — Adaptador SQLite/sqflite

Status: planejada
MoSCoW: MUST
Dependências: R-07b

Áreas: novo packages/deltasync_storage_sqflite/, workspace e testes de integração.
Objetivo: implementar adaptador opcional ao consumidor e entregue no TCC.

Critérios:

- [ ] Schema inicial versionado e tratamento de versão incompatível definidos.
- [ ] Estado, clocks e outbox persistidos na mesma transação local.
- [ ] Merge remoto persistido atomicamente.
- [ ] Identidade durável; comportamento de cópia/backup documentado.
- [ ] Suíte R-07b aprovada no adaptador.
- [ ] Core e sync continuam sem dependência de Flutter, SQL ou sqflite.

Validação: analisar/buildar pacote na plataforma suportada e executar contrato
com SQLite real. Registrar dispositivo/plataforma; não substituir por mock.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-07d"></a>

## R-07d — Recuperação durável e falhas

Status: planejada
MoSCoW: MUST
Dependências: R-05, R-07c

Áreas: adaptador sqflite, sync e testes de recuperação/injeção de falhas.
Objetivo: comprovar recuperação entre sessões, não apenas reuso de objeto em memória.

Critérios:

- [ ] Fechar/reabrir banco e recriar engine preserva estado e pendências.
- [ ] Identidade, HLC, dots, sequências e tombstones não regressam.
- [ ] Interrupção antes do envio e após envio/antes do ACK mantém recuperação.
- [ ] Falhas transacionais não produzem snapshot sem outbox necessária.
- [ ] Limites de backup/restore e plataforma documentados.

Validação: integração SQLite real, reabertura e falhas em etapas do commit;
registrar evidências específicas, separadas dos testes de MemoryStorage.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.


## Gate da fase

R-07b, R-07c e R-07d concluídas. Fase pode avançar inicialmente com LWW; suporte
aos oito tipos também depende de R-07a antes da conclusão integrada do TCC.
