# Spec Delta

## Purpose

Tells the user what to change to get what they want: the smallest sets of current choices and assumption values to change so that a wanted option becomes feasible or a conflicting configuration becomes consistent.

## ADDED Requirements

### Requirement: Repairs for a wanted option
For an infeasible option the user wants, the solver SHALL return repairs: sets of current choices and known assumption values which, if all changed, make the option feasible. Each repair SHALL be subset-minimal: changing any proper subset of it is not enough.

#### Scenario: Single-choice repair
- **WHEN** the choices are `{Sessions: Token}` and the user wants `InstantRevocation = yes`
- **THEN** one repair is "change Sessions", and with Sessions unchosen `InstantRevocation = yes` is feasible

#### Scenario: Alternative repairs
- **WHEN** the choices are `{Hosting: Serverless.Functions, Realtime: WebSockets}` and A1 is set to no
- **THEN** the repairs for consistency are "change Hosting", "change Realtime" and "A1 turns out yes", each on its own

### Requirement: No repair when choices cannot help
When an option is infeasible under every possible change of choices and assumption values, the solver SHALL report that no repair exists and SHALL return the explanation instead.

#### Scenario: Option ruled out by the model itself
- **WHEN** an option conflicts with hard rules alone, whatever is chosen
- **THEN** the solver reports that no repair exists, with an explanation that contains no choices

### Requirement: Repairs never touch rules
Repairs SHALL consist only of the user's choices and assumption values, never of rules.

#### Scenario: Rule not offered as a repair
- **WHEN** a hard rule takes part in the conflict
- **THEN** no repair proposes ignoring that rule

### Requirement: Assumption values marked
A repair that includes an assumption value SHALL mark it as an assumption, so it can be shown as "if this turns out differently" rather than as a choice.

#### Scenario: Repair through an assumption
- **WHEN** `A1 = no` is part of a repair
- **THEN** the repair lists A1 as an assumption, separately from choices

### Requirement: Fewest changes first
The solver SHALL return up to the requested number of repairs (default 3) in order of increasing number of changes, so that no repair returned has more changes than one left out.

#### Scenario: Limit respected
- **WHEN** two repairs are requested for the "Alternative repairs" situation
- **THEN** two single-change repairs are returned
