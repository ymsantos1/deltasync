# R-34 — Piloto Saropa essential

Decisão: **adiar a adoção permanente de Saropa** nesta entrega. Manter
`package:lints/recommended.yaml`, o job Flutter próprio e a consulta de advisories
da R-33. O piloto funciona com Dart 3.13.5; não há motivo demonstrado para voltar
a Dart 3.12. O custo adicional, o ruído contextual e a diferença de cobertura
entre scanner e plugin não justificam alterar agora a configuração dos usuários
ou dos contribuidores.

Execução em 24–25/10/2026, Linux x64, Dart 3.13.5 e Flutter 3.47.7.
Revisão inicial: `2a42a0b9f2143fc36e2b793d4e86867d5217623a`, worktree limpa.
Dois clones descartáveis separaram a medição da experimentação com o plugin.
Todos os comandos usaram `dart`/`flutter` do PATH; nenhum runtime 3.12 foi usado.
As cinco etapas estão no [registro da execução](../../TRACEABILITY.md#execucao-r-34-2026-10-25).

## Versão, resolução e integração

Runner isolado com `saropa_lints: 16.7.0` exato, sem dependência adicionada aos
sete pacotes ou ao app. O [manifest do runner](runner.pubspec.yaml.txt) e os
[grafos resolvidos](resolutions.json) permitem verificar as versões.
Metadados do [Pub API](https://pub.dev/api/packages/saropa_lints) e o hash
verificado pelo cache Pub concordam com o arquivo publicado:

```text
https://pub.dev/api/archives/saropa_lints-16.7.0.tar.gz
sha256: 22f997a97a06528394ecaa68a71c75ca3ee50e4243643bb3c1e8eb6f85bdd3fa
SDK declarado por Saropa: >=3.9.0 <4.0.0
analyzer do runner: 12.1.0
```

O mínimo de SDK permite 3.13; a resolução e o scan resolvido efetivamente
passaram nessa versão. O analyzer 12.1.0 instalado declara language version
3.13.0. Isso não representa execução no patch 3.13.0 nem em outras plataformas.

| Experimento | Resultado observado |
|---|---|
| Workspace sem Saropa | test 1.33.0, analyzer 14.6.0, lints 6.1.0; análise limpa |
| Runner separado | Saropa 16.7.0/analyzer 12.1.0; scanner executa sem alterar o workspace |
| Saropa e test 1.33.0 no mesmo manifest | Resolução falha, exit 1: test exige analyzer >=13.0.0 <15.0.0; Saropa exige ^12.1.0 |
| Saropa e test ^1.25.6 no mesmo manifest | Resolve, mas escolhe test 1.31.1 e analyzer 12.1.0 |
| Plugin nativo isolado pelo analyzer | Workspace conserva test 1.33.0/analyzer 14.6.0; plugin inicia sem dependência Saropa no manifest |
| Exemplo Flutter | Resolução própria com --enforce-lockfile; análise original limpa e CLI resolvida analisa seus 13 arquivos |

A incompatibilidade comprovada é entre essas dependências no **mesmo grafo**,
não uma rejeição geral ao Dart 3.13. O plugin nativo tem resolução separada;
não usar o conflito da fixture como alegação de impossibilidade dessa integração.
Não se recomenda rebaixar test para obter lint. A resolução atual também não é
a resolução histórica da R-33: analyzer 14.6.0 foi selecionado neste checkout.

O nome `essential` não assegurou conjuntos idênticos nos caminhos experimentados:

- CLI `--tier essential --resolve`: 334 regras carregadas, lane full.
- Bloco `plugins` copiado do YAML essential publicado, com versão fixada em
  16.7.0 e os includes originais preservados: 42 regras explícitas; o log do
  plugin mostrou quatro habilitadas na lane light padrão. Análises do contrato
  storage e do app retornaram zero, sem demonstrar a cobertura da CLI.
- Com `lane: full` em `analysis_options_custom.yaml`: análise do contrato storage
  retornou nove diagnósticos/exit 2; Flutter continuou com zero.
- Inicializador oficial `saropa_lints:init --tier essential --reset --target ...`,
  executado somente no clone: gerou 254 regras habilitadas por projeto e manteve
  os includes recommended/Flutter. Com lane full, a raiz retornou 141
  diagnósticos/exit 3; Flutter retornou zero/exit 0, enquanto a CLI encontrou 25.
  Os arquivos gerados tinham 344/342 linhas; nada foi copiado à configuração real.
- Remover somente a exclusão Flutter da raiz desse clone não eliminou a
  diferença: Flutter ainda retornou zero. A causa da divergência nativa não foi
  estabelecida. Não tratá-la como análise equivalente, integração aprovada ou
  defeito comprovado do app. Antes de eventual adoção, exigir controle positivo
  no próprio contexto Flutter e explicar filtros/configuração efetivos.

Esses resultados avaliam a integração; não constituem um gate Saropa aprovado.
A CLI com lista explícita cobre todos os pacotes pertinentes sem depender de
exclusões padrão de `example/`. Ver [logs resumidos](logs.txt) e [probes](pilot.json).

## Medição e cobertura

Após resolver dependências e compilar o scanner, executaram-se duas passagens
por alvo e ferramenta. A baseline usa `dart analyze` nos sete pacotes e
`flutter analyze --no-pub` no app. O scanner recebe os arquivos Dart rastreados
de cada alvo via stdin; não inclui código gerado/cache. Os 116 arquivos são
únicos, com hashes iguais aos fontes da worktree, listados no
[inventário](inventory.json). A raiz do analyzer também percorre subpacotes;
portanto as tabelas descrevem o custo dos comandos de manutenção, não um
benchmark com trabalhos internos idênticos.

Valores da segunda passagem, já aquecida. Memória em MiB, convertida do
`ru_maxrss` em KiB observado por `os.wait4` no Linux:

| Alvo | Arquivos CLI | Alertas CLI | Baseline (s) | CLI adicional (s) | RSS baseline/CLI (MiB) |
|---|---:|---:|---:|---:|---:|
| facade, exemplos e ferramentas | 19 | 40 | 1.080 | 13.101 | 179.2 / 706.1 |
| core | 44 | 46 | 0.487 | 8.500 | 107.7 / 379.4 |
| sync | 17 | 11 | 0.442 | 6.788 | 106.1 / 357.9 |
| storage | 6 | 11 | 0.433 | 6.087 | 94.6 / 377.3 |
| storage_sqflite | 8 | 8 | 0.509 | 7.946 | 117.0 / 398.9 |
| storage_testing | 3 | 24 | 0.443 | 5.577 | 93.3 / 390.3 |
| transport | 6 | 1 | 0.438 | 6.139 | 93.6 / 371.2 |
| Flutter | 13 | 25 | 3.591 | 17.091 | 356.9 / 728.5 |
| Soma dos tempos; máximo dos picos | 116 | 166 | 7.423 | 71.229 | 356.9 / 728.5 |

Adicionar todos os scans à rotina medida levaria aproximadamente 78.652 s
nessa passagem. Não substituiria os 7.423 s da análise atual. Na primeira
passagem, os totais foram 16.998/71.897 s e os máximos 623.5/753.4 MiB.
CPU user+system total: 22.911/110.765 s na primeira e 8.274/109.502 s na segunda.
As [32 medições](metrics.json) incluem os códigos de saída: 16 baselines com
zero e 16 scans com 1 por diagnósticos, não por falha de configuração.

Não houve skip por resolução, falha de regra ou parada antecipada nos stderr
inspecionados. Cada alvo ficou abaixo do limite padrão de 500 diagnósticos
não ERROR do scanner; máximo observado: 46. As duas listas de diagnósticos
foram idênticas. Isso comprova o inventário fornecido e a estabilidade observada,
não a execução útil de cada regra nem a descoberta de todos os defeitos.

Duas amostras locais não estimam variância nem desempenho em CI. Downloads e
compilação inicial ficam fora dos tempos; o primeiro aquecimento do analyzer
aparece na primeira passagem. O probe nativo rodou em paralelo durante parte
da medição, podendo disputar recursos. RSS não soma processos vivos nem mede
RAM total do host. Sem estimativa de bateria/energia ou promessa de limite fixo.

## Amostra revisada e utilidade

Os [166 diagnósticos](diagnostics.json) cobrem 19 nomes de regra. A amostra abaixo
inspeciona ao menos uma ocorrência de cada nome e inclui guardas pertinentes.
Ela é dirigida por regra e risco; não permite estimar percentuais de falsos
positivos na população. Um alerta contextual não torna a regra inútil em geral.

| Ocorrência na revisão inicial | Classificação e decisão |
|---|---|
| core/g_counter.dart:204, `avoid_null_assertion` | Falso positivo contextual: applyDelta rejeita dot null antes dos acessos. Não remover validação nem trocar por valor padrão. |
| storage/replica_storage_contract.dart:169/172, `avoid_unsafe_collection_methods` | Falso positivo contextual: construtor exige exatamente uma mudança antes de usar single. |
| sync/sync_engine.dart:133, `require_stream_controller_close` | Falso positivo: `_disposeInternal` aguarda `_observations.close()` na linha 460; ownership está explícito. |
| sync/serial_commit_queue.dart:13, `avoid_catch_all` | Catch necessário para completar Future com erro e stack originais, sem envenenar a fila. Não restringir genericamente tipos de falha. |
| sync/sync_engine.dart:447/452, `avoid_swallowing_exceptions` e `require_catch_logging` | Tratamento intencional durante drain de start/push: erro já foi entregue ao chamador. Logging obrigatório no core duplicaria política do consumidor. |
| core/json_set_value.dart:53, `require_catch_logging` | Falso positivo contextual: contains de elemento inválido retorna false; lookup retorna null. Não introduzir logger no core. |
| core/g_set.dart:78, `avoid_losing_stack_trace` | Sinal útil para revisar diagnóstico, não defeito funcional confirmado: codec converte ArgumentError em FormatException do contrato. Preservar stack pode ser melhoria futura localizada; não trocar a política de erro em massa. |
| storage_sqflite/sqflite_replica_storage.dart:229, `avoid_dynamic_sql` e `require_sqflite_whereargs` | Falsos positivos de segurança: identificador de tabela privado constante, where escolhido entre literais e valores fornecidos em arguments. Não há entrada externa interpolada nesse SQL. |
| mesmo arquivo:293/299/309, `avoid_dynamic_sql` | Interpolação apenas dos nomes constantes do schema. Não são quatro vulnerabilidades comprovadas. |
| storage/replica_storage_contract.dart:180/181, `prefer_utc_for_storage` | Falso positivo: o próprio construtor normaliza createdAt/sentAt com toUtc nas linhas 142/143, inclusive entradas externas; a serialização usa campos já normalizados. Não mudar reader/formato para silenciar lint. |
| storage_sqflite/sqflite_replica_storage.dart:265, `document_analyzer_ignore_rationale` | Alerta de manutenção já atendido pelo comentário imediatamente acima: compatibilidade de linhas históricas confirmed. Não duplicar a justificativa só para satisfazer a heurística. |
| storage_testing/replica_storage_contract.dart:159, `avoid_unsafe_where_methods` | singleWhere intencional verifica cardinalidade do teste; fallback esconderia falha do adaptador. |
| storage_testing/replica_storage_contract.dart:206, `avoid_swallowing_exceptions` | Catch específico e comentado admite lista imutável ou cópia mutável, ambos permitidos pelo contrato. |
| Flutter/demo_page.dart:72, `require_mounted_check_after_await` e `require_mounted_check` | Dois alertas sobre o mesmo setState; guarda `if (!mounted)` com return fica nas linhas 66–70. Falso positivo contextual e duplicação de sinal. |
| Flutter/main_eight.dart:41, `require_error_handling_graceful` | Sugestão útil de UX, não falha de tratamento comprovada: catch fecha recursos e abre tela de erro. Mensagem de domínio e política visual pertencem ao aplicativo. |
| example/field_query_example.dart:23–25, `avoid_assert_in_production` | Assert demonstra contrato; não é a validação de entrada da biblioteca. Não usar a demonstração como prova de segurança em produção. |
| example/measure_crdt_cost.dart:278, `avoid_path_traversal` e `require_file_path_sanitization` | Caminho do benchmark vem de diretório temporário e nome interno fixo, não input de rede. Não há travessia demonstrada; regra seria útil com origem não confiável. |
| example/offline_reconciliation.dart:169, `avoid_parameter_mutation` | Atualizar `app.lastFailure` é efeito pretendido do exemplo; não reatribui referência do parâmetro. Não refatorar fluxo apenas pelo alerta. |

Paths abreviados acima são relativos a `packages/deltasync_<alvo>/lib/src/`,
`example/flutter_mobile/lib/` ou `example/`; coordenadas completas estão no JSON.
Consultados os fontes e os testes existentes de cardinalidade, eventos e dispose
como suporte de leitura. Eles não foram reapresentados como testes executados
nesta tarefa. Nenhum defeito funcional bloqueador foi confirmado nessa amostra;
nenhuma correção de produto ou regressão nova foi necessária. As demais
ocorrências não receberam auditoria exaustiva de correção.

### Controle positivo e sobreposição

A [fixture descartável](probe.dart.txt) contém defeitos deliberados e não foi
adicionada a lib/test nem executada como aplicação. `dart analyze` retorna exit 2:
`equal_keys_in_map` e `use_rethrow_when_possible`. Saropa retorna exit 1 com seis
alertas: `avoid_duplicate_map_keys`, `avoid_losing_stack_trace`, dois
`avoid_catch_all`, `avoid_swallowing_exceptions` e `require_catch_logging`.

Há sobreposição concreta nos pares de chave duplicada e throw/rethrow; não é
necessário adicionar outro gate para obter esses dois sinais. O catch vazio
nomeado `_` recebe sinal adicional útil de swallowing no Saropa, embora o
recommended não o reporte nessa fixture. Exigir logging sempre ainda não é
uma política adequada à biblioteca. O controller local nunca fechado não foi
reportado por nenhum dos dois: controle também evidencia cobertura incompleta.
Não contar quantidade de regras como ganho de qualidade ou segurança.

## Decisão e manutenção

O piloto fundamenta **adiamento**, permitido pelos critérios da R-34. Não há
plugin, baseline genérica, supressão, autofix, downgrade ou dependência nova
na configuração permanente. Consumidores, contribuidores e forks continuam
com o fluxo R-33; nenhuma API, estado, join, delta, commit, restauração ou formato
persistido mudou. O app mantém modelos/UI/autenticação; a biblioteca não passa
a decidir logging ou UX por heurística do lint.

Para reconsiderar a adoção, executar novo piloto com versão exata em runner
isolado; comparar resolução e custo atuais, manter recommended e testar
controles positivos no plugin Dart/Flutter. Explicar qualquer diferença entre
preset YAML, inicializador, lane e CLI. Somente então escolher regras com uso
concreto e exceções pontuais justificadas; não habilitar essential inteiro nem
aceitar downgrade/baseline ampla sem revisão. Isso é condição de reavaliação,
não nova tarefa obrigatória da release nem dependência adicional de R-35.

Lint não comprova convergência dos oito CRDTs, atomicidade, recuperação durável,
ACK remoto, autenticação/TLS nem ausência de vulnerabilidades. Advisories Pub
continuam na consulta online OSV da [política R-33](../../../docs/ci.md), separada
da análise de código. Nenhuma consulta OSV nova, suíte runtime ou build Android
é alegada por este piloto documental. A próxima tarefa continua sendo R-35;
VAL-17 permanece responsável pela validação integral da release.

## Reprodução e artefatos

Os JSONs registram resultados históricos; não substituem executar ferramentas.
`{checkout}`, `{runner}`, `{native}` e `{pubCache}` nos logs/JSONs são placeholders
para os diretórios temporários. Hashes de logs brutos referem-se aos arquivos
originais antes da normalização de caminhos/whitespace; coordenadas/códigos e resultados decisivos
estão preservados em logs.txt. Não publicar caches, bancos, APKs ou relatórios
temporários gerados pelas ferramentas.

1. Criar clones descartáveis da revisão inicial, fora da worktree de trabalho.
   Resolver um clone com `dart pub get`; resolver seu app com
   `flutter pub get --enforce-lockfile`, usando o SDK selecionado e cache próprio.
2. Criar diretório de runner com o manifest exato fornecido e executar
   `dart pub get` nele. Aquecer com `dart run saropa_lints:scan --help`.
3. Em cada alvo, rodar a baseline original duas vezes. No runner, repetir:

   ```sh
   dart run saropa_lints:scan <alvo-absoluto> --tier essential --resolve --format json --files-from-stdin
   ```

   Fornecer por stdin um arquivo por linha, conforme inventory.json. Lista
   explícita evita omitir exemplos por exclusões padrão. Não adicionar filtros
   de severidade nem interpretar exit 1 por alertas como falha de resolução.
4. Para repetir as medidas Linux, o [instrumento executado](measure.py.txt)
   lê `/tmp/deltasync-r34-paths.json` com as chaves pilot, runner e pubCache;
   ajustar os caminhos para clones novos e usar saída temporária vazia. Não
   executar esse instrumento na árvore principal nem sobrescrever esta evidência.
   Ele mede wall/CPU/RSS via wait4 e conserva as duas passagens.
5. Resolver separadamente as fixtures [exata](exact.pubspec.yaml.txt) e
   [flexível](flexible.pubspec.yaml.txt). Para o controle positivo, usar o
   [manifest da fixture](fixture.pubspec.yaml.txt), recommended e probe.dart.
6. No segundo clone, preservar includes e instalar só a configuração de plugin
   descrita acima. Registrar fase padrão, lane full e inicializador oficial
   como experimentos diferentes. Não copiar alterações experimentais ao projeto.

Nenhuma configuração permanente foi adotada; a validação final confere dados,
hashes, decisão, links/status e diff. O [resultado](validation.json) registra
checks do [instrumento de validação](validate.py.txt), ligado aos inputs
temporários desta execução. A lista de hashes exclui o próprio validation.json
para evitar checksum circular. Não há justificativa para repetir testes de CRDT
por mudanças somente documentais.
