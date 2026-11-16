# Spec Delta

## Purpose

Puts numbers on a configuration: what the chosen options cost and are worth, the range still possible, the best configurations, and which options give the most value per cost (ADR-0006).

## ADDED Requirements

### Requirement: Running total
For any set of choices, the solver SHALL report the total cost and total value of the chosen options and hidden choices plus every combination term whose condition holds.

#### Scenario: Combination term counted
- **WHEN** the choices are `{Hosting: Serverless.Functions, Database: ManagedSQL}` in the reference model
- **THEN** the total cost includes 2 for Functions, 3 for ManagedSQL and 3 for the combination term

### Requirement: Range over feasible configurations
The solver SHALL report the minimum and maximum total cost and total value over all feasible completions of the current choices, under hard rules only.

#### Scenario: Range never widens
- **WHEN** a choice is added to a consistent configuration
- **THEN** the minimum total cost does not decrease and the maximum does not increase

#### Scenario: Agreement with exhaustive enumeration
- **WHEN** a range is computed for any reachable set of choices on either bundled model
- **THEN** it equals the range found by enumerating every feasible completion

### Requirement: Cheapest and most valuable configurations
The solver SHALL return a feasible completion with the lowest total cost, breaking ties by higher value; and, given a cost budget, a feasible completion with the highest total value within it, breaking ties by lower cost, or report that none fits.

#### Scenario: Cheapest reference configuration
- **WHEN** the cheapest completion of the reference model is requested with no choices and all assumptions unknown
- **THEN** it costs 12 points and includes `Hosting = Serverless.Functions` and `Realtime = WebSockets`

#### Scenario: Budget too small
- **WHEN** the budget is below the minimum total cost
- **THEN** the solver reports that no completion fits the budget

### Requirement: Assumptions behind optimistic answers
Range, cheapest, most valuable and Pareto answers SHALL let unknown assumptions take any value, and SHALL list the assumption values each returned configuration relies on.

#### Scenario: Cheapest configuration relies on an open question
- **WHEN** the cheapest completion of the reference model is requested with A1 unknown
- **THEN** the answer lists A1 = yes as relied on

### Requirement: Robust variant
The solver SHALL also answer cheapest, most valuable and Pareto queries robustly: considering only completions that are feasible for every value of every unknown assumption, numeric ones across their bounds.

#### Scenario: Robust cheapest avoids the open question
- **WHEN** the robust cheapest completion of the reference model is requested with all assumptions unknown
- **THEN** it does not combine `Hosting.Serverless` with `Realtime.WebSockets`, and it costs 13 points

### Requirement: Pareto front
The solver SHALL return one feasible completion for each point (total cost, total value) on the Pareto front: the points for which no feasible completion has lower or equal cost and higher or equal value with at least one strictly better.

#### Scenario: Dominated point excluded
- **WHEN** one completion costs 8 with value 13 and another costs 8 with value 21
- **THEN** only the point (8, 21) is on the front

### Requirement: Value per cost for options
For every feasible unchosen option, the solver SHALL report its value per cost, its cost delta and value delta (the change in the cheapest completion's totals if it were chosen), and the consequences that choosing it would make true. Options with cost 0 SHALL be reported without a ratio.

#### Scenario: High ratio with a costly consequence
- **WHEN** no choices are made in the reference model
- **THEN** `Logging.FullBodies` is reported with value per cost 5.0, together with K1 and K3

#### Scenario: Zero cost
- **WHEN** an option has cost 0
- **THEN** no ratio is reported for it, and its value is still reported
