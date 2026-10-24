# Migração de fonte e dados para 1.0.1

A consolidação planejada para 1.0.1 remove APIs públicas. Por escolha expressa
do autor, esse número inclui quebras normalmente reservadas a uma versão major.
Não considere o upgrade compatível apenas pelo número. Os manifests ainda serão
ajustados em R-36; esta mudança não publica nem renumera pacotes ou dados.

## Substituições de fonte

| Antes | Depois | Adaptação |
|---|---|---|
| `PendingDeltaStore`, `MemoryPendingDeltaStore` | `ReplicaStorage`, `MemoryStorage` ou SQLite | Snapshot e outbox devem participar do mesmo commit; memória continua volátil |
| `SyncEngine(store: ...)`, `engine.store` | `SyncEngine.withStorage(storage: ...)`, `engine.storage` | Storage é obrigatório e não nullable; construtor sem nome também aceita `storage:` obrigatório |
| `Replica.set/remove`, `SyncEngine.set/remove` | `setDelta/removeDelta` | Engine retorna Future; aguarde commit local antes de indicar sucesso |
| `Delta.crdt(changes)` | `Delta(changes)` | Lote de mudanças nativas |
| `delta.crdtChanges` | `delta.changes` | Mesma ordem e conteúdo |
| `entry.operationId` | `entry.entryId` ou `entry.changeIds` | ID singular ou coleção, sem gerar outro ID |
| `Operation`, `migrateLegacyOperation` exportados | Métodos nativos e `DeltaCodec.decode` para registros históricos versionados | Não importar `src`; o DTO/conversor histórico são detalhes internos |

`DeltaChange`, `ReplicaStorage` e os contratos de transporte continuam
implementáveis pelos consumidores. Seus membros não mudaram nesta tarefa.
Adaptadores de storage devem implementar `loadReplica`, `saveReplica`, `commit`,
`commitRemote`, `enqueue`, `pending`, `markSent` e `acknowledge`. Execute a suíte
de `deltasync_storage_testing`, além de provas de rollback/reabertura no seu banco.
O [consumidor migrado](../plan/evidence/r39/consumer_test.dart.txt) implementa os
contratos públicos por composição, sem herdar ou importar implementação interna.

## Migração do antigo pending store

Antes de atualizar o código, interrompa novas edições e envios e aguarde operações
em andamento. Ainda com a biblioteca antiga, exporte `await store.read(replicaId)`
com `DeltaCodec.encode`, além de um checkpoint completo obtido por
`replica.toSnapshotJson()`. Preserve réplica, IDs e clocks originais. O store
antigo guarda somente pendências: sozinho não recupera dados já confirmados ou
remotos. Se não houver checkpoint completo, obtenha um bootstrap confiável antes
de migrar. Não considere um delta pendente um backup de toda a réplica.

Escolha explicitamente o peer de destino; o store antigo não o registrava.
Valide o export pelo codec versionado, restaure o checkpoint, aplique pendências
e crie uma `OutboxEntry` por mudança, sem reemitir mutações ou gerar IDs novos.
Os antigos stores não tinham tentativas persistidas; as entradas importadas
começam `pending`. Não derive peer ou clocks de suposições sobre o aplicativo.

Exemplo de função pertencente ao consumidor, para um destino ainda vazio:

```dart
Future<void> importPending({
  required ReplicaStorage target,
  required Map<String, Object?> checkpoint,
  required Map<String, Object?> encodedPending,
  required String recipientPeerId,
}) async {
  final candidate = Replica.fromSnapshotJson(checkpoint);
  final pending = DeltaCodec.decode(encodedPending);
  if (pending.changes.any((change) => change.replicaId != candidate.id)) {
    throw FormatException('Pending batch belongs to another replica');
  }
  if (await target.loadReplica(candidate.id) != null ||
      (await target.pending(candidate.id)).isNotEmpty) {
    throw StateError('Import target must be empty');
  }
  candidate.apply(pending);
  await target.commit(ReplicaSnapshot.fromReplica(candidate), [
    for (final change in pending.changes)
      OutboxEntry(delta: Delta([change]), recipientPeerId: recipientPeerId),
  ]);
}
```

O chamador garante exclusividade durante essa importação; consulta seguida de
commit não implementa exclusão entre processos. No destino persistente, feche e
reabra o banco, restaure pela engine e confira valores, metadados e IDs antes de
trocar o aplicativo. Preserve export, checkpoint e origem até verificar o novo
fluxo. Uma falha de importação não autoriza apagar ou confirmar a origem.
`MemoryStorage` serve para testes/sessões voláteis; não comprova migração durável.

O importador é uma operação de manutenção da aplicação. Não há novo framework
de migração nem adaptação automática de regras de negócio na biblioteca.
Ao migrar um backend que já implementa `ReplicaStorage`, mantenha o banco e use
os readers existentes; não execute esse importador sobre dados já presentes.

## Formatos, restauração e manutenção

R-39 mantém DeltaCodec v4, snapshot interno v9, ReplicaSnapshot/outbox/envelope
v2 e SQLite schema v1. Os readers anteriores continuam disponíveis: codec v1/v2
com migração explícita e v3/v4; snapshots internos v1 a v9; storage v1/v2;
outbox/envelope v1 com peer/destinatário explícito e v2. Continuam rejeitando
payload inválido, destino ausente e identidade conflitante.

`ReplicaSnapshot.legacy` e `OutboxStatus.confirmed` permanecem depreciados para
compatibilidade de dados/adaptadores. Não são outro caminho operacional de sync.
O writer de snapshot continua canônico; converta um wrapper antigo por restauração
antes de escrever. ACK continua removendo somente IDs confirmados pelo peer.
Nenhum join, tombstone, contexto causal ou dado persistido foi descartado.

| Regra | Ponto de manutenção |
|---|---|
| DTO e conversão de operação antiga | Core, `src/operation.dart`, usado somente pelos readers de delta e snapshot |
| Seleção da versão do delta | Core, `DeltaCodec`; `Delta.fromJson` valida/converte payload |
| Estado, mutação, delta e join dos oito tipos | Core, `Replica` e cada CRDT; não mudaram com a remoção das APIs |
| Candidata, commit e adoção | Sync, `SyncEngine` e `ReplicaPersistence`; agora um caminho obrigatório de storage |
| Snapshot/outbox e transação | Contrato `ReplicaStorage`; implementação no backend escolhido |
| Restauração de wrapper antigo | Sync, `ReplicaPersistence`, e readers públicos de storage/core |
| Seleção por peer, tentativas e ACK | `OutboundSync` e `ReplicaStorage`; envio fora da fila de commits |

Não copie o parser histórico para o aplicativo. A remoção do export não altera
o reader usado por `DeltaCodec` ou `Replica.fromSnapshotJson`.

## Rollback

Antes do upgrade, feche conexões e preserve um backup consistente do backend,
incluindo seu procedimento para WAL. Arquive código, versões, checkpoint e
exports. Não copie apenas o arquivo principal de um SQLite em uso.

A referência 1.0.0 fixada em R-30 lê os mesmos formatos desta tarefa. A prova
executa três processos sobre o mesmo SQLite: biblioteca antiga grava; atual
restaura, edita e recebe ACK parcial; antiga reabre e verifica dados novos,
45 pendências e isolamento das 23 entradas do outro peer. Isso valida rollback
de biblioteca para essa revisão, sem restaurar um backup que apagaria edições.

Pare e feche a instância atual antes de voltar ao código anterior. Recompile o
consumidor para a API escolhida e mantenha a mesma identidade e banco. Nunca
execute simultaneamente versões com a mesma identidade de réplica. Aplicativos
que usavam somente `PendingDeltaStore` precisam manter o adaptador `ReplicaStorage`
na versão de rollback ou exportar também o estado novo e suas pendências. Voltar
apenas ao store antigo não transporta automaticamente dados gravados no SQLite.

Leitores anteriores a essa referência podem não entender formatos causais mais
recentes, como o contexto MV compacto. Nenhuma garantia adicional de downgrade
foi introduzida. Outras tarefas desta release ainda exigem VAL-17 antes da
distribuição; R-39 não certifica antecipadamente seus formatos ou artefatos.

## Prova reproduzível

Na raiz, com dependências do SDK de referência disponíveis no cache:

```sh
python3 plan/evidence/r39/validate.py --dart dart --report /tmp/r39-validation.json
```

O script preserva os fontes/dados congelados de R-30, testa o consumidor antigo
com sua revisão, exige falha de compilação das APIs removidas na árvore atual,
analisa/testa o consumidor migrado fora do workspace e verifica rollback SQLite.
Compara também os sete inventários de API com uma lista explícita de remoções.
Usa dependências por path e resolução offline própria; não prova publicação
hosted, execução Android ou SDK mínimo. As evidências e limites reais da execução
ficam no [registro R-39](../plan/TRACEABILITY.md#execucao-r-39-2026-10-24).
