# Decoder opcional — R-40

Execução de 2026-10-24 sobre `0e17a2a964b7adb8fcb0974dd6301e1168cfcc8d`,
com worktree inicial limpa. Entrega: `PresentField.decode<T>` na library de
Replica, exportado por core/facade. É uma conveniência opcional sobre o valor
isolado já retornado pela consulta; estado, consulta e lifecycle continuam R-42.

## Contrato e manutenção

O consumidor escolhe entre `field.value` bruto e
`field.decode(Model.fromValue)`. O callback tem tipo `T Function(Object?)`,
recebe o valor exatamente uma vez, inclusive null legítimo, e devolve T sem
alteração. T pode ser nullable; retorno null não transforma o campo em ausente.
Falhas propagam sem wrapping/default ou alteração do resultado de um commit.

AbsentField/DeletedField não oferecem decode: trate seus ramos por switch.
Assim, presença, LWW null, remoção e erro do modelo mantêm contratos distintos,
sem novo DTO ou generificação da hierarquia. O membro da variante presente
serve aos resultados de Replica, engine e editor sem repetir consulta nem
referenciar estado, storage ou transporte. Use o [guia de consumo](../../../docs/migracao-1.0.1.md#decoder-opcional-no-resultado-presente--r-40)
e o [exemplo tipado](../../../example/field_decoder_example.dart).

Entrada mantém isolamento profundo/read-only existente; modelo e mutabilidade
de saída pertencem ao app. O decoder pode copiar dados para um modelo mutável.
Um resultado retido pode ser convertido após edições, fechamento do editor ou
dispose; obter nova consulta continua sujeito ao lifecycle. Callback não deve
executar I/O/mutações externas; a biblioteca não desfaz efeitos capturados pelo
app. Erro que escapar de callback de lote segue seu rollback existente.

Regra nova vive apenas em PresentField.decode. Estado/delta/join permanecem
no core; candidata/commit/adoção/restauração permanecem em sync e persistência
nos adaptadores. Sem novas classes de produto, enum, schema, codegen, repositório,
cache, variantes ou formatos. `query`/`valueAt` mantêm assinaturas e comportamento.
Um membro de instância pode sombrear extension decode do consumidor; migração
documenta renomeação ou invocação explícita da extension.

## Evidências por etapa

[validation.json](validation.json) registra leitura, implementação, review próprio
após correções, comandos reais, saídas, hashes e limites. A matriz aprovada dos
pacotes afetados contém **225 testes**: facade 17, core 132, sync 76. Três checks
de formato sem mudanças e três análises limpas. Focados anteriores repetem parte
da matriz; não somar suas contagens ao total.

- Core: modelo válido, cópia mutável de saída sem alterar JSON de entrada,
  modelo incompatível, null legítimo/retorno nullable, ausência/remoção em ramos
  próprios e callback chamado uma vez. Erro do modelo, tentativa de mutação
  aninhada e exceção arbitrária propagam preservando snapshot/clocks. Os oito
  tipos usam o mesmo valor isolado; nested map/list/set permanecem protegidos.
- Sync: conversão/falhas não alteram snapshot ativo/persistido, clocks, outbox
  ou streams de commit/erro. Falha de rede preserva leitura e edição posterior.
  Query antes/durante start e após dispose rejeita antes de invocar decoder;
  resultado retido continua convertível. Decoder lê candidata no editor e erro
  que escapa do callback aborta lote sem estado/outbox parcial.
- Facade: switch público com ausência/null/modelo válido/inválido/remoção.
  [Consumidor externo](consumer_test.dart.txt), com resolução própria fora do
  workspace, passa dois testes e análise; modelo/erro tratado pertencem ao app.
- [Inventários](consumer-validation.json): sete pacotes comparados com HEAD
  inicial. Única adição: PresentField.decode em core/facade; nenhuma assinatura
  anterior modificada/removida, novo símbolo ou mudança em adaptadores. Prova
  negativa rejeita decode em AbsentField e DeletedField com undefined_method.
- Exemplo executado exibe missing/valid/null/deleted/invalid, captura erro de
  modelo e mantém acesso ao valor bruto inválido para o app.

Correções: lint de bloco if no modelo de teste; expectativa da fixture externa
era quatro pendências para três mutações confirmadas localmente. Corrigida para
três sem mudar produto; falha real preservada em validation.json. Deltas revistos
e checks finais aprovados. Guia complementado com precedência de membro sobre
extension do consumidor. Nenhum impeditivo restante; review não independente.

## Reprodução e limites

Na raiz, com dependências já disponíveis no cache do SDK:

```sh
for package in . packages/deltasync_core packages/deltasync_sync; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done
python3 -B plan/evidence/r40/validate_consumer.py --dart dart --report /tmp/r40-consumer.json
dart run example/field_decoder_example.dart
python3 scripts/check_plan.py
git diff --check
```

Dart 3.13.5/Linux x86_64; sem runtime SDK mínimo 3.12.x ou Android novo. Não
reexecutada durabilidade SQLite: não é critério de R-40, nem houve mudança de
storage/formato. Matriz limita-se a core/sync/facade; não é gate completo da
release. Inventário cobre os sete pacotes; consumidor usa path, não hosted.
R-41 recomendada e R-33 também pronta; fase 6/VAL-17 abertos. Sem commit/publicação.
