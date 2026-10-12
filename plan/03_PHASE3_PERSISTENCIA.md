# Fase 3 — Persistência durável de referência

Estado: pendente de R-12. Objetivo: comprovar durabilidade mantendo contrato Dart puro.
Entrada: R-08d concluída; contrato consolidado e três tipos com fluxo em memória.
Não depende de finalizar cinco tipos restantes.
Saída: contrato validado, adaptador persistente de referência SQLite/sqflite e
recuperação real com falhas testadas, incluindo as regressões de R-11/R-12.
Riscos: commit parcial, regressão de identidade/clocks, backup com ID duplicado,
payload divergente ignorado e abertura falha sem retry (RISK-18/19).
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


<a id="r-11"></a>

## R-11 — Rejeitar payload divergente para ID pendente

Status: concluída
MoSCoW: MUST
Dependências: R-07b, R-07c, R-07d

Áreas: contrato/suíte de storage, MemoryStorage e SqfliteReplicaStorage.
Objetivo: alinhar SQLite à rejeição de ID pendente reutilizado com conteúdo
divergente. MUST por permitir snapshot novo com outbox antiga sem erro.
Diagnóstico: dois commits com mesmo ID e valores old/new preservam snapshot=new
e outbox=old no SQLite; MemoryStorage rejeita o segundo commit.

Critérios:

- [x] Commit e enqueue rejeitam payload divergente para o mesmo ID pendente;
  definir equivalência conforme o contrato público de delta e destinatário.
- [x] Retransmissão equivalente continua idempotente e preserva metadados de
  envio/tentativas existentes; não substituir silenciosamente a entrada.
- [x] Verificação ocorre na transação; falha mantém snapshot, clocks e toda a
  outbox anteriores, inclusive em lote com entradas novas antes do conflito.
- [x] Suíte compartilhada cobre duplicata equivalente e divergente em commit
  e enqueue, executada em MemoryStorage e SQLite real.
- [x] Fechar/reabrir SQLite comprova preservação de snapshot, payload e metadados
  após rejeição; erros são observáveis ao consumidor sem confirmação de sucesso.
- [x] Documentar comportamento e compatibilidade; não criar histórico ilimitado
  de IDs confirmados nem migração destrutiva para corrigir pendência conflitante.

Validação: regressão do diagnóstico, rollback de lote e comparação dos dois
adaptadores. Format/analyze/test nos pacotes afetados; integração de engine/facade
quando contrato afetado. Review após correções e evidência SQLite após reabertura.

Evidência de diagnóstico: [revisão de 2026-10-11](TRACEABILITY.md#revisao-tecnica-2026-10-11).
Evidência de conclusão: [execução R-11 — 2026-10-12](TRACEABILITY.md#execucao-r-11-2026-10-12).

<a id="r-12"></a>

## R-12 — Retry após falha de abertura SQLite

Status: pronta
MoSCoW: MUST
Dependências: R-05, R-07c, R-07d

Áreas: abertura/fechamento de SqfliteReplicaStorage e integração de SyncEngine.
Objetivo: permitir nova tentativa após falha transitória de abertura no mesmo
adaptador. MUST por inviabilizar o retry de start já previsto no lifecycle.
Diagnóstico: _opening retém Future falho; duas chamadas de loadReplica falham
com apenas uma abertura na factory. Recuperação exige close explícito atualmente.

Critérios:

- [ ] Falha de abertura não mantém Future falho como resultado permanente;
  nova chamada pode abrir o banco sem exigir close ou recriar o adaptador.
- [ ] Chamadas concorrentes compartilham a tentativa em curso; tratamento de
  falha antiga não invalida abertura posterior bem-sucedida.
- [ ] SyncEngine.start falha de forma observável, permite retry no mesmo
  adaptador e restaura estado/outbox antes de aceitar mutações.
- [ ] Regressões cobrem primeira abertura falha seguida de sucesso, concorrência
  e close conforme contrato; SQLite real verifica estado recuperado.
- [ ] Schema incompatível continua rejeitado sem apagar dados; retry não mascara
  erro persistente nem altera formatos/identidade para forçar recuperação.
- [ ] Documentar retry e limites para consumidor/manutenção; core e sync não
  adquirem dependência de SQLite ou política de reconexão do backend.

Validação: factory com falha injetada na primeira abertura e SQLite real na segunda;
integração de start/retry com dados persistidos. Format/analyze/test nos pacotes
afetados e review após correções, incluindo lifecycle e concorrência.

Evidência de diagnóstico: [revisão de 2026-10-11](TRACEABILITY.md#revisao-tecnica-2026-10-11).
Evidência de conclusão: ainda não registrada.

## Gate da fase

R-07b, R-07c, R-07d e R-11 concluídas. A fase exige R-12 antes de fechar;
suporte durável aos oito tipos foi consolidado em R-07a.
