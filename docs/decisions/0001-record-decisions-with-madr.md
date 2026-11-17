---
status: accepted
date: 2026-11-16
---

# Record standing decisions as MADR files next to OpenSpec changes

## Context and Problem Statement

Planning uses [OpenSpec](https://github.com/Fission-AI/OpenSpec): each change carries its own proposal, specs, design and tasks, and is archived when done. Some decisions outlive a single change (the model format, the solver choice, how confidence is interpreted). Where do those live so that later changes, contributors and agents find them?

## Decision Drivers

* A decision made in one change's `design.md` disappears into the archive with that change.
* The product itself is meant to help teams that keep decision records; this repository should follow the same process.
* Agents must be able to find and cite standing decisions.

## Considered Options

* MADR 4.0.0 files in `docs/decisions/`, linked from the change that made them
* Only OpenSpec `design.md` files
* Decisions recorded in `docs/concept.md`

## Decision Outcome

Chosen option: "MADR 4.0.0 files in `docs/decisions/`", because it keeps cross-change decisions durable and discoverable while OpenSpec keeps describing what each change does and how.

* OpenSpec `design.md` explains a change's approach and links the ADRs it creates or relies on.
* An ADR records one standing decision, with the options considered and the evidence.
* `docs/concept.md` stays a draft of ideas and links to ADRs where a question has been decided.
* New ADRs copy [adr-template.md](adr-template.md) and take the next free number.
* ADRs leave out MADR's optional Confirmation section. Whether the implementation follows a decision is checked by OpenSpec specs and tasks, which change with the code; an ADR that names them would go stale. Evidence behind a decision, such as a probe's findings, goes under More Information.

### Consequences

* Good, because decisions survive change archiving and can be superseded explicitly.
* Good, because the repository dogfoods the workflow the product is meant to support.
* Bad, because a decision can be described in two places (a change's `design.md` and an ADR); the ADR is authoritative and `design.md` links to it.

## More Information

* [MADR 4.0.0](https://adr.github.io/madr/)
