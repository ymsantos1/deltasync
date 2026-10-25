# R-35 — Guia durável e consumo público

R-35 reorganiza o percurso de integração sem alterar código de produção da
biblioteca, APIs, formatos, manifests ou SDK. A revisão inicial limpa foi
`9fc0f68629e794c962fb9a74e163d8ebe27da27f`. Execução em 25/10/2026 com Dart
3.13.5, Linux x64 e SQLite FFI; cinco etapas no
[registro](../../TRACEABILITY.md#execucao-r-35-2026-10-25).

## Resultado para quem integra e mantém

- README passa de 805 a 195 linhas e abre com composição SQLite durável. As 17
  âncoras anteriores permanecem. Não se promete compatibilidade pela versão patch.
- [Guia](../../../docs/guia-integracao.md) explica identidade/endereço, mutação,
  consulta/decoder, lote, eventos seletivos, status/ACK, retry de abertura,
  ownership e encerramento. Suas nove âncoras anteriores permanecem.
- [Referência](../../../docs/referencia-tecnica.md) localiza os oito CRDTs,
  estado/mutação/delta/join, codecs, commit/restauração, SQL e testes pertinentes.
  Modelo/negócio e adaptadores de rede permanecem no consumidor, sem plugin
  genérico, schema de domínio ou alteração específica para Compass.
- [Medições](../../../docs/medicoes.md) conserva literalmente os resultados
  históricos e a comparação Compass, ajustando somente caminhos de links quando
  necessário. Nenhuma medição antiga foi reapresentada como execução nova.
- [Exemplo novo](../../../example/commit_status_example.dart) reutiliza o decoder
  anterior e separa sucesso local de falhas posteriores. A CLI offline usa
  consulta pontual e resumo leve; outbox vazia não é tratada como prova de ACK.
  CI executa o exemplo novo em diretório temporário, sem publicar/ativar serviço.

O exemplo aceita JSON bruto deliberadamente para demonstrar erro de modelo após
commit. Em um app real, validar edições locais antes de gravar e dados remotos
ao consultar. Listeners e UI não desfazem commit nem decidem regras do core.

## Provas proporcionais

A [fixture de integração](../../../test/integration_guide_test.dart) usa somente
imports públicos e SQLite real. A subclasse de teste sobrescreve métodos públicos
do adaptador para injetar falhas; não importa src nem sugere substituir internos
no aplicativo. Ela verifica:

1. Commit concluído seguido de falha de pendingSummary: continua salvo, emite um
   evento seletivo, preserva outbox e não lê payload para contar. Falha de push
   conserva IDs; fechar/reabrir o banco restaura modelo e entrada sent; nova
   edição continua possível.
2. JSON estruturalmente válido com modelo inválido: decoder apresenta erro
   separado, sem transformar presença em ausência nem desfazer snapshot/outbox.
   O payload inválido exato continua no snapshot salvo.
3. Falha do próprio commit: apenas mensagem de falha de gravação, sem consulta
   de status nem candidata visível/entrada nova. Essa injeção ocorre antes da
   transação; não é apresentada como nova prova de rollback SQL após writes.

Esses três casos integram os **21 testes da facade**. Após a revisão/correção,
passaram os sete pacotes: **312 testes** (21/134/83/14/40/10/10), mais dois testes
do enlace e 11 da política CI. Formato/análise dos sete pacotes aprovados.
Nenhum teste é somado novamente por ter sido executado na checagem preliminar.

Cinco exemplos existentes passaram. A CLI offline executou reset/offline/reconnect
em três processos e confirmou outbox/convergência após reabrir os bancos.
O exemplo novo executou em dois processos com o mesmo diretório: segunda abertura
restaurou Profile e contou duas mudanças ainda sem ACK. O
[probe](readme_probe.dart.txt) executou o **bloco Dart real do README**, com um
transporte offline fornecido pelo chamador, e confirmou snapshot/IDs distintos
após duas chamadas e reabertura SQLite. Isso não comprova runtime Android/iOS.

## Reprodução e registros

Na raiz, com Dart 3.13.5 e a resolução do workspace disponível:

```sh
dart format --output=none --set-exit-if-changed lib test
dart analyze
dart test --reporter expanded
dart test example/support/peer_link_test.dart --reporter expanded
python3 -B -m unittest discover -s scripts/tests -v
python3 scripts/check_plan.py
git diff --check
```

Repita formato/análise/testes em cada subpacote; comandos/diretórios exatos,
versões resolvidas, saídas resumidas e hashes dos logs brutos estão em
[validation.json](validation.json). A resolução usada já existia: não houve
consulta OSV nova, instalação limpa, build Flutter ou execução remota de CI
nesta tarefa. Os comandos do CI existentes continuam cobrindo esses contextos.
Os exemplos completos exigem checkout do repositório, não somente o pacote pub.

Para executar a CLI nova, passe diretório próprio a
`dart run example/commit_status_example.dart <diretorio>`. Repetir no mesmo
diretório demonstra restauração e uma nova edição com novo ID. Ela mantém o peer
offline de propósito. Para a CLI antiga, use diretório separado nos três comandos
descritos no guia; reset apaga os bancos dessa demonstração.

O probe contém o snippet do README seguido de um harness; copie-o para um arquivo
Dart temporário e use `dart run --packages=.dart_tool/package_config.json <arquivo>`.
Ele cria/remove apenas seu próprio diretório temporário. Hashes de
`sourceSha256` ligam a validação aos documentos/fontes entregues. Logs originais
ficam em /tmp; saídas no JSON normalizam o diretório runtime para `{runtime}`.
Hashes brutos referem-se aos bytes anteriores à normalização, não ao excerpt.

[documentation.json](documentation.json) registra âncoras anteriores,
comparações históricas e 49 links GitHub do próprio projeto resolvidos contra
arquivos/âncoras locais. Isso valida os destinos preparados, sem alegar que já
foram publicados em main. Publicação e renumeração não pertencem à R-35.

Revisão feita pelo próprio implementador em etapa distinta, **não independente**.
Correções foram revistas antes dos checks finais. R-36 é a próxima tarefa;
VAL-17 permanece aberto para o gate completo da release.
