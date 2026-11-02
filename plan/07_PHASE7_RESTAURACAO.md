# Fase 7 — Correção da restauração com outbox extensa

Estado: R-44 e R-45 concluídas. Gate histórico da 1.0.1 permanece concluído e
publicado; esta correção posterior não autoriza nova publicação.

<a id="r-44"></a>

## R-44 — Evitar replay quadrático na restauração

Status: concluída
MoSCoW: SHOULD
Dependências: R-43

Origem: piloto CP-15 com 1.000 notas LWW e 1.000 pendências em dois Androids.
Primeira restauração levou 32–52 s. Diagnóstico em cópias SQLite isolou o
replay individual após snapshot; [evidência](../../samples_test_lib/compass_app/app/evidence/cp-15/restore-investigation.md).

Critérios:

- [x] Preservar ordem, validação, HLC, clocks, sequência, isolamento, falha
  atômica e formatos persistidos ao restaurar outbox extensa. Não descartar
  pendências apenas porque aparecem no snapshot; manter leitor legado.
- [x] Remover cópias repetidas do estado por entrada no caminho de restauração,
  sem alterar comportamento público de `Replica.apply` nem protocolo de sync.
- [x] Regressões para os oito CRDTs, outbox com múltiplas entradas, dados
  conflitantes, snapshot legado e recuperação real SQLite após processo novo.
- [x] Medir antes/depois N=1/N=1000 em cópias fechadas e Android físico profile
  nos dois aparelhos; auditar chaves, outbox/ACK, hashes e limites de medição.
- [x] Review próprio após correções, validação do consumidor/facade e manutenção
  de plano/risco/evidência; não declarar release publicada.

Validação: análise/testes dos pacotes afetados e facade, integração SQLite,
consumidor Compass, medições comparáveis, checker e diff.

<a id="r-45"></a>

## R-45 — Preparar metadados da versão 1.0.2

Status: concluída
MoSCoW: SHOULD
Dependências: R-44

Origem: autor vai commitar a correção e os registros e solicitou preparação
para 1.0.2. Manter os sete pacotes alinhados, conforme o fluxo anterior.
Preparação local não autoriza publicar, criar tag, commit ou push.

Critérios:

- [x] Atualizar sete versões e 17 constraints internas para 1.0.2/^1.0.2,
  preservando SDK e formatos/API da 1.0.1.
- [x] Acrescentar changelogs proporcionais à mudança real, identificando R-44
  em sync/facade, regressões SQLite e somente alinhamento nos demais pacotes.
- [x] Atualizar instruções atuais de consumo/publicação, preservando histórico
  1.0.1, medições congeladas e melhorias futuras do hub ainda não implementadas.
- [x] Revisar metadados, resolver workspace, validar sete pacotes e exportar
  diretórios standalone com versões/constraints e inventário conferidos;
  registrar limites e manter gate/publicação de 1.0.2 separados.

Validação: formato/análise/testes dos sete pacotes, resolução local, inventário
de exportação, checker e diff. Sem novo ensaio físico por renumeração de pacote.

Evidência de conclusão: [execução R-45](TRACEABILITY.md#execução-r-45--2026-11-02)
e [checks/inventário](evidence/r45-preparacao-1.0.2/README.md).

## Gate da fase

R-44 só conclui com todos os critérios e sem regressão durável. O resultado
informará uma versão futura; a 1.0.1 publicada não será alterada.

R-45 preparou a versão futura como 1.0.2 e validou metadados/workspace/exportação.
Isso não conclui um gate de publicação dos novos artefatos nem autoriza envio.

Resultado e limites em [evidence/r44](evidence/r44/README.md).
