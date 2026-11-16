---
status: accepted
date: 2026-11-16
---

# In an ADR-based flow, decisions are their decision records

## Context and Problem Statement

A team that keeps ADRs records each decision's status, outcome and reasoning there. A decision model also has decisions with a status and a chosen option. If both hold them, they drift apart. Which is the source of truth, and what does each hold?

## Decision Drivers

* One source of truth per fact.
* ADRs are the established artefact teams already review and keep.
* The solver needs a machine-readable status and chosen option.

## Considered Options

* The ADR is the decision: the model links to it and reads status and outcome from its frontmatter
* The model is the source; ADRs are generated from it
* Both hold status and outcome, kept in sync by tooling

## Decision Outcome

Chosen option: "The ADR is the decision", because teams review and keep ADRs anyway, and reading two fields from frontmatter is simpler than keeping two copies in sync.

* The model holds what solving needs (options, rules, assumptions, consequences) and a one-line summary per decision.
* A linked ADR carries `status` (standard MADR and EventCatalog field) and an `x-decision` field with the decision id, the chosen option and the rules and assumptions it relies on. Custom `x-` fields are allowed in [EventCatalog ADRs](https://www.eventcatalog.dev/docs/development/guides/resources/adrs/reference.md); MADR frontmatter is optional metadata and accepts extra fields.
* Technical specifications summarise decisions and link to their ADRs.
* Teams without ADRs keep status and chosen option in the model.
* Writing and updating ADRs (when, which template, how much prose, who reviews) is process, and belongs in the skill, not in the format.

### Consequences

* Good, because a decision's status and reasoning live in one reviewed place.
* Good, because the solver can flag an accepted ADR whose `relies-on` rules changed or whose chosen option became infeasible: the record to revisit is known.
* Bad, because loading a model now also means reading the linked records.

### Confirmation

The `model-format` change's `model/decision-records` spec rejects a model that states a linked decision's status or rationale itself.
