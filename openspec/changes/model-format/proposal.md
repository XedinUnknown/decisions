# Proposal

## Why

Every backend, the test oracle and the AI that maintains models need one authoritative description of a decision model ([ADR-0002](../../../docs/decisions/0002-own-model-format-compiled-to-solver-languages.md)). Without it, the first engine change would define the format by accident inside its test fixtures. The format also has to catch AI drafting errors deterministically, before any solver runs.

## What Changes

- Define the model format: YAML for authoring, validated by a JSON Schema plus semantic checks. Element kinds: decisions with options (optionally nested in families), hidden yes/no choices, rules, assumptions (yes/no or numeric), consequences, and cost and value on options and on combinations of options.
- Define the rule expression language: `is`, `in`, `all`, `any`, `not`, `if`/`then`, and integer comparisons over numeric assumptions and option attributes.
- Rule metadata: id, source, confidence level (verified, likely, plausible, guess, unrated; [ADR-0004](../../../docs/decisions/0004-confidence-as-ordered-levels.md)), reason. Background facts are allowed and marked as not constraining.
- Cost and value as relative points on the Fibonacci scale by default, or a declared unit ([ADR-0006](../../../docs/decisions/0006-relative-cost-and-value.md)).
- Identifiers and references (`Decision.Option`, `Decision.Family.Option`), with `Name[instance]` reserved for future per-instance decisions and rejected for now.
- Decision records: a decision may link to an ADR (MADR or EventCatalog), which is then the source of truth for its status and chosen option; a `sync` command copies them into the model and a `check` command catches drift ([ADR-0007](../../../docs/decisions/0007-decisions-are-decision-records.md)). Without a record, status and chosen option live in the model.
- Semantic validation with errors that name the offending id: unknown references, duplicate ids, unused assumptions, cycles between consequences, values off the declared scale.
- Ship two models: a **minimal example** (about 3 decisions, 2 rules, 1 assumption) used in the README and as the first test fixture, and the **reference model** matched to the structural profile of a real specification, used as a stress fixture.
- A command-line validator that reports every error in a model file.

Out of scope: solving, compilers to solver languages (each backend brings its own in `solver-core`), UVL import, the evidence layer, per-instance decisions (only reserved here), and writing or updating decision records (process, for the skill).

## Capabilities

### New Capabilities

- `model/format`: The structure of a decision model file and the rules for a model to be valid.
- `model/validation`: Checking a model file and reporting every error with the id and location it concerns.
- `model/decision-records`: Linking decisions to decision records, which hold their status, chosen option and reasoning.

### Modified Capabilities

None.

## Impact

- **Concept sections:** §2 (schema stage), §4.2 (rejected custom format; reversed by ADR-0002), §4.4 (confidence levels), §8 (worked example).
- **Open questions:** settles Q4 in part (models are files, loaded from wherever they live).
- **Unverified claims relied on:** none.
- **New code:** a TypeScript package with the schema, validator and CLI; `examples/minimal.yaml` and `examples/reference.yaml`.
- **Dependencies:** a YAML parser and a JSON Schema validator.
- **Ordering:** `solver-core` builds on this change.
