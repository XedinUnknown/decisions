# Spec Delta

## Purpose

Lets doubtful rules be wrong. Rules below a confidence threshold do not remove options on their own; the solver says which doubtful rules stand in the way, blaming the least trusted rules first (ADR-0004).

## ADDED Requirements

### Requirement: Hard and soft rules by threshold
A constraining rule whose level is at or above the threshold given in the request SHALL be hard. A rule below it SHALL be soft. The default threshold SHALL be `verified`.

#### Scenario: Default threshold
- **WHEN** no threshold is given and a rule is `likely`
- **THEN** that rule is soft

#### Scenario: Unrated rule
- **WHEN** a rule is `unrated`
- **THEN** it is soft at every threshold except `unrated`

### Requirement: Feasibility ignores soft rules
Option feasibility, forced options, consistency, explanations, repairs and cost answers SHALL be determined by hard rules only.

#### Scenario: Option blocked only by a soft rule
- **WHEN** the choices are `{Sessions: Token, Hosting: Serverless.Functions}` in the reference model
- **THEN** `SessionStore.InMemory` is reported feasible, although R4 (`likely`) would rule it out

### Requirement: Doubtful rules in the way, level first
For a feasible option, the solver SHALL consider the completions that include it, and SHALL report the set of soft rules violated by the best of them, where sets are compared level first: the set whose highest level is lower wins; at the same level, fewer rules wins; then the next level down decides. Unknown assumptions SHALL take whatever values make the set smallest, and the answer SHALL list the assumption values it relies on.

#### Scenario: Blamed soft rule
- **WHEN** the choices are `{Sessions: Token, Hosting: Serverless.Functions}` in the reference model
- **THEN** for `SessionStore.InMemory` the solver reports R4

#### Scenario: Three plausible rules rather than one likely rule
- **WHEN** in a fixture an option can hold either if one `likely` rule is wrong or if three `plausible` rules are wrong
- **THEN** the solver reports the three `plausible` rules

#### Scenario: Fewer rules at the same level
- **WHEN** in a fixture an option can hold either if one `guess` rule is wrong or if two `guess` rules are wrong
- **THEN** the solver reports the single `guess` rule

#### Scenario: No soft rule in the way
- **WHEN** an option is part of a completion that violates no soft rule
- **THEN** no doubtful rules are reported for it

### Requirement: Threshold changes re-classify rules
Changing the threshold SHALL re-classify every rule and change feasibility accordingly, without changing the model.

#### Scenario: Lowering the threshold
- **WHEN** the threshold is lowered from `verified` to `likely` with the choices `{Sessions: Token, Hosting: Serverless.Functions}`
- **THEN** `SessionStore.InMemory` is reported infeasible, explained by R4
