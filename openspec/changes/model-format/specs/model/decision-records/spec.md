# Spec Delta

## Purpose

Lets a team that keeps decision records (ADRs) treat each record as the decision itself. The record is the source of truth for status and outcome; a sync step copies those into the model, so the model stays self-contained wherever it is used.

## ADDED Requirements

### Requirement: Decision linked to a record
A decision MAY link to a decision record, given as a file path relative to the model file. The record SHALL be a Markdown file with YAML frontmatter, such as a MADR file or an EventCatalog ADR.

#### Scenario: Linked decision
- **WHEN** decision `Sessions` declares `record: ../docs/decisions/0012-session-state.md`
- **THEN** the model is valid, and the sync command knows which record to read for `Sessions`

### Requirement: Record frontmatter
A linked record SHALL carry its status in the standard `status` field (`proposed`, `accepted`, `rejected`, `deprecated` or `superseded`, optionally followed by a reference such as `superseded by ADR-0123`) and its link to the model in an `x-decision` field with `decision` (the decision id), optional `chosen` (an option id) and optional `relies-on` (rule and assumption ids the decision depends on).

#### Scenario: Accepted record with a chosen option
- **WHEN** the record has `status: accepted` and `x-decision: {decision: Sessions, chosen: Server, relies-on: [R1]}`
- **THEN** a sync copies `status: accepted`, `chosen: Server` and `relies-on: [R1]` into the model's synced fields for `Sessions`

### Requirement: Sync from records
A sync command SHALL read every linked record and write its status, chosen option and relied-on ids into the decision's `synced` block in the model, together with a fingerprint of the record's frontmatter. It SHALL change nothing else in the model, and SHALL report each decision it changed.

#### Scenario: Status changed in the record
- **WHEN** a record's status changes from `proposed` to `accepted` and the sync runs
- **THEN** only that decision's `synced` block changes, and the command reports the decision and the new status

#### Scenario: Nothing changed
- **WHEN** the sync runs and no linked record changed since the last sync
- **THEN** the model file is left byte-for-byte unchanged

### Requirement: Loading never reads records
Loading and validating a model SHALL use only the model file, including its synced blocks, and SHALL NOT require the linked records to be present.

#### Scenario: Model used without its records
- **WHEN** a model with linked decisions is loaded somewhere the record files do not exist
- **THEN** it loads and validates using its synced blocks

### Requirement: Drift check
A check command SHALL compare each synced block with its linked record and fail with a non-zero exit status when a record's frontmatter no longer matches its fingerprint or a synced block was edited by hand, naming each affected decision and record.

#### Scenario: Record changed without a sync
- **WHEN** a record's status is changed and the sync is not run
- **THEN** the check fails naming the decision and the record

#### Scenario: Synced block edited by hand
- **WHEN** a person changes `chosen` inside a `synced` block directly
- **THEN** the check fails naming the decision, because the block no longer matches the record

### Requirement: Status meaning
The loader SHALL interpret a decision's synced status as follows: `accepted` makes its chosen option a current choice; `proposed` makes it a candidate that is reported but not imposed; `rejected`, `deprecated` and `superseded` impose nothing.

#### Scenario: Proposed decision
- **WHEN** a synced block has `status: proposed` and `chosen: Token`
- **THEN** the loaded model lists `Sessions = Token` as a candidate, and no choice is imposed for `Sessions`

### Requirement: Record consistency checks
The sync SHALL refuse to write, and report an error naming the record file, when the record file is missing, has no or malformed frontmatter, has no `x-decision` field, when `x-decision.decision` does not match the decision that links to it, when `chosen` is not an option path of that decision, when `relies-on` names an id the model does not declare, or when the status is `accepted` or `proposed` without a `chosen` option.

#### Scenario: Chosen option missing from the model
- **WHEN** a record says `chosen: Cookie` and decision `Sessions` has no option `Cookie`
- **THEN** the sync reports an error naming the record and `Cookie`, and the model is not changed

#### Scenario: Missing record file
- **WHEN** a decision links to a record file that does not exist
- **THEN** the sync and the check both report an error naming the decision and the path

#### Scenario: Two decisions link the same record
- **WHEN** decisions `Sessions` and `SessionStore` both link to the same record
- **THEN** validation fails with an error naming both decisions and the record

### Requirement: Summaries only
A decision MAY carry a one-line `summary`. When it links to a record, the model SHALL NOT carry the decision's rationale, or a status or chosen option outside the `synced` block; validation SHALL reject either.

#### Scenario: Rationale kept in the record
- **WHEN** a linked decision has a `rationale` field in the model
- **THEN** validation fails with an error stating that rationale belongs in the record

#### Scenario: Status stated outside the synced block
- **WHEN** a linked decision declares `status: accepted` directly
- **THEN** validation fails with an error naming the decision and the record

### Requirement: Models without records
A decision that links to no record MAY declare `status`, `chosen` and `relies-on` directly, and the loader SHALL give them the same meanings as synced values. An `accepted` or `proposed` status without `chosen` SHALL fail validation.

#### Scenario: Team without ADRs
- **WHEN** a decision declares `status: accepted` and `chosen: Server` and no record
- **THEN** the model is valid and `Sessions = Server` is an accepted choice

#### Scenario: Accepted without a chosen option
- **WHEN** a decision declares `status: accepted` without `chosen`
- **THEN** validation fails with an error naming the decision
