# Tabelas CP-12

Geradas de CP-11. A=G52; B=G53; first=primeira abertura; second=pull posterior de A. n=6 por célula. Tempos em ms do Stopwatch do instrumento Dart. p95 usa nearest rank e equivale ao máximo; nenhuma estimativa de cauda estável.

## Tempos por etapa

| N | Coletor | Aparelho | Abertura | Etapa | n | Mínimo | Mediana | Máximo/p95 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | off | A | first | edit | 6 | 21.875 | 25.143 | 34.134 |
| 1 | off | A | first | restore | 6 | 92.435 | 99.418 | 147.582 |
| 1 | off | A | first | sync | 6 | 129.747 | 159.778 | 323.324 |
| 1 | off | A | second | restore | 6 | 70.464 | 94.320 | 127.053 |
| 1 | off | A | second | sync | 6 | 63.247 | 75.011 | 90.246 |
| 1 | off | B | first | edit | 6 | 13.794 | 20.998 | 33.759 |
| 1 | off | B | first | restore | 6 | 54.656 | 70.108 | 72.661 |
| 1 | off | B | first | sync | 6 | 72.875 | 102.377 | 110.979 |
| 1 | on | A | first | edit | 6 | 11.992 | 12.804 | 15.779 |
| 1 | on | A | first | restore | 6 | 96.506 | 127.352 | 189.894 |
| 1 | on | A | first | sync | 6 | 116.099 | 182.452 | 304.343 |
| 1 | on | A | second | restore | 6 | 67.415 | 109.706 | 170.546 |
| 1 | on | A | second | sync | 6 | 50.424 | 55.380 | 91.896 |
| 1 | on | B | first | edit | 6 | 14.746 | 16.761 | 18.353 |
| 1 | on | B | first | restore | 6 | 63.448 | 72.438 | 96.408 |
| 1 | on | B | first | sync | 6 | 74.775 | 129.352 | 170.575 |
| 1000 | off | A | first | edit | 6 | 158.866 | 163.034 | 166.698 |
| 1000 | off | A | first | restore | 6 | 692.522 | 775.309 | 898.499 |
| 1000 | off | A | first | sync | 6 | 3604.131 | 3787.837 | 4108.208 |
| 1000 | off | A | second | restore | 6 | 377.824 | 415.814 | 641.814 |
| 1000 | off | A | second | sync | 6 | 379.778 | 404.266 | 477.491 |
| 1000 | off | B | first | edit | 6 | 91.231 | 99.762 | 120.188 |
| 1000 | off | B | first | restore | 6 | 483.148 | 505.303 | 626.494 |
| 1000 | off | B | first | sync | 6 | 3311.012 | 3386.430 | 3441.681 |
| 1000 | on | A | first | edit | 6 | 164.047 | 172.317 | 183.882 |
| 1000 | on | A | first | restore | 6 | 736.105 | 837.724 | 991.217 |
| 1000 | on | A | first | sync | 6 | 4003.642 | 4219.186 | 5268.885 |
| 1000 | on | A | second | restore | 6 | 348.921 | 423.703 | 482.468 |
| 1000 | on | A | second | sync | 6 | 395.655 | 436.725 | 524.712 |
| 1000 | on | B | first | edit | 6 | 83.227 | 91.514 | 99.448 |
| 1000 | on | B | first | restore | 6 | 491.776 | 501.111 | 529.297 |
| 1000 | on | B | first | sync | 6 | 3176.580 | 3200.695 | 3341.573 |

## Diferenças pareadas: ligado menos desligado

Cada diferença usa o mesmo índice de par, aparelho, carga, abertura e etapa. Valores negativos indicam menor tempo observado no ligado, sem atribuir causalidade.

| N | Aparelho | Abertura | Etapa | n | Mínimo ms | Mediana ms | Máximo/p95 ms |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | A | first | edit | 6 | -22.033 | -12.399 | -8.699 |
| 1 | A | first | restore | 6 | -42.615 | 31.947 | 89.432 |
| 1 | A | first | sync | 6 | -174.742 | 26.448 | 170.333 |
| 1 | A | second | restore | 6 | -39.264 | 9.315 | 88.807 |
| 1 | A | second | sync | 6 | -36.640 | -12.732 | 6.189 |
| 1 | B | first | edit | 6 | -19.013 | -4.603 | 4.559 |
| 1 | B | first | restore | 6 | -9.213 | 4.087 | 25.883 |
| 1 | B | first | sync | 6 | -25.890 | 44.334 | 66.486 |
| 1000 | A | first | edit | 6 | 2.888 | 10.252 | 21.300 |
| 1000 | A | first | restore | 6 | -162.394 | 74.062 | 185.168 |
| 1000 | A | first | sync | 6 | 96.482 | 493.562 | 1160.677 |
| 1000 | A | second | restore | 6 | -190.401 | -22.857 | 87.368 |
| 1000 | A | second | sync | 6 | -78.857 | 30.457 | 144.934 |
| 1000 | B | first | edit | 6 | -36.961 | -8.352 | 1.862 |
| 1000 | B | first | restore | 6 | -113.884 | -6.699 | 46.149 |
| 1000 | B | first | sync | 6 | -238.067 | -188.963 | -49.497 |

## Recursos: medianas por etapa

CPU é tempo acumulado do processo, não uso percentual. PSS é leitura da API Android em kB, com frequência limitada; não é pico nem heap Dart. UID conta todo tráfego do próprio UID. Dispersão e faltantes constam em summary.csv.

| N | Coletor | Aparelho | Abertura | Etapa | CPU ms | PSS após kB | UID TX bytes | UID RX bytes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | off | A | first | edit | 46.000 | 158814.500 | 0.000 | 0.000 |
| 1 | off | A | first | restore | 158.000 | 158814.500 | 0.000 | 0.000 |
| 1 | off | A | first | sync | 86.000 | 158814.500 | 0.000 | 0.000 |
| 1 | off | A | second | restore | 147.000 | 162568.500 | 0.000 | 0.000 |
| 1 | off | A | second | sync | 99.000 | 162568.500 | 0.000 | 0.000 |
| 1 | off | B | first | edit | 42.500 | 97395.000 | 0.000 | 0.000 |
| 1 | off | B | first | restore | 119.500 | 97395.000 | 0.000 | 0.000 |
| 1 | off | B | first | sync | 170.500 | 97395.000 | 0.000 | 0.000 |
| 1 | on | A | first | edit | 19.000 | 161196.000 | 0.000 | 0.000 |
| 1 | on | A | first | restore | 172.500 | 161196.000 | 0.000 | 0.000 |
| 1 | on | A | first | sync | 43.000 | 161196.000 | 0.000 | 0.000 |
| 1 | on | A | second | restore | 128.500 | 146868.000 | 0.000 | 0.000 |
| 1 | on | A | second | sync | 31.000 | 146868.000 | 0.000 | 0.000 |
| 1 | on | B | first | edit | 20.500 | 100718.000 | 0.000 | 0.000 |
| 1 | on | B | first | restore | 123.000 | 100718.000 | 0.000 | 0.000 |
| 1 | on | B | first | sync | 94.000 | 100718.000 | 0.000 | 0.000 |
| 1000 | off | A | first | edit | 166.000 | 146865.000 | 0.000 | 0.000 |
| 1000 | off | A | first | restore | 862.000 | 146865.000 | 0.000 | 0.000 |
| 1000 | off | A | first | sync | 3711.000 | 146865.000 | 628495.000 | 614265.000 |
| 1000 | off | A | second | restore | 606.000 | 143422.000 | 0.000 | 0.000 |
| 1000 | off | A | second | sync | 290.000 | 143422.000 | 0.000 | 0.000 |
| 1000 | off | B | first | edit | 231.000 | 99813.500 | 0.000 | 0.000 |
| 1000 | off | B | first | restore | 1083.000 | 99813.500 | 0.000 | 0.000 |
| 1000 | off | B | first | sync | 3750.000 | 99813.500 | 622739.000 | 606077.000 |
| 1000 | on | A | first | edit | 184.000 | 146164.500 | 0.000 | 0.000 |
| 1000 | on | A | first | restore | 918.500 | 146164.500 | 0.000 | 0.000 |
| 1000 | on | A | first | sync | 4201.500 | 146164.500 | 628357.000 | 614655.000 |
| 1000 | on | A | second | restore | 566.000 | 154582.500 | 0.000 | 0.000 |
| 1000 | on | A | second | sync | 291.500 | 154582.500 | 0.000 | 0.000 |
| 1000 | on | B | first | edit | 113.500 | 96832.500 | 0.000 | 0.000 |
| 1000 | on | B | first | restore | 1071.500 | 96832.500 | 0.000 | 0.000 |
| 1000 | on | B | first | sync | 3351.500 | 96832.500 | 621786.000 | 606155.000 |

## Corpos HTTP por rota: medianas

Push envia backlog de deltas; pull usa snapshot completo. São bytes de corpo JSON, sem cabeçalhos, TLS, TCP ou tarifação. Os intervalos completos estão em network-summary.csv.

| N | Coletor | Aparelho | Abertura | Rota | n | TX corpo bytes | RX corpo bytes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | off | A | first | /sync/ack | 6 | 201.000 | 11.000 |
| 1 | off | A | first | /sync/pull | 6 | 0.000 | 716.000 |
| 1 | off | A | first | /sync/push | 6 | 1208.000 | 272.000 |
| 1 | off | A | second | /sync/ack | 6 | 200.000 | 11.000 |
| 1 | off | A | second | /sync/pull | 6 | 0.000 | 713.000 |
| 1 | off | B | first | /sync/ack | 6 | 199.000 | 11.000 |
| 1 | off | B | first | /sync/pull | 6 | 0.000 | 712.000 |
| 1 | off | B | first | /sync/push | 6 | 1201.000 | 270.000 |
| 1 | on | A | first | /sync/ack | 6 | 201.000 | 11.000 |
| 1 | on | A | first | /sync/pull | 6 | 0.000 | 716.000 |
| 1 | on | A | first | /sync/push | 6 | 1208.000 | 272.000 |
| 1 | on | A | second | /sync/ack | 6 | 200.000 | 11.000 |
| 1 | on | A | second | /sync/pull | 6 | 0.000 | 713.000 |
| 1 | on | B | first | /sync/ack | 6 | 199.000 | 11.000 |
| 1 | on | B | first | /sync/pull | 6 | 0.000 | 712.000 |
| 1 | on | B | first | /sync/push | 6 | 1201.000 | 270.000 |
| 1000 | off | A | first | /sync/ack | 6 | 78027.000 | 11.000 |
| 1000 | off | A | first | /sync/pull | 6 | 0.000 | 505022.000 |
| 1000 | off | A | first | /sync/push | 6 | 505523.000 | 78101.000 |
| 1000 | off | A | second | /sync/ack | 6 | 77027.000 | 11.000 |
| 1000 | off | A | second | /sync/pull | 6 | 0.000 | 502022.000 |
| 1000 | off | B | first | /sync/ack | 6 | 77026.000 | 11.000 |
| 1000 | off | B | first | /sync/pull | 6 | 0.000 | 502021.000 |
| 1000 | off | B | first | /sync/push | 6 | 502519.000 | 77100.000 |
| 1000 | on | A | first | /sync/ack | 6 | 78027.000 | 11.000 |
| 1000 | on | A | first | /sync/pull | 6 | 0.000 | 505022.000 |
| 1000 | on | A | first | /sync/push | 6 | 505523.000 | 78101.000 |
| 1000 | on | A | second | /sync/ack | 6 | 77027.000 | 11.000 |
| 1000 | on | A | second | /sync/pull | 6 | 0.000 | 502022.000 |
| 1000 | on | B | first | /sync/ack | 6 | 77026.000 | 11.000 |
| 1000 | on | B | first | /sync/pull | 6 | 0.000 | 502021.000 |
| 1000 | on | B | first | /sync/push | 6 | 502519.000 | 77100.000 |
