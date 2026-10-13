# Consumidor Flutter Android — VAL-08

Este app consome apenas APIs públicas de DeltaSync. Duas réplicas usam bancos
SQLite separados no diretório do aplicativo. O enlace é sintético, no mesmo
processo e com peer fixo; não representa rede ou backend. O projeto usa paths e
overrides locais, em workspace Flutter separado do workspace Dart da biblioteca.

## Percurso interativo

Execute `flutter pub get` e `flutter run -d <dispositivo>` neste diretório. O
enlace começa offline. A tela mostra A e B separadamente: título LWW, G-Counter,
pendências, último erro de envio, confirmação da tentativa atual e origem/HLC do
vencedor. A confirmação exibida é da sessão de UI; pendências e valores vêm dos
bancos e sobrevivem ao reinício. `Envio concluído` só indica que a tentativa
terminou sem erro; confira confirmação e pendências de cada réplica.

1. Digite títulos diferentes em A e B e toque em **Salvar título** de cada uma.
   Ambos editam `shopping/title`. Toque em **+1 item** para atualizar o G-Counter
   `shopping/items` em cada réplica. O commit local termina antes de qualquer envio.
2. Toque em **Enviar pendências** ainda offline. Cada réplica mostra erro de peer
   indisponível; títulos, contadores e outbox continuam. Edite novamente em A ou B
   enquanto há pendências e confira o novo commit local.
3. Force o fechamento do processo e abra o app. Valores e pendências devem ser
   restaurados. O switch volta a offline de propósito; a disponibilidade do peer
   pertence à sessão, não ao snapshot da biblioteca.
4. Ative **Peer disponível** e toque em **Enviar pendências**. As duas visões
   devem convergir para o mesmo título, vencedor LWW e contador; pendências vão a
   zero após ACK `appliedAndPersisted`. A ordem LWW usa HLC e, em empate,
   `replicaId` e ID. A UI mostra origem e timestamp do vencedor.
5. Edite outra vez, agora com peer disponível. O novo commit permanece local até
   outro toque em **Enviar pendências**. Force novo fechamento/abertura para
   conferir estado e outbox confirmada.

**Limpar dados da demo** pede confirmação, fecha a sessão e apaga somente
`shopper-a.sqlite` e `shopper-b.sqlite` no diretório deste app. Não apaga outros
bancos nem dados de outros aplicativos. Dados da versão VAL-07 usam endereços LWW
antigos; para iniciar um percurso com o título compartilhado, use essa limpeza.

Se a abertura falhar, **Tentar novamente** reabre os mesmos bancos sem limpar
estado ou pendências. Ações com réplicas ficam indisponíveis até a restauração.
Retry de abertura e envio são separados. Cada toque em **Enviar pendências** chama
`push(force: true)`; DeltaSync não agenda tentativas em segundo plano. Falha de
envio mantém commit e outbox para outra tentativa.

## Validação e manutenção

```sh
flutter analyze
flutter test
flutter build apk --debug
```

`test/demo_session_test.dart` cobre conflito, edições durante falha, retry,
reabertura SQLite e limpeza restrita. `test/open_retry_test.dart` injeta falha de
abertura e confere recursos/outbox. `test/interactive_demo_test.dart` cobre as duas
visões e os controles. Testes Flutter usam SQLite FFI no host; não substituem
runtime no plugin Android.

Para instalar e verificar reinício real sem sessão residente do Flutter:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.example.deltasync_mobile_consumer/.MainActivity
adb shell pidof com.example.deltasync_mobile_consumer
adb shell am force-stop com.example.deltasync_mobile_consumer
adb shell pidof com.example.deltasync_mobile_consumer
adb shell am start -n com.example.deltasync_mobile_consumer/.MainActivity
```

Após obter o PID atual, `adb logcat -d --pid=<PID> -s flutter:I` mostra linhas
`VAL08 restored` e as ações. Hot reload/restart não substitui force-stop.

`lib/main.dart` inicia o app; `demo_page.dart` apresenta estados e comandos;
`demo_session.dart` coordena as duas engines, snapshots da UI, armazenamento e
limpeza; `peer_link.dart` implementa o enlace sintético. Estado, mutação, delta,
join, commit e restauração continuam nos contratos públicos da biblioteca e no
adaptador SQLite. A divisão não muda APIs nem formatos persistidos da biblioteca.

A execução anterior em Moto G52, Android 13/API 33, Flutter 3.47.7, Dart 3.13.5
e `sqflite` 2.4.4+1 pertence a
[VAL-07](../../plan/TRACEABILITY.md#execucao-val-07-2026-10-12-mobile).
O percurso interativo desta versão foi executado no mesmo Moto G52 em
[VAL-08](../../plan/TRACEABILITY.md#execucao-val-08-2026-10-12).
iOS, rede real e avaliação com participantes não foram executados.
