# Protocolo de testes de desempenho no Compass

Data inicial: 2026-10-31. Atualização de preparação: 2026-11-01.
Estado: instrumentação, sessões e builds validados em CP-01–CP-09, com provas
funcionais em host e piloto físico M1–M6 nos dois Androids, por ADB autorizado.
CP-10 aceitou um ciclo completo com uma nota; as repetições restantes foram
interrompidas. CP-14 prepara populações de 1, 10, 100 e 1.000 notas distintas.
A série principal e seu número de rodadas dependem do piloto de escala e do
congelamento em CP-16.
Em 2026-11-01, o autor autorizou planejar e iniciar a coleta automatizada.
A seção 9 orienta a série principal; as instruções manuais anteriores
continuam disponíveis como alternativa, com séries identificadas separadamente.

Atualização autorizada em 2026-11-01: durante CP-07, o autor pediu que o agente
fizesse a validação com ADB. O piloto funcional M1–M6 pode ser automatizado nos
dois aparelhos físicos, registrando comandos, intervalos e interferência de
ADB/USB/acessibilidade. Esses resultados verificam preparação e comportamento;
não integram a série principal manual nem a futura coleta final.
Comparação ligada/desligada nesse diagnóstico conserva mesma carga e sequência
de ações, sem presumir custo zero do controlador ou subtrair constante.

## 1. Objetivo e perguntas

Avaliar desempenho e consumo de dados da DeltaSync durante uso das notas de
viagem do Compass em Android físico, com persistência SQLite. Responder:

1. Quanto custam commit local e atualização do fluxo do consumidor?
2. Como esse custo varia com tamanho do texto e quantidade de edições pendentes?
3. Quanto demora sincronizar e quantos bytes são trocados nos dois sentidos?
4. Edição continua disponível quando a sincronização falha?
5. Quais atividades Dart, memória e quadros lentos aparecem nas rodadas diagnósticas?

O resultado será um estudo de caso das notas LWW, complementar aos testes gerais
dos oito CRDTs. Este protocolo não amplia o gate acadêmico nem autoriza alterações
da biblioteca. Usar as [medições locais](medicoes.md), a
[baseline R-32](../plan/evidence/r32/README.md) e a
[VAL-15](val15-dois-dispositivos.md) como contexto, sem tratar execuções antigas
em debug/USB como resultados atuais de desempenho.

## 2. Implementação inspecionada

Consulta local, somente leitura, em
`/projetos/tcc/samples_test_lib/compass_app`. Repositório samples_test_lib:
`07fb9407252f5ac97b6a92d8f0cc9fdacd78a0b0`, sem alterações locais na consulta.
A tabela abaixo preserva a baseline anterior a CP-01–CP-06. Ela não descreve
as alterações posteriores. Registrar revisão, alterações locais e hashes antes
de cada execução; o plano canônico do consumidor registra a preparação atual.

Os caminhos da tabela são relativos a compass_app. São referências de localização
no consumidor externo, não arquivos distribuídos por esta biblioteca.

| Fonte | Comportamento que define o ensaio |
|---|---|
| `app/lib/main_deltasync.dart` | Inicializa sqflite, NotesConfiguration, transporte e SyncEngine.withStorage; aguarda repository.start antes de runApp; usa providersLocal |
| `app/lib/data/services/notes/notes_configuration.dart` | Lê REPLICA_ID, PEER_ID e NOTES_URL; URL padrão é http://127.0.0.1:8091; nome do banco depende da réplica |
| `app/lib/data/repositories/notes/trip_notes_repository.dart` | edit chama engine.setDelta e depois _refresh; sync executa push(force: true), pull e receiveEnvelope |
| `app/lib/ui/booking/widgets/trip_notes_card.dart` | Campo Nova nota e botões Salvar no dispositivo e Sincronizar notas; apresenta nota persistida, pendências e erros |
| `app/lib/data/services/notes/http_notes_transport.dart` | Usa dart:io HttpClient, JSON e rotas /sync/push, /sync/pull e /sync/ack |
| `server/bin/notes_server.dart` | Hub SQLite/FFI, no máximo dois clientes; --snapshot-pull exporta estado LWW materializado |
| `app/android/app/src/{main,profile,debug}/AndroidManifest.xml` | INTERNET em profile/debug; usesCleartextTraffic=true somente em debug; main não declara INTERNET |
| `app/pubspec.yaml`, `server/pubspec.yaml` e workspace samples_test_lib | Consumo por path, com overrides internos no workspace; não comprova instalação hosted |

A chave é formada por `trip-notes:` mais JSON de destino, data inicial e data
final. O valor LWW é `{'text': text}`. Dois clientes devem abrir viagens com
esses três componentes iguais; igualdade do número local da reserva não basta.

O fluxo inspecionado separa salvar de sincronizar. Não há polling ou retry de
rede periódico nesse recorte: `incoming` é vazio e a pessoa solicita cada sync.
As notificações da engine disparam consultas locais de pendências; não são
requisições ao servidor. Na baseline, `_refresh()` usava `pendingDelta().changes.length`:
essa era a implementação da baseline. CP-03 substituiu a consulta por
`pendingSummary` por peer e reuniu refreshes concorrentes; CP-02 separou commit
de falha de status. Declarar essas revisões e não misturar implementações na
mesma série. CP-04 preparou rede de profile, CP-05 adicionou o coletor e CP-06
adicionou sessões, corpus e exportação. Consulte os procedimentos atuais:
[plano do consumidor](../../samples_test_lib/compass_app/app/PLANO_DELTASYNC_1_0_1.md),
[coleta](../../samples_test_lib/compass_app/app/docs/coleta-desempenho.md),
[sessões](../../samples_test_lib/compass_app/app/docs/sessoes-ensaio.md) e
[rede](../../samples_test_lib/compass_app/app/docs/rede-ensaio.md).

Na sincronização com pendências, o percurso é:

1. `POST /sync/push`; hub aplica/persiste antes de retornar ACK de IDs.
2. `GET /sync/pull?recipientReplicaId=...`; hub exporta estado materializado.
3. `receiveEnvelope` aplica/persiste localmente e envia `POST /sync/ack`.

A etapa 3 foi conferida também na implementação atual de
`SyncEngine.receiveEnvelope` da biblioteca. Sem pendências, a engine pode
omitir o POST de push, mas o repositório ainda solicita pull. Registrar o tráfego
real; uma sincronização ociosa não significa necessariamente zero bytes.

O push pode estar confirmado e a outbox vazia mesmo se o pull ou seu ACK falhar.
Logo, zero pendências não prova sucesso do ciclo inteiro nem convergência do
outro cliente. No modo snapshot-pull, ACK de pull não apaga uma fila global do hub.

## 3. Condições para iniciar a coleta

- Reservar dois dispositivos e gerar configurações conforme o guia de sessões.
  IDs local/peer devem começar por compass-ensaio- para habilitar os controles.
  Manter cada identidade/banco no mesmo aparelho; não apagar bancos reais nem
  clonar réplicas. Os exemplos antigos perf-* não habilitam o ensaio atual.
- Registrar modelos, Android/API, Flutter/Dart, revisões, hashes de APK e fontes,
  versão resolvida dos pacotes, endpoint, configuração do hub e variante.
  O lockfile observado fica na raiz samples_test_lib, não em compass_app/app.
  CP-01 resolveu o lock antigo de 2.0.0 para 1.0.1. Conferir novamente os
  pacotes efetivamente resolvidos antes de cada build, sem usar somente a
  versão declarada ou o estado histórico como prova da versão testada.
- Usar profile para a série principal e para DevTools, conforme a
  [orientação Flutter](https://docs.flutter.dev/perf/ui-performance).
  Eventual série release deve ficar separada, com os mesmos cenários.
- Fixar brilho, taxa de atualização, orientação e teclado. Registrar bateria,
  carregamento e temperatura disponível; aguardar resfriamento entre blocos.
  Manter apps concorrentes e carga do host do servidor controlados.
- Preparar rede real entre app e hub: ADB e adb reverse não participam da coleta.
  Para Wi-Fi, endpoint deve usar IP acessível do host; loopback padrão não serve.
  Internet móvel exige endpoint acessível por essa rede. Relatar LAN como LAN.
- Conferir a configuração de profile preparada em CP-04: URI e host no XML
  precisam coincidir. Mudança de host exige novo build/inspeção. A política
  Android não é firewall para sockets Dart; TLS depende de terminação externa.
- Habilitar NOTES_PERFORMANCE=true com IDs dedicados e usar o painel Ensaio
  de CP-06. Salvar/exportar depois da janela e conferir a cópia recebida. Sem
  opt-in não há painel nem métricas do coletor.
- Após preparar o consumidor, executar análise/testes do app e servidor e conferir
  build e percurso funcional no aparelho antes de medir. Registrar comandos e
  resultados reais; a consulta de fontes deste documento não valida esses checks.
- Abrir a mesma viagem nos dois aparelhos e aguardar carregamentos de imagens,
  fontes e caches. providersLocal não elimina imagens remotas. Congelar esse
  preparo; contar separadamente tráfego total do app e tráfego das notas.

Preparação em compass_app/app, fora da janela, com pasta nova:

```sh
python3 tool/prepare_notes_fixture.py --output /tmp/compass-piloto-c1-novo --load C1
```

O fixture.json gerado contém serverCommand/serverWorkingDirectory, banco novo
e dois clientes com --snapshot-pull. Não inicia servidor nem verifica seu estado.
Capture revisão/hash e GET /state externamente antes das edições. O endpoint
padrão é http://192.168.3.10:8091; ajuste URI e XML juntos quando necessário.
Build de alpha em compass_app/app:

```sh
flutter build apk --profile --target lib/main_deltasync.dart --dart-define-from-file=/tmp/compass-piloto-c1-novo/alpha.json
```

Guardar artefato/hash de alpha antes de gerar beta pelo beta.json, pois o caminho
de saída é o mesmo. Instalação/preparo podem usar cabo ou transferência manual
fora da coleta. Configuração, hashes e execução efetiva pertencem ao registro
da tarefa; estes exemplos não certificam instalação em aparelho físico.

## 4. Métricas e pontos de instrumentação

Os pontos abaixo orientaram CP-05/CP-06. O contrato efetivo e seus limites estão
na documentação de coleta do consumidor. Usa relógio de tempo decorrido, como
[Stopwatch](https://api.dart.dev/dart-core/Stopwatch-class.html), com unidade µs.

| Métrica | Início e término | O que inclui |
|---|---|---|
| Commit local | Antes de engine.setDelta até retorno/falha, dentro de edit | Persistência/adoção local pela API pública; exclui _refresh posterior |
| Edição no repositório | Entrada em edit até seu retorno/falha | Commit e _refresh; a nota pode estar persistida se apenas _refresh falhar |
| Restauração | Antes/depois de engine.start, dentro de repository.start | Restauração da engine; medir repository.start separado, pois também consulta pendências |
| Push confirmado | Antes/depois de engine.push(force: true) | Preparo, envio e confirmação durável dos IDs retornados |
| Pull recebido | Antes/depois de transport.pull | Requisição e decodificação do envelope |
| Aplicação e ACK de pull | Antes/depois de engine.receiveEnvelope | Commit remoto local e envio do ACK pelo transporte |
| Ciclo completo | Entrada em repository.sync até retorno/falha | Push, pull, aplicação/ACK e _refresh final; exclui tempo humano entre botões |
| Quadros | FrameTiming nas janelas identificadas | buildDuration, rasterDuration e totalSpan, sem confundir com tempo do commit |

As observações de commit/push já disponíveis ajudam a conferir IDs e resultados,
mas não substituem os limites acima. Algumas consultas por observações são
assíncronas; conservar o agrupamento por operação e esperar estabilização antes
de iniciar a próxima. Se o commit já ocorreu e uma consulta falhou, não repetir
a edição para corrigir apenas a indicação da UI.

Para quadros sem DevTools conectado, a preparação pode usar
[SchedulerBinding.addTimingsCallback](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html).
O callback entrega lotes: associar os timestamps dos frames à janela da operação,
não o instante de chegada do lote. Registrar taxa de atualização e orçamento
por frame. Ele não fornece sozinho o instante exato em que a nota salva foi
fisicamente exibida; não chamar totalSpan de latência de commit ou toque.

### Tráfego

Instrumentar `HttpNotesTransport.request`, preservando seu comportamento:

- Contar bytes UTF-8 do corpo enviado e dos dados de resposta, inclusive erros,
  ACKs e novas tentativas. Reutilizar serialização existente, sem duplicar JSON.
- Separar método/rota, status, direção, tentativa e operação. Explicitar se a
  contagem da resposta é antes/depois de descompressão; headers, TLS e
  retransmissões TCP não entram automaticamente no tamanho do JSON.
- Registrar requisição incompleta e bytes parciais quando disponíveis, sem
  convertê-los em sucesso ou zero. HttpClient tem connectionTimeout de 2 s e
  timeouts de 5 s em etapas distintas; 5 s não é limite total garantido do sync.
- Para tráfego do processo, ler
  [TrafficStats](https://developer.android.com/reference/android/net/TrafficStats)
  do UID do próprio app no início/fim da janela. Desde Android N, essa API não
  permite a outro UID consultar esses contadores. Guardar delta Tx/Rx, canal e
  indisponibilidade; não transformar UNSUPPORTED em zero.

TrafficStats agrega interfaces/serviços do UID; não separa sozinho Wi-Fi de móvel
nem notas de imagens. Desativar canais alternativos quando necessário e registrar
o canal efetivo. Não subtrair automaticamente o tráfego ocioso como custo exato.
Não alegar redução de internet comparando apenas JSON de deltas com snapshots.

### Memória e CPU

A coleta principal registra tempos, corpos HTTP, tráfego por UID e, se preparado,
FrameTiming local. Ela não precisa de DevTools, logcat ou ADB conectados.

Em rodadas manuais separadas, usar [CPU profiler](https://docs.flutter.dev/tools/devtools/cpu-profiler)
e [Memory view](https://docs.flutter.dev/tools/devtools/memory) para investigar
o mesmo cenário em profile. CPU profiler amostra stacks Dart; não é percentual
global de CPU. Heap Dart não é PSS/RSS do processo. Snapshots de heap e coleta
conectada têm custo e não devem integrar a série principal de latência/bytes.
PSS por dumpsys, se desejado, pertence a diagnóstico separado com ADB declarado.

Na rodada de CPU, abrir o profiler, iniciar Record, executar manualmente M2 ou M5,
parar com Stop e exportar a captura. Conservar o mesmo tamanho de carga e observar
stacks de mutação, serialização e consultas, sem atribuir toda atividade à lib.
Na rodada de memória, registrar heap antes da carga, depois dela e depois do
mesmo período ocioso. Para investigar retenção, comparar snapshots sob a mesma
política de GC, explicitando qualquer coleta forçada. Uma elevação isolada de
heap não prova vazamento. Exportar cada diagnóstico com o run_id correspondente.

## 5. Cargas e preparação de cada rodada

Começar com uma viagem compartilhada e reescritas da sua nota. Não exigir criar
100 reservas manualmente para representar 100 edições pendentes.

| Carga | Texto por edição | Salvamentos antes de sincronizar |
|---|---|---:|
| C1 | 64 B ASCII | 10 |
| C2 | 64 B ASCII | 100 |
| C3 | 1.024 B ASCII | 10 |

Preparar textos fora da janela: prefixo A001- seguido de 59 caracteres x totaliza
64 B; para 1.024 B, usar 1.019 caracteres após o mesmo prefixo. Incrementar número
por edição; beta usa B001-. Não usar texto idêntico em todas as edições. Registrar
tamanho do JSON inteiro e do estado; bytes do texto não são bytes do protocolo.

Texto pode ser colado manualmente, sempre com o mesmo mecanismo. Intervalo de
digitação/colagem fica fora do commit. Salvar apenas depois de terminar a entrada;
aguardar nota/pendências estabilizadas antes da próxima ação. Definir intervalo
manual mínimo no piloto e registrar o realmente usado.

A UI não fornece reset de fixtures. O gerador prepara identidades e caminho de
hub novos, sem apagar bancos. Para amostras independentes, comprovar externamente
estado/outbox conhecidos dos dois lados. Não presumir que apagar o texto ou zerar pendências restaure
histórico/metadados. Sem fixture reproduzível, tratar a sequência como estudo
longitudinal de estado crescente, não como repetições independentes da mesma carga.

## 6. Execução manual dos cenários

Antes de cada rodada, registrar run_id, carga, estado inicial, pendências,
temperatura disponível e canal. Iniciar registro local preparado no consumidor.
Desconectar diagnóstico/ADB e usar somente a interface. Não gravar tela durante
a série principal. Exportar registros e capturar comprovações depois da janela.

### M1 — Ocioso e sincronização sem alterações

1. Abrir a viagem, com pendências zeradas e conteúdo já estabilizado.
2. Na sessão M1 ociosa, aguardar 60 s sem editar ou sincronizar; encerrar e salvar.
3. Iniciar outra sessão M1, tocar Sincronizar notas uma vez, aguardar e salvar.
4. Relacionar ambos os run_id às etapas no manifesto externo; uma única janela
   agregada não separa bytes UID ociosos e de sync retroativamente.
   Conferir pull/ACK mesmo sem novo push.

### M2 — Edição local com rede disponível

1. Com hub acessível, digitar/colar primeiro texto e tocar Salvar no dispositivo.
2. Conferir Nota salva no dispositivo e aumento esperado de Pendentes de notas.
3. Repetir até completar C1. Não tocar em Sincronizar notas entre salvamentos.
4. Conferir que salvar não enviou notas automaticamente. Medir commit e edit.

### M3 — Edição offline e tentativa de sincronização

1. Tornar endpoint indisponível fora da janela local; confirmar que outro canal
   não mantém acesso. Pode-se desligar Wi-Fi/dados no aparelho ou parar o hub de
   ensaio. Registrar qual falha foi produzida; servidor parado não é perda de pacotes.
2. Salvar textos distintos até completar a carga; confirmar edição local.
3. Tocar uma vez em Sincronizar notas e aguardar sucesso inesperado ou erro.
4. Registrar duração/etapa da falha. Salvar outra versão depois dela, comprovando
   continuidade da edição. Esse salvamento extra entra na contagem da rodada.

### M4 — Reinício com pendências

1. Partir de M3 com quantidade de pendências e nota final conhecidas.
2. Com coleta ligada, tocar Encerrar e salvar, aguardar confirmação e tocar
   Preparar reinício M4. O arquivo anterior precisa estar salvo no dispositivo.
3. Usar Configurações do Android, aplicativo Compass, Forçar parada; não limpar
   dados. Apenas remover dos recentes não garante encerramento do processo.
4. Reabrir pelo ícone e voltar à mesma viagem. Com coleta ligada e M4 armado,
   o bootstrap salva a restauração vinculada à anterior antes de exibir a UI.
   Com coleta desligada, conferir persistência pelos observáveis comuns do piloto;
   não esperar arquivo ou tempo interno do coletor.
5. Conferir nota, pendências e arquivos preservados. Usar medida local de engine.start;
   não incluir navegação humana. Forçar parada não simula queda de energia.

### M5 — Reconexão e confirmação

1. Restaurar acesso ao mesmo hub/banco, fora da janela de sync.
2. Tocar Sincronizar notas uma vez no aparelho A e aguardar término.
3. Conferir IDs confirmados, nota no hub e pendências do lote removidas.
4. Sincronizar B para buscar o estado; verificar a mesma nota relevante.
5. Separar duração de sync de A, sync de B e pausas humanas entre eles. Não
   subtrair timestamps de relógios diferentes nem reportar a soma como propagação automática.

### M6 — Edições concorrentes e convergência

1. Com viagens/chaves iguais e sem rede, salvar uma versão distinta em A e B.
2. Reconectar e sincronizar A, B e A, nessa ordem, sem novas edições.
3. Conferir vencedor LWW igual nos dois e confirmação dos IDs de cada cliente.
4. Não exigir que A ou B ganhe antecipadamente: relógios/ordem LWW decidem.
   Conferir que confirmar A não limpa pendências de B.

M1 a M6 são o conjunto principal. C2/C3 aprofundam M2, M3 e M5 após piloto.
Timeout, HTTP de erro, banda reduzida e perda de pacotes são experimentos
distintos. Qualquer rodada de rede degradada exige parâmetros no gateway/proxy
e registro do alcance; pausas manuais não simulam latência de rede.

## 7. Repetições, análise e arquivos

Executar primeiro um piloto curto com N=1 e N=1000 em cada aparelho. Usar seus
tempos, dispersão e falhas para justificar as condições, aquecimentos, repetições
e duração total antes da série principal; registrar tudo em CP-16. Trinta rodadas
por condição não são requisito automático. Aquecimento não garante cache uniforme;
reinício de processo não limpa cache do SO. Alternar a ordem das condições.

Conservar amostras brutas e agrupamento por rodada. Reportar mediana, mínimo,
máximo e p95 por aparelho/carga/intervalo; não misturar falhas com sucessos.
Declarar o método de p95, por exemplo posição ceil(0,95 × n) na série ordenada:
com dez rodadas, equivale ao máximo. Declarar a incerteza conforme o tamanho real
da amostra.
Publicar erros, timeouts e exclusões justificadas, sem apagar amostras lentas.

Conferir `droppedSamples`, `droppedWindows` e `collectorFailures` antes de
calcular estatísticas. O buffer padrão retém 2.048 amostras e 16 janelas,
removendo as mais antigas. O piloto físico por ADB atingiu esse limite no G53;
seus arquivos truncados foram preservados e excluídos da análise de tempos.
Não apresentar a cauda retida como todas as operações da rodada. Antes da série
principal, executar um ensaio manual da carga escolhida e confirmar retenção
completa. Se necessário, ajustar janela ou capacidade antes da série, registrar
o compromisso de memória e revalidar os artefatos; não misturar configurações.
Uma comparação externa on/off pode continuar válida com métricas internas
truncadas, desde que as duas bordas, a carga e os commits sejam comprovados.

Guardar os artefatos da futura execução junto a [TRACEABILITY](../plan/TRACEABILITY.md):
manifesto de ambiente, lockfile resolvido, hashes, configuração do hub/canal,
cargas e textos, amostras, diagnósticos e comprovantes funcionais. Estrutura mínima:

```text
run_id, aparelho, revisao_app, revisao_lib, variante, cenario, carga,
repeticao, coleta_ativa, canal, chave_viagem, pendencias_antes,
operacao_id, etapa, duracao_us, tx_corpo_B, rx_corpo_B, tx_uid_B,
rx_uid_B, resultado, timeout, motivo_exclusao, artefato
```

Nunca usar zero para métrica ausente. Exportar após a janela pelos arquivos e
compartilhamento de CP-06. Salvar e armar M4 antes de Forçar parada; RAM não
sobrevive ao encerramento do processo. Interrupção sem salvar registra
metrics=null e motivo explícito, sem inventar amostras recuperadas.

No piloto ligado/desligado, manter mesma carga, configuração e política de
preparação, alternar a ordem e registrar estado inicial/histórico crescente.
NOTES_PERFORMANCE=false remove painel e métricas de etapas/UID/frames; ausência
não é zero. Comparar somente medidas disponíveis nas duas condições pelo mesmo
diagnóstico externo em séries separadas, com interferência declarada. Não inferir
custo do coletor comparando tempos de ligado com dados ausentes em desligado.
Sem medida comparável, a interferência permanece pendente mesmo com dois builds.

Uma rodada tem sucesso funcional quando os commits esperados persistem,
pendências/ACKs pertencem ao destinatário correto e o cenário converge quando
aplicável. Se o push foi confirmado mas o pull falhou, reportar ambos os fatos.
Sem limite temporal justificado antes da execução, relatar desempenho observado,
não certificar aceitabilidade universal.

## 8. Referências e limites das ferramentas

- [Flutter: profiling em aparelho físico/profile](https://docs.flutter.dev/perf/ui-performance):
  orienta variante e diagnóstico; não substitui controle da carga.
- [Dart: Stopwatch](https://api.dart.dev/dart-core/Stopwatch-class.html) e
  [Flutter: FrameTiming local](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addTimingsCallback.html):
  viabilizam instrumentação com ações manuais, sem coordenador ADB na janela.
- [DevTools: CPU](https://docs.flutter.dev/tools/devtools/cpu-profiler),
  [memória](https://docs.flutter.dev/tools/devtools/memory) e
  [rede](https://docs.flutter.dev/tools/devtools/network): rodadas diagnósticas;
  o transporte dart:io do Compass é compatível com a captura de rede descrita.
- [Android: TrafficStats](https://developer.android.com/reference/android/net/TrafficStats):
  contadores do UID, diferentes de payload JSON e da fatura da operadora.
- [Macrobenchmark](https://developer.android.com/topic/performance/benchmarking/macrobenchmark-overview?hl=pt-br):
  referência para ensaios Android de jornadas/inicialização próximos de produção;
  opcional e separado da série manual aqui definida.
- [Flutter: integração com timeline](https://docs.flutter.dev/cookbook/testing/integration/profiling):
  alternativa futura automatizada, não mecanismo desta coleta manual.
- [Android: ADB](https://developer.android.com/tools/adb) e
  [dumpsys](https://developer.android.com/tools/dumpsys): preparo ou diagnóstico
  separados; custo de instrumentação e comunicação não é presumido zero.

Este documento especifica o protocolo. Os resultados executados estão nos
registros ligados ao final; consultar referências não substitui evidência runtime.

## 9. Coleta automatizada autorizada

Planejamento e critérios ficam na fase CP-08–CP-16 do
[plano canônico](../../samples_test_lib/compass_app/app/PLANO_DELTASYNC_1_0_1.md#fase-de-coleta-automatizada--cp-08-a-cp-13).
As 24 sessões CP-07 permanecem um piloto funcional histórico. CP-11 concluiu
a série principal de escala em 2026-11-02; CP-12 concluiu sua análise.

### Método e matriz fixados para preparação

Usar profile nos Moto G52/G53 físicos, mesmo app/SDK/liberação local da biblioteca
1.0.1, LAN Wi-Fi com hub de dois clientes, identidades novas por conjunto e mesma
viagem. Preservar a instalação normal. ADB/USB conduzem a UI e estão presentes
na coleta; registrar sua interferência e mecanismo de entrada de texto.
Não subtrair tempo constante de ADB nem cronometrar a biblioteca pelo shell.
Commit/sync usam intervalos internos existentes; CPU/PSS são observáveis do
processo nas bordas. Não executar profiler adicional na série principal.

| Bloco | Carga | Repetições por aparelho | Observação |
|---|---|---|---|
| Calibração | C1, M1–M6 | Três ciclos | Fora da série principal; fixar capacidade/ritmo e comprovar retenção |
| Série principal | C1, M1–M6 | Dois aquecimentos e 30 ciclos medidos | M1 ocioso ≥60 s e sync em janelas separadas; M3–M4–M5 vinculados |
| Comparação de instrumentação | M2/C1 on/off | Dois aquecimentos e 30 duplas medidas | Mesmo controlador/observáveis externos, ordem alternada |
| Extensão exploratória | C2/C3 | A definir antes de executar | Só após a série C1; exige calibração própria, sem alegar coleta já autorizada/concluída |

Os números são escolhas metodológicas deste estudo, não exigências das fontes.
Um ciclo combina janelas de cenários; não é uma repetição independente de estado
vazio. C1 continua dez salvamentos de 64 bytes; o commit adicional após falha
em M3 deve ser declarado à parte. M6 usa edições concorrentes nos dois aparelhos.
Alternar qual cliente sincroniza primeiro. Registrar IDs antes/depois e comparar
LWW/vencedor com ambos os clientes/hub; zero pendências sozinho não basta.

A execução medida de um aparelho por vez reduz disputa do host. Sincronizar a
coordenação necessária a M6 e declarar qualquer sobreposição. Preservar estado
crescente e limpar pendências somente pelo fluxo normal documentado, fora da
janela quando se tratar de preparo; nunca apagar SQLite para uniformizar estado.
Fixtures de calibração e da série usam namespaces distintos. Não reutilizar a
fixture CP-07 nem renomear réplica existente para iniciar uma série nova.

### Retenção, congelamento e aceitação

CP-08 expõe capacidade configurável no build; 8.192 é um valor inicial candidato
para calibração C1, não capacidade global validada para toda a matriz. CP-10
registra a configuração da base de uma nota. Após a ampliação autorizada para
escala, CP-16 congela capacidade, ritmo/entrada de texto, resfriamento, ordem,
APKs, fontes/lock e métricas depois de CP-14/CP-15. Buffer maior aumenta memória
e custo do próprio instrumento;
medir PSS e manter a mesma configuração durante a série. Não misturar dados dos
APKs CP-07 com a série nova nem aumentar capacidade no meio dela.

Antes de aceitar uma rodada, verificar contadores de perdas/falhas do coletor
iguais a zero, todas as operações esperadas, ausência de queryError/troca de
viagem, limites de janela, JSON/recibo e estado persistido. Frames possuem cauda
aproximada já declarada; ausência de descarte não torna callbacks perfeitos.
Guardar todas as tentativas e seus motivos. Rodada incompleta/truncada fica
excluída das estatísticas que exigem retenção completa; não eliminar apenas
resultados lentos nem substituir ausentes por zero.

Preparo de hub e conexão LAN deve ser conferido novamente: os recursos e regras
temporárias CP-07 foram encerrados/removidos. Se o host exigir autenticação local,
registrar a dependência sem solicitar senha. Exportar depois de encerrar a janela.
Não haverá rede reversa por ADB no experimento de consumo de internet.

### Análise e relato

Usar rodada como unidade de agrupamento. Reportar n planejado/tentado/válido/
excluído, mediana, mínimo, máximo e p95 pelo método já definido na seção 7.
Manter sucessos/falhas e aparelhos separados; não somar operações aninhadas.
Relatar pares on/off com ordem/histórico e valores brutos. NOTES_PERFORMANCE
também controla painel/coordenador: comparação não isola apenas amostragem.
Processo/PSS, corpo HTTP e UID têm escopos distintos; não extrapolar para heap
Dart, bytes tarifados, redes móveis ou desempenho geral dos oito CRDTs.

Automação é suportada no [guia Flutter de testes de desempenho](https://docs.flutter.dev/cookbook/testing/integration/profiling).
O [guia de profiling Flutter](https://docs.flutter.dev/perf/ui-performance) orienta
uso de profile e aparelhos físicos. O estudo reutiliza controles/coletor locais
e o piloto ADB existente; a referência não significa que integration_test já foi
implementado. [Macrobenchmark](https://developer.android.com/topic/performance/benchmarking/macrobenchmark-overview?hl=pt-br)
continua alternativa para métricas Android amplas, sem novo módulo obrigatório.

## 10. Escala com notas distintas, antes da série principal

Ampliação autorizada em 2026-11-01. O bloco anterior usa uma única chave LWW
da viagem ativa. C1 muda seu valor dez vezes; C2/C3 aumentam mutações ou bytes,
sem aumentar a quantidade de notas. Arquivos de ensaio e contadores crescentes
não equivalem a mais registros de domínio. A calibração atual permanece como
base de uma nota, separada dos resultados futuros de escala.

O [plano canônico](../../samples_test_lib/compass_app/app/PLANO_DELTASYNC_1_0_1.md#cp-14)
acrescenta CP-14 (preparo/matriz), CP-15 (calibração física) e CP-16 (congelamento
global). CP-11 depende de CP-16. CP-14 preparou 1/10/100/1000 notas distintas;
CP-15 mediu um piloto profile com N=1 e N=1000 nos dois aparelhos. Em N=1000,
a primeira restauração levou 32–52 s, motivando a correção R-44 antes da série
principal. O piloto não fornece p95 nem isola o efeito do coletor.

### População e preparo

Usar N = 1, 10, 100 e 1000 notas distintas, de 64 bytes cada, com chaves válidas
geradas pelo mapeamento de viagens do consumidor. Uma chave ativa fixa deve
pertencer ao conjunto. Conferir exatamente N chaves LWW e os valores restaurados
por APIs públicas, incluindo hashes e IDs. Mil alterações da mesma chave não
satisfazem N=1000. Duas réplicas do mesmo conjunto representam N notas lógicas,
não 2N notas. Não usar contagem de outbox/histórico como cardinalidade de notas.

Preparar dados fora das janelas, com ferramenta dedicada do consumidor e APIs
públicas da biblioteca/adaptador. Não escrever tabelas internas, limpar SQLite,
renomear réplica existente ou mudar o core para facilitar o ensaio. Conferir
estado vazio quando a fixture é nova, exclusividade, commit/restauração real e
recusa de preparo parcial/ambíguo. Reusar fluxos e ferramentas já existentes.
Essa população mede estado de notas da integração; não comprova renderização
de uma lista com 1000 reservas nem oferece uma nova funcionalidade de reservas.

### Perguntas e matriz de escala

| Estado preparado | O que medir | Controle necessário |
|---|---|---|
| N notas persistidas e replicadas | Restauração, CPU/PSS, edição C1 na chave ativa e sync | N permanece constante; N-1 notas ficam preservadas; pendências iniciais declaradas |
| N notas distintas pendentes de envio | Push, pull, ACK, bytes e convergência | Separar remetente/receptor, número de notas e número de deltas; confirmar todo o conjunto |

CP-14 fixa procedimento de abertura/restauração, quantidade inicial de pendências,
distribuição de chaves, preparação de backlog e janelas antes de medir. Não repetir
M1–M6 inteiro para cada N: os casos básicos de falha, reinício e concorrência
continuam cobertos pela calibração base. O bloco de escala focaliza custo de
estado persistido e transferência; preparo em lote não mede velocidade de uma
UI inexistente para cadastrar mil reservas.

Começar pelo piloto curto N=1/N=1000 em cada aparelho. Fixar depois a quantidade
de repetições, ordem de volumes/papéis e comparação on/off, com justificativa,
estimativa de duração e configuração congelada em CP-16. Conservar histórico longitudinal e preparar novas
pendências pelo fluxo público, sem apagar dados para uniformizar estado. Se
capacidade/instrumento mudar, repetir calibrações afetadas e a base comparável
de N=1. Não misturar configurações nem decidir exclusões depois de ver tempos.

O hub atual usa `--snapshot-pull`: o pull pode transferir o estado completo de
N notas. Identificar snapshot e delta por rota/envelope; não apresentar todo
tráfego como delta nem alterar o protocolo para melhorar o resultado aparente.
Separar corpo HTTP, UID e bytes tarifados; manter limites de CPU/PSS/ADB e análise
por rodada/aparelho/N/estado/etapa. Não extrapolar LWW para os oito CRDTs.

O preparo CP-14 usa `tool/prepare_notes_scale_fixture.py` para gerar IDs novos e
quatro configurações: criação e verificação para cada aparelho. O app profile
`tool/prepare_notes_scale.dart` usa `TripNotesRepository.edit` para criar cada
nota, fecha o banco e reabre em outro processo para verificar todas as chaves,
valores e pendências. Cada N usa banco e identidade próprios. O preparo não faz
requisição de rede nem mede desempenho. A chave ativa coincide com a viagem
Alaska existente; as demais notas são viagens sintéticas no estado persistido,
sem criar reservas na lista visual. O [piloto CP-15](../../samples_test_lib/compass_app/app/evidence/cp-15/README.md)
mediu restauração, uma edição e sync com N=1/1000, com auditoria de todas as
chaves e bytes por rota. Repetições e matriz final pertencem a CP-16 e à série
congelada posteriormente.
Após a correção R-44, a
[escala intermediária](../plan/evidence/r44/intermediate-scale.md) mediu somente
restauração N=10/100 nos dois Androids e no host. Uma
[rodada de sync N=10/100](../plan/evidence/r44/intermediate-sync.md) passou com
ACK e convergência nos dois aparelhos. Essas rodadas permanecem exploratórias,
separadas da série principal N=1/1000 concluída em CP-11 e analisada em CP-12.

CP-14–CP-16 satisfizeram seus critérios e liberaram a série. CP-10 permanece
parcial e histórico, sem compor a distribuição principal.

## 11. Resultados consolidados e uso no artigo

O [relatório do consumidor](../../samples_test_lib/compass_app/app/docs/relatorio-desempenho-deltasync.md)
reúne método, resultados, exclusões e apontamentos para o artigo. A
[análise reproduzível](../plan/evidence/cp12/README.md) liga tabelas e scripts
aos brutos e hashes da série: 12 pares válidos N=1/1000 on/off, 72 fases,
dois pares de aquecimento separados e uma tentativa excluída no preflight.

Destacar o crescimento conjunto de cardinalidade/backlog, pull por snapshot,
fonte local R-44, limites PSS/UID e p95 descritivo com seis pares. Não há limite
de latência previamente fixado que permita classificar os tempos como adequados
para todo aplicativo.

Após CP-13, o [piloto incremental CP-17](../plan/evidence/cp17/README.md)
executou o experimento antes proposto: 1000 notas já sincronizadas e somente
uma nova pendência em A. Um push de 737 bytes levou uma mudança; o pull de
A ainda recebeu 502025 bytes e seu ACK enviou 1000 IDs (77028 bytes). O
[complemento do artigo](../../samples_test_lib/compass_app/app/docs/piloto-incremental-deltasync.md)
separa esse piloto da série principal. Um ensaio não estima mediana/p95 e não
altera os limites da medição de memória.
