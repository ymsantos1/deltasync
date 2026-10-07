# Fase 5 — Validação acadêmica e entrega

Estado: ativa. Objetivo: consolidar evidências e demonstração do TCC.
Entrada: dependências por tarefa; gate final exige fases anteriores concluídas.
Saída: VAL-05 concluída. Prazo e esforço disponíveis ainda não informados.
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

Status: pronta
MoSCoW: MUST
Dependências: R-08c

Áreas: aplicativo de demonstração consumidor, exemplo, README e adaptador SQLite.
Objetivo: demonstrar uso real da biblioteca e experiência offline em fluxo
pequeno. Compass pode ser usado como exemplo, se disponível.

Critérios:

- [ ] Dois tipos CRDT, duas réplicas, edição offline e convergência após reconexão.
- [ ] SQLite preserva estado e pendências após reinício.
- [ ] Aplicativo consumidor implementar mapeamento de seus modelos e fluxo contra
  a API pública; regras de negócio/UI permanecem no app. Compass é evidência
  ilustrativa opcional, sem exigir mudanças em DeltaSync para atendê-lo.
- [ ] Registrar passos de configuração e dificuldades de integração; corrigir
  falhas gerais do contrato na biblioteca, se confirmadas; resolver necessidades
  específicas por adaptação do consumidor, sem duplicar estado/sync ou sobrescrever
  implementação interna. Mudança em DeltaSync exige justificativa aplicável a
  consumidores gerais ou defeito confirmado.
- [ ] Percurso no app comprovar edição/consulta durante indisponibilidade,
  apresentação coerente de pendência/erro/confirmação e recuperação após reinício.
  Registrar ações/resultados no consumidor escolhido; achados de usabilidade
  limitados ao cenário e aos participantes efetivamente avaliados.
- [ ] Instruções de execução/plataforma e resultado esperado reproduzíveis.
- [ ] Sem dependência de codegen ou framework de objetos.

Validação: executar aplicação consumidora e registrar versão, cenário, ações e
resultado, distinguindo integração e experiência offline. Compass, quando usado,
ilustra consumo real; sua disponibilidade não bloqueia esta tarefa nem autoriza
customização do core. Se não disponível, usar consumidor pequeno e reproduzível.
Exemplo de CRDT isolado sem storage/reconexão não satisfaz demonstração. Este
cenário complementa cobertura geral dos oito tipos em VAL-01.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="val-03"></a>

## VAL-03 — Relatório e rastreabilidade finais

Status: planejada
MoSCoW: MUST
Dependências: VAL-01, VAL-02, R-07d, R-08c

Áreas: TRACEABILITY.md e relatório acadêmico.
Objetivo: ligar requisitos a código, testes, comandos e resultados finais.

Critérios:

- [ ] Cada requisito MUST tem implementação e evidência adequada.
- [ ] Unidade, integração, recuperação real e demonstração identificadas separadamente.
- [ ] Topologia, semântica de ACK, retenção de metadados e limites documentados.
- [ ] Não alegar ganhos de desempenho ou correção universal sem evidência.

Validação: conferir matriz contra arquivos e resultados de VAL-01/VAL-02,
R-07d e R-08c; lacunas mantêm requisito incompleto.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="val-04"></a>

## VAL-04 — Alinhar texto acadêmico

Status: planejada
MoSCoW: MUST
Dependências: R-07a, R-07d, R-08c, VAL-02

Áreas: fonte editável do TCC quando fornecida; documentação de integração/manutenção,
proposta.md e registro de decisões.
Objetivo: alinhar texto/diagrama acadêmicos com entrega efetiva.

Critérios:

- [ ] Quatro subpacotes/facade e storage abstrato com adaptador SQLite/sqflite de
  referência descritos, com escolha de backend pelo consumidor conforme o
  [escopo de storage](README.md#storage-e-adaptadores).
- [ ] Correspondência da API real com métodos conceituais do PDF documentada.
- [ ] Contratos consolidados de core, estado, storage e mensagem terem diagrama
  curto e exemplos que expliquem mutação, delta, join, commit e restauração.
- [ ] Guia de integração/manutenção apontar arquivos e testes para alterar um
  comportamento de CRDT ou implementar adaptador de storage, incluindo invariantes
  e compatibilidade. Explicar implementação direta de `ReplicaStorage` e execução
  da suíte compartilhada, com commit atômico por transação ou mecanismo equivalente;
  exemplos podem usar adaptadores existentes, sem exigir outro backend persistente.
  Usar uma alteração real das tarefas como percurso documentado
  para contribuidores/forks; evitar criar extensão sem uso para demonstrar facilidade.
- [ ] Quando Compass for demonstrado, relatar consumo da API e adaptações feitas
  no app sem inferir mudanças necessárias na biblioteca; separar essa evidência
  dos resultados gerais de CRDTs, manutenção e durabilidade.
- [ ] Oito tipos e distinção de extensões futuras preservados.
- [ ] Demonstração e limitações refletem resultados obtidos.

Validação: revisão textual e correspondência com implementação final.
Somente PDF de referência disponível hoje: preparação da lista de alterações é
possível; edição final depende da fonte editável, sem sobrescrever o PDF.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="val-05"></a>

## VAL-05 — Gate final do TCC

Status: planejada
MoSCoW: MUST
Dependências: VAL-03, VAL-04

Áreas: plano, código, testes, demonstração e relatório.
Objetivo: verificar conclusão do recorte acadêmico, sem ampliar escopo.

Critérios:

- [ ] Oito tipos integrados e propriedades/deltas validados.
- [ ] SQLite, commits atômicos, clocks/outbox e recuperação demonstrados.
- [ ] ACK parcial/retry/reordenação e réplica ausente não perdem alterações.
- [ ] Transporte abstrato e formatos compatíveis/versionados verificados.
- [ ] Limpeza de R-09a/R-09b e fluxo inicial de R-08d concluídos; classes e contratos
  públicos terem responsabilidade demonstrável, sem quota de classes removidas.
- [ ] Demonstração executada; matriz e texto acadêmico alinhados.
- [ ] VAL-02 demonstrar uso real por um consumidor e VAL-04 manter documentação
  geral de integração/manutenção. Uso do Compass é exemplo adicional e não requisito
  da biblioteca; execução isolada não comprova funcionalidade ou usabilidade geral.
- [ ] Requisitos MUST concluídos; limitações explícitas.

Validação: revisar evidências de todas as tarefas MUST e executar conjunto final
de checks apenas quando mudanças ou dúvidas justificarem. Aprovação dos testes
da baseline ou da revisão de 2026-10-03, isoladamente, não conclui TCC.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="val-06"></a>

## VAL-06 — Medir tamanho dos deltas

Status: planejada
MoSCoW: SHOULD
Dependências: VAL-02

Áreas: cenário de demonstração e relatório de medição.
Objetivo: comparar bytes de delta e estado completo sob condições reproduzíveis.

Critérios:

- [ ] Informar tamanho do estado, mutações, metadados e forma de serialização.
- [ ] Medir bytes efetivos e registrar procedimento/resultado.
- [ ] Conclusão limitada ao cenário, sem ganho universal presumido.

Validação: repetir medição documentada. SHOULD; ausência justificada não bloqueia
VAL-05. Não introduzir suíte de benchmark obrigatória.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.


## Gate da fase

Verificar VAL-05; documentação migrada não marca tarefas de produto concluídas.
