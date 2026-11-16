# Spec Delta

## Purpose

Lets a team that keeps decision records (ADRs) treat each record as the decision itself: the record is the source of truth for status and outcome, and the model holds only what solving needs plus a one-line summary.

## ADDED Requirements

### Requirement: Decision linked to a record
A decision MAY link to a decision record, given as a file path relative to the model file. The record SHALL be a Markdown file with YAML frontmatter, such as a MADR file or an EventCatalog ADR.

#### Scenario: Linked decision
- **WHEN** decision `Sessions` declares `record: ../docs/decisions/0012-session-state.md`
- **THEN** the loader reads that record together with the model

### Requirement: Record frontmatter
A linked record SHALL carry its status in the standard `status` field (`proposed`, `accepted`, `rejected`, `deprecated` or `superseded`, optionally followed by a reference such as `superseded by ADR-0123`) and its link to the model in an `x-decision` field with `decision` (the decision id), optional `chosen` (an option id) and optional `relies-on` (rule and assumption ids the decision depends on).

#### Scenario: Accepted record with a chosen option
- **WHEN** the record has `status: accepted` and `x-decision: {decision: Sessions, chosen: Server, relies-on: [R1]}`
- **THEN** the loaded model treats `Sessions = Server` as an accepted choice that relies on R1

### Requirement: Record is the source of truth
When a decision links to a record, its status and chosen option SHALL come only from the record. A model that also declares a status or chosen option for that decision SHALL fail validation.

#### Scenario: Status stated twice
- **WHEN** a decision links to a record and also declares `status: accepted` in the model
- **THEN** validation fails with an error naming the decision and the record

### Requirement: Status meaning
A record's status SHALL be loaded as follows: `accepted` makes its chosen option a current choice; `proposed` makes it a candidate that is reported but not imposed; `rejected`, `deprecated` and `superseded` impose nothing.

#### Scenario: Proposed decision
- **WHEN** a record has `status: proposed` and `chosen: Token`
- **THEN** the loaded model lists `Sessions = Token` as a candidate, and no choice is imposed for `Sessions`

### Requirement: Record consistency checks
Validation SHALL fail when a record's `x-decision.decision` does not match the decision that links to it, when `chosen` is not an option of that decision, or when `relies-on` names an id the model does not declare; each error SHALL name the record file.

#### Scenario: Chosen option missing from the model
- **WHEN** a record says `chosen: Cookie` and decision `Sessions` has no option `Cookie`
- **THEN** validation fails with an error naming the record and `Cookie`

### Requirement: Summaries only
A decision MAY carry a one-line `summary`. When it links to a record, the model SHALL NOT carry the decision's rationale; rationale lives in the record.

#### Scenario: Rationale kept in the record
- **WHEN** a linked decision has a `rationale` field in the model
- **THEN** validation fails with an error stating that rationale belongs in the record

### Requirement: Models without records
A decision that links to no record MAY declare `status` and `chosen` in the model itself, and the loader SHALL give them the same meanings as in a record.

#### Scenario: Team without ADRs
- **WHEN** a decision declares `status: accepted` and `chosen: Server` and no record
- **THEN** the model is valid and `Sessions = Server` is an accepted choice
