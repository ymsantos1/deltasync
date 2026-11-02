# R-45 — preparação local da versão 1.0.2

Concluída em 2026-11-02. Pedido do autor para preparar a versão antes do commit.
Sem commit, tag, push ou publicação nesta tarefa. Não equivale ao gate completo
de envio dos novos archives ao pub.dev.

## Alterações e revisão

Leitura: R-44 concluída; conferidos worktree, sete manifests, script de exportação,
histórico 1.0.1 e consumidores por path. Mantido o alinhamento dos sete pacotes.
Implementação: sete versões 1.0.2, 17 constraints internas ^1.0.2, entradas novas
nos sete changelogs, README, guia de publicação e [notas 1.0.2](../../../docs/notas-1.0.2.md).

Mudança funcional: replay ordenado em lote de R-44 no sync, já presente antes
desta tarefa. SQLite tem duas regressões novas da correção. Outros pacotes
recebem alinhamento de metadados, sem funcionalidades fictícias. Não foram
alterados SDK, APIs, formatos, testes físicos congelados ou código do hub.
Fontes/locks históricos usados nas medições não são renumerados retroativamente.

Review próprio aprovado, não independente: conferidos constraints e changelogs,
compatibilidade com 1.0.1 e distinção entre correção entregue e pull/ACK futuro.
Documentação de publicação passou a identificar candidatos R-43/VAL-17 como
históricos 1.0.1, evitando reutilizá-los como release 1.0.2.

## Validação nova

- `dart pub get --offline`: resolução do workspace aprovada, sem atualizar
  dependências externas por iniciativa desta tarefa.
- Em cada um dos sete pacotes: `dart format --output=none --set-exit-if-changed
  lib test`, `dart analyze` e `dart test --reporter expanded`, todos exit 0.
- 314 testes: facade 21, core 134, storage 14, transport 10, sync 83,
  storage_testing 10 e storage_sqflite 42.
- `python3 scripts/prepare_release.py --output
  /tmp/deltasync-release-1.0.2-7a05e2e176df4a7db9e3b6ca194384d1`: sete diretórios
  standalone, 85 arquivos. Conferidos hashes, versão, changelog e 17 constraints;
  manifests exportados não contêm workspace, resolution ou overrides.
- `python3 scripts/check_plan.py` e `git diff --check` após manutenção.

Comandos, saídas e exit codes em [checks.json](checks.json) e `logs/`.
[Inventário dos candidatos](export-inventory.json). O destino em `/tmp` é
temporário e contém a fonte anterior ao commit; reexportar para envio final.

## Limites de entrega

Gate hosted, dry-runs dos sete candidatos 1.0.2, advisories online, instalação
hosted e publicação não foram executados nesta preparação de metadados.
Dependentes exigem ^1.0.2 no registro de destino; não reduzir constraints para
resolver contra a versão antiga. Gate/publicação 1.0.1 permanecem históricos.
Nenhum novo APK ou teste físico foi executado por renumeração; o consumidor
Compass usa paths e mantém seus próprios registros no repositório dele.

Manutenção: quatro critérios R-45 marcados; fase, índice, TRACEABILITY e guia
reconciliados. Preparação autorizada concluída, publicação continua separada.
