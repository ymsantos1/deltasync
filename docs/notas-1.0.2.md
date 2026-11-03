# Notas da versão 1.0.2

Estado: metadados preparados localmente, sem publicação nesta tarefa.
Os sete pacotes mantêm versão alinhada 1.0.2 e constraints internas ^1.0.2.
SDK Dart ^3.13.0 permanece. A [1.0.1 publicada](../plan/evidence/publicacao-1.0.1/README.md)
é histórica e não é sobrescrita por esta preparação.

## Correção incluída

`deltasync_sync` restaura a outbox em um único Delta ordenado, após carregar
o snapshot. Evita repetir cópias completas da réplica por entrada pendente.
Mantém validação, adoção atômica, clocks, sequência local, entradas pendentes
e readers legados. A facade passa a exigir a dependência corrigida.

O adaptador SQLite recebe regressões de reinício com 1000 pendências e de
recuperação após conflito. Nos demais pacotes, a mudança desta versão é o
alinhamento de metadados/dependências, sem nova funcionalidade anunciada.
Detalhes, medições e limites da correção em [R-44](../plan/evidence/r44/README.md).

## Compatibilidade e atualização

Sem nova mudança pública de API ou formatos persistidos em relação à 1.0.1.
Snapshot interno v9, DeltaCodec v4, ReplicaSnapshot v2, outbox v2 e schema
SQLite v1 permanecem. Não é necessária migração adicional de dados por esta
correção. Quem parte da 1.0.0 ainda deve seguir a [migração 1.0.1](migracao-1.0.1.md).

Após publicação dos pacotes, consumidores hosted podem atualizar, por exemplo:

```yaml
dependencies:
  deltasync: ^1.0.2
  deltasync_storage_sqflite: ^1.0.2
```

Resolver dependências e validar os fluxos de recuperação/sync do consumidor.
Consumidores por `path`, como o Compass usado nos ensaios, resolvem a versão
do checkout; não precisam renumerar o aplicativo como se fosse pacote da lib.

## Evidências e trabalho futuro

Os ensaios Compass usaram fonte local com R-44 antes da renumeração, em variante
de ensaio e integração real de notas. Seus APKs/configs/fontes/hashes permanecem
congelados com as versões que efetivamente tinham; a preparação 1.0.2 não
reescreve essas evidências nem equivale a novo teste de um archive publicado.
Ver [série/análise](../plan/evidence/cp12/README.md) e
[piloto incremental](../plan/evidence/cp17/README.md).

Pull incremental por destinatário e redução do ACK não são funcionalidades
novas da biblioteca 1.0.2. Após a preparação destes metadados, o
[protótipo CP-18](../plan/evidence/cp18/README.md) implementou e comparou essa
estratégia no hub LWW do Compass, sem modificar o núcleo ou APIs públicas.
Os resultados são da integração e do protocolo da amostra, não demonstram
defeito nos CRDTs nem generalizam desempenho aos oito tipos. A medição de
pico/heap/energia também não passa a existir pela renumeração.

## Preparação para envio

Executar [preparação e publicação](publicacao.md) com os manifests atuais.
R-45 conferiu resolução local, formato/análise e 314 testes dos sete pacotes,
além de 85 arquivos exportados; [checks e limites](../plan/evidence/r45-preparacao-1.0.2/README.md).
Preparação/exportação local não substitui gate de publicação: revisar arquivos,
resolver artefatos standalone, conferir dry-runs e validar consumidor hosted.
VAL-17 e a publicação 1.0.1 não atestam os novos artefatos 1.0.2. Commit,
tag, push e publicação não são executados por esta alteração de metadados.
