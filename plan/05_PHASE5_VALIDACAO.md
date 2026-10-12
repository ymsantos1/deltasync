# Fase 5 — Validação técnica e entrega

Estado: reaberta em 2026-10-12; VAL-05 pronta para validação final após o
trabalho SHOULD que for executado ou adiado.
VAL-07 mantém conclusão histórica no Android; melhorias são tarefas próprias.
Objetivo: consolidar evidências técnicas e demonstração da biblioteca.
Entrada: dependências por tarefa; gate final exige fases anteriores concluídas.
Saída: VAL-05 concluída. Escrita e revisão do TCC ficam fora do escopo desta fase.
Riscos: relatório extrapolar evidências; omissão de tipos; validação de memória
apresentada como persistência real.
Exclusões: codegen, ObjectCrdt obrigatório e otimização sem medida.

<a id="val-01"></a>

## VAL-01 — Propriedades e regressão completas

Status: concluída
MoSCoW: MUST
Dependências: R-07a

Áreas: testes dos quatro pacotes e facade.
Objetivo: consolidar propriedades dos oito CRDTs e regressões das correções.

Critérios:

- [x] Unidade, join algébrico, deltas, JSON/restauração cobrem oito tipos.
- [x] Casos de concorrência, duplicação/reordenação e tombstones cobertos.
- [x] Diagnósticos da baseline têm regressões ou limitação/compatibilidade explícita.
- [x] Achados F-01 a F-06 da análise e demais inconsistências aplicáveis terem
  evidência de correção ou limite explícito nas tarefas R-09a/R-09b/R-05/R-08d.
- [x] Geração determinística informa sementes e condições de convergência.

Validação: suíte completa na raiz e todos os pacotes; evidência por requisito.

Evidência de conclusão: [execução VAL-01](TRACEABILITY.md#execucao-val-01-2026-10-06).

<a id="val-02"></a>

## VAL-02 — Demonstração mínima

Status: concluída
MoSCoW: MUST
Dependências: R-08c

Áreas: aplicativo de demonstração consumidor, exemplo, README e adaptador SQLite.
Objetivo: demonstrar uso real da biblioteca e experiência offline em fluxo
pequeno. Compass pode ser usado como exemplo, se disponível.

Critérios:

- [x] Dois tipos CRDT, duas réplicas, edição offline e convergência após reconexão.
- [x] SQLite preserva estado e pendências após reinício.
- [x] Aplicativo consumidor implementar mapeamento de seus modelos e fluxo contra
  a API pública; regras de negócio/UI permanecem no app. Compass é evidência
  ilustrativa opcional, sem exigir mudanças em DeltaSync para atendê-lo.
- [x] Registrar passos de configuração e dificuldades de integração; corrigir
  falhas gerais do contrato na biblioteca, se confirmadas; resolver necessidades
  específicas por adaptação do consumidor, sem duplicar estado/sync ou sobrescrever
  implementação interna. Mudança em DeltaSync exige justificativa aplicável a
  consumidores gerais ou defeito confirmado.
- [x] Percurso no app comprovar edição/consulta durante indisponibilidade,
  apresentação coerente de pendência/erro/confirmação e recuperação após reinício.
  Registrar ações/resultados no consumidor escolhido; achados de usabilidade
  limitados ao cenário e aos participantes efetivamente avaliados.
- [x] Instruções de execução/plataforma e resultado esperado reproduzíveis.
- [x] Sem dependência de codegen ou framework de objetos.

Validação: executar aplicação consumidora e registrar versão, cenário, ações e
resultado, distinguindo integração e experiência offline. Compass, quando usado,
ilustra consumo real; sua disponibilidade não bloqueia esta tarefa nem autoriza
customização do core. Se não disponível, usar consumidor pequeno e reproduzível.
Exemplo de CRDT isolado sem storage/reconexão não satisfaz demonstração. Este
cenário complementa cobertura geral dos oito tipos em VAL-01.

Evidência de conclusão: [execução VAL-02](TRACEABILITY.md#execucao-val-02-2026-10-06).

<a id="val-03"></a>

## VAL-03 — Matriz de evidências e rastreabilidade

Status: concluída
MoSCoW: MUST
Dependências: VAL-01, VAL-02, R-07d, R-08c

Áreas: TRACEABILITY.md e documentação do repositório.
Objetivo: ligar requisitos a código, testes, comandos e resultados finais.

Critérios:

- [x] Cada requisito MUST tem implementação e evidência adequada.
- [x] Unidade, integração, recuperação real e demonstração identificadas separadamente.
- [x] Topologia, semântica de ACK, retenção de metadados e limites documentados.
- [x] Não alegar ganhos de desempenho ou correção universal sem evidência.

Validação: conferir matriz contra arquivos e resultados de VAL-01/VAL-02,
R-07d e R-08c; lacunas mantêm requisito incompleto.

Evidência de conclusão: [execução VAL-03](TRACEABILITY.md#execucao-val-03-2026-10-06).

<a id="val-04"></a>

## VAL-04 — Documentação de arquitetura e integração

Status: concluída
MoSCoW: MUST
Dependências: R-07a, R-07d, R-08c, VAL-02

Áreas: documentação de integração/manutenção, proposta.md e registro de decisões.
Objetivo: documentar arquitetura, API e fluxo efetivamente entregues.

Critérios:

- [x] Quatro subpacotes/facade e storage abstrato com adaptador SQLite/sqflite de
  referência descritos, com escolha de backend pelo consumidor conforme o
  [escopo de storage](README.md#storage-e-adaptadores).
- [x] Correspondência da API real com métodos conceituais do PDF documentada.
- [x] Contratos consolidados de core, estado, storage e mensagem terem diagrama
  curto e exemplos que expliquem mutação, delta, join, commit e restauração.
- [x] Guia de integração/manutenção apontar arquivos e testes para alterar um
  comportamento de CRDT ou implementar adaptador de storage, incluindo invariantes
  e compatibilidade. Explicar implementação direta de `ReplicaStorage` e execução
  da suíte compartilhada, com commit atômico por transação ou mecanismo equivalente;
  exemplos podem usar adaptadores existentes, sem exigir outro backend persistente.
  Usar uma alteração real das tarefas como percurso documentado
  para contribuidores/forks; evitar criar extensão sem uso para demonstrar facilidade.
- [x] Quando Compass for demonstrado, relatar consumo da API e adaptações feitas
  no app sem inferir mudanças necessárias na biblioteca; separar essa evidência
  dos resultados gerais de CRDTs, manutenção e durabilidade.
- [x] Oito tipos e distinção de extensões futuras preservados.
- [x] Demonstração e limitações refletem resultados obtidos.

Validação: revisar documentação e correspondência com implementação final.
Escrita e revisão do TCC não pertencem ao escopo desta tarefa.

Evidência de conclusão: [execução VAL-04](TRACEABILITY.md#execucao-val-04-2026-10-06).

<a id="val-05"></a>

## VAL-05 — Fechamento técnico da biblioteca

Status: pronta
MoSCoW: MUST
Dependências: VAL-03, VAL-04, R-10, R-11, R-12, R-13, R-14, R-15, R-18

Áreas: plano, código, testes, demonstração e documentação do repositório.
Objetivo: verificar conclusão dos requisitos técnicos MUST da biblioteca, sem ampliar escopo.
Reaberta pela revisão de 2026-10-11: R-10/R-11/R-12 são defeitos confirmados,
não extensões. Evidências anteriores permanecem válidas para os cenários executados;
o fechamento requer correção e nova validação dos casos ausentes. Reaberta
novamente pela [revisão geral de 2026-10-12](TRACEABILITY.md#revisao-geral-2026-10-12):
R-13/R-14/R-15/R-18 são MUST. Preservar histórico; revalidar após correções e
eventuais refatorações executadas. R-16, VAL-08/09/10 e R-17 não viram dependências MUST.

Critérios:

- [ ] Oito tipos integrados e propriedades/deltas validados, incluindo coleções
  LWW tipadas, igualdade/hash de clocks e restauração MV após R-10/R-13/R-14.
- [ ] SQLite, commits atômicos, clocks/outbox e recuperação demonstrados,
  incluindo ID pendente divergente, retry de abertura e snapshot MV inválido.
- [ ] ACK parcial/retry/reordenação e réplica ausente não perdem alterações.
- [ ] Transporte abstrato e formatos compatíveis/versionados verificados.
- [ ] Limpeza de R-09a/R-09b e fluxo inicial de R-08d concluídos; classes e contratos
  públicos terem responsabilidade demonstrável, sem quota de classes removidas.
- [ ] Demonstração executada; matriz e documentação do repositório alinhadas
  às correções e ao layout efetivamente entregue, sem alegar tarefas SHOULD/COULD pendentes.
- [ ] VAL-02 demonstrar uso real por um consumidor e VAL-04 manter documentação
  geral de integração/manutenção. Uso do Compass é exemplo adicional e não requisito
  da biblioteca; execução isolada não comprova funcionalidade ou usabilidade geral.
- [ ] R-10/R-11/R-12/R-13/R-14/R-15/R-18 concluídas com regressões pertinentes,
  review após correções e evidências; suíte final da raiz e seis subpacotes,
  consumidor Flutter e demonstração offline/reconnect executados após mudanças.
- [ ] Requisitos técnicos MUST concluídos; limitações e adiamentos explícitos.

Validação: revisar evidências de todas as tarefas técnicas MUST e executar conjunto
final de checks apenas quando mudanças ou dúvidas justificarem. Aprovação dos testes
da baseline ou da revisão de 2026-10-03, isoladamente, não conclui a entrega técnica.
Na reabertura atual, executar analyze/test da raiz e dos seis subpacotes, demo
em processos separados, format/analyze/test pertinentes e build/runtime do
consumidor Flutter, checker do plano e diff limpo. Atualizar matriz e limites.

Evidência: [revisão técnica VAL-05](TRACEABILITY.md#execucao-val-05-2026-10-11),
com histórico das execuções anteriores preservado. Conclusão anterior superada
pelos [novos diagnósticos](TRACEABILITY.md#revisao-tecnica-2026-10-11).
Evidência da conclusão anterior: [execução VAL-05 em 2026-10-12](TRACEABILITY.md#execucao-val-05-2026-10-12).
Evidência de nova conclusão: ainda não registrada.

<a id="val-06"></a>

## VAL-06 — Medir tamanho dos deltas

Status: concluída
MoSCoW: SHOULD
Dependências: VAL-02

Áreas: cenário de demonstração e relatório de medição.
Objetivo: comparar bytes de delta e estado completo sob condições reproduzíveis.

Critérios:

- [x] Informar tamanho do estado, mutações, metadados e forma de serialização.
- [x] Medir bytes efetivos e registrar procedimento/resultado.
- [x] Conclusão limitada ao cenário, sem ganho universal presumido.

Validação: repetir medição documentada. SHOULD; ausência justificada não bloqueia
VAL-05. Não introduzir suíte de benchmark obrigatória.

Evidência de conclusão: [execução VAL-06](TRACEABILITY.md#execucao-val-06-2026-10-07).


<a id="val-07"></a>

## VAL-07 — Validar consumo Flutter e SQLite mobile

Status: concluída
MoSCoW: SHOULD
Dependências: VAL-02, R-10, R-11, R-12

Áreas: consumidor Flutter mínimo, adaptador SQLite/sqflite e documentação técnica.
Objetivo: reduzir a lacuna entre evidência Linux/FFI e integração mobile indicada
no PDF. SHOULD por ampliar evidência de plataforma; não há defeito mobile confirmado.

Critérios:

- [x] Consumidor usa APIs públicas e factory do plugin sqflite em pelo menos
  uma plataforma mobile suportada; registrar SO, dispositivo/emulador e SDKs.
- [x] Dois tipos e duas réplicas demonstram edição offline, pendência/erro e
  convergência após reconexão no cenário de peer fixo.
- [x] Encerrar/reabrir o processo preserva estado/outbox SQLite e permite retry;
  reuso de objeto em memória ou FFI/Linux não substitui essa evidência.
- [x] Registrar configuração, build/runtime, resultados e limitações; regras
  de modelo/UI ficam no consumidor. Não exigir Compass ou backend/protocolo novo.
- [x] Se plataforma/ambiente indisponível, registrar impedimento concreto e
  justificativa de adiamento; nunca declarar mobile validado por testes desktop.

Validação: build e execução no alvo mobile escolhido, percurso offline/reinício/
reconexão reproduzível e review das adaptações/documentação. Ausência justificada
pode adiar SHOULD; não bloqueia VAL-05 nem exige validar Android e iOS conjuntamente.

Evidência de conclusão: [execução VAL-07 no Moto G52](TRACEABILITY.md#execucao-val-07-2026-10-12-mobile).
O [impedimento anterior](TRACEABILITY.md#execucao-val-07-2026-10-12) permanece no histórico.

<a id="val-08"></a>

## VAL-08 — Tornar a demonstração Flutter interativa e explicativa

Status: pronta
MoSCoW: SHOULD
Dependências: R-15, VAL-07

Áreas: consumidor Flutter, modelo de demonstração, UI e documentação técnica.
Objetivo: mostrar conflito e continuidade de edição offline além do percurso fixo.

Critérios:

- [ ] Mostrar A e B separadamente, com valores, pendências, erro e confirmação;
  usuário controla disponibilidade do peer sem exigir rede/backend novo.
- [ ] Permitir editar um campo LWW compartilhado nas duas réplicas e observar
  vencedor conforme HLC/desempate. Manter G-Counter como segundo tipo integrado.
- [ ] Permitir novas edições enquanto houver pendências e após reconectar,
  sem depender de valores hardcoded ou bloquear edição por ausência do peer.
- [ ] Separar entrada, UI, sessão/modelo e enlace do exemplo em arquivos com
  responsabilidade clara; evitar duplicar regras de commit/join da biblioteca.
- [ ] Permitir repetir o cenário, com limpeza explícita e restrita aos dados
  da demonstração; reinício real continua parte do procedimento documentado.
- [ ] Testes pertinentes, build e runtime Android comprovam conflito, edição
  durante falha, retry e estado/outbox após reinício; não exigir oito telas.

Validação: consumidor usa API pública; verificar UI e persistência em alvo mobile
registrado e rever adaptações após correções. Duas réplicas no mesmo app com peer
sintético são limite declarado; segundo aparelho/protocolo real é extensão opcional.
Evidência de motivação: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: ainda não registrada.

<a id="val-09"></a>

## VAL-09 — Ampliar histórias e metadados nas propriedades dos CRDTs

Status: pronta
MoSCoW: SHOULD
Dependências: R-13, R-14

Áreas: testes dos oito CRDTs, snapshots e integração relevante.
Objetivo: complementar fixtures pequenas com histórias reproduzíveis e estado causal.

Critérios:

- [ ] Histórias determinísticas variadas exercem os oito tipos, escritas
  concorrentes, versões substituídas, remoção/readição quando permitida,
  duplicação, reordenação e restauração.
- [ ] Registrar sementes quando houver RNG, ou enumeração explícita quando não
  houver; reportar condições de entrega/convergência e cenários executados.
- [ ] Comparar valores e metadados relevantes normalizados, preservando dots,
  contextos e tombstones; diferenças locais excluídas exigem justificativa.
- [ ] Operações posteriores a merge/restore e replay antigo não ressuscitam
  valores removidos, não reutilizam IDs e mantêm o comportamento esperado.
- [ ] Associatividade, comutatividade, idempotência e equivalência delta/snapshot
  verificadas nos casos válidos; fixtures finitas não são prova universal.

Validação: format/analyze/test do core e integração afetada; regressões de R-13/R-14
permanecem identificáveis. Evitar volume de casos sem ligação a uma propriedade.
Evidência de motivação: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: ainda não registrada.

<a id="val-10"></a>

## VAL-10 — Medir deltas e custo sob cargas distintas

Status: pronta
MoSCoW: SHOULD
Dependências: VAL-06

Áreas: script de medição, cenários reproduzíveis e resultados técnicos.
Objetivo: mostrar quando o incremental economiza bytes e quando seu custo cresce.
Diagnóstico: 100 escritas LWW pendentes no mesmo campo geraram envelope de
20.117 B contra snapshot de 452 B na reprodução local; não é ganho universal.

Critérios:

- [ ] Comparar poucas mudanças em estado previamente grande, muitas escritas
  no mesmo endereço e contexto/tags crescentes em tipo observado.
- [ ] Fixar IDs, dados, quantidade e relógio; distinguir bytes de delta,
  envelope, snapshot e metadados, sem excluir custos seletivamente.
- [ ] Registrar custo local de um percurso limitado de mutação/commit com
  SQLite real, tamanho do estado e ambiente; separar observação estrutural
  de cópia/snapshot de medida de tempo e de alegação de desempenho.
- [ ] Procedimento e resultados incluem casos favoráveis e desfavoráveis,
  condições, limites e comparação justa; não prometer redução universal.
- [ ] Não introduzir compactação, GC, protocolo novo ou alteração de join para
  melhorar números; otimização exige tarefa própria e prova de preservação.

Validação: repetir medições documentadas; informar ambiente e variação observada
sem transformar poucos tempos em benchmark universal. SHOULD, não gate MUST.
Evidência de motivação: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: ainda não registrada.

## Gate da fase

Verificar VAL-05; documentação migrada não marca tarefas de produto concluídas.
VAL-06 a VAL-10 são SHOULD; registrar adiamento justificado quando aplicável.
