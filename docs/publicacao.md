# Preparação e publicação

Os sete pacotes usam a versão 1.0.0. A publicação é manual, responsabilidade do
autor. Preparação e `--dry-run` não enviam pacotes nem reservam nomes no pub.dev.

## Preparar arquivos distribuíveis

Requisitos: Python 3 e Dart compatível com `sdk: ^3.12.0`, disponíveis no PATH.
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
Antes da primeira publicação, os dry-runs de dependentes podem falhar porque as
versões 1.0.0 ainda não existem no pub.dev. A validação histórica R-28 usou um
registro local somente leitura com os sete artefatos então numerados 2.0.0 e um
consumidor externo sem overrides;
essa prova não representa instalação do pub.dev. Após publicar cada dependência,
repita a resolução/dry-run do próximo pacote usando o registro público padrão.
Não use `PUB_HOSTED_URL` do teste local para uma publicação real.

Somente o autor executa `dart pub publish` após revisar o dry-run no diretório
preparado. Verifique propriedade/disponibilidade dos sete nomes e autenticação
no momento do envio. Publicação é permanente; confirme versão e compatibilidade.
Após os sete envios, teste um consumidor novo com as versões do pub.dev.

## Documentação, exemplos e limites

Metadados apontam para `main`; faça os merges planejados antes de publicar para
que README, arquivos e exemplos referidos estejam acessíveis nessa branch.
Os changelogs 1.0.0 descrevem os pacotes atuais. A numeração 2.0.0 usada durante
o desenvolvimento foi substituída por 1.0.0 a pedido do autor, antes da publicação.
IDs de counters e formatos compactos MV exigem leitores compatíveis; consulte
as notas de migração no README principal antes de abrir dados antigos.

O arquivo publicado não inclui exemplos completos nem evidências. Eles continuam
consultáveis no [repositório DeltaSync](https://github.com/ymsantos1/deltasync)
e no [fork Compass](https://github.com/ymsantos1/samples-for-tcc).
Testes Dart/SQLite FFI e os roteiros Android registrados não certificam iOS,
segurança de rede ou topologias arbitrárias de produção.

Referências oficiais: [publicação](https://dart.dev/tools/pub/publishing) e
[resolução entre pacotes de workspace](https://dart.dev/tools/pub/workspaces#interdependencies-between-workspace-packages).
