# Guia de Arquitetura e Boas Práticas: Recursos Avançados do Dart

Este guia é uma referência de escolha dos recursos do Dart, subordinada às
[instruções do projeto](AGENTS.md#uso-adequado-dos-recursos-do-dart) e aos critérios
da tarefa. Seu objetivo é reduzir complexidade com segurança de tipos e clareza.
Não exige usar todos os recursos nem autoriza refatorar trechos fora da tarefa.

Class modifiers, records e patterns exigem Dart 3.0+; extension types exigem
Dart 3.3+. DeltaSync declara SDK `^3.13.0`: conferir a versão mínima do pacote
afetado antes de usar outros recursos. Exemplos são ilustrativos; fragmentos
dependem do contexto indicado, e antipadrões podem conter erros intencionais.

## Diretriz Primária

Regra de Ouro: Toda estrutura de linguagem deve resolver um problema concreto de segurança de tipo, desempenho ou manutenibilidade. Não utilize recursos modernos apenas para tornar o código sintaticamente exótico. Se uma solução simples com if/else ou uma classe comum resolve o problema com clareza, prefira a simplicidade.

## 1. Class Modifiers (sealed, final, base, interface)

### Quando Usar

- `sealed`: para variantes fechadas com switches exaustivos, quando os subtipos
  diretos ficam na mesma library Dart. Uma library pode incluir arquivos `part`;
  pertencer ao mesmo pacote não basta. `sealed` é implicitamente abstrata.
- `final`: impede herança e implementação fora da library da classe.
- `base`: permite herança externa, impede implementação externa; subtipos devem
  ser `base`, `final` ou `sealed`.
- `interface`: permite implementação externa, impede herança externa.
  `abstract interface class` define contrato sem instâncias diretas, adequado
  aos adaptadores de storage e transport do DeltaSync.
- Esses modificadores controlam subtipagem, não imutabilidade dos objetos.
  Avaliar compatibilidade e pontos de extensão de consumidores/forks.

### Quando NÃO Usar (Anti-padrões)

- Evite `sealed` quando consumidores precisarem criar subtipos diretos em outras
  libraries. Não reorganizar arquivos apenas para usá-la sem ganho de clareza.
- Evite adicionar restrições mecanicamente a classes internas. `final` e `base`
  também limitam implementações usadas como mocks fora da library; escolher
  conforme o contrato e as formas de teste necessárias.

```dart
// CORRETO: Modelagem de estado de UI onde a exaustividade do switch é desejada
sealed class ProductState {}

class ProductLoading extends ProductState {}

class ProductSuccess extends ProductState {
  final List<String> items;
  ProductSuccess(this.items);
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

// INCORRETO: Abuso cosmético em DTO simples sem hierarquia
sealed class UserDto {
  // Sem subclasses e implicitamente abstrata; não pode ser instanciada.
  final String name;
  UserDto(this.name);
}
```

## 2. Pattern Matching e Switch Expressions

### Quando Usar

- Usar switches exaustivos sobre variantes fechadas, como enums ou hierarquias
  sealed, e desestruturar records quando facilitar a leitura.
- Parsing e validação de estruturas de dados dinâmicas (ex.: `Map<String, dynamic>` provenientes de JSONs ou bibliotecas de terceiros).
- Simplificação de retornos condicionais diretos usando `switch` expressions e field punning (`:var campo`).

### Quando NÃO Usar (Anti-padrões)

- Substituir um `if` booleano simples por um `if-case` apenas para usar a sintaxe nova.
- Encadear múltiplos `when` extremamente complexos em um `switch` que poderiam ser extraídos para métodos bem documentados.

```dart
// CORRETO: Desestruturação limpa de JSON e validação em um único ponto
if (json case {'status': 200, 'data': {'user': String name}}) {
  print('Usuário autenticado: $name');
}

// INCORRETO: Uso de Pattern Matching onde um 'if' simples é mais legível
// Ruim:
if (isLoggedIn case true) { ... }

// Bom:
if (isLoggedIn) { ... }
```

## 3. Extension Types (extension type)

### Quando Usar

- Diferenciar IDs em assinaturas, sem objeto wrapper adicional em runtime
  (ex.: `UserId(int)` vs `OrderId(int)`). Reusar tipos existentes quando adequados;
  alocação adicional, por si só, não torna uma classe wrapper inadequada.
- Visões tipadas sobre JSON quando reduzirem conversões repetidas. Getters tipados
  não validam automaticamente o mapa nem protegem dados aninhados contra mutação.
- JS Interop: mapeamento de objetos nativos JavaScript no desenvolvimento Web.

### Quando NÃO Usar (Anti-padrões)

- Não substituir classes que precisem de identidade nominal, igualdade própria,
  encapsulamento ou despacho polimórfico em runtime. Extension types são visões
  estáticas; `runtimeType`, testes `is`, casts e patterns usam a representação.
- Construtores podem validar dados. Casts e patterns não executam esses
  construtores: validar entradas explicitamente ao criar/restaurar valores.
  Não tratar o tipo como garantia de que qualquer dado externo já foi validado.
- No DeltaSync, avaliar o `ReplicaId` existente e sua igualdade/validação antes
  de propor troca; não substituir todas as classes de identidade automaticamente.

```dart
// CORRETO: Wrapper estático sem overhead para prevenir bugs de ID
extension type UserId(int id) {}
extension type OrderId(int id) {}

void processOrder(UserId user, OrderId order) {} // Impede inversão de argumentos

// INCORRETO: Tentar reatribuir o getter da representação primitiva
extension type BankAccount(double balance) {
  void withdraw(double amount) {
    balance -= amount; // Erro: representação exposta por getter, sem setter.
  }
}
```

## 4. Extension Methods (extension)

### Quando Usar

- Adicionar utilitários a classes de terceiros ou bibliotecas nativas do Dart (ex.: `String`, `DateTime`, `BuildContext` do Flutter).
- Facilitar chamadas encadeadas (fluent APIs) em dados utilitários.
- Conversões e conveniências nos modelos do consumidor, mantendo regras de
  negócio no próprio aplicativo. Extensions são resolvidas pelo tipo estático;
  não fazem override de membros existentes nem despacho por `dynamic`.

### Quando NÃO Usar (Anti-padrões)

- Vazar regras de negócio centrais do sistema dentro de extensões em tipos genéricos (ex.: colocar a regra de cálculo de impostos como `extension Taxa on double`).
- Criar extensões para membros que deveriam ser métodos de uma classe sob seu controle direto.
- Ocultar em extensions metadados essenciais, joins ou invariantes que pertencem
  ao contrato da biblioteca. Conveniências opcionais podem permanecer extensions
  mesmo em tipos próprios quando isso mantiver o contrato central simples.

```dart
// CORRETO: Método utilitário de formatação em tipo do SDK
extension DateFormatting on DateTime {
  String toIsoDateOnly() => toIso8601String().split('T').first;
}

// INCORRETO: Regra de negócio crítica acoplada a primitivo
extension BusinessRules on double {
  bool get canApplyForLoan => this > 50000; // Oculta o contexto do cliente
}
```

## 5. Records (Tuplas)

### Quando Usar

- Retorno privado ou local de múltiplos valores em uma função, eliminando a necessidade de parâmetros `out` ou classes descartáveis de uso único.
- Agrupamento temporário de dados dentro do escopo de um arquivo.
- Retornos públicos pequenos, com campos nomeados e significado documentado,
  quando não houver necessidade de identidade nominal, validação ou comportamento.

### Quando NÃO Usar (Anti-padrões)

- Não substituir modelos que precisem de identidade de domínio, invariantes ou
  métodos próprios. Records têm tipagem estrutural; um `typedef` nomeia a forma,
  mas não cria um tipo nominal distinto.
- Records posicionais grandes: evite campos cujo significado dependa de lembrar
  posições. Prefira records nomeados (`({int id, String name})`) ou uma classe,
  conforme o domínio e a evolução do contrato.

```dart
// CORRETO: Retorno duplo simples em função privada/interna
(double min, double max) _calculateBounds(double a, double b) =>
    a <= b ? (a, b) : (b, a);

// TAMBÉM VÁLIDO: Retorno público pequeno com significado documentado.
/// Limites ordenados de dois valores finitos.
({double min, double max}) calculateBounds(double a, double b) =>
    a <= b ? (min: a, max: b) : (min: b, max: a);
```

## 6. Enhanced Enums

### Quando Usar

- Representar um conjunto estático e fixo de constantes que possuem metadados associados (ex.: descrições, códigos numéricos, ícones).
- Para formatos persistidos/enviados, declarar rótulo explícito e estável;
  rejeitar valores desconhecidos no parsing. Não persistir `.index` nem atrelar
  formato a renomeações de `.name`. Preservar formatos/IDs ou versionar mudanças.

### Quando NÃO Usar (Anti-padrões)

- Tentar usar enums para dados que vêm de um banco de dados ou API e podem mudar sem nova compilação do código.
- Enums com métodos que executam efeitos colaterais complexos (chamadas I/O, requisições de rede).

```dart
// CORRETO: Enum com metadados e comportamento puro
enum Priority {
  low('Baixa', 1),
  high('Alta', 2);

  final String label;
  final int value;

  const Priority(this.label, this.value);

  bool get isUrgent => value > 1;
}
```

## 7. Exemplos de aplicação no DeltaSync

Estes exemplos mostram escolhas possíveis para R-09a/R-09b, não APIs já
implementadas. Nomes e contratos finais dependem da tarefa e da compatibilidade.

### Tipos fechados e metadados comuns — R-09a

Exemplo com os três CRDTs atuais; os oito previstos permanecem no escopo.
Um único catálogo tipado evita repetir strings em roteamento, codecs e storage.

```dart
enum CrdtKind {
  lww('lww'),
  gCounter('g-counter'),
  pnCounter('pn-counter');

  const CrdtKind(this.wireName);
  final String wireName;

  static CrdtKind fromWire(String value) {
    for (final kind in values) {
      if (kind.wireName == value) return kind;
    }
    throw FormatException('Unknown CRDT kind: $value');
  }
}

// Contrato ilustrativo; hoje DeltaChange expõe apenas id e toJson().
abstract interface class DeltaChange {
  String get id;
  String get crdtId;
  CrdtKind get kind;
  String get replicaId;
  Map<String, Object?> toJson();
}
```

No desenho ilustrado, origem, endereço e tipo são membros do contrato comum;
storage deixa de precisar selecionar
`LwwDelta`, `GCounterDelta` ou `PnCounterDelta` apenas para ler origem. Uma
extension que esconda esse switch mantém a duplicação. Identidades tipadas podem
ser adotadas quando úteis, respeitando `ReplicaId` existente e compatibilidade.
Reusar enums existentes, como `OutboxStatus` e `ClockRelation`.

### Nulabilidade coerente — R-09b

Fragmento focado na presença obrigatória do delta; usa `Delta` do core atual e
não define o desenho completo da futura outbox por mudança.

```dart
class OutboxEntry {
  OutboxEntry({required this.delta}) {
    if (delta.isEmpty) {
      throw ArgumentError('non-empty delta is required');
    }
  }

  final Delta delta;
}
```

Hoje o construtor rejeita ausência de delta, mas o campo é `Delta?` e consumidores
usam `!`. Campo obrigatório torna a invariante explícita. Isso não torna payloads
imutáveis nem garante origem única: isolamento, identidade, commit e restauração
continuam critérios de R-09b. Campos cuja ausência é legítima permanecem nullable.

## Matriz de Decisão Rápida para Agentes

Sugestões condicionadas ao uso concreto, não substituições automáticas. Escolher
a alternativa que preserve invariantes com menos conceitos e duplicações.

| Necessidade | Estrutura Recomendada | O que EVITAR |
| --- | --- | --- |
| Representar variantes fechadas | Enum ou `sealed` conforme os dados | Flags que permitem combinações inválidas; fechar contrato que precisa de subtipos externos |
| Retornar poucos valores relacionados | Record, de preferência nomeado quando houver ambiguidade | DTO descartável sem semântica própria; record para entidade com invariantes |
| Distinguir IDs | Reusar tipo existente; extension type ou classe conforme garantias necessárias | Trocar wrappers só por alocação; depender de identidade nominal de extension type em runtime |
| Adicionar conveniência coesa | Extension, função ou membro conforme responsabilidade | Extension global com regra de negócio; classe utilitária sem função concreta |
| Representar constantes fechadas com metadados | Enhanced enum com rótulo estável quando serializado | Strings repetidas; enum para catálogo aberto de dados |
| Exigir dado presente | Campo não nullable e construtor validado | `!` repetido para invariante que o próprio tipo pode expressar |

## Referências oficiais

- [Class modifiers](https://dart.dev/language/class-modifiers).
- [Patterns](https://dart.dev/language/patterns).
- [Extension types](https://dart.dev/language/extension-types).
- [Extension methods](https://dart.dev/language/extension-methods).
- [Records](https://dart.dev/language/records).
- [Enums](https://dart.dev/language/enums).
- [Evolução e versões da linguagem](https://dart.dev/resources/language/evolution).
