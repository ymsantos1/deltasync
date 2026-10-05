---
name: code-reviewer
description: Revisar diff DeltaSync para correção de CRDTs, persistência, sync e compatibilidade, sem implementar correções por pedido de review.
---

# Review DeltaSync

Leia [AGENTS.md](../../../AGENTS.md), tarefa/critério correspondente quando houver
e diff real. Se pedido não indicar tarefa, revisar escopo solicitado sem impor
associação artificial ao plano. Preserve alterações alheias.

Verifique riscos pertinentes à mudança: join versus deduplicação, ordem LWW,
identidade entre CRDTs, lacunas causais, ACK parcial, commit local/remoto, rollback,
restauração, lifecycle e callback remoto. Consulte baseline em TRACEABILITY.md
somente quando ajudar a avaliar código atual.

Avalie contrato público, formato persistido e compatibilidade; procure casos em
que teste aprovado cobre apenas exemplo simples. Priorize impacto concreto e
condições reproduzíveis; não produzir lista hipotética nem comentários cosméticos.

Reporte achado com gravidade, arquivo/linha, gatilho, consequência e correção
sugerida. Diferencie falha comprovada de risco inferido e teste ausente.
Sem achados, informe limitações da revisão; isso não substitui validação runtime.

Mesmo agente pode revisar após implementar, em etapa distinta. Não chamar esse
review de independente. Pedido só de review não autoriza editar código/status.
Em implementação autorizada, resolver achados relevantes e revalidar partes afetadas.
