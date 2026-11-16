# Spec Delta

## Purpose

Lets solving tools be added or swapped as modules, so that new tools can answer new kinds of questions without changing the engine or the existing tools.

## ADDED Requirements

### Requirement: Backends declare supported query kinds
Every backend SHALL declare the query kinds it supports (for example satisfiability check, optimisation, consequence evaluation, enumeration of possible or forced options).

#### Scenario: Declaration is inspectable
- **WHEN** the engine is asked which query kinds the loaded backends support
- **THEN** it lists each backend with its declared query kinds

### Requirement: Query routing
For each query, the engine SHALL use a loaded backend that declares the query kind, choosing by the host's configured order of preference.

#### Scenario: Preferred backend used
- **WHEN** two loaded backends both support optimisation and the host prefers backend B
- **THEN** optimisation queries are answered by backend B

#### Scenario: Fallback to a capable backend
- **WHEN** the preferred backend does not support a query kind and another loaded backend does
- **THEN** that query is answered by the other backend

### Requirement: Unsupported queries rejected
When no loaded backend supports a query kind, the engine SHALL reject the query with an error naming the query kind, instead of returning a partial or approximate answer.

#### Scenario: Missing capability
- **WHEN** only a backend without optimisation is loaded and a cheapest-completion query is made
- **THEN** the engine rejects the query with an error naming the optimisation query kind

### Requirement: Backends are interchangeable
For every query kind two backends both support, they SHALL return equivalent answers on the same model and input. Explanations are equivalent when both are minimal and unsatisfiable; optimisation results are equivalent when their objective values are equal.

#### Scenario: Same feasibility from every backend
- **WHEN** the conformance suite runs on the reference model with each loaded backend
- **THEN** every backend that supports the query kinds produces the same feasibility, consequence and range results as the brute-force backend

### Requirement: Backends added without changing the engine
Adding a backend SHALL require only providing the backend module and including it in the host's composition; the engine and other backends SHALL NOT change.

#### Scenario: Test-only backend
- **WHEN** a test composes the engine with an extra backend that supports one query kind
- **THEN** queries of that kind can be routed to it, and no engine source file differs from the production build
