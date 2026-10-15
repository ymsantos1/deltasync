---
name: plan-reader
description: Ler planejamento DeltaSync e selecionar próxima tarefa autorizada por dependências, fase e risco, sem implementar nem mudar status.
---

# Leitura do plano DeltaSync

Localize raiz que contém AGENTS.md e pubspec.yaml. Leia
[plan/README.md](../../../plan/README.md) e definição completa da tarefa na fase.
Leia decisões/riscos ligados à tarefa e evidência relevante em TRACEABILITY.md.

Pedido com ID ou escopo explícito tem precedência sobre recomendação do índice.
Na seleção automática, considere dependências satisfeitas e entrada da fase;
priorize falhas de correção/perda de dados antes de expansão. Consulte fase ativa
e próxima tarefa no índice; não fixar IDs ou fase corrente nesta skill.
Não usar RICE nem exigir encerramento de fase inteira quando dependências
específicas permitem avançar.

Retorne ID, objetivo, status real, dependências, áreas, critérios, checks exigidos
e primeiro passo executável. Diferencie implementação parcial de tarefa concluída.
Se índice e fase discordarem, exponha diferença e use código/evidência para
avaliar; não mudar estado em pedido somente de leitura.

Seleção de tarefa não autoriza implementação, ampliação de escopo ou delegação.
Para pedido que já autoriza implementar, esta leitura prepara trabalho seguinte.
