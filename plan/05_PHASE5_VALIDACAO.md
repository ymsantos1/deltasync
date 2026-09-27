# Fase 5 — Validação acadêmica e entrega

Estado: planejada. Objetivo: consolidar evidências e demonstração do TCC.
Entrada: dependências por tarefa; gate final exige fases anteriores concluídas.
Saída: VAL-05 concluída. Prazo e esforço disponíveis ainda não informados.
Riscos: relatório extrapolar evidências; omissão de tipos; validação de memória
apresentada como persistência real.
Exclusões: codegen, ObjectCrdt obrigatório e otimização sem medida.

<a id="val-01"></a>

## VAL-01 — Propriedades e regressão completas

Status: planejada
MoSCoW: MUST
Dependências: R-07a

Áreas: testes dos quatro pacotes e facade.
Objetivo: consolidar propriedades dos oito CRDTs e regressões das correções.

Critérios:

- [ ] Unidade, join algébrico, deltas, JSON/restauração cobrem oito tipos.
- [ ] Casos de concorrência, duplicação/reordenação e tombstones cobertos.
- [ ] Diagnósticos da baseline têm regressões ou limitação/compatibilidade explícita.
- [ ] Geração determinística informa sementes e condições de convergência.

Validação: suíte completa na raiz e todos os pacotes; evidência por requisito.

Evidência de conclusão: ainda não registrada; critérios permanecem abertos.

<a id="val-02"></a>

## VAL-02 — Demonstração mínima

Status: planejada
MoSCoW: MUST
Dependências: R-08c

Áreas: example/ ou aplicação de demonstração, README e adaptador SQLite.
Objetivo: demonstrar consumo manual da biblioteca em cenário pequeno.

Critérios:

- [ ] Dois tipos CRDT, duas réplicas, edição offline e convergência após reconexão.
- [ ] SQLite preserva estado e pendências após reinício.
- [ ] Instruções de execução/plataforma e resultado esperado reproduzíveis.
- [ ] Sem dependência de codegen ou framework de objetos.

Validação: executar aplicação na plataforma suportada, registrar cenário e
resultado. Exemplo Dart atual de alteração local não satisfaz demonstração.

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
Dependências: R-07a, R-07d, R-08c

Áreas: fonte editável do TCC quando fornecida; proposta.md e registro de decisões.
Objetivo: alinhar texto/diagrama acadêmicos com entrega efetiva.

Critérios:

- [ ] Quatro subpacotes/facade e storage abstrato com adaptador sqflite descritos.
- [ ] Correspondência da API real com métodos conceituais do PDF documentada.
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
- [ ] Demonstração executada; matriz e texto acadêmico alinhados.
- [ ] Requisitos MUST concluídos; limitações explícitas.

Validação: revisar evidências de todas as tarefas MUST e executar conjunto final
de checks apenas quando mudanças ou dúvidas justificarem. Aprovação dos 38 testes
da baseline, isoladamente, não conclui TCC.

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
