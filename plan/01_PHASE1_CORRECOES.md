# Fase 1 — Simplificação e correções da base existente

Estado: MUST e R-16 SHOULD concluídos em 2026-10-12; R-19 COULD concluída
em 2026-10-12 após validação, review e registro de evidências. R-20 SHOULD concluída
em 2026-10-13 com consolidação de responsabilidades e regressões de ownership.
R-21 SHOULD concluída em 2026-10-13; R-22 COULD permanece pronta.
R-23 MUST concluída em 2026-10-13 após achado nas histórias VAL-11.
Ampliação de ergonomia: R-25 MUST concluída, sem apagar conclusões anteriores.

Objetivo: consolidar core nativo, estado/storage e corrigir commits e lifecycle.
Entrada: implementação atual, [análise](../docs/analise-arquitetura.md) e
diagnósticos em [TRACEABILITY.md](TRACEABILITY.md).
Saída: R-01 a R-05, R-09a/R-09b, R-10, R-13/R-14/R-15/R-18 concluídas,
com evidências dos critérios. R-16 é SHOULD, com adiamento justificado permitido.
Áreas: core, storage, sync, transport e seus testes.
Riscos: [RISK-01 a RISK-05, RISK-07, RISK-13 a RISK-16 e RISK-20](RISKS.md).
Exclusões: novos frameworks de objetos, codegen e GC destrutivo.

R-01 a R-05 e R-09a/R-09b conservam suas conclusões históricas. A revisão de
2026-10-11 confirmou falha no uso público de LWW com coleções tipadas, corrigida
em R-10. A [revisão geral de 2026-10-12](TRACEABILITY.md#revisao-geral-2026-10-12)
acrescentou os novos defeitos e o pedido de organização estrutural.
A ordem atual de execução está no índice do plano.

<a id="r-01"></a>

## R-01 — LWW nativo e compatibilidade

Status: concluída
MoSCoW: MUST
Dependências: nenhuma

Baseline histórica anterior a R-01: parcial.

Problema reproduzido: operações legadas z={z:1}, a={z:1,a:1}, m={m:1}, todas
sobre a mesma chave. Ordens [z,a,m] e [a,m,z] resultam em m e z.
Operation.compareTo não fornece ordem transitiva ao combinar causalidade e
desempate por replicaId. Testes existentes de duas operações não cobrem o caso.

Critérios:

- [x] Caminho público recomendado produz/aplica LwwDelta com HLC.
- [x] Caso de três operações é coberto por regressão; definir correção ou rejeição
  explícita do caminho legado, sem anunciá-lo como CRDT convergente.
- [x] Documentar migração/compatibilidade de Operation e dados antigos.
- [x] Não misturar políticas causal e HLC como se fossem equivalentes. Atualmente,
  operação legada após primeiro delta nativo é ignorada naquele registrador.
- [x] Atualizar exemplo/README para API escolhida, mantendo quebras explícitas.

Não remover API pública silenciosamente. Compatibilidade temporária precisa de
limites documentados; nomes antigos podem ser wrappers se semântica for definida.

Validação: Regressão das três operações em todas as permutações; LWW nativo com HLC, tombstones e repetição; compatibilidade da facade e exemplo.

Evidência de conclusão: [Execução R-01 — 2026-09-27](TRACEABILITY.md#execução-r-01--2026-09-27).
<a id="r-02"></a>

## R-02 — Identidade e roteamento

Status: concluída
MoSCoW: MUST
Dependências: R-01

Baseline histórica anterior a R-02: parcial.

Problemas reproduzidos: Replica.apply rejeita GCounterDelta; dois GCounter da mesma
réplica produzem o mesmo ID na primeira mutação e Delta.merge perde uma mudança.
OutboxEntry só extrai origem de delta nativo LWW.

Critérios:

- [x] Endereço estável do CRDT acompanha cada mudança.
- [x] IDs não colidem entre instâncias/campos; definir alocação de dots local e
  namespace causal. Sequência por tipo/instância não é relógio global da réplica.
- [x] Replica, codec, OutboxEntry e SyncEngine roteiam LWW e counters sem perda.
- [x] Testar dois counters independentes na mesma réplica, lote misto e restauração.
- [x] Validar origem/endereço/tipo e rejeitar lote inválido sem aplicação parcial.
- [x] Definir semântica para IDs repetidos com payload divergente.
- [x] Planejar contexto que distingue lacunas: observar dot 3 não implica ter
  recebido dot 1/2 de CRDTs independentes.

Integração manual suficiente; não exige ObjectCrdt ou build_runner.

Validação: Dois counters na mesma réplica, lote misto, codec e outbox; ID conflitante, delta inválido e restauração das sequências.

Evidência de conclusão: [Execução R-02 — 2026-09-28](TRACEABILITY.md#execução-r-02--2026-09-28).
<a id="r-03"></a>

## R-03 — ACK e outbox seguros

Status: concluída
MoSCoW: MUST
Dependências: nenhuma

Baseline histórica anterior a R-03: parcial.

Problema reproduzido: enqueue de lote com duas mudanças e ACK só da primeira
deixa zero entradas pendentes. MemoryStorage.acknowledge usa any(ids.contains).

Critérios:

- [x] Definir ACK por mudança ou envelope. ACK parcial preserva parte não
  confirmada, ou lote só é removido após confirmação de todos os IDs.
- [x] ACK externo só confirma IDs do lote enviado e da outbox da réplica local;
  ACK separado por peer aguarda identidade de destino em R-08b.
- [x] Envio sem confirmação mantém pendências; migrar ou restringir caminho
  PendingDeltaStore que atualmente limpa tudo após send.
- [x] Falha de envio, timeout e reinício antes do ACK permitem retry sem perda.
- [x] Retry respeita política documentada; push(force:true) e maxAttempts têm
  comportamento explícito, sem confundir reenvio manual com entrega garantida.
- [x] Documentar quem confirma e se aplicação/persistência remota precedem ACK.

Não usar ACK de envio para GC de tombstones.

Validação: ACK parcial, envio falho, envio sem ACK, timeout e retry; cobrir caminho ReplicaStorage e caminho legado enquanto existir.

Evidência de conclusão: [Execução R-03 — 2026-09-28](TRACEABILITY.md#execução-r-03--2026-09-28).
<a id="r-04"></a>

## R-04 — Commits atômicos e snapshots

Status: concluída
MoSCoW: MUST
Dependências: R-02, R-03

Baseline anterior: primitivas separadas disponíveis; commit atômico pendente.

Na baseline anterior, mutação alterava memória, enqueue e saveReplica separadamente.
Adicionar transação no adaptador não resolve chamadas independentes automaticamente.

Critérios:

- [x] Contrato expressa commit local único de estado + clocks + outbox.
- [x] Commit remoto preserva estado/contexto/clocks e falha sem efeito parcial.
- [x] Falha do commit deixa memória e storage consistentes; sucesso só é retornado
  após commit. Definir preparação isolada, rollback ou estratégia equivalente.
- [x] Não usar ReplicaState.copy como isolamento sem corrigir cópia compartilhada
  de LwwRegister; caso reproduzido altera cópia ao mutar original.
- [x] Serializar mutações/merges que compartilham réplica e storage.
- [x] Snapshot versionado restaura estado, tombstones, identidade e clocks sem
  exigir replay ilimitado de Replica.export().
- [x] Dot/sequências de IDs/HLC não regressam após restauração ou compactação.
- [x] Testes de contrato incluem falhas entre etapas e versão incompatível.

Snapshots novos guardam estado materializado versionado; snapshots legados em
metadata['delta'] continuam legíveis durante migração.

Validação: Falhas de commit local/remoto, isolamento de estado, concorrência e restauração versionada; validar MemoryStorage como contrato, sem alegar durabilidade.

Evidência de conclusão: [Execução R-04 — 2026-10-01](TRACEABILITY.md#execução-r-04--2026-10-01).

Conclusão acima cobre evidências dessa execução. F-01/F-03/F-04 da análise de
2026-10-03 deixam garantias adicionais pendentes em R-09b/R-05; preservação do
registro não representa aprovação atual de todo isolamento ou fluxo entre engines.

<a id="r-09a"></a>

## R-09a — Core nativo e compatibilidade

Status: concluída
MoSCoW: MUST
Dependências: R-01, R-02

Áreas: core, consumidores em sync/storage/transport, facade, exemplos e testes.
Objetivo: eliminar representações sobrepostas e consolidar contratos dos três tipos
atuais, preservando joins e preparando integração dos oito CRDTs.

Critérios:

- [x] Inventariar APIs exportadas e formatos usados no workspace; documentar
  política de remoção, wrappers ou conversão isolada e quebras para consumidores.
- [x] DeltaCrdt ser contrato principal; retirar CrdtOperation sem uso e caminho
  operacional legado da execução normal, incluindo herança de LwwRegister.
- [x] LWW manter vencedor nativo único com tombstone; operações antigas, quando
  suportadas, usar migração explícita sem dois modelos permanentes de vencedor.
- [x] Delta ser lote nativo; contrato comum de mudança expor endereço, tipo, origem
  e ID com tipos adequados, sem switches por classe apenas para ler metadados comuns.
  Serialização e envelope terem funções distintas; avaliar necessidade de DeltaCodec
  como classe pública sem criar registry, codegen ou framework genérico.
- [x] Conjunto fechado de tipos usar enum com rótulo serializado explícito ou
  solução tipada equivalente, evitando strings fixas espalhadas. Preservar rótulos
  e IDs existentes ou versionar mudança; rejeitar tipos desconhecidos. Não usar
  `.index` nem depender de renomeações de `.name` para formatos persistidos.
- [x] Simplificar componentes internos de PN-Counter; validar delta inteiro antes
  de aplicar e manter join por máximo com deltas cumulativos.
- [x] Validar endereços/valores locais antes de mutar; saída válida ser aceita
  por codec e outra Replica. HLC/contexto/dots servirem apenas à semântica aplicável.
- [x] Exemplo e documentação explicarem estado, mutação, delta, join e restauração
  de cada tipo atual e apontarem arquivos/testes para uma alteração localizada;
  preservação de tipos úteis não depender de quota de classes.

Validação: regressões nativas dos três tipos, PN inválido sem efeito parcial,
endereço vazio, lotes, round-trip de tipos/rótulos/IDs e rejeição de desconhecidos,
fixtures de compatibilidade/rejeição e consumidores.
Checks de pacotes afetados e facade; ausência de classes sem uso no fluxo revisado.
Conferir exemplos e correspondência do percurso de alteração com arquivos/testes.

Evidência de conclusão: [Execução R-09a — 2026-10-03 (conclusão)](TRACEABILITY.md#execucao-r-09a-2026-10-03-conclusao).
Status: concluída.

<a id="r-09b"></a>

## R-09b — Estado, snapshots e outbox consolidados

Status: concluída
MoSCoW: MUST
Dependências: R-09a, R-03, R-04

Áreas: estado de Replica, snapshots, contrato de storage, SyncEngine e testes.
Objetivo: manter estado restaurável canônico e isolamento real, com uma pendência
por mudança e pipeline local de commit comum.

Critérios:

- [x] Unificar estado por endereço, com vínculo de tipo incluindo LWW/counters;
  consolidar Replica/ReplicaState conforme responsabilidade própria de cada uma.
- [x] Snapshot canônico guardar estado, tombstones, clocks/contexto e sequências;
  eliminar duplicação entre state/clock e metadata['replicaState']; versionar formato
  e definir leitura/conversão ou rejeição explícita de snapshots anteriores.
- [x] Definir valores serializáveis e proteger entradas, consultas, cópias e
  snapshots contra mutação externa de listas/mapas aninhados. Fork preservar fonte
  de tempo injetada e isolamento necessário para falha de commit.
- [x] Engine controlar escrita na réplica ativa, inclusive referência originalmente
  fornecida pelo consumidor; mutação externa não produzir perda ou colisão de IDs.
- [x] Histórico completo sair do caminho normal; outbox conservar somente pendências.
  Definir exportação, bootstrap aplicável e alcance de rejeição de ID conflitante
  após restauração sem prometer deduplicação eterna por log ilimitado.
- [x] ReplicaStorage ser contrato principal; descontinuar PendingDeltaStore e
  MemoryPendingDeltaStore do fluxo normal com compatibilidade explícita. Consolidar
  gravações em commit atômico; primitivas restantes terem função documentada.
- [x] Outbox ter uma entrada por mudança, identidade direta e ACK parcial sem perda;
  lotes serem formados no envio. Tentativas e status terem significado consistente.
- [x] Nulabilidade refletir invariantes: entrada de outbox exigir mudança válida
  no tipo/construtor, sem campo opcional que todo consumidor precisa forçar com `!`.
  Rejeitar entradas inválidas na criação/restauração; ausência legítima continuar
  explícita, sem valores artificiais para esconder estado ausente.
- [x] Mutações locais compartilharem pipeline interno de preparação/commit/adoção;
  falhas manterem estado e outbox anteriores, sem framework público de comandos.

Validação: payload alterado pelo chamador e por consultas não altera estado/outbox;
referência externa durante commit, relógio controlado, tipo/endereço conflitante,
snapshot/restauração e sequência, falhas locais/remotas, ACK parcial e compatibilidade.
Verificar contrato tipado da outbox, criação/restauração inválida e consumidores.
MemoryStorage simula contrato; durabilidade continua em R-07c/R-07d.

Evidência de conclusão: [Execução R-09b — 2026-10-03](TRACEABILITY.md#execucao-r-09b-2026-10-03).

<a id="r-05"></a>

## R-05 — Lifecycle e processamento remoto

Status: concluída
MoSCoW: MUST
Dependências: R-09b

Baseline: parcial; correções ainda não concluídas.

Mutações antes de start podem sobrescrever snapshot anterior; após dispose também
são aceitas. Falha de start deixa flag iniciada. Listener descarta Future de erro.
Fila de commits aguarda rede em push, bloqueando edição local e aplicação remota.

Critérios:

- [x] Definir contrato de uso antes de start e após dispose; impedir mutação antes
  da restauração ou depois do descarte, conforme contrato.
- [x] Falha de start permite recuperação ou estado terminal documentado; _started
  não pode sugerir sucesso após falha de carregamento.
- [x] Processamento remoto aguardado/serializado; erros observáveis e sem aplicação
  parcial ou confirmação antes do commit.
- [x] Envio e espera de ACK ocorrerem fora da fila de commits; edição local e
  recepção continuarem enquanto rede estiver lenta ou indisponível. ACK só alcançar
  mudanças do lote enviado, preservando pendências criadas durante envio.
- [x] API pública permitir distinguir commit local concluído, mudanças pendentes
  e confirmação remota, além de observar falhas e ciclo de vida; consumidor não
  depender de acesso a campos internos nem de framework de estados novo.
- [x] dispose trata operação em andamento e impede novos trabalhos.
- [x] Testar start falho, entrada inválida, falha de storage, concorrência e
  cancelamento; guarda isolada não comprova lifecycle completo.

Validação: start falho/repetido, perda de snapshot por uso antes da restauração,
mutação fora do lifecycle, callback remoto com erro, edição/recepção durante envio
pendente, ACK concorrente e dispose com trabalho em andamento. Duas engines e
envio simultâneo são verificados em R-08d antes de expandir tipos.
Resultados de commit/pendência/confirmação e erros devem ser verificáveis pela API pública.

Evidência de conclusão: [Execução R-05 — 2026-10-03](TRACEABILITY.md#execucao-r-05-2026-10-03).

<a id="r-10"></a>

## R-10 — LWW com coleções JSON tipadas

Status: concluída
MoSCoW: MUST
Dependências: R-09a, R-09b

Áreas: LwwRegister, LwwDelta, cópia de valores JSON e testes de core/facade.
Objetivo: corrigir casts que falham em coleções tipadas na API pública, mantendo
isolamento dos valores. MUST por impedir uso válido de um CRDT previsto.
Diagnóstico: aplicar LwwDelta<List<int>> com [1, 2] a LwwRegister<List<int>>
lança erro ao converter a cópia List<Object?> para List<int>.

Critérios:

- [x] Contrato genérico e cópia JSON compatíveis para listas e mapas tipados,
  incluindo valores aninhados; entradas inválidas continuam rejeitadas.
- [x] Aplicação de delta, consulta de value/winner, join, JSON e restauração
  seguem o contrato definido sem casts que falhem em valores válidos.
- [x] Alterações em valores fornecidos ou consultados não modificam estado/delta;
  preservar HLC, desempate e tombstones.
- [x] Regressões permanentes cobrem listas/mapas tipados, nulidade, isolamento e
  integração pelo caminho Object? de Replica/SyncEngine.
- [x] Documentar consumo tipado e compatibilidade de APIs/formatos; qualquer
  restrição ou mudança pública exige justificativa e caminho de migração.

Validação: reproduzir falha antes da correção e executar regressões após o review
das correções. Format/analyze/test no core e consumidores afetados; conferir SDK,
formatos persistidos e uso público, sem ampliar para um framework de codecs.

Evidência de diagnóstico: [revisão de 2026-10-11](TRACEABILITY.md#revisao-tecnica-2026-10-11).
Evidência de conclusão: [execução R-10](TRACEABILITY.md#execucao-r-10-2026-10-12).

<a id="r-13"></a>

## R-13 — Corrigir igualdade e hash de VectorClock

Status: concluída
MoSCoW: MUST
Dependências: R-02

Áreas: VectorClock e testes de core/facade.
Objetivo: preservar o contrato Dart entre igualdade e hash.
Diagnóstico reproduzido: relógios vazio e `{a: 0}` comparam iguais, mas têm hashes
diferentes; um Set mantém os dois. Gravidade média, com impacto em Set/Map.

Critérios:

- [x] Relógios iguais têm hash igual, inclusive componente ausente versus zero,
  entradas em ordens diferentes e múltiplas réplicas.
- [x] Regressões verificam inserção, deduplicação e consulta em Set/Map.
- [x] Preservar compare/tick/merge, JSON aceito e rejeição de valores inválidos;
  qualquer normalização de zeros tem compatibilidade explícita.
- [x] Consumidores e metadados existentes permanecem compatíveis; sem novo relógio.

Validação: reprodução anterior, regressões, format/analyze/test do core e facade;
review após correções. Não confundir hash com mecanismo de convergência.
Evidência de diagnóstico: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: [execução R-13 em 2026-10-12](TRACEABILITY.md#execucao-r-13-2026-10-12).

<a id="r-14"></a>

## R-14 — Rejeitar sequência inválida no snapshot MV-Register

Status: concluída
MoSCoW: MUST
Dependências: R-06c, R-07a

Áreas: MvRegister.fromJson, Replica.fromSnapshotJson e recuperação de engine.
Objetivo: rejeitar snapshot cujo contador local permite reutilizar dot observado.
Diagnóstico reproduzido: snapshot com dot local 1 e sequence 0 é aceito; a próxima
escrita falha. É entrada inconsistente; não foi observada em banco gerado pelo app.

Critérios:

- [x] Sequência restaurada é compatível com os dots da própria réplica no contexto,
  incluindo dots sem versão ativa; inconsistente falha antes de publicar estado.
- [x] Entradas inválidas falham explicitamente, sem corrigir silenciosamente IDs
  nem alterar JSON, política causal ou dados persistidos.
- [x] Regressões cobrem sequência atrasada, versão substituída, réplica distinta,
  restauração válida e novas escritas sem colisão de dots.
- [x] Validar o caminho de Replica e start da engine com snapshot inválido;
  falha não sobrescreve o banco nem estado válido, e retry continua possível.

Validação: core/facade, integração sync e recuperação SQLite quando afetada;
reproduzir antes, revisar correções e executar regressões após review.
Evidência de diagnóstico: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: [execução R-14 em 2026-10-12](TRACEABILITY.md#execucao-r-14-2026-10-12).

<a id="r-15"></a>

## R-15 — Recuperar abertura falha no consumidor Flutter

Status: concluída
MoSCoW: MUST
Dependências: VAL-07

Áreas: inicialização, erro, UI e recursos do consumidor em example/flutter_mobile.
Objetivo: permitir nova tentativa após falha de abertura sem exigir matar o app.
Diagnóstico por inspeção: catch de _open mantém _busy verdadeiro, sem ação de retry.

Critérios:

- [x] Erro de inicialização fica visível e oferece nova tentativa; ações que
  exigem engine restaurada continuam indisponíveis até sucesso.
- [x] Tentativa falha libera recursos adquiridos; retry não duplica engines,
  listeners ou commits e não apaga dados para contornar falha.
- [x] Regressão pertinente simula falha transitória e sucesso posterior,
  verificando UI, restauração e ausência de mutação antes de start.
- [x] Build e percurso no Android continuam preservando estado/outbox entre
  processos; modelo e UI permanecem no consumidor.

Validação: format/analyze e teste Flutter significativo de falha/retry; build e
runtime Android com plataforma registrada, após review das correções.
Evidência de diagnóstico: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: [execução R-15 em 2026-10-12](TRACEABILITY.md#execucao-r-15-2026-10-12).

<a id="r-16"></a>

## R-16 — Refatorar organização e remover código sem uso comprovado

Status: concluída
MoSCoW: SHOULD
Dependências: R-13, R-14, R-18

Áreas: core, sync, storage, exports, testes e documentação de manutenção.
Objetivo: localizar responsabilidades com menos duplicação, preservando comportamento.
Pedido do autor: avaliar divisão de pastas/arquivos e possíveis remoções até 16/11.

Critérios:

- [x] Inventariar responsabilidades e referências antes de mover/remover; distinguir
  código sem uso, APIs exportadas, migração, fixtures e possibilidades sem prova.
- [x] Definir layout por responsabilidades concretas: no core, avaliar CRDTs,
  metadados, réplica e serialização; reduzir concentração em Replica. Em sync e
  storage, separar contratos/DTOs/políticas da execução onde facilitar manutenção.
  Pastas/arquivos novos devem ter dono claro; evitar um arquivo por método.
- [x] Organizar testes por comportamento/tipo quando facilitar regressões, com
  fixtures compartilhadas apenas quando houver duplicação real.
- [x] Fazer uma fronteira por vez e conservar estados intermediários verificáveis.
  Registrar baseline e mesmas provas após cada extração relevante.
- [x] Preservar imports públicos, APIs, labels/versões JSON, schema SQLite,
  causalidade, identidade, rollback, ordem de commit, ACK/retry e lifecycle.
  Não misturar otimização, correção algorítmica ou funcionalidade nova à refatoração.
- [x] Remover apenas código sem uso demonstrado. Operation, PendingDeltaStore e
  aliases depreciados têm referências de migração/testes e política de compatibilidade;
  não removê-los como código morto. Remoção pública exige escopo/versão próprios.
- [x] Atualizar exports, exemplos e mapa de manutenção; explicar onde alterar
  estado, mutação, delta, join, commit e restauração no layout resultante.

Validação: safe-refactor e ciclo plan-executor; mesmos testes de unidade,
integração e SQLite antes/depois, incluindo facade e consumidor Flutter quando
afetados. Revalidar build/runtime se integração mobile mudar. Review do diff real
e das remoções. Se prazo impedir conclusão, registrar adiamento SHOULD;
reorganização cosmética não é requisito de fechamento nem prova de melhoria.
Evidência de motivação: [revisão e inventário](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: [execução R-16 em 2026-10-12](TRACEABILITY.md#execucao-r-16-2026-10-12).

<a id="r-18"></a>

## R-18 — Precisar contrato de retry e limites de consumo

Status: concluída
MoSCoW: MUST
Dependências: R-08c, VAL-04

Áreas: README, comentários públicos de sync e instruções dos consumidores.
Objetivo: descrever o comportamento existente sem prometer agendamento automático.
Diagnóstico: README chama retries de automáticos; a política só seleciona entradas
quando push é chamado. O consumidor é responsável por iniciar novas tentativas.

Critérios:

- [x] Explicitar quem chama ou agenda push, backoff, maxAttempts e force; não
  introduzir scheduler para corrigir uma descrição incorreta.
- [x] Distinguir sucesso local, pendência, ACK e falha; documentar caminho de
  atualização da UI sem anunciar stream de commits ainda não entregue.
- [x] Manter explícitos peer fixo, enlace sintético do exemplo, OR-Map com G-Set,
  plataforma efetivamente validada e ausência de economia universal de deltas.
- [x] Conferir API/README/exemplos contra código atual, com links e referências
  de manutenção válidos; escrita do TCC fica com o autor.

Validação: revisão documental, links/anchors, consistência com API e diff limpo.
Testes Dart só se houver mudança de código justificada dentro do escopo.
Evidência de diagnóstico: [revisão geral](TRACEABILITY.md#revisao-geral-2026-10-12).
Evidência de conclusão: [execução R-18 em 2026-10-12](TRACEABILITY.md#execucao-r-18-2026-10-12).

<a id="r-19"></a>

## R-19 — Compactar contexto causal do MV-Register com compatibilidade

Status: concluída
MoSCoW: COULD
Dependências: VAL-09, VAL-10

Áreas: MV-Register, representação de contexto causal, codecs/snapshots e integração
SQLite afetada; documentação de consumo e manutenção.
Objetivo: reduzir o custo demonstrado de contexto mantendo o mesmo conhecimento
causal, valores e comportamento após entrega atrasada/restauração.
Entrada: VAL-09 aprovada, VAL-10 com custo e ganho esperado identificados e margem
para implementação, review, migração e validação confirmada pelo autor em
2026-10-12: “questão de prazo está ok. Pode ser feito agora”. O adiamento anterior
foi superado por essa direção explícita; estimativa numérica de capacidade não é
um bloqueio adicional. Se a implementação não demonstrar ganho ou encontrar
impedimento concreto, registrar resultado e reavaliar a entrega COULD.
Defeito de correção encontrado na investigação exige tarefa de correção própria;
não classificar perda de informação como otimização opcional.

### Sequência de execução e pontos de alteração

1. **Baseline e inventário.** Reexecutar as cargas fixas de VAL-10 antes de editar
   código e guardar resultados em TRACEABILITY. Localizar contexto do estado,
   de cada versão e de cada delta em
   [mv_register.dart](../packages/deltasync_core/lib/src/mv_register.dart);
   listar consumidores de `MvRegisterDelta.context`, codecs, export/bootstrap,
   cópia de Replica, snapshots e outbox. Baseline reexecutada em Linux x86_64,
   Dart 3.13.5 e SQLite FFI. DeltaCodec passou de v3 para v4 e snapshot interno
   de Replica v8 para v9. Envelope `ReplicaSnapshot` v2, outbox v2 e schema
   SQLite v1 não mudam; formatos antigos são lidos e regravados no próximo
   commit atômico, sem migração de schema.
2. **Representação causal mínima.** Introduzir um auxiliar de contexto no core,
   usado pelo MV-Register, com prefixo contíguo por `(replicaId, crdtId)` e dots
   esparsos acima desse prefixo. Definir pertencimento, inclusão, união, cópia
   isolada e codificação determinística. Comparar essas operações com `Set<Dot>`
   explícito em testes; dots 1 e 3 não incluem 2. Contexto de delta deve permanecer
   imutável, sem compartilhar mutações com estado ou versões. Uma representação
   canônica é a fonte de verdade; views de compatibilidade não são estado paralelo.
3. **Integração no MV-Register e compatibilidade.** Aplicar o auxiliar ao estado,
   às versões e aos deltas, mantendo escrita, applyDelta, mergeState, export e
   sequência local. Preservar construtor com `Iterable<Dot>` e leitura pública
   de `context` quando viável, como conversão na fronteira; operações internas e
   serialização compacta não devem expandir todos os dots a cada escrita.
   Definir formato compacto versionado, leitura do contexto explícito anterior,
   validação de lacunas/endereço e rejeição por leitores incompatíveis. Evitar
   gravar lista explícita junto do formato compacto, pois repetiria o custo alvo.
   Não fixar novos números de versão antes do inventário; alterar apenas as
   versões cujos formatos mudarem e documentar qualquer incompatibilidade pública.
4. **Persistência e recuperação.** Exercitar snapshot e outbox anteriores em
   banco SQLite real, fechar/reabrir e continuar escrevendo. A conversão preserva
   IDs, destinatários e metadados de tentativas; falha cancela o commit inteiro.
   Comparação de payload pendente deve reconhecer contextos semanticamente iguais
   nos dois formatos e continuar rejeitando divergências. Registrar rollback por
   conversão validada ou backup consistente anterior à migração. Backup só cobre
   rollback antes de aceitar novos commits; após novas escritas, a reversão deve
   preservar também essas mudanças e pendências. Não pressupor que binário antigo
   lê dados compactos novos, nem apagar banco ou pendências.
5. **Review, medição e validação.** Revisar diff com atenção a lacunas, namespaces,
   replay, aliasing, migração e ACK. Corrigir achados e repetir review/checks
   afetados. Reexecutar VAL-09 e cargas VAL-10 com mesmas entradas; registrar
   bytes, unidades compactas e dots logicamente representados separadamente.
   Revalidar o gate técnico VAL-05 após a mudança, com registro adicional que
   preserve as evidências históricas e as limitações das plataformas executadas.
6. **Consumo e manutenção.** Atualizar documentação e mapa de responsabilidades
   para localizar estado, mutação, delta, join, commit e restauração; mostrar
   leitura de dados anteriores e caminho público de integração. Registrar
   escolhas, riscos, comandos e resultado por etapa; só então marcar critérios
   e concluir R-19 no índice e na fase.

### Ganho esperado e limite da comparação

VAL-10 mediu 496 referências causais nos deltas pendentes de 32 escritas MV
sequenciais, 35.877 B de delta e 4.109 B de snapshot. Esses números são baseline
histórica, não validação da mudança. Nessa carga de um namespace sem lacunas,
cada contexto não vazio pode ser representado por um prefixo, preservando os
mesmos 496 pertencimentos lógicos no lote. Demonstrar redução dos bytes de delta
e outbox nas cargas N=16 e N=32 frente à baseline reexecutada; medir snapshot e
custo de conversão/commit, sem exigir melhoria universal de tempo ou arquivo
SQLite. Incluir carga com lacunas e concorrência para explicitar os limites.
Não prometer remoção da necessidade de contexto causal nem agregação de IDs.

Critérios:

- [x] Delimitar primeiro MV-Register e a representação responsável pelo custo
  medido: estado, contexto do delta ou snapshot. Registrar baseline, ganho
  esperado e limite da mudança. OR-Set/OR-Map só entram em tarefa posterior se
  medições e semântica justificarem; não reescrever os oito CRDTs nesta tarefa.
- [x] Representar prefixos contíguos observados e dots esparsos com lacunas,
  preservando namespaces `(replicaId, crdtId)`. Comparar pertencimento e join do
  contexto compacto contra a representação explícita usada como referência;
  receber dot 3 nunca inventa observação dos dots 1/2.
- [x] Preservar substituição causal, versões concorrentes, identidade e
  sequência local, sem ressuscitar versão eliminada após replay/merge/restore.
  Compactação deve preservar informação causal; nenhum descarte por idade,
  envio ou ACK, e nenhuma alteração silenciosa de semântica.
- [x] Inventariar APIs, JSON, snapshots e outboxes existentes antes da mudança.
  Manter formatos quando possível; mudança necessária exige versão explícita,
  leitura/migração de dados anteriores, rejeição segura por leitor incompatível
  e percurso de rollback documentado. Não apagar bancos ou pendências para migrar.
- [x] Preservar commit atômico, recuperação durável, IDs da outbox e confirmação
  por mudança/peer. Não eliminar IDs pendentes por dominância como consequência
  da compactação do estado; agregação de envio exige escopo próprio.
- [x] Repetir propriedades e cenários pertinentes de VAL-09 nas duas
  representações, incluindo lacunas, origens/endereço distintos, snapshots
  antigos, falhas de migração, nova escrita após restore e replay atrasado.
  Validar integração SQLite com fechamento/reabertura e rollback real.
- [x] Repetir as cargas de VAL-10 com parâmetros e contabilidade iguais;
  demonstrar redução dos bytes de delta e outbox MV em N=16/N=32, distinguindo
  unidades compactas de dots lógicos, registrar custo adicional e limites de
  lacunas/concorrência. Atualizar APIs/exemplos/mapa de manutenção afetados,
  revisar após correções e revalidar VAL-05 antes de concluir.

Um auxiliar de contexto deve ter operações e dono claros. Um DotKernel comum
só se justifica por regras comprovadamente comuns nos tipos alterados, sem criar
hierarquia paralela, framework de plugins ou OR-Map genérico. A referência C++
orienta conceitos e casos; não determina layout, interfaces nem política LWW.

Validação: baseline e provas antes/depois; format/analyze/test do core, facade e
pacotes/consumidores afetados; equivalência causal e de deltas, compatibilidade de
formatos, recuperação SQLite e medição reproduzível. Mudança que atingir o
consumidor mobile exige checks/build/runtime proporcionais. VAL-05 revalida o
resultado após R-19; R-19 não é dependência MUST do gate.
Evidência de motivação: [referência delta-crdts C++](TRACEABILITY.md#referencia-delta-cpp-2026-10-12).
Evidência de entrada e planejamento: [planejamento R-19 em 2026-10-12](TRACEABILITY.md#planejamento-r-19-2026-10-12).
Evidência de conclusão: [execução R-19 em 2026-10-12](TRACEABILITY.md#execucao-r-19-2026-10-12).

<a id="r-20"></a>

## R-20 — Refatorar responsabilidades e eliminar duplicação estrutural

Status: concluída
MoSCoW: SHOULD
Dependências: R-16, R-19

Áreas: core, sync, storage, facade, consumidor e documentação de manutenção.
Autorização: autor pediu refatoração geral, com redução de acoplamento e
duplicação, além das extrações em arquivos de R-16. Preservar oito CRDTs,
contratos públicos, formatos v4/v9/v2/schema v1 e regras observáveis.

Critérios:

- [x] Inventariar responsabilidades e registrar baseline antes de alterar código.
- [x] Consolidar armazenamento dos CRDTs e operações repetidas de cópia,
  exportação, merge e restauração; Replica coordena identidade/metadados/mutações,
  sem manter representações paralelas ou framework genérico de plugins.
- [x] Separar validação de lote e codec de snapshot por contratos explícitos,
  preservando versões antigas, identidade, atomicidade e lacunas causais.
- [x] Separar persistência, envio/ACK e fila serial do lifecycle do SyncEngine;
  compartilhar percurso de commit local simples/em lote e remoto, sem bloquear
  edição durante rede lenta nem perder eventos ou IDs da outbox.
- [x] Dar ao contexto causal MV dono independente e consolidar leitura explícita/
  compacta. Desacoplar adaptador MemoryStorage do contrato; preservar imports
  públicos e remover apenas duplicações/código com uso substituído comprovado.
- [x] Revisar diff após correções; executar mesmas provas de core/sync/storage,
  SQLite com reabertura/rollback, facade e consumidor Flutter antes/depois.
- [x] Atualizar mapa de manutenção, decisões/riscos e evidências por etapa;
  revalidar gate técnico e executar checker/diff antes de concluir.

Validação: safe-refactor por fronteira, baseline e checks intermediários;
analyze/test de todos os pacotes e facade; Flutter analyze/test/build do consumidor.
Build/runtime adicionais se integração de plataforma mudar. Sem escrita do TCC.
Evidência de conclusão: [execução R-20 em 2026-10-13](TRACEABILITY.md#execucao-r-20-2026-10-13).

<a id="r-21"></a>

## R-21 — Reduzir travessias e alocações redundantes no core

Status: concluída
MoSCoW: SHOULD
Dependências: R-20

Áreas: validação de lotes/JSON, contexto MV e consulta pontual de ReplicaState.
Objetivo: eliminar trabalho evitável identificado na revisão de 2026-10-13,
mantendo contratos, isolamento, causalidade e comportamento de falhas.
Motivação: `change.context.any(...)` expande os prefixos compactos MV;
`validateJsonInput` copia e serializa o mesmo valor; `ReplicaState.operator[]`
constrói a visão de todos os valores para consultar um endereço.
Entrada: R-20 concluída; melhorias de custo não constituem novos requisitos MUST
acadêmicos. Defeito de correção confirmado deve receber tarefa MUST própria.

Critérios:

- [x] Registrar baseline e entradas fixas para validação MV com prefixos/lacunas,
  valores JSON aninhados e consulta de um campo em estado com muitos endereços.
  Separar custo estrutural, alocações observadas e tempo; não prometer ganho universal.
- [x] Validar contexto MV sem materializar a lista pública de dots nas operações
  internas afetadas. Manter `MvRegisterDelta.context` compatível e preservar
  validação de endereço, origem, sequência, lacunas e formatos explícito/compacto.
- [x] Consolidar validação JSON usando as regras existentes em um dono claro.
  Rejeitar ciclos, chaves não-string, números não-finitos e objetos não-JSON antes
  da mutação; preservar ordem, classe de erro e ausência de efeitos parciais.
- [x] Consultar somente o endereço solicitado em `ReplicaState.operator[]`,
  preservando campo ausente/null/tombstone e cópia isolada de coleções aninhadas.
  A visão `values` mantém seu contrato; consulta não expõe registros mutáveis.
- [x] Preservar cópias necessárias de candidata/adoção, commit/rollback, IDs e
  sequências. Remover apenas travessias/materializações substituídas com prova;
  não alterar joins, GC, API pública nem formatos v4/v9/v2/schema v1 por otimização.
- [x] Revisar após correções e executar format/analyze/test do core e consumidores
  afetados, incluindo sync/facade e SQLite com reabertura/rollback quando pertinentes.
  Demonstrar os percursos simplificados com mesmos dados antes/depois; medir limites.
- [x] Atualizar mapa de manutenção, decisões/riscos e evidências; revalidar gate
  técnico com checks proporcionais e liberar VAL-11 ao concluir.

Validação: safe-refactor e ciclo plan-executor; comandos `dart format`,
`dart analyze` e `dart test` nos pacotes afetados. Registrar versão do SDK do PATH,
casos de falha, compatibilidade e resultados das cargas fixas.
Evidência de motivação: [revisão e planejamento de 2026-10-13](TRACEABILITY.md#manutencao-ajustes-consumidor-2026-10-13).
Evidência de conclusão: [execução R-21](TRACEABILITY.md#execucao-r-21-2026-10-13).

<a id="r-22"></a>

## R-22 — Reutilizar enlace comum dos exemplos sem generalizar infraestrutura

Status: pronta
MoSCoW: COULD
Dependências: R-20

Áreas: demonstrações CLI/Flutter e código de suporte dos exemplos.
Objetivo: compartilhar o comportamento repetido de DemoPeerLink/PeerLink,
comprovado nos exemplos, mantendo cada cenário legível e executável.

Critérios:

- [ ] Comparar implementações e distinguir enlace comum de doubles que simulam
  falhas, retry ou entrega parcial; registrar baseline dos exemplos afetados.
- [ ] Reusar apenas o enlace comum em suporte Dart dos exemplos, com dependências
  públicas da biblioteca. Sem pacote novo, framework de mocks ou transporte de
  produção no core; variantes com comportamento diferente permanecem justificadas.
- [ ] Preservar peer fixo, confirmação somente após commit remoto, fechamento
  do stream e falhas observáveis. Manter comandos CLI e consumidor Flutter
  executáveis sem depender de detalhes privados ou caminhos locais de SDK.
- [ ] Revisar após correções e validar demonstração offline/reconnect, testes e
  build do consumidor quando afetados, incluindo caminhos de import e uso isolado.
  Se executada após VAL-12 e alterar o consumidor Flutter, repetir o percurso
  runtime afetado antes de reutilizar a evidência Android como resultado do app atualizado.
- [ ] Registrar ganho concreto de manutenção e compatibilidade dos exemplos;
  atualizar README/mapa/evidências. Adiar explicitamente se compartilhamento
  aumentar dependências ou dificultar consumo mais do que a repetição pequena.

Validação: safe-refactor; `dart analyze` e exemplos pertinentes; `flutter analyze`,
`flutter test` e build se consumidor afetado. COULD não condiciona R-21 ou VAL-11/12/13.
Evidência de motivação: [revisão e planejamento de 2026-10-13](TRACEABILITY.md#manutencao-ajustes-consumidor-2026-10-13).
Evidência de conclusão: ainda não registrada.

<a id="r-23"></a>

## R-23 — Preservar equivalência da adição repetida no G-Set

Status: concluída
MoSCoW: MUST
Dependências: R-06a

Áreas: mutação G-Set, seleção canônica de eventos, delta e restauração.
Origem: histórias VAL-11 reproduziram divergência após observar um valor remoto
e adicioná-lo localmente. DEC-36 exige registrar defeito de correção como MUST.
A correção começou durante VAL-11; esta tarefa formaliza seu fechamento próprio.

Critérios:

- [x] Registrar regressão mínima: réplica a recebe adição de b, adiciona mesmo
  valor e compara snapshot local com aplicação do delta numa cópia anterior.
  Demonstrar falha anterior e aprovação depois da correção.
- [x] Aplicar a mesma seleção canônica na mutação e no delta, inclusive sem valor
  novo. Preservar valor, sequência, compacidade, IDs e formatos; sem GC novo.
- [x] Revisar correção e cobrir histórias/permutações, replay, restauração e SQLite
  real. Validar pacotes afetados e consumidor, com comandos do PATH.
- [x] Registrar compatibilidade, causa, evidências e limites; revalidar gate
  técnico e liberar fechamento de VAL-11 somente após aprovação.

Validação: ciclo plan-executor; format/analyze/test do workspace e Flutter
analyze/test. Sem mudança de API, formato ou integração de plataforma.
Evidência de motivação: [execução VAL-11](TRACEABILITY.md#execucao-val-11-2026-10-13).
Evidência de conclusão: [execução R-23](TRACEABILITY.md#execucao-r-23-2026-10-13).

<a id="r-25"></a>

## R-25 — Consultar valores pela engine sem copiar todo o estado

Status: concluída
MoSCoW: MUST
Dependências: R-21, VAL-13

Áreas: API pública de consulta em sync/core e consumidores.
Origem: análise da integração Compass e autorização do autor em 2026-10-13.

Critérios:

- [x] Definir consulta pública por endereço, com lifecycle explícito, preservando absent/null/tombstone e sem expor Replica, registros ou coleções mutáveis.
- [x] Consultar somente o campo solicitado, sem fork da réplica nem cópia integral do estado; preservar cópias necessárias ao isolamento e aos commits.
- [x] Cobrir os oito tipos, valores aninhados, tentativa de mutação do resultado, restauração e consulta durante falha de rede. Comparar percursos com entrada fixa; sem promessa universal de desempenho.
- [x] Atualizar consumo/documentação e testar core/sync/facade e SQLite quando afetados. Revisar após correções; manter API e formatos anteriores compatíveis.

Validação: ciclo plan-executor, checks proporcionais ao contrato/consumidor afetado;
regressões e compatibilidade são obrigatórias na própria tarefa.
Evidência de motivação: [planejamento de ergonomia](TRACEABILITY.md#manutencao-ergonomia-2026-10-13).
Evidência de conclusão: [execução R-25](TRACEABILITY.md#execucao-r-25-2026-10-13).

## Gate da fase

Revisar diff de cada tarefa, executar verificações acima e análise dos pacotes
afetados. Concluir fase somente com evidências de R-01 a R-05, R-09a/R-09b,
R-10 e R-13/R-14/R-15/R-18. R-16 SHOULD não bloqueia fechamento com adiamento justificado.
R-09b libera envelopes; R-08d libera expansão dos tipos e contrato durável.
R-23 MUST, descoberta em VAL-11, também exige fechamento antes de reutilizar o gate.
R-25 exige consulta isolada e validação antes de novo fechamento em VAL-05.
Limpeza documental não conclui correções de código.
