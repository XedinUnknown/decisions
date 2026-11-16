# Spec Delta

## Purpose

Lets low-confidence rules be wrong. Rules below a confidence threshold do not rule options out on their own; the solver reports which of them stand in the way of an option, weighted by confidence.

## ADDED Requirements

### Requirement: Hard and soft rules by threshold
A rule whose confidence is at or above the configured threshold SHALL be hard. A rule below the threshold, or unrated, SHALL be soft.

#### Scenario: Rule at the threshold is hard
- **WHEN** the threshold is 180 and a rule has confidence 180
- **THEN** that rule is treated as hard

#### Scenario: Unrated rule is soft
- **WHEN** a rule has no confidence value
- **THEN** that rule is treated as soft with the lowest weight

### Requirement: Feasibility ignores soft rules
Option feasibility and consistency SHALL be determined by hard rules only.

#### Scenario: Option blocked only by a soft rule
- **WHEN** an option conflicts with the current choices only through a rule below the threshold
- **THEN** the option is reported feasible

### Requirement: Soft-rule conflicts reported
For a feasible option that violates one or more soft rules, the solver SHALL report the soft rules that would have to be wrong for the option to hold, choosing the set with the lowest total confidence.

#### Scenario: Cheapest set of soft rules
- **WHEN** an option can be made to hold either by dropping one soft rule of confidence 100 or two soft rules of confidence 25 each
- **THEN** the solver reports the two rules of confidence 25

#### Scenario: No soft rule in the way
- **WHEN** an option satisfies all soft rules under the current choices
- **THEN** no soft-rule conflict is reported for it

### Requirement: Threshold changes re-classify rules
Changing the threshold SHALL re-classify every rule and SHALL change feasibility accordingly, without changing the model.

#### Scenario: Raising the threshold
- **WHEN** the threshold is raised above a hard rule's confidence
- **THEN** options that rule alone made infeasible are reported feasible, with that rule as a soft-rule conflict
