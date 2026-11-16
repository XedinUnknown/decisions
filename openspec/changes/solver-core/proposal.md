# Proposal

## Why

Every later stage of the product (configurator UI, export, write-up) depends on one engine that, for a set of choices, says which options remain feasible, why the others are not, and what that depends on. Two open choices block building it: the authoring language (UVL or MiniZinc, Q6) and whether explanations can come from an in-browser loop rather than external tools (Q7, Q3). Settling them by building the engine test-first, against a reference model as large and as tangled as a real specification, turns the spike into durable behaviour instead of throwaway code.

## What Changes

- Specify the solving behaviour in language-neutral terms: inputs are a model plus choices and assumption values; outputs are option ids, rule ids, assumption ids and consequence ids.
- Add **consequences** to the concept: derived outcomes that are neither choices nor rules, defined by the model and reported by the solver (docs/concept.md §2 and §8).
- Add a generic **reference model** whose structure matches the profile of a real-world specification (about 10 decisions, one nested; about 10 linking rules; 14 assumptions; converging chains of depth 4; a numeric cost rule; mixed confidence). It is written once in each candidate language.
- Add a **brute-force reference solver** in the test suite that enumerates assignments and computes ground truth for feasibility, conflicts and consequences, so expected results are not derived by hand.
- Implement two backends behind one interface: MiniZinc via `minizinc` (WebAssembly) and UVL via `uvl-parser`, an own compiler and `z3-solver` (WebAssembly). Run the same conformance suite against both, plus the reference solver.
- Implement QuickXplain on top of the backend interface, so explanations need no external tool.
- Record the backend decision (Q6), the explanation route (Q7) and browser viability (Q3) in design.md, then remove the losing backend.

Out of scope: the configurator UI, JSON export, LLM write-up, evidence layer, stale-justification detection, and MCP routes (Q9). The reference model includes a stale justification so that a later change can test against it.

## Capabilities

### New Capabilities

- `solving/feasibility`: Propagation. For given choices and assumption values, which options remain feasible, including feasibility that holds only under a particular assumption value.
- `solving/conflict-explanation`: For an infeasible option or an inconsistent configuration, a minimal set of rule ids and assumptions that conflict.
- `solving/soft-rules`: Rules below a confidence threshold are soft; the solver reports which low-confidence rules would have to be wrong for an option to become feasible, weighted by confidence.
- `solving/consequences`: Derived outcomes that the model defines in terms of choices, reported for a configuration and usable by rules.

### Modified Capabilities

None.

## Impact

- **Concept sections:** §2 (pipeline stage 2), §4.3–4.4 (languages, confidence), §5 (solving and explanation), §8 (worked example, extended).
- **Open questions:** closes Q6, Q7 and the browser part of Q3; partly answers Q1 and Q2 if the UVL backend is built far enough; informs Q8 by exercising a threshold.
- **Unverified claims relied on or closed:**
  - `[U]` one solver call per option is fast enough (§5): measured on the reference model.
  - `[U]` Z3 supports weighted soft constraints (§4.4): closed by the UVL backend.
  - `[U]` `z3-solver` runs in a browser; `[?]` its threading requirements (§5): closed by running both backends from a static page.
  - `[U]` per-value assumption checks via `check-sat-assuming` or added constraints (§5): closed by both backends.
- **New code:** a JavaScript/TypeScript package with the backend interface, two backends, QuickXplain, the reference solver and the conformance suite.
- **Dependencies:** `minizinc`, `uvl-parser`, `z3-solver` (the losing one is removed at the end).
