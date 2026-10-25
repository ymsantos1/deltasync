# Lote local atômico — R-38

Execução de 2026-10-24 sobre ae1eefe7321da59b9fb420d17eb233dda6903cdc,
com worktree inicial limpa. Entrega: `SyncEngine.batch` e editor `LocalBatch`,
exportados pela facade/sync. O editor só delega mutações aos oito CRDTs existentes;
regras, deltas, identidade e joins continuam no core. Nenhum storage/transport,
formato, schema, SDK ou manifesto mudou.

## Contrato e manutenção

O callback síncrono recebe uma candidata por um editor sem Replica pública.
valueAt vê edições anteriores do lote. Métodos retornam void; após um único
commit de snapshot/outbox, o Future retorna Delta com todas as mudanças emitidas.
Há uma notificação local e uma entrada de outbox por mudança/peer. ACK continua
por mudança e pode ser parcial: atomicidade local não é transação distribuída.

Lote vazio, Future retornado, exceção do callback, qualquer edição inválida
(mesmo capturada) ou falha de commit abortam o lote. O editor fecha antes de
aguardar storage, liberando a referência à candidata. Contexto Zone acompanha
continuações rejeitadas e impede novas operações na engine nesse contexto.
Isso não desfaz I/O ou efeitos externos iniciados pelo app: o contrato exige
preparar dados antes e não agendar trabalho assíncrono separado no callback.

LocalBatch é um final class de construtor privado na mesma library de SyncEngine
via part. _record centraliza coleta/falha; _close encerra o editor. O pipeline
existente _commitLocalResult mantém fila, commit, adoção e notificação. Não há
framework de comandos ou modelos de domínio paralelos. Ver
[guia de uso/limites](../../../docs/migracao-1.0.1.md#lote-local-atômico--r-38)
e [exemplo executável](../../../example/local_batch_example.dart).

## Evidências por etapa

[validation.json](validation.json) registra hashes, review próprio, logs e limites.
Primeira implementação usava flag síncrona; a revisão levou a contexto Zone
para proteger também continuações async rejeitadas. Regressão específica passou.
Depois da matriz geral, reforçou-se o teste de commit falho para conter os oito
tipos simultaneamente e conferir novos dots/IDs no retry. Delta revisado e oito
testes focados reexecutados; produção não mudou após a matriz.

- Matriz: **278 testes** em sete pacotes, respectivamente 15/122/70/14/37/10/10,
  com formato e análise aprovados. Reforço posterior: oito testes de lote aprovados.
- Memória: 22 mutações cobrindo todos os métodos, um commit/evento, leituras
  isoladas, falhas capturadas/não capturadas, rollback dos oito tipos, IDs no retry,
  editor expirado, callbacks async/reentrância, edição concorrente e rede falha.
- SQLite real: falha de mutação/callback sem commit; trigger aborta segunda
  inserção depois de snapshot/primeira entrada. Fechamento/reabertura mantém
  snapshot/outbox/tentativas antigos; retry reutiliza sequência correta. Lote dos
  oito tipos reabre intacto e ACK parcial preserva as outras sete entradas.
- [Consumidor externo](consumer_test.dart.txt): dois testes em projeto isolado,
  callback nomeado void e editor capturado. Compilação negativa impede construtor
  público/implementação forjada. [Relatório](consumer-validation.json) confere sete
  inventários: somente LocalBatch e SyncEngine.batch adicionados.
- O inventário atual usa [scripts/api_inventory.dart](../../../scripts/api_inventory.dart),
  com suporte a parts. Antes da mudança produz inventário igual ao extrator
  histórico, que permanece congelado em R-30.
- Exemplo público verifica perfil com nome/preferências/revisão, três deltas e
  três pendências. Não usa internos nem simula ACK remoto.

## Reprodução

Na raiz, com dependências resolvidas:

```sh
python3 -B plan/evidence/r38/validate_consumer.py --dart dart --report /tmp/r38-consumer.json
dart run example/local_batch_example.dart
```

Loop de formato/análise/testes dos sete pacotes está completo em validation.json.
Não somar testes focados repetidos ao total da matriz. Review do próprio agente
não é independente. Ambiente: Dart 3.13.5/Linux x86_64 e SQLite FFI; sem runtime
SDK 3.12.x, Android novo, kill de processo ou rede física. Consumidor usa path;
artefatos finais e migração integral continuam no gate VAL-17. Sem commit/publicação.
