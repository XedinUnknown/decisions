# Spec Delta

## Purpose

Lets solving tools be added or swapped as modules, so that new tools can answer new kinds of questions without changing the engine or the existing tools.

## ADDED Requirements

### Requirement: Backends declare supported query kinds
Every backend SHALL declare which of these query kinds it supports: `check` (satisfiability of a subset of rules with given choices and assumption values), `optimise` (best assignment under ordered objectives), `consequences`, `possible` (options true in some completion) and `forced` (options true in every completion).

#### Scenario: Declaration is inspectable
- **WHEN** the engine is asked which query kinds the loaded backends support
- **THEN** it lists each backend with its declared kinds

### Requirement: User-facing questions map to query kinds
The engine SHALL answer feasibility, conditions, forced options, consequences, explanations and repairs with `check`, `possible`, `forced` and `consequences`, and SHALL answer soft-rule blame, ranges, cheapest and most valuable configurations and the Pareto front with `optimise`.

#### Scenario: Explanation on a check-only backend
- **WHEN** only a backend declaring `check` is loaded and an explanation is requested
- **THEN** the explanation is computed from repeated `check` calls

### Requirement: Routing and fallback
For each query, the engine SHALL use the first backend in the host's order of preference that declares the needed kind. When no loaded backend declares `possible`, `forced` or `consequences`, the engine SHALL compute them from repeated `check` calls.

#### Scenario: Preferred backend used
- **WHEN** two loaded backends both declare `optimise` and the host prefers backend B
- **THEN** `optimise` queries are answered by backend B

#### Scenario: Fallback to repeated checks
- **WHEN** no loaded backend declares `forced`
- **THEN** forced options are still reported, computed from `check`

### Requirement: Unsupported queries rejected
When a question needs `optimise` and no loaded backend declares it, the engine SHALL reject the question with an error naming the `optimise` kind, instead of returning a partial or approximate answer.

#### Scenario: Missing optimisation
- **WHEN** only a backend without `optimise` is loaded and a cheapest-configuration question is asked
- **THEN** the engine rejects it with an error naming `optimise`

### Requirement: Backends are interchangeable
For every question two loaded backends can both answer, they SHALL return equivalent answers on the same model and request: feasibility, conditions, forced options, consequences and ranges equal; explanations and repairs each minimal as specified, with the same set of repairs of the smallest size; blame sets and optimisation results with equal objective values.

#### Scenario: Same answers as the brute-force backend
- **WHEN** the conformance suite runs on both bundled models with each backend
- **THEN** every backend's answers are equivalent to the brute-force backend's for the kinds it declares

### Requirement: Backends added without changing the engine
Adding a backend SHALL require only providing its module and including it in the host's composition.

#### Scenario: Test-only backend
- **WHEN** a test composes the engine with an extra backend that declares one query kind
- **THEN** queries of that kind are routed to it, and the engine's own modules are used unmodified

### Requirement: Backend failures reported
When a backend fails to load (for example its WebAssembly cannot be fetched), cannot compile a model construct, or exceeds a configurable time limit, the engine SHALL report an error naming the backend and the cause, SHALL try the next preferred backend that declares the needed kind, and SHALL NOT return a partial answer.

#### Scenario: WebAssembly not available
- **WHEN** the preferred backend's WebAssembly file cannot be loaded and a second loaded backend declares the same kind
- **THEN** the second backend answers, and the failure of the first is reported

#### Scenario: Time limit exceeded
- **WHEN** a query exceeds the time limit on every capable backend
- **THEN** the engine returns an error naming the query and the backends tried
