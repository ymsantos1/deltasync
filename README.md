# DeltaSync

Biblioteca Dart modular para aplicações offline-first com CRDTs e sincronização incremental por deltas.

## Pacotes

- `deltasync_core`: estado de réplicas, operações LWW e deltas deduplicados.
- `deltasync_sync`: coordenação de alterações locais, pendências e deltas remotos.
- `deltasync_storage`: contrato de persistência, sem dependência de banco específico.
- `deltasync_transport`: contrato de transporte, sem dependência de HTTP ou WebSocket.
- `deltasync`: facade que exporta APIs dos subpackages.

## Uso

```dart
import 'package:deltasync/deltasync.dart';

final replica = Replica('device-a');
replica.set('message', 'edited offline');
print(replica.state.values);
```

Cada adaptador de storage ou transporte pertence à aplicação consumidora. SQLite, HTTP e WebSocket não são dependências do núcleo.

### Storage

`ReplicaStorage` é o contrato oficial para persistência. A aplicação deve fornecer
um adaptador persistente quando precisar recuperar estado após reinício, como um
adaptador SQLite, Hive, Isar ou arquivos.

`MemoryStorage` é apenas uma implementação volátil de referência. Serve para
testes, exemplos e protótipos; todos os dados são perdidos quando o processo
termina e não deve ser usado como storage de produção.

### Escopo da persistência

Cada dispositivo persiste somente sua própria réplica. O estado completo das
outras réplicas não é armazenado localmente.

Na primeira versão persistente, o modelo lógico possui três tabelas:

- `replicas`: identidade, `VectorClock`, contador local e metadados;
- `state_entries`: estado atual por campo, operação vencedora e tombstones;
- `outbox`: operações locais ainda não confirmadas pelo transporte.

O `VectorClock` pode conter identificadores e contadores de outras réplicas.
Isso registra conhecimento causal, não o estado completo delas. Operações
remotas podem aparecer como operação vencedora ou ser resumidas pelo relógio,
sem exigir armazenamento da réplica remota inteira.

Uma tabela adicional de operações pode ser criada futuramente para auditoria,
replay, histórico ou deduplicação explícita. Confirmações por participante
também podem ser persistidas futuramente para orientar compactação segura de
operações e tombstones. Nenhuma dessas extensões armazena estados completos de
outras réplicas.

## Validação

```shell
dart pub get
dart format .
dart analyze
dart test
```
