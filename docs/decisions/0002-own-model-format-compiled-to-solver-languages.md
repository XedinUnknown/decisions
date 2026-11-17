---
status: accepted
date: 2026-11-16
---

# Own model format, compiled to solver languages

## Context and Problem Statement

A decision model (decisions, options, rules, assumptions, consequences, costs) has to reach one or more solvers. [Concept §4.2](../concept.md#42-gap-constraint-metadata) rejected a custom JSON format in favour of authoring directly in a standard language (UVL or MiniZinc) for portability. Since then, the application has become composed from modules: several backends may answer different kinds of questions over the same model ([ADR-0005](0005-application-composed-from-config-based-modules.md)), and an AI is expected to maintain models through conversation. What is the authoritative model format?

## Decision Drivers

* Several backends must answer questions about the same model.
* AI-maintained models need a format that can be validated deterministically before any solver runs.
* Rule identity and metadata (id, source, confidence level, reason) must be first-class, which UVL cannot express without workarounds.
* Standard formats should stay reachable, as compile targets or importers.

## Considered Options

* Own intermediate representation (IR): YAML for authoring, a JSON Schema for validation, one compiler per backend
* Author directly in one solver language (ASP, MiniZinc or UVL)
* Author in UVL and translate it to the other backends

## Decision Outcome

Chosen option: "Own intermediate representation", because it is the only option that serves several backends from one source, and it lets models be validated before solving. This reverses the concept's rejection of a custom format: portability now comes from compiling to standard languages, not from authoring in one.

The IR has the element kinds of the concept (decisions with options, hidden yes/no choices, rules, assumptions, consequences, costs and values) and a small expression language for rules: atoms (option paths, hidden choices, yes/no assumptions, consequences), `in` over option families, `all`, `any`, `not`, `if`/`then`, and integer comparisons over linear terms with named constants. The `model-format` change defines it precisely. Every candidate backend expresses each of these directly.

### Consequences

* Good, because one model serves every backend and the brute-force test oracle.
* Good, because a JSON Schema plus semantic checks (unknown ids and consequence cycles as errors; unused assumptions and unrated rules as warnings) catch AI drafting errors before solving.
* Good, because UVL remains possible as an importer into the IR.
* Bad, because the format is not a standard; its documentation and schema are this project's responsibility.
* Bad, because each backend needs a compiler (expected to be a few hundred lines each).

## More Information

* Specified in the `model-format` change (format, validation, bundled models) and the `solver-core` change (compilers and backends).
* The [Potassco COOM Suite](https://github.com/potassco/coom-suite) (MIT) is a configuration language compiled to clingo; read it before fixing the IR's details.
