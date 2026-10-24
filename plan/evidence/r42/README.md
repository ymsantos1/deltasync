# Consulta explícita de campo — R-42

Execução de 2026-10-24 sobre `754c763d5a90bdc95b10cc55fcf36b929890b47b`,
com worktree inicial limpa. Entrega: `Replica.query`, `SyncEngine.query` e
`LocalBatch.query`, com `FieldQuery` sealed e três variantes final:
`AbsentField`, `PresentField` e `DeletedField`. O valor continua `Object?`;
o tipo do resultado distingue presença, não valida modelos do aplicativo.

## Contrato e manutenção

Somente endereço sem CRDT vinculado é ausente. LWW null é presente; tombstone
LWW é removido. Todos os outros sete tipos vinculados são presentes mesmo com
zero/coleção vazia; MV escrito com null tem valor `{null}`. Os resultados usam
os tipos de `valueAt`, inclusive coleções aninhadas somente leitura e isoladas.
`valueAt` preserva o retorno null para ausência, LWW null e tombstone.

`ReplicaState.kindAt/isDeletedAt` leem metadados canônicos sem copiar payload.
`Replica` centraliza o acesso ao valor em um percurso privado compartilhado com
`valueAt`, sem reconstrução completa da réplica ou cache de presença. O helper
de tombstone evita copiar vencedor/valor apenas para verificar um bool.
Variantes ficam em part da library de Replica para construtores privados e
switch exaustivo. Isso fecha os três estados válidos, sem framework de modelos.

Engine consulta o último estado adotado após start, inclusive durante espera
de commit/rede; falha de storage não expõe candidata. O editor consulta valores
provisórios apenas durante callback e expira antes de aguardar commit. Presença
e remoção não dependem de outbox/ACK. Não mudaram joins, mutações, commit,
restauração, formatos, adaptadores, SDK ou manifests. Subclasses externas devem
conferir eventual conflito com método próprio chamado query.

O [guia público](../../../docs/migracao-1.0.1.md#consulta-explícita-de-campo--r-42)
explica consumo e relação com R-40: converter apenas valor presente, inclusive
null legítimo; ausência/remoção seguem ramos próprios e erro de decoder deve ser
tratado pelo app. A conveniência de decoder não foi implementada nesta tarefa.

## Evidências por etapa

[validation.json](validation.json) registra leitura, review próprio após
correções, comandos, saídas reais, hashes e limites. A matriz aprovada contém
**291 testes**, por ordem raiz/core/sync/storage/SQLite/testing/transport:
16/128/73/14/40/10/10. Sete checks de formato sem alterações e sete análises
limpas. Testes focados anteriores repetem parte dessa matriz; não somar contagens.

- Core: oito tipos, sete estados vinculados vazios restaurados, LWW null,
  tombstone/ressurreição, valores aninhados, imutabilidade e estabilidade.
  Duas ordens de chegada de LWW concorrente e replay antigo preservam vencedor;
  leitura não altera snapshot/clocks. Guarda de teste impede consulta via cópia
  completa de state, fork ou snapshot numa réplica de 500 campos.
- Sync: lifecycle criado/inicializando/falha/retry/iniciado/descartado; consulta
  de candidata no editor versus estado adotado durante commit bloqueado;
  editor expirado e commit falho. Rede falha permite leitura/edição; ACK
  controlado esvazia outbox sem eliminar tombstone. Restauração em memória
  complementa, sem substituir, a prova durável.
- SQLite real: fechamento/reabertura com os oito tipos, null, tombstone,
  sete tipos vazios/zero e valores aninhados; nenhuma pendência inventada.
  Trigger aborta INSERT da outbox após tentativa de snapshot; engine e banco
  preservam null/snapshot/outbox anteriores. Reabre, remove após retry e
  reabre novamente com tombstone. SQL serve apenas à injeção de falha do teste;
  consultas usam contratos públicos.
- Facade: switch exaustivo sobre os três resultados pela engine/editor.
  [Consumidor externo](consumer_test.dart.txt), fora do workspace, passa dois
  testes e análise por imports públicos; compilação negativa impede construtor,
  implementação de FieldQuery e implementação de PresentField.
- [Inventários](consumer-validation.json): sete pacotes comparados com a revisão
  inicial pelo extrator canônico com suporte a parts. Adicionados apenas quatro
  tipos, query em Replica/SyncEngine/LocalBatch e ReplicaState.isDeletedAt.
  Nenhuma remoção/alteração de assinatura anterior ou mudança em adaptadores.
- [Exemplo](../../../example/field_query_example.dart) executa ausência, null,
  tombstone, PN zero e OR-Set vazio sem importar internos.

Falhas iniciais preservadas no relatório: fixture tentou editar snapshot
imutável, exemplo usou getter inexistente label e comparador do inventário não
considerou Dartdoc incluído pelo AST. Corrigidos Map.of, wireName e comparação
do sufixo da assinatura. Revisão posterior conferiu os deltas; validação final
passou. Nenhum desses erros exigiu mudar formatos ou regras dos CRDTs.

## Reprodução e limites

Na raiz, com dependências disponíveis no cache do SDK:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done
python3 -B plan/evidence/r42/validate_consumer.py --dart dart --report /tmp/r42-consumer.json
dart run example/field_query_example.dart
python3 scripts/check_plan.py
git diff --check
```

Review do próprio agente, não independente. Dart 3.13.5/Linux x86_64 e SQLite
FFI; sem SDK mínimo 3.12.x, Android novo, kill de processo ou rede física.
ACK controlado não comprova persistência remota. Consumidor usa path, não pacote
hosted. R-40 está pronta; fase 6/VAL-17 continuam abertos. Sem commit/publicação.
