# Spec Delta

## Purpose

Defines what a decision model file contains, so that people, AI agents, solver backends and tests all read models the same way.

## ADDED Requirements

### Requirement: File format
A model SHALL be a YAML document whose structure is defined by the project's JSON Schema, and SHALL be loadable from any file path.

#### Scenario: Model outside the repository
- **WHEN** the validator is given the path of a model file stored outside this repository
- **THEN** the model is loaded and validated the same way as the bundled examples

### Requirement: Identifiers
Every decision, option, hidden choice, assumption, consequence and rule SHALL have an identifier made of letters, digits and underscores, starting with a letter. An option is referenced as `Decision.Option`, and a nested option as `Decision.Family.Option`.

#### Scenario: Nested option reference
- **WHEN** a rule refers to `Hosting.Serverless.Functions`
- **THEN** the reference resolves to the `Functions` option in the `Serverless` family of `Hosting`

### Requirement: Reserved instance qualifiers
The form `Name[instance]` (for example `Hosting[orders]`) SHALL be reserved for future per-instance decisions. A model that uses it SHALL fail validation with an error stating that instances are not supported yet, and no other meaning SHALL be given to square brackets in identifiers.

#### Scenario: Instance qualifier used today
- **WHEN** a rule refers to `Hosting[orders].Serverless`
- **THEN** validation fails with an error naming the reference and stating that instance qualifiers are reserved

### Requirement: Decisions and options
A model SHALL declare decisions, each with two or more options; exactly one option of each decision holds in a configuration. An option MAY be a family that contains further options.

#### Scenario: Nested options
- **WHEN** a decision `Hosting` has families `Containers` and `Serverless`, each with two options
- **THEN** the model is valid and the decision has four selectable options

### Requirement: Hidden choices
A model SHALL be able to declare yes/no choices that are not numbered decisions but can be referenced by rules.

#### Scenario: Hidden choice in a rule
- **WHEN** a rule refers to the hidden choice `InstantRevocation`
- **THEN** the model is valid

### Requirement: Assumptions
A model SHALL declare open questions as assumptions, each either yes/no or numeric, with a description and an optional closing action.

#### Scenario: Numeric assumption
- **WHEN** an assumption `A10` is declared numeric with the description "expected monthly requests"
- **THEN** rules may compare `A10` with integers

### Requirement: Rule expressions
Rules SHALL be written in the expression language `is`, `in`, `all`, `any`, `not`, `if`/`then`, and integer comparisons (`<`, `<=`, `=`, `>=`, `>`, `!=`) over numeric assumptions, option attributes and totals.

#### Scenario: Implication between options
- **WHEN** a rule states `if: InstantRevocation` and `then: {is: [Sessions, Server]}`
- **THEN** the model is valid

### Requirement: Rule metadata
Every rule SHALL have an id, a source and a reason, and SHALL have a confidence level of `verified`, `likely`, `plausible`, `guess` or `unrated`. A missing level SHALL mean `unrated`.

#### Scenario: Missing level
- **WHEN** a rule has no confidence level
- **THEN** it is loaded as `unrated`

### Requirement: Background facts
A rule MAY be marked as a background fact; a background fact SHALL carry metadata but SHALL NOT constrain configurations.

#### Scenario: Fact that removes a justification
- **WHEN** a rule is marked as a background fact
- **THEN** the model is valid and the rule has no expression requirement

### Requirement: Consequences
A model SHALL declare consequences as named expressions over choices, assumptions and other consequences. Consequences SHALL NOT form cycles.

#### Scenario: Consequence defined by consequences
- **WHEN** consequence `K3` is defined as `any: [K1, K2]`
- **THEN** the model is valid

### Requirement: Cost and value
Options and combinations of options MAY carry a cost and a value. Both SHALL be non-negative integers in which every point counts the same, so that sums and ratios are meaningful. By default they are relative points; a model MAY instead declare a measured unit (for example hours or money). A model MAY declare `guide: fibonacci`, which makes validation warn about values that are not Fibonacci numbers without rejecting them.

#### Scenario: Combination term
- **WHEN** a combination term gives `{all: [{in: [Hosting, Serverless]}, {is: [Realtime, WebSockets]}]}` an extra cost of 5
- **THEN** the model is valid

#### Scenario: Declared unit
- **WHEN** a model declares its cost unit as `hours`
- **THEN** an option cost of 40 is valid

#### Scenario: Value off the Fibonacci guide
- **WHEN** a model declares `guide: fibonacci` and an option has cost 4
- **THEN** the model is valid, with a warning naming the option and the nearest guide values 3 and 5

#### Scenario: Negative or fractional value
- **WHEN** an option has cost 2.5 or -1
- **THEN** validation fails with an error naming the option

### Requirement: Bundled examples
The project SHALL ship a minimal example model and a reference model, both valid.

#### Scenario: Minimal example size
- **WHEN** the minimal example is loaded
- **THEN** it has at most 3 decisions, at most 3 rules and exactly 1 assumption, and it contains at least one conflict that an explanation can show

#### Scenario: Reference model profile
- **WHEN** the reference model is loaded
- **THEN** it has 10 decisions with one nested decision, at least 10 constraining rules, 14 assumptions each used by at least one rule, a decision depending on at least 4 assumptions, at least 2 assumptions that affect 2 decisions each, a consequence chain of depth 4 where two chains converge, a numeric rule, a background fact that removes a justification, rules at every confidence level, and costs and values on every option
