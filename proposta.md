# Instruções de contexto — TCC

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

`sqflite` pode ser utilizado como uma implementação inicial, de referência ou na aplicação de demonstração, mas não deve ser uma dependência obrigatória da arquitetura.

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

