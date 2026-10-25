# R-43 — Limpeza após o gate 1.0.1

Pedido do autor em 2026-10-25: limpar código legado não utilizado. Worktree
inicial limpa em `76e0299215ea6b78a2cfe1b137f3688a87d1a6af`.
Leitura, implementação, revisão própria, validação e manutenção seguiram as
cinco skills, em um agente. Aplicado também safe-refactor com prova antes/depois.

## Mudança e limite

Removidos de Operation interna: toJson, operator ==, hashCode e _mapsEqual.
Não havia consumidores operacionais desses membros: os testes geravam JSON
antigo e comparavam seu roundtrip. Os testes agora recebem JSON explícito,
conferem os campos lidos, as seis ordens de migração LWW e o snapshot histórico
seguido de nova mutação. Não há encoder legado de substituição no runtime.

Constructor, fromJson, validações e migrateLegacyOperation continuam idênticos,
assim como seus call sites nos readers Delta/ReplicaState. Permanecem leitura
de dados anteriores, clocks, IDs, tombstones e formatos. Nenhum export público,
SDK, dependência, API de consumidor, adaptador ou fluxo de commit foi alterado.
Apenas dois arquivos de lib mudaram: Operation e sync_types, onde saíram uma
supressão sem uso e orientação obsoleta sobre storage legado. Changelog do core
registra a manutenção. Não foram removidos arquivos, evidências ou caches.

## Validação atual

[Registro completo](validation.json) contém comandos, versões resolvidas,
outputs relevantes, hashes, inventário e comparação com os candidatos anteriores.

- Antes/depois: 48 testes do arquivo afetado aprovados. Eles integram os testes
  do core; não são somados novamente ao total do workspace.
- Formato/análise/testes em sete pacotes: 312 aprovados, nas contagens
  21/134/83/14/40/10/10, com Dart 3.13.5/Linux/SQLite real.
- Novo consumidor hosted fora do workspace: 54 testes e análise aprovados,
  sem paths/overrides; 14 probes de remoção e diagnósticos de evento/override
  confirmam as quebras já documentadas, sem acrescentar quebra pública.
- Sete candidatos novos: dry-runs aprovados com zero warnings, 85 arquivos/48
  fontes de lib conferidos no preparo e nos pacotes instalados. Registro GET-only
  encerrado, nenhum upload.

O diff dos candidatos anteriores de VAL-17 contém exatamente três arquivos:
core/lib/src/operation.dart, core/CHANGELOG.md e sync/lib/src/sync_types.dart.
Os 103 arquivos de evidências históricas permanecem intactos. Não se sobrescrevem
os resultados nem os candidatos de VAL-17 para aparentar validação da nova fonte.

Revisão própria distinta, não independente, sem impeditivos. O formatter inicial
recebeu caminhos relativos à raiz dentro do pacote; foi repetido no diretório
correto. Depois disso, o gate completo de formato passou. Nenhuma expectativa
de migração foi relaxada e nenhum teste foi removido para encobrir falha.

Não houve novo runtime/build Flutter/Android: parser, migração, pipeline,
lifecycle, plugin e app permanecem idênticos; foram removidos auxiliares sem uso
nesses percursos. A execução nativa VAL-17 é histórica e não é contada novamente.
Sem nova consulta OSV, piloto Saropa, CI remota, iOS ou SDK 3.13.0/3.12.

## Candidatos atuais e publicação

Preparação: `python3 -B scripts/prepare_release.py`.
Candidatos atuais: `/tmp/deltasync-release-parent-dkj7k781/release`.
O inventário completo está dentro de artifacts.inventory em validation.json;
comparar hashes antes de publicar. Se o diretório temporário desaparecer,
preparar outro e conferir/revalidar os arquivos correspondentes.

```sh
python3 -B plan/evidence/val17/validate_artifacts.py \
  --release /tmp/deltasync-release-parent-dkj7k781/release \
  --report /tmp/deltasync-r43-artifacts.json
```

O harness existente foi reutilizado intacto. Estes candidatos substituem os
anteriores para envio da fonte limpa. A cobertura maior do gate
[VAL-17](../val17/README.md) continua histórica para o restante inalterado;
a prova atual desta limpeza está neste registro.

Publicação permanece manual pelo autor conforme
[roteiro](../../../docs/publicacao.md): core; storage/transport;
sync/storage_testing; storage_sqflite; facade. Retirar PUB_HOSTED_URL de teste e
resolver/dry-run no pub.dev à medida que cada dependência 1.0.1 ficar disponível.
Registro local não comprova instalação pública. Não houve upload, commit, tag,
merge, push ou remoção de dados/caches.
