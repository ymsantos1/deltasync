# Fase 6 — Consolidação completa para 1.0.1

Estado: em andamento em 2026-10-24; R-30/R-31/R-32/R-37/R-39 concluídas e nenhuma ativa.
R-33/R-38/R-42 prontas; demais tarefas ainda não iniciadas.
Objetivo: aplicar toda a análise à biblioteca em 1.0.1, incluindo correções,
novas APIs, remoção de legado, medições, ferramentas e documentação de migração.
Origem: pedido do autor para planejar os pontos da análise geral da biblioteca,
após confrontá-los com um consumidor real. O pedido autoriza este planejamento;
a execução seguirá o [RUNBOOK](RUNBOOK.md) quando solicitada. Em esclarecimento
posterior, o autor pediu incluir também os itens antes reservados a minor/major.
Entrada: R-29 concluída no histórico 1.0.0. Após recuperação do stash, a branch
6b7016a mantém manifests 2.0.0; R-30 deve comparar esse estado com a referência
1e969182e8e172a8858a48ecf83a1feb2c21a455 antes de editar. O alvo permanece 1.0.1;
esta resolução não renumera pacotes. Baseline e limites da análise estão na
[rastreabilidade](TRACEABILITY.md#planejamento-1-0-1-2026-10-24).
Saída: VAL-17 concluída e sete artefatos 1.0.1 preparados, sem publicação.

## Escopo, versões e prioridade

Por decisão explícita do autor, 1.0.1 reúne todos os encaminhamentos desta fase,
incluindo novas APIs e remoções incompatíveis com 1.0.0. Esta numeração é uma
exceção deliberada à convenção [SemVer](https://semver.org/); não apresentar
a release como atualização patch compatível ou prometer upgrade sem ajustes.
Não há itens desta análise reservados a 1.1.0/2.0.0. Critérios de migração,
integridade e validação continuam obrigatórios; publicação não está autorizada.

Preservar SDK e formatos de dados existentes, inclusive readers legados, como
regra deste trabalho. Remoção de uma API não autoriza apagar dados, retirar seu
reader ou mudar schema. Toda quebra de fonte intencional deve constar do mapa
de migração e ser exercitada com consumidor/adaptador atualizado na VAL-17.

As tarefas desta fase são SHOULD em relação à entrega acadêmica já validada.
Para preparar a release 1.0.1 deste plano, todas as dependências de VAL-17 são
obrigatórias. Um adiamento exige revisar explicitamente o escopo dessa release;
não basta fechar o gate histórico VAL-05. As fases anteriores mantêm seus
resultados históricos. Ferramenta de lint não vira requisito acadêmico novo.

Manter oito CRDTs, arquitetura modular, propriedade dos dados, joins, clocks,
contextos causais, tombstones, commit atômico, restauração e ACK por peer/ID.
MemoryStorage continua volátil e SQLite é o único adaptador persistente oficial
de referência. Não criar ORM, codegen obrigatório, schema de domínio, backend,
framework de plugins, GC destrutivo ou suporte genérico a múltiplos peers.
Não editar Compass ou seus serviços: sua observação orienta requisitos gerais,
e a validação da biblioteca usa fixtures próprias reproduzíveis.

## Cobertura da análise

| Ponto da análise | Encaminhamento canônico |
|---|---|
| Arquitetura, oito tipos e garantias atuais | R-30 fixa baseline; VAL-17 verifica preservação |
| Montagem quadrática da outbox | R-31 corrige e mede antes/depois |
| Cópias, snapshots, consultas e restauração | R-32 mede sem presumir outra refatoração |
| Consulta leve de pendências | R-32 mede custo atual; R-37 entrega API em 1.0.1 |
| Commit, pendência, ACK e falha de consulta distintos | R-35 documenta e exercita contratos existentes |
| Remover caminho legado e aliases | R-30 inventaria; R-39 remove; R-35 documenta upgrade para 1.0.1 |
| CI, lint e vulnerabilidades em dependências | R-33 automatiza; R-34 avalia Saropa |
| Guia durável, ownership e limites de extensão | R-35 simplifica documentação/exemplos |
| Lote público com commit local atômico | R-38 implementa e testa |
| Decoder opcional sem schema no core | R-40 implementa e testa |
| Eventos seletivos e consolidação interna dos canais | R-41 implementa e testa |
| Leitura explícita de ausente/null/tombstone | R-42 implementa e testa |
| Versões, distribuição e consumidor fora do workspace | R-36 e VAL-17 |

<a id="r-30"></a>

## R-30 — Fixar baseline e mapa de migração da 1.0.1

Status: concluída
MoSCoW: SHOULD
Dependências: R-29

Áreas: exports/APIs dos sete pacotes, contratos de storage/transport, formatos,
testes de compatibilidade e instrumentos de medição existentes.
Primeiro passo: inspecionar worktree e inventariar contratos 1.0.0 antes de editar
produção. Não tratar a revisão anterior como execução desta tarefa.

Critérios:

- [x] Registrar baseline reproduzível de fontes/revisão, SDK, ambiente e testes;
  inventariar construtores, membros exportados, aliases depreciados, contratos
  externos e readers legados necessários. Guardar fixtures 1.0.0 independentes
  do writer novo, incluindo estado/outbox dos oito tipos e adaptadores externos.
- [x] Fixar preservação de SDK e formatos: SDK ^3.12.0, DeltaCodec v4,
  snapshot interno v9, ReplicaSnapshot/outbox/envelope v2 e schema SQLite v1,
  com os readers anteriores documentados. Verificar números no código antes
  de registrar a fixture; não renumerar JSON junto com a versão dos pacotes.
- [x] Identificar o custo de mergeOutbox e conservar uma baseline de carga para
  R-31: quantidades crescentes de entradas, peers distintos e conteúdo misto.
  Instrumentos não devem manter outra implementação de join em produção.
- [x] Mapear cada quebra intencional de fonte, substituto público e adaptação
  necessária: storage legado, aliases, Operation, capacidades de storage e
  eventos/leitura que mudarem. Não usar compatibilidade integral 1.0.0 como gate;
  exigir preservação fora das quebras previstas e migração verificável.
- [x] Definir execução no SDK mínimo 3.12.x e no SDK de referência disponível,
  incluindo implementações externas dos contratos e consumidores antes/depois.
  Registrar limites sem elevar SDK silenciosamente ou criar framework de migração.

Validação: análise/testes dos sete pacotes, fixtures de API/formato e baseline
de custos. Registros identificam comando, diretório, SDK e conteúdo comparado.
Execução: 243 testes do workspace e 14 checks do consumidor em cada árvore,
histórica/atual, aprovados no Dart 3.13.5/Linux; 47 fontes de lib idênticas.
SDK 3.12.x teve execução definida, conforme critério, mas não foi executado;
R-33/VAL-17 devem executar a matriz mínima antes do gate final da release.
Artefatos: [baseline e mapa](evidence/r30/README.md), incluindo fixtures
congeladas, origem dos imports, hashes e cargas para R-31.
Evidência de conclusão: [execução R-30](TRACEABILITY.md#execucao-r-30-2026-10-24).

<a id="r-31"></a>

## R-31 — Corrigir montagem quadrática da outbox

Status: concluída
MoSCoW: SHOULD
Dependências: R-30

Áreas: mergeOutbox em sync, Delta.merge no core somente se necessário e testes
de pendências/push/recuperação. Corrigir no menor ponto responsável.

Critérios:

- [x] Reunir mudanças numa passagem e validar IDs em uma consolidação, evitando
  reprocessar todo o prefixo para cada entrada. Custo de montagem deve ser linear
  no número de mudanças, além da leitura/validação de seus payloads.
- [x] Preservar ordem observável atual, outbox vazia, duplicatas equivalentes,
  rejeição de mesmo ID com payload divergente e seleção por peer. Não agregar
  mudanças por dominância, descartar IDs, limpar pendências ou fazer GC.
- [x] Cobrir os oito tipos, ACK parcial/perdido, retry, entrada inválida,
  falha de commit, concorrência com edição e restauração SQLite. Falha de
  preparação/envio não pode remover mudanças sem confirmação durável.
- [x] Comparar cargas de R-30 antes/depois com prova estrutural de travessias
  e amostras de tempo/memória disponíveis. Evitar limiar temporal frágil em teste;
  distinguir complexidade comprovada de ganho observado na máquina de medição.

Validação: sync, core/facade se afetados, suíte de storage e recuperação SQLite;
formato/análise/testes dos pacotes alterados e consumidores internos pertinentes.
Resultado: 249 testes nos sete pacotes e 14 checks por consumidor histórico/
atual aprovados. Regressão estrutural falha no código anterior e passa com a
correção; medianas de 1024 entradas no host caíram de 58646 para 8834 µs.
Sem mudança de API, formato, joins ou regras de ACK; heap não medido.
Evidência de conclusão: [execução R-31](TRACEABILITY.md#execucao-r-31-2026-10-24),
com [resultados e comparação](evidence/r31-validation.json).

<a id="r-32"></a>

## R-32 — Medir custos de mutação, restauração e pendências

Status: concluída
MoSCoW: SHOULD
Dependências: R-31

Áreas: instrumentos existentes em example, Replica.fork/adopt, snapshots e
consultas de estado/outbox. Entrega é evidência, sem refatoração especulativa.

Critérios:

- [x] Reusar/estender os medidores existentes com cargas fixas crescentes de
  campos, tamanho de valores e pendências. Medir mutação, snapshot, restauração
  com outbox, preparação de push e consultas repetidas de quantidade/status.
- [x] Distinguir estado materializado, metadados causais e outbox. Incluir
  MemoryStorage e SQLite FFI onde pertinentes; não confundir memória com
  durabilidade nem bytes JSON com tamanho recuperável do arquivo SQLite.
- [x] Registrar aquecimento, repetições, sementes, ambiente, tempos e medida
  de memória explicitamente suportada. Se heap/alocações não forem medidos,
  declarar a ausência; leituras contadas não equivalem a bytes alocados.
- [x] Identificar gargalos restantes e decidir se exigem correção
  antes da release ou tarefa posterior. Medição não autoriza remover isolamento,
  mudar checkpoints/formatos ou reestruturar todos os CRDTs. Registrar também
  resultado sem gargalo relevante e os limites das conclusões.

Validação: execução reproduzível dos medidores e verificação de resultados
equivalentes, sem transformar desempenho específico do host em garantia pública.
Resultado: medidor existente estendido com --paths; 14 cargas Memory/SQLite,
70 amostras medidas e 28 aquecimentos com verificações equivalentes; modo antigo
preservado. Formato/análise e 13 testes da facade aprovados. Medidos RSS do
processo, JSON e arquivos fechados SQLite separadamente; heap/alocações ausentes.
R-37 segue antes da release; novas otimizações de replay/cópias/SQL ficam para
avaliação posterior (DEC-61), sem alterar a lib ou retirar critérios da fase.
Evidência de conclusão: [execução R-32](TRACEABILITY.md#execucao-r-32-2026-10-24),
[método/resultados](evidence/r32/README.md),
[amostras](evidence/r32/measurements.json) e
[validação/review](evidence/r32/validation.json).

<a id="r-33"></a>

## R-33 — Automatizar verificações e advisories em CI

Status: pronta
MoSCoW: SHOULD
Dependências: R-30

Áreas: workflows do repositório, comandos de verificação e dependências de
desenvolvimento. Configurar arquivos locais; ativar serviços externos não está
autorizado por este plano.

Critérios:

- [ ] Automatizar formatação, análise e testes da facade e dos seis subpacotes,
  com SQLite FFI real, SDK mínimo 3.12.x e SDK estável selecionado/documentado.
  Falha de qualquer pacote deve falhar o job; cache não pode esconder resolução.
- [ ] Executar check_plan.py e git diff --check em mudanças pertinentes;
  validar exemplo Dart e exemplo Flutter com análise/testes/build proporcionais.
  Separar jobs Flutter dos pacotes Dart e registrar que build não prova runtime.
- [ ] Consultar advisories das dependências na resolução e definir tratamento
  verificável para achado, exceção justificada e falha de rede. Não presumir
  que dart pub get retorna erro quando apenas imprime aviso, nem usar pub
  outdated como scanner de vulnerabilidades. Documentar atualização periódica.
- [ ] Validar a configuração e seus comandos localmente; demonstrar detecção
  de falha de teste/pacote e advisory por fixture adequada sem introduzir
  dependência vulnerável nos manifests de produção. Usar permissões mínimas,
  sem credenciais de publicação, uploads ou autofix de produto no workflow.
- [ ] Registrar separadamente checks locais e execução remota. Se não houver
  execução remota autorizada/disponível, manter essa limitação explícita;
  não afirmar que GitHub Actions passou sem resultado real.

Validação: workflow/configuração e comandos dos jobs, cenários negativos
controlados e matriz de pacotes. Referência: [advisories Dart](https://dart.dev/tools/pub/security-advisories).
Evidência de conclusão: ainda não registrada.

<a id="r-34"></a>

## R-34 — Avaliar Saropa e lint proporcional

Status: planejada
MoSCoW: SHOULD
Dependências: R-33

Áreas: ferramentas de análise e configuração de desenvolvimento. Executar
piloto isolado antes de alterar resolução/configuração permanente do workspace.

Critérios:

- [ ] Manter lints/recommended e avaliar saropa_lints com preset essential,
  versão registrada e runner isolado. Conferir compatibilidade de SDK,
  analyzer/test, integração Flutter e análise de todos os pacotes pertinentes.
- [ ] Comparar tempo e uso de recursos disponíveis com a baseline; classificar
  amostra revisada de alertas úteis, falsos positivos, sobreposição com regras
  existentes e custo de manutenção. Não inferir utilidade pela quantidade de regras.
- [ ] Decidir e justificar adoção seletiva ou adiamento. Concluir o piloto não
  exige instalar Saropa. Se adotado, usar somente ferramenta de desenvolvimento,
  conservar resolução dos consumidores e documentar regras/exceções delimitadas.
- [ ] Tratar achados reais com regressões e validação proporcionais no ciclo da
  tarefa; não aplicar autofix em massa, ocultar erros críticos em baseline genérica
  ou fazer mudanças cosméticas amplas. Achado fora do escopo recebe tarefa
  própria; incompatibilidade já prevista nesta fase segue seu mapa de migração.
- [ ] Explicar que lint não prova convergência, atomicidade, recuperação,
  autenticação ou ausência de vulnerabilidades; manter advisories/testes separados.

Validação: logs/relatório do piloto, decisão revisada e checks das configurações
que forem adotadas. Referência: [Saropa](https://pub.dev/packages/saropa_lints).
Evidência de conclusão: ainda não registrada.

<a id="r-35"></a>

## R-35 — Simplificar guia durável e esclarecer contratos públicos

Status: planejada
MoSCoW: SHOULD
Dependências: R-34, R-37, R-38, R-39, R-40, R-41, R-42

Áreas: README, docs/guia-integracao.md, READMEs dos pacotes e exemplos da lib.
Não implementar regras de notas nem alterar consumidor externo.

Critérios:

- [ ] Abrir README com percurso durável curto usando SyncEngine e SQLite;
  reusar exemplos existentes e manter variante volátil explicitamente identificada.
  Mover histórico/medições detalhados para docs pertinentes com links atualizados,
  preservando evidências, anchors existentes e informação de compatibilidade.
- [ ] Mostrar configuração, identidade/endereço estáveis, edição, consulta,
  sincronização e encerramento/restauração. Distinguir commit local, pendência,
  ACK do peer configurado e propagação a outros participantes não garantida.
- [ ] Exercitar com fixture geral uma consulta de pendências que falha depois
  de commit bem-sucedido; mostrar tratamento independente da falha de status.
  Mostrar validação de modelo no consumidor para JSON estruturalmente válido,
  sem schema de domínio no core ou promessa de rollback após sucesso local.
- [ ] Documentar ownership de engine/transporte/storage, streams sem replay,
  listeners, retry de abertura, dispose e agendamento de push pelo consumidor.
  Usar consulta leve de pendências e eventos seletivos para evitar reconstruir
  deltas/atualizar toda a interface a cada edição.
- [ ] Mapear pontos de manutenção: estado/mutação/join no core, commit/restauração
  em sync/storage, atomicidade SQL no adaptador e codecs nas respectivas camadas.
  Explicar extensão de storage/transport, oito tipos fechados integrados e
  necessidade de alterar core/codec/testes para integrar um CRDT adicional.
- [ ] Documentar remoções e migração de fonte/adaptadores 1.0.0 para 1.0.1;
  destacar a quebra deliberada apesar da numeração patch. Mostrar decoder,
  lote local atômico, eventos seletivos e consulta explícita de estado de campo.
  Explicar LWW por valor inteiro, par fixo por engine e responsabilidades de
  autenticação/TLS/modelos/UI; não prometer transação distribuída ou merge de texto.

Validação: links/anchors, exemplos executados e fixtures de falha/consumo;
análise/testes dos pacotes tocados se houver exemplo ou teste Dart novo.
Evidência de conclusão: ainda não registrada.

<a id="r-36"></a>

## R-36 — Preparar metadados da release 1.0.1

Status: planejada
MoSCoW: SHOULD
Dependências: R-35

Áreas: sete manifests, constraints internas, changelogs, guia de publicação
e preparação de distribuição existente. Não publicar, criar tags ou fazer merges.

Critérios:

- [ ] Atualizar os sete pacotes para 1.0.1 somente após as tarefas de produto;
  ajustar limites inferiores internos para exigir 1.0.1 onde a correção for
  necessária, mantendo resolução consistente dos sete artefatos distribuídos.
- [ ] Registrar mudanças realmente entregues em changelogs únicos; preservar
  histórico 1.0.0, SDK suportado e dependências externas salvo decisão validada.
  Identificar APIs novas/removidas e requisitos de migração efetivamente validados;
  não anunciar leitor abandonado ou Saropa adotado sem evidência.
- [ ] Atualizar docs/publicacao.md e exemplos de dependência; preparar diretórios
  novos com prepare_release.py, mantendo fontes, licença, filtros e inventário.
  Ferramentas de CI/lint não podem virar dependência runtime do consumidor.
- [ ] Conferir exports/assinaturas, classes implementáveis, enums e variantes
  de evento contra o mapa de R-30; documentar todas as quebras autorizadas e seus
  substitutos. Manter formatos JSON/schema e leitores; a renumeração dos pacotes
  não altera dados. Destacar nos sete releases que 1.0.1 exige revisão do upgrade.

Validação: manifests/changelogs, resolução local e inspeção dos diretórios
preparados. O teste completo dos artefatos pertence à VAL-17.
Evidência de conclusão: ainda não registrada.

<a id="val-17"></a>

## VAL-17 — Validar migração e artefatos da 1.0.1

Status: planejada
MoSCoW: SHOULD
Dependências: R-36

Áreas: workspace, fixtures 1.0.0, SQLite, exemplos e sete artefatos preparados.
Este é o gate da release de manutenção; não substitui registros históricos.

Critérios:

- [ ] Executar formato/análise/testes dos sete pacotes no SDK mínimo e no SDK
  de referência definidos em R-30. Revalidar os oito CRDTs, histórias geradas,
  concorrência, ACK parcial/perdido, edição durante falha e recuperação SQLite.
- [ ] Consumir fixtures 1.0.0 preservando estado, clocks, contextos, tombstones,
  IDs/outbox e próxima mutação após restauração. Confirmar mesmo formato de escrita
  para readers 1.0.0 e manutenção dos readers legados já documentados.
- [ ] Compilar consumidores/adaptadores migrados de 1.0.0 e executar fluxos
  equivalentes; provar preservação dos contratos fora das quebras inventariadas.
  Fixtures de uso das APIs retiradas devem apontar os substitutos documentados,
  sem mascarar quebra de fonte nem exigir compilação inalterada do legado.
- [ ] Revalidar consulta leve, lote local atômico, decoder, eventos seletivos
  e ausente/null/tombstone com falhas, concorrência e recuperação. Conferir
  remoção do fluxo legado de produção e preservação dos readers de dados.
- [ ] Inspecionar conteúdo/hashes e executar dry-runs dos sete artefatos. Usar
  consumidor fora do workspace, sem paths/overrides, em registro local somente
  leitura quando as dependências ainda não existirem no pub.dev. Preservar
  distinção entre essa prova e instalação/publicação reais no registro público.
- [ ] Executar exemplos Dart/SQLite e Flutter analyze/test/build pertinentes.
  Decidir e registrar necessidade de runtime Android conforme diff efetivo;
  mudança em lifecycle/persistência/plugin exige roteiro pertinente e evidência
  atual. Build ou evidência histórica não substituem runtime exigido pela mudança.
- [ ] Conferir CI e decisão Saropa, riscos remanescentes, documentação e registros
  por tarefa; executar check_plan.py e git diff --check. Não concluir com falha
  impeditiva ou critério pendente. Entregar instruções concretas de publicação
  manual ao autor, sem upload, tag, commit, merge ou push automático.

Validação: matriz de critérios/comandos/evidências e limites reais de plataforma,
SDK e serviços. Publicação real continua com o autor, conforme DEC-50.
Evidência de conclusão: ainda não registrada.

## APIs e simplificações incluídas na release

As tarefas abaixo fazem parte de 1.0.1 e são dependências transitivas de VAL-17.
O pedido atual planeja sua execução; nenhuma implementação foi iniciada.

<a id="r-37"></a>

## R-37 — Oferecer consulta leve de pendências

Status: concluída
MoSCoW: SHOULD
Dependências: R-32, R-39

Alvo: 1.0.1.

Critérios:

- [x] Definir consulta pública de quantidade/resumo por peer com a outbox como
  fonte; evitar cache paralelo e materialização de todos os deltas quando o
  adaptador suportar consulta leve. Usar evidências de R-32 para desenho mínimo.
- [x] Escolher o menor contrato que suporte consulta eficiente e documentar
  impacto em implementadores externos. Se houver capacidade opcional/fallback,
  justificá-los pelo caso concreto; se houver membro obrigatório novo, fornecer
  implementação de referência, suíte de contrato e instrução de migração.
- [x] Validar pendentes/enviados, ACK parcial, falha de consulta, concorrência,
  restauração e equivalência MemoryStorage/SQLite, com documentação de consumo.

Validação: contrato opcional/adaptadores externos, integração sync/facade e
recuperação SQLite, além de demonstração do custo evitado.
Resultado: pendingSummary obrigatório no storage e público na engine/facade;
266 testes, 18 checks externos e sete inventários aprovados. Em SQLite, cinco
contagens globais de 256 entradas passaram de 31537 a 3157 µs na mesma execução.
Sem schema novo; fallback para SQLite sem JSON1 documentado/testado, sem prometer
custo constante ou ganho universal.
Evidência de conclusão: [execução R-37](TRACEABILITY.md#execucao-r-37-2026-10-24)
e [contrato, migração e resultados](evidence/r37/README.md).

<a id="r-38"></a>

## R-38 — Implementar lote público com commit local atômico

Status: pronta
MoSCoW: SHOULD
Dependências: R-39

Alvo: 1.0.1. Reusar o pipeline existente de candidata, mutação, delta e commit.

Critérios:

- [ ] Expor operação pública para mutações relacionadas em vários endereços,
  com uma candidata e commit único de snapshot/outbox. Não entregar Replica
  viva nem permitir mutação após o término do lote ou fora do pipeline.
- [ ] Definir retorno, lote vazio, exceção na mutação, callback assíncrono e
  limites de uso. Escolher API mínima sem comandos/schemas de domínio paralelos;
  documentar restrições que impedem I/O ou escrita fora da transação local.
- [ ] Provar tudo-ou-nada em memória e SQLite quando falha qualquer mutação
  ou commit; preservar sequência/identidade, oito tipos e edição concorrente.
- [ ] Demonstrar consumo geral de múltiplos campos; explicar que envio/ACK
  continuam por mudança e que atomicidade local não é transação distribuída.

Validação: core/sync/facade, contrato de storage e recuperação SQLite, incluindo
rollback, campos relacionados, callbacks inválidos e falha durante o lote.
Evidência de conclusão: ainda não registrada.

<a id="r-39"></a>

## R-39 — Remover superfície legada preservando migração de dados

Status: concluída
MoSCoW: SHOULD
Dependências: R-30, R-31

Alvo: 1.0.1, com quebra de fonte expressamente incluída pelo autor.

Critérios:

- [x] Migrar/remover PendingDeltaStore e MemoryPendingDeltaStore, seus ramos
  na engine/persistência, aliases set/remove, Delta.crdt/crdtChanges e
  OutboxEntry.operationId; retirar Operation da superfície principal.
- [x] Separar remoção de API da política de dados: preservar readers e conversão
  históricos necessários aos dados 1.0.0 e anteriores já suportados, mantendo
  DTO/parser legado interno quando necessário. Não apagar snapshots/outbox nem
  renumerar dados por conveniência; leitor histórico não é API operacional nova.
- [x] Documentar upgrade dos consumidores/adaptadores, rollback e ponto único de
  manutenção de cada regra; verificar inventário externo, testes de compilação,
  migração e recuperação durável. Remover legado não autoriza mudar os oito joins.

Validação: provas de migração de fonte/dados, suíte geral/contrato/SQLite,
consumidor isolado e revisão dos imports/exports que passam a ser internos.
Resultado: 249 testes nos sete pacotes; consumidor histórico com 14 checks e
migrado isolado com 15 checks, incluindo exemplo extraído do guia. Doze probes
rejeitam APIs removidas; inventário limita quebras às previstas. Três processos
antigo/atual/antigo verificam o mesmo SQLite após edições e ACK parcial.
Evidência de conclusão: [execução R-39](TRACEABILITY.md#execucao-r-39-2026-10-24),
[provas de consumo/dados](evidence/r39/validation.json),
[workspace/review](evidence/r39/workspace.json) e
[guia de upgrade](../docs/migracao-1.0.1.md).

<a id="r-40"></a>

## R-40 — Oferecer leitura com decoder opcional

Status: planejada
MoSCoW: SHOULD
Dependências: R-42

Alvo: 1.0.1. Converter valores por contrato público sem conhecer modelos do app.

Critérios:

- [ ] Oferecer conveniência de leitura com decoder fornecido pelo consumidor,
  preservando acesso ao JSON e sem schema, codegen ou repositório genérico.
  Centralizar o percurso de consulta existente e explicitar entrada/retorno.
- [ ] Definir comportamento para ausência, valor null, tombstone e falha no
  decoder; não converter automaticamente dado inválido em sucesso ou valor padrão.
- [ ] Provar isolamento de coleções aninhadas e ausência de mutação de estado,
  clocks ou outbox durante conversão, inclusive quando o decoder falha.
- [ ] Exercitar modelo simples e JSON incompatível com ele, com erros tratados
  no consumidor; validar lifecycle e consumo pela facade.

Validação: consultas core/sync/facade e exemplo tipado, com decoder que falha e
valores aninhados; não confundir validação JSON com regra de domínio.
Evidência de conclusão: ainda não registrada.

<a id="r-41"></a>

## R-41 — Oferecer eventos seletivos e consolidar canais internos

Status: planejada
MoSCoW: SHOULD
Dependências: R-37, R-38

Alvo: 1.0.1. Permitir reação aos endereços afetados sem cache paralelo de estado.

Critérios:

- [ ] Informar endereços afetados em commits locais, lotes e merges remotos;
  definir se significam endereços processados ou valores visíveis alterados.
  Snapshot remoto deve seguir a mesma semântica, com metadados isolados.
- [ ] Demonstrar observação seletiva por endereço usando APIs públicas,
  sem polling, réplica inteira copiada ou sincronização disparada por listener.
- [ ] Consolidar emissão interna de observations/commits/errors numa fonte
  comum, preservando canais existentes quando útil e documentando qualquer
  ajuste intencional. Evitar múltiplas representações persistidas de pendências.
- [ ] Testar emissão somente após adoção, rollback sem evento de sucesso,
  ausência de replay, listeners tardios/pausados/com erro, ordem e dispose.
  Commit continua distinto de ACK; listeners não governam a transação.
- [ ] Inventariar mudança em construtores/variantes fechadas e demonstrar
  adaptação de switches externos quando necessária no guia de migração.

Validação: observações/concorrência sync/facade, lote e snapshot remoto, com
falhas de commit/ACK e fixture de consumidor seletivo.
Evidência de conclusão: ainda não registrada.

<a id="r-42"></a>

## R-42 — Distinguir ausência, valor null e tombstone na consulta

Status: pronta
MoSCoW: SHOULD
Dependências: R-39

Alvo: 1.0.1. Consulta explícita coexistindo com a conveniência valueAt atual.

Critérios:

- [ ] Expor resultado tipado para endereço ausente, valor presente inclusive
  null e remoção LWW. Definir resultado dos outros sete tipos, inclusive
  coleção vazia/contador zero vinculados, sem expor estado mutável interno.
- [ ] Reusar dono canônico do estado e consulta pontual. Não reconstruir
  toda a réplica nem inferir remoção pela existência de ACK ou outbox vazia.
- [ ] Manter semântica documentada de valueAt para consumidores que usam a
  conveniência; identificar como a nova consulta e decoder se combinam.
- [ ] Validar oito tipos, valores aninhados, concorrência, consulta durante
  commit, falha de commit, restauração SQLite e lifecycle da engine.

Validação: core/sync/facade e recuperação SQLite com ausência, LWW null,
tombstone e valores vazios existentes, usando somente contratos públicos.
Evidência de conclusão: ainda não registrada.

## Gate da fase

Concluir a release 1.0.1 somente após R-30 a R-42 e VAL-17 concluídas. Todos
esses itens pertencem ao mesmo gate; não adiar R-37 a R-42 por classificação
SemVer nem concluir apenas sua avaliação sem entregar as APIs/remoções previstas.
O piloto Saropa mantém decisão de adoção fundamentada conforme R-34.
Não marcar conclusão por este planejamento, pela baseline 243 testes ou por
VAL-05 histórico. Exigir artefatos finais, dados preservados e migração de fonte
validada, destacando que 1.0.1 contém quebras intencionais em relação a 1.0.0.
Capacidade e duração não foram estimadas pelo autor; seguir dependências e
preservar a margem acadêmica até 16/11/2026, sem prometer data de publicação.
