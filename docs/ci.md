# Verificações locais e GitHub Actions

O workflow em `.github/workflows/ci.yml` configura três jobs independentes:

| Job | Verificações |
|---|---|
| Dart 3.13.5 stable | Resolução, advisories, formato/análise/testes de todos os pacotes do workspace, exemplos Dart e teste do enlace |
| Flutter 3.47.7 stable | Resolução/advisories próprios, formato/análise/testes do exemplo e builds debug das duas entradas Android |
| Policy | actionlint 1.7.7, fixtures de falha, consistência do plano e whitespace do diff local/último commit |

O mínimo declarado é `^3.13.0`, conforme orientação posterior do autor na R-33.
A execução de referência usa 3.13.5, na família mínima 3.13 e stable selecionada.
Não se executa Dart 3.12. Isso não representa teste específico no patch 3.13.0.
Baseline e evidências anteriores com 3.12 são registros históricos preservados.
Atualize a versão stable fixada após conferir releases e repetir os checks;
não trate o alias móvel stable como prova da versão previamente registrada.

## Comandos compartilhados

Na raiz, usando os SDKs selecionados no PATH:

```sh
python3 -B scripts/ci.py dart
python3 -B scripts/ci.py flutter
python3 -B scripts/ci.py policy
```

O script usa os comandos `dart` e `flutter`; caminhos alternativos podem ser
passados em `--dart`/`--flutter`. Exige Python 3.9+ e checkout Git com HEAD e
seu pai. O job policy verifica também `git diff --check HEAD^ HEAD`, útil em
checkout limpo; no pull request padrão do Actions, esse diff é o merge com a base.
Actionlint valida separadamente o YAML e as expressões do workflow; o script
não simula um runner do GitHub nem afirma execução remota.

Em Dart, `dart pub get` sempre roda, seguido de `dart pub workspace list --json`.
Essa lista canônica define quais pacotes recebem formato, análise e testes;
adicionar um pacote Dart ao workspace não exige copiar outra lista no workflow.
Qualquer falha encerra o job e preserva seu código de saída. O SQLite FFI é
exercitado pelos testes de storage/testing/recuperação, não substituído por memória.
O analyzer da raiz exclui somente `example/flutter_mobile/**`, pois esse app
tem SDK/configuração próprios e análise integral no job Flutter. Isso permite
executar o job Dart sem resolução Flutter prévia; nenhum pacote da biblioteca
foi excluído da análise. A validação local usa checkouts separados por job.

Os exemplos novos usam somente contratos públicos. A CLI de reconciliação roda
reset/offline/reconnect em diretório temporário próprio, sem tocar bancos do
consumidor. O exemplo Flutter tem resolução separada, lockfile obrigatório
(`pub get --enforce-lockfile`) e seus próprios testes. A biblioteca não versiona
lockfile; seu job resolve o grafo compatível a cada checkout limpo.
Os dois builds usam `lib/main.dart` e `lib/main_eight.dart`; não instalam APK,
publicam artefatos ou comprovam runtime no plugin Android.

## Política de advisories

Pub pode imprimir um advisory e ainda terminar a resolução com sucesso.
`pub outdated` informa versões disponíveis e não é usado como scanner.
Ver [documentação do Dart](https://dart.dev/tools/pub/security-advisories).

Após resolução, o script lê `dart pub deps --json` de cada workspace e consulta
online o [OSV querybatch](https://google.github.io/osv.dev/post-v1-querybatch/)
para os nomes/versões hospedados no ecossistema Pub. OSV inclui Pub e agrega
fontes como GitHub Advisory Database; ver [fontes e cobertura](https://google.github.io/osv.dev/data/).
O serviço avalia as versões; não há comparador SemVer paralelo. Paginação é
seguida até o fim, e resultados são associados à ordem documentada da consulta.

O fluxo suporta dependências Pub hospedadas, incluindo nomes com underscore
inicial. Bibliotecas locais/path/workspace e componentes SDK não são consultados
como pacotes publicados. Fonte desconhecida, como git, falha explicitamente;
esta política não é um scanner completo de SDK, código, SO, Gradle ou Maven.
Forks com repositório hospedado privado devem adaptar o scanner antes de usá-lo;
não enviar metadados privados ao serviço público. O projeto usa pub.dev.

| Situação | Resultado |
|---|---|
| Nenhum advisory conhecido nas versões consultadas | Job continua |
| Advisory sem exceção exata | Exit 1; corrigir dependência ou revisar exceção |
| Falha de rede/TLS/HTTP, resposta inválida/incompleta ou paginação repetida | Exit 2; job não fica verde com resposta de cache |
| Exceção expirada, vazia, duplicada ou não utilizada | Exit 2; corrigir/remover configuração |
| Falha de resolução, análise, formato, teste ou build | Código não zero do comando, sem continuar o job |

Exceções vivem em `.github/advisory-exceptions.json`, inicialmente vazio. Para
aceitar um caso, registre package, versão exata, ID, reason e expires (data UTC):

```json
[
  {
    "package": "example_package",
    "version": "1.2.3",
    "id": "GHSA-example-only",
    "reason": "Justificativa revisada com referência ao risco e plano de correção",
    "expires": "2026-12-01"
  }
]
```

Esse exemplo não é uma exceção ativa. Não usar wildcard ou supressão genérica;
um upgrade exige revisar novamente a combinação pacote/versão/ID. A lista
ignored_advisories do pub não substitui essa revisão e não esconde achados do
OSV. Ausência de achado não prova ausência de vulnerabilidade; lint, testes de
CRDT, atomicidade e recuperação continuam separados. O piloto Saropa é R-34.

Toda execução consulta a rede, inclusive com dependências já em cache. O workflow
não restaura caches de dependências e nunca usa relatório antigo como resultado
atual. A resolução pode reutilizar downloads locais; o comando e a consulta
online de advisories continuam obrigatórios. Jobs semanais (segunda, 08:17 UTC),
push/PR e execução manual refazem os checks. Revisar mensalmente SDKs/actions,
dependências e exceções, mantendo versões/SHAs e evidências atualizados.

## Permissões, manutenção e evidências

Workflow usa somente contents:read, checkout sem persistir credenciais e actions
fixadas por SHA. Não há token de publicação, uploads, autofix ou escrita remota.
Actionlint tem release/checksum fixados e verificados antes da execução. Nenhum
serviço foi ativado ou workflow remoto acionado por preparar esses arquivos.

`scripts/ci.py` centraliza os comandos e a política, `scripts/tests/test_ci.py`
cobre controles negativos e a lista canônica evita omitir novos pacotes. As
fixtures usam nomes/advisories sintéticos e nunca adicionam pacote vulnerável
aos manifests. Falhas reais anteriores e correções constam no
[registro R-33](../plan/TRACEABILITY.md#execucao-r-33-2026-10-24).

Checks locais e execução remota devem ser registrados separadamente. Alterar o
YAML não comprova que GitHub Actions passou. A evidência local também não prova
rede física, execução Android ou publicação hosted.
