---
name: plan-implementer
description: Implementar tarefa autorizada do plano DeltaSync seguindo critérios da fase e limites entre core, sync, storage e transport.
---

# Implementação de tarefa DeltaSync

Leia [AGENTS.md](../../../AGENTS.md), índice e tarefa completa em plan/.
Inspecione código/testes envolvidos e alterações existentes antes da edição.
Se tarefa já foi lida no turno, reutilize contexto; não repetir discovery completo.

Implemente escopo autorizado e registre em andamento na tarefa e no índice quando
estiver executando tarefa de produto. Não interpretar dependência ausente como licença para começar
trabalho materialmente diferente; resolver pré-requisitos incluídos no pedido
quando isso estiver autorizado.

Aplique invariantes pertinentes de plan/DECISIONS.md: join correto, identidade
sem colisão, causalidade com lacunas, commit atômico e outbox sem descarte indevido.
Core/sync/contrato de storage ficam independentes de Flutter, SQL e rede concreta.
Não introduzir ObjectCrdt, build_runner ou GC como consequência automática de tarefa.

Mudança de semântica/API/formato deve explicitar compatibilidade e ter validação
adequada. Escolhas técnicas rotineiras não exigem nova aprovação; registrar
decisão com fundamento. Não expandir recorte acadêmico silenciosamente.

Cubra comportamento relevante com regressões, não testes que só espelham código.
Execute format/analyze/test proporcionais aos pacotes e consumidores afetados.
Falha por ambiente não equivale a sucesso nem autoriza enfraquecer gate.

Prepare diff para review; registre escopo, checks, desvios e lacunas.
Não marcar concluída antes de review e evidências dos critérios.
