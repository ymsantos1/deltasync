# Sync de escala intermediária após R-44

Execução: 2026-11-01. Uma rodada profile com coletor ligado para N=10 e N=100
notas LWW distintas, 64 bytes por nota, em cada aparelho. O instrumento CP-15
foi copiado para namespace `r46`, restrito a N=10/100. Cada carga usou hub
novo com `--snapshot-pull`; ordem A/G52, B/G53, A/G52. Fontes e quatro APKs
foram retidos com hashes. Não há mudança na lib nem no app normal.

| N | A/G52: primeiro sync | B/G53: primeiro sync | A/G52: pull final | Corpo HTTP do primeiro A: push / pull / ACK |
|---:|---:|---:|---:|---:|
| 10 | 181,8 ms | 180,3 ms | 72,5 ms | 5.675 / 5.180 / 871 B |
| 100 | 749,5 ms | 471,0 ms | 344,3 ms | 50.714 / 50.216 / 7.724 B |

Os números HTTP são corpos por rota vistos pelo proxy: push enviado, resposta
do pull e ACK enviado. Não são bytes tarifados. O pull transporta snapshot
materializado do hub; não apresentar todo o tráfego como delta. Todas as rotas
responderam HTTP 200. A primeira fase de cada aparelho teve push/pull/ACK;
a segunda fase de A teve pull/ACK. Após cada fase, a outbox do cliente ficou
vazia. Na fase final, os mapas LWW completos de A, B e hub eram idênticos,
com exatamente N chaves e zero pendências. Sem perdas/falhas do coletor.

O controlador conferiu hashes dos bancos anteriores antes/depois da coleta,
parou hub/proxy e os apps. A reinstalação automática do APK CP-10 no G52
expirou porque o Play Protect abriu uma pergunta sobre enviar o app ao Google;
foi selecionado **Não enviar**. A reinstalação posterior foi verificada pelo
SHA-256 do APK instalado. O G53 também teve APK CP-10 conferido por hash.
Nenhuma regra UFW foi criada ou removida.

Artefatos completos:
`/projetos/tcc/samples_test_lib/compass_app/app/.performance-artifacts/r46/7c635e9317644190816304caba139d5f/`.
O `manifest.json` lista 46 arquivos e tem
SHA-256 `88c813df5c4269f304fa2b96052471c7bf7c43b1ad6bc70e74c688b694099019`.

Limite: um par A/B por carga. Tempos não formam distribuição, p95 ou comparação
causal on/off. Os pontos N=1/1000 de CP-15 pertencem a build anterior à R-44;
não misturar as quatro cargas como uma série homogênea. CP-16 ainda precisa
congelar matriz e repetições antes da série principal.
