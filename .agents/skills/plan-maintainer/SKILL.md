---
name: plan-maintainer
description: Atualizar tarefas, índice, evidências, decisões e riscos do plano DeltaSync após trabalho autorizado, sem criar planejamento concorrente.
---

# Manutenção do plano DeltaSync

Leia [plan/README.md](../../../plan/README.md), tarefa da fase e evidências obtidas.
Mantenha critérios só na fase; índice espelha status/prioridade/dependências.
TRACEABILITY.md registra resultados; DECISIONS.md escolhas; RISKS.md impedimentos
e riscos. Não copiar requisito inteiro para múltiplos arquivos.

Concluir tarefa somente quando critérios, review e checks exigidos estiverem
satisfeitos. Registre arquivos/testes/comandos reais e limitações; baseline antiga
não valida mudança nova. Manter falhas e resultados anteriores como histórico.

Atualize status da fase/índice, gates e tarefa ativa de forma consistente.
Tarefa sem dependências satisfeitas é planejada; bloqueada exige impedimento
concreto. Não deixar várias implementações em andamento num fluxo de um agente.
Proponha próxima tarefa selecionável sem iniciá-la quando pedido autoriza apenas
manutenção.

Dependência pode ser ajustada por evidência dentro do escopo autorizado; documentar
justificativa. Nova ferramenta/otimização não vira requisito acadêmico.
Mudança material de escopo requer direção do autor; não inferir autorização de
um pedido só para atualizar checklist.

Confira links, IDs/dependências, referências cruzadas e diff. Reorganização
documental não conclui CRDTs, SQLite, integração ou validação acadêmica.
