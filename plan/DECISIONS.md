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

DEC-33 — Adotada para planejamento em 2026-10-12: autor confirmou margem e pediu
planejar R-19 para execução agora. Essa direção supera o adiamento de DEC-32;
R-19 passa a pronta com VAL-09/VAL-10 concluídas. A fase 1 detalha baseline,
contexto compacto limitado ao MV-Register, compatibilidade de APIs/formatos,
recuperação SQLite, ganho medido e revalidação de VAL-05. Cronograma é janela de
trabalho, sem estimativa inventada de capacidade; prazo confirmado não dispensa
review, recuperação durável nem demonstração de ganho. Implementação ainda não
iniciada. Registro em [planejamento R-19](TRACEABILITY.md#planejamento-r-19-2026-10-12).

DEC-34 — Aplicada em R-19 em 2026-10-12: contexto MV usa prefixo contíguo e dots
esparsos por réplica dentro do endereço `crdtId`. Estado, contexto de cada versão
e deltas compartilham a representação privada no `mv_register.dart`; a API
`MvRegisterDelta.context` mantém `List<Dot>` e expande sob consulta. DeltaCodec v4
e snapshot interno v9 identificam o formato; leitores migram dados explícitos
anteriores ao carregar e só os regravam em commit atômico. Wrapper `ReplicaSnapshot`
v2, outbox v2 e schema SQLite v1 permanecem. Sem GC ou agregação de ACK. Evidência:
[execução R-19](TRACEABILITY.md#execucao-r-19-2026-10-12).

DEC-35 — Aplicada em R-20, 2026-10-13: após pedido explícito de refatoração geral,
Replica delega instâncias e percursos comuns a `ReplicaContents`/`CrdtTable`;
codec de snapshot e validação de lote são libraries internas com entradas explícitas.
As sete tabelas não-LWW compartilham cópia/restauração/export/merge tipados; LWW
continua em `ReplicaState`, e joins ficam nos oito CRDTs. Não há registro público
de plugins nem novo formato. Contexto MV tem dono independente e leitor único.
SyncEngine coordena lifecycle/adoção/eventos, com fila, persistência e envio/ACK
separados; local simples/em lote e remoto delta/snapshot compartilham seus percursos.
Contratos e adaptadores storage não dependem reciprocamente: entrypoints anteriores
reexportam tipos, evitando quebra de import. Operações públicas, v4/v9/v2/schema v1,
aliases e migração permanecem. Adoção copia antes de substituir, corrigindo perda
LWW na autoadoção reproduzida no código anterior. Evidência:
[execução R-20](TRACEABILITY.md#execucao-r-20-2026-10-13).

DEC-36 — Adotada para planejamento em 2026-10-13: autor autorizou incorporar os
ajustes pontuais e validação de consumidor externo apontados na revisão geral.
R-21 SHOULD reduz travessias/alocações sem mudar contratos; R-22 COULD compartilha
apenas enlace repetido dos exemplos. VAL-11 SHOULD amplia histórias reproduzíveis;
VAL-12 SHOULD revalida Android após os ajustes; VAL-13 SHOULD integra caso pequeno
de app externo, preferencialmente Compass acessível, com SQLite e rede real.
Evidências das quatro categorias do PDF §6.9 e gate MUST histórico permanecem;
novas tarefas estão pendentes e não são novas obrigações acadêmicas. Falha de
correção encontrada exige tarefa MUST, sem ser tratada como custo opcional.
Modelos/regras/transporte próprios ficam no consumidor; publicação no pub.dev
permanece com o autor. Novos comandos usam `dart`/`flutter` do PATH e registram
versões; caminhos absolutos de evidências anteriores são históricos. Registro:
[manutenção de 2026-10-13](TRACEABILITY.md#manutencao-ajustes-consumidor-2026-10-13).

DEC-37 — Aplicada em R-21, 2026-10-13: validação e cópia JSON compartilham um
percurso com modos privados copy/freeze/validate em `json/value.dart`. O modo de
validação percorre entradas sem construir cópias JSON/string; o entrypoint público
`json_value.dart` continua exportando somente `copyJsonValue`. Falhas de leitura
UnsupportedError/JsonUnsupportedObjectError continuam convertidas em ArgumentError
no validador de entrada. Contexto MV privado/isolado é validado pelo construtor;
o lote verifica metadados sem expandir sua view pública. Consulta pontual lê/congela
somente um campo. Cópias transacionais e visões destacadas permanecem; APIs e
formatos v4/v9/v2/schema v1 não mudaram. Medidor conta dots materializados/leituras,
não heap total nem desempenho universal. Ver [execução R-21](TRACEABILITY.md#execucao-r-21-2026-10-13).

DEC-38 — Aplicada em VAL-11/R-23, 2026-10-13: histórias limitadas usam Random com
sementes fixas e HLC injetado, sem dependências novas. Comparação compartilha
suporte de VAL-09: normaliza metadados locais somente entre peers, preserva-os
na equivalência/replay, mantém causalidade e listas do usuário. PN zero/ausente
é equivalente; ordenação de versões MV não apaga dots/contextos. SQLite compara
snapshots/outbox completos, exceto HLC local que pode avançar no start/replay;
seu avanço não pode regredir. Seleção canônica G-Set também se aplica em adições
locais repetidas: R-23 corrige diferença entre mutação e delta sem mudar APIs ou
formatos. Banco antigo permanece legível; evento representativo pode mudar para
o mesmo representante que aplicação do delta já selecionava. Histórico finito e
transporte em processo não substituem VAL-12/13. Ver
[VAL-11](TRACEABILITY.md#execucao-val-11-2026-10-13) e
[R-23](TRACEABILITY.md#execucao-r-23-2026-10-13).

DEC-39 — Aplicada em VAL-13, 2026-10-13: Compass fornecido pelo autor recebe um
recorte de notas por viagem, composto sobre Booking/destino/datas, sem alterar
core ou IDs locais do modelo. Datas de calendário e referência do destino formam
chave estável no cenário de usuário único; cada nota é valor LWW {text}.
main_deltasync compõe providers locais com SQLite/SyncEngine; entrypoints antigos
permanecem. HTTP/TCP entre Android e backend Dart separado usa par fixo, push/pull
manual, ACK somente depois de commit em cada receptor e remoção por peer/IDs.
Backend loopback e adb reverse são canal real de desenvolvimento, sem alegação
de Wi-Fi/produção/multiusuário. Dependências path/overrides vivem no workspace
externo de samples; não houve publicação nem import de internos da biblioteca.
Reprodução por patch contra 5541c59 e roteiro do consumidor; estado/formatos da
biblioteca permanecem. Review corrigiu chave com fuso, mensagem da sessão e harness
UI; problemas de Gradle/Java e fotos HTTP 403 pertencem ao consumidor/ambiente.
Ver [execução VAL-13](TRACEABILITY.md#execucao-val-13-2026-10-13).

DEC-40 — Planejada por autorização do autor em 2026-10-13: melhorar ergonomia
com codec ACK, consulta pontual e guia revalidado (R-24/R-25/VAL-14 MUST);
coordenação remota, acompanhamento e dois dispositivos são SHOULD.
Codegen/build_runner, anotações e gerador próprio permanecem WON'T-YET, sem tarefa
executável, dependência ou remoção de ferramentas que o consumidor já usa.
HTTP separado e conveniências de mapeamento ficam COULD para avaliação posterior
com repetição comprovada; não criar framework nem customizar core ao Compass.
Novos MUST são critérios de engenharia autorizados, não exigências atribuídas ao
PDF. VAL-05 retorna a planejada; resultados históricos continuam válidos para seus
cenários. Detalhes em [planejamento de ergonomia](TRACEABILITY.md#manutencao-ergonomia-2026-10-13).

DEC-41 — Aplicada em R-24, 2026-10-13: DeltaAcknowledgement oferece toJson/fromJson
sem wrapper, versão nova ou dependência de rede. Formato mantém peerReplicaId,
stage com rótulo estável e changeIds como lista. Lista vazia é válida, duplicatas
viram Set isolado e campos extras são ignorados; conhecidos inválidos geram
FormatException. Constructor anterior permanece. Codec não valida autorização:
sync/adaptador vincula destinatário e exige appliedAndPersisted após commit.
Compass reutiliza codec nas duas direções; ACK de pull mantém checagem de peer,
estágio e interseção com pendências. Envelopes/snapshots/SQLite não mudam.
Ver [execução R-24](TRACEABILITY.md#execucao-r-24-2026-10-13).

DEC-42 — Aplicada em R-25, 2026-10-13: Replica.valueAt usa kindAt e switch
exaustivo dos oito CRDTs, reutilizando valores isolados existentes; SyncEngine.valueAt
consulta a réplica interna somente quando started. Não chama fork/state.copy nem
altera cópias de commit/rollback. Query síncrona lê último estado adotado durante
commit/rede; antes de restauração ou após dispose lança StateError.
Ausente/LWW null/tombstone continuam null; valores dos demais tipos preservam
int/Set/Map. Coleções aninhadas permanecem isoladas/somente leitura. API é aditiva;
views/helpers anteriores e formatos persistidos não mudam. Sem classe de resultado,
codegen ou requisito específico de Booking.
Ver [execução R-25](TRACEABILITY.md#execucao-r-25-2026-10-13).

DEC-43 — Aplicada em VAL-14, 2026-10-13: guia técnico único reúne percurso de
integração e ownership, vinculado pelo README, sem escrita acadêmica ou codegen.
Comparação Compass separa configuração/UI/transporte/servidor/testes; 503 para
488 linhas de produção não é meta nem estudo de usabilidade. Revalidação
235 testes Dart/quatro Flutter e Compass 72/13 complementa runtime Android do
APK atual com APIs R-24/R-25. VAL-05 fica pronta, não concluída automaticamente.
Ver [execução VAL-14](TRACEABILITY.md#execucao-val-14-2026-10-13).

DEC-44 — Aplicada no fechamento VAL-05 após ergonomia, 2026-10-13: a validação
completa e runtime de VAL-14 são vinculados ao código atual por comparação Git
dos fontes, reprodução byte a byte dos 17 arquivos Compass e hash do APK.
Sem alteração de produto posterior, não repetir runtime nem suíte completa
por ritual; 19 regressões focadas foram executadas novamente nesta tarefa.
Isso preserva evidência real do código entregue, sem chamar execução anterior
de teste novo nem ampliar claims de plataforma/topologia. Corrigido mapa antigo
de storage em AGENTS para refletir adaptador e suíte já entregues.
Ver [fechamento VAL-05](TRACEABILITY.md#execucao-val-05-ergonomia-2026-10-13).

DEC-45 — Aplicada em R-26, 2026-10-13: receiveEnvelope centraliza validação
do par, aplicação/commit remoto e ACK. IncomingAcknowledgingDeltaTransport é
contrato opcional mínimo para envio do ACK pelo adaptador, sem HTTP no sync.
Pull e incoming reutilizam o mesmo método; sem contrato opcional, retorna ACK
para envio explícito e stream conserva comportamento sem ACK automático.
Aplicação direta de Delta por applyRemote permanece disponível. ACK espera fora
da fila de commits; falha de envio preserva commit e permite replay. Dispose
drena recepções aceitas/ACK; adaptador limita espera de rede e fecha após drenagem.
Não há cancelamento implícito de commit nem rollback após ACK falhar. API aditiva,
schema/envelope/ACK preservados. Ver [R-26](TRACEABILITY.md#execucao-r-26-2026-10-13).

DEC-46 — Aplicada em R-27, 2026-10-13: observations oferece stream broadcast
assíncrono sem replay/cache de estado, com SyncObservation sealed na mesma library
das variantes. Reutiliza os próprios objetos SyncCommitEvent/SyncFailure/SyncPushResult;
SyncRestoredEvent distingue restauração de commit, SyncPushFailure distingue erro
de push de falha recebida. Nenhum enum antigo ou formato persistido muda.
Pendências continuam derivadas de pendingDelta; sessão/ACK não são restaurados.
APIs anteriores e implementação externa dos eventos antigos seguem compatíveis.
Listeners não governam commit; assinaturas pausadas devem ser canceladas antes
do dispose. Falhas diretas diferentes de push seguem nas Futures. Consumidor
Compass reage a commits externos sem polling; mais linhas são justificadas pelo
comportamento novo, sem prometer redução de LOC.
Ver [R-27](TRACEABILITY.md#execucao-r-27-2026-10-13).

DEC-47 — Preparação R-22, 2026-10-13: enlace Dart puro comum vive no suporte do
lib Flutter para compatibilidade de package URI. Export CLI local usa exceção
de lint documentada; nenhum pacote novo. Imports, nomes e mensagens anteriores
preservados, inclusive wrapper DemoPeerLink. Testes/CLI/build passaram antes e
depois; runtime pendente após autor retirar celular, sem conclusão da tarefa.
Retomada posterior: autorização ADB resolvida e runtime do APK atualizado aprovado
no Moto G52, com dois reinícios, valores/IDs restaurados e ACK durável.
R-22 concluída; ver [execução R-22](TRACEABILITY.md#execucao-r-22-2026-10-13).

DEC-48 — Preparação VAL-15, 2026-10-13: dois clientes Compass com IDs alpha/beta
estáveis por dart-define e bancos próprios apontam para notes-hub. Hub consumidor
usa uma engine/SQLite serial e aceita somente notas LWW. Push confirma commit
no hub; pull envia estado materializado dirigido ao cliente, sem outbox global
que ACK de um possa remover. Não promete entrega incremental do hub, confirmação
no segundo celular ou histórico completo de clocks. Modo legado permanece padrão;
snapshot-pull recusa outbox local/dados de outros tipos e não aceita edição local
no hub. Configuração rejeita espaços que seriam normalizados pelo core, sem
mudar ReplicaId. Topologia/roteamento/reabertura passaram no host, dois APKs
preparados; dispositivos físicos permanecem necessários. Sem mudança da biblioteca.
Ver [preparação VAL-15](TRACEABILITY.md#preparacao-val-15-2026-10-13).
Retomada física: VAL-15 concluída no Moto G52 Android 13/API 33 e Moto G53 5G
Android 14/API 34, HTTP por reverse USB independente. Bancos confirmam identidades,
ACK isolado, vencedor comum e outboxes vazias após reinícios dos apps/hub.
Não amplia o contrato da biblioteca; ver [execução VAL-15](TRACEABILITY.md#execucao-val-15-2026-10-13).

DEC-49 — VAL-16, 2026-10-13: reutilizar projeto Android, com entrada técnica
separada, cenário explícito e HTTP de peers diretos alpha/beta. Envelopes completos
passam pelo receiveEnvelope/SQLite, incluindo contexto MV e tombstones; não adaptar
o hub materializado LWW do Compass aos oito tipos. Forward/reverse USB mantém peer
fixo por cliente. Sem nova API/pacote/dependência da biblioteca; helper de exemplo
não define transporte de produção. Prova deve cobrir os oito, ACK, restauração e
resolução causal MV. Ver [roteiro](../example/flutter_mobile/EIGHT_CRDTS.md).
Host aprovado com sete testes e dois APKs. Runtime parcial: base entregue a beta,
alpha editou durante falha e restaurou outbox/contextos; G53 bloqueado interrompeu
ramificação beta. VAL-16 incompleta até reconciliação/resolução MV nos aparelhos.
Retomada posterior concluída: beta ramificou sobre a base preservada, ambos
restauraram outboxes/contextos, convergiram nos oito tipos e confirmaram peers
diretos. MV manteve duas versões concorrentes e resolução posterior removeu ambas;
replay de envelopes antigos e novos reinícios não as ressuscitaram. Auditoria
compara estado causal sem owner/sequence locais e normaliza componentes PN zero,
sem exigir HLCs iguais. Ver [execução VAL-16](TRACEABILITY.md#execucao-val-16-2026-10-13).

DEC-50 — R-28, 2026-10-15: preparar os sete releases em diretórios independentes,
fora do Git, com `scripts/prepare_release.py`. Filtros locais dos subpacotes não
recuperam diretórios excluídos pelo `.pubignore` ancestral. Manter o filtro enxuto
da facade e o layout atual evita incluir todo o monorepo no pacote público.
Exportar somente fontes/documentos públicos e exemplo mínimo, removendo apenas
configuração de workspace dos manifests exportados. Restrições de dependência,
nomes, versões, licença, APIs e formatos permanecem iguais. Inventário SHA-256 e
consumo hosted em registro local somente leitura comprovam conteúdo e resolução
sem overrides; isso não comprova publicação/autorização no pub.dev. Autor publica
dependências primeiro, repete dry-runs no registro público e instala em consumidor
novo depois dos envios. Ver [guia](../docs/publicacao.md) e
[execução R-28](TRACEABILITY.md#execucao-r-28-2026-10-15).

DEC-51 — R-29, 2026-10-15: autor escolheu 1.0.0 para a publicação dos sete pacotes.
Substituir a numeração 2.0.0 adotada durante o desenvolvimento, inclusive nas
restrições internas, READMEs e changelogs. DEC-17 mantém suas escolhas técnicas;
somente a versão pública foi substituída. APIs, versões de JSON/snapshot/outbox,
schema SQLite e migrações não mudam por essa renumeração. Evidências anteriores
permanecem com os números realmente verificados. Gerar diretórios de release
novamente após a troca; os exports antigos continuam com os manifests antigos.
Publicação e verificação de disponibilidade das versões permanecem com o autor.

DEC-52 — Substituída por DEC-55 após esclarecimento do autor em 2026-10-24.
Registro da primeira interpretação: o pedido do autor abrange os pontos da
análise geral, com foco exclusivo na biblioteca. 1.0.1 preserva a API pública
1.0.0, interfaces implementáveis, variantes fechadas, aliases já depreciados,
SDK e formatos persistidos. Correções internas, medições, CI e documentação
cabem no patch. Consulta leve de pendências é funcionalidade pública para 1.1.0;
outras ampliações exigem caso/compatibilidade comprovados. Remoções de
PendingDeltaStore, aliases e export público de Operation ficam para 2.0.0.
Novos membros obrigatórios em interfaces ou variantes que quebram switches
externos também exigem major. Depreciações novas exigem minor. Referências:
[SemVer](https://semver.org/) e [versionamento Dart](https://dart.dev/tools/pub/versioning).
O plano futuro não autoriza implementar/publicar essas releases antecipadamente.

DEC-53 — Substituída por DEC-56 após ampliação expressa em 2026-10-24.
Registro do primeiro gate de manutenção: a [fase 6](06_PHASE6_MANUTENCAO_1_0_1.md)
integra o plano canônico, sem reabrir artificialmente as conclusões acadêmicas
das fases 1–5. Seus SHOULD são relativos à entrega do TCC; R-30 a R-36 e VAL-17
compõem a release planejada e devem ser concluídos antes de prepará-la como
validada. VAL-05 não substitui VAL-17. R-30 começa pela baseline 1.0.0;
R-36 só renumera após o trabalho de produto; VAL-17 verifica SDK, API, dados,
adaptadores externos e consumidor isolado. Publicação continua manual com o autor.

DEC-54 — Ferramentas e limites de consumo, 2026-10-24: medir e corrigir outbox
sem eliminar IDs ou contexto causal. Cópias/snapshots mantêm garantias até haver
evidência que justifique outra tarefa. CI deve distinguir testes, advisories,
lint e runtime; aviso de advisory não equivale a falha automática do pub get.
R-34 executa piloto Saropa essential isolado e pode concluir por adiamento
fundamentado. Não tornar a ferramenta dependência runtime, requisito acadêmico
ou atestado de segurança. Modelo, identidade, UI, autenticação/TLS e agendamento
pertencem ao consumidor. R-35 demonstra tratamento de falha de status após commit
sem alterar Compass nem introduzir schema de domínio ou framework genérico.

DEC-55 — Escopo integral na versão 1.0.1, 2026-10-24: autor esclareceu que deseja
todos os pontos da análise nesta versão, inclusive mudanças que deveriam ser
minor/major. Essa direção substitui DEC-52 e o adiamento de R-37/R-38/R-39.
Manter número 1.0.1, com novas APIs e remoção de legado, documentando expressamente
a incompatibilidade de fonte com 1.0.0 e a exceção à convenção SemVer. Não exigir
outra aprovação apenas pela quebra já incluída no escopo. O pedido autoriza
planejar toda a entrega; implementação continua dependendo de pedido de execução.
Preservar dados, readers e formatos existentes; mudanças de API não autorizam
descarte, GC, retirada de leitores ou renumeração automática de JSON/schema.

DEC-56 — Gate integral 1.0.1, 2026-10-24: substitui DEC-53 quanto ao alcance.
R-30 a R-42 e VAL-17 compõem a mesma entrega. R-38 entrega lote público;
R-40 decoder opcional; R-41 eventos seletivos e consolidação de emissão;
R-42 consulta explícita de ausente/null/tombstone. R-37 entrega consulta leve e
R-39 retira a superfície legada preservando conversão de dados interna. Esses
itens não podem ser concluídos apenas por avaliação ou adiamento por SemVer.
R-35 documenta o resultado e upgrade; R-36 prepara a numeração depois do produto;
VAL-17 valida consumidores migrados, dados anteriores e artefatos finais.
SHOULD continua prioridade relativa ao TCC; todos os itens são obrigatórios
para esta release. VAL-05 histórico e decisão fundamentada do piloto R-34
permanecem; não incluir ORM, codegen, app externo ou publicação automática.

DEC-57 — Recuperação do stash em 2026-10-24: conflitos em README, DECISIONS e
TRACEABILITY ocorreram ao recuperar o planejamento sobre a branch 6b7016a, que
mantém versões 2.0.0 e não contém a alteração histórica R-29 para 1.0.0.
Preservar decisões/evidências R-29 e todo o escopo R-30 a R-42/VAL-17, mantendo
intactos manifests e alterações da branch atual. R-29 permanece conclusão
histórica vinculada à revisão original, não comprovação das versões desta branch.
R-30 deve inventariar a divergência; o alvo 1.0.1 de DEC-55/56 não muda.

DEC-58 — Baseline R-30, 2026-10-24: fontes de lib e superfícies públicas de
400161283e741d62dddf01cfc314629968a93828 coincidem com a revisão histórica
1e969182e8e172a8858a48ecf83a1feb2c21a455: 47 arquivos, hashes em
[baseline.json](evidence/r30/baseline.json). Manifests atuais 2.0.0 e históricos
1.0.0 divergem; nenhum foi alterado nesta tarefa. A comparação é de fonte/API,
não prova publicação ou resolução hosted. Alvo 1.0.1 de DEC-55 permanece.
Fixados inventário de exports/assinaturas e dados dos oito tipos com writer
histórico, independente do futuro writer 1.0.1. Guardar consumidor e gerador
como fontes de fixture `.dart.txt`, com @dart=3.12 e materialização explícita;
assim remoções futuras não tornam código antigo parte da análise recursiva.
Dados e inventário não podem ser sobrescritos pelo argumento de relatório.
R-31 usa a carga fixada; R-39 conserva referência antiga e acrescenta consumidor
migrado, sem regenerar expectativas. O SDK 3.12.x teve execução definida em
R-30, sem alegação de execução; R-33 e VAL-17 devem efetivamente realizá-la.

DEC-59 — Consolidação da outbox R-31, 2026-10-24: coletar mudanças uma vez no
helper interno de sync e usar uma única Delta.merge para checar IDs. Manter
validação profunda do core, posição do primeiro ID, payload da última duplicata
equivalente e todos os IDs de componentes cumulativos; não compactar por campo,
dot máximo ou dominância. Seleção por peer e metadata/ACK continuam em seus donos.
Nenhuma classe/API/formato de produção foi adicionada ou alterada. Medidor R-30
foi reutilizado sem modificar sua baseline. A regressão mede crescimento de
leituras de ID, sem limiar temporal; resultado do host não garante latência em
outras plataformas. Dados, exports e consumidores antigos seguem validados em
[R-31](TRACEABILITY.md#execucao-r-31-2026-10-24).

DEC-60 — Remoção de legado R-39, 2026-10-24: SyncEngine exige ReplicaStorage
não nullable nos dois construtores e mantém withStorage. Removidos contrato e
implementação PendingDeltaStore, seus ramos, aliases de mutação/lote e
OutboxEntry.operationId. Operation e migrateLegacyOperation deixam os exports;
o mesmo DTO/parser em src/operation.dart continua atendendo readers de delta e
snapshot, sem outra implementação ou protocolo. ReplicaSnapshot.legacy e
OutboxStatus.confirmed permanecem para dados/adaptadores históricos. Nenhum join,
formato, schema, SDK ou manifesto foi alterado. Inventário dos sete entry points
confere somente remoções/assinaturas previstas e mudanças documentais explícitas.
Consumidor isolado usa contratos por composição; exemplo de importação pertence
ao app e exige checkpoint completo, peer explícito e commit atômico. Rollback foi
executado para a revisão 1.0.0 fixada sobre o mesmo SQLite, incluindo escritas
novas e ACK parcial; não garante downgrade a readers anteriores ou migração
automática de um app de volta ao pending store. Ver
[R-39](TRACEABILITY.md#execucao-r-39-2026-10-24) e
[guia](../docs/migracao-1.0.1.md).

DEC-61 — Medição de custos R-32, 2026-10-24: estender o medidor existente por
--paths, com parâmetros independentes de campos/valor/pendências, dois backends,
dois aquecimentos e cinco amostras por carga. Usar records privados para cargas
e o fluxo real de preparação, sem outra implementação de join ou alteração de
produção. Verificar valores sem depender da ordem de mapas/sets; listas mantêm
ordem. Na restauração, exigir HLC monotônico e os demais metadados iguais.
RSS é do processo inteiro; não mede heap/alocações. Projeções JSON de valores e
causalidade não somam um backup, e bytes do SQLite fechado não são recuperáveis.
R-37 permanece necessária antes de 1.0.1: contagem/status ainda materializam
payloads. Replay por entrada com fork/adopt e markSent por ID explicam custos
restantes observados, mas esta tarefa não demonstra defeito de dados nem dispõe
de SLA para impor outra refatoração. Avaliar otimizações novas de replay/cópias/
SQL após a release, com esta baseline e provas de isolamento, causalidade e
rollback; orçamento de consumidor mais estrito exige reavaliar a decisão.
Nenhum item já planejado foi adiado ou retirado. R-35/VAL-17 continuam responsáveis
por documentação/gate completo; não alegar latência universal ou suporte mínimo
executado. Ver [R-32](TRACEABILITY.md#execucao-r-32-2026-10-24) e
[resultados](evidence/r32/README.md).

DEC-62 — Resumo de pendências R-37, 2026-10-24: adicionar pendingSummary
obrigatório em ReplicaStorage e expor a leitura pela engine, na fila existente.
OutboxSummary valida contagens não negativas e deriva total, sem cache paralelo.
Filtro null inclui todos os peers; entradas peer/ID contam separadamente e
sent permanece sem ACK. Confirmed legado é excluído, sem remoção durante resumo.
Um membro obrigatório com referências/suíte/migração é menor que capacidade
opcional mais dispatch/fallback na engine. MemoryStorage lê metadata; SQLite
agrega JSON no SQL mantendo schema v1, com fallback de metadata em Dart apenas
para ausência de json_extract. Outros erros propagam; consulta não certifica
payload, envio ou sucesso remoto, nem desfaz commit anterior. Ganhos medidos
nas cargas R-32 não prometem latência universal ou otimização de builds sem JSON1.
Contrato externo novo é quebra de fonte autorizada para 1.0.1; formatos, joins,
SDK e manifests permanecem. Ver [R-37](TRACEABILITY.md#execucao-r-37-2026-10-24).

DEC-63 — Lote local R-38, 2026-10-24: SyncEngine.batch usa o pipeline existente
de candidata/commit/adoção e retorna Delta após sucesso. Editor LocalBatch com
construtor privado e final class, na mesma library via part, delega regras ao
core, coleta mudanças e fecha antes do await do storage. Um contexto Zone impede
operações reentrantes e acompanha continuações de callbacks async rejeitados.
Future retornado, lote vazio, erro de callback/edição (mesmo capturado) ou commit
falho abortam; não desfaz efeitos externos do app, proibidos pelo contrato.
Preservar IDs, formatos, joins e uma entrada/ACK por mudança; lote não é transação
distribuída. Sem contrato novo de storage/transport ou comandos de domínio.
Extrator canônico de APIs passa a scripts/api_inventory.dart com suporte a parts;
ferramenta/dados R-30 ficam intactos e inventários anteriores equivalem. Ver
[R-38](TRACEABILITY.md#execucao-r-38-2026-10-24).

DEC-64 — Consulta explícita R-42, 2026-10-24: Replica.query retorna FieldQuery
sealed com AbsentField, PresentField(kind/value) e DeletedField para tombstone
LWW. Construtores privados e variantes final em part da library de Replica
preservam origem canônica e switches exaustivos, sem exigir modelo do app.
Outros sete tipos vinculados continuam presentes com zero/coleção vazia.
ReplicaState.kindAt/isDeletedAt consultam metadados; o segundo evita copiar o
vencedor/payload só para verificar remoção. Um percurso privado de valor serve
query e valueAt, sem reconstruir réplica ou manter cache paralelo. valueAt
preserva sua ambiguidade null anterior e não aloca o resultado tipado.
SyncEngine.query exige start e lê último commit adotado; LocalBatch.query lê
candidata só no escopo do editor. ACK/outbox não determinam presença. R-40
reutilizará esse contrato: decoder no ramo presente, inclusive null, sem ocultar
erro como ausência. Nenhum formato, join ou contrato de adaptador mudou; colisão
com método query em subclasses externas e futura expansão de variantes exigem
atenção de migração. Ver [R-42](TRACEABILITY.md#execucao-r-42-2026-10-24).

DEC-65 — Decoder opcional R-40, 2026-10-24: PresentField.decode<T> recebe
T Function(Object?) e retorna T sem wrapping, valor padrão ou novo acesso ao
estado. Converte o valor já isolado exatamente uma vez, inclusive null legítimo;
retorno nullable permanece decisão do consumidor. Ausente/removido não oferecem
decode, exigindo tratar os ramos existentes de FieldQuery. Valor bruto permanece
disponível. Um membro na variante presente atende Replica/engine/editor e mantém
um percurso de consulta, sem classes, generificação da hierarquia, schema ou
adaptadores adicionais. Preferido membro sobre extension por ser conveniência
pequena do tipo controlado pela biblioteca; não há despacho novo ou override.
Resultado pode ser convertido após edições/dispose; nova consulta ainda respeita
lifecycle. Modelo, validação, mutabilidade de saída e efeitos externos do decoder
pertencem ao consumidor. Erro de leitura propaga ao chamador sem desfazer commit
anterior ou emitir falha da engine; erro que escapar do callback de lote segue
seu rollback existente. Novo membro pode sombrear extension decode do consumidor;
guia orienta migração. Sem mudanças de query/valueAt, variantes, joins, commit,
ACK ou formatos. Ver [R-40](TRACEABILITY.md#execucao-r-40-2026-10-24).

## Decisões abertas

| ID | Tarefa | Questão e limite atual |
|---|---|---|
| OPEN-02 | R-03, R-08b | R-03 definiu ACK por mudança; R-08b resolve no enlace fixo: IDs parciais só limpam outbox do peer que reportou `appliedAndPersisted`. ACK de recebimento não limpa. Confirmação para topologias com mais peers fica fora do recorte. |
| OPEN-04 | R-08b | Resolvida em R-08b para peer fixo: outbox endereçada permanece até ACK durável e retry ao reconectar. Bootstrap para peer novo/novos peers além do par ainda não tem protocolo no escopo. |
| OPEN-07 | R-09a, R-09b, VAL-13, R-28, R-29 | Compass identificado/inventariado e integrado em VAL-13, com path/overrides externos. R-28 valida sete artefatos hosted em registro local, sem overrides. Outros consumidores permanecem desconhecidos; mudanças incompatíveis da consolidação, aliases temporários e migrações seguem documentados. Registro local não comprova publicação no pub.dev; publicação permanece com o autor. |
| OPEN-08 | R-30, R-37, R-38, R-40, R-41, R-42 | Todas as APIs entram na 1.0.1. R-30 fixou superfícies e mapa de impacto/substitutos existentes; nomes/assinaturas das conveniências novas serão fechados nas tarefas responsáveis e atualizados no mapa. Quebras de interface/switches exigem fixture migrada; decisão de versão resolvida em DEC-55. |
| OPEN-09 | R-34 | Adoção Saropa depende de resolução, alertas úteis, falsos positivos e custo medidos no piloto; preset/versionamento/configuração final ainda não escolhidos. Decisão de adiar pode satisfazer a tarefa de avaliação, com evidência. |

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
