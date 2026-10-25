# R-36 — Preparação dos sete pacotes 1.0.1

R-36 alinha versões, constraints, changelogs e instruções de distribuição. Os
diretórios foram preparados em `/tmp/deltasync-release-parent-cgx9_tyj/release`.
São candidatos locais; **VAL-17 ainda precisa aprovar o gate completo**. Não houve
upload, publicação, tag, commit, merge ou push. A numeração patch inclui quebras
deliberadas, conforme decisão do autor, e exige revisão do upgrade.

## Estado inicial e preservação

HEAD inicial: `9fc0f68629e794c962fb9a74e163d8ebe27da27f`, com a entrega R-35
na worktree ainda não commitada. Antes de editar, registraram-se status e hashes
de 298 arquivos. A execução preservou o código e os registros de R-35; README,
guias e exemplos de dependência receberam apenas os ajustes de release previstos.
Não houve stash/reset nem sobrescrita das evidências anteriores.

O [registro das cinco etapas](../../TRACEABILITY.md#execucao-r-36-2026-10-25)
explicita revisão própria após correções, validação e manutenção. SDK usado:
Dart 3.13.5/Linux x64. Mínimo ^3.13.0 e constraints externas foram preservados.

## Pacotes e preparação

| Pacote | Versão | Arquivos preparados | Arquivos de lib |
|---|---|---:|---:|
| deltasync_core | 1.0.1 | 33 | 28 |
| deltasync_storage | 1.0.1 | 9 | 4 |
| deltasync_transport | 1.0.1 | 9 | 4 |
| deltasync_sync | 1.0.1 | 12 | 7 |
| deltasync_storage_testing | 1.0.1 | 7 | 2 |
| deltasync_storage_sqflite | 1.0.1 | 7 | 2 |
| deltasync | 1.0.1 | 8 | 1 |
| Total | | 85 | 48 |

As 17 constraints internas são ^1.0.1, inclusive desenvolvimento. Os manifests
exportados removem somente workspace/resolution; conservam os demais campos.
Licenças, README/changelog, fontes, exemplo mínimo e filtros foram inspecionados.
Não há cache, lockfile, teste, plano ou pacote aninhado nos diretórios preparados.
O [inventário](inventory.json) registra SHA-256 dos 85 arquivos e foi comparado
byte a byte com os candidatos. As 48 fontes Dart de biblioteca permanecem
idênticas às anteriores à renumeração; formatos/writers/readers/schema não mudaram.

Changelogs têm uma única entrada 1.0.1 por pacote. O rascunho rotulado 2.0.0 foi
consolidado e o histórico 1.0.0 existente foi preservado. Capacidades anteriores
ficam sob Retained capabilities; não são anunciadas como novos formatos nem
validações runtime realizadas por esta tarefa. Todos os sete avisam sobre upgrade.
Saropa continua adiado; lint/CI não foram adicionados ao runtime dos consumidores.
storage_testing depende de test para registrar sua suíte e deve ser dev_dependency
do adaptador; não integra o runtime da facade.

## Conferência pública

A [comparação](api-diff.json) cobre sete superfícies contra a revisão 1.0.0
`1e969182e8e172a8858a48ecf83a1feb2c21a455`, congelada em R-30. O
[instrumento](api_inventory.dart.txt) é uma cópia temporária do extrator existente
com início de assinatura após o comentário AST; não modifica ferramenta/dados
históricos nem confunde docstrings com código. Os nomes históricos conferem com
api_1_0_0.json; a revisão foi extraída de Git em diretório temporário.

Conferidos removidos, adicionados e membros alterados esperados por pacote,
sem diferença inesperada de modificadores das declarações existentes. Dez enums
existentes e as cinco variantes de SyncObservation permanecem. Os novos tipos
fechados FieldQuery/variantes e LocalBatch têm restrições explícitas no
[guia de migração](../../../docs/migracao-1.0.1.md#conferência-das-sete-superfícies--r-36).
OutboxSummary é valor de contagem validado. Não se alteraram assinaturas nesta
tarefa: o inventário confirma as entregas anteriores e seus substitutos.

O mapa distingue remoções de Operation/pending-store/aliases, storage obrigatório,
pendingSummary em adaptadores e construtor/getter de SyncCommitEvent. Também
identifica overrides de mergeSnapshotJson, query/decoder/batch/filtros e potenciais
colisões em subclasses/extensions. Transporte e assinaturas da suíte testing
não mudaram contra R-30; a suíte exige o novo comportamento de resumo.

## Validação e reprodução

Comandos executados na worktree de trabalho, sem publicar:

```sh
dart pub get --offline
dart pub deps --json
dart pub workspace list --json
dart --version
dart analyze
python3 -B scripts/prepare_release.py
python3 -B scripts/check_plan.py
git diff --check
```

No exemplo Flutter: `flutter pub get --offline`. O diff do lockfile contém
somente seis versões de bibliotecas locais 2.0.0 para 1.0.1; nenhum pacote externo
mudou. O app de demonstração conserva sua versão própria e suas dependências path.
A resolução Dart local contém os sete membros em 1.0.1. Análise passou.

Para repetir a conferência de API, copie o instrumento para arquivo Dart
temporário e execute com `dart --packages=.dart_tool/package_config.json <instrumento>
<raiz>`, tanto na árvore histórica extraída quanto na atual. Comparar assinaturas
exige o mesmo extrator e excluir somente o caminho interno source. O JSON registra
diferenças, não implica que consumidores antigos compilarão sem migração.

Preparar outra cópia exige destino **novo**, fora de Git. Não sobrescreva os
candidatos acima. O script captura o estado atual, inclusive alterações ainda
não commitadas. As referências oficiais de
[publicação](https://dart.dev/tools/pub/publishing) e
[workspace](https://dart.dev/tools/pub/workspaces#interdependencies-between-workspace-packages)
foram conferidas; as instruções concretas e a ordem manual estão em
[publicação](../../../docs/publicacao.md).

Os [resultados](validation.json), a [resolução](resolution.json) e o inventário
ligam a evidência aos arquivos preparados. A inspeção comparou hashes, constraints,
campos de SDK, histórico, filtros e escopo; checker não substitui esses checks.
Os testes R-35 são históricos e não foram contados novamente. R-36 não executa
dry-runs, suíte completa, consumidor hosted sem overrides ou runtime Android:
essas provas pertencem à próxima tarefa, VAL-17. Preparação/análise/resolução
local não comprovam publicação nem completam o gate da release.
