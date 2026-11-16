# Spec Delta

## Purpose

Catches mistakes in a model file, whether written by a person or drafted by an AI, before any solver runs, and says exactly where each mistake is.

## ADDED Requirements

### Requirement: All errors reported
Validation SHALL report every error it finds in one run, not only the first.

#### Scenario: Two independent errors
- **WHEN** a model has an unknown option reference in rule R3 and a duplicate decision id
- **THEN** both errors are reported

### Requirement: Errors name what they concern
Each error SHALL name the id of the element it concerns and its location in the file (line and column where available).

#### Scenario: Unknown reference
- **WHEN** rule R3 refers to option `Sessions.Cookie`, which the model does not declare
- **THEN** the error names R3, the unknown reference `Sessions.Cookie` and the line of R3

### Requirement: Structural checks
Validation SHALL reject a model that does not match the JSON Schema.

#### Scenario: Decision with one option
- **WHEN** a decision declares a single option
- **THEN** validation fails with an error naming the decision

### Requirement: Semantic checks
Validation SHALL reject unknown references, duplicate ids, cycles between consequences, values off the declared scale, and comparisons between non-numeric terms.

#### Scenario: Consequence cycle
- **WHEN** K1 is defined using K2 and K2 using K1
- **THEN** validation fails with an error naming K1 and K2

#### Scenario: Off-scale value
- **WHEN** an option has cost 4 and the model uses the default relative scale
- **THEN** validation fails with an error naming the option and the allowed values

### Requirement: Warnings for suspicious models
Validation SHALL warn, without failing, about assumptions no rule uses and rules that are unrated.

#### Scenario: Unused assumption
- **WHEN** assumption A6 is declared but no rule refers to it
- **THEN** validation passes with a warning naming A6

### Requirement: Command-line validator
A command SHALL validate a model file, print errors and warnings, and exit with a non-zero status when there are errors.

#### Scenario: Valid model
- **WHEN** the command is run on the minimal example
- **THEN** it prints no errors and exits with status 0

#### Scenario: Invalid model
- **WHEN** the command is run on a model with errors
- **THEN** it prints each error and exits with a non-zero status
