# Spec Delta

## Purpose

Defines what a decision model file contains, so that people, AI agents, solver backends and tests all read models the same way.

## ADDED Requirements

### Requirement: File format
A model SHALL be a YAML document whose structure is defined by the project's JSON Schema, SHALL declare its format version in a `format` field, and SHALL be loadable from any file path.

#### Scenario: Model outside the repository
- **WHEN** the validator is given the path of a model file stored outside this repository
- **THEN** the model is loaded and validated the same way as the bundled examples

#### Scenario: Unsupported format version
- **WHEN** a model declares `format: 99`
- **THEN** validation fails with an error naming the version and the versions supported

### Requirement: Identifiers and namespace
Every decision, option, hidden choice, assumption, consequence, rule and constant SHALL have an identifier made of letters, digits and underscores, starting with a letter. Decisions, hidden choices, assumptions, consequences, rules and constants SHALL share one namespace; option ids SHALL be unique within their decision or family.

#### Scenario: Name clash across kinds
- **WHEN** a rule and an assumption are both named `A1`
- **THEN** validation fails with an error naming both

#### Scenario: Same option id in different decisions
- **WHEN** decision `SessionStore` has an option `Database` and the model also has a decision `Database`
- **THEN** the model is valid

### Requirement: Option paths
An option SHALL be referenced in expressions by its full path, `Decision.Option` or `Decision.Family.Option`. A family path (`Decision.Family`) SHALL be allowed only inside `in`, where it means one of the family's options.

#### Scenario: Nested option reference
- **WHEN** a rule refers to `Hosting.Serverless.Functions`
- **THEN** the reference resolves to the `Functions` option in the `Serverless` family of `Hosting`

#### Scenario: Family used as an atom
- **WHEN** a rule uses `Hosting.Serverless` outside `in`
- **THEN** validation fails with an error stating that a family is only allowed inside `in`

### Requirement: Reserved instance qualifiers
The form `Name[instance]` (for example `Hosting[orders]`) SHALL be reserved for future per-instance decisions. A model that uses it SHALL fail validation with an error stating that instances are not supported yet, and no other meaning SHALL be given to square brackets in identifiers.

#### Scenario: Instance qualifier used today
- **WHEN** a rule refers to `Hosting[orders].Serverless.Functions`
- **THEN** validation fails with an error naming the reference and stating that instance qualifiers are reserved

### Requirement: Decisions and options
A model SHALL declare decisions, each with two or more options; exactly one option of each decision holds in a configuration. An option MAY be a family that contains two or more further options; a family itself is never the option that holds.

#### Scenario: Option families
- **WHEN** a decision `Hosting` has families `Containers` and `Serverless`, each with two options
- **THEN** the model is valid and the decision has four selectable options

### Requirement: Hidden choices
A model SHALL be able to declare yes/no choices that are not decisions, may carry a cost and value, and can be referenced by rules.

#### Scenario: Hidden choice in a rule
- **WHEN** a rule refers to the hidden choice `InstantRevocation`
- **THEN** the model is valid

### Requirement: Assumptions
A model SHALL declare open questions as assumptions, each either yes/no or numeric, with a description and an optional closing action. A numeric assumption SHALL declare integer `min` and `max` bounds.

#### Scenario: Numeric assumption with bounds
- **WHEN** assumption `A10` is declared numeric with `min: 0` and `max: 2000`
- **THEN** rules may compare `A10` with integers, and values outside the bounds are invalid inputs

#### Scenario: Numeric assumption without bounds
- **WHEN** a numeric assumption has no `max`
- **THEN** validation fails with an error naming the assumption

### Requirement: Constants
A model MAY declare named integer constants, and numeric terms SHALL be able to refer to them by name.

#### Scenario: Constant in a rule
- **WHEN** constants `PricePerThousand: 2` and `Budget: 1000` are declared and a rule compares `A10 × PricePerThousand` with `Budget`
- **THEN** the model is valid

### Requirement: Rule expressions
Rules SHALL be written with: atoms (an option path, hidden choice, yes/no assumption or consequence id); `in` over a family path; `all`, `any`, `not`, and `if`/`then`; and comparisons (`lt`, `le`, `eq`, `ge`, `gt`, `ne`) between numeric terms, which are integers, constants, numeric assumptions, `plus`, and `times` with at least one constant factor.

#### Scenario: Implication between options
- **WHEN** a rule states `if: InstantRevocation` and `then: Sessions.Server`
- **THEN** the model is valid

#### Scenario: Product of two variables
- **WHEN** a rule multiplies two numeric assumptions
- **THEN** validation fails with an error stating that `times` needs a constant factor

### Requirement: Rule metadata
Every rule SHALL have an id, a source and a reason, and SHALL have a confidence level of `verified`, `likely`, `plausible`, `guess` or `unrated`. A missing level SHALL mean `unrated`.

#### Scenario: Missing level
- **WHEN** a rule has no confidence level
- **THEN** it is loaded as `unrated`

### Requirement: Background facts and retired rules
A rule MAY be marked as a background fact, which carries metadata but no expression and SHALL NOT constrain configurations. A rule MAY be marked `retired_by` a background fact; a retired rule SHALL NOT constrain configurations but SHALL remain in the model so that decisions relying on it can be found.

#### Scenario: Retired rule
- **WHEN** rule R14 is marked `retired_by: R11` and R11 is a background fact
- **THEN** the model is valid and R14 does not constrain configurations

#### Scenario: Retired by something that is not a fact
- **WHEN** rule R14 is marked `retired_by: R2` and R2 is a constraining rule
- **THEN** validation fails with an error naming R14 and R2

### Requirement: Consequences
A model SHALL declare consequences only in its `consequences` section, each as an expression over choices, assumptions and other consequences. Consequences SHALL have no confidence level, SHALL NOT form cycles, and SHALL NOT be set by any input.

#### Scenario: Consequence defined by consequences
- **WHEN** consequence `K5` is defined as `all: [K3, K4]`
- **THEN** the model is valid

### Requirement: Cost and value
Options, hidden choices and combinations of options MAY carry a cost and a value. Both SHALL be non-negative integers in which every point counts the same, so that sums and ratios are meaningful. By default they are relative points; a model MAY instead declare a measured unit (for example hours or money). A model MAY declare `guide: fibonacci`, which makes validation warn about values that are not Fibonacci numbers without rejecting them.

#### Scenario: Combination term
- **WHEN** a combination term gives `{all: [{in: Hosting.Serverless}, Database.ManagedSQL]}` an extra cost of 3
- **THEN** the model is valid

#### Scenario: Declared unit
- **WHEN** a model declares its cost unit as `hours`
- **THEN** an option cost of 40 is valid

#### Scenario: Value off the Fibonacci guide
- **WHEN** a model declares `guide: fibonacci` and an option has cost 4
- **THEN** the model is valid, with a warning naming the option and the nearest guide values 3 and 5

#### Scenario: Negative or fractional value
- **WHEN** an option has cost 2.5 or -1
- **THEN** validation fails with an error naming the option

### Requirement: Bundled examples
The project SHALL ship the minimal example and the reference model exactly as specified in this change's design, both valid.

#### Scenario: Minimal example size
- **WHEN** the minimal example is loaded
- **THEN** it has 3 decisions, 2 rules and 1 assumption, and with `Sessions = Token` the hidden choice `InstantRevocation` cannot hold

#### Scenario: Reference model profile
- **WHEN** the reference model is loaded
- **THEN** it has 10 decisions of which one has option families; at least 10 constraining rules covering every confidence level; 14 assumptions, each used by at least one rule; a decision whose options depend on at least 4 assumptions; at least 2 assumptions that each affect 2 decisions or hidden choices; a chain of four steps from a choice through three consequences where two chains converge; a numeric rule; a retired rule that an accepted decision relies on; and a cost and value on every option
