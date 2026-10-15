---
name: plan-executor
description: Executar tarefa ou fase autorizada do plano DeltaSync com leitura, implementação, review, validação e manutenção obrigatórios, em um agente.
---

# Execução completa do plano DeltaSync

Ponto de entrada para pedidos de implementação de tarefa, próxima tarefa ou fase.
Leia [AGENTS.md](../../../AGENTS.md) e [guia de uso](../../../plan/RUNBOOK.md).
Não iniciar implementação em pedido apenas de consulta, diagnóstico ou review.

## Preparação

Leia integralmente as cinco skills abaixo antes do trabalho; reutilize leitura já
feita no turno. Elas são procedimentos do mesmo agente, não processos executáveis
ou autorização para delegar. Aplique cada uma na etapa correspondente.

1. [plan-reader](../plan-reader/SKILL.md): selecionar tarefa e verificar critérios,
   dependências, estado real e escopo autorizado.
2. [plan-implementer](../plan-implementer/SKILL.md): implementar tarefa selecionada.
3. [code-reviewer](../code-reviewer/SKILL.md): revisar diff preparado e semântica.
4. [plan-validator](../plan-validator/SKILL.md): executar checks dos critérios.
5. [plan-maintainer](../plan-maintainer/SKILL.md): registrar evidências e status.

## Ciclo obrigatório por tarefa

- Registrar tarefa ativa e status em andamento no índice e na fase; preservar
  alterações anteriores e delimitar quais mudanças pertencem à execução atual.
- Implementar apenas escopo autorizado. Ao preparar mudança, passar a em revisão.
- Aplicar code-reviewer ao diff da tarefa, incluindo arquivos novos não rastreados.
  Resolver achados que impedem critérios; voltar a implementação quando necessário.
- Passar a em validação e aplicar plan-validator. Se correção modificar código,
  revisar delta da correção e reexecutar checks afetados. Não repetir toda suíte
  sem necessidade nem substituir integração/recuperação por check mais fraco.
- Aplicar plan-maintainer: marcar critérios demonstrados e adicionar registro de
  execução em TRACEABILITY.md conforme RUNBOOK. Atualizar índice/fase, decisões,
  riscos e próximas tarefas liberadas pelo encerramento.
- Só marcar concluída com todos os critérios satisfeitos, review aprovado,
  validação aprovada e evidências reais. Rodar `python3 scripts/check_plan.py` e
  `git diff --check` após manutenção; corrigir inconsistências antes da entrega.

Falha ou evidência ausente mantém tarefa incompleta. Registrar motivo, estado
adequado e trabalho restante; sem concluir fase por aprovação parcial. Quando
etapa não puder ser executada, registrar não realizada e motivo, sem inventar
review/teste. Não alterar produto apenas para cumprir ritual de cinco skills.

## Limite e continuidade

Pedido com ID executa esse ID. Pedido de próxima tarefa executa uma selecionável
e apresenta próxima ao terminar. Pedido de fase repete ciclo em suas tarefas
autorizadas, respeitando dependências; não avança para fase seguinte automaticamente.
Não iniciar dependência fora do pedido sem autorização já existente. Se tarefa
já estiver concluída, conferir registro/estado e reportar, sem reimplementação.

Ao retomar tarefa interrompida, usar estado, diff e último registro para completar
etapas faltantes; não confundir baseline histórica com validação da mudança atual.
Ao terminar, informar tarefa/status, alteração, review, checks, limites e próxima
tarefa selecionável. Código/arquivo marcado concluído não prova qualidade por si;
checagem estrutural controla registros, não substitui julgamento nem testes.
