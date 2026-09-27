# Riscos — DeltaSync

Revisão: 2026-09-27. Responsável pelas correções: autor/implementador da tarefa.
Não atribuir probabilidades numéricas sem dados.

| ID | Situação/probabilidade | Impacto e gatilho | Mitigação/tarefas |
|---|---|---|---|
| RISK-01 | falha reproduzida | LWW legado diverge com três eventos causalmente relacionados/concorrentes | R-01; regressão, caminho nativo e compatibilidade explícita |
| RISK-02 | falha reproduzida | ACK parcial remove lote e impede retry da parte não confirmada | R-03; confirmação por mudança ou lote completo |
| RISK-03 | falhas reproduzidas | Counters independentes colidem IDs; Replica rejeita counter delta | R-02/R-07a; identidade, endereço e roteamento de tipos |
| RISK-04 | lacuna confirmada; ocorrência não estimada | Commit separado/falha deixa memória, snapshot, clocks e outbox discordantes | R-04/R-07b/R-07c/R-07d; transações, isolamento e injeção de falha |
| RISK-05 | cópia compartilhada reproduzida; concorrência não validada | Callback remoto e mutações simultâneas causam inconsistência; cópia não isola rollback | R-04/R-05; estado isolado, processamento serial e erros observáveis |
| RISK-06 | lacuna confirmada | MemoryStorage confundido com recuperação entre sessões | R-07c/R-07d; SQLite real, fechamento/reabertura e ambiente registrado |
| RISK-07 | lacuna confirmada | VectorClock máximo trata evento posterior como entrega de anteriores ausentes | R-02/R-06c/R-06d/R-08b; contexto com lacunas ou entrega causal assegurada |
| RISK-08 | política pendente | Peer ausente não recupera delta já removido da outbox | R-08b/R-08c; retenção/replay/snapshot e topologia explícitos |
| RISK-09 | prazo/estimativas desconhecidos | Oito tipos, OR-Map e persistência durável não cabem no prazo disponível | Sequenciar incrementos e informar cronograma; recorte só com decisão acadêmica explícita |
| RISK-10 | divergência documental confirmada | Texto final descreve módulos/API/SQLite diferentes da entrega | VAL-04; atualizar fonte editável e diagrama, preservar referência |
| RISK-11 | mitigado no plano; monitorar | Codegen/ObjectCrdt/GC viram obrigação e desviam esforço | DEC-08; escopo centralizado e origem de novos requisitos |
| RISK-12 | limitação conhecida | Review pelo próprio implementador deixa erro conceitual passar | code-reviewer em etapa separada, regressões/permutações; não anunciar revisão independente |

Atualizar situação quando evidência mudar. Risco resolvido mantém histórico e
referência à tarefa/validação que demonstrou mitigação.
