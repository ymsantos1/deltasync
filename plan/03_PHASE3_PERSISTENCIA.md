# Fase 3 — Persistência durável de referência

Estado: planejada. Objetivo: comprovar durabilidade mantendo contrato Dart puro.
Entrada: R-08d concluída; contrato consolidado e três tipos com fluxo em memória.
Não depende de finalizar cinco tipos restantes.
Saída: contrato validado, adaptador sqflite e recuperação real com falhas testadas.
Riscos: commit parcial, regressão de identidade/clocks, backup com ID duplicado.
Exclusões: suporte simultâneo a todos os bancos e persistência de réplicas remotas
inteiras. Tabelas são detalhes do adaptador, não contrato obrigatório do core.

<a id="r-07b"></a>

## R-07b — Suíte de contrato de storage

Status: planejada
MoSCoW: MUST
Dependências: R-08d

Áreas: packages/deltasync_storage/lib/src/ e testes de contrato compartilhados.
Objetivo: tornar reutilizáveis checks do contrato de R-09b e fluxo de R-08d
para execução em MemoryStorage e adaptadores persistentes.

Critérios:

- [ ] Mesma suíte executável em MemoryStorage e adaptadores persistentes.
- [ ] Commit local/remoto, versões, ACK e metadados verificáveis.
- [ ] Snapshot canônico e outbox por mudança não exigirem do adaptador conhecimento
  de classes CRDT concretas; dados retornados não permitirem mutação do storage.
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
- [ ] Adaptador consumir contrato consolidado; schema não duplicar estados/clocks
  nem adicionar abstrações de bancos sem uso no cenário do TCC.

Validação: analisar/buildar pacote na plataforma suportada e executar contrato
com SQLite real. Registrar dispositivo/plataforma; não substituir por mock.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="r-07d"></a>

## R-07d — Recuperação durável e falhas

Status: planejada
MoSCoW: MUST
Dependências: R-07c, R-08d

Áreas: adaptador sqflite, sync e testes de recuperação/injeção de falhas.
Objetivo: comprovar recuperação entre sessões, não apenas reuso de objeto em memória.

Critérios:

- [ ] Fechar/reabrir banco e recriar engine preserva estado e pendências.
- [ ] Identidade, HLC, dots, sequências e tombstones não regressam.
- [ ] Interrupção antes do envio e após envio/antes do ACK mantém recuperação.
- [ ] Falhas transacionais não produzem snapshot sem outbox necessária.
- [ ] Limites de backup/restore e plataforma documentados.
- [ ] Cenários de duas engines de R-08d serem executados com SQLite real, incluindo
  envio simultâneo, falha/retry e mutação enquanto ACK estiver pendente.

Validação: integração SQLite real, reabertura e falhas em etapas do commit;
registrar evidências específicas, separadas dos testes de MemoryStorage.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.


## Gate da fase

R-07b, R-07c e R-07d concluídas. Recuperação começa com três tipos existentes;
suporte durável aos oito tipos é consolidado em R-07a antes do gate final.
