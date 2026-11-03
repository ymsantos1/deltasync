# R-44 — restauração de outbox extensa

Execução: 2026-11-01. Código-fonte posterior à publicação da 1.0.1.
Fixture CP-14: N notas LWW distintas e N entradas pendentes, N=1/1000.
Foram usadas cópias fechadas, preservando os bancos e APKs anteriores.

## Alteração e revisão

`ReplicaPersistence.restoreInto` aplica as mudanças pendentes na ordem do
storage em um `Delta`, após carregar o snapshot. Isso mantém validação e
adoção atômica de `Replica.apply`, mas evita um fork/cópia por entrada.
Nenhuma API pública, formato SQLite/JSON ou mensagem de rede mudou. Pendências
não são descartadas por coincidirem com o snapshot; uma entrada pode ser mais
nova. Estado, mutação, join e commit permanecem nos módulos existentes.

Revisão própria posterior à correção conferiu ordem, IDs, conflito de tipo,
rollback, HLC/sequência, leitor legado e ACK. Sem achado pendente. É revisão
do implementador, não independente.

## Medição

Tempo de `TripNotesRepository.start` em Android profile, milissegundos:

| Aparelho | N | Antes CP-15 | Após R-44 | CPU após |
|---|---:|---:|---:|---:|
| Moto G52, API 33 | 1 | 124,8 | 101,7 | 165 ms |
| Moto G53, API 34 | 1 | 91,6 | 72,3 | 115 ms |
| Moto G52, API 33 | 1000 | 52.217 | 829,9 | 1.074 ms |
| Moto G53, API 34 | 1000 | 32.264 | 522,6 | 1.124 ms |

No host, `SyncEngine.start` após a correção levou 134,4 ms (N=1) e
438,2 ms (N=1000). O diagnóstico anterior isolou 15,97 s de replay individual
para N=1000 e 57 ms de aplicação em lote, além de menos de 0,35 s para leitura
e decodificação. O host mede `SyncEngine.start`; Android mede o início do
repositório consumidor. Ambos carregam o mesmo tipo de fixture, mas os tempos
absolutos não são intercambiáveis.

O entrypoint de medição R-44 difere do piloto CP-15, mas usa o mesmo
`TripNotesRepository.start`, fixture CP-14, build profile e coletor. É um
par antes/depois por aparelho e carga, suficiente para confirmar a remoção
do gargalo observado, não para estimar p95 ou atribuir efeito ao coletor.
Nenhuma janela de sync/rede foi repetida nesta correção.

Medições suplementares N=10/100 nos dois aparelhos e no host estão em
[escala intermediária](intermediate-scale.md). Não integram a série principal.
O [sync N=10/100](intermediate-sync.md) também foi medido em rodada física
separada, com auditoria de ACK e convergência.

## Integridade e validação

- Cada cópia física foi inspecionada pelo leitor público: N chaves/valores
  LWW, N IDs pendentes e sequência N. Sem perdas do coletor.
- Hashes das fontes CP-14 e bancos antigos ficaram iguais. Os APKs anteriores
  foram reinstalados, e os apps de ensaio foram parados.
- Teste SQLite novo: 1000 entradas sobrevivem a reabertura, ACK e nova
  reabertura. Outro teste prova replay de valor mais novo, falha por conflito
  posterior sem gravar snapshot e retry após remover a entrada inválida.
- `dart format --output=none --set-exit-if-changed lib test`, `dart analyze`
  e `dart test`: sucesso na raiz e nos seis pacotes. Suítes existentes cobrem
  os oito CRDTs e snapshots legados.
- Compass: `flutter analyze --no-pub` e `flutter test --no-pub`, 141 testes
  aprovados. Quatro APKs profile executados nos dois aparelhos.

Brutos, logs, fontes, APKs, configurações, scripts, hashes e relatório por
aparelho estão fora do Git em
`../samples_test_lib/compass_app/app/.performance-artifacts/r44/7c635e9317644190816304caba139d5f/`,
relativo à raiz `/projetos/tcc`. O `manifest.json` SHA-256 é
`ccfb5783dd024d4266f8370702932b139fbea7996cf54bf52dad51dcf2623427`.
O diagnóstico anterior está em
`../samples_test_lib/compass_app/app/evidence/cp-15/restore-investigation.md`.

Limite de distribuição: os sete pacotes 1.0.1 publicados ainda contêm o
replay antigo. Esta evidência valida o código-fonte local; nova publicação
precisa de versão, gate e autorização próprios.
