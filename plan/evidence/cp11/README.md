# CP-11 — série principal de escala

Concluída em 2026-11-02. G52/API 33 e G53/API 34 executaram seis pares on/off
por carga, N=1 e N=1000 notas LWW distintas: 12 pares válidos, 72 fases A/B/A.
Dois pares de aquecimento (quatro condições) ficaram fora da amostra.
Uma tentativa de N=1/par 5 falhou durante o preflight por perda dos dois
dispositivos no ADB; nenhuma fase medida começou. Foi preservada e excluída,
antes de calcular estatísticas. Após reconexão, usou-se namespace novo.

## Artefatos e reprodução

Cofre local:
`/projetos/tcc/samples_test_lib/compass_app/app/.performance-artifacts/cp-11/175064aec0144dc08a66f7ec88bbe394/`.
Manifesto SHA-256:
`f31292331b17d2389313c52138c516724ea394bf11faea5fa4ef4a6205b295ac`.
448 arquivos, 82.670.945 bytes, copiados e verificados por tamanho/hash.
Incluem relatórios, SQLite fechados, inspeções públicas, estados de hub,
HTTP por rota, estado dos aparelhos, scripts efetivos, comandos/saídas,
exclusões, auditoria e recibos de limpeza.

Base imutável: [CP-16](../cp16/matriz.md), manifesto
`d21d29542d46d1761360b433fbf750aeb711f72b97236fcc368382de91debc1c`.
Antes da primeira medição, abriu-se a coorte acima com correção exclusiva do
controlador: confirmar USB em `dumpsys usb`, aceitando alimentação reportada
como AC ou USB. O G53 reportava AC mesmo conectado por USB. Quatro casos
positivos/negativos e os dois aparelhos validaram o gate. Hash do controlador:
`9aa489ea3ae07debfab322e179790d086d5415cb1d2d74d0edcd08c6707e6674`.
APKs/configs/fixtures/hub e demais 237 fontes mantiveram hashes da base.
O controlador efetivo foi copiado antes da coleta; não se mesclaram coortes.

Play Protect pediu envio opcional durante reinstalações; selecionado “Não
enviar”. Auxiliar automatizou essa ação somente durante processos de instalação,
com texto do diálogo conferido, fora das janelas medidas. Ações posteriores à
ativação do auxiliar constam em `dialog-actions.jsonl`.

## Etapas e critérios

- Leitura: dependência CP-16 satisfeita; mantidos extremos, seis pares/carga,
  alternância on/off, aquecimentos, USB e limites da matriz. CP-10 continua
  parcial e histórico; M1–M6 não foram repetidos.
- Implementação: correção localizada do gate USB, congelamento do controlador
  efetivo e execução sequencial, com intenções persistidas antes dos comandos.
- Revisão própria após correção: conferido diff contra o controlador CP-16,
  isolamento dos pares, falha fechada do gate, escopos medidos e retomada em
  namespace novo. Sem achados impeditivos restantes; review não independente.
- Validação: controlador aprovou N chaves, N−1 valores preservados, seq=N+1,
  ACK/outbox vazia, push/pull/ACK HTTP 200, igualdade integral A/B/hub e nenhuma
  perda/falha do coletor ligado. Off mantém métricas internas ausentes.
  [audit_series.py](audit_series.py) reabriu todos os relatórios/inspeções e
  confirmou 12 pares principais, dois aquecimentos e a exclusão declarada.
  Comando: `python3 plan/evidence/cp11/audit_series.py <cofre>`.
- Manutenção: seis critérios CP-11 atendidos; CP-12 pronta. APKs anteriores
  restaurados, apps parados, bancos antigos com hashes preservados, portas
  8091/8092 fechadas. Regra UFW preexistente mantida. Checker e diffs conferidos.

Esta entrega comprova coleta e integridade. Análise e ameaças à validade são
CP-12; p95 de seis valores é o máximo descritivo. O recorte Android é LWW com
hub HTTP local, snapshot pull e USB/ADB; não generalizar para oito CRDTs, WAN
ou energia. A lib corrigida é fonte local R-44, ainda não publicada em 1.0.1.
