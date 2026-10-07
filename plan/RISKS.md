# Riscos — DeltaSync

Revisão: 2026-10-04. Responsável pelas correções: autor/implementador da tarefa.
Não atribuir probabilidades numéricas sem dados.

| ID | Situação/probabilidade | Impacto e gatilho | Mitigação/tarefas |
|---|---|---|---|
| RISK-01 | divergência mitigada em R-01; legado temporário | LWW legado divergia com três eventos; coexistência de políticas ainda favorece uso incorreto | R-01 conserva regressão; R-09a consolida caminho nativo e compatibilidade |
| RISK-02 | mitigado em R-03 | ACK parcial removia lote e impedia retry da parte não confirmada | `ReplicaStorage.acknowledge` preserva mudanças sem ACK; regressões em storage e sync |
| RISK-03 | colisões antigas mitigadas; vínculo de tipo parcial | Counters independentes colidiam IDs; mesmo endereço ainda aceita LWW e counter | R-02 corrigiu identidade/roteamento; R-09b unifica estado e vínculo; R-07a consolida oito tipos |
| RISK-04 | mitigado pelo contrato em SQLite FFI; recuperação sync entre sessões pendente | Adaptador persistente pode violar atomicidade ou divergir após falha | R-07c executa suíte compartilhada e falha SQL dentro de commit; R-07d cobre retomada e engine |
| RISK-05 | mitigado em R-05 | Falha de aplicação remota ou erro do stream precisa chegar ao consumidor sem mutação parcial | `SyncEngine.errors` publica falhas de callback; `applyRemote` continua aguardável e commit precede adoção |
| RISK-06 | SQLite real reabre snapshot e preserva ID; recuperação do SyncEngine entre sessões pendente | MemoryStorage confundido com recuperação completa entre sessões | R-07c valida reabertura em SQLite FFI/Linux; R-07d testa engine, outbox, HLC e falhas |
| RISK-07 | mitigado para G/PN, MV-Register e OR-Set; OR-Map pendente | Tratar dot máximo como prova de entrega de eventos individuais ausentes perde mudanças | R-02/R-08b: counters atuais carregam componente cumulativo; R-06c preserva contexto por dots explícitos; R-06d remove por tags exatas observadas, sem inferir entrega por máximo |
| RISK-08 | mitigado no enlace ponto a ponto; topologia geral fora de escopo | Peer ausente não recupera delta já removido da outbox | R-08b mantém outbox por destinatário até ACK `appliedAndPersisted`; retry ao reconectar; peers adicionais exigem cópia/ACK individual |
| RISK-09 | prazo/estimativas desconhecidos | Oito tipos, OR-Map e persistência durável não cabem no prazo disponível | Sequenciar incrementos e informar cronograma; recorte só com decisão acadêmica explícita |
| RISK-10 | divergência documental confirmada | Texto final descreve módulos/API/SQLite diferentes da entrega | VAL-04; atualizar fonte editável e diagrama, preservar referência |
| RISK-11 | mitigado no plano; monitorar | Codegen/ObjectCrdt/GC, ORM, framework de plugins ou adaptadores persistentes oficiais adicionais viram obrigação e desviam esforço | DEC-08/23; escopo centralizado, extensão por contrato público e um adaptador persistente oficial de referência |
| RISK-12 | limitação conhecida | Review pelo próprio implementador deixa erro conceitual passar | code-reviewer em etapa separada, regressões/permutações; não anunciar revisão independente |
| RISK-13 | isolamento confirmado no contrato SQLite; recuperação durável do SyncEngine pendente | Listas/mapas aninhados alteram estado/snapshot/outbox sem delta; referência de Replica contorna commit e pode perder alteração | R-09b copia/congela payloads e isola engine; R-07c valida adapter; R-07d repete recuperação após reabertura |
| RISK-14 | contrato SQLite real validado; engines simultâneas com outbox durável pendentes | Espera de rede não pode bloquear commit/aplicação remota; engines separadas ainda não coordenam seleção concorrente da mesma outbox | R-05/R-08d cobrem engines em memória; R-07d repete envio simultâneo, falha/retry e edição enquanto ACK aguarda usando SQLite |
| RISK-15 | mitigado em R-05 | Estado não restaurado pode ser sobrescrito; início falho pode bloquear retry; uso após descarte pode alterar estado | Primeira operação aguarda restauração, start falho retorna a created e dispose é terminal; testes de lifecycle |
| RISK-16 | mitigado com limite explícito | Modelos duplicados e histórico ilimitado ampliam custo de alteração e cópia; exportação/ID conflitante mudam após restore | R-09a/R-09b removem log operacional e documentam bootstrap/deduplicação limitada; exemplos de R-08d permitem revisar fluxo sem framework novo |
| RISK-17 | mitigado no fluxo genérico mínimo; Compass não exercitado | Requisito específico de um consumidor pode vazar para o core, criando hooks, overrides ou dependências que outros apps não precisam | DEC-15/AGENTS.md; exemplo R-08d usa facade e contratos públicos sem adaptação específica; VAL-02 demonstra integração de consumidor |

Atualizar situação quando evidência mudar. Risco resolvido mantém histórico e
referência à tarefa/validação que demonstrou mitigação.
