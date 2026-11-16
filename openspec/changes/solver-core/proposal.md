# Proposal

## Why

Every later stage of the product (configurator UI, export, write-up, EventCatalog sync) depends on one engine that, for a model and a set of choices, says which options remain feasible, which are forced, why the others are not, what to change to enable them, what that depends on, and what the result costs. This change builds that engine test-first on the model format from the `model-format` change, against both bundled models.

## What Changes

- Implement the solving behaviour in language-neutral terms: inputs are a model (in the format of `model-format`) plus choices and assumption values; outputs are ids and numbers.
- Report feasible, infeasible and **forced** options, including options feasible only under a particular assumption value.
- Explain infeasibility with minimal conflicts (QuickXplain), and suggest **repairs**: the smallest sets of choices to change so that a wanted option becomes feasible (FastDiag), as configurator research found users need ([range fixes](https://gsd.uwaterloo.ca/publications/view/436.html)).
- Treat rules below a confidence threshold as soft and blame doubtful rules level first ([ADR-0004](../../../docs/decisions/0004-confidence-as-ordered-levels.md)).
- Report consequences, totals, ranges, cheapest and most valuable configurations, the cost/value Pareto front, and value per cost for ranking options ([ADR-0006](../../../docs/decisions/0006-relative-cost-and-value.md)).
- Make solving tools modules that declare the query kinds they answer ([ADR-0005](../../../docs/decisions/0005-solving-tools-as-modules.md)).
- Build two backends, clingo first and MiniZinc second ([ADR-0003](../../../docs/decisions/0003-clingo-first-minizinc-second.md)), each with a compiler from the model format, plus a brute-force backend as test oracle.
- Measure in a browser and inside a claude.ai artifact, and record the results in ADR-0003.

Out of scope: the configurator UI and its list orderings, JSON export, LLM write-up, evidence layer, stale-justification detection, MCP routes (Q9), further query kinds (what-if, which open question to answer first), UVL import.

## Capabilities

### New Capabilities

- `solving/feasibility`: Feasible, infeasible and forced options, including feasibility that holds only under a particular assumption value.
- `solving/conflict-explanation`: A minimal set of rules, choices and assumption values behind an infeasible option or an inconsistent configuration.
- `solving/diagnosis`: The smallest sets of choices to change so that a wanted option becomes feasible or an inconsistent configuration becomes consistent.
- `solving/soft-rules`: Rules below a confidence threshold do not remove options; doubtful rules are blamed level first.
- `solving/consequences`: Derived outcomes reported for a configuration and usable by rules.
- `solving/cost`: Totals, ranges, cheapest and most valuable configurations, the Pareto front, and value per cost.
- `solving/backends`: Solving tools as modules that declare supported query kinds, with routing and rejection of unsupported queries.

### Modified Capabilities

None.

## Impact

- **Concept sections:** §2 (pipeline stage 2), §4.3–4.5 (languages, confidence), §5 (solving and explanation), §8 (worked example).
- **Open questions:** closes Q6 and Q7 and the browser part of Q3; informs Q8 by exercising a threshold.
- **Unverified claims relied on or closed:**
  - `[U]` one solver call per option is fast enough (§5): measured on the reference model, in a browser.
  - `[U]` per-value assumption checks (§5): closed by both backends.
- **Depends on:** the `model-format` change.
- **New code:** a TypeScript package with the module registry, query handlers, the clingo and MiniZinc backends with their compilers, and the brute-force oracle.
- **Dependencies:** `clingo-wasm`, `minizinc`. Their WebAssembly files ship with the application, because a claude.ai artifact cannot fetch them from a CDN (ADR-0003).
