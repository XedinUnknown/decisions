# Spec Delta

## Purpose

Reports the derived outcomes of a configuration, such as "personal data is stored at rest", that the model defines in terms of choices and that rules can depend on.

## ADDED Requirements

### Requirement: Consequences are derived, not chosen
A consequence SHALL take its value only from the model's definition over choices, assumptions and other consequences. A request that sets a consequence directly SHALL be rejected.

#### Scenario: Setting a consequence is rejected
- **WHEN** a request sets consequence K1 to true
- **THEN** the solver rejects the request with an error naming K1

### Requirement: Consequence values reported
For a consistent configuration, the solver SHALL report each consequence as true, false, or undetermined while the choices that define it are still open.

#### Scenario: Consequence follows from a choice
- **WHEN** the choices are `{Logging: FullBodies}`
- **THEN** K1 is reported true

#### Scenario: Consequence still open
- **WHEN** no choice affecting K1 has been made
- **THEN** K1 is reported undetermined

### Requirement: Converging consequences
A consequence defined by other consequences SHALL be reported true when any defining path makes it true.

#### Scenario: Two chains reach the same outcome
- **WHEN** the choices are `{Auth: External, Logging: MetadataOnly, AuditTrail: false}`
- **THEN** K2 and K3 are reported true and K1 false

### Requirement: Consequences in explanations
When a rule that depends on a consequence takes part in a conflict, the explanation SHALL include the rule that defines the consequence and the choices that made it true.

#### Scenario: Chain shown in full
- **WHEN** `Search = External` is infeasible because of R7 with `Region = Single` and `A7 = false`
- **THEN** the explanation includes R6, which makes K2 true, as well as R7
