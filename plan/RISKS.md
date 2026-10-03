# Riscos — DeltaSync

Revisão: 2026-10-03. Responsável pelas correções: autor/implementador da tarefa.
Não atribuir probabilidades numéricas sem dados.

| ID | Situação/probabilidade | Impacto e gatilho | Mitigação/tarefas |
|---|---|---|---|
| RISK-01 | divergência mitigada em R-01; legado temporário | LWW legado divergia com três eventos; coexistência de políticas ainda favorece uso incorreto | R-01 conserva regressão; R-09a consolida caminho nativo e compatibilidade |
| RISK-02 | mitigado em R-03 | ACK parcial removia lote e impedia retry da parte não confirmada | `ReplicaStorage.acknowledge` preserva mudanças sem ACK; regressões em storage e sync |
| RISK-03 | colisões antigas mitigadas; vínculo de tipo parcial | Counters independentes colidiam IDs; mesmo endereço ainda aceita LWW e counter | R-02 corrigiu identidade/roteamento; R-09b unifica estado e vínculo; R-07a consolida oito tipos |
| RISK-04 | mitigado no contrato/MemoryStorage; durabilidade ainda não validada | Adaptador persistente pode violar atomicidade ou divergir após falha | R-04 cobre contrato; R-07b/R-07c/R-07d exigem contrato e recuperação durável |
| RISK-05 | mutações/merges serializados em R-04; erro do listener ainda sem canal observável | Falha assíncrona remota pode não chegar ao consumidor | R-05; ciclo de vida, callback remoto e erros observáveis |
| RISK-06 | lacuna confirmada | MemoryStorage confundido com recuperação entre sessões | R-07c/R-07d; SQLite real, fechamento/reabertura e ambiente registrado |
| RISK-07 | lacuna confirmada | VectorClock máximo trata evento posterior como entrega de anteriores ausentes | R-02/R-06c/R-06d/R-08b; contexto com lacunas ou entrega causal assegurada |
| RISK-08 | política pendente | Peer ausente não recupera delta já removido da outbox | R-08b/R-08c; retenção/replay/snapshot e topologia explícitos |
| RISK-09 | prazo/estimativas desconhecidos | Oito tipos, OR-Map e persistência durável não cabem no prazo disponível | Sequenciar incrementos e informar cronograma; recorte só com decisão acadêmica explícita |
| RISK-10 | divergência documental confirmada | Texto final descreve módulos/API/SQLite diferentes da entrega | VAL-04; atualizar fonte editável e diagrama, preservar referência |
| RISK-11 | mitigado no plano; monitorar | Codegen/ObjectCrdt/GC viram obrigação e desviam esforço | DEC-08; escopo centralizado e origem de novos requisitos |
| RISK-12 | limitação conhecida | Review pelo próprio implementador deixa erro conceitual passar | code-reviewer em etapa separada, regressões/permutações; não anunciar revisão independente |
| RISK-13 | falha reproduzida | Listas/mapas aninhados alteram estado/snapshot/outbox sem delta; referência de Replica contorna commit e pode perder alteração | R-09b; propriedade dos dados, consulta protegida, escrita controlada e regressões de isolamento |
| RISK-14 | falha reproduzida | Push mantém fila enquanto aguarda rede; duas engines enviando simultaneamente bloqueiam aplicação e ACK, inclusive edição offline | R-05 separa rede/commits; R-08d testa duas engines; R-07d repete com SQLite |
| RISK-15 | falha reproduzida | Mutação antes de start sobrescreve snapshot; start falho impede retry e mutação após dispose continua aceita | R-05; inicialização aguardada, falhas e descarte definidos; regressões de perda/restauração |
| RISK-16 | estrutura confirmada por inspeção | Modelos duplicados e histórico ilimitado ampliam custo de alteração e cópia; exportação/ID conflitante mudam após restore | R-09a/R-09b consolidam contratos e limites; exemplos de R-08d permitem revisar fluxo sem framework novo |
| RISK-17 | risco inferido | Requisito específico de um consumidor pode vazar para o core, criando hooks, overrides ou dependências que outros apps não precisam | DEC-15/AGENTS.md; R-08d testa consumidor via contratos públicos, VAL-02 aceita qualquer consumidor pequeno, adaptação do Compass fica no app |

Atualizar situação quando evidência mudar. Risco resolvido mantém histórico e
referência à tarefa/validação que demonstrou mitigação.
