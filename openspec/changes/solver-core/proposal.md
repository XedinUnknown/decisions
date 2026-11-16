# Proposal

## Why

Every later stage of the product (configurator UI, export, write-up) depends on one engine that, for a set of choices, says which options remain feasible, why the others are not, what that depends on, and what the result costs. Two open choices block building it: the authoring language (UVL, MiniZinc or Answer Set Programming, Q6) and whether explanations can come from an in-browser loop rather than external tools (Q7, Q3). Settling them by building the engine test-first, against a reference model as large and as tangled as a real specification, turns the spike into durable behaviour instead of throwaway code.

The engine also has to stay open to tools that answer further questions later, so solving tools plug in as modules rather than being wired in.

## What Changes

- Specify the solving behaviour in language-neutral terms: inputs are a model plus choices and assumption values; outputs are option ids, rule ids, assumption ids, consequence ids and numbers.
- Add **consequences** to the concept: derived outcomes that are neither choices nor rules, defined by the model and reported by the solver (docs/concept.md §2 and §8).
- Add **cost and value** to the concept: integer attributes on options (for example story points for effort, and a value score), with the running total, the range over feasible completions, the cheapest completion, the most valuable completion within a budget, and a return-on-investment figure derived from the two.
- Report **forced options**: options that hold in every feasible completion of the current choices.
- Make solving tools **modules**. Each backend declares the query kinds it supports; the engine routes each query to a backend that supports it and rejects queries that no loaded backend supports.
- Add a generic **reference model** whose structure matches the profile of a real-world specification (about 10 decisions, one nested; about 10 linking rules; 14 assumptions; converging chains of depth 4; a numeric rule; mixed confidence; costs and values on options). It is written once in each candidate language.
- Add a **brute-force reference solver** in the test suite that computes ground truth, so expected results are not derived by hand. It is also a backend module, which the shared layer is developed against first.
- Implement three candidate backends: MiniZinc via `minizinc`; UVL via `uvl-parser`, an own compiler and `z3-solver`; and Answer Set Programming via `clingo-wasm`. All run the same conformance suite.
- Implement QuickXplain on top of the backend interface, so explanations need no external tool.
- Record the backend decision (Q6), the explanation route (Q7) and browser viability (Q3) in design.md, then remove the losing backends.

Out of scope: the configurator UI and its list orderings, JSON export, LLM write-up, evidence layer, stale-justification detection, MCP routes (Q9), and further query kinds (minimal undo, what-if, which open question to answer first). The module mechanism is what lets those arrive later; the reference model includes a stale justification so that a later change can test against it.

## Capabilities

### New Capabilities

- `solving/feasibility`: Propagation. For given choices and assumption values, which options remain feasible, which are forced, and which feasibility holds only under a particular assumption value.
- `solving/conflict-explanation`: For an infeasible option or an inconsistent configuration, a minimal set of rule ids and assumptions that conflict.
- `solving/soft-rules`: Rules below a confidence threshold are soft; the solver reports which low-confidence rules would have to be wrong for an option to become feasible, weighted by confidence.
- `solving/consequences`: Derived outcomes that the model defines in terms of choices, reported for a configuration and usable by rules.
- `solving/cost`: Cost and value attributes on options; totals, ranges, cheapest and most valuable completions, and return on investment.
- `solving/backends`: Solving tools as modules that declare supported query kinds, with routing, rejection of unsupported queries, and identical results across backends.

### Modified Capabilities

None.

## Impact

- **Concept sections:** §2 (pipeline stage 2), §4.3–4.4 (languages, confidence), §5 (solving and explanation), §8 (worked example, extended); a new comparison entry for Answer Set Programming in §3 and §4.
- **Open questions:** closes Q6 (now three-way), Q7 and the browser part of Q3; partly answers Q1 and Q2 if the UVL backend is built far enough; informs Q8 by exercising a threshold.
- **Unverified claims relied on or closed:**
  - `[U]` one solver call per option is fast enough (§5): measured on the reference model.
  - `[U]` Z3 supports weighted soft constraints (§4.4): closed by the UVL backend.
  - `[U]` `z3-solver` runs in a browser; `[?]` its threading requirements (§5): closed by running all backends from a static page.
  - `[U]` per-value assumption checks via `check-sat-assuming` or added constraints (§5): closed by the backends.
- **New code:** a TypeScript package with the module composition, the backend interface, three backends, QuickXplain, the reference solver and the conformance suite.
- **Dependencies:** `minizinc`, `uvl-parser`, `z3-solver`, `clingo-wasm` (losing ones are removed at the end).
