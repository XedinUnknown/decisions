# Spec Delta

## Purpose

Lets doubtful rules be wrong. Rules below a confidence threshold do not remove options on their own; the solver says which doubtful rules stand in the way, blaming the least trusted rules first (ADR-0004).

## ADDED Requirements

### Requirement: Hard and soft rules by threshold
A rule whose confidence level is at or above the configured threshold SHALL be hard. A rule below it SHALL be soft. The default threshold SHALL be `verified`.

#### Scenario: Default threshold
- **WHEN** no threshold is configured and a rule is `likely`
- **THEN** that rule is treated as soft

#### Scenario: Unrated rule
- **WHEN** a rule is `unrated`
- **THEN** it is soft at every threshold except one set explicitly to `unrated`

### Requirement: Feasibility ignores soft rules
Option feasibility and consistency SHALL be determined by hard rules only.

#### Scenario: Option blocked only by a soft rule
- **WHEN** an option conflicts with the current choices only through a rule below the threshold
- **THEN** the option is reported feasible

### Requirement: Doubtful rules in the way, level first
For a feasible option that violates soft rules, the solver SHALL report which soft rules would have to be wrong for the option to hold, choosing among alternatives by comparing levels first: the alternative whose highest blamed level is lower wins; at the same level, fewer blamed rules wins; then the next level down decides.

#### Scenario: Three plausible rules rather than one likely rule
- **WHEN** an option can hold either if one `likely` rule is wrong or if three `plausible` rules are wrong
- **THEN** the solver reports the three `plausible` rules

#### Scenario: Fewer rules at the same level
- **WHEN** an option can hold either if one `guess` rule is wrong or if two `guess` rules are wrong
- **THEN** the solver reports the single `guess` rule

#### Scenario: No soft rule in the way
- **WHEN** an option satisfies all soft rules under the current choices
- **THEN** no doubtful rules are reported for it

### Requirement: Threshold changes re-classify rules
Changing the threshold SHALL re-classify every rule and change feasibility accordingly, without changing the model.

#### Scenario: Lowering the threshold
- **WHEN** the threshold is lowered from `verified` to `likely`
- **THEN** options that a `likely` rule alone kept feasible-with-doubt are reported infeasible, explained by that rule
