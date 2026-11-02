# CP-12 — análise da série CP-11

Concluída em 2026-11-02. Esta análise usa exclusivamente a coorte principal
[CP-11](../cp11/README.md), com fonte local corrigida R-44. A versão hosted
1.0.1 não contém essa correção. Pilotos e N=10/100 permanecem exploratórios.

## Resultado observado

Primeira abertura, **coletor desligado**, mediana de seis pares por célula,
em ms do Stopwatch do instrumento Dart ao redor da ação do repositório:

| Notas distintas | Aparelho | Restaurar | Editar uma nota | Sync inicial |
| --- | --- | ---: | ---: | ---: |
| 1 | G52 | 99,42 | 25,14 | 159,78 |
| 1 | G53 | 70,11 | 21,00 | 102,38 |
| 1000 | G52 | 775,31 | 163,03 | 3787,84 |
| 1000 | G53 | 505,30 | 99,76 | 3386,43 |

As [tabelas completas](results/tables.md) incluem on/off, segunda abertura de A,
mínimo/máximo/p95, CPU, PSS e rede. Os [valores por etapa](results/phases.csv)
permitem rastrear cada valor ao relatório bruto. Arredondamento aqui: três
casas nas tabelas completas e duas aqui; CSV preserva valores calculados sem
esse arredondamento de apresentação.

N cresce junto com o backlog inicial: N notas de 64 bytes e N pendências,
mais uma edição. O custo medido inclui adaptação do Compass, SQLite, replay,
status e transporte conforme a ação; não isola custo puro do core. Há aumento
observado de restauração, edição e sync entre os extremos. Duas cargas não
identificam uma curva de complexidade nem um limite máximo suportado.

No G52/N=1000, a mediana da diferença pareada do sync inicial (on−off) foi
**+493,562 ms**; no G53, **−188,963 ms**. Não há efeito uniforme que autorize
subtrair um custo fixo do coletor. Ordem, aparelho, histórico de instalação e
estado do processo podem influir. [Diferenças por par](results/paired.csv),
[resumo pareado](results/paired-summary.csv) e [separação por ordem](results/paired-by-order.csv)
retêm sinal e dispersão; cada ordem tem apenas três pares por carga/aparelho/etapa.

## Internet e recursos

No G52, primeira abertura/off, mediana do corpo do push: **1208 bytes** com
N=1 e **505523 bytes** com N=1000. Mediana do corpo recebido no pull:
**716** e **505022 bytes**, respectivamente. O push envia deltas do backlog;
o hub desta série responde ao pull com snapshot completo. Na segunda abertura
de A/N=1000/off, o pull ainda recebeu **502022 bytes**, após a edição remota.
Isso caracteriza este protocolo/configuração, não sync incremental ideal de
uma única edição. [Rede por rota](results/network-summary.csv) separa TX/RX,
ACK, push, pull e duração do proxy.

Bytes HTTP são corpos JSON, sem cabeçalhos/TCP/TLS e sem equivalência com
bytes tarifados. UID cobre todo tráfego do próprio UID em outra fronteira de
amostragem. Em N=1/off, os contadores UID não avançaram nas janelas de sync
dos dois aparelhos, apesar de haver HTTP confirmado. Zero nesse contador não
significa ausência de rede; os corpos HTTP são a evidência direta do payload.

CPU é diferença de tempo acumulado do processo, incluindo suas threads,
não percentual de utilização. PSS é memória proporcional do processo,
não heap Dart nem memória atribuível à biblioteca. **Todos os 192 pares de
leituras PSS antes/depois foram iguais dentro da etapa.** A API
[ActivityManager.getProcessMemoryInfo](https://developer.android.com/reference/android/app/ActivityManager#getProcessMemoryInfo(int%5B%5D))
limita frequência desde Android Q e pode repetir a amostra anterior. Essa
limitação torna inadequado inferir crescimento ou pico por ação a partir
destes valores; as leituras observadas permanecem nas tabelas. Heap Dart e
energia não foram medidos. O tempo de inicialização via ADB não foi retido
com fronteira final suficiente; timestamps host/device permanecem separados
em [timeline](results/timeline.csv), sem subtrair relógios diferentes.

## Amostra, exclusões e validade

Planejados 12 pares principais; tentados 13; válidos 12; excluído um no
preflight N=1/par 5, antes de qualquer fase medida. Dois pares de aquecimento
não participam da análise. Para cada carga/condição/aparelho há seis pares
válidos; A produz first/second e B apenas first. [Cobertura](results/coverage.csv)
separa os 72 relatórios de fase das 192 etapas e das operações internas.
A exclusão sem condição iniciada não foi atribuída artificialmente a on/off.

p95 usa posição `ceil(0,95 × n)`: com seis valores é o máximo descritivo.
Não há estimativa estável de cauda, intervalo de confiança ou teste de
significância. A/B são papéis fixos, não réplicas intercambiáveis: B recebe
estado de A; a segunda abertura de A não tem nova edição nem o mesmo backlog.
Não agrupar essas etapas como repetições equivalentes.

Limites: dois modelos Android, LWW, profile ARM64, LAN com hub/proxy local,
snapshot pull, USB e automação ADB. N=1 foi coletado antes de N=1000;
condições alternaram, cargas não foram randomizadas. Houve reconexão entre
pares N=1 e diálogos Play Protect durante instalações fora das janelas,
com upload recusado. Os pares já válidos foram preservados; a retomada usa
novo namespace. Não extrapolar para oito CRDTs, WAN, UI com mil reservas,
edição de todas as notas, desligamento do processo sob falha ou consumo de energia.

## Reprodução, revisão e validação

Na raiz DeltaSync, com o cofre CP-11 identificado no registro:

```sh
python3 -m unittest discover -s plan/evidence/cp12 -p 'test_analysis.py' -v
python3 plan/evidence/cp12/analyze.py <cofre-cp11> <diretorio-novo>
python3 plan/evidence/cp12/validate_results.py <cofre-cp11> <diretorio-novo>
```

O script verifica manifesto e todos os 448 inputs por hash e executa auditor
CP-11 antes de calcular. Mediana usa observações por par; diferença pareada
é calculada antes de resumir, não como diferença entre medianas. Métricas
ausentes não viram zero. Etapas aninhadas do coletor não são somadas.
[Manifesto da análise](manifest.json) registra hashes de scripts, testes,
tabelas e metadados e o hash da entrada.

Leitura: dependência, matriz, instrumentação Kotlin/Dart e exclusões conferidas.
Implementação: scripts e tabelas reproduzíveis; nenhuma coleta nova ou mudança
no app/lib. Review próprio: conferidos pareamento, ordem, relógios, unidades,
cardinalidade/backlog e limites PSS/UID; revisão não independente. Validação:
seis casos conhecidos, 32 grupos de duração e 16 grupos de diferenças
conferidos diretamente nos microssegundos brutos com Decimal; reprodução
completa gerou arquivos idênticos. Manutenção: critérios e índice atualizados,
CP-13 pronta; checker e diff verificados.
