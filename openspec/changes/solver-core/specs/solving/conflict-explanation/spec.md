# Spec Delta

## Purpose

Explains why an option is infeasible or a configuration is inconsistent, as a minimal set of the rules, choices and assumption values that conflict.

## ADDED Requirements

### Requirement: Explanation of an infeasible option
For every option reported infeasible, the solver SHALL return an explanation: the tested option itself, plus the rules, choices and known assumption values that together rule it out.

#### Scenario: Single-rule explanation
- **WHEN** the choices are `{Sessions: Token}` and `InstantRevocation = yes` is reported infeasible
- **THEN** its explanation is R1, the choice `Sessions = Token`, and the tested `InstantRevocation = yes`

#### Scenario: Explanation through a consequence
- **WHEN** the threshold is `likely`, the choices are `{Region: Single}`, A7 is set to no, and `Search.External` is reported infeasible
- **THEN** its explanation is R7, the choice `Region = Single`, `A7 = no` and the tested `Search.External`, with the definition of K2 shown as the link between `Search.External` and R7

### Requirement: Explanation of an inconsistent configuration
For an inconsistent configuration, the solver SHALL return an explanation of the same form for the conflict among the current choices and known assumption values.

#### Scenario: Conflict after an assumption closes
- **WHEN** the choices are `{Hosting: Serverless.Functions, Realtime: WebSockets}` and A1 is set to no
- **THEN** the explanation is R2, both choices and `A1 = no`

### Requirement: Minimality
Every explanation SHALL be minimal over its removable elements, which are rules, choices and assumption values: the explanation is unsatisfiable together with the model's option structure and consequence definitions, and removing any one removable element makes it satisfiable. The tested option is always part of the explanation and is not removable.

#### Scenario: No superfluous elements
- **WHEN** any explanation is produced on either bundled model
- **THEN** removing each removable element in turn yields a satisfiable set every time

#### Scenario: Explanation is itself unsatisfiable
- **WHEN** any explanation is produced on either bundled model
- **THEN** checking the explanation together with the option structure and consequence definitions yields unsatisfiable

### Requirement: Rules cited by id with metadata
Each rule in an explanation SHALL be identified by its rule id, and SHALL carry the rule's reason, source and level from the model.

#### Scenario: Rule metadata in the explanation
- **WHEN** an explanation contains R1
- **THEN** it includes R1's reason, source and level as written in the model

### Requirement: No network service for explanations
Explanations SHALL be computed without calling any network service.

#### Scenario: Offline explanation
- **WHEN** an explanation is requested with the network unavailable
- **THEN** the explanation is still returned
