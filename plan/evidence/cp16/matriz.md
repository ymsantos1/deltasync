# CP-16 — matriz definida para a série principal

Decisão de 2026-11-01; gate concluído em 2026-11-02. Este documento fixa a
**matriz de coleta**. APKs, fontes, configurações, scripts e lockfile foram
congelados antes da primeira rodada principal. Pilotos CP-15/R-44/R-45/R-46
e smokes CP-16 não entram na amostra principal.

## Amostra e ordem

| Bloco | Cargas | Condições | Repetições válidas | Aparelhos |
|---|---|---|---:|---|
| Série principal | 1 e 1.000 notas distintas | coletor ligado e desligado | 6 pares por carga | G52/API 33 e G53/API 34 |
| Curva exploratória já medida | 10 e 100 notas distintas | coletor ligado | 1 por carga | G52 e G53 |

Cada par principal contém uma rodada ligada e outra desligada com fixtures
independentes, mesmo N e mesmo procedimento. Nos pares ímpares, executar
ligado antes de desligado; nos pares pares, inverter. Em cada rodada, usar a
ordem A/G52, B/G53, A/G52. Um aquecimento por carga/condição antecede a
série, em fixture própria e fora da amostra. Intervalo mínimo: 5 s entre
fases e 30 s entre pares; manter USB conectado nas duas condições. Exigir
bateria inicial de pelo menos 40% e registrar o estado térmico antes de cada
condição. Se o estado térmico mudar dentro do par, invalidar o par completo.

## Trabalho medido

Profile ARM64, duas réplicas e hub local HTTP/SQLite com `--snapshot-pull`.
Cada fixture começa com N notas LWW distintas de 64 bytes e N pendências por
aparelho, preparadas por API pública fora da janela. Medir abertura/restauração,
uma edição de 64 bytes na chave ativa e sync. A segunda abertura de A mede o
pull após B, sem nova edição. Exportação, preparo, instalação e auditoria
ficam fora das janelas. Usar cópia fechada, namespace novo por par/condição,
hub novo e APK/config idênticos dentro de cada condição. Não repetir M1–M6,
C2/C3 nem introduzir rede degradada nesta série; CP-10 parcial é histórico
funcional, não amostra estatística.

## Aceitação e análise

Aceitar uma rodada só com N chaves e valores esperados, N−1 preservados após
edição, pendências zeradas após ACK, push/pull/ACK HTTP 200, convergência
integral A/B/hub e nenhum descarte/falha do coletor ligado. Conferir hashes
das fontes e bancos antigos. Reter toda tentativa, inclusive falhas e lentas;
registrar exclusão antes de calcular estatísticas. Falha de instrumento,
desconexão, mudança de APK/configuração ou estado térmico fora do limite
documentado invalida o par completo; nova tentativa usa namespace novo.

Reportar por aparelho, N, condição e etapa: tentativas, válidas, excluídas,
mediana, mínimo e máximo; comparar on/off por diferença pareada de tempo
externo do mesmo escopo. Calcular p95 descritivo por posição
`ceil(0,95 × n)`; com seis pares, ele é o máximo e **não** estima cauda estável.
Separar tempo interno/ADB, corpo HTTP/UID, snapshot/delta e PSS/heap. CPU/PSS
são do processo; UID curto pode não avançar. Métricas internas do coletor
desligado são ausentes, nunca zero. A curva N=10/100 permanece exploratória,
em build/coorte anterior, e não compõe a distribuição principal.

## Gate de congelamento cumprido

Bundle e revisão no registro CP-16 externo do Compass:
`../../../../samples_test_lib/compass_app/app/evidence/cp-16/README.md`.
Manifesto: `app/.performance-artifacts/cp-16/61c07bd14c2a401d9a1bd7c41218e2b9/manifest.json`,
SHA-256 `d21d29542d46d1761360b433fbf750aeb711f72b97236fcc368382de91debc1c`.
O verificador `verify_bundle.py` conferiu 126 arquivos, oito builds e 238 fontes.
O smoke final N=1.000 on/off passou nos dois Androids com capacidade 8.192 e
zero perda do coletor; N=1 também passou. Protocolos, configs, fixtures,
ambiente e tentativas falhas estão retidos. Mudança posterior inicia série nova.
CP-11 foi liberada, sem usar os smokes como amostra.

O instrumento externo `../../../../samples_test_lib/compass_app/app/tool/run_notes_scale_series.dart`
foi criado a partir do piloto sem alterá-lo. O controlador grava
`cp16-pair.txt` de forma atômica no diretório privado `databases` de cada
aparelho, com o mesmo ID hexadecimal de 32 caracteres para A/B no par. O app
rejeita ID ausente/inválido e usa nomes únicos para cópia e relatório. Build,
análise, 141 testes Flutter, smoke N=1/1000 e auditoria integral passaram.
O aquecimento e os 12 pares principais pertencem a CP-11.
