# Consumidor Flutter Android — VAL-07

Este app usa somente as APIs públicas de DeltaSync e passa a factory do plugin
`sqflite` para `SqfliteReplicaStorage`. Modelo, peer fixo e UI pertencem ao app.
As duas réplicas usam bancos SQLite distintos no diretório do aplicativo.
O projeto resolve os pacotes locais por paths e overrides, em workspace próprio;
o workspace Dart da biblioteca continua separado do SDK Flutter.

Execute `flutter pub get` e `flutter run -d <dispositivo>` neste diretório. Para
um percurso novo, limpe os dados do aplicativo antes de iniciar. Toque em
**1. Editar offline**: cada réplica faz uma escrita LWW e incrementa G-Counter;
o peer desligado causa erro de envio, mantendo duas pendências por réplica.
Feche o processo com `adb shell am force-stop com.example.deltasync_mobile_consumer`
e abra novamente. A tela e a linha `VAL07 restored` no log devem mostrar os
mesmos valores e pendências. Toque em **2. Reconectar**. A tela e o log devem
mostrar `Ana/Beto; itens=5` nas duas réplicas e zero pendências. Force o fechamento
e abra mais uma vez para verificar a confirmação durável.

Se a abertura do banco falhar, a tela mostra o erro e libera **Tentar novamente**.
Editar e reconectar permanecem desativados até a restauração terminar. O retry
reabre os mesmos bancos sem limpar o estado ou as pendências. A regressão Flutter
injeta uma falha de abertura, verifica o fechamento dos recursos e confirma a
restauração das duas réplicas e da outbox:

```sh
flutter test test/open_retry_test.dart
```

O retry de abertura é distinto do envio. **2. Reconectar** configura o enlace
sintético e chama `push(force: true)` em cada réplica; não há envio agendado pela
biblioteca. Após sucesso, a tela exibe valores e pendências consultados; em falha,
exibe o erro. Uma falha de envio mantém o commit local e a outbox para nova tentativa.

O botão de reconexão conecta dois objetos no mesmo processo. Esse enlace é um
peer fixo de demonstração, não um protocolo de rede ou backend. O caminho SQLite,
a factory e os valores exibidos permitem verificar a integração do plugin mobile
e a separação entre commit local, pendência e confirmação remota.

Para instalar sem uma sessão residente do Flutter:

```sh
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.example.deltasync_mobile_consumer/.MainActivity
adb shell pidof com.example.deltasync_mobile_consumer
# Depois de editar offline, encerrar e confirmar ausência de PID:
adb shell am force-stop com.example.deltasync_mobile_consumer
adb shell pidof com.example.deltasync_mobile_consumer
adb shell am start -n com.example.deltasync_mobile_consumer/.MainActivity
```

Leia as linhas `VAL07` com `adb logcat -d --pid=<PID> -s flutter:I` após obter o
PID atual. Para repetir do zero, `adb shell pm clear com.example.deltasync_mobile_consumer`
apaga os dados deste app de demonstração. Hot reload/restart não substitui o
encerramento do processo Android. Estado, mutações, deltas, join e commit pertencem
a `SyncEngine`/`Replica` e ao adaptador; apresentação e valores do cenário ficam
em `lib/main.dart`. Não há mudança de API ou formato persistido da biblioteca.

Executado em Moto G52, Android 13/API 33, Flutter 3.47.7 e Dart 3.13.5, com
`sqflite` 2.4.4+1. [Evidência e limites](../../plan/TRACEABILITY.md#execucao-val-07-2026-10-12-mobile).
iOS, rede real e participantes não foram avaliados.
