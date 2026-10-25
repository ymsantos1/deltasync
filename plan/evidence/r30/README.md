# Baseline e mapa de migração — R-30

Esta evidência fixa o estado anterior às mudanças da release 1.0.1.
Não implementa APIs futuras nem corrige a outbox; esses trabalhos pertencem
às tarefas seguintes da [fase 6](../../06_PHASE6_MANUTENCAO_1_0_1.md#r-30).

## Revisões e proveniência

- Baseline histórica 1.0.0: `1e969182e8e172a8858a48ecf83a1feb2c21a455`.
- Árvore atual antes de R-30: `400161283e741d62dddf01cfc314629968a93828`.
  Seus sete manifests declaram 2.0.0; o alvo autorizado continua 1.0.1.
- Os 47 arquivos Dart de `lib/` dos sete pacotes têm conteúdo SHA-256 idêntico
  nas duas revisões. Os exports e as assinaturas declaradas também coincidem.
  Divergem metadados de versão/documentação; isso não renumera os dados.
- [baseline.json](baseline.json) registra hashes, versões por pacote, SDK,
  resolução offline histórica e checks do consumidor com origem verificada.
  Nenhum manifesto ou fonte de produção foi alterado por esta tarefa.

`capture.py` exporta a revisão histórica pelo Git e executa `dart pub get
--offline` no diretório temporário. O gerador de dados usa exclusivamente o
package_config dessa árvore 1.0.0; expectativas não são produzidas com o writer
da versão que estará sendo testada. O teste de proveniência verifica o caminho
real do import da facade nos dois consumidores.

## Arquivos e execução

| Arquivo | Uso |
|---|---|
| [api_1_0_0.json](api_1_0_0.json) | Inventário congelado das sete superfícies exportadas |
| [fixture_1_0_0.json](fixture_1_0_0.json) | Snapshot, 46 entradas para dois peers, 23 mudanças locais, envelope e ACK |
| [fixture.dart.txt](fixture.dart.txt) | Gerador histórico, executado somente com fontes 1.0.0 |
| [consumer_test.dart.txt](consumer_test.dart.txt) | Consumidor independente e implementadores de contratos públicos |
| [capture.py](capture.py) | Exportação, resolução offline, hashes, comparação e materialização das fixtures |
| [api_inventory.dart](api_inventory.dart) | Extração AST dos exports e assinaturas declaradas |
| [measure_outbox.dart](measure_outbox.dart) | Cargas fixas, sem outra implementação de join |
| [outbox_baseline.json](outbox_baseline.json) | Amostras antes de R-31; sem limiar temporal de teste |
| [validation.json](validation.json) | Resultados reais do workspace, análise, formato e guardas |

Reexecutar a conferência de R-30 enquanto as fontes ainda coincidem:

```sh
python3 plan/evidence/r30/capture.py --dart dart --test-consumers --report /tmp/r30-recheck.json
```

Após mudanças de produto, preparar apenas a referência antiga e conferir os
consumidores, sem sobrescrever a baseline:

```sh
python3 plan/evidence/r30/capture.py --dart dart --prepare-only --test-consumers > /tmp/r30-consumers.json
```

Esse segundo comando deve continuar passando antes das quebras. Após remover
APIs em R-39 ou mudar um contrato, é esperado que o consumidor antigo não
compile contra fontes novas: conservar a fixture histórica e acrescentar seu
par migrado. Não esconder a quebra regenerando os dados antigos ou apagando
asserts. A VAL-17 compara os consumidores antes/depois e os mesmos dados.

Os fontes `.dart.txt` são copiados para diretórios temporários e compilados
explicitamente; `@dart=3.12` fixa a versão de linguagem mesmo fora do workspace.
APIs antigas não ficam sob análise recursiva como código atual.
O teste do consumidor registra o caminho dos imports e inclui 8 checks da suíte
pública de contrato, dados congelados, readers legados, aliases e SQLite FFI.
Fechar/reabrir SQLite comprova esse percurso; não equivale a kill de processo,
rede real, publicação ou execução Android. O transporte de teste fornece ACK
controlado; não representa persistência remota real.

`--freeze` só cria arquivos ainda ausentes. Não utilizá-lo para atualizar a
fixture durante migrações. Os temporários são descartáveis; os JSON/fontes desta
pasta e o objeto Git histórico permitem repetir a prova em outro checkout com
as dependências disponíveis. Cache offline ausente exige resolução normal
autorizada antes da repetição, sem interpretar falha de cache como sucesso.

## Inventário público e pontos de extensão

O extrator segue exports transitivos e respeita `show`/`hide`; imports internos
não se tornam API exportada. Captura classes, interfaces, enums, construtores,
campos, getters/setters, operadores e funções públicas declaradas. Herança e
interfaces estão nos cabeçalhos; membros implícitos do SDK/inherited não são
duplicados. Export condicional ou declaração sem tratamento causa falha explícita.
É um inventário sintático revisável, não uma prova automática de compatibilidade.

| Pacote | Símbolos declarados alcançados pelo entry point |
|---|---:|
| deltasync | 62 |
| deltasync_core | 38 |
| deltasync_storage | 7 |
| deltasync_transport | 6 |
| deltasync_sync | 11 |
| deltasync_storage_sqflite | 1 |
| deltasync_storage_testing | 2 |

A facade reexporta core/storage/transport/sync; não exporta os dois adaptadores
de teste/SQLite. O contrato externo de storage tem loadReplica, commit,
commitRemote, saveReplica, enqueue, pending, markSent e acknowledge. Transporte
tem peerReplicaId, send e incoming, com capacidades opcionais sendAndAwaitAck e
acknowledge. A suíte pública recebe ReplicaStorageContractFixture com duas
factories. A fixture implementa esses contratos por delegação, sem importar
`src` ou herdar implementação interna.

DeltaCrdt e DeltaChange fornecem contratos comuns. A integração Replica/codec
continua fechada nos oito CrdtKind; implementar DeltaChange não registra outro
CRDT automaticamente. Estado/mutação/join pertencem ao core; candidata, commit,
outbox e restauração ao fluxo sync/storage; SQL ao adaptador. Modelos, identidade
de instalação, endereços, agendamento, rede e UI continuam no consumidor.

O extrator usa analyzer 14.5.0 já selecionado pelo grafo de dependências de teste,
com import limitado ao instrumento. Não adiciona dependência runtime nem impõe
analyzer à biblioteca distribuída. O relatório identifica a versão efetivamente usada.

## Formatos preservados

| Fronteira | Writer atual/histórico 1.0.0 | Readers já suportados |
|---|---|---|
| DeltaCodec | v4 | v1/v2 com migração explícita, v3 e v4 |
| Snapshot interno Replica | v9 | v1 a v9, rejeitando dados insuficientes/inválidos |
| ReplicaSnapshot de storage | v2 | v1 e v2 |
| OutboxEntry | v2, uma mudança por entrada | v1 com peer explícito e v2 |
| DeltaEnvelope | v2 | v1 com destinatário explícito e v2 |
| SQLite | schema 1 | schema compatível; upgrade/downgrade desconhecido é rejeitado |
| ACK | Sem campo de versão | peer, IDs e labels received/applied-and-persisted validados |

A fixture cobre os oito tipos, LWW null/tombstone, MV concorrente e compacto,
OR-Set com lacuna real de entrega, remoção/recriação OR-Map, dados JSON aninhados,
IDs e metadados de tentativas para dois destinatários. Entregar depois os dots
1/2 ausentes confirma que observar o dot 3 não os descartou por máximo.

Os casos de codec/storage/envelope/outbox anteriores são fixtures de fronteira
dos readers documentados; não representam uma instalação histórica dessas
versões. A suíte geral existente mantém as demais regressões de versões.
Valores wire usam labels explícitos; `.index` ou renomeação de enum não altera
o formato. Remover um tipo operacional público não permite retirar seu reader.

## Mapa de migração para a 1.0.1

Todos os pontos abaixo pertencem à mesma release autorizada. Os substitutos
existentes são reais; nomes/assinaturas de novas conveniências serão fixados na
tarefa indicada e atualizados neste mapa antes da VAL-17.

| Uso 1.0.0 afetado | Encaminhamento público e adaptação | Tarefa |
|---|---|---|
| PendingDeltaStore/MemoryPendingDeltaStore | Implementar ReplicaStorage; usar MemoryStorage volátil ou SQLite persistente; garantir snapshot + outbox atômicos | R-39 |
| SyncEngine com store: | Compor SyncEngine.withStorage(storage: ...), restaurar e fechar recursos pelo lifecycle público | R-39 |
| Replica.set/remove e SyncEngine.set/remove | Usar setDelta/removeDelta; aguardar Futures da engine para commit local | R-39 |
| Delta.crdt e crdtChanges | Usar Delta(changes) e changes | R-39 |
| OutboxEntry.operationId | Usar entryId para o ID singular ou changeIds para coleção | R-39 |
| Operation e migrateLegacyOperation exportados | Produzir DeltaChange nativo; ler payload antigo pelo DeltaCodec versionado; parser/DTO histórico ficam internos | R-39 |
| pendingDelta().changes.length para status | R-37 fornece quantidade/resumo sem materializar lote; outbox continua fonte; documentar adaptação de storage se houver membro novo | R-37 |
| Chamadas de mutação separadas para campos relacionados | R-38 fornece lote local atômico; adaptar agrupamento sem prometer transação remota distribuída | R-38 |
| Casts/conversões repetidos após valueAt | R-40 fornece decoder opcional do consumidor, com erro explícito e JSON isolado | R-40 |
| SyncCommitEvent(origin: ...) e observação global | R-41 acrescenta endereços e emissão comum; adaptar construção/seleção e switches se houver quebra, preservando commit distinto de ACK | R-41 |
| valueAt indistinguindo ausente/null/tombstone | R-42 fornece consulta tipada; valueAt mantém semântica atual | R-42 |

Também inventariados: OutboxStatus.confirmed e ReplicaSnapshot.legacy estão
depreciados e ligados a leitores antigos. Sua existência não autoriza descartá-los
como dados. R-39 decide internalização necessária preservando os readers e
documentando qualquer remoção pública adicional. R-37 não precisa mudar
interfaces de transporte; qualquer alteração em implementadores de storage deve
ter fixture migrada e suíte atualizada. Não exigir abstração opcional se apenas
duplicar regras; justificar o menor contrato pelo caso de consulta de status.

Casos sem quebra prevista conservam contratos, incluindo SDK, joins, identidade,
atomicidade, isolamento, falhas e manutenção dos dados. Formatos e readers são
um gate separado da compilação de fonte. A escolha de numeração não os dispensa.

## Custo da outbox antes de R-31

```sh
dart --packages=.dart_tool/package_config.json plan/evidence/r30/measure_outbox.dart > /tmp/r30-outbox.json
```

Cargas: 32, 128, 512 e 1024 entradas com os oito tipos, divididas entre peer-a
e peer-b. Construção/JSON das entradas fica fora do tempo medido. Duas rodadas
de aquecimento e cinco amostras por carga; sem medição de heap. Confere conteúdo,
ordem e subconjunto por peer. O tempo mede consolidação global, não I/O SQLite,
rede ou latência completa de push. O subconjunto de peer é validado sem cronômetro.

`baselineReferencePrefixVisits = n*(n+1)/2` é uma contagem analítica dos laços
históricos de mergeOutbox/Delta.merge, não instrumentação do algoritmo que será
alterado. O medidor chama a implementação real e não contém outro join.
R-31 deve comparar mesma carga após a correção e preservar a rejeição de IDs
conflitantes; amostras do host não sustentam ganho universal nem limite de teste.

## Matriz de SDK

| SDK | Execução de R-30 | Checks definidos |
|---|---|---|
| 3.13.5 stable/Linux x86_64 | Executado | Sete pacotes, consumidor histórico/atual, SQLite e medidor |
| 3.12.x, mínimo de ^3.12.0 | Definido, não executado neste host | Mesmos contratos/dados e sete pacotes, com resolução própria para esse SDK |

Para a faixa mínima, selecionar uma instalação 3.12.x no PATH e confirmar
`dart --version` antes dos comandos. Rodar em checkout/cópia separado, resolver
dependências com esse SDK e executar:

```sh
dart pub get
for package in . packages/deltasync_core packages/deltasync_sync packages/deltasync_storage packages/deltasync_storage_sqflite packages/deltasync_storage_testing packages/deltasync_transport; do
  (cd "$package" && dart analyze && dart test --reporter expanded) || exit 1
done
python3 plan/evidence/r30/capture.py --dart dart --prepare-only --test-consumers > /tmp/r30-sdk-minimum.json
```

Registrar SDK, resolução, diretórios, resultados e origem dos imports; não copiar
package_config/lock de SDK posterior para alegar suporte mínimo. R-30 define
essa execução; R-33 e VAL-17 exigem sua realização. Apenas 3.13.5 está instalado
neste host. Ausência de 3.12 não vira aprovação de runtime nessa versão.
