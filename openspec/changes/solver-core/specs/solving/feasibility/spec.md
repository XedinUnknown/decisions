# Spec Delta

## Purpose

Tells the caller, for a model and the current choices, which options remain feasible and which open questions that feasibility depends on.

## ADDED Requirements

### Requirement: Solve request
The solver SHALL accept a model, a set of choices (decision id to option id, or hidden choice id to true/false) and a set of assumption values (assumption id to true, false or unknown), and SHALL answer in terms of the model's own ids only.

#### Scenario: Ids in, ids out
- **WHEN** the solver is asked about the reference model with choices `{Sessions: Token}`
- **THEN** every option, rule, assumption and consequence in the answer is identified by its id in the reference model

#### Scenario: Unknown id
- **WHEN** a choice refers to a decision or option id the model does not define
- **THEN** the solver rejects the request with an error naming the unknown id, and returns no feasibility result

### Requirement: Option feasibility
For every option the caller has not chosen, the solver SHALL report whether the current choices plus that option can satisfy all hard rules.

#### Scenario: Option ruled out by a rule
- **WHEN** the choices are `{Sessions: Token}` and all assumptions are known
- **THEN** the hidden choice `InstantRevocation = true` is reported infeasible

#### Scenario: Option still open
- **WHEN** the choices are `{Sessions: Server}`
- **THEN** `InstantRevocation = true` is reported feasible

#### Scenario: Agreement with exhaustive enumeration
- **WHEN** feasibility is computed for any reachable set of choices on the reference model
- **THEN** each option's result equals the result of exhaustively enumerating all assignments of the model

### Requirement: Nested options
The solver SHALL treat an option family (for example "serverless" with "functions" and "edge") as feasible when at least one of its members is feasible, and SHALL report each member separately.

#### Scenario: Family feasible through one member
- **WHEN** the choices make edge functions infeasible but leave plain functions feasible
- **THEN** the family is reported feasible, edge functions infeasible and plain functions feasible

### Requirement: Assumption-dependent feasibility
For an assumption whose value is unknown, the solver SHALL check each value separately and SHALL report an option as feasible regardless, feasible only if the assumption is true, feasible only if it is false, or infeasible regardless.

#### Scenario: Feasible only under one value
- **WHEN** the choices are `{Realtime: WebSockets}` and A1 is unknown
- **THEN** `Hosting = serverless` is reported feasible only if A1 is true

#### Scenario: Assumption closed
- **WHEN** the same choices are given with A1 set to false
- **THEN** `Hosting = serverless` is reported infeasible

#### Scenario: Unrelated assumption not reported
- **WHEN** an option's feasibility does not change with an unknown assumption
- **THEN** that assumption is not listed as a dependency of the option

### Requirement: Limit on assumption combinations
The solver SHALL toggle only the unknown assumptions that can affect an option, not all combinations of every unknown assumption.

#### Scenario: Irrelevant assumptions are not combined
- **WHEN** all 14 assumptions of the reference model are unknown
- **THEN** checking one option toggles only the assumptions that occur in rules reachable from that option

### Requirement: Inconsistent configuration
When the current choices and known assumption values already violate a hard rule, the solver SHALL report the configuration as inconsistent instead of a feasibility list.

#### Scenario: Assumption closes against a choice
- **WHEN** the choices are `{Hosting: Serverless/Functions, Realtime: WebSockets}` and A1 is set to false
- **THEN** the configuration is reported inconsistent

### Requirement: Numeric rules
The solver SHALL evaluate rules that compare numeric expressions over numeric assumption values and option attributes.

#### Scenario: Cost exceeds budget
- **WHEN** `Hosting = serverless` is chosen and the expected traffic (A10) times the unit price exceeds the budget
- **THEN** the configuration is reported inconsistent

#### Scenario: Cost within budget
- **WHEN** the same choice is made with a traffic value that keeps the cost within the budget
- **THEN** the configuration is consistent

#### Scenario: Numeric assumption unknown
- **WHEN** `Hosting = serverless` is unchosen and A10 has no value
- **THEN** the cost rule does not rule the option out, and A10 is listed as an assumption the option's feasibility depends on

### Requirement: Response time
On the reference model, a full propagation (every unchosen option, with every relevant unknown assumption toggled) SHALL complete within 2 seconds in a current desktop browser.

#### Scenario: Propagation on the reference model
- **WHEN** a full propagation runs in a browser with no choices made and all assumptions unknown
- **THEN** it finishes within 2 seconds
