# Spec Delta

## Purpose

Explains why an option is infeasible or a configuration is inconsistent, as a minimal set of the rules, choices and assumption values that conflict.

## ADDED Requirements

### Requirement: Explanation of an infeasible option
For every option reported infeasible, the solver SHALL return an explanation: the rule ids, the choices and the known assumption values that together rule the option out.

#### Scenario: Single-rule explanation
- **WHEN** the choices are `{Sessions: Token}` and `InstantRevocation = true` is reported infeasible
- **THEN** its explanation contains rule R1 and the choice `Sessions = Token`

#### Scenario: Explanation through a consequence chain
- **WHEN** the threshold is `likely`, the choices are `{Region: Single}` with A7 false, and `Search = External` is reported infeasible
- **THEN** its explanation contains rules R6 and R7, the choice `Region = Single` and the assumption value `A7 = false`

### Requirement: Explanation of an inconsistent configuration
For an inconsistent configuration, the solver SHALL return an explanation of the same form for the conflict among the current choices and known assumption values.

#### Scenario: Conflict after an assumption closes
- **WHEN** the choices are `{Hosting: Serverless.Functions, Realtime: WebSockets}` and A1 is set to false
- **THEN** the explanation contains rule R2, both choices and `A1 = false`

### Requirement: Minimality
Every explanation SHALL be minimal: removing any one of its rules, choices or assumption values SHALL make the remaining set satisfiable.

#### Scenario: No superfluous elements
- **WHEN** any explanation is produced on the reference model
- **THEN** checking the explanation with each element removed in turn yields a satisfiable set every time

#### Scenario: Explanation is itself unsatisfiable
- **WHEN** any explanation is produced on the reference model
- **THEN** checking the explanation on its own yields unsatisfiable

### Requirement: Rules cited by id with metadata
Each rule in an explanation SHALL be identified by its rule id, and SHALL carry the rule's reason, source and confidence (or unrated) from the model.

#### Scenario: Rule metadata in the explanation
- **WHEN** an explanation contains R1
- **THEN** it includes R1's reason, source and confidence as written in the model

### Requirement: No external service for explanations
Explanations SHALL be computed by the same component that checks satisfiability, without calling any network service.

#### Scenario: Offline explanation
- **WHEN** an explanation is requested with the network unavailable
- **THEN** the explanation is still returned
