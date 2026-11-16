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

* The ADR is the decision; a sync step copies its status and outcome into the model
* The ADR is the decision; the model reads its frontmatter on every load
* The model is the source; ADRs are generated from it

## Decision Outcome

Chosen option: "The ADR is the decision; a sync step copies its status and outcome into the model", because teams review and keep ADRs anyway, and a synced copy keeps the model self-contained. Reading ADRs on every load fails wherever the records are not present: in a browser, in a claude.ai artifact, or when the ADRs live in EventCatalog or another repository.

* The model holds what solving needs (options, rules, assumptions, consequences) and a one-line summary per decision.
* A sync command copies `status`, the chosen option and the relied-on ids from each linked ADR into a `synced` block in the model, with a fingerprint of the record's frontmatter. Only the sync writes that block.
* A drift check (run in CI) fails when an ADR changed without a re-sync, or a synced block was edited by hand.
* A linked ADR carries `status` (standard MADR and EventCatalog field) and an `x-decision` field with the decision id, the chosen option and the rules and assumptions it relies on. Custom `x-` fields are allowed in [EventCatalog ADRs](https://www.eventcatalog.dev/docs/development/guides/resources/adrs/reference.md); MADR frontmatter is optional metadata and accepts extra fields.
* Technical specifications summarise decisions and link to their ADRs.
* Teams without ADRs keep status and chosen option in the model.
* Writing and updating ADRs (when, which template, how much prose, who reviews) is process, and belongs in the skill, not in the format.

### Consequences

* Good, because a decision's status and reasoning live in one reviewed place.
* Good, because the solver can flag an accepted ADR whose `relies-on` rules changed or whose chosen option became infeasible: the record to revisit is known.
* Good, because the model works anywhere, and a status change appears as a reviewable diff in the model.
* Bad, because the model can lag behind its ADRs between syncs; the drift check makes that visible rather than preventing it.

### Confirmation

The `model-format` change's `model/decision-records` spec covers the sync, the drift check, and rejection of a model that states a linked decision's status or rationale outside the synced block.
