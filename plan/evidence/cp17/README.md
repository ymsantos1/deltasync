# CP-17 — piloto incremental N=1000

Concluído em 2026-11-02. Resultados e interpretação no consumidor externo:
`../../../../samples_test_lib/compass_app/app/docs/piloto-incremental-deltasync.md`.
Um piloto, coletor off, três fases A/B/A; memória não faz parte deste recorte.

## Brutos e reprodução

Cofre local:
`/projetos/tcc/samples_test_lib/compass_app/app/.performance-artifacts/cp-17/85b0ff7df9624c81aeef8f0a1b43506d/`.
Manifesto SHA-256:
`5bef169dcff477d6cb8c3bfe49bd29e4e05accbf8669360dcd38d7703dec14c1`.
67 arquivos, 135.557.364 bytes, todos conferidos após cópia ao cofre.

Inclui dois APKs profile/configs/logs, archive de 240 fontes, SQLite e inspeções
de origem CP-11, hub, scripts de preparo/execução, ambiente Flutter/Android,
corpos HTTP, relatórios, CSVs, comandos, recibos de limpeza e hashes dos bancos
anteriores. Fonte CP-11: último par N=1000/off, com A-second/B-first e hub
iguais e sem pendências; não foram usados bancos com backlog CP-14.

`sources.tar.gz`/`controller.py` retêm a versão anterior à correção de
transferência; **`controller-v2.py` é o controlador efetivamente aprovado**,
congelado antes das medições. `transfer-correction.json` identifica a alteração.
O instrumento Dart e APKs permaneceram os mesmos. `command-attempt2.json`
contém o comando real; `launch2.py` e `prepare.py` preservam o preparo.
Reprodução exige namespace/saída novos e fontes/identidades correspondentes,
preservando cópias originais. Não executar o comando histórico sobre sua saída
existente. O parâmetro herdado `--cp14-device` aponta aos inputs sincronizados
CP-17; o controlador valida pendências zero e estados iniciais iguais.

## Etapas e critérios

- Leitura: pedido autorizou piloto curto de uma nova alteração após sincronizar
  1000 notas. CP-13 satisfeita; matrizes anteriores e worktrees preservados.
- Implementação: novos entrypoint/controlador no consumidor. Somente A edita;
  estado inicial sem pendências, cópias/relatórios novos, hub clonado e protocolo
  snapshot mantido. CPU/UID e Stopwatch externos ao coletor seguem disponíveis
  com coletor desligado. Capturados corpos request/response para contar mudanças.
- Review próprio após correção: primeira transferência por heredoc tentou criar
  temporário em diretório não permitido. Tentativa `run` falhou antes de medir e
  teve limpeza aprovada. Corrigido para stdin binário com shell quoting, recusa
  de sobrescrita e hash no aparelho. `run2` usa outro namespace. Sem achados
  impeditivos restantes; revisão não independente.
- Validação: formatação, `flutter analyze --no-pub`, `flutter test --no-pub`
  (141 testes), dois builds profile ARM64 e piloto nos G52/G53 passaram.
  A teve 0→1→0 pendências, B e A-second 0→0→0. Push com uma mudança; pull/ACK
  de A com 1000 mudanças/IDs. N−1 valores preservados, seq incrementada apenas
  em A, outboxes vazias e mapas A/B/hub iguais ao término. Releitura dos corpos
  e inspeções confirmou os resultados. Baseline e hashes finais dos bancos
  anteriores são iguais; limpeza sem erros e portas encerradas.
- Manutenção: quatro critérios CP-17 marcados; complemento do artigo, índice,
  roteiro e TRACEABILITY atualizados; checker e diffs após manutenção.

## Limites e resultado útil

Uma execução por fase, sem p95/mediana ou inferência causal. No G52, edição
135,443 ms (CPU 136 ms) e sync 587,468 ms (CPU 343 ms). Push de uma mudança:
737 bytes. Pull: 502025 bytes; ACK: 77028 bytes com 1000 IDs. O volume
remanescente é observável na configuração snapshot do hub da amostra.
Não é medição de pull por deltas nem prova de defeito do core. UID zero nas
janelas não anulou o HTTP capturado; PSS/heap/pico/energia não foram avaliados.
O relatório CP-13 e os manifestos CP-11/CP-12/CP-13 permanecem históricos e
íntegros; este complemento registra o experimento que antes era proposto.

## Complemento de análise para o artigo

A análise do problema no relatório externo
`../../../../samples_test_lib/compass_app/app/docs/piloto-incremental-deltasync.md#analise-do-problema`
liga payload, comportamento e camada responsável. O primeiro sync de A somou
580009 bytes de corpos JSON; pull e ACK responderam por 579064 bytes (99,84%).
Essa proporção não é previsão de economia nem divisão do tempo gasto.
As fontes consultadas do hub/transporte conferem com os hashes CP-17.

Foram registrados o motivo de segurança do modo snapshot para dois clientes,
as hipóteses de melhoria por peer, os critérios de validação futura e um texto
de discussão para o artigo. O estudo não demonstrou necessidade de mudar o
core nem os contratos públicos; essa avaliação permanece trabalho futuro.
Os brutos e seus manifestos permanecem inalterados. Acréscimo apenas documental.
