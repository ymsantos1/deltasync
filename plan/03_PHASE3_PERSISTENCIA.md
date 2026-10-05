# Fase 3 — Persistência durável de referência

Estado: concluída. Objetivo: comprovar durabilidade mantendo contrato Dart puro.
Entrada: R-08d concluída; contrato consolidado e três tipos com fluxo em memória.
Não depende de finalizar cinco tipos restantes.
Saída: contrato validado, adaptador persistente de referência SQLite/sqflite e
recuperação real com falhas testadas.
Riscos: commit parcial, regressão de identidade/clocks, backup com ID duplicado.
Exclusões: entrega/manutenção de adaptadores persistentes oficiais adicionais e
persistência de réplicas remotas inteiras. Adaptadores do consumidor permanecem
permitidos pelo contrato público. Tabelas e `DatabaseFactory` são detalhes do
adaptador SQLite; regras gerais estão no [escopo de storage](README.md#storage-e-adaptadores).

<a id="r-07b"></a>

## R-07b — Suíte de contrato de storage

Status: concluída
MoSCoW: MUST
Dependências: R-08d

Áreas: packages/deltasync_storage/lib/src/ e testes de contrato compartilhados.
Objetivo: tornar reutilizáveis checks do contrato de R-09b e fluxo de R-08d
para execução em MemoryStorage e adaptadores persistentes.

Critérios:

- [x] Mesma suíte executável em MemoryStorage e adaptadores persistentes.
- [x] Commit local/remoto, versões, ACK e metadados verificáveis.
- [x] Snapshot canônico e outbox por mudança não exigirem do adaptador conhecimento
  de classes CRDT concretas; dados retornados não permitirem mutação do storage.
- [x] Falha injetada não deixa estado/outbox parcialmente confirmados.
- [x] Testes de memória identificados como simulação, não reinício de processo.

Validação: suíte de contrato em MemoryStorage, incluindo falha e concorrência.

Evidência de conclusão: execução R-07b em TRACEABILITY.md.

<a id="r-07c"></a>

## R-07c — Adaptador SQLite/sqflite

Status: concluída
MoSCoW: MUST
Dependências: R-07b

Áreas: novo packages/deltasync_storage_sqflite/, workspace e testes de integração.
Objetivo: implementar o único adaptador persistente oficial de referência do TCC,
opcional ao consumidor que escolha outro backend via `ReplicaStorage`.

Critérios:

- [x] Schema inicial versionado e tratamento de versão incompatível definidos.
- [x] Estado, clocks e outbox persistidos na mesma transação local.
- [x] Merge remoto persistido atomicamente.
- [x] Identidade durável; comportamento de cópia/backup documentado.
- [x] Suíte R-07b aprovada no adaptador.
- [x] Core e sync continuam sem dependência de Flutter, SQL ou sqflite.
- [x] Adaptador consumir contrato consolidado; schema não duplicar estados/clocks
  nem adicionar abstrações de bancos sem uso no cenário do TCC.

Validação: analisar/buildar pacote na plataforma suportada e executar contrato
com SQLite real. Registrar dispositivo/plataforma; não substituir por mock.

Evidência de conclusão: execução R-07c em TRACEABILITY.md.

<a id="r-07d"></a>

## R-07d — Recuperação durável e falhas

Status: concluída
MoSCoW: MUST
Dependências: R-07c, R-08d

Áreas: adaptador sqflite, sync e testes de recuperação/injeção de falhas.
Objetivo: comprovar recuperação entre sessões, não apenas reuso de objeto em memória.

Critérios:

- [x] Fechar/reabrir banco e recriar engine preserva estado e pendências.
- [x] Identidade, HLC, dots, sequências e tombstones não regressam.
- [x] Interrupção antes do envio e após envio/antes do ACK mantém recuperação.
- [x] Falhas transacionais não produzem snapshot sem outbox necessária.
- [x] Limites de backup/restore e plataforma documentados.
- [x] Cenários de duas engines de R-08d serem executados com SQLite real, incluindo
  envio simultâneo, falha/retry e mutação enquanto ACK estiver pendente.

Validação: integração SQLite real, reabertura e falhas em etapas do commit;
registrar evidências específicas, separadas dos testes de MemoryStorage.

Evidência de conclusão: execução R-07d em TRACEABILITY.md.


## Gate da fase

R-07b, R-07c e R-07d concluídas. Recuperação começa com três tipos existentes;
suporte durável aos oito tipos é consolidado em R-07a antes do gate final.
