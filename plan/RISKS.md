# Riscos — DeltaSync

Revisão: 2026-10-03. Responsável pelas correções: autor/implementador da tarefa.
Não atribuir probabilidades numéricas sem dados.

| ID | Situação/probabilidade | Impacto e gatilho | Mitigação/tarefas |
|---|---|---|---|
| RISK-01 | divergência mitigada em R-01; legado temporário | LWW legado divergia com três eventos; coexistência de políticas ainda favorece uso incorreto | R-01 conserva regressão; R-09a consolida caminho nativo e compatibilidade |
| RISK-02 | mitigado em R-03 | ACK parcial removia lote e impedia retry da parte não confirmada | `ReplicaStorage.acknowledge` preserva mudanças sem ACK; regressões em storage e sync |
| RISK-03 | colisões antigas mitigadas; vínculo de tipo parcial | Counters independentes colidiam IDs; mesmo endereço ainda aceita LWW e counter | R-02 corrigiu identidade/roteamento; R-09b unifica estado e vínculo; R-07a consolida oito tipos |
| RISK-04 | mitigado no contrato/MemoryStorage; durabilidade ainda não validada | Adaptador persistente pode violar atomicidade ou divergir após falha | R-04 cobre contrato; R-07b/R-07c/R-07d exigem contrato e recuperação durável |
| RISK-05 | mitigado em R-05 | Falha de aplicação remota ou erro do stream precisa chegar ao consumidor sem mutação parcial | `SyncEngine.errors` publica falhas de callback; `applyRemote` continua aguardável e commit precede adoção |
| RISK-06 | lacuna confirmada | MemoryStorage confundido com recuperação entre sessões | R-07c/R-07d; SQLite real, fechamento/reabertura e ambiente registrado |
| RISK-07 | lacuna confirmada | VectorClock máximo trata evento posterior como entrega de anteriores ausentes | R-02/R-06c/R-06d/R-08b; contexto com lacunas ou entrega causal assegurada |
| RISK-08 | política pendente | Peer ausente não recupera delta já removido da outbox | R-08b/R-08c; retenção/replay/snapshot e topologia explícitos |
| RISK-09 | prazo/estimativas desconhecidos | Oito tipos, OR-Map e persistência durável não cabem no prazo disponível | Sequenciar incrementos e informar cronograma; recorte só com decisão acadêmica explícita |
| RISK-10 | divergência documental confirmada | Texto final descreve módulos/API/SQLite diferentes da entrega | VAL-04; atualizar fonte editável e diagrama, preservar referência |
| RISK-11 | mitigado no plano; monitorar | Codegen/ObjectCrdt/GC viram obrigação e desviam esforço | DEC-08; escopo centralizado e origem de novos requisitos |
| RISK-12 | limitação conhecida | Review pelo próprio implementador deixa erro conceitual passar | code-reviewer em etapa separada, regressões/permutações; não anunciar revisão independente |
| RISK-13 | mitigado no fluxo em memória; durabilidade pendente | Listas/mapas aninhados alteram estado/snapshot/outbox sem delta; referência de Replica contorna commit e pode perder alteração | R-09b copia/congela payloads e isola engine; R-07c/R-07d validam adaptador persistente |
| RISK-14 | mitigado dentro de uma engine; uso simultâneo entre engines pendente | Espera de rede não pode bloquear commit/aplicação remota; engines separadas ainda não coordenam seleção concorrente da mesma outbox | R-05 move I/O para fora da fila interna; R-08d verifica duas engines; R-07d repete com SQLite |
| RISK-15 | mitigado em R-05 | Estado não restaurado pode ser sobrescrito; início falho pode bloquear retry; uso após descarte pode alterar estado | Primeira operação aguarda restauração, start falho retorna a created e dispose é terminal; testes de lifecycle |
| RISK-16 | mitigado com limite explícito | Modelos duplicados e histórico ilimitado ampliam custo de alteração e cópia; exportação/ID conflitante mudam após restore | R-09a/R-09b removem log operacional e documentam bootstrap/deduplicação limitada; exemplos de R-08d permitem revisar fluxo sem framework novo |
| RISK-17 | risco inferido | Requisito específico de um consumidor pode vazar para o core, criando hooks, overrides ou dependências que outros apps não precisam | DEC-15/AGENTS.md; R-08d testa consumidor via contratos públicos, VAL-02 aceita qualquer consumidor pequeno, adaptação do Compass fica no app |

Atualizar situação quando evidência mudar. Risco resolvido mantém histórico e
referência à tarefa/validação que demonstrou mitigação.
