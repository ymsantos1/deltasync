# VAL-17 — Gate final 1.0.1

Execução em 2026-10-25, sobre HEAD limpo
`0d68d9b9919579335f52ba886e149d7b2b5ff01d`. Um agente executou leitura,
implementação do harness, revisão própria, validação e manutenção em etapas
distintas. A revisão não é independente. Não houve alteração de fontes de lib,
API, formatos, manifests, SDK, dependências ou código do aplicativo neste gate.

## Resultado e proveniência

Os sete critérios de [VAL-17](../../06_PHASE6_MANUTENCAO_1_0_1.md#val-17)
foram demonstrados. [Validação](validation.json), [artefatos](artifacts.json),
[Android](android.json), [resoluções](resolution.json),
[inventário](inventory.json) e [preservação de fontes](source.json) registram
resultados atuais. R-28/R-30/R-36 e demais evidências anteriores ficaram intactas.

| Critério | Evidência atual e alcance |
|---|---|
| C1 — workspace e invariantes | Sete pacotes com formato/análise aprovados e 312 testes: facade 21, core 134, sync 83, storage 14, SQLite 40, storage_testing 10, transport 10. Histórias dos oito tipos, oito seeds e quatro permutações por seed; falhas, concorrência, ACK parcial/perdido e recuperação SQLite integram essas suítes. |
| C2 — dados anteriores e writer | Fixture 1.0.0 lida pelo consumidor atual; 14 testes da revisão histórica também passaram. Três processos SQLite seed/upgrade/verify executaram writer 1.0.1 e reader 1.0.0 no mesmo banco. Snapshot v9, 45 pendências após duas novas mudanças e três ACKs, 23 payloads do outro peer preservados. |
| C3 — fonte e adaptadores | Consumidor hosted fora do workspace, sem paths/overrides, executou 54 testes. Adaptador migrou pendingSummary pelo contrato público. Quatorze usos retirados falham nas linhas esperadas; probes adicionais conferem construtor/const/interface de evento e override de mergeSnapshotJson. Guia mostra substitutos. |
| C4 — APIs novas e legado | Fixtures externas de R-37/R-38/R-40/R-41/R-42, suíte compartilhada do adaptador e testes de lote/consulta/decoder/eventos/restauração passaram. Trigger SQLite da fixture geral injeta falha depois de escrita parcial e verifica rollback. Revisão de exports/call sites confirma Operation restrita aos readers internos; fluxo de escrita usa mudanças nativas. |
| C5 — distribuição | Sete candidatos 1.0.1: 85 arquivos preparados, incluindo sete .pubignore; 78 arquivos servidos e 48 fontes de lib. Hashes dos arquivos instalados coincidem com o inventário. Sete dry-runs terminaram com zero warnings; registro local recebeu somente GET e nenhum upload. |
| C6 — exemplos e plataforma | Cinco exemplos Dart, CLI reset/offline/reconnect em processos separados, exemplo commit/status durável e dois testes do enlace passaram. Flutter: formato/análise, sete testes e APKs main/main_eight. Runtime atual no Moto G52 Android 13 confirmou commit offline, reinício, nova edição, reconexão, ACK e novo reinício usando sqflite nativo. |
| C7 — entrega e manutenção | Jobs locais atuais, OSV online sem findings, 11 testes de política, actionlint 1.7.7, decisão Saropa DEC-68 preservada, riscos/índice/fase/trace atualizados e check_plan/diff conferidos. Instruções de publicação manual abaixo. |

## Ambiente e comandos do host

Dart 3.13.5, Flutter 3.47.7 stable, Linux x64. A família mínima dos manifests
é `^3.13.0`, conforme R-33/DEC-67. O patch efetivamente executado é 3.13.5;
não houve execução 3.13.0 ou 3.12. Diretivas `// @dart=3.12` das fixtures
congeladas indicam versão de linguagem, não um SDK 3.12 usado nesta validação.

Dois checkouts temporários de HEAD e caches Pub inicialmente novos/separados
executaram o runner vigente, com `PUB_CACHE` específico por job:

```sh
python3 -B scripts/ci.py dart
python3 -B scripts/ci.py flutter
python3 -B scripts/ci.py policy
/tmp/deltasync-r33-actionlint/actionlint .github/workflows/ci.yml
```

Os jobs Dart/Flutter terminaram com exit 0 em 74.074 s/92.097 s, respectivamente.
São medidas locais, não SLA. A resolução Dart nova usou test 1.33.0,
analyzer 14.6.0 e sqlite3 3.8.0. Flutter usou seu lockfile e grafo próprio.
Consultas OSV atuais cobriram 60 pacotes hosted Dart e 46 Flutter, sem findings;
os controles negativos de política usam advisory fictício e devem falhar.
Isso não prova ausência de vulnerabilidades desconhecidas. O workflow remoto
não foi disparado. Saropa permanente continua adiado; não houve novo piloto,
baseline, downgrade ou instalação de lint no runtime.

As fontes Dart, manifests e scripts/CI dos clones coincidem com a entrega.
README/publicação só receberam redação condicional do gate. O candidato novo
inclui o README atual; o candidato histórico R-36 não foi sobrescrito.

## Consumidor e migração reproduzíveis

Preparação e harness desta execução:

```sh
python3 -B scripts/prepare_release.py
python3 -B plan/evidence/val17/validate_artifacts.py \
  --release /tmp/deltasync-release-parent-r8mpulxa/release \
  --report /tmp/deltasync-val17-artifacts.json
```

O destino de preparação é temporário/novo. Para repetir, use o caminho retornado
pelo preparador, não sobrescreva o inventário anterior. O harness liga um Pub
loopback somente leitura, serve os sete arquivos com SHA-256 e consulta metadata
externa no pub.dev; archives externos mantêm URLs públicas. Ele encerra o servidor
ao terminar, inclusive em falha. Os 54 testes rodam contra pacotes instalados no
cache hosted, não fontes do checkout. Os dry-runs incluem dependências de
desenvolvimento e não enviam pacotes. A resposta 405 impede POST no registro.

O consumidor reutiliza a fixture geral R-28, o adaptador R-39 atualizado com
pendingSummary e fixtures públicas R-37/R-38/R-40/R-41/R-42. Copia e compila
também o trecho importPending do guia atual. Fontes congeladas permanecem sem
edição; somente suas cópias temporárias recebem versões, delegação e formatter.
Erros de compilação dos probes retirados são esperados, com exit 3; não são
falhas ignoradas da suíte positiva. As saídas estão em artifacts.json.

Extração histórica: `python3 -B plan/evidence/r30/capture.py --dart dart --prepare-only`,
sem `--freeze`, revisão `1e969182e8e172a8858a48ecf83a1feb2c21a455`.
Executado `dart test <historicalConsumer> --reporter expanded` com
`R30_EXPECT_SOURCE=<historicalSourceDirectory>`. O arquivo congelado
`plan/evidence/r39/rollback.dart.txt` rodou, como rollback.dart, nos modos:

```sh
dart run rollback.dart seed <banco> <fixture_1_0_0.json>
dart run rollback.dart upgrade <banco> <fixture_1_0_0.json>
dart run rollback.dart verify <banco> <fixture_1_0_0.json>
```

Seed/verify usaram resolução histórica; upgrade usou os pacotes hosted atuais.
São três processos e o mesmo SQLite fechado entre etapas. Comandos, diretórios,
variáveis de proveniência e resultados estão nos relatórios e no harness.

## Android atual: roteiro e limites

Runtime foi necessário: o diff desde R-30 afeta lote, fila, eventos e lifecycle,
apesar de VAL-17 não mudar código. Autor conectou e autorizou o aparelho.
Foi atualizado somente `com.example.deltasync_mobile_consumer` com `adb install -r`,
após backup dos bancos; nenhum clear/uninstall ou edição no Compass.
Um build adicional de main.dart repôs o APK sobrescrito pelo build main_eight
do job. SHA-256 do APK instalado:
`52feb5b84176398326f8947bb5489d525972e098bb41aa623eac2d4919f5c765`.

1. Com peer indisponível, editar título e incrementar contador em A e B; provocar
   falha de envio e concluir nova edição A. Esperar status de commit local.
2. Encerrar processo, confirmar ausência de PID e copiar bancos fechados via
   `adb exec-out run-as com.example.deltasync_mobile_consumer tar -cf - databases`.
   Abrir novamente; conferir mesmas três pendências A/duas B e estado exato.
3. Encerrar/reabrir e concluir nova edição A: ID `shopper-a:delta:12`, distinto
   dos IDs restaurados, com quatro pendências A/duas B antes do envio.
4. Ativar peer e enviar. Log do PID 23257 registra Envio concluído, ambos os
   títulos `VAL17_161926_A_restored`, contador 8 e zero pendências.
5. Encerrar/reabrir novamente e aguardar `VAL08 restored` do novo PID 27656.
   Confirmar títulos/contador/outboxes e encerrar antes da última cópia SQLite.

Inspeção das cópias fechadas, sem escrever no aparelho:

```sh
python3 -B plan/evidence/val17/inspect_android.py \
  --directory /tmp/deltasync-val17-mobile \
  --report /tmp/deltasync-val17-mobile/proof.json
```

Estado/outbox anteriores ao ACK são idênticos após restauração. Os snapshots
finais A/B têm mesmo winner completo e componentes de contador 4+4; outboxes
vazias e estado final idêntico após o último reinício. Schema SQLite v1,
snapshot interno v9. O banco eight-alpha preexistente conserva hash exato.
App ficou encerrado; XML temporário removido, bancos/backups preservados.

Esta prova usa duas réplicas no mesmo processo e enlace simulado, com dois CRDTs
na plataforma nativa. Os oito tipos e falhas de lote/ACK são cobertos pelos testes
atuais de host; não se afirma execução dos oito no aparelho, rede real,
autenticação/TLS, iOS ou usabilidade com participantes. Isso exercita o pipeline
comum e o plugin real sem criar framework de integração para o gate.
APKs, bancos, XML e logcat bruto permanecem em /tmp; só hashes, checkpoints e
dados técnicos da demo constam no registro versionável.

## Correções do harness e revisão

Primeira passagem hosted falhou no controle de proveniência: faltava
R37_EXPECT_SOURCE. Após incluir o caminho instalado, todos os 54 testes e os sete
dry-runs passaram em cache/consumidor novos. A falha anterior tem hash registrado.

No roteiro Android, uma edição foi encerrada antes da confirmação de commit;
não foi contada como salva. O harness passou a esperar o status. O dump UI também
passou a remover seu XML anterior e validar a resposta antes de ler. O primeiro
reinício final não confirmou startup pelo PID atual; a prova definitiva usa novo
processo e checkpoint de restauração. A inspeção foi corrigida para atravessar
o envelope versionado de DeltaCodec antes do lote. Repetidos os passos afetados;
expectativas não foram relaxadas e nenhuma falha da lib foi confirmada.

Revisão própria distinta incluiu arquivos novos, correções e resultados, fontes
dos readers, hashes/exports, ausência de upload e limites das alegações. Não há
achado impeditivo restante. Testes aprovados não tornam essa revisão independente.

## Publicação manual pelo autor

Candidatos aprovados: `/tmp/deltasync-release-parent-r8mpulxa/release`.
Conferir seus hashes com inventory.json antes do envio. Diretórios temporários
podem desaparecer; uma nova preparação exige comparar hashes e repetir checks
afetados. Mudanças de fonte invalidam a aprovação daqueles artefatos.

O autor revisa/commita/integra a entrega e disponibiliza os links de documentação
em main antes de publicar. Este gate não executou esses passos. Ver
[publicação](../../../docs/publicacao.md) e [migração](../../../docs/migracao-1.0.1.md).

Ordem: core; storage e transport; sync e storage_testing; storage_sqflite; facade.
Em cada diretório preparado, retirar PUB_HOSTED_URL de teste, usar o registro
público, executar `dart pub get` e `dart pub publish --dry-run`. Após revisar
arquivos/versão/propriedade/autenticação, somente o autor executa
`dart pub publish`. Esperar cada dependência 1.0.1 ficar disponível publicamente
antes de validar/publicar dependentes; não reduzir constraints. Depois dos sete
envios, validar instalação em consumidor novo do pub.dev sem paths/overrides.

1.0.1 contém quebras de fonte deliberadas; não é patch compatível pela convenção
SemVer. Dados/readers/schema foram preservados. O registro local e os dry-runs
aprovam estes candidatos, sem comprovar disponibilidade, autorização dos nomes,
checks extras do servidor ou instalação pública. Não houve upload, commit, tag,
merge, push ou tarefa subsequente executada.
