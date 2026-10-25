# Custos de mutação, restauração e pendências — R-32

Execução em 2026-10-24, após R-31/R-39. Entrega de medição: nenhuma fonte de
produção, contrato público, dependência, manifesto ou formato foi alterado.
O instrumento existente ganhou `--paths`; o modo sem argumentos foi preservado.

## Reprodução e proveniência

Na raiz, com dependências já resolvidas:

```sh
dart run example/measure_crdt_cost.dart --paths > /tmp/r32-paths.json
dart format --output=none --set-exit-if-changed example/measure_crdt_cost.dart lib test
dart analyze
dart test --reporter expanded
dart run example/measure_crdt_cost.dart
```

Não rode outras suítes Dart em paralelo ao medidor. O modo antigo é conferência
funcional do instrumento anterior, sem comparação direta dos seus tempos.
[measurements.json](measurements.json) contém amostras e ambiente completos;
[validation.json](validation.json) guarda comandos, hashes, review, correções e
checagens; [root-checks.json](root-checks.json) contém formato/análise e os 13 testes
da facade. Não foi necessário repetir os testes dos sete pacotes: a biblioteca
não mudou. R-39 permanece evidência histórica, não uma execução nova nesta tarefa.

Ambiente: Dart 3.13.5 stable, Linux x86_64, 12 processadores disponíveis.
Semente 20261024 e relógio de criação fixo em 1730000000000 ms. Cada carga usa
uma string ASCII determinística; os oito tipos compartilham esse valor onde a
operação admite payload. Não representa objetos profundamente aninhados ou um
perfil completo de modelos reais. SDK 3.12.x e Android não foram executados.

## Desenho e verificações

Há sete configurações em cada backend: base com 16 campos, valor ASCII de 64 B
e 16 pendências; campos crescem para 64/256, valor para 256/1024 B e pendências
para 64/256, variando um parâmetro de configuração por vez. Mais pendências
também modificam estado causal/valores dos tipos cumulativos, como num backlog
real: esse eixo não conserva o snapshot byte a byte entre tamanhos diferentes.

Cada configuração/backend tem dois aquecimentos e cinco amostras medidas:
14 cargas, 28 aquecimentos e 70 amostras. Nenhum limiar temporal reprova a carga.
Fixtures são reconstruídas por execução, sem acumular as mutações entre amostras.
A ordem é fixa, MemoryStorage antes de SQLite; JIT, GC e caches do SO não são
neutralizados. Os dois aquecimentos não provam estado estacionário. Por isso
cargas menores nem sempre têm tempos menores, e razões não são garantias.

Estado e outbox incluem os oito CRDTs. Cada peer recebe blocos com oito tipos;
metade das entradas pertence ao peer selecionado. Entradas `pending` e `sent`
têm tentativas/metadados iniciais fixos. O checkpoint já inclui os efeitos das
pendências, como após commit atômico; a restauração reaplica os deltas de forma
idempotente. SQLite é fechado após o seed e reaberto durante start. Isso testa
esse percurso de reabertura FFI, sem simular queda de energia/processo mobile.

Cada execução verifica cópia/adoção, snapshot, valores restaurados, clocks/dots/
sequências/contextos, IDs, ordenação e metadados da outbox. Replay pode avançar
HLC: exige monotonicidade e igualdade dos demais campos do snapshot. Mapas/sets
são normalizados somente para comparar valores; listas mantêm ordem. A primeira
execução falhou por ordem de mapas na comparação do medidor; a correção foi
revista e as execuções seguintes passaram, sem alterar a biblioteca.

Consultas não podem mudar estado/clocks. Preparação deve conservar todas as
pendências, produzir IDs/payloads do peer escolhido e incrementar apenas suas
tentativas. A mutação final deve manter sequência, estado armazenado igual ao
adotado e acrescentar uma entrada. Resultados e tamanhos de fixtures MemoryStorage/SQLite
foram conferidos como equivalentes. Não se trata de um novo teste geral de
convergência, falhas de rede ou durabilidade de todos os adaptadores.

## Escopo dos cronômetros

- `fork`, `nativeMutation` e `adopt`: cópia, escrita LWW e adoção isoladas no core.
  A escrita repete o mesmo valor no campo existente; ainda produz delta/clock.
- `snapshot`: construção do mapa de snapshot; `snapshotJsonEncode`: conversão
  desse mapa em string JSON; `snapshotDecode`: restauração direta do mapa.
- `engineStartWithOutbox`: load, replay e save pela engine, incluindo abertura
  da conexão SQLite. Preparação do banco e fechamento anterior ficam fora.
- `engineMutation`: escrita LWW após start, incluindo candidata, commit e adoção.
- `pushPreparation`: implementação real de OutboundSync.prepare, com leitura,
  filtro, consolidação e markSent. Exclui fila externa, envio e espera de ACK.
  Imports internos existem somente para instrumentar essa etapa do produto.
- `pendingCountViaEngineBatch`: cinco chamadas públicas a pendingDelta e length,
  cobrindo os dois peers; `countStatusViaStorageBatch`: cinco consultas de status
  do peer selecionado, que ainda materializam entradas. São escopos diferentes.
- `valueAtBatch`: cinco leituras de um campo LWW string, sem fork da réplica.

Setup, validação e contagem de bytes ficam fora dos cronômetros. Tempos de fases
isoladas não devem ser somados como uma decomposição exata de engineMutation.

## Resultados observados

Medianas em microssegundos; as colunas de contagem/status medem cinco chamadas.
`start` inclui restauração; `prep` inclui persistir metadados de tentativa.

| Carga | Backend | Mutação engine | Start | Prep | Contagem ×5 | Status peer ×5 |
|---|---|---:|---:|---:|---:|---:|
| base | Memory | 959 | 15641 | 434 | 1650 | 40 |
| base | SQLite | 2038 | 12993 | 4680 | 5905 | 3146 |
| fields-64 | Memory | 1426 | 18596 | 266 | 710 | 33 |
| fields-64 | SQLite | 2807 | 20875 | 3929 | 4186 | 2422 |
| fields-256 | Memory | 4878 | 59677 | 262 | 589 | 22 |
| fields-256 | SQLite | 7028 | 72765 | 3898 | 3494 | 1835 |
| value-256 | Memory | 444 | 5236 | 156 | 482 | 16 |
| value-256 | SQLite | 1354 | 7437 | 3072 | 2925 | 1675 |
| value-1024 | Memory | 573 | 7104 | 185 | 560 | 16 |
| value-1024 | SQLite | 1501 | 9497 | 3214 | 3298 | 1808 |
| pending-64 | Memory | 583 | 21242 | 443 | 1347 | 29 |
| pending-64 | SQLite | 1352 | 24629 | 8931 | 7853 | 3679 |
| pending-256 | Memory | 889 | 153115 | 1610 | 5110 | 48 |
| pending-256 | SQLite | 2077 | 168325 | 28568 | 28681 | 11919 |

Projeções em bytes UTF-8 JSON, antes de preparar/escrever a mutação final.
São iguais nos dois backends; não são parcelas aditivas ou backups restauráveis.
Metadados projetam clocks/HLC, sequências, contextos MV, identidade/dots e
observações retidas, inclusive mudanças internas OR-Map e timestamps LWW.
Valores de domínio são excluídos dessa projeção. Snapshot continua sendo o
formato completo, separado da outbox e de suas tentativas/destinos.

| Carga | Valores visíveis | Projeção causal | Snapshot réplica | Outbox |
|---|---:|---:|---:|---:|
| base | 1062 | 4413 | 6878 | 6682 |
| fields-64 | 4248 | 15103 | 23928 | 6684 |
| fields-256 | 17012 | 57980 | 92285 | 6688 |
| value-256 | 3366 | 4413 | 9566 | 8602 |
| value-1024 | 12582 | 4413 | 20318 | 16282 |
| pending-64 | 1134 | 6205 | 9618 | 26664 |
| pending-256 | 1446 | 13462 | 20691 | 106950 |

SQLite é medido em outro ponto: arquivos main/WAL/SHM após preparação, nova
mutação e fechamento, sem VACUUM. Por exemplo, pending-256 terminou com main de
233472 B e WAL/SHM de 0 B; a outbox JSON inicial tinha 106950 B. Esses números não
medem o mesmo objeto/instante e não indicam espaço recuperável no arquivo.

RSS após as amostras variou de 270348288 a 323764224 B no mesmo processo.
ProcessInfo.currentRss/maxRss inclui runtime, fixtures, validações e SQLite nativo,
com histórico de alocação/cache das cargas anteriores. Heap e alocações não foram
medidos. Não atribuir diferença de RSS a uma operação, nem inferir vazamento,
bytes alocados ou consumo de MemoryStorage contra SQLite a partir dessa faixa.

## Gargalos e encaminhamento

1. **Consulta de pendências: R-37 antes da release.** Com 256 entradas, cinco
   contagens pela engine levaram 5110 µs em memória e 28681 µs no SQLite. O status
   do peer materializou 128 entradas por chamada e levou 11919 µs no SQLite.
   Código confirma leitura/decodificação de payloads para obter quantidade/status.
   Implementar R-37 já prevista e comparar estas mesmas cargas; não duplicar a
   fonte de verdade da outbox nem confundir commit com ACK.
2. **Restauração: otimização posterior, sem mudar a release por especulação.**
   Com 256 pendências, start levou 153115/168325 µs em Memory/SQLite. Com 256
   campos e 16 pendências, 59677/72765 µs. ReplicaPersistence reaplica cada entrada
   por Replica.apply, que faz fork/adopt; snapshot grande é copiado repetidamente.
   Isso justifica investigação posterior de replay em lote, preservando validação,
   HLC, identidade e rollback. Não é um defeito de dados demonstrado nem existe
   orçamento de latência definido que autorize classificar estes tempos como
   aceitáveis para qualquer app. Decisão desta tarefa: não bloquear 1.0.1 com uma
   nova refatoração de replay; orçamento de inicialização mais estrito exige
   reavaliar essa decisão com carga/plataforma do consumidor.
3. **Cópias de estado: preservar isolamento; avaliar depois.** Ao crescer de
   16 para 256 campos, fork/adopt em memória passaram de 393/308 a 1389/1402 µs;
   snapshot, de 173 a 1349 µs. Mutação nativa ficou em 29/32 µs, enquanto a engine
   passou de 959 a 4878 µs. Os cronômetros isolados não quantificam qual fração
   exata cabe a cada cópia no commit. Não retirar cópias/checkpoints nem mudar
   todos os CRDTs nesta tarefa. O write e os valores maiores também aumentam
   serialização/arquivo; resultados de tempo não são monotônicos no eixo string.
4. **Preparação SQLite: manter contrato; otimização posterior do adaptador.**
   Preparar 128 entradas do peer levou 28568 µs, contra 1610 µs em memória.
   markSent consulta e reescreve payload por ID na mesma transação. Este dado não
   mede rede/ACK nem prova que toda diferença vem do SQL. Não alterar semântica
   de tentativas/seleção para reduzir número. R-31 continua resolvida no merge;
   a próxima medição de um ajuste do adaptador deve repetir o mesmo percurso.
5. **Consulta pontual:** estas cinco leituras de string não mostraram crescimento
   consistente com campos/pendências. Isso apoia usar valueAt no consumidor, sem
   sustentar promessa para coleções grandes, modelos ou outras plataformas.

Esses encaminhamentos satisfazem a decisão de R-32: R-37 permanece entrega desta
release; possíveis otimizações novas de replay/cópias/SQL ficam para avaliação
posterior, fora do escopo de consolidação já autorizado. Nenhum requisito da
análise foi removido. Sem novo join, GC, schema ou framework. R-35 documentará
consumo/status; VAL-17 continua gate da release inteira.
