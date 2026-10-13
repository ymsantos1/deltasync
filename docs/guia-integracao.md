# Integração e manutenção

DeltaSync fornece oito CRDTs, mutações com deltas, commit local e sincronização
para um peer fixo. Modelos, identidade da instalação, rede e interface pertencem
ao consumidor. Este guia técnico não altera a proposta acadêmica.

## 1. Configurar armazenamento e identidade

Use a facade `package:deltasync/deltasync.dart`. Para durabilidade, acrescente
o pacote `deltasync_storage_sqflite` e forneça uma DatabaseFactory compatível
com o alvo. Core, sync e contrato de storage continuam Dart puro.

O [exemplo Flutter](../example/flutter_mobile/README.md) mostra dependências,
inicialização do sqflite e comandos do PATH. O
[exemplo CLI](../example/offline_reconciliation.dart) usa SQLite FFI.
MemoryStorage é volátil; não comprova recuperação após reiniciar o processo.

Escolha um replicaId estável por instalação e mantenha-o entre aberturas.
Não clone o banco para criar outra réplica. Mudanças pendentes ficam vinculadas
ao peer configurado; trocar transporte para outro peer não transfere a outbox.
O cenário atual cobre um par fixo. Muitos dispositivos exigem roteamento e
confirmação por destinatário; não compartilhe identidades.

Componha `SyncEngine.withStorage(replica: ..., storage: ..., transport: ...)`
e aguarde `engine.start()` antes de consultar. Falha de abertura permite repetir
start nos mesmos objetos; schema desconhecido não deve ser apagado para tentar
novamente. Mutações também aguardam a restauração inicial.

## 2. Mapear modelos e escolher CRDT

Escolha endereço estável e tipo por campo conforme a semântica desejada.
LWW escolhe um vencedor; MV mantém versões concorrentes; counters e sets possuem
contratos próprios. Não altere o tipo de um endereço já vinculado.
Consulte [semântica dos tipos](../README.md#onde-alterar-cada-tipo).

No Compass, Booking é convertido em chave de viagem com destino e datas de
calendário; a nota é LWW `{'text': texto}`. Essa conversão pertence ao app.
IDs temporários locais e fuso não identificam a nota. A biblioteca não conhece
Booking nem gera adaptadores de modelos. JSON deve respeitar os tipos suportados.

## 3. Editar e consultar

Após configurar/iniciar a engine:

```dart
await engine.setDelta(address, {'text': text});
final note = engine.valueAt(address);
final pending = await engine.pendingDelta();
```

A mutação termina depois de snapshot/outbox serem persistidos atomicamente e
o estado candidato ser adotado. Isso confirma commit local, sem provar envio.
Consulta síncrona lê um campo adotado após commit, sem copiar toda a réplica.
Durante commit em andamento, devolve o último estado adotado.

Ausente, LWW null e tombstone retornam null; counters vinculados retornam int,
MV/sets retornam Set<Object?> e OR-Map retorna Map<String, Set<Object?>>.
Coleções aninhadas são isoladas/somente leitura. Antes de start ou após dispose,
valueAt lança StateError. APIs anteriores de leitura permanecem disponíveis.

## 4. Observar falhas e pendências

Aguarde mutações/push/applyRemote e trate seus erros no chamador. O stream
`errors` informa falhas de recepção/callback remoto; não substitui try/catch
das chamadas diretas. Uma falha de rede conserva outbox e não impede editar.

`commits` é broadcast sem replay e sinaliza adoção local/remota bem-sucedida.
Ao receber evento, consulte valueAt; restauração inicial não emite esse evento.
O evento não informa ACK. Conte pendências com pendingDelta e mantenha estado
visual distinto para salvo localmente, pendente e confirmado remotamente.
Após reinício, restaure valor/outbox; mensagem de confirmação da sessão pode
reiniciar sem indicar perda de commit anterior.

## 5. Sincronizar e confirmar

Chame `engine.push()` após reconexão ou ação do usuário. A aplicação agenda retry;
não há timer/worker automático. `push(force: true)` ignora backoff/limite.
Resultado contém lote enviado, ACK e IDs reconhecidos. Lote vazio com
fullyAcknowledged verdadeiro não comprova envio de pendências filtradas.

O adaptador serializa envelope com DeltaEnvelope.toJson/fromJson e ACK com
DeltaAcknowledgement.toJson/fromJson. ACK mantém peerReplicaId, stage e
changeIds; campos conhecidos inválidos geram FormatException, extras são ignorados,
IDs repetidos são deduplicados e lista vazia é válida.

Decoder não autentica remetente nem comprova commit. Validar peer/destinatário,
aplicar e aguardar persistência precede emitir appliedAndPersisted.
received indica apenas recebimento e não remove outbox. Remover somente IDs
do lote/destinatário reconhecidos; perda de ACK exige reenvio seguro.

No pull do Compass, o consumidor valida envelope, aguarda applyRemote e só então
envia ACK. GET entrega sem remover pendências do servidor. Rede/timeouts continuam
no adaptador HTTP; esse fluxo ainda é manual (R-26). Protocolos não entram no core.

## 6. Encerrar e restaurar

Cancele listeners da aplicação, aguarde engine.dispose, feche transporte e
storage em finally. Dispose é terminal e aguarda operações aceitas; não descarte
recursos enquanto o commit ainda está em execução. Ao reabrir, crie composição
nova com o mesmo banco/identidade e aguarde start. Não use clear-data para provar
recuperação. O repositório de notas do Compass exemplifica esse ownership.

## Pontos de manutenção e compatibilidade

| Regra | Dono |
|---|---|
| Modelo, endereço, identidade da instalação e UI | Consumidor |
| Estado, mutação, delta e join | Replica e CRDT concreto |
| Consulta pontual dos oito tipos | Replica.valueAt; lifecycle em SyncEngine.valueAt |
| Formatos de envelope e ACK | deltasync_transport; validação de peer no fluxo |
| Commit/adoção, outbox e restauração | SyncEngine e ReplicaStorage |
| Atomicidade SQLite e abertura do banco | Adaptador sqflite |
| Busca/envio, timeouts e protocolo | Adaptador do consumidor |

R-24/R-25 são aditivas: construtores/views anteriores, snapshots e schema não
mudam. Para criar outro storage, execute a suíte pública
`replicaStorageContractTests`; para outro transporte, implemente os contratos
públicos e preserve confirmação após commit. Não sobrescreva internos.
Veja [mapa de manutenção](../README.md#onde-alterar-cada-tipo) e
[compatibilidade](../README.md#compatibilidade-de-api-e-formatos).

Não há codegen obrigatório. Conveniências futuras exigem uso concreto e contratos
estáveis; quantidade de classes/linhas não é meta. Evidência no Compass cobre
notas e um par fixo, sem estudo de usabilidade com participantes.

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
Coordenação pull/ACK e acompanhamento continuam manuais (R-26/R-27 SHOULD).
Esta comparação mostra manutenção e consumo; não mede tempo de integração de
terceiros, esforço acadêmico ou usabilidade com participantes.
