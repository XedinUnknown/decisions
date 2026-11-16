# Spec Delta

## Purpose

Tells the user what to change to get what they want: the smallest sets of current choices to undo so that a wanted option becomes feasible or a conflicting configuration becomes consistent.

## ADDED Requirements

### Requirement: Repairs for a wanted option
For an infeasible option the user wants, the solver SHALL return repairs: sets of current choices and known assumption values which, if changed, make the option feasible. Each repair SHALL be minimal: undoing any proper subset of it is not enough.

#### Scenario: Single-choice repair
- **WHEN** the choices are `{Sessions: Token}` and the user wants `InstantRevocation = true`
- **THEN** one repair is "change Sessions", and choosing `InstantRevocation = true` after undoing it is feasible

#### Scenario: Alternative repairs
- **WHEN** the choices are `{Hosting: Serverless.Functions, Realtime: WebSockets}`, A1 is false, and the user wants to keep both choices consistent
- **THEN** the repairs include "change Hosting" and "change Realtime", each on its own

### Requirement: Repairs never touch rules
Repairs SHALL consist only of the user's choices and assumption values, never of hard rules.

#### Scenario: Rule not offered as a repair
- **WHEN** a hard rule causes the conflict
- **THEN** no repair proposes ignoring that rule

### Requirement: Assumption values marked
A repair that includes a known assumption value SHALL mark it as an assumption, so it can be shown as "if this turns out differently" rather than as a choice.

#### Scenario: Repair through an assumption
- **WHEN** A1 = false is part of a repair
- **THEN** the repair lists A1 as an assumption, separately from choices

### Requirement: Several repairs, smallest first
The solver SHALL return up to a requested number of repairs, ordered by the number of changes.

#### Scenario: Limit respected
- **WHEN** three repairs are requested and five exist
- **THEN** three are returned, none larger than any repair left out
