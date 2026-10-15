---
name: plan-validator
description: Validar critérios de tarefa DeltaSync com checks proporcionais e evidências de unidade, integração, recuperação durável ou documentação.
---

# Validação DeltaSync

Leia critérios completos da tarefa e [AGENTS.md](../../../AGENTS.md).
Escolha checks por comportamento esperado e risco da mudança, não por comando
mais fácil. Inspecione evidência anterior para evitar repetir checks sem motivo.

Código localizado: format/analyze/test do pacote e consumidores afetados.
Contrato público/camadas: incluir facade e integração relevante.
Gate final: workspace completo, inclusive novos pacotes; Dart puro não valida
build/runtime de pacote Flutter futuro.

Durabilidade SQLite exige banco real, fechamento/reabertura e plataforma
suportada registrada. Reusar MemoryStorage não comprova reinício de processo.
Convergência exige mesmo conjunto relevante de informações e cobertura de
permutação/duplicação/contexto aplicável; testar dois valores não prova oito tipos.

Mudança só documental: links/anchors, IDs únicos, dependências sem ciclo,
status do índice versus fases, escopo e frontmatter de skills, git diff --check.
Não executar suíte Dart por ritual nem reapresentar baseline como resultado novo.

Registre comando, data, ambiente, resultado e critérios cobertos/pendentes.
Review e teste são evidências distintas. Não substituir check exigido por mock
ou análise estática sem apontar lacuna. Falha/ambiente indisponível mantém tarefa
incompleta; não ampliar permissões nem ações externas.

Após checks suficientes, encerrar validação e passar evidências à manutenção.
