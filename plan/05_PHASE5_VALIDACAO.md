# Fase 5 — Validação técnica e entrega

Estado: concluída após revalidação de VAL-05; VAL-07 segue SHOULD pronta.
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
Dependências: VAL-03, VAL-04, R-10, R-11, R-12

Áreas: plano, código, testes, demonstração e documentação do repositório.
Objetivo: verificar conclusão dos requisitos técnicos MUST da biblioteca, sem ampliar escopo.
Reaberta pela revisão de 2026-10-11: R-10/R-11/R-12 são defeitos confirmados,
não extensões. Evidências anteriores permanecem válidas para os cenários executados;
o fechamento requer correção e nova validação dos casos ausentes.

Critérios:

- [x] Oito tipos integrados e propriedades/deltas validados, incluindo o contrato
  público de coleções LWW tipadas após R-10.
- [x] SQLite, commits atômicos, clocks/outbox e recuperação demonstrados,
  incluindo ID pendente divergente e retry após falha de abertura.
- [x] ACK parcial/retry/reordenação e réplica ausente não perdem alterações.
- [x] Transporte abstrato e formatos compatíveis/versionados verificados.
- [x] Limpeza de R-09a/R-09b e fluxo inicial de R-08d concluídos; classes e contratos
  públicos terem responsabilidade demonstrável, sem quota de classes removidas.
- [x] Demonstração executada; matriz de evidências e documentação do repositório
  alinhadas à implementação após R-10/R-11/R-12.
- [x] VAL-02 demonstrar uso real por um consumidor e VAL-04 manter documentação
  geral de integração/manutenção. Uso do Compass é exemplo adicional e não requisito
  da biblioteca; execução isolada não comprova funcionalidade ou usabilidade geral.
- [x] R-10/R-11/R-12 concluídas com regressões permanentes, review após correções
  e evidências de validação; suíte final da raiz e seis subpacotes e demonstração
  offline/reconnect executadas após as correções.
- [x] Requisitos técnicos MUST concluídos; limitações explícitas.

Validação: revisar evidências de todas as tarefas técnicas MUST e executar conjunto
final de checks apenas quando mudanças ou dúvidas justificarem. Aprovação dos testes
da baseline ou da revisão de 2026-10-03, isoladamente, não conclui a entrega técnica.
Na reabertura atual, executar analyze/test da raiz e dos seis subpacotes, demo
em processos separados, checker do plano e diff limpo. Atualizar matriz e limites.

Evidência: [revisão técnica VAL-05](TRACEABILITY.md#execucao-val-05-2026-10-11),
com histórico das execuções anteriores preservado. Conclusão anterior superada
pelos [novos diagnósticos](TRACEABILITY.md#revisao-tecnica-2026-10-11).
Evidência de nova conclusão: [execução VAL-05 em 2026-10-12](TRACEABILITY.md#execucao-val-05-2026-10-12).

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

Status: pronta
MoSCoW: SHOULD
Dependências: VAL-02, R-10, R-11, R-12

Áreas: consumidor Flutter mínimo, adaptador SQLite/sqflite e documentação técnica.
Objetivo: reduzir a lacuna entre evidência Linux/FFI e integração mobile indicada
no PDF. SHOULD por ampliar evidência de plataforma; não há defeito mobile confirmado.

Critérios:

- [ ] Consumidor usa APIs públicas e factory do plugin sqflite em pelo menos
  uma plataforma mobile suportada; registrar SO, dispositivo/emulador e SDKs.
- [ ] Dois tipos e duas réplicas demonstram edição offline, pendência/erro e
  convergência após reconexão no cenário de peer fixo.
- [ ] Encerrar/reabrir o processo preserva estado/outbox SQLite e permite retry;
  reuso de objeto em memória ou FFI/Linux não substitui essa evidência.
- [ ] Registrar configuração, build/runtime, resultados e limitações; regras
  de modelo/UI ficam no consumidor. Não exigir Compass ou backend/protocolo novo.
- [ ] Se plataforma/ambiente indisponível, registrar impedimento concreto e
  justificativa de adiamento; nunca declarar mobile validado por testes desktop.

Validação: build e execução no alvo mobile escolhido, percurso offline/reinício/
reconexão reproduzível e review das adaptações/documentação. Ausência justificada
pode adiar SHOULD; não bloqueia VAL-05 nem exige validar Android e iOS conjuntamente.

Evidência de conclusão: ainda não registrada.

## Gate da fase

Verificar VAL-05; documentação migrada não marca tarefas de produto concluídas.
VAL-06/VAL-07 são SHOULD; registrar adiamento justificado quando aplicável.
