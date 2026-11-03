# Escala intermediária após R-44

Execução: 2026-11-01. Complemento de calibração, sem alterar a biblioteca nem
concluir CP-16. As fixtures fechadas de CP-14 contêm 10 ou 100 notas LWW
distintas de 64 bytes e a mesma quantidade de entradas pendentes. O ensaio
reusa o entrypoint de restauração R-44 com N=10/100, em cópias novas.

| N | G52/API 33, `repository.start` | G53/API 34, `repository.start` | Host A/B, `SyncEngine.start` |
|---:|---:|---:|---:|
| 10 | 144,8 ms; CPU 228 ms | 70,0 ms; CPU 135 ms | 148,7 / 146,3 ms |
| 100 | 245,9 ms; CPU 401 ms | 116,2 ms; CPU 203 ms | 231,5 / 241,3 ms |

As quatro janelas Android foram profile ARM64. Cada cópia foi auditada por API
pública: exatamente N chaves/valores, N pendências/IDs e sequência N, iguais
à fixture CP-14. Sem perda/falha do coletor. Hashes dos bancos normais e de
ensaio anteriores ficaram iguais; os APKs CP-10 foram reinstalados e parados.
Não houve sync nem alteração de rede/UFW nesta medição.

Brutos, quatro APKs, configurações, bancos copiados, inspeções, logs, fontes
do entrypoint e hashes estão em
`/projetos/tcc/samples_test_lib/compass_app/app/.performance-artifacts/r45/7c635e9317644190816304caba139d5f/`.
SHA-256 do `manifest.json`:
`98169a5924a0cf546dc607f2c52f4244b843d04fa09131e6142b412b98905b78`.
O manifesto lista 36 arquivos e hashes da lib, do lockfile e do instrumento.

Uma execução por aparelho/carga mostra que a abertura intermediária também é
rápida após R-44. Não estima p95, energia nem efeito do coletor. Host e Android
usam bordas de tempo diferentes. A série principal ainda precisa de matriz,
ordem e repetições congeladas em CP-16, seguida de sync e análise por rodada.
