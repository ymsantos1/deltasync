# Medições e histórico técnico

Este documento preserva as cargas, resultados e limites antes publicados no README.
São evidências históricas, não medições refeitas na reorganização R-35. Para uso
atual, consulte o [guia](guia-integracao.md) e a [referência técnica](referencia-tecnica.md).

### Medição de tamanho

`dart run example/measure_delta_size.dart` mede as quatro mutações offline acima
antes da reconexão: cada réplica altera um nome LWW e seu componente G-Counter.
Script fixa IDs, valores, quantidade e relógio HLC. Conta bytes UTF-8 de JSON
compacto: `DeltaCodec` para mudanças, `DeltaEnvelope` v2 para mensagem completa e
`Replica.toSnapshotJson()` para snapshot de cada réplica. Delta inclui metadados das
mudanças; envelope acrescenta versão, remetente e destinatário; snapshot inclui
estado materializado, clocks e metadados de réplica. Não inclui whitespace, gzip,
headers, protocolo ou armazenamento SQLite.

Resultado reproduzido duas vezes em Dart/Linux x64:

| Réplica | Mutações | Delta | Envelope | Snapshot |
|---|---:|---:|---:|---:|
| `shopper-a` | 2 | 454 B | 539 B | 627 B |
| `shopper-b` | 2 | 455 B | 540 B | 628 B |
| Total | 4 | 909 B | 1.079 B | 1.255 B |

Neste cenário, envelopes somam 86,0% dos snapshots separados (14,0% menos bytes).
Isso compara a soma das duas mensagens destinadas ao peer fixo com os dois estados
locais antes da reconexão. Resultado descreve apenas esse JSON, payload, valores e
implementação; não demonstra ganho geral nem estima tráfego comprimido ou de rede.

### Custo de contexto e outbox

`dart run example/measure_crdt_cost.dart` compara poucas mudanças em estado
grande com cargas desfavoráveis de MV-Register e OR-Set. O script fixa IDs,
valores, quantidades e HLC; executa mutações/commits por `SyncEngine` com
`SqfliteReplicaStorage` e SQLite FFI real. Um peer SQLite aplica o lote antes de
retornar ACK `appliedAndPersisted`. O resultado separa bytes JSON do delta,
envelope, snapshot e linhas da outbox com metadados, contagens causais, tamanho
do arquivo SQLite e tempos locais observados. Timestamps de criação da outbox e
tempos são gerados em runtime.

Procedimento reproduzível executado duas vezes em Linux x86_64, Dart 3.13.5,
12 processadores reportados. Cada linha usa banco novo. Tempos abaixo são a faixa
mínima/máxima observada entre as duas execuções, sem aquecimento controlado ou
repetições estatísticas; não são benchmark universal.

| Carga | Estado visível | Estrutura/outbox | Delta | Envelope | Snapshot | SQLite |
|---|---:|---:|---:|---:|---:|---:|
| G-Set: 250 valores existentes + 3 novas mudanças | 253 | outbox 1.176 B | 707 B | 809 B | 56.664 B | — |
| MV, N=4 | 1 versão; 4 context dots; 6 refs | 4 pendentes; outbox 1.807 B | 1.210 B | 1.287 B | 803 B | 24.576 B antes/depois do ACK |
| MV, N=8 | 1 versão; 8 context dots; 28 refs | 8 pendentes; outbox 4.525 B | 3.296 B | 3.373 B | 1.259 B | 32.768 B antes/depois do ACK |
| MV, N=16 | 1 versão; 16 context dots; 120 refs | 16 pendentes; outbox 12.922 B | 10.413 B | 10.492 B | 2.221 B | 40.960 B antes/depois do ACK |
| MV, N=32 | 1 versão; 32 context dots; 496 refs | 32 pendentes; outbox 40.930 B | 35.877 B | 35.956 B | 4.109 B | 86.016 B antes; 90.112 B depois do ACK |
| OR-Set: 8 ciclos add/remove + add final | 1 valor | 9 tags; 17 eventos; 8 refs observadas; outbox 7.305 B | 4.569 B | 4.661 B | 4.851 B | — |

Baseline anterior à R-19: refs MV confirmam `N(N−1)/2`: 6, 28, 120 e 496. O delta
pendente cresce mais rápido que o snapshot neste fluxo sequencial. ACK durável limpa 100% das linhas
da outbox; snapshot e contexto do MV permanecem iguais, pois ACK não apaga
conhecimento causal. OR-Set retém 17 eventos para um valor visível. No caso
favorável, três deltas/envelope custam 809 B diante de snapshot de 56.664 B;
outbox com metadados custa 1.176 B. Custos observados para outros casos seguem
carga e histórico. Esses valores preservam a medição anterior à compactação.

Após R-19, o mesmo comando, entradas, ambiente e SQLite FFI mediram:

| Carga | Dots lógicos/ref. | Unidades compactas | Delta | Outbox | Snapshot | SQLite antes/depois ACK |
|---|---:|---:|---:|---:|---:|---:|
| MV, N=4 | 6 | 3 | 1.112 B | 1.709 B | 542 B | 24.576/24.576 B |
| MV, N=8 | 28 | 7 | 2.220 B | 3.449 B | 542 B | 32.768/32.768 B |
| MV, N=16 | 120 | 15 | 4.525 B | 7.034 B | 552 B | 36.864/36.864 B |
| MV, N=32 | 496 | 31 | 9.085 B | 14.138 B | 552 B | 45.056/45.056 B |

Em N=32, delta caiu 74,7%, outbox 65,5% e snapshot 86,6% contra baseline;
os mesmos 496 dots lógicos continuam representados. Em N=16, delta caiu 56,5%
e outbox 45,6%. Tamanho SQLite inclui páginas e não mede espaço recuperável.

Faixa de `write-us` entre execuções: N=4 1.127–5.005; N=8 1.020–1.402; N=16
998–2.354; N=32 861–1.755. ACK: 16, 11, 18–19 e 29–30 ms, respectivamente.
Essas amostras pequenas variam e não sustentam comparação de desempenho entre
plataformas. O tamanho do arquivo SQLite inclui páginas/índices e pode crescer
após apagar linhas; não equivale a bytes de payload ou espaço imediatamente
recuperável. A execução não mede Android, compressão, rede, concorrência ou
cargas multi-peer.

Conclusão técnica: R-19 reduziu bytes MV nas cargas medidas, mantendo lacunas,
IDs da outbox e recuperação SQLite após fechamento/reabertura. R-19 segue COULD;
não muda o gate MUST. Medição limitada a Linux x86_64, Dart 3.13.5, SQLite FFI e
cargas fixas. VAL-05 foi revalidada após a mudança.

### Custos dos percursos locais

`dart run example/measure_core_paths.dart` executa cargas fixas e limitadas para
validação MV, validação JSON e consulta pontual em `ReplicaState`. O instrumento
conta expansão da view pública de contexto e leituras dos elementos JSON, não
alocações totais do heap. Os imports internos desse medidor servem à manutenção;
consumidores usam os contratos públicos documentados acima.

Em R-21, 20 validações de contexto com prefixo 5.000 e dois dots esparsos deixaram
de materializar 100.040 dots: o construtor de `MvRegisterDelta` já valida e guarda
o contexto isolado. A consulta pública `context` continua expandindo sob solicitação.
Validar 20 vezes um JSON com lista de 5.000 elementos passou de 200.000 para
100.000 leituras; o percurso de validação não constrói cópias JSON nem string
serializada. Cópia e validação compartilham regras de ciclos, chaves e números.

`ReplicaState[key]` agora lê e congela somente o campo solicitado; `values` mantém
a visão completa. Isso não elimina as cópias isoladas de candidata, adoção ou das
visões públicas de `SyncEngine.replica`/`Replica.state`. Tempos e ambiente antes/
depois estão em [execução R-21](../plan/TRACEABILITY.md#execucao-r-21-2026-10-13);
as cargas pequenas não sustentam promessa universal de desempenho.

## Esforço observado no Compass

Comparação mantém funcionalidade de notas, SQLite, UI e backend HTTP do VAL-13.
Contagem inclui imports, comentários e linhas vazias; não representa mínimo
necessário para integrar a biblioteca.

| Categoria | VAL-13 | Após R-24/R-25 |
|---|---:|---:|
| Inicialização/configuração Dart | 58 | 58 |
| Repositório de notas | 106 | 106 |
| Transporte HTTP | 83 | 72 |
| UI e encaixe na tela existente | 115 | 115 |
| Servidor Dart | 141 | 137 |
| Total de produção | 503 | 488 |
| Testes adicionais do consumidor | 410 | 435 |

Codec público eliminou 15 linhas de produção no consumidor. Consulta pontual
substituiu expressão com cópias por valueAt, sem reduzir linhas do repositório.
Biblioteca acrescentou 65 linhas de produção, incluindo documentação das duas
APIs; parsing e consulta passam a ter donos gerais, com regressões próprias.
Testes cresceram ao verificar ACK inválido por HTTP. Configuração Android,
dependências e documentação ficam fora desses totais.

Bootstrap, domínio, interface e canal real ainda exigem código próprio.
Após R-26, validação/commit/ACK ficam em receiveEnvelope; busca e ação de
sincronizar continuam no consumidor. R-27 oferece observações da sessão com os
mesmos resultados de push, commits e erros, sem duplicar estado persistido.
Esta comparação mostra manutenção e consumo; não mede tempo de integração de
terceiros, esforço acadêmico ou usabilidade com participantes.

R-26 reduziu a produção do consumidor para 479 linhas. R-27 acrescentou
assinatura e tratamento de observações: repositório 101 para 125 linhas, total
de produção novamente 503. O ganho desta etapa é reagir a commits externos
ao fluxo da tela sem polling, usando os contratos comuns. Não é redução de LOC.
As contagens anteriores da tabela são históricas, posteriores a R-24/R-25.
