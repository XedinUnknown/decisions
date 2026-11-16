# Spec Delta

## Purpose

Reports the derived outcomes of a configuration, such as "personal data is stored at rest", which the model defines in terms of choices and which rules can depend on.

## ADDED Requirements

### Requirement: Consequences are derived, not chosen
A consequence SHALL take its value only from its definition in the model. A request that sets a consequence SHALL be rejected.

#### Scenario: Setting a consequence is rejected
- **WHEN** a request sets consequence K1 to yes
- **THEN** the solver rejects the request with an error naming K1

### Requirement: Consequence values reported
For a consistent configuration, the solver SHALL report each consequence as true or false when it has the same value in every feasible completion, and as undetermined otherwise.

#### Scenario: Consequence follows from a choice
- **WHEN** the choices are `{Logging: FullBodies}`
- **THEN** K1 and K3 are reported true

#### Scenario: Consequence still open
- **WHEN** neither Logging nor AuditTrail is chosen
- **THEN** K1 is reported undetermined

### Requirement: Converging consequences
A consequence defined by other consequences SHALL be reported according to its definition over their values.

#### Scenario: Two chains reach the same outcome
- **WHEN** the choices are `{Auth: External, Logging: MetadataOnly, AuditTrail: no}`
- **THEN** K2 and K3 are reported true and K1 false

#### Scenario: Four-step chain
- **WHEN** the choices are `{Auth: External, Region: Multi}`
- **THEN** K2, K3, K4 and K5 are reported true

### Requirement: Consequences in explanations
When a rule that depends on a consequence takes part in a conflict, the explanation SHALL show the consequence's definition and the choices that made it true, as links between the tested option and the rule.

#### Scenario: Chain shown in full
- **WHEN** the threshold is `likely` and `Search.External` is infeasible because of R7 with `Region = Single` and `A7 = no`
- **THEN** the explanation shows K2's definition linking `Search.External` to R7
