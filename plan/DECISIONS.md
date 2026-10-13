# Decisões — DeltaSync

Revisão: 2026-10-12. “Adotada” é escolha de planejamento/arquitetura;
não significa implementação concluída.

| ID | Estado | Decisão e fundamento |
|---|---|---|
| DEC-01 | adotada | Oito CRDTs do PDF preservados; autor reafirmou escopo em 2026-10-03. Limpeza da implementação antecede expansão; ferramentas sugeridas não ampliam requisitos acadêmicos. |
| DEC-02 | adotada | Core/sync/storage abstrato/transport em Dart puro; SQLite/sqflite em adaptador de referência previsto no TCC e opcional ao consumidor. `ReplicaStorage` é o ponto de extensão para outros backends. `DatabaseFactory` de `sqflite_common` configura somente o adaptador SQLite de R-07c. |
| DEC-03 | adotada | DeltaCrdt como contrato central; HLC para LWW nativo, dots/contexto causal para tipos observados. Legado exige correção ou migração explícita. |
| DEC-04 | adotada | Roteamento e identidade únicos por CRDT; endereço estável acompanha mudança e dot local é namespaceado por `crdtId`. |
| DEC-05 | adotada | Estado, clocks e outbox têm contrato de commit atômico; snapshots versionados restauram estado sem replay ilimitado. R-04 implementou contrato/MemoryStorage; R-07c valida transação SQLite real; R-07d valida recuperação do ciclo sync entre sessões e falhas, e R-08c valida reconciliação offline integrada após reinício. |
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
| DEC-16 | adotada | Usar recursos do Dart para reduzir duplicação, estados inválidos e esforço de manutenção. R-09a consolida tipos/metadados com serialização estável; R-09b alinha nulabilidade às invariantes. Enums, extensions, extension types, modificadores e pattern matching são ferramentas condicionadas a uso concreto, SDK e compatibilidade, sem quota de adoção ou hierarquias paralelas. Orientação canônica em AGENTS.md; aplicada no ciclo do RUNBOOK. |
| DEC-17 | adotada | R-09a publica os pacotes core/storage/sync/transport e facade como 2.0.0 para alterações incompatíveis. `Delta` contém só `DeltaChange`; versões 1/2 e snapshots antigos migram explicitamente. Aliases `set/remove`, `Delta.crdt/crdtChanges` permanecem depreciados até próxima versão principal; tipos de operação e base antigos saem do caminho operacional. Consumidores externos não inventariados, portanto não há promessa de compatibilidade além dos formatos documentados. |
| DEC-18 | adotada | R-09b remove histórico completo da `Replica`; `export()` é bootstrap compacto e snapshots internos v3 preservam tombstones, clocks e sequências conhecidas. Storage v2 mantém um payload canônico; v1 é migrado/rejeitado quando insuficiente. Outbox tem uma mudança por entrada e lote só no envio. Valores JSON são copiados/congelados; engine possui cópia da réplica. IDs antigos só podem ser comparados com estado vencedor/mais recente retido, sem deduplicação ilimitada. `PendingDeltaStore` fica depreciado como ponte. R-07b mantém `markSent` obrigatório para tentativa/horário e fornece suíte de contrato reutilizável aos adapters. |
| DEC-19 | adotada | R-05 restaura antes da primeira operação (ou via `start()` idempotente); falha permite retry. Lifecycle é terminal após `dispose`. Commit e aplicação remota ficam serializados; I/O de push ocorre fora da fila e ACK volta à fila apenas para IDs do lote capturado. `pendingDelta()`, `SyncPushResult` e `errors` distinguem retenção, confirmação e falhas do listener. Storage legado pode reter mudança já confirmada remotamente. |
| DEC-20 | adotada | `DeltaTransport` e `SyncEngine` usam `DeltaEnvelope` v2, com remetente/destinatário e payload `DeltaCodec`. `senderReplicaId` pode diferir das origens CRDT em mudanças encaminhadas. `send` confirma transmissão local; `DeltaAcknowledgement` distingue recebimento de incorporação/persistência. Serialização permanece neutra a protocolo; adapters antigos precisam migrar campos/assinaturas. |
| DEC-21 | adotada | Topologia R-08b é enlace ponto a ponto para peer fixo por `DeltaTransport`. Cada entrada outbox grava destinatário; envio, ACK parcial e remoção ficam limitados a esse peer. Ausência/falha mantém dados para retry; troca de adapter para outro peer não herda nem confirma pendência antiga. Destinatários adicionais exigem cópia por peer e ACK independente. Deltas G/PN atuais carregam componentes cumulativos; dot máximo de origem não é tratado como prova de que eventos individuais sem payload cumulativo foram recebidos. Tipos futuros com eventos individuais exigem contexto causal com lacunas ou entrega causal. |
| DEC-22 | adotada | R-07c mantém um payload `ReplicaSnapshot` versionado e outbox por mudança no schema SQLite v1. Versões de schema desconhecidas falham sem apagar dados; migrações futuras devem ser explícitas. `replicaId` restaura sem clonagem automática. Backup exige banco fechado e arquivos WAL/SHM juntos quando presentes, ou API SQLite de backup. |
| DEC-23 | adotada | Autor confirmou em 2026-10-04 o recorte de storage extensível com um único adaptador persistente oficial de referência. Outros backends são integrados pelo consumidor via `ReplicaStorage`; limites e evidências estão no [escopo de storage](README.md#storage-e-adaptadores). Não exigir outro backend persistente, ORM ou framework de plugins para concluir o TCC. |
| DEC-24 | adotada | Revisão de 2026-10-11 confirmou três defeitos de contratos existentes: R-10/R-11/R-12 são MUST e reabrem VAL-05. Priorizar R-11, R-12 e R-10 por integridade/recuperação/uso público, sem dependências artificiais entre correções. VAL-07 é SHOULD para evidência Flutter/mobile, adiável com justificativa; Linux/FFI não comprova plugin mobile. Preservar histórico e exigir regressões, review após correções e revalidação final. Escrita/revisão do TCC permanecem com o autor e fora do plano técnico. |
| DEC-25 | adotada | R-11 fixa equivalência da outbox por `(replicaId, recipientPeerId, entryId)` pendente: conteúdo do delta é comparado pela regra `Delta.merge`, inclusive JSON aninhado; metadados de envio da primeira entrada ficam preservados em retransmissão equivalente. Divergência lança `FormatException` e cancela o commit inteiro. SQLite executa consulta e inserção dentro de transação; schema e JSON persistido permanecem v1/v2. Não manter histórico ilimitado de IDs já confirmados. |
| DEC-26 | adotada | R-12 mantém em cache apenas abertura SQLite em curso ou bem-sucedida. Erro limpa o cache somente quando ele ainda aponta para a tentativa falha, preservando abertura posterior; o erro e stack seguem ao chamador. Chamadas concorrentes compartilham a tentativa. `SyncEngine.start()` reaproveita o mesmo adaptador após erro transitório; schema incompatível continua rejeitado sem migração ou apagamento automático. |

| DEC-27 | adotada | R-10 guarda valor LWW em cópia JSON canônica; `LwwDelta.value` e `LwwRegister.value/winner` devolvem cópias. Coleções com `T` específico exigem `decodeValue` em delta, register e restauração; conversão deve preservar conteúdo JSON. `const LwwDelta` deixa de existir para isolar entrada, com migração de código documentada. `Replica`/`SyncEngine` seguem em `Object?`; HLC, tombstones, snapshots e wire JSON não mudam. |

## Revisão geral, refatoração e prazo — 2026-10-12

DEC-28 — Adotada em 2026-10-12: revisão geral posterior ao fechamento confirmou
novos defeitos e imprecisão documental. R-13/R-14/R-15/R-18 são MUST; reabrir fase 1
e VAL-05, preservar conclusões anteriores como evidência histórica e exigir
regressões/review/revalidação. R-16 e VAL-08/09/10 são SHOULD; R-17 é COULD.
Melhorias não se tornam requisitos acadêmicos por terem sido sugeridas.

DEC-29 — Adotada para planejamento: refatoração por responsabilidades, sem
reescrita geral dos algoritmos. Movimentos em core, sync/storage e testes ficam em
R-16; divisão do consumidor acompanha VAL-08. Aplicar safe-refactor com baseline
e mesma prova após cada extração, mantendo contratos/exports/JSON/schema/invariantes.
Código morto exige ausência comprovada de uso, considerando APIs e migração.
Operation e PendingDeltaStore têm referências e política de compatibilidade;
nenhuma remoção pública foi autorizada por este pedido documental.

DEC-30 — Adotada como orientação de prazo: entrega informada pelo autor em
16/11/2026; congelamento estrutural proposto para 02/11, com margem de validação
e correções. Janelas do índice são proposta, não estimativa nem promessa de
capacidade. SHOULD pode ser adiada com evidência; MUST permanece obrigatório.
Notificação de commits e execução entre dois aparelhos não condicionam fechamento.
Economia de deltas depende da carga; medir cenários desfavoráveis sem introduzir
compactação/GC ou alegar ganhos universais. Escrita do TCC continua com o autor.

DEC-31 — Adotada para planejamento após análise da referência C++: reforçar
VAL-09 com lei de delta-mutação, equivalência com join de estado, lacunas e
namespaces; reforçar VAL-10 com crescimento causal de MV-Register/OR-Set e custo
da outbox. R-19 é COULD, com entrada condicionada às provas/medições e margem
anterior a 02/11. Compactar representação preserva conhecimento causal; não
autoriza GC por idade/ACK, descarte de pendências ou inferência por dot máximo.
Tipos separados de estado e delta permanecem válidos quando a equivalência é
demonstrada; agregar por ID não substitui join. DotKernel compartilhado é opção
apenas com uso concreto; port integral e OR-Map genérico ficam WON'T-YET.
Nenhum ajuste se torna MUST sem defeito de correção comprovado. Referência e
limites em [TRACEABILITY](TRACEABILITY.md#referencia-delta-cpp-2026-10-12).

DEC-32 — VAL-10 confirmou crescimento quadrático das referências de contexto
nos deltas pendentes MV sequenciais: N=4/8/16/32 produziu 6/28/120/496 refs;
OR-Set reteve 17 eventos para um valor visível. R-19 mantém mérito técnico como
COULD, limitado à compactação de representação MV e às provas já definidas.
Adiada para esta entrega: em 12/10 não há estimativa de esforço nem margem
comprovada antes do congelamento estrutural de 02/11 para implementação,
migração, review e validação durável SQLite. VAL-05 MUST segue prioritária;
reabrir R-19 exige novo plano com margem explícita. Medições e limites em
[TRACEABILITY](TRACEABILITY.md#execucao-val-10-2026-10-12).

## Decisões abertas

| ID | Tarefa | Questão e limite atual |
|---|---|---|
| OPEN-02 | R-03, R-08b | R-03 definiu ACK por mudança; R-08b resolve no enlace fixo: IDs parciais só limpam outbox do peer que reportou `appliedAndPersisted`. ACK de recebimento não limpa. Confirmação para topologias com mais peers fica fora do recorte. |
| OPEN-04 | R-08b | Resolvida em R-08b para peer fixo: outbox endereçada permanece até ACK durável e retry ao reconectar. Bootstrap para peer novo/novos peers além do par ainda não tem protocolo no escopo. |
| OPEN-07 | R-09a, R-09b | Consumidores externos não foram localizados/inventariados. R-09a/R-09b registram quebras 2.0.0, aliases temporários e migração de formatos; confirmar consumidores conhecidos antes de fechar documentação de integração. |

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
- Persistir estado, clocks e outbox local em um commit atômico, com transação do
  backend ou mecanismo equivalente validado. Só confirmar sucesso da mutação
  quando commit terminar; falha não pode deixar memória e dados persistidos
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

Em 2026-10-03, autor autorizou incorporar uso adequado dos recursos do Dart às
instruções e etapas do plano. DEC-16 orienta simplificação e contratos tipados,
com exemplos e limites em AGENTS.md e critérios em R-09a/R-09b e fase 2.
Nenhuma API, classe ou formato foi alterado nesta manutenção documental.

Em 2026-10-03, R-09a iniciou consolidação incompatível em versão principal 2.0.0.
Delta nativo único e migração explícita de versões 1/2 removem operação do caminho
normal sem descartar formatos documentados. Aliases depreciados têm limite na
próxima versão principal; ausência de inventário de consumidores externos continua
registrada em OPEN-07.

Em 2026-10-03, R-05 definiu inicialização antes de qualquer operação, retry após
falha, descarte terminal com drenagem das operações aceitas e envio de rede fora
da fila de commits. Resultado de push informa ACK remoto; pendência local permanece
observável, inclusive no adaptador legado sem operação de remoção.

Em 2026-10-11, autor autorizou incorporar os achados da revisão ao planejamento
com MoSCoW. R-10/R-11/R-12 e VAL-07 registram correções e lacuna de plataforma;
VAL-05 volta a planejada até os MUST concluídos. A manutenção preserva evidências
anteriores, corrige descrições desatualizadas e não implementa mudanças de produto.
