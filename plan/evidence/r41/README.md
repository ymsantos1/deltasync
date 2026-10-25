# Eventos seletivos e fonte comum — R-41

Execução de 2026-10-24 sobre `bc65f4a2658b75141953477c6281c12eebf11f07`,
com worktree inicial limpa. Entrega: `SyncCommitEvent.addresses`,
`SyncEngine.commitsFor(address)` e uma fonte assíncrona para observations,
commits e errors. Sem cache de estado/pendências ou sync disparado por listener.

## Contrato e manutenção

Endereços são inputs processados, não diferenças de valores visíveis. Replay,
escrita perdedora, tombstone e coleção vazia podem notificar. Um lote gera um
evento e deduplica seus endereços; delta remoto vazio pode gerar conjunto vazio.
Snapshot usa bindings do peer, incluindo os oito tipos e vazios/zero, excluindo
campos apenas locais. OR-Map informa endereço do CRDT, não chave interna.

Deltas usam DeltaChange.crdtId. Replica.mergeSnapshotJson retorna Set<String>
dos bindings do peer já restaurado, sem outro parse ou cópia de valores só
para metadados. SyncCommitEvent copia seu conjunto antes de aguardar storage;
o evento só é emitido após commit e adoção. Um controller broadcast assíncrono
de SyncObservation e `_emit` são a fonte comum; commits/errors filtram tipos e
commitsFor compara endereço exato. Todos preservam a mesma instância do evento.

Consulte query/valueAt para estado atual; evento atrasado não guarda valor
histórico. Sem replay: hidratação inicial é explícita. Ordem vale por
subscription, não entre execuções de listeners diferentes. Listeners não
governam commit; seus erros pertencem à Zone do consumidor. Falha de envio de
ACK após commit remoto não desfaz estado/evento. Push/ACK continuam distintos.

Pausa não impede commits, mas pode acumular eventos da fonte, inclusive aqueles
que o filtro descartará. Retome/cancele subscriptions pausadas antes de aguardar
dispose; fechamento aguarda done nos listeners ativos. Dispose drena trabalho
aceito antes de fechar a fonte e rejeita trabalho novo.

Quebras de fonte: SyncCommitEvent exige addresses e perde const; implementadores
adicionam getter e subclasses adaptam super/construtores. mergeSnapshotJson
retorna Set<String> em vez de void; implementadores/overrides adaptam retorno.
Chamadas que ignoram retorno continuam válidas. Nenhuma variante de
SyncObservation mudou; switches mantêm cinco casos e podem ler addresses no
padrão de commit. Ver [migração completa](../../../docs/migracao-1.0.1.md#eventos-seletivos-e-fonte-comum--r-41).

Estado/deltas/joins continuam no core; candidata/commit/adoção na engine;
persistência/ACK em seus contratos existentes. JSON/schema/SDK/versões não mudam.
Não há nova classe de produto, framework de listeners ou parser paralelo.

## Evidências por etapa

[validation.json](validation.json) registra leitura, implementação, review próprio
após correções, comandos reais, saídas e hashes. Matriz: **309 testes**, por
ordem facade/core/sync/storage/SQLite/testing/transport: 18/134/83/14/40/10/10.
Sete formatos sem mudanças e sete análises limpas. Focados de core/sync repetem
parte da matriz; não somar contagens.

- Core: merge retorna bindings dos oito tipos com vazios/zero/tombstone, exclui
  local-only, mantém conjunto isolado/read-only e semântica no replay. Snapshot
  inválido não retorna sucesso nem altera estado/clocks.
- Sync: lote dos oito tipos, deduplicação, identidade entre canais e filtro;
  replay/perdedor LWW, delta vazio e snapshot com CRDT vazio/tombstone. Consulta
  durante commit bloqueado permanece anterior; listener observa adoção. Falhas
  local/remota/snapshot não emitem sucesso. Metadata resiste a mutações posteriores.
- ACK: erro no storage preserva pendências e gera SyncPushFailure; retry parcial
  não gera outro commit. Falha de envio de ACK remoto preserva commit; replay
  via incoming emite commit seguido de SyncFailure comum a errors/observations.
  Erro de stream preserva identidade e fonte da falha. São ACKs controlados.
- Listeners: tardio sem replay, filtro seletivo pausado/com erro, ordem de
  commits concorrentes, errors pausado que descarta eventos não selecionados,
  resume/done, dispose aguardando pause e drenando commit aceito bloqueado.
  Não há garantia de valor histórico nem prioridade entre listeners.
- Facade: seleção por endereço e conjunto imutável; fixture de caminhos
  históricos mantém identidade de tipos com construtor/implementação migrados.
- [Consumidor externo](consumer_test.dart.txt): dois testes com filtro, leitura
  pontual/decoder, nenhum envio automático, hidratação inicial, construtor e
  implementação externos migrados. Switch exaustivo mantém cinco variantes.
- [Inventários](consumer-validation.json): sete pacotes, sem símbolos/variantes
  novos; somente commitsFor, addresses/construtor e retorno de mergeSnapshotJson
  alterados. Prova negativa exige erro no construtor const antigo, falta de
  addresses em implementação externa e override void antigo.
- [Exemplo executável](../../../example/selective_observation_example.dart):
  inicial ausente, uma atualização para Ada e três pendências locais sem push.

Revisão identificou lacuna de cobertura de errors pausado após unificação:
adicionado teste e revalidado. Eventos passaram a ser preparados antes do I/O,
removendo cópia intermediária de endereços remotos. Deltas revistos após correções;
dez testes focados e matriz final aprovados. Nenhuma falha de teste foi ocultada
ou convertida em sucesso. Correções operacionais de cache/format constam no JSON.
Review do próprio agente não é independente.

## Reprodução e limites

Na raiz, com dependências disponíveis no cache do SDK:

```sh
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart format --output=none --set-exit-if-changed lib test && dart analyze && dart test --reporter expanded) || exit 1
done
python3 -B plan/evidence/r41/validate_consumer.py --dart dart --report /tmp/r41-consumer.json
dart run example/selective_observation_example.dart
python3 scripts/check_plan.py
git diff --check
```

Dart 3.13.5/Linux x86_64 e SQLite FFI real nas suítes existentes; sem SDK mínimo
3.12.x ou Android novo. Não é prova de rede física/ACK remoto real. Consumidor
usa path/resolução própria offline, não hosted. R-33 é próxima; fase 6/VAL-17
continuam abertos. Sem Compass, commit ou publicação.
