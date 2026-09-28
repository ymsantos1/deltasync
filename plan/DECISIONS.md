# Decisões — DeltaSync

Revisão: 2026-09-27. “Adotada” é escolha de planejamento/arquitetura;
não significa implementação concluída.

| ID | Estado | Decisão e fundamento |
|---|---|---|
| DEC-01 | adotada | Oito CRDTs do PDF preservados; ferramentas sugeridas não ampliam requisitos acadêmicos. |
| DEC-02 | adotada | Core/sync/storage abstrato/transport em Dart puro; SQLite/sqflite em adaptador de referência previsto no TCC e opcional ao consumidor. |
| DEC-03 | adotada | DeltaCrdt como contrato central; HLC para LWW nativo, dots/contexto causal para tipos observados. Legado exige correção ou migração explícita. |
| DEC-04 | adotada | Roteamento e identidade únicos por CRDT; endereço estável acompanha mudança e dot local é namespaceado por `crdtId`. |
| DEC-05 | adotada | Estado, clocks e outbox devem ter commit atômico; snapshot restaurável sem histórico ilimitado. Implementação pendente em R-04. |
| DEC-06 | adotada | Preservar tombstones/contexto necessário; nenhum GC destrutivo por idade ou ACK de envio. |
| DEC-07 | adotada | Demonstração mínima mantida como MUST pelo contexto atual; PDF a apresenta como possibilidade. Sem framework de objetos obrigatório. |
| DEC-08 | adotada | build_runner, codegen, ObjectCrdt, migração genérica de modelos, sequências e anti-entropy arbitrário ficam WON'T-YET. |
| DEC-09 | adotada | Um agente com procedimentos de leitura/implementação/review/validação/manutenção. Sem subagentes ou diretório de papéis por padrão. |
| DEC-10 | adotada | Planejamento em plan/, skills locais em .agents/skills/; sem RICE nem estrutura paralela. Seleção por dependência, correção e risco. |
| DEC-11 | adotada | Pedido de implementação de tarefa/fase aplica plan-executor e cinco skills por tarefa; conclusão exige review, validação, evidências e manutenção consistentes. Pedido só de consulta/review mantém escopo restrito. |

## Decisões abertas

| ID | Tarefa | Questão e limite atual |
|---|---|---|
| OPEN-02 | R-03, R-08b | R-03 resolveu ACK por mudança: apenas IDs do lote enviado confirmados após aplicação e persistência remota durável; ACK parcial preserva restante. Identidade de destino e confirmação por participante seguem para topologia R-08b. |
| OPEN-03 | R-04, R-07c | Criação/persistência de identidade e política de backup/restore. Não clonar identidade ativa silenciosamente. |
| OPEN-04 | R-08b | Topologia e retenção/retransmissão/replay ou fallback de snapshot para peer offline. |
| OPEN-05 | VAL-04 | Fonte editável e atualização do texto acadêmico; PDF de referência permanece preservado. |
| OPEN-06 | VAL-05 | Prazo, esforço disponível e cronograma. Viabilidade no prazo ainda não confirmada. |

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

## Histórico da reorganização

Em 2026-09-27, a pedido do autor, planos anteriores migrados para arquivos por fase,
com rastreabilidade, decisões, riscos e cinco skills. R-06/R-07/R-08 desmembrados
sem aumento do escopo funcional; R-01 e R-03 mantidos como primeiras tarefas.
Alternativas não adotadas: agentes especializados paralelos, RICE sem dados,
duplicação de critérios entre skills e tarefas.

Ainda em 2026-09-27, autor restaurou moscow.md como referência e solicitou ponto
de entrada para ciclo completo. Adotados plan-executor, RUNBOOK e checker local
somente de leitura, sem executar tarefas de produto durante sua criação.
