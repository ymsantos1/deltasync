# Decisões — DeltaSync

Revisão: 2026-10-03. “Adotada” é escolha de planejamento/arquitetura;
não significa implementação concluída.

| ID | Estado | Decisão e fundamento |
|---|---|---|
| DEC-01 | adotada | Oito CRDTs do PDF preservados; autor reafirmou escopo em 2026-10-03. Limpeza da implementação antecede expansão; ferramentas sugeridas não ampliam requisitos acadêmicos. |
| DEC-02 | adotada | Core/sync/storage abstrato/transport em Dart puro; SQLite/sqflite em adaptador de referência previsto no TCC e opcional ao consumidor. |
| DEC-03 | adotada | DeltaCrdt como contrato central; HLC para LWW nativo, dots/contexto causal para tipos observados. Legado exige correção ou migração explícita. |
| DEC-04 | adotada | Roteamento e identidade únicos por CRDT; endereço estável acompanha mudança e dot local é namespaceado por `crdtId`. |
| DEC-05 | adotada | Estado, clocks e outbox têm contrato de commit atômico; snapshots versionados restauram estado sem replay ilimitado. R-04 implementou contrato/MemoryStorage; isolamento de payload/referência e fila requerem R-09b/R-05. Durabilidade continua pendente em R-07c/R-07d. |
| DEC-06 | adotada | Preservar tombstones/contexto necessário; nenhum GC destrutivo por idade ou ACK de envio. |
| DEC-07 | adotada | Demonstração mínima mantida como MUST pelo contexto atual; PDF a apresenta como possibilidade. Sem framework de objetos obrigatório. |
| DEC-08 | adotada | build_runner, codegen, ObjectCrdt, migração genérica de modelos, sequências e anti-entropy arbitrário ficam WON'T-YET. |
| DEC-09 | adotada | Um agente com procedimentos de leitura/implementação/review/validação/manutenção. Sem subagentes ou diretório de papéis por padrão. |
| DEC-10 | adotada | Planejamento em plan/, skills locais em .agents/skills/; sem RICE nem estrutura paralela. Seleção por dependência, correção e risco. |
| DEC-11 | adotada | Pedido de implementação de tarefa/fase aplica plan-executor e cinco skills por tarefa; conclusão exige review, validação, evidências e manutenção consistentes. Pedido só de consulta/review mantém escopo restrito. |
| DEC-12 | adotada | Consolidar DeltaCrdt e caminho nativo dos três tipos atuais, eliminando classes sem uso e representações legadas sobrepostas. R-09a define compatibilidade antes de alterar APIs/formatos; abstrações adicionais exigem uso concreto no escopo. |
| DEC-13 | adotada | Estado por endereço com vínculo de tipo, snapshot canônico e outbox por mudança; proteção de valores aninhados e escrita da réplica ativa em R-09b. Rede/ACK fora da fila de commits em R-05; sem log ilimitado no caminho normal. |
| DEC-14 | adotada | R-08d comprova fluxo dos três tipos atuais com duas engines antes de expandir tipos. Cada R-06 inclui integração; R-07a consolida oito tipos e SQLite. Exemplos curtos explicam responsabilidades e invariantes, sem quota de classes. |
| DEC-15 | adotada | Uso real, integração e manutenção/forks são critérios transversais. Compass é exemplo de consumidor, sem direcionar core/gate. Consumidores adaptam modelos e fluxos usando API pública, composição e adaptadores; DeltaSync muda por necessidade geral prevista ou defeito de contrato. Não sobrescrever implementações internas nem criar plugins genéricos. R-08d testa consumidor simples; VAL-02 aceita demonstração sem Compass. |

## Decisões abertas

| ID | Tarefa | Questão e limite atual |
|---|---|---|
| OPEN-02 | R-03, R-08b | R-03 resolveu ACK por mudança: apenas IDs do lote enviado confirmados após aplicação e persistência remota durável; ACK parcial preserva restante. Identidade de destino e confirmação por participante seguem para topologia R-08b. |
| OPEN-03 | R-07c | Criação da identidade persistente e política de backup/restore. R-04 restaura o mesmo `replicaId` do snapshot e não clona identidade ativa. |
| OPEN-04 | R-08b | Topologia e retenção/retransmissão/replay ou fallback de snapshot para peer offline. |
| OPEN-05 | VAL-04 | Fonte editável e atualização do texto acadêmico; PDF de referência permanece preservado. |
| OPEN-06 | VAL-05 | Prazo, esforço disponível e cronograma. Viabilidade no prazo ainda não confirmada. |
| OPEN-07 | R-09a, R-09b | Inventário de consumidores e política de APIs/formatos antigos: remoção com quebra documentada, wrappers temporários ou conversão isolada. Consumidores externos ainda não verificados; não manter dois modelos permanentes por conveniência. |

Abertura de decisão não impõe pausa automática. Resolver escolhas técnicas
rotineiras dentro da tarefa autorizada, registrar fundamento e validar.
Mudança material de recorte acadêmico ou ação externa depende de direção do autor.

## Invariantes de engenharia

- Correção de CRDT vem do join, não de deduplicação por ID.
- HLC ordena LWW nativo; dots/contexto causal servem a tipos observados.
- IDs de mensagem e identidade causal têm funções distintas. R-02 endereça dots
  locais por `crdtId`; G-Counter/PN-Counter carregam valores
  cumulativos e toleram lacunas. Tipos futuros cuja semântica dependa de dots
  individuais precisam de contexto causal por endereço com lacunas explícitas ou
  pré-condição de entrega causal, sem achatar sequência local em VectorClock.
- Um componente máximo de VectorClock não prova recebimento de todos os dots
  anteriores quando deltas chegam fora de ordem. Representar lacunas ou usar
  pré-condições explícitas de entrega; testar perda do evento anterior.
- Cada dispositivo persiste sua réplica materializada e conhecimento causal
  necessário, sem exigir cópias completas de todas as réplicas remotas.
- Persistir estado, clocks e outbox local em uma transação. Só confirmar sucesso
  da mutação quando commit terminar; falha não pode deixar memória e disco
  discordantes. Serializar commits e merges remotos.
- Espera de rede/ACK ocorrer fora da fila de commits; edição local e recepção
  precisam continuar durante envio. Inicialização restaurar antes de aceitar
  mutações; descarte e falhas serem observáveis.
- Valores fornecidos/consultados e referência de Replica não permitirem alterar
  estado comprometido ou pendências fora do pipeline. Fonte de tempo injetada
  permanecer válida ao preparar candidata.
- Recuperar estado sem depender de replay ilimitado do histórico. Preservar
  tombstones, clocks e sequências após snapshot/restauração.
- Definir ACK por mudança ou por envelope inteiro; nunca apagar deltas não
  confirmados. Retorno de send não prova incorporação remota.
- Manter tombstones/contexto necessário durante o TCC; sem GC por idade.
- Documentar topologia, quem recebe/guarda deltas e como replica offline recupera
  mensagens. Duas réplicas fixas com retransmissão até confirmação durável são
  cenário inicial suficiente; topologias maiores exigem outra política.
- Versionamento e rejeição explícita de formatos incompatíveis são decisões
  técnicas; não exigem framework genérico de migração.
- Core manter uma representação nativa de mudança e estado canônico por endereço.
  HLC, componentes monotônicos e contexto observado atendem semânticas distintas;
  deduplicação eterna e relógio universal não são substitutos dos joins.

## Histórico da reorganização

Em 2026-09-27, a pedido do autor, planos anteriores migrados para arquivos por fase,
com rastreabilidade, decisões, riscos e cinco skills. R-06/R-07/R-08 desmembrados
sem aumento do escopo funcional; R-01 e R-03 mantidos como primeiras tarefas.
Alternativas não adotadas: agentes especializados paralelos, RICE sem dados,
duplicação de critérios entre skills e tarefas.

Ainda em 2026-09-27, autor restaurou moscow.md como referência e solicitou ponto
de entrada para ciclo completo. Adotados plan-executor, RUNBOOK e checker local
somente de leitura, sem executar tarefas de produto durante sua criação.

Em 2026-10-03, autor pediu atualização da análise e do plano para limpeza de classes
e melhoria da estrutura, preservando oito tipos. Adotadas DEC-12 a DEC-14; R-09a,
R-09b e R-08d tornam correções/integração explícitas. Código não foi implementado
nesta revisão documental. Redução de tipos sugerida na conversa não foi adotada.

Ainda em 2026-10-03, autor autorizou incorporar uso real no Compass e facilidade
de integração, manutenção, contribuição e forks. DEC-15 e orientações de AGENTS.md
valem para todas as tarefas; critérios existentes foram ampliados, sem novas
tarefas/tipos nem implementação de produto nesta manutenção.

Em 2026-10-03, autor esclareceu que Compass serve como exemplo de consumo.
Consumidor deve se adaptar aos contratos públicos; mudança na biblioteca exige
necessidade geral prevista ou correção de defeito. DEC-15, R-08d, VAL-02/04/05 e
AGENTS.md refletem esse limite. Compass deixa de ser requisito de gate; detalhes
específicos dele não justificam modificar DeltaSync.
