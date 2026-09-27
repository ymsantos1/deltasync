# Instruções de contexto — TCC

## Relação com a proposta acadêmica

Este arquivo registra o contexto arquitetural atual; não é a transcrição integral
da [proposta acadêmica em PDF](<referencia/Proposta TCC.pdf>). A revisão de
2026-09-27, o estado da implementação e as entregas estão em
[plan/README.md](plan/README.md). Correções técnicas estão na
[fase 1](plan/01_PHASE1_CORRECOES.md); evidências em
[TRACEABILITY.md](plan/TRACEABILITY.md).

O PDF prevê SQLite/`sqflite` para persistência e três módulos internos. O contexto
atual mantém SQLite como adaptador de referência previsto para o TCC, com contrato
de storage independente de banco, quatro subpacotes e facade Dart. Essa evolução
precisa ser refletida no texto e no diagrama finais do trabalho; não elimina a
entrega de persistência durável em SQLite.

Estou desenvolvendo um TCC cujo objetivo é criar uma **biblioteca em Dart voltada a aplicações offline-first**, utilizando **CRDTs e sincronização incremental baseada em deltas**.

Ao me auxiliar neste projeto, considere os seguintes pontos como contexto principal.

## Objetivo

A biblioteca deve permitir que aplicações realizem alterações localmente, continuem funcionando sem conexão e posteriormente reconciliem essas alterações entre diferentes réplicas.

A proposta busca fornecer uma **base modular e reutilizável para sincronização offline-first**, e não uma plataforma completa de colaboração distribuída ou um backend pronto.

A sincronização deve ser orientada principalmente a **deltas**, evitando o envio recorrente do estado completo sempre que possível.

## Tecnologia

A implementação será feita em **Dart**, com foco principal no uso em aplicações Flutter.

O núcleo da solução deve, sempre que possível, permanecer independente de Flutter e de tecnologias específicas de infraestrutura.

## Estrutura da biblioteca

A arquitetura deve possuir responsabilidades bem separadas, principalmente entre:

* **Core:** implementação dos CRDTs, estados, deltas e lógica necessária para convergência.
* **Sync:** gerenciamento do fluxo de sincronização, alterações pendentes, aplicação de alterações remotas e integração entre réplicas.
* **Storage:** persistência do estado, deltas pendentes e informações necessárias para recuperar e continuar a sincronização.
* **Transport:** integração com o mecanismo utilizado pela aplicação para transmitir dados entre réplicas.

Essas áreas devem possuir baixo acoplamento entre si.

## Persistência

A persistência **não deve estar diretamente acoplada ao SQLite ou ao `sqflite`**.

A biblioteca deve fornecer uma **abstração de armazenamento**, permitindo que diferentes bancos ou mecanismos de persistência sejam integrados através de adaptadores.

`sqflite` será o adaptador persistente de referência previsto pela proposta
acadêmica, mas não deve ser dependência obrigatória do core, sync ou contrato de
storage. Sua entrega e validação são previstas para o TCC; sua utilização é
opcional para aplicações consumidoras que escolham outro adaptador.

`MemoryStorage` serve a testes e protótipos. Restauração usando a mesma instância
em memória não comprova durabilidade entre sessões ou recuperação de processo.

A intenção é permitir que futuramente outros mecanismos de armazenamento possam ser utilizados sem alterar a lógica central da biblioteca.

## Comunicação

A biblioteca não deve definir um protocolo de comunicação específico.

HTTP, WebSocket ou outros mecanismos pertencem à aplicação que utilizar a biblioteca.

Da mesma forma, autenticação, autorização, segurança do transporte e regras de acesso aos dados ficam fora do núcleo da solução.

## Modularidade

Ao sugerir arquitetura ou implementação, priorize:

* baixo acoplamento;
* separação de responsabilidades;
* inversão de dependência;
* facilidade de testes;
* possibilidade de substituir componentes de infraestrutura;
* APIs idiomáticas em Dart;
* simplicidade suficiente para que o projeto continue viável dentro do escopo de um TCC.

Evite overengineering e abstrações criadas apenas para prever cenários muito distantes do objetivo atual.

## Validação

A biblioteca deverá ser validada principalmente por testes automatizados e por uma aplicação de demonstração.

Os testes devem verificar, entre outros aspectos:

* comportamento dos CRDTs;
* geração e aplicação de deltas;
* convergência entre réplicas;
* tolerância a duplicação e reordenação quando aplicável;
* persistência e recuperação;
* funcionamento conjunto das camadas da biblioteca.

A abstração de armazenamento também deve permitir testar a biblioteca sem depender necessariamente de um banco específico.

## Escopo

O conjunto prioritário previsto no PDF é: `LWW-Register`, `MV-Register`,
`G-Counter`, `PN-Counter`, `G-Set`, `2P-Set`, `OR-Set` e `OR-Map`. Reduzir esse
conjunto exige alteração explícita do recorte acadêmico, não apenas do plano.

OR-Map pode compor valores CRDT por API manual. `ObjectCrdt`, anotações, geração
de código com `build_runner` e migração automática de modelos são extensões
futuras, não requisitos da proposta. Política add/update-wins de objetos não é
regra global obrigatória para todos os tipos.

Reconciliação e recuperação de réplica offline precisam funcionar na topologia
documentada. Anti-entropy para topologias arbitrárias e garbage collection
destrutivo de tombstones podem permanecer fora da versão acadêmica.

O projeto não pretende resolver de forma completa:

* autenticação e autorização;
* protocolos de rede;
* backend de sincronização;
* transações distribuídas;
* invariantes globais complexas;
* colaboração em tempo real em escala industrial;
* todos os tipos existentes de CRDT.

Esses pontos podem ser tratados como responsabilidades externas ou possíveis extensões futuras.

## Como me auxiliar

Ao responder perguntas sobre o TCC:

* considere essa arquitetura como referência;
* não trate decisões de implementação ainda abertas como requisitos definitivos;
* diferencie decisões arquiteturais de exemplos de implementação;
* não assuma `sqflite` como armazenamento obrigatório;
* priorize soluções que mantenham storage e transporte desacoplados do núcleo;
* avise quando uma sugestão aumentar significativamente o escopo do projeto;
* caso uma decisão proposta comprometa propriedades importantes dos CRDTs ou da sincronização, explique o problema;
* priorize uma solução tecnicamente correta, mas também implementável e justificável academicamente.

O objetivo final é desenvolver uma **biblioteca Dart modular para sincronização offline-first com CRDTs e deltas**, mantendo detalhes de infraestrutura, como banco de dados e transporte, substituíveis e desacoplados do núcleo.
