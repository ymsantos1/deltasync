# Consulta leve de pendências — R-37

Execução de 2026-10-24 após R-32/R-39, revisão inicial
f2edf0f4da878dd785c1240536b4537aa081e9d4. A API entregue é
`SyncEngine.pendingSummary({String? recipientPeerId})`, com retorno
`OutboxSummary`: pendingCount, sentCount e totalCount calculado. Filtro null
inclui todos os peers; o total conta entradas peer/ID, não IDs únicos globais.
Sent ainda aguarda ACK; confirmed histórico é excluído. Consulta não confirma,
não remove entradas e não valida o corpo dos deltas.

ReplicaStorage ganha pendingSummary obrigatório. Esse único membro evita uma
capacidade opcional e duas rotas de dispatch na engine. Adaptadores externos
devem implementar a leitura consistente e executar a suíte compartilhada. Veja
[migração e consumo](../../../docs/migracao-1.0.1.md#resumo-de-pendências-em-adaptadores--r-37)
e [consumidor externo](consumer_test.dart.txt). Nenhum formato/schema/SDK mudou.

MemoryStorage percorre status/destino sem acessar delta. SQLite agrupa status
no SQL, devolvendo somente grupos/contagens a Dart; ainda processa JSON no banco,
sem contagem constante ou índice novo. Builds sem json_extract usam fallback de
metadata JSON em Dart. Somente ausência dessa função habilita fallback; outros
erros propagam, sem devolver zero. A
[documentação SQLite](https://www.sqlite.org/json1.html#compiling_in_json_support)
explica por que disponibilidade não é assumida para toda build.

## Evidências

- [validation.json](validation.json): 266 testes nos sete pacotes, formato e
  análise aprovados, hashes e falha inicial de compilação do helper de teste.
  Helper corrigido e revisão repetida antes da rodada completa.
- [consumer-validation.json](consumer-validation.json): 18 checks em projeto
  isolado por path, adaptador antigo rejeitado pelo membro ausente e sete
  inventários com apenas as adições previstas. R-30/R-39 permanecem intactos.
- [measurements.json](measurements.json): 14 cargas, 70 amostras, 28 aquecimentos,
  verificações de equivalência e custos de consultas antigas/novas na mesma
  execução. Campo task identifica a família de cargas R-32 reutilizada.

Suíte cobre filtros de réplica/peer, pending/sent/confirmed, ACK parcial, leitura
concorrente com commit e rede, rollback, falha de consulta e lifecycle. SQLite
é fechado/reaberto preservando snapshot e contagens após ACK parcial. Provas
estruturais fazem o getter delta falhar em MemoryStorage e verificam que a
agregação SQLite não retorna payloads. Fallback é exercitado sobre banco real
com ausência da função simulada; JSON/metadata inválidos e outras falhas propagam.

## Custo observado

Medianas em microssegundos para cinco consultas, carga pending-256:

| Backend | Contagem antiga global | Resumo global | Status antigo por peer | Resumo por peer |
|---|---:|---:|---:|---:|
| MemoryStorage | 5215 | 55 | 53 | 42 |
| SQLite FFI | 31537 | 3157 | 12977 | 1552 |

Global cobre 256 entradas; peer cobre 128. O caminho antigo de status chama
storage diretamente; o novo inclui também a fila da engine. Em carga pequena,
esse custo fixo pode superar o scan em memória: base teve 40/73 µs por peer.
Não existe garantia de ganho em toda carga. Timings são observações do host,
com JIT/GC/caches e ordem fixa; não medem rede nem heap/alocações. O fallback
sem JSON1 não foi benchmarkado. Nenhuma conclusão de espaço SQLite recuperável.

## Reprodução

```sh
python3 -B plan/evidence/r37/validate_consumer.py --dart dart --report /tmp/r37-consumer.json
dart run example/measure_crdt_cost.dart --paths > /tmp/r37-paths.json
```

Rodar benchmark sem outras suítes Dart em paralelo. O medidor verifica que
resumos equivalem às contagens materializadas em cada carga. A validação geral
usa formato/análise/testes nos sete pacotes, com comando/log completo no JSON.
Ambiente: Dart 3.13.5, Linux x86_64 e SQLite FFI. SDK 3.12.x e Android não
executados; resolução por path não prova os artefatos finais da VAL-17.
