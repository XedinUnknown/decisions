# Spec Delta

## Purpose

Defines how providers of keyed definitions and extensions compose, so that any part can be added, replaced or wrapped without changing the others, and the application can be loaded by another system as one provider.

## ADDED Requirements

### Requirement: Providers are configuration
A provider SHALL consist only of definitions and extensions, each under a string key. A definition SHALL produce a key's value from the composed application; an extension SHALL receive the key's previous value and the composed application and return the new value. Composing providers SHALL NOT invoke any definition or extension.

#### Scenario: Composition runs nothing
- **WHEN** providers whose definitions and extensions each count their calls are composed
- **THEN** every count is zero

### Requirement: Later definitions replace earlier ones
When several providers define the same key, the value SHALL come from the definition in the provider that comes last in the composition's order. Earlier definitions for that key SHALL have no effect.

#### Scenario: Override
- **WHEN** provider A defines `greeting` as "hello" and a later provider B defines it as "hi"
- **THEN** `greeting` resolves to "hi" and A's definition is never invoked

### Requirement: Extensions all apply in provider order
All extensions to a key SHALL apply, in the order of their providers, to the value of the winning definition, including extensions contributed by providers that come before the winning definition. A key with extensions and no definition SHALL start from no value.

#### Scenario: Extension contributed before the winning definition
- **WHEN** provider A defines `list` as `[a]`, provider B extends it by appending `b`, and provider C defines `list` as `[c]`
- **THEN** `list` resolves to `[c, b]`

#### Scenario: Extensions in order
- **WHEN** provider A defines `list` as `[]`, and providers B and C, in that order, each extend it by appending their name
- **THEN** `list` resolves to `[B, C]`

#### Scenario: Extension without definition
- **WHEN** only an extension is contributed for `list`, appending `x` to the previous value or to an empty list when there is none
- **THEN** `list` resolves to `[x]`

### Requirement: Composed providers compose again
The result of composing providers SHALL itself be a provider, usable as one entry in a further composition with the same semantics.

#### Scenario: Nested composition
- **WHEN** providers A and B are composed into one provider P, and P is composed after provider C
- **THEN** keys resolve as if A and B had been placed after C directly

### Requirement: Entries scoped from outside
A loading system SHALL be able to place the keys of any entry of its composition, whether one provider or a composition of providers, under a prefix without changing the providers in it. Nothing SHALL be scoped unless the loading system asks. Inside a scoped entry, every key its providers define, extend or require SHALL refer to the prefixed key, with no fallback to the unprefixed key.

#### Scenario: Scoped provider
- **WHEN** provider P defines `a` from `b`, and a system composes P under the prefix `x` with a provider that defines `x/b` as 2
- **THEN** `x/a` resolves from 2, and `a` is not defined

#### Scenario: Scoped group keeps its internal references
- **WHEN** provider A defines `list` as `[a]` and provider B extends `list` by appending `b`, A and B are composed into one provider, and a system composes it under the prefix `x`
- **THEN** `x/list` resolves to `[a, b]`, and an unprefixed `list` is not defined

#### Scenario: No fallback to unprefixed keys
- **WHEN** provider P requires `b`, a system composes P under the prefix `x` next to a provider that defines an unprefixed `b`, and nothing defines `x/b`
- **THEN** resolving `x/a` fails with an error naming `x/b`

#### Scenario: Outside provider targets prefixed keys
- **WHEN** a system composes the group above under `x`, followed by a provider that extends `x/list` by appending `c`
- **THEN** `x/list` resolves to `[a, b, c]`

### Requirement: Lazy, cached resolution
A key SHALL be resolved on first request and its value reused for every later request in the same application. Definitions SHALL see the whole composed application, including keys from value sources.

#### Scenario: Resolved once
- **WHEN** a key whose definition counts its calls is requested twice
- **THEN** the definition ran once and both requests return the same value

#### Scenario: Failure is not cached
- **WHEN** a definition fails on its first request and succeeds on a second
- **THEN** the second request returns the value

### Requirement: Value sources ahead of providers
A composition root SHALL be able to supply ready values for keys through value sources, which take priority over provider definitions for the same key and are visible to every definition.

#### Scenario: Supplied value wins
- **WHEN** a provider defines `cli/args` and the composition root supplies `cli/args` through a value source
- **THEN** `cli/args` resolves to the supplied value, and a definition depending on it receives that value

### Requirement: Missing keys reported
Requesting a key that no provider or value source supplies SHALL fail with an error that names the key.

#### Scenario: Unknown key
- **WHEN** `solver/backends` is requested and nothing supplies it
- **THEN** the error message contains `solver/backends`

### Requirement: Dependency cycles reported
A key whose resolution requires itself, directly or through other keys, SHALL fail on first request with an error that lists the cycle in order.

#### Scenario: Indirect cycle
- **WHEN** `a` depends on `b`, `b` on `c`, and `c` on `a`, and `a` is requested
- **THEN** the error message contains `a → b → c → a`

### Requirement: Declared dependencies
Definitions built with the library's helpers SHALL report the keys they depend on without resolving anything, so that tools can list what a provider requires.

#### Scenario: Dependencies of a definition
- **WHEN** a definition is built from the keys `model/parse` and `model/files`
- **THEN** it reports `[model/parse, model/files]` and nothing is resolved
