# Design

## Context

See proposal.md. Everything is contributed through the `composition` change's library and added to its application provider. Models come in the format defined by the `model-format` change, which also ships the minimal example and the reference model. Standing decisions: [ADR-0003](../../../docs/decisions/0003-clingo-first-minizinc-second.md) (clingo first, MiniZinc second), [ADR-0004](../../../docs/decisions/0004-confidence-as-ordered-levels.md) (confidence levels), [ADR-0005](../../../docs/decisions/0005-application-composed-from-config-based-modules.md) (composition), [ADR-0006](../../../docs/decisions/0006-relative-cost-and-value.md) (cost and value). Development is test-first ([CONTRIBUTORS.md](../../../CONTRIBUTORS.md)).

## Goals / Non-Goals

**Goals:**
- One conformance suite, written before any real backend, that every backend passes for the query kinds it declares.
- Ground truth computed mechanically by a brute-force oracle.
- Measurements that confirm or revise ADR-0003.

**Non-Goals:**
- A stable public API. The engine's API settles when the configurator UI uses it.

## Decisions

### 1. Providers and keys

Per ADR-0005, the engine is contributed through composition (`composition` change, design §2) like every other part of the application. Nothing in the engine knows which backends exist: backends, query handlers and the router are values under `solver/` keys, and any provider may add to them. A backend is not a module of its own by rule; a provider may contribute several backends, or a backend together with its compiler.

| Key | Value | Defined by | Extended by |
| --- | --- | --- | --- |
| `solver/backends` | list of backends, each declaring its query kinds | `solverProvider`, empty | any provider that adds a backend |
| `solver/backend-preference` | list of backend ids, most preferred first | `solverProvider`, `[clingo, minizinc, oracle]` | a composition root, by a later definition per environment |
| `solver/time-limit` | milliseconds per backend call | `solverProvider` | a composition root |
| `solver/queries` | map from question to handler | `solverProvider`, with the handlers of this change | any provider that adds a question |
| `solver/router` | picks the first preferred loaded backend that declares a kind, with the fallback of the `solving/backends` spec | `solverProvider` | diagnostics, e.g. by wrapping it to log which backend answered |
| `solver/engine` | the questions of the specs, answered through `solver/queries` and `solver/router` | `solverProvider` | |
| `solver/load-wasm` | loads a WebAssembly file shipped with the application; required, not defined | bound by the platform provider (`nodeProvider` to `node/load-wasm`) | |
| `model/checks` | extended with checks a backend needs (e.g. compilable numeric terms) | `model-format` | the provider of that backend |

Providers in `packages/solver/`, added to `decisionsProvider` after the `model-format` providers:
- `solverProvider`: the engine keys above.
- `clingoProvider`: the clingo backend and its compiler, appended to `solver/backends`; loads its WebAssembly through `solver/load-wasm`.
- `minizincProvider`: the MiniZinc backend and its compiler.
- `oracleProvider`: the brute-force backend. Tests always include it; `decisionsProvider` does not.

Tests compose `solverProvider` with exactly the backend providers they exercise; the conformance suite runs once per composition.

### 2. Backend interface and query kinds

```
load(model)                                           -> handle
check(handle, choices, assumptions, ruleIds)          -> sat | unsat           kind: check
optimise(handle, choices, assumptions, objectives[])  -> assignment + values   kind: optimise
consequences(handle, choices, assumptions)            -> id -> true|false|undetermined   kind: consequences
possible(handle, choices, assumptions)                -> options true in some completion  kind: possible
forced(handle, choices, assumptions)                  -> options true in all completions  kind: forced
```

`check` takes an explicit subset of constraining rule ids; the option structure and consequence definitions are always included, because they are not rules (model-format: consequences have no level and cannot be removed). `objectives` is a list in priority order; each question uses its own list (soft-rule blame: levels only; cheapest: cost then value; most valuable: value then cost), and cost questions never include soft rules. Handlers fall back on repeated `check` where a backend lacks `possible`, `forced` or `consequences`; only `optimise` has no fallback, and the router rejects it when no loaded backend declares it (spec `solving/backends`).

clingo declares all kinds (`possible` and `forced` through brave and cautious reasoning, `optimise` through weak constraints with priorities). MiniZinc declares `check`, `optimise` and `consequences`.

### 3. Compilers from the model format

Each backend compiles the model once per load:

| Model element | clingo | MiniZinc |
| --- | --- | --- |
| Decision with options | `1 { choose(D,O) : option(D,O) } 1 :- decision(D).` with families as `in(D,F,O)` facts | enum per decision |
| Constraining rule | integrity constraint guarded by `active(R)`, so `check` can switch rules off | `constraint :: "R"` guarded by a Boolean parameter per rule |
| Assumption (yes/no) | atom fixed per run by a fact | `bool` parameter per run |
| Numeric assumption | integer constant per run, or a choice over its bounds when unknown | `int` parameter, or `var min..max` when unknown |
| Constant, `plus`, `times` | integer constants and arithmetic in `#sum` or comparisons | integer constants and arithmetic |
| Consequence (definition, never removable) | rules deriving `k(K)` | `var bool` defined by its expression |
| Retired rule, background fact | not compiled | not compiled |
| Cost, value, combination terms | `#sum` aggregates | `sum(...)` |
| Soft rule | weak constraint `:~ violated(R), level(R,L). [1@P,R]` where `P` grows with the level | lexicographic objective (see §5) |

Choices and assumption values are passed as facts per call. The Siemens API passes them as external atoms so the program is not re-grounded ([Comploi-Taupe et al. 2023](https://www.cs.uni-potsdam.de/wv/publications/DBLP_conf/confws/Comploi-TaupeFH23.pdf)); `clingo-wasm` wraps the command-line tool and offers no such API, so every call re-grounds. Task 5.1 measures whether that fits the response-time requirement before the remaining handlers are built.

### 4. Explanations and repairs

- **Conflicts:** QuickXplain over `check`, treating rules, choices and known assumption values as removable. About 40 lines, backend-neutral. FindMUS is not in MiniZinc's WebAssembly build, and clingo's explanation tools are Python only, so owning this loop is the browser-compatible choice.
- **Repairs:** smallest first, as the spec requires minimum-cardinality order. With `optimise`, minimise the number of changed choices and assumption values subject to the wanted option, then block each found set and repeat. With `check` only, enumerate candidate sets by increasing size (models of this size have few choices). FastDiag is used to shrink a found set to subset-minimal where the order is not needed.
- **Consequence links:** an explanation that contains a rule mentioning a consequence also shows that consequence's definition and the choices that made it true, computed from the final assignment; definitions are never removable elements.
- **Readable parts** (Kepler's approach, [Sahu et al. 2026](https://arxiv.org/abs/2604.25506)) are deferred: splitting rules into parts would need part identifiers outside the id grammar.

### 5. Soft rules by level

Levels map to priorities (verified highest, unrated lowest). clingo's weak-constraint priorities compare level first natively. MiniZinc has no priorities; the objective is a single weighted sum with base `B` greater than the number of rules: a violated rule at level index `n` weighs `Bⁿ`, which reproduces level-first comparison exactly. Blame is computed over completions that include the option, with unknown assumptions free (optimistic); the assumption values of the best completion are reported as relied on (spec).

### 6. Assumptions per value

Feasibility of an option under unknown assumptions is existential: the option is feasible if some values of the unknown assumptions allow it. Its condition is then computed as a minimal disjunction of conjunctions of assumption values (spec: dependency conditions):

1. Collect the unknown assumptions that occur in rules reachable from the option through shared choices and consequences; others cannot matter.
2. Enumerate assignments of those assumptions in order of increasing size of partial assignment, checking feasibility with the rest unconstrained; keep minimal satisfying partial assignments (prime implicants). Reachable sets are small in practice (at most 6 for Hosting in the reference model).
3. For a numeric assumption, find the bound by binary search over its range with `check`, producing literals such as `A10 ≤ 500`.

A condition shared by every feasible option is reported once at configuration level. Forced options quantify the other way: an option is forced if it holds in every feasible completion under every assumption assignment for which the configuration is consistent; `forced` (cautious) is evaluated per relevant assignment, or with repeated `check` as a fallback.

### 7. Cost and value

Totals, ranges, cheapest and most valuable configurations are linear and use `optimise`, with hard rules only. The Pareto front is computed lexicographically: minimise cost, then maximise value at that cost; record the point; require value strictly greater; repeat until infeasible. Each step's lexicographic order prevents recording a dominated point. One completion is returned per point. The robust variant adds, for each yes/no assumption that occurs in a hard rule, the requirement that the completion satisfies the rules under both of its values (and, for numeric ones, at both bounds), which on these models is a small number of copies of the affected rules. Value per cost and deltas are computed from optimisation results for each feasible option.

### 8. Brute-force oracle

The reference model has 6,912 option combinations × 4 hidden-choice combinations = 27,648 combinations of choices, and 2¹³ assignments of yes/no assumptions. A generic evaluator sweeps about 7.7 million assignments per second in Node, so a full naive sweep takes about 29 s.

Instead, the oracle evaluates rules bit-parallel over assumption assignments. Each yes/no assumption is a precomputed 8,192-bit mask (bit i set when assumption assignment i makes it yes). For one combination of choices, every rule reduces to a mask built with AND, OR and NOT over those masks (choice atoms are constants within a combination), so the combination's "satisfies all hard rules" set is the AND of the hard rules' masks: about 20 rules × 128 machine words per combination, roughly 70 million word operations for the whole reference model. The table stores, per combination, the satisfied-assignment mask and one violation mask per soft rule, so blame can be computed too.

The numeric assumption A10 is sampled at its bounds and at the boundary value of each numeric rule (for R10: 500 and 501), which is exact for linear rules with one numeric variable.

Possible options, forced options, conditions, consequences and cost ranges are unions and intersections over the table. Minimality of explanations and repairs is checked with the same table. One build per model and threshold is cached for the whole suite.

The oracle is itself a backend declaring every query kind, contributed by `oracleProvider`, so the shared handlers are developed against it before any real backend exists.

### 9. Runtime and deployment

- TypeScript, Vitest in Node, plus a browser run of the same suite from a static page.
- WebAssembly files ship with the application: the build step copies each backend's JavaScript and `.wasm` files into the output, and an artifact publish includes them with the page. A claude.ai artifact cannot fetch them from a CDN, and is not cross-origin isolated (ADR-0003, probe results).
- No server-side backend (ADR-0003 lists when to revisit).
- MiniZinc's `minizinc.wasm` (18.9 MB) is over the 15 MB limit for a single file published with an artifact. MiniZinc therefore serves self-hosted deployments; clingo is the backend for artifacts. The router's preference list differs per platform.
- MiniZinc's npm package needs a native MiniZinc install in Node; the development container and CI image install it, the Node test run uses it, and the browser run covers the WebAssembly path.
- The browser run is part of CI and enforces the response-time requirement for the clingo backend.

### 10. Every iteration passes on both bundled models

CI runs the whole suite against the minimal example and the reference model on every push (model-format design §4).

## Risks / Trade-offs

- [Re-grounding on every clingo call misses the response-time target] → Measured first (task 5.1). Fallbacks: batch per-option checks into one brave/cautious call; restrict toggled assumptions; consider a multi-shot build later.
- [`clingo-wasm` has one maintainer] → The backend is contributed by its own provider and can be left out or replaced; MiniZinc covers self-hosted use.
- [Oracle and backends share a misreading of the model] → Hand-written scenarios from the specs are checked against both.
- [Response-time target of 2 seconds is a guess] → Revised with measurements; changing it changes the spec.
