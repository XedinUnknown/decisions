# Spec Delta

## Purpose

Puts numbers on a configuration: what the chosen options cost and are worth, the range still possible, the best configurations, and which options give the most value per cost (ADR-0006).

## ADDED Requirements

### Requirement: Running total
For any set of choices, the solver SHALL report the total cost and total value of the chosen options plus every combination term whose condition holds.

#### Scenario: Combination term counted
- **WHEN** the choices are `{Hosting: Serverless.Functions, Realtime: WebSockets}` and the model has a combination term for that pair with cost 5
- **THEN** the total cost includes the two options' costs plus 5

### Requirement: Range over feasible configurations
The solver SHALL report the minimum and maximum total cost and total value over all feasible completions of the current choices.

#### Scenario: Range narrows as choices are made
- **WHEN** a choice is added that removes the most expensive feasible completion
- **THEN** the reported maximum total cost decreases accordingly

#### Scenario: Agreement with exhaustive enumeration
- **WHEN** a range is computed for any reachable set of choices on the reference model
- **THEN** it equals the range found by enumerating every feasible completion

### Requirement: Cheapest and most valuable configurations
The solver SHALL return a feasible completion with the lowest total cost, and, given a cost budget, a feasible completion with the highest total value within it, or report that none fits.

#### Scenario: Cheapest respects rules
- **WHEN** the cheapest options would violate a hard rule together
- **THEN** the returned completion satisfies all hard rules and no feasible completion costs less

#### Scenario: Budget too small
- **WHEN** the budget is below the minimum total cost
- **THEN** the solver reports that no completion fits the budget

### Requirement: Pareto front
The solver SHALL return the feasible completions for which no other feasible completion is both cheaper or equal in cost and more or equally valuable with at least one strictly better.

#### Scenario: Dominated configuration excluded
- **WHEN** configuration X costs 8 with value 13 and configuration Y costs 5 with value 13
- **THEN** X is not on the front

### Requirement: Value per cost for options
For every feasible unchosen option, the solver SHALL report its value per cost, its cost delta (the change in the cheapest completion's total if it were chosen), and its value delta likewise. Options with cost 0 SHALL be reported without a ratio.

#### Scenario: Ratio reported
- **WHEN** an option has value 13 and cost 5
- **THEN** its value per cost is reported as 2.6

#### Scenario: Zero cost
- **WHEN** an option has cost 0
- **THEN** no ratio is reported for it, and its value is

### Requirement: Assumptions behind cost answers
Every range, cheapest, most valuable and Pareto answer SHALL list the unknown assumptions whose favourable value it relies on, and the solver SHALL also provide a pessimistic variant in which every unknown yes/no assumption is taken as no.

#### Scenario: Cheapest configuration relies on an open question
- **WHEN** the cheapest configuration uses `Hosting = Serverless.Functions` with `Realtime = WebSockets` and A1 is unknown
- **THEN** the answer lists A1 as relied on, and the pessimistic variant returns a configuration that does not need A1

### Requirement: Consequences next to ratios
Value per cost for an option SHALL be reported together with the consequences that choosing the option would make true.

#### Scenario: Cheap option with a costly consequence
- **WHEN** `Logging = FullBodies` has a high value per cost
- **THEN** its report also lists K1 (personal data at rest) and K3 (privacy review widens)
