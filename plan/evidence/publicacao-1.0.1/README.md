# Publicação 1.0.1 — 2026-10-25

Os sete pacotes foram publicados no pub.dev após pedido explícito do autor.
Fonte: main, commit `c5d5bb400267eb7ca1fe88e4e60e51d74ec44c11`, worktree
inicial limpa. Os três jobs remotos passaram antes do primeiro envio:
[GitHub Actions](https://github.com/ymsantos1/deltasync/actions/runs/40233077899).
Nenhum workflow de publicação automática foi adicionado.

| Pacote | Versão pública | Arquivos conferidos |
|---|---|---|
| deltasync_core | [1.0.1](https://pub.dev/packages/deltasync_core/versions/1.0.1) | 32 |
| deltasync_storage | [1.0.1](https://pub.dev/packages/deltasync_storage/versions/1.0.1) | 8 |
| deltasync_transport | [1.0.1](https://pub.dev/packages/deltasync_transport/versions/1.0.1) | 8 |
| deltasync_sync | [1.0.1](https://pub.dev/packages/deltasync_sync/versions/1.0.1) | 11 |
| deltasync_storage_testing | [1.0.1](https://pub.dev/packages/deltasync_storage_testing/versions/1.0.1) | 6 |
| deltasync_storage_sqflite | [1.0.1](https://pub.dev/packages/deltasync_storage_sqflite/versions/1.0.1) | 6 |
| deltasync | [1.0.1](https://pub.dev/packages/deltasync/versions/1.0.1) | 7 |

## Envio e conferência

Nova preparação em `/tmp/deltasync-release-parent-yglhq7f9/release` reproduziu
exatamente os 85 hashes aprovados em R-43, incluindo 48 fontes de lib.
Consulta pública inicial confirmou sete versões 1.0.0 e nenhuma 1.0.1.
Cada pacote recebeu resolução e dry-run no registro público antes do upload;
todos os sete dry-runs passaram sem warnings. Envios seguiram a ordem da tabela,
usando `dart pub publish --force` com autorização já dada pelo autor.
PUB_HOSTED_URL do registro de testes foi retirado do ambiente dos comandos.

Após cada envio, foram consultados metadata e arquivo público 1.0.1. SHA-256
do archive corresponde ao divulgado pelo pub.dev; os hashes dos 78 arquivos
distribuídos correspondem ao inventário aprovado. Os sete .pubignore preparados
não integram os arquivos publicados. Não se compara o hash do tar público ao
tar sintético do registro local: metadados do archive podem diferir; o conteúdo
foi conferido arquivo por arquivo.

O índice público demorou a propagar dependências recém-enviadas. Tentativas
de resolução que ainda viam 1.0.0 foram repetidas; constraints e versões não
foram reduzidas. Nenhum upload confirmado foi repetido. Esses resultados
intermediários permanecem no [registro](validation.json).

## Consumidor público

Consumidor fora do workspace, com cache inicialmente novo, instalou os sete
pacotes hosted 1.0.1 diretamente do pub.dev, sem paths/overrides. Os arquivos
instalados coincidem com o mesmo inventário aprovado. `dart analyze test` e
54 testes passaram em Dart 3.13.5/Linux/SQLite FFI. Os testes reutilizam as
fixtures públicas já aprovadas; não são 54 novos casos da biblioteca.

[Validação e hashes](validation.json) registra fonte, CI, URLs, arquivos, saídas,
propagação e consumidor. Credenciais/tokens não integram a evidência. Nenhum
código, versão ou formato foi alterado para publicar; nenhum commit, tag, merge
ou push foi executado pelo agente. Atualizações posteriores são só registros.

As quebras de fonte deliberadas em 1.0.1 continuam no
[guia de migração](../../../docs/migracao-1.0.1.md). Publicação e instalação
públicas agora estão demonstradas; isso não amplia as garantias para iOS,
topologias arbitrárias, autenticação/TLS ou consumidores desconhecidos.
Próximos envios exigem nova versão e autorização; merge na main continua
executando somente os checks existentes.
