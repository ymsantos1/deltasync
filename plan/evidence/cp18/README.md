# CP-18 — comparação controlada integral/incremental

Concluída em 2026-11-02. Relatório técnico para o TCC no consumidor externo:
`../../../../samples_test_lib/compass_app/app/docs/comparacao-integral-incremental-deltasync.md`.
[Tabela](results/table.md), [execuções](results/runs.csv), [rotas](results/routes.csv),
[tempos](results/timings.csv), [resumos](results/summary.csv) e [pares](results/paired.csv).

## Cofre e código efetivamente avaliado

`/projetos/tcc/samples_test_lib/compass_app/app/.performance-artifacts/cp-18/047f6fda88184cc58764fcff4f58a096/`.
Manifesto SHA-256:
`e34b4ad38ec1e85fc6b2ccd86e6096a8cd14548f3a2781f561021a39d04c1ec7`.
596 arquivos, 299.712.034 bytes, conferidos por tamanho e SHA-256 após cópia.
Fontes reais: 244 arquivos no archive/inventário, com hashes iguais antes/depois
da coleta; commit de referência, SDK e fingerprints em `environment.json`.
Arquivo de entrada congelado SHA-256:
`71b809b415a58ceb383623db940b09b2c5e71f44de6649ab0d0e37d33b20eadd`.

O cofre retém APKs/configs/logs, fontes, resolução, SQLite e inspeções, corpos
HTTP completos com IDs de captura únicos, comandos, controles por execução,
bootstrap/aquecimento, testes, análise e recibos de limpeza. A biblioteca é
fonte local com metadados 1.0.2, não uma nova versão hosted comprovada.
CP-17 e os demais experimentos/manifestos antigos permanecem preservados.

## Método e cobertura

Dois APKs profile da variante de ensaio do Compass, comuns às estratégias;
integração real de notas, sem avaliar sua interface completa. G52=A e G53=B.
N=1000 notas de 64 bytes,
mesma base fechada sem pendências e mesmo texto novo dentro do par. Hub e
arquivos dos clientes novos por estratégia. Bootstrap real A/B e confirmações
fora da amostra. Um aquecimento por protocolo, seis pares alternados.

Principais planejadas/tentadas/válidas: 12/12/12; excluídas: zero. Aquecimentos:
duas estratégias. Medidos 36 relatórios principais, mais seis de aquecimento;
28 bootstraps separados. Não contar etapas internas como repetições independentes.
Protocolo declarado antes da coleta em `protocol.json`.

## Evidências por etapa

1. Leitura: questão experimental e critérios CP-18 registrados no plano Compass;
   infraestrutura CP-17, contratos públicos e guia Dart consultados. Worktrees
   anteriores preservados; núcleo e APIs fora do escopo de alteração.
2. Implementação: opção `--incremental-pull` e `LwwDeliveryProgress` no servidor,
   com ofertas/confirmações por peer em transações SQLite. Snapshot continua
   disponível; cliente usa os mesmos envelopes/ACKs. Instrumento CP-18 comum
   inclui bootstrap, edição, recepção e nova consulta em B.
3. Review próprio: conferidos tombstones, ordenação durável, isolamento de peers,
   ACK antigo/inválido e ausência de conhecimento falso após crash. Ordenação
   de imports corrigida; captura HTTP usa UUID para evitar colisão entre handlers.
   Reforçada prova de rollback de ACK misto e de conhecimento do emissor após
   reinício. Sem achados impeditivos restantes; não é review independente.
4. Validação: servidor e app sem issues; 141 testes do consumidor; 11 cenários
   HTTP/SQLite únicos aprovados, cobrindo A–D nos dois modos e ACK inválido no
   incremental. Três casos reexecutados após reforço. Dois builds ARM64. Na
   coleta física, 12/12 estratégias convergiram e preservaram 999 notas, com
   vencedor/valor esperados e outboxes vazias. Corpos HTTP e contagens foram
   auditados diretamente nos arquivos; bootstrap e consultas vazias conferidos.
5. Manutenção: relatório, tabelas/scripts e plano/índice/roteiro atualizados.
   Bancos anteriores com hashes preservados, APKs restaurados, apps parados,
   hub/proxy encerrados e UFW inalterado. CP-10 permanece parcial e histórica.

## Resultado e interpretação

Recepção de B: 502024 → 736 bytes; ACK de B: 77027 → 209 bytes. Total do ciclo
A+B: 1159071 → 2275 bytes. Push: 737 bytes em ambos. Sem novidades, B recebeu
zero mudanças no incremental, mas ainda houve 372 bytes de corpos/metadados.
Sync de B: mediana 327,634 → 186,820 ms; mediana da redução pareada 42,781%.
Tempos mínimos/máximos, consulta sem novidades e reduções estão na tabela.

Seis pares em LAN não sustentam superioridade universal, significância ou cauda
estável. O bootstrap completo foi excluído; o hub ainda varre os vencedores e
mantém metadados sem GC. O cliente conserva sua persistência de snapshot local,
inclusive ao receber lote vazio. Não há nova avaliação de memória, energia ou
dos oito CRDTs. Testes offline são automatizados, não campanha de desconexão longa.

## Reprodução

Servidor, em `compass_app/server`:

```sh
dart analyze
dart test test/notes_incremental_test.dart --reporter expanded
```

Construir o entrypoint `app/tool/run_notes_distribution_comparison.dart` com os
configs do cofre em profile ARM64; `prepare.py` retém os comandos usados. Para
repetir no hardware, `command.json` registra os argumentos do controlador mantido
`app/tool/cp18_distribution_comparison.py`: usar saída nova, dados sincronizados
do cofre, seriais corretos, `--app-dir` e APKs anteriores de cada aparelho para
restauração. Os backups desta execução são os referidos no cofre CP-16; não
substituir APKs/dados pessoais sem preparar a preservação correspondente.
O parâmetro herdado `--cp14-device` aponta a inputs **sem pendências**, não à
fixture CP-14 com mil pendências. O controlador valida essa diferença.
`--count 1000 --pair-index 1` são argumentos de entrada herdados; os slots
0–6 e a alternância são controlados internamente na campanha. Não repetir o
comando sobre a saída histórica.

Análise na raiz DeltaSync, com cofre e diretório de saída novo:

```sh
python3 -m unittest discover -s plan/evidence/cp18 -p test_analysis.py -v
python3 plan/evidence/cp18/analyze_comparison.py <cofre-cp18> <saida-nova>
python3 plan/evidence/cp18/validate_results.py <cofre-cp18> <saida-nova>
```

Três casos conhecidos aprovados. Medianas/min/max e 12 diferenças/percentuais
de tempo conferidos com Decimal sobre inteiros brutos. Duas execuções produziram
sete arquivos idênticos. `analyze_comparison.py` rejeita campanha incompleta ou
com falha; não seleciona apenas ensaios rápidos. Checks de plano/links e diffs
dos dois repositórios foram executados após manutenção. Artigo externo não editado.
