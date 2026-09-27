# Instruções de trabalho — DeltaSync

Biblioteca Dart offline-first com CRDTs e deltas, no escopo de TCC.
Contexto: [proposta.md](proposta.md). Planejamento: [plan/README.md](plan/README.md).

## Organização e limites

- `packages/deltasync_core/`: CRDTs, estado, identidade, clocks e deltas.
- `packages/deltasync_storage/`: contrato e MemoryStorage; ainda sem SQLite.
- `packages/deltasync_sync/`: outbox, mutações e fluxo remoto.
- `packages/deltasync_transport/`: contrato de transporte e envelopes.
- `lib/deltasync.dart`: facade; `test/`: somente seus testes.
- `plan/`: escopo/tarefas/evidências/decisões/riscos.
- `.agents/skills/`: procedimentos de trabalho, sem agentes especializados.

Use um agente. Não delegar ou criar subagentes, salvo pedido explícito do usuário.
Faça leitura, implementação, review, validação e manutenção como etapas distintas;
review pelo próprio implementador não é revisão independente.

Core, sync e contrato de storage não dependem de Flutter, SQL, banco ou protocolo
de rede. SQLite/sqflite é adaptador de referência previsto para o TCC; MemoryStorage
é volátil. Oito CRDTs permanecem no escopo. Codegen/build_runner, ObjectCrdt e
GC destrutivo são extensões futuras; invariantes em [DECISIONS](plan/DECISIONS.md).

## Procedimentos

Para implementar tarefa, próxima tarefa ou fase do plano, aplicar
[plan-executor](.agents/skills/plan-executor/SKILL.md), mesmo quando usuário não
nomear a skill. Esse procedimento exige leitura e aplicação das cinco skills
abaixo por tarefa, com review, validação e manutenção antes da conclusão.
Guia de pedidos e registro: [RUNBOOK.md](plan/RUNBOOK.md).

Leia SKILL.md completo quando aplicar procedimento, reutilizando leitura já feita
no turno. No ciclo completo, ler cinco skills; fora dele, apenas procedimento
solicitado. Carregue só fase/referências pertinentes, não todos os planos.

| Pedido/etapa | Procedimento |
|---|---|
| Ler plano ou escolher próxima tarefa | [plan-reader](.agents/skills/plan-reader/SKILL.md) |
| Implementar tarefa autorizada | [plan-implementer](.agents/skills/plan-implementer/SKILL.md) |
| Revisar diff ou correção conceitual | [code-reviewer](.agents/skills/code-reviewer/SKILL.md) |
| Verificar critérios e evidências | [plan-validator](.agents/skills/plan-validator/SKILL.md) |
| Atualizar plano após trabalho | [plan-maintainer](.agents/skills/plan-maintainer/SKILL.md) |

Pedido completo de implementação inclui etapas pertinentes de review/validação/
manutenção. Pedido só de leitura, diagnóstico ou review não autoriza correção.
Não pedir novamente aprovação já dada; resolver escolhas rotineiras dentro do
escopo. Mudança material de proposta ou ação externa requer autorização própria.

## Código e verificação

Siga convenções Dart existentes; documente semântica e limites das APIs públicas.
Inspecione worktree e preserve alterações do usuário. Use apply_patch em edições.
Mudanças de API/formato precisam explicitar compatibilidade; regressões devem
cobrir comportamento, especialmente falhas/concorrência/recuperação.

Para mudança localizada, executar no pacote afetado:

```sh
dart format --output=none --set-exit-if-changed lib test
dart analyze
dart test
```

Formatar arquivos editados quando necessário. Incluir consumidores/facade quando
contrato afetar outros pacotes. Validação completa do workspace atual:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_transport; do
  (cd "$package" && dart analyze && dart test) || exit 1
done
git diff --check
```

Pacotes novos entram na validação conforme sua tecnologia; pacote Flutter futuro
também exige checks/build/runtime pertinentes. Não confundir suíte da raiz com
todos os testes, MemoryStorage com durabilidade ou análise estática com integração.

Mudança só documental exige links/anchors, IDs/dependências, consistência de
status, frontmatter das skills e diff limpo; testes Dart só se houver motivo.
Registrar evidências em TRACEABILITY.md e status no índice/fase. Nenhuma tarefa
concluída sem critérios satisfeitos e validação adequada.

Após manutenção, executar `python3 scripts/check_plan.py` e `git diff --check`.
Checker não executa skills/testes nem modifica plano; controla consistência dos
registros. `moscow.md` é referência histórica; regras vigentes estão aqui e em plan/.
