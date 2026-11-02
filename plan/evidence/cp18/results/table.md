# Comparação observada CP-18

Seis pares válidos; aquecimentos e bootstrap excluídos. Tempos: mediana [mínimo; máximo]. Redução: mediana de 100×(snapshot−incremental)/snapshot calculada dentro de cada par. Redução negativa indica aumento observado. Sem inferência de significância.

| Métrica | Snapshot | Incremental | Redução pareada % |
| --- | ---: | ---: | ---: |
| Bytes recebidos por B no pull | 502024.000 [502024.000; 502024.000] | 736.000 [736.000; 736.000] | 99.853 |
| Bytes de ACK de B | 77027.000 [77027.000; 77027.000] | 209.000 [209.000; 209.000] | 99.729 |
| Bytes de ACK de A+B | 154055.000 [154055.000; 154055.000] | 341.000 [341.000; 341.000] | 99.779 |
| Total de corpos HTTP do ciclo A+B | 1159071.000 [1159071.000; 1159071.000] | 2275.000 [2275.000; 2275.000] | 99.804 |
| Distribuição remota do ciclo A+B | 1158126.000 [1158126.000; 1158126.000] | 1330.000 [1330.000; 1330.000] | 99.885 |
| Sync de B (ms) | 327.634 [305.155; 430.293] | 186.820 [163.893; 280.452] | 42.781 |
| Consulta sem novidades de B (bytes) | 579062.000 [579062.000; 579062.000] | 372.000 [372.000; 372.000] | 99.936 |
| Consulta sem novidades de B (ms) | 318.961 [311.878; 335.580] | 183.219 [151.652; 197.987] | 44.887 |
| Convergência nos ensaios físicos | 6/6 | 6/6 | — |

Ciclo A+B inclui A/editar/sync e B/receber/sync; a consulta sem novidades é separada. Distribuição remota exclui request/response de /sync/push, incluindo pulls e ACKs de A+B. Não são bytes tarifados. A soma de durações A+B não é tempo de relógio do ciclo completo.
