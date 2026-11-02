# O que versionar

O repositório mantém código, testes, exemplos de integração, documentação e
evidências selecionadas do TCC. Arquivos gerados durante a execução ficam fora
do Git. O filtro de publicação `.pubignore` já restringe o pacote publicado;
conteúdo do repositório e conteúdo publicado são conjuntos diferentes.

| Conteúdo | Destino |
| --- | --- |
| Fontes, scripts mantidos e testes | Git |
| Fixtures de compatibilidade, serialização e recuperação | Git |
| Exemplos Dart/Flutter usados para demonstrar integração | Git |
| Relatórios, tabelas, manifestos e hashes dos experimentos | Git |
| Caches Python/Dart, builds, APKs e logs gerados | Arquivos locais ignorados |
| Dumps dos aparelhos, corpos HTTP, bancos e execuções intermediárias | Cofre local ignorado |
| Prompt pessoal de execução | Arquivo local ignorado |

Os CSVs pequenos de CP-12 e CP-18 permanecem versionados: permitem conferir
os cálculos e relacionar resultados com execuções. As fixtures e os inventários
de API históricos também permanecem. Removê-los apenas por serem JSON ou
amostras prejudicaria a manutenção e a rastreabilidade.

## Limpeza de 2026-11-02

Dois arquivos `.pyc` de CP-12 e `prompt.txt` foram retirados somente do índice
Git. Suas cópias locais permanecem. `.gitignore` impede sua inclusão futura.
Essa mudança não reescreve commits antigos nem altera resultados experimentais.

No repositório consumidor Compass, `app/evidence/` ainda não estava versionado.
O filtro agora mantém seus registros Markdown e os manifestos CP-14/CP-15,
deixando os demais intermediários locais. Fontes, testes, fixtures e ferramentas
mantidas em `app/tool/` continuam elegíveis para versionamento.

Antes do filtro, foram copiados e conferidos por SHA-256 os 1.325 arquivos
da pasta Compass, totalizando 21.724.846 bytes. Arquivo de preservação local:

```text
/projetos/tcc/deltasync/.performance-artifacts/cleanup-2026-11-02/compass-evidence.tar.gz
```

SHA-256: `e83c0d7ae7de5579e8f83196039e53295ca1b67d5346046763cf373efced0295`.
O `manifest.json` ao lado contém tamanho e hash de cada arquivo. O arquivo
compactado contém 3.038.245 bytes. Nenhum original foi apagado.

Os cofres CP-11/CP-16/CP-17/CP-18 anteriores permanecem inalterados. Um clone
Git não contém esses brutos: a reprodução integral exige obter o cofre indicado
no relatório correspondente. Cofre local não é backup remoto; preserve uma
cópia independente antes de limpar o disco. Não use `git clean -fdx` para
essa organização, pois ele remove também os arquivos ignorados.
