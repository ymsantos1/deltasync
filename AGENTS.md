# Instruções de trabalho — DeltaSync

Biblioteca Dart offline-first com CRDTs e deltas, no escopo de TCC.
Contexto: [proposta.md](proposta.md). Planejamento: [plan/README.md](plan/README.md).

## Organização e limites

- `packages/deltasync_core/`: CRDTs, estado, identidade, clocks e deltas.
- `packages/deltasync_storage/`: contrato Dart puro e MemoryStorage volátil.
- `packages/deltasync_storage_sqflite/`: adaptador SQLite/sqflite persistente de referência.
- `packages/deltasync_storage_testing/`: suíte compartilhada do contrato de storage.
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

## Uso real, simplicidade e manutenção

DeltaSync deve ser uma biblioteca utilizável em projetos diversos. Compass é um
exemplo de consumidor real indicado pelo autor, não alvo para adaptar o core.
Toda tarefa deve considerar quem integra a biblioteca, quem usa o aplicativo e
quem mantém, contribui ou cria forks.

- Priorizar correção, integração simples e facilidade de alteração. Código enxuto
  significa menos conceitos e duplicações; quantidade de linhas/classes não é meta.
- Justificar classes, camadas e abstrações novas com um uso concreto no fluxo ou
  nos oito CRDTs previstos. Preferir a solução mais simples que preserve invariantes;
  evitar frameworks e extensões para necessidades hipotéticas.
- Manter responsabilidade localizável: uma regra deve ter um lugar claro para ser
  alterada, sem atualizar representações paralelas da mesma informação. Explicar
  onde vivem estado, mutação, delta, join, commit e restauração.
- APIs públicas devem permitir configurar, editar, consultar e acompanhar falhas
  e sincronização sem depender de detalhes internos. Distinguir commit local,
  pendência de envio e confirmação remota; preservar edição durante falhas de rede.
- O consumidor adapta seus modelos, regras de negócio e fluxos aos contratos
  públicos da biblioteca, usando composição, mapeamento e adaptadores próprios.
  Alterar DeltaSync somente para requisito geral dos consumidores previstos ou
  corrigir defeito/contrato da biblioteca, nunca apenas para atender Compass.
  Extensão deve ter contrato público explícito; consumidor não sobrescreve
  implementação interna nem exige framework genérico de plugins.
- Exemplos, documentação e testes devem ajudar a integrar e modificar a biblioteca.
  Ao mudar contrato/estrutura, mostrar caminho de consumo e pontos de manutenção,
  incluindo testes pertinentes e compatibilidade para consumidores e forks.
- Usar Compass como exemplo de consumo quando pertinente; necessidades específicas
  dele orientam adaptadores e mudanças no próprio app. Evidência no Compass ilustra
  uso real e complementa, sem substituir, testes gerais dos CRDTs, integração e
  recuperação durável.

Aplicar estes critérios durante leitura, implementação, review e validação, com
evidências proporcionais à tarefa. Critérios de entrega estão nas fases do plano;
cumprir o procedimento exige avaliar também uso e manutenção do resultado.

## Uso adequado dos recursos do Dart

Aproveitar recursos da linguagem quando reduzirem duplicação, estados inválidos
ou esforço de compreensão. Escolher pelo problema concreto, sem exigir todos os
recursos nem modernizar classes previstas para remoção. Conferir SDK suportado,
invariantes, compatibilidade pública e formatos persistidos antes da adoção.

Consultar trechos pertinentes do [guia Dart](dart_lang_instruction.md) durante
leitura e decisões de implementação/review. Guia é referência subordinada a estas
instruções e à tarefa; seus exemplos não são APIs entregues nem receita obrigatória.

- **Enums, inclusive enhanced enums:** representar conjuntos fechados como tipos
  de CRDT, status e relações de clocks. Reusar enums existentes. Strings continuam
  na fronteira JSON; usar rótulos explícitos e estáveis, rejeitar desconhecidos.
  Não persistir `.index` nem vincular formato a renomeações de `.name`.
  Exemplo de catálogo e metadados comuns no guia; os oito CRDTs seguem previstos.

- **Contratos tipados e null safety:** expor metadados comuns em `DeltaChange`
  para evitar switches apenas para obter origem/tipo/endereço. Se uma entrada
  exige delta válido, como `OutboxEntry`, expressar isso no tipo e construtor;
  evitar campo nullable que exige `!` em todo consumo. Validar dados externos.
- **Extensions:** usar para conveniências e conversões coesas, inclusive nos
  modelos do consumidor. Resolução é estática; não substituem overrides, membros
  essenciais do contrato nem validação das invariantes.
- **Extension types:** avaliar IDs distintos em compilação quando evitarem
  confusões concretas. Reusar `ReplicaId` onde adequado; não criar wrappers em
  massa. Extension types usam o tipo de representação em runtime; não fornecem
  identidade nominal em runtime nem dispensam validação na entrada/JSON.
- **Modificadores de classe e pattern matching:** usar `abstract interface class`
  para contratos implementáveis por adaptadores; avaliar `sealed` e switches
  exaustivos para variantes fechadas. Subtipos de `sealed` ficam na mesma library
  Dart, não apenas no pacote. `final` restringe herança/implementação externa;
  considerar consumidores/forks e evitar reorganização que acrescente complexidade.

Exemplos são referências de decisão, sem obrigação de usar cada recurso.
Aplicar nas etapas descritas em [RUNBOOK.md](plan/RUNBOOK.md).

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
