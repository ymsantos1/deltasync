# Fase 5 — Validação técnica e entrega

Estado: concluída em 2026-10-13 após fechamento de R-24/R-25/VAL-14 e revalidação de VAL-05.
Conclusão de 2026-10-12 e revalidações posteriores permanecem no histórico.
Extensão de confiança SHOULD: VAL-11/VAL-12/VAL-13 concluídas em 2026-10-13;
não apagam o fechamento técnico histórico. VAL-14 MUST e VAL-15 SHOULD
registram a nova ampliação de ergonomia autorizada pelo autor.
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

Status: concluída
MoSCoW: MUST
Dependências: VAL-03, VAL-04, R-10, R-11, R-12, R-13, R-14, R-15, R-18, R-23, R-24, R-25, VAL-14

Áreas: plano, código, testes, demonstração e documentação do repositório.
Objetivo: verificar conclusão dos requisitos técnicos MUST do escopo autorizado.
Reaberta em 13/10 para ergonomia: R-24/R-25/VAL-14. Não invalida os resultados
históricos nem atribui as melhorias como requisitos novos do PDF acadêmico.
Reaberta pela revisão de 2026-10-11: R-10/R-11/R-12 são defeitos confirmados,
não extensões. Evidências anteriores permanecem válidas para os cenários executados;
o fechamento requer correção e nova validação dos casos ausentes. Reaberta
novamente pela [revisão geral de 2026-10-12](TRACEABILITY.md#revisao-geral-2026-10-12):
R-13/R-14/R-15/R-18 são MUST. Preservar histórico; revalidar após correções e
eventuais refatorações executadas. R-16/R-20, VAL-08/09/10 e R-17/R-19 não viram dependências MUST.
Em 2026-10-13, R-23 MUST corrigiu divergência G-Set descoberta em VAL-11;
gate revalidado após correção com 224 testes Dart/quatro Flutter, SQLite real
e review das correções. Evidências em [R-23](TRACEABILITY.md#execucao-r-23-2026-10-13)
e [VAL-11](TRACEABILITY.md#execucao-val-11-2026-10-13); Android final permanece em VAL-12.

Critérios:

- [x] Oito tipos integrados e propriedades/deltas validados, incluindo coleções
  LWW tipadas, igualdade/hash de clocks e restauração MV após R-10/R-13/R-14.
- [x] SQLite, commits atômicos, clocks/outbox e recuperação demonstrados,
  incluindo ID pendente divergente, retry de abertura e snapshot MV inválido.
- [x] ACK parcial/retry/reordenação e réplica ausente não perdem alterações.
- [x] Transporte abstrato e formatos compatíveis/versionados verificados.
- [x] Limpeza de R-09a/R-09b e fluxo inicial de R-08d concluídos; classes e contratos
  públicos terem responsabilidade demonstrável, sem quota de classes removidas.
- [x] Demonstração executada; matriz e documentação do repositório alinhadas
  às correções e ao layout efetivamente entregue, sem alegar tarefas SHOULD/COULD pendentes.
- [x] VAL-02 demonstrar uso real por um consumidor e VAL-04 manter documentação
  geral de integração/manutenção. Uso do Compass é exemplo adicional e não requisito
  da biblioteca; execução isolada não comprova funcionalidade ou usabilidade geral.
- [x] R-10/R-11/R-12/R-13/R-14/R-15/R-18 concluídas com regressões pertinentes,
  review após correções e evidências; suíte final da raiz e seis subpacotes,
  consumidor Flutter e demonstração offline/reconnect executados após mudanças.
- [x] Requisitos técnicos MUST do fechamento histórico concluídos; limitações e adiamentos explícitos.
- [x] Revalidar novo fechamento após R-24/R-25/VAL-14, com regressões,
  compatibilidade, consumo e manutenção demonstrados. Atualizar matriz e limites;
  preservar evidências anteriores sem usá-las para aprovar APIs ainda não entregues.

Validação: revisar evidências de todas as tarefas técnicas MUST e executar conjunto
final de checks apenas quando mudanças ou dúvidas justificarem. Aprovação dos testes
da baseline ou da revisão de 2026-10-03, isoladamente, não conclui a entrega técnica.
Na reabertura atual, executar analyze/test da raiz e dos seis subpacotes, demo
em processos separados, format/analyze/test pertinentes e build/runtime do
consumidor Flutter, checker do plano e diff limpo. Atualizar matriz e limites.

Evidências históricas: [revisão técnica VAL-05](TRACEABILITY.md#execucao-val-05-2026-10-11),
[diagnósticos seguintes](TRACEABILITY.md#revisao-tecnica-2026-10-11) e
[conclusão anterior](TRACEABILITY.md#execucao-val-05-2026-10-12). A revalidação
após as correções está em [execução VAL-05 de 2026-10-12](TRACEABILITY.md#execucao-val-05-revalidacao-2026-10-12).
Evidência de conclusão atual: [fechamento após ergonomia](TRACEABILITY.md#execucao-val-05-ergonomia-2026-10-13).

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

Status: concluída
MoSCoW: SHOULD
Dependências: R-15, VAL-07

Áreas: consumidor Flutter, modelo de demonstração, UI e documentação técnica.
Objetivo: mostrar conflito e continuidade de edição offline além do percurso fixo.

Critérios:

- [x] Mostrar A e B separadamente, com valores, pendências, erro e confirmação;
  usuário controla disponibilidade do peer sem exigir rede/backend novo.
- [x] Permitir editar um campo LWW compartilhado nas duas réplicas e observar
  vencedor conforme HLC/desempate. Manter G-Counter como segundo tipo integrado.
- [x] Permitir novas edições enquanto houver pendências e após reconectar,
  sem depender de valores hardcoded ou bloquear edição por ausência do peer.
- [x] Separar entrada, UI, sessão/modelo e enlace do exemplo em arquivos com
  responsabilidade clara; evitar duplicar regras de commit/join da biblioteca.
- [x] Permitir repetir o cenário, com limpeza explícita e restrita aos dados
  da demonstração; reinício real continua parte do procedimento documentado.
- [x] Testes pertinentes, build e runtime Android comprovam conflito, edição
  durante falha, retry e estado/outbox após reinício; não exigir oito telas.

Validação: consumidor usa API pública; verificar UI e persistência em alvo mobile
registrado e rever adaptações após correções. Duas réplicas no mesmo app com peer
sintético são limite declarado; segundo aparelho/protocolo real é extensão opcional.
Evidência de motivação: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: [execução VAL-08 em 2026-10-12](TRACEABILITY.md#execucao-val-08-2026-10-12).

<a id="val-09"></a>

## VAL-09 — Ampliar histórias e metadados nas propriedades dos CRDTs

Status: concluída
MoSCoW: SHOULD
Dependências: R-13, R-14

Áreas: testes dos oito CRDTs, snapshots e integração relevante.
Objetivo: complementar fixtures pequenas com histórias reproduzíveis e estado causal.

Critérios:

- [x] Histórias determinísticas variadas exercem os oito tipos, escritas
  concorrentes, versões substituídas, remoção/readição quando permitida,
  duplicação, reordenação e restauração.
- [x] Registrar sementes quando houver RNG, ou enumeração explícita quando não
  houver; reportar condições de entrega/convergência e cenários executados.
- [x] Comparar valores e metadados relevantes normalizados, preservando dots,
  contextos e tombstones; diferenças locais excluídas exigem justificativa.
- [x] Operações posteriores a merge/restore e replay antigo não ressuscitam
  valores removidos, não reutilizam IDs e mantêm o comportamento esperado.
- [x] Associatividade, comutatividade, idempotência e equivalência delta/snapshot
  verificadas nos casos válidos; fixtures finitas não são prova universal.
- [x] Verificar a lei de delta-mutação: partir de cópias do mesmo estado,
  comparar o resultado da mutação com a aplicação do delta retornado sobre a
  cópia anterior. Comparar também entrega individual, lote agregado e join do
  estado completo, incluindo metadados causais normalizados. Tipos separados
  para estado e delta são permitidos; `Delta.merge` agrega por ID e não substitui
  o join de cada CRDT.
- [x] Incluir dots recebidos com lacunas (por exemplo, 1 e 3 antes de 2),
  CRDTs distintos com a mesma réplica e sequências iguais, e empates de HLC em
  LWW com origens diferentes. Distinguir prefixo observado de máximo recebido;
  documentar condições de entrega que cada representação exige.

Validação: format/analyze/test do core e integração afetada; regressões de R-13/R-14
permanecem identificáveis. Evitar volume de casos sem ligação a uma propriedade.
Evidência de motivação: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Referência complementar: [comparação com delta-crdts C++](TRACEABILITY.md#referencia-delta-cpp-2026-10-12).
Evidência de conclusão: [execução VAL-09 em 2026-10-12](TRACEABILITY.md#execucao-val-09-2026-10-12).

<a id="val-10"></a>

## VAL-10 — Medir deltas e custo sob cargas distintas

Status: concluída
MoSCoW: SHOULD
Dependências: VAL-06

Áreas: script de medição, cenários reproduzíveis e resultados técnicos.
Objetivo: mostrar quando o incremental economiza bytes e quando seu custo cresce.
Diagnóstico: 100 escritas LWW pendentes no mesmo campo geraram envelope de
20.117 B contra snapshot de 452 B na reprodução local; não é ganho universal.

Critérios:

- [x] Comparar poucas mudanças em estado previamente grande, muitas escritas
  no mesmo endereço e contexto/tags crescentes em tipo observado.
- [x] Fixar IDs, dados, quantidade e relógio; distinguir bytes de delta,
  envelope, snapshot e metadados, sem excluir custos seletivamente.
- [x] Registrar custo local de um percurso limitado de mutação/commit com
  SQLite real, tamanho do estado e ambiente; separar observação estrutural
  de cópia/snapshot de medida de tempo e de alegação de desempenho.
- [x] Procedimento e resultados incluem casos favoráveis e desfavoráveis,
  condições, limites e comparação justa; não prometer redução universal.
- [x] Não introduzir compactação, GC, protocolo novo ou alteração de join para
  melhorar números; otimização exige tarefa própria e prova de preservação.
- [x] Medir escritas sequenciais de MV-Register a partir de contexto vazio em
  diferentes quantidades N, antes e depois de confirmar a outbox. Contar versões
  ativas, dots do contexto e referências a dots nos deltas pendentes, além dos
  bytes. Conferir a hipótese estrutural de N(N−1)/2 referências de contexto
  acumuladas nas N escritas pendentes atuais; distinguir essa contagem de bytes
  efetivos e tempo medido.
- [x] Medir ciclos de adição/remoção/readição em OR-Set com poucos valores
  visíveis, contando tags e eventos retidos. Explicar quando tamanho visível,
  metadados causais, snapshot e lote de envio crescem de maneiras distintas.
- [x] Registrar se resultados justificam executar R-19, qual representação
  concentra o custo e qual ganho seria verificável. Verificar margem antes do
  congelamento estrutural; ausência de ganho ou de margem leva a adiamento
  explícito da otimização, preservando resultados e fechamento MUST.

Validação: repetir medições documentadas; informar ambiente e variação observada
sem transformar poucos tempos em benchmark universal. SHOULD, não gate MUST.
Evidência de motivação: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Referência complementar: [comparação com delta-crdts C++](TRACEABILITY.md#referencia-delta-cpp-2026-10-12).
Evidência de conclusão: [execução VAL-10 em 2026-10-12](TRACEABILITY.md#execucao-val-10-2026-10-12).

<a id="val-11"></a>

## VAL-11 — Exercitar histórias geradas e múltiplas ordens de entrega

Status: concluída
MoSCoW: SHOULD
Dependências: R-21, VAL-09, R-23

Áreas: propriedades dos oito CRDTs, metadados, codecs/snapshots e integração relevante.
Objetivo: ampliar cobertura finita de VAL-09 com histórias e ordens variadas
reproduzíveis. O cenário atual chamado shuffled usa uma ordem invertida fixa.

Critérios:

- [x] Definir sementes, quantidade de histórias, tamanho, réplicas e catálogo de
  operações para os oito tipos; limitar custo da suíte e registrar semente/traço
  em qualquer falha. Reusar suporte existente antes de adicionar dependências.
- [x] Gerar operações válidas em múltiplas réplicas, incluindo valores JSON
  aninhados, concorrência, tombstones, remoção/readição quando permitida, contexto
  com lacunas e endereços distintos. Evitar histórias que ignoram pré-condições do tipo.
- [x] Comparar entrega individual, lotes agregados e join de estado sob várias
  permutações, duplicação, atraso e perda temporária seguida de reenvio. Só exigir
  convergência após todos receberem o mesmo conjunto de informação causal relevante.
- [x] Verificar equivalência de mutação/delta, associatividade, comutatividade e
  idempotência aplicáveis. Comparar valores e metadados; normalizar somente campos
  locais justificados, sem descartar causalidade para fazer o teste passar.
- [x] Incluir roundtrip e restauração no meio das histórias, nova escrita e replay
  antigo; preservar sequências/IDs. Casos duráveis afetados exigem SQLite real,
  além do snapshot em memória. Falha descoberta recebe regressão mínima reproduzível.
- [x] Revisar após correções, executar format/analyze/test dos pacotes afetados e
  registrar sementes/cobertura/limites. Histórias finitas não são prova universal.

Validação: `dart format`, `dart analyze`, `dart test`; integração/SQLite quando
afetados. Esta ampliação complementa as quatro categorias do PDF §6.9 já entregues.
Evidência de motivação: [revisão e planejamento de 2026-10-13](TRACEABILITY.md#manutencao-ajustes-consumidor-2026-10-13).
Evidência de conclusão: [execução VAL-11](TRACEABILITY.md#execucao-val-11-2026-10-13).

<a id="val-12"></a>

## VAL-12 — Revalidar runtime Android após os ajustes estruturais

Status: concluída
MoSCoW: SHOULD
Dependências: R-21, VAL-11

Áreas: consumidor Flutter de exemplo, sqflite Android, recuperação e reconciliação.
Objetivo: obter evidência do código final após R-20/R-21; o runtime de R-19
permanece histórico, e build/test Flutter de R-20 não o substituem.
Entrada: Android disponível com SDK e depuração; priorizar celular indicado pelo
autor, sem tornar emulador ou segundo aparelho uma exigência automática.

Critérios:

- [x] Registrar revisão/diff executado, Flutter/Dart, dispositivo, Android/API,
  backend sqflite e preparação; gerar e instalar o APK correspondente.
- [x] Executar edição offline, versões concorrentes e falha/retry de envio;
  confirmar disponibilidade da edição e preservação de pendências antes do ACK.
- [x] Encerrar e reiniciar o processo, verificando estado e outbox em banco
  persistente. Reconciliar réplicas e confirmar remoção apenas de IDs reconhecidos
  por ACK durável; verificar nova abertura após confirmação.
- [x] Registrar ações/resultados/logs e limitações. Distinguir duas réplicas no
  mesmo app, enlace em processo e comunicação real entre dispositivos; não
  extrapolar execução em um Android para iOS, outros modelos ou rede real.
- [x] Revisar evidências e corrigir/retestar achados relevantes antes da conclusão;
  atualizar matriz e gate técnico. Sem alvo disponível, registrar pendência ou
  adiamento SHOULD; nunca declarar runtime aprovado apenas pelo build.

Validação: `flutter analyze`, `flutter test`, `flutter build apk --debug` e runtime
no alvo registrado. Uso de dispositivo continua respeitando autorização do autor.
Evidência de motivação: [revisão e planejamento de 2026-10-13](TRACEABILITY.md#manutencao-ajustes-consumidor-2026-10-13).
Evidência de conclusão: [execução VAL-12](TRACEABILITY.md#execucao-val-12-2026-10-13).

<a id="val-13"></a>

## VAL-13 — Validar integração de consumidor externo com SQLite e rede real

Status: concluída
MoSCoW: SHOULD
Dependências: R-21, VAL-11, VAL-12

Áreas: app consumidor externo, mapeamento de modelos, APIs públicas, transporte e
experiência offline; correções gerais comprovadas da biblioteca em tarefas próprias.
Objetivo: testar integração fora do workspace da biblioteca antes da publicação
pretendida pelo autor. Preferir uma funcionalidade pequena de app existente, como
Compass, quando houver acesso; não criar outro exemplo sintético como substituto.
Entrada: identificar repositório/app, acesso autorizado, revisão da biblioteca e
canal de rede. Esta tarefa não autoriza publicação.
Impedimento inicial em 2026-10-13: consumidor externo não localizado. Superado
quando autor informou o caminho abaixo. Registro histórico:
[tentativa VAL-13](TRACEABILITY.md#tentativa-val-13-2026-10-13).
Retomada: autor informou `/projetos/tcc/samples_test_lib/compass_app`.
App/server do sample Flutter acessíveis; recorte escolhido: notas de viagem por
reserva, SQLite e HTTP entre Android e servidor Dart em processo separado.

Critérios:

- [x] Registrar app/revisão, caso de uso pequeno, SDKs/plataformas, versões dos
  pacotes e instalação fora do workspace. Verificar resolução/imports/API pública
  sem depender da configuração compartilhada de testes da biblioteca.
  Pacotes ainda não publicados podem ser consumidos por path/Git e overrides
  explícitos no app; registrar essa configuração e seu limite, sem exigir upload
  ao pub.dev para começar a validação externa.
- [x] Adaptar modelos e regras no consumidor por composição/mapeamento; configurar
  IDs/endereço, storage e transporte pelas APIs públicas. Não sobrescrever internos
  nem ampliar core apenas por necessidade específica do Compass.
- [x] Usar SQLite durável e duas réplicas comunicando por canal real escolhido pelo
  consumidor. Registrar topologia e contrato de ACK após aplicação/persistência;
  callback entre objetos no mesmo processo não satisfaz este critério.
- [x] Demonstrar edição offline, conflito, atraso/duplicação pertinente, reinício
  com pendências, perda de conexão e retry, reconciliação e outbox confirmada.
  Distinguir commit local, envio pendente e confirmação remota no fluxo do app.
- [x] Avaliar integração por quem desenvolve e uso no cenário executado: configuração,
  consultas, notificações/falhas e manutenção. Registrar dificuldades e evidências;
  não alegar estudo de usabilidade com participantes que não foram avaliados.
- [x] Classificar achados: adaptações do app ficam no app; defeitos/contratos gerais
  da biblioteca exigem tarefas próprias, regressão e novo review/check. Só concluir
  com os problemas impeditivos do caso de uso resolvidos ou recorte reavaliado pelo autor.
- [x] Registrar resultado reproduzível, limites, versões e roteiro para o autor;
  atualizar matriz/decisões/riscos. Publicação, conta e upload ao pub.dev permanecem
  com o autor e não são ações desta tarefa nem requisito acadêmico acrescentado.

Validação: instalação/build/runtime do consumidor, testes próprios pertinentes,
SQLite com reinício e comunicação real. APIs gerais alteradas exigem regressões
core/sync/storage/facade; integração externa complementa as propriedades dos oito tipos.
Evidência de motivação: [revisão e planejamento de 2026-10-13](TRACEABILITY.md#manutencao-ajustes-consumidor-2026-10-13).
Evidência de conclusão: [execução VAL-13](TRACEABILITY.md#execucao-val-13-2026-10-13).

<a id="val-14"></a>

## VAL-14 — Documentar e revalidar integração com APIs simplificadas

Status: concluída
MoSCoW: MUST
Dependências: R-24, R-25, VAL-13

Áreas: Guia técnico, exemplos, regressões e evidências de integração.
Origem: análise da integração Compass e autorização do autor em 2026-10-13.

Critérios:

- [x] Documentar percurso completo: configuração, identidade persistente, endereço/modelo, consulta, edição, falhas, pendências, confirmação e encerramento. Manter escrita acadêmica com o autor.
- [x] Mostrar as APIs de R-24/R-25, contratos de extensão e responsáveis por estado, mutação, delta, join, commit e restauração. Preservar instruções de integração sem gerador.
- [x] Revalidar workspace e consumidores afetados; repetir SQLite/rede/runtime quando o percurso mudar. Registrar comandos do PATH, versões, resultados e revisão após correções.
- [x] Comparar código manual antes/depois com a mesma funcionalidade, separando UI, configuração, transporte, servidor e testes. Não tratar linhas como meta nem alegar estudo de usabilidade com participantes.
- [x] Registrar compatibilidade e limitações, atualizar mapa/evidências e liberar revalidação de VAL-05 somente com os novos MUST satisfeitos. SHOULD pendentes não impedem este fechamento.

Validação: ciclo plan-executor, checks proporcionais ao contrato/consumidor afetado;
regressões e compatibilidade são obrigatórias na própria tarefa.
Evidência de motivação: [planejamento de ergonomia](TRACEABILITY.md#manutencao-ergonomia-2026-10-13).
Evidência de conclusão: [execução VAL-14](TRACEABILITY.md#execucao-val-14-2026-10-13).

<a id="val-15"></a>

## VAL-15 — Validar duas instalações em dispositivos físicos distintos

Status: concluída
MoSCoW: SHOULD
Dependências: R-26, R-27, VAL-13

Áreas: Identidade/configuração do exemplo consumidor e runtime em rede real.
Entrada de runtime: identificar dois dispositivos físicos disponíveis/autorizados
e definir a topologia suportada. Conclusão das dependências libera desenho e
preparação, sem afirmar que um segundo aparelho já está disponível.
Origem: análise da integração Compass e autorização do autor em 2026-10-13.

Critérios:

- [x] Definir antes da execução a topologia suportada e canal real. Configurar identidades distintas e persistentes sem editar fonte; não clonar banco nem ampliar implicitamente o par fixo para múltiplos peers.
- [x] Se houver servidor intermediário, comprovar roteamento e outbox/ACK por destinatário em escopo explícito antes do runtime. Registrar tarefa própria para alteração geral necessária; não confirmar para dois clientes com o vínculo fixo atual.
- [x] Usar dois dispositivos disponíveis/autorizados; executar edições offline/concorrentes, desconexão, reinício com pendências, retry e reconciliação, incluindo disponibilidade da edição durante falha.
- [x] Comprovar convergência e confirmações duráveis pelos bancos/IDs; registrar dispositivos, versões, canal e limites. Sem segundo aparelho, manter pendência ou adiamento SHOULD justificado.
- [x] Revisar após correções e validar app/backend e runtime afetado; não extrapolar dois dispositivos para topologia arbitrária, produção ou outras plataformas.

Validação: ciclo plan-executor, checks proporcionais ao contrato/consumidor afetado;
regressões e compatibilidade são obrigatórias na própria tarefa.
Preparação: [roteiro e topologia](../docs/val15-dois-dispositivos.md).
Hub é composição do consumidor com estado LWW materializado, sem outbox global
de entrega. Clientes mantêm outbox separada para hub; ACK de um não confirma outro.
Defaults antigos preservados; não houve alteração geral da biblioteca.
Impedimento resolvido: dois aparelhos autorizados, Moto G52 Android 13/API 33 e
Moto G53 5G Android 14/API 34. Runtime HTTP/USB, reinícios e bancos inspecionados
confirmaram convergência/ACK isolado. Review e checks do consumidor/backend aprovados.
Evidência parcial: [preparação VAL-15](TRACEABILITY.md#preparacao-val-15-2026-10-13).
Evidência de motivação: [planejamento de ergonomia](TRACEABILITY.md#manutencao-ergonomia-2026-10-13).
Evidência de conclusão: [execução VAL-15](TRACEABILITY.md#execucao-val-15-2026-10-13).

<a id="val-16"></a>

## VAL-16 — Exercitar oito CRDTs entre dois Androids com peers diretos

Status: concluída
MoSCoW: SHOULD
Dependências: VAL-15, R-07a, R-26

Origem: autor autorizou ampliar teste físico após discutir limites LWW da VAL-15.
Áreas: entrada técnica do exemplo Flutter existente, suporte HTTP e cenários de teste.
Topologia: duas engines/SQLite privados com IDs alpha/beta e peer fixo direto;
HTTP/TCP por forward/reverse USB. Não ampliar hub Compass nem contratos da biblioteca.

Critérios:

- [x] Implementar cenário explícito dos oito tipos com base causal compartilhada,
  LWW/MV concorrentes, incrementos e adição/remoção concorrente de conjuntos/mapa;
  expectativas semânticas documentadas e testes gerais independentes dos aparelhos.
- [x] Usar APIs públicas, IDs/bancos isolados e ACK somente após commit remoto;
  preservar exemplos anteriores e fechar recursos/rejeitar envelopes inválidos.
- [x] Validar em dois Androids: falha de rede, edição offline, reinício com outbox,
  retry/duplicação, convergência dos oito tipos e resolução causal do MV-Register.
- [x] Inspecionar SQLite/metadados/IDs/outboxes após reinícios e ACK, registrar
  APKs/aparelhos/canal, sem confundir igualdade de valores com toda causalidade.
- [x] Revisar após correções, passar análise/testes/build/runtime e atualizar mapa,
  evidências/decisões/riscos; manter limites de exemplo técnico sem produção/iOS.

Validação: analyze/test/build do exemplo e testes HTTP/SQLite dos cenários;
runtime em Moto G52/G53 disponíveis. Sem novo pacote ou dependência de produção.
Impedimento resolvido: telas desbloqueadas permitiram retomar os mesmos bancos.
Dois ramos, restauração, ACK isolado, convergência dos oito, replay e resolução
causal MV passaram no Android. Túneis temporários removidos, bancos preservados.
Evidência parcial: [preparação VAL-16](TRACEABILITY.md#preparacao-val-16-2026-10-13).
Evidência de conclusão: [execução VAL-16](TRACEABILITY.md#execucao-val-16-2026-10-13).

## Gate da fase

Novo fechamento concluído após R-24/R-25/VAL-14 e revalidação de VAL-05.
VAL-15 concluiu a evidência adicional de dois Androids físicos em 2026-10-13,
com hub LWW/SQLite, ACK isolado, restauração e convergência; limites em DEC-48.
R-26/R-27/VAL-15 SHOULD podem ser adiadas com justificativa; codegen fica fora.

VAL-05 concluiu o gate técnico MUST. VAL-06 a VAL-10 SHOULD foram concluídas;
R-19 COULD concluiu; VAL-05 foi revalidada após compactação, recuperação SQLite
e validação do consumidor Flutter/Android. R-20 SHOULD concluiu em 2026-10-13;
a suíte completa, demonstração offline/reconnect, SQLite e Flutter analyze/test/build
revalidaram o gate após refatoração. Runtime Android não foi repetido em R-20,
sem dispositivo conectado e sem mudança na integração de plataforma. Evidências
anteriores permanecem no histórico.
R-21 revalidou o gate com suíte completa, SQLite/CLI e Flutter analyze/test em 2026-10-13.
VAL-11/R-23 revalidaram o gate em 2026-10-13: 224 testes Dart e quatro Flutter,
com histórias geradas e reabertura SQLite. VAL-12 concluiu Android final no Moto G52/API 33, com dois reinícios reais,
SQLite e reconciliação; VAL-13 concluiu notas no Compass externo, com SQLite
e HTTP/TCP entre Android e processo Dart, 72 testes do app e 13 do servidor.
São ampliações SHOULD;
complementam as quatro categorias de testes já demonstradas;
não invalidam resultados históricos nem certificam prontidão para publicação.
Escrita e revisão do TCC permanecem fora desta fase.
