# CI, advisories e SDK 3.13 — R-33

Execução de 2026-10-24 sobre `c803825f98c7e05c7770c1d287187fe2c91fdb9b`,
com worktree inicial limpa. Entrega local: workflow de três jobs, runner comum,
fixtures negativas, política de advisories e mínimo Dart ^3.13.0. O autor pediu
evitar 3.12 e autorizou alinhar para 3.13; a referência executada é 3.13.5.
Não houve execução de 3.12 nem teste específico no patch 3.13.0. Evidências
históricas R-30 permanecem intactas. Saropa não foi instalado; piloto é R-34.

## Entrega e pontos de manutenção

- `.github/workflows/ci.yml`: jobs Dart, Flutter e policy, actions por SHA,
  contents:read, checkout sem credenciais persistidas, sem upload/publicação.
- `scripts/ci.py`: resolução obrigatória, pacote por pacote pela lista canônica
  `dart pub workspace list --json`, formato/análise/testes e exemplos. Erro
  interrompe o job com código não zero. O app Flutter tem lockfile obrigatório.
- `.github/advisory-exceptions.json`: inicialmente vazio; exceção exige
  pacote/versão/ID exatos, motivo e expiração UTC. Erro de rede/resposta não
  reaproveita resposta antiga para aprovar o job. OSV consulta versões Pub
  resolvidas e segue paginação; outdated não é usado como scanner.
- `scripts/tests/test_ci.py`: onze testes de controles, sem adicionar pacote
  vulnerável aos manifests. Casos incluem aviso do pub com exit 0, falha de
  pacote/teste Flutter, expiração, paginação, rede e grafo/resposta inválidos.
- `analysis_options.yaml`: mantém recommended e exclui somente o app Flutter
  independente da análise Dart. O app recebe análise completa no próprio job.
- Sete manifests e exemplo: mínimo ^3.13.0, sem mudar versões dos pacotes ou
  ranges de dependências. Dezenove arquivos tiveram somente formato exigido
  pela nova language version; os programas parseados antes/depois são idênticos.

Estado/CRDTs, joins, codecs, commit/outbox/ACK e formatos não foram redesenhados.
Novos comandos são ferramentas de desenvolvimento, sem dependência runtime.
O [guia de CI](../../../docs/ci.md) explica atualização periódica, comandos,
exceções, permissões e distinção de build/runtime.

## Evidências por etapa

[validation.json](validation.json) contém leitura, revisão própria após
correções, comandos, diretórios, saídas reais, hashes e falhas anteriores.
[resolutions.json](resolutions.json) registra as versões efetivamente resolvidas
nos dois ambientes independentes; não são cópias de package_config/lock da raiz.

| Check local final | Resultado |
|---|---|
| Job Dart em checkout/cache novos | 309 testes: 18/134/83/14/40/10/10, sete formatos e análises limpos |
| Enlace Dart compartilhado | Dois testes aprovados |
| Exemplos Dart | Cinco conveniências/integração e CLI reset/offline/reconnect aprovadas |
| Job Flutter em outro checkout/cache | Análise/formato e sete testes aprovados |
| Android debug | main.dart e main_eight.dart compilados |
| Advisories online | 60 pacotes hospedados Dart e 46 Flutter, nenhum achado nas versões consultadas |
| Política/controles | Onze testes aprovados, incluindo códigos de falha 1/2/7/9 |
| Workflow | actionlint 1.7.7 aprovado; arquivo oficial verificado por SHA-256 |
| Formato/semântica | Dezenove árvores sintáticas canônicas idênticas ao HEAD inicial |

Os jobs finais usam clones locais distintos, sem .dart_tool/resolução prévia,
e PUB_CACHE separado e novo para cada um. O checkout Dart concluiu sem gerar
package_config no app Flutter. Isso detectou um problema real que a execução
na árvore já resolvida não mostrava: análise Dart recursiva do app Flutter sem
seu SDK. A correção limita contextos e mantém os dois percursos completos.

Falhas anteriores permanecem no relatório, com trechos decisivos e hashes dos
logs completos: regex rejeitava underscore inicial de nome Pub; formato mudou
com SDK 3.13; CLI offline precisava de argumentos; checkout limpo revelou mistura
de contextos. Corrigidos e revalidados. Revisão também reforçou tratamento de
respostas contraditórias/incompletas e dados malformados do workspace.
Nenhum resultado parcial foi usado para aprovar um job ainda falho.

## Reprodução

Com Dart 3.13.5/Flutter 3.47.7 no PATH:

```sh
python3 -B scripts/ci.py dart
python3 -B scripts/ci.py flutter
python3 -B scripts/ci.py policy
```

Para reproduzir isolamento, use dois checkouts da mesma mudança, sem copiar
pubspec.lock da biblioteca/.dart_tool, e configure PUB_CACHE diferente para
cada execução. Preserve o lockfile versionado do app Flutter. Não executar
os dois jobs no mesmo checkout para alegar independência.

A [prova de formato](format_ast.dart.txt) aceita primeiro o hash da revisão
inicial e depois os caminhos listados em validation.json. Copie-a para .dart
temporário e use `dart --packages=.dart_tool/package_config.json` para executar
com o analyzer registrado. Ela compara AST canônica, não apenas whitespace.
O checksum/release do actionlint e seus comandos estão no workflow/relatório.

## Limites

Review do próprio agente, não independente. Host Linux/OpenJDK 25.0.3/Python
3.15; workflow configura Ubuntu 24.04/Temurin 21. SDK e Gradle podem aproveitar
downloads locais; resolução Pub, package_config e consulta de advisories finais
usaram ambientes separados. Build não prova execução no plugin Android.

GitHub Actions **não foi acionado**; sem URL de run ou resultado remoto.
Configurar YAML não ativa serviço nem prova execução remota. Nenhum artefato
foi enviado/publicado. Advisory é um retrato de vulnerabilidades conhecidas
nos pacotes Pub, não prova de segurança do código/SDK/SO/Gradle/Maven. Nenhuma
exceção está ativa. R-34 é próxima; fase 6/VAL-17 continuam abertos. Sem commit.
