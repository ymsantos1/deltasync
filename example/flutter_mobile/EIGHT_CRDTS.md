# Validação técnica de oito CRDTs — VAL-16

Entrada separada `lib/main_eight.dart` no projeto Android existente. Cada aparelho
mantém uma única engine, ID alpha/beta, banco eight-alpha.sqlite/eight-beta.sqlite
e peer fixo direto. O exemplo anterior e seus bancos shopper-a/b são preservados.
Compass e seu hub LWW não participam deste cenário. Não há pacote/dependência nova.

## Responsabilidades

`support/eight_scenario.dart` define história e consultas pelas APIs públicas.
`support/http_peer_link.dart` envia envelopes JSON por HTTP e retorna ACK recebido;
o listener usa `SyncEngine.receiveEnvelope`, que valida destino/origem, faz join e
commit SQLite antes de devolver ACK. Core/sync/storage mantêm essas invariantes.
GET /state é inspeção técnica quando ações estão ociosas; prova durável exige fechar
processos e inspecionar SQLite. Não é um snapshot transacional combinado de estado/outbox.
`main_eight.dart` compõe recursos, mostra comandos/valores e acompanha commits.
Recursos vivem durante o processo; falha de abertura fecha recursos. Force-stop
encerra recursos nativos. Testes fecham listener, engine e storage explicitamente.

Botões executam mutações sequenciais, com commit por mutação; não há transação
única dos oito tipos. Não interromper no meio de Criar base/Editar offline e assumir
que a história está completa. Guards evitam repetição da fase completa; uma fase
parcial exige inspecionar banco antes de decidir nova execução. Não há limpeza automática.

## História e resultados esperados

Criar base uma vez em alpha e enviá-la para beta. Só depois desconectar canal,
executar Editar offline em ambos e tentar envio. Editar após falha grava outra
versão LWW sem depender de rede. Restaurar processos/bancos antes
de reconectar. As duas ramificações partem da mesma base causal.

| Tipo | Base e ramificações | Resultado após ambas entregas |
|---|---|---|
| LWW | base; alpha/beta escrevem valores diferentes | vencedor por HLC, replicaId e ID; metadados iguais |
| G-Counter | base 1; alpha +2, beta +3 | 6, componentes somados sem duplicação |
| PN-Counter | base 1; alpha +4, beta -2 | 3, contribuições positivas/negativas preservadas |
| G-Set | seed; cada um adiciona seu ID | alpha, beta, seed |
| 2P-Set | shared; alpha remove, beta adiciona shared; ambos adicionam seus IDs | alpha, beta; shared removido permanentemente |
| MV-Register | base; escritas alpha/beta concorrentes | duas versões; Resolver MV após observar ambas produz apenas resolved |
| OR-Set | shared; alpha remove tags observadas, beta cria nova tag; ambos adicionam seus IDs | alpha, beta, shared; adição concorrente sobrevive |
| OR-Map | chave shared com seed; alpha remove encarnação observada, beta cria outra e adiciona beta | shared contém beta; encarnação removida não ressuscita seed |

Replay dos mesmos envelopes deve preservar valores, tombstones/contextos e outboxes
confirmadas. Os clocks locais/HLC podem avançar em recepções, sem exigir igualdade
de todos os metadados locais. Inspecionar contexto causal e versões nos snapshots,
não somente valores exibidos. Após resolver MV, voltar a reiniciar e conferir ACK.

## Build e canal USB

Neste diretório, com Dart/Flutter no PATH:

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build apk --debug --no-pub --target lib/main_eight.dart --dart-define=REPLICA_ID=alpha
cp build/app/outputs/flutter-apk/app-debug.apk /tmp/eight-alpha.apk
flutter build apk --debug --no-pub --target lib/main_eight.dart --dart-define=REPLICA_ID=beta
cp build/app/outputs/flutter-apk/app-debug.apk /tmp/eight-beta.apk
```

Instalar cada artefato sempre no mesmo aparelho; não clonar banco ou alternar IDs.
O mesmo applicationId substitui a entrada da demo anterior, preservando seus bancos;
reinstalar o APK de main.dart para retornar ao percurso antigo. Não usar clear-data.

```sh
adb -s SERIAL_ALPHA install -r /tmp/eight-alpha.apk
adb -s SERIAL_BETA install -r /tmp/eight-beta.apk
adb -s SERIAL_ALPHA forward tcp:18092 tcp:8092
adb -s SERIAL_BETA forward tcp:28092 tcp:8092
adb -s SERIAL_ALPHA reverse tcp:8093 tcp:28092
adb -s SERIAL_BETA reverse tcp:8093 tcp:18092
```

Cada listener vincula somente loopback no aparelho. GET http://127.0.0.1:18092/state
inspeciona alpha; porta 28092 inspeciona beta. Remover reverses simula desconexão
sem afetar edição/SQLite; forwards podem continuar para inspeção. Reconectar
reverses e enviar ambos. Replay de /delta pode usar envelopes salvos antes do ACK.
Fechar/reabrir apps com am force-stop/am start, sem hot restart. Ao terminar,
remover somente forwards/reverses criados e preservar bancos/APKs identificados.

HTTP cleartext está habilitado somente no manifest debug para esta prova. Helpers
não são transporte de produção: sem auth, limite de payload ou serviço público.
Teste físico complementa propriedades/permutação das suítes; não certifica todas
as histórias, outras plataformas, topologia arbitrária ou desempenho universal.

## Estado da execução de 2026-10-13

Sete testes Flutter/análise/formatação e os dois builds passaram. Preparação
inicial interrompida pelo G53 bloqueado; retomada posterior passou sem apagar bancos
ou repetir branch alpha. Moto G52 Android 13/API 33 e Moto G53 5G Android 14/API 34
convergiram nos oito tipos. Alpha restaurou 11 entradas; beta ramificou sobre a
base preservada e restaurou 13, com edições após envio falho. ACK alpha não removeu
pendências beta. Valores seguiram a tabela; LWW escolheu beta-retry pelo HLC.

MV conservou alpha/beta concorrentes; resolução causal em alpha produziu resolved
nos dois aparelhos. Replay dos 11/13 deltas anteriores recebeu ACK e não alterou
resultados, inclusive após resolução MV. Novo reinício confirmou estado e outboxes
vazias por SQLite fechado. Contextos/tombstones/componentes/encarnações foram
comparados, excluindo owner/sequence locais e tratando componentes PN zero ausentes
como zero. HLC local pode avançar em restore/recepção. Não exigir bytes iguais para
snapshots que representam o mesmo estado causal.

VAL-16 concluída; [execução](../../plan/TRACEABILITY.md#execucao-val-16-2026-10-13)
e [artefato completo](../../plan/evidence/val16-runtime.json). Túneis temporários
removidos, stay-on restaurado, bancos preservados e apps técnicos encerrados.
