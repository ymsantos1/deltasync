# Preparação e validação VAL-15 — dois clientes Compass

Preparação local seguida de runtime aprovado em dois dispositivos físicos
autorizados, em 2026-10-13. Biblioteca permanece inalterada nesta tarefa.

## Topologia e garantias

Dois Compass com IDs alpha/beta têm SQLite privado e peer fixo notes-hub.
Backend notes-hub mantém estado LWW durável numa engine, serializando HTTP.
Push confirma somente IDs recebidos após commit SQLite do hub. Cada cliente
remove sua própria outbox vinculada ao hub.

Snapshot-pull exporta estado LWW materializado em DeltaEnvelope para destinatário
explícito. Não é entrega incremental com outbox do servidor por cliente: hub não
edita localmente nem remove estado ao receber ACK de pull. Um cliente não confirma
pendências do outro. Estado retido permite ao outro buscar vencedor/tombstones.

Essa composição pertence ao consumidor. Não transforma SyncEngine em fanout,
não altera storage nem promete todo histórico causal/clocks ou oito CRDTs nesse
modo. Somente notas LWW trip-notes são aceitas. Modo antigo de um peer/outbox
permanece padrão. Snapshot-pull rejeita banco com outbox local anterior.

## Configuração reproduzível

No diretório compass_app/server, use banco dedicado:

```sh
dart run bin/notes_server.dart --replica notes-hub --clients alpha,beta --snapshot-pull --port 8091 --db ./notes-hub.sqlite
```

No diretório compass_app/app, crie APKs sem editar fonte:

```sh
flutter build apk --debug --target lib/main_deltasync.dart --dart-define=REPLICA_ID=alpha --dart-define=PEER_ID=notes-hub
cp build/app/outputs/flutter-apk/app-debug.apk build/compass-alpha.apk
flutter build apk --debug --target lib/main_deltasync.dart --dart-define=REPLICA_ID=beta --dart-define=PEER_ID=notes-hub
cp build/app/outputs/flutter-apk/app-debug.apk build/compass-beta.apk
```

Cada APK volta sempre ao mesmo aparelho. Identidade fica configurada no artefato
e snapshot; compass-notes-alpha.sqlite/compass-notes-beta.sqlite separam bancos.
Reinstalar mesmo ID preserva banco. Trocar ID abre outro banco, sem migrar/clonar.
Banco compass-notes.sqlite legado continua preservado.

Canal inicial: HTTP/TCP real por USB, com reverse independente por serial:

```sh
adb -s SERIAL_ALPHA install -r build/compass-alpha.apk
adb -s SERIAL_BETA install -r build/compass-beta.apk
adb -s SERIAL_ALPHA reverse tcp:8091 tcp:8091
adb -s SERIAL_BETA reverse tcp:8091 tcp:8091
```

Para Wi-Fi, escolher IP/rede antes de compilar: backend --host 0.0.0.0 e
ambos APKs --dart-define=NOTES_URL=http://IP_DO_HOST:8091. Loopback padrão não
é acessível de outro host sem reverse. Cleartext é debug. Lista de IDs delimita
roteiro, sem autenticação de serviço público.

## Roteiro físico reproduzível

1. Registrar modelos/Android/seriais, versões, hashes dos APKs e canal.
2. Abrir mesma viagem e salvar versões diferentes offline nos dois apps.
3. Tentar envio indisponível, editar novamente e conferir pendências.
4. Force-stop/reabrir cada processo sem clear-data; conferir valores/IDs/outbox.
5. Disponibilizar hub; sincronizar alpha, beta e alpha para completar pull.
6. Conferir vencedor LWW comum, confirmações e outboxes dos clientes vazias.
   Inspecionar bancos com processos fechados e verificar destinatários/IDs.
7. Reiniciar hub com mesmo banco e ambos apps; repetir consulta/reconciliação.
8. Remover apenas reverses criados e encerrar backend de teste.

Pull pareado sem destinatário/ID desconhecido é rejeitado. ACK desconhecido ou
received não confirma envio. Retry pode reaplicar mesmos vencedores.
Não exigir HLC/clocks locais idênticos: bootstrap LWW transporta estado relevante,
sem todo histórico causal de mudanças perdedoras.

## Prova local e limites

Testes usam dois bancos clientes e processo HTTP hub separado, sem celular.
Cobrem identidade, roteamento de pull, endereço errado, confirmações isoladas,
edição durante falha, reabertura dos três bancos e convergência de vencedores LWW.
Não substituem plugin Android, dois celulares, rede física ou reinício real dos apps.
Escrita acadêmica e publicação continuam com o autor.

## Execução física registrada

VAL-15 executou este roteiro no Moto G52 (alpha, Android 13/API 33) e Moto G53 5G
(beta, Android 14/API 34), com APKs configurados e HTTP/TCP por reverse USB.
Ambos salvaram duas versões independentes da mesma nota, observaram falha de
envio e continuaram editando. Force-stop/reabertura preservou valores e duas
pendências em cada banco, destinadas somente a notes-hub. Sincronizar alpha
zerou sua outbox e manteve as duas pendências beta. Após beta e novo pull alpha,
ambos convergiram para o mesmo vencedor beta:delta:2 e zeraram pendências.

Novo reinício dos apps e do hub preservou vencedor/outboxes, inclusive snapshot
completo do hub. Repetir sincronização após reinícios manteve resultado. Bancos
dos três processos foram inspecionados fechados. Backend e reverses temporários
foram encerrados; stay-on de USB voltou ao valor original, sem alterar a preferência
de tempo de bloqueio escolhida pelo autor. Nenhum banco foi apagado.

Ver [execução e limites](../plan/TRACEABILITY.md#execucao-val-15-2026-10-13) e
[artefato de bancos/IDs/dispositivos/hashes](../plan/evidence/val15-runtime.json).
Essa prova cobre notas LWW, dois Androids e canal USB; não certifica Wi-Fi, iOS,
produção, todos os oito tipos nessa topologia ou entrega incremental do hub.
