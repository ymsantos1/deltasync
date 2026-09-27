# Como executar o planejamento

Use um pedido curto. O procedimento completo é
[plan-executor](../.agents/skills/plan-executor/SKILL.md).

```text
$plan-executor Execute R-01.
```

```text
$plan-executor Execute a próxima tarefa pronta do plano.
```

```text
$plan-executor Execute a fase 1, com review, validação e atualização do plano por tarefa.
```

Pedidos em linguagem natural, como “implemente R-01” ou “execute a próxima tarefa
do plano”, também devem seguir esse ciclo por instrução de AGENTS.md. Em ambiente
que não liste a skill, pedir leitura de `.agents/skills/plan-executor/SKILL.md`.
Usar “fase” autoriza tarefas dessa fase; “próxima tarefa” encerra após uma entrega.

## O que o agente deve fazer

| Etapa | Skill | Resultado exigido |
|---|---|---|
| Leitura | plan-reader | Tarefa, dependências e critérios verificados |
| Implementação | plan-implementer | Mudança delimitada e regressões pertinentes |
| Review | code-reviewer | Diff revisado e achados impeditivos resolvidos |
| Validação | plan-validator | Comandos/resultados ligados aos critérios |
| Manutenção | plan-maintainer | Critérios, índice, fase e evidências atualizados |

Cinco skills lidas e aplicadas por tarefa, no mesmo agente. Sem subagentes.
Achado ou falha retorna à implementação; revisão e checks afetados são repetidos.
Review do próprio agente não é independente. Pedido só de leitura/review não
autoriza implementar ou atualizar status de produto.

## Controle do andamento

- Na fase: status, checkboxes e campo “Evidência de conclusão” são atualizados
  conforme resultado, apontando registro real em TRACEABILITY.md.
- No índice: status/dependências espelhados; campo “Tarefa ativa” identifica
  trabalho em andamento, revisão ou validação.
- Em TRACEABILITY.md: registro de execução com cinco etapas, inclusive falhas.
- Em DECISIONS.md/RISKS.md: registrar escolhas ou riscos que realmente mudaram.

Concluída exige critérios satisfeitos, review e validação aprovados. Dependência
concluída pode tornar outra tarefa pronta; gate da fase só fecha com suas entregas.
Falha de teste mantém tarefa em andamento ou em validação, conforme trabalho
restante; bloqueada exige impedimento concreto. Interrupção deixa registro
suficiente para retomar sem inventar evidências.

## Registro por execução

Adicionar em [TRACEABILITY.md](TRACEABILITY.md), mantendo histórico. Uma execução
posterior da mesma tarefa recebe novo registro. Este exemplo é formato, não
evidência; substituir textos entre parênteses por resultados reais.

```markdown
## Execução R-01 — (data da execução)

Status final: concluída
Skills: plan-reader, plan-implementer, code-reviewer, plan-validator, plan-maintainer
Leitura: (dependências verificadas e critérios identificados)
Implementação: (arquivos e comportamento alterados)
Review: aprovado
Achados: (nenhum impeditivo restante; descrever correções ou limites)
Validação: aprovada
Comandos: (comandos exatos, diretórios, ambiente e resultados)
Critérios: (ligar cada critério aos testes/resultados ou decisão documentada)
Manutenção: (checkboxes, índice, fase, decisões/riscos e próxima tarefa atualizados)
Limitações: (limites concretos ou nenhuma limitação adicional conhecida)
```

Execução incompleta usa status real; review/validação podem registrar “não
realizado: motivo” ou “reprovada: motivo”. Não copiar exemplo preenchendo
aprovação quando trabalho não foi executado.

## Checagem do plano

Na raiz do projeto:

```sh
python3 scripts/check_plan.py
git diff --check
```

Script somente lê arquivos. Verifica links/anchors locais, metadados básicos das
skills, tarefas/indexação, status, dependências sem ciclos, tarefa ativa e gates.
Conclusão sem checkboxes marcados ou registro de review/validação é rejeitada.
Retorna código diferente de zero em inconsistência. Não executa skills, Dart ou
testes, não muda status e não certifica conteúdo das evidências.

As verificações de implementação continuam derivadas da tarefa e de AGENTS.md:
análise/testes proporcionais, integração das camadas e SQLite real quando exigido.

## Referência moscow.md

[moscow.md](../moscow.md) preserva prompt original como referência histórica.
Fluxo vigente pertence a AGENTS.md e plan/: um agente, sem RICE artificial,
sem novos requisitos de codegen e sem copiar regras antigas de aprovação para
tarefas já autorizadas pelo usuário.
