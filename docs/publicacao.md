# Preparação e publicação

Os sete pacotes estão preparados como **1.0.1**, com dependências internas
`^1.0.1`. Essa versão patch inclui quebras deliberadas de fonte; revise o
[guia de migração](migracao-1.0.1.md) e os changelogs de todos os pacotes antes
de atualizar. Dados/JSON/schema não são renumerados junto com os pacotes.

R-36 prepara metadados/diretórios; a publicação exige **gate VAL-17 aprovado**.
A publicação permanece manual, responsabilidade do autor. Preparação e dry-run
não enviam pacotes nem reservam nomes. Nenhum upload, tag, merge ou push é
autorizado por estes comandos de preparação.

## Preparar arquivos distribuíveis

Requisitos: Python 3 e Dart compatível com `sdk: ^3.13.0`, disponíveis no PATH.
Execute na raiz do repositório:

```sh
python3 scripts/prepare_release.py --output /tmp/deltasync-release
```

O destino deve ser novo e ficar fora de qualquer repositório Git. O comando recusa
sobrescrever diretórios existentes. Escolha outro destino para repetir a preparação.
Os fontes do workspace permanecem intactos. Revise/commite o código antes da
preparação final: o script copia o estado atual, inclusive alterações não commitadas.

O script exporta apenas `lib`, pubspec, licença, README, changelog e configuração
de análise quando presente. A facade inclui também o exemplo Dart mínimo. Remove
somente `workspace` e `resolution: workspace` dos manifests exportados; nomes,
versões e restrições de dependência permanecem iguais. `inventory.json`, fora dos
pacotes, registra SHA-256 de cada arquivo preparado. Não é assinatura ou atestado
de publicação. Ao adicionar novos recursos distribuíveis, ajuste a lista de cópia
no script e revalide os arquivos preparados.

O `.pubignore` raiz mantém exemplos completos, planos, evidências e outros pacotes
fora do arquivo da facade. O pub herda esse filtro desde a raiz Git, inclusive ao
operar nos subpacotes. Portanto **não publique diretamente de `packages/`**:
os arquivos seriam excluídos pelo filtro ancestral. Use os diretórios preparados
para todos os sete releases. Seus filtros locais excluem cache, build e lockfile.

## Ordem e verificações

Publicar uma versão dependente exige que as versões usadas de suas dependências
já estejam no registro de destino. A ordem sugerida considera também dependências
de desenvolvimento verificadas pelo dry-run:

1. `deltasync_core`.
2. `deltasync_storage` e `deltasync_transport`.
3. `deltasync_sync` e `deltasync_storage_testing`.
4. `deltasync_storage_sqflite`.
5. `deltasync`.

Para cada diretório preparado, nesta ordem:

```sh
cd /tmp/deltasync-release/deltasync_core
dart pub get
dart pub publish --dry-run
```

Confira a lista de arquivos, versão, licença e ausência de fontes do monorepo.
Antes da primeira publicação, os dry-runs de dependentes podem falhar se as
versões 1.0.1 exigidas ainda não estiverem disponíveis no pub.dev. Não reduza
constraints para fazer o dry-run passar com uma versão 1.0.0 incompatível.
VAL-17 consumiu os sete artefatos 1.0.1 em registro local somente leitura,
sem paths/overrides, e aprovou os sete dry-runs. Veja os
[candidatos, hashes e limites](../plan/evidence/val17/README.md).
R-28 permanece evidência histórica de uma preparação anterior. A prova
local não representa instalação/publicação do pub.dev. Após publicar cada dependência,
repita a resolução/dry-run do próximo pacote usando o registro público padrão.
Não use `PUB_HOSTED_URL` do teste local para uma publicação real.

Somente o autor executa `dart pub publish` após revisar o dry-run no diretório
preparado. Verifique propriedade/disponibilidade dos sete nomes e autenticação
no momento do envio. Publicação é permanente; confirme versão e compatibilidade.
Após os sete envios, teste um consumidor novo com as versões do pub.dev.

## Documentação, exemplos e limites

Metadados apontam para `main`; faça os merges planejados antes de publicar para
que README, arquivos e exemplos referidos estejam acessíveis nessa branch.
Cada changelog possui uma entrada 1.0.1; o rascunho de fonte antes rotulado
2.0.0 foi consolidado, preservando o histórico 1.0.0 existente. Capacidades já
presentes na baseline ficam identificadas como retidas, não como novo formato
introduzido pela renumeração. Reader antigo, versão de dados, API e número do
pacote são contratos distintos. Consulte a
[matriz de superfícies](migracao-1.0.1.md#conferência-das-sete-superfícies--r-36).

As remoções de aliases/pending-store, storage obrigatório, pendingSummary,
construtor de evento e overrides de mergeSnapshotJson exigem adaptar fonte.
Query/decoder/lote/filtros são APIs novas, com restrições documentadas. Enums
existentes e as cinco variantes de observação continuam; FieldQuery é uma nova
hierarquia fechada. Snapshot interno v9, DeltaCodec v4, ReplicaSnapshot v2,
outbox v2 e schema SQLite v1 permanecem, com os readers anteriores suportados.
Somente fonte migrada e dados recuperados em VAL-17 aprovam o upgrade completo.

CI/analyzer/lints permanecem ferramentas de desenvolvimento; Saropa foi avaliado
e adiado. O pacote storage_testing depende de test para registrar sua suíte e
deve ser usado como dev_dependency pelo adaptador; não integra o runtime da facade.

O arquivo publicado não inclui exemplos completos nem evidências. Eles continuam
consultáveis no [repositório DeltaSync](https://github.com/ymsantos1/deltasync)
e no [fork Compass](https://github.com/ymsantos1/samples-for-tcc).
Testes Dart/SQLite FFI e os roteiros Android registrados não certificam iOS,
segurança de rede ou topologias arbitrárias de produção.

Referências oficiais: [publicação](https://dart.dev/tools/pub/publishing) e
[resolução entre pacotes de workspace](https://dart.dev/tools/pub/workspaces#interdependencies-between-workspace-packages).
