# Spec Delta

## Purpose

Puts numbers on a configuration: what the chosen options cost and are worth, the range still possible, the cheapest and the most valuable completions, and the return on investment.

## ADDED Requirements

### Requirement: Cost and value attributes
A model SHALL be able to give each option an integer cost and an integer value. An option without a cost or value SHALL count as 0 for that attribute.

#### Scenario: Missing attribute counts as zero
- **WHEN** an option has a cost but no value
- **THEN** totals treat its value as 0

#### Scenario: Non-integer attribute rejected
- **WHEN** a model gives an option a cost of 2.5
- **THEN** the model is rejected with an error naming the option and the attribute

### Requirement: Running total
For any set of choices, the solver SHALL report the total cost and total value of the chosen options.

#### Scenario: Total of chosen options
- **WHEN** the choices are `{Sessions: Server, Hosting: Serverless/Functions}` in the reference model
- **THEN** the total cost equals the sum of those two options' costs

### Requirement: Range over feasible completions
The solver SHALL report the minimum and maximum total cost, and the minimum and maximum total value, over all feasible completions of the current choices.

#### Scenario: Range narrows as choices are made
- **WHEN** a choice is added that removes the most expensive feasible completion
- **THEN** the reported maximum total cost decreases accordingly

#### Scenario: Agreement with exhaustive enumeration
- **WHEN** a range is computed for any reachable set of choices on the reference model
- **THEN** it equals the range found by exhaustively enumerating feasible completions

### Requirement: Cheapest completion
The solver SHALL return a feasible completion of the current choices with the lowest total cost, and its total.

#### Scenario: Cheapest completion respects rules
- **WHEN** the cheapest options would violate a hard rule together
- **THEN** the returned completion satisfies all hard rules and no feasible completion costs less

### Requirement: Most valuable completion within a budget
Given a cost budget, the solver SHALL return a feasible completion with the highest total value whose total cost does not exceed the budget, or report that none exists.

#### Scenario: Budget too small
- **WHEN** the budget is below the minimum total cost
- **THEN** the solver reports that no completion fits the budget

### Requirement: Return on investment
For any complete or partial configuration, the solver SHALL report return on investment as total value divided by total cost, and SHALL report it as undefined when the total cost is 0.

#### Scenario: Ratio reported
- **WHEN** a configuration has total value 30 and total cost 12
- **THEN** its return on investment is reported as 2.5

#### Scenario: Zero cost
- **WHEN** a configuration has total cost 0
- **THEN** its return on investment is reported as undefined

### Requirement: Per-option cost delta
For every feasible unchosen option, the solver SHALL report the change in the cheapest completion's total cost if that option were chosen.

#### Scenario: Delta of a more expensive option
- **WHEN** choosing option X forces a completion that costs 5 more than the current cheapest completion
- **THEN** X's cost delta is reported as +5
