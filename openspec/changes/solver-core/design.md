# Design

## Context

See proposal.md. Models come in the format defined by the `model-format` change, which also ships the minimal example and the reference model. Standing decisions: [ADR-0003](../../../docs/decisions/0003-clingo-first-minizinc-second.md) (clingo first, MiniZinc second), [ADR-0004](../../../docs/decisions/0004-confidence-as-ordered-levels.md) (confidence levels), [ADR-0005](../../../docs/decisions/0005-solving-tools-as-modules.md) (modules), [ADR-0006](../../../docs/decisions/0006-relative-cost-and-value.md) (cost and value). Development is test-first ([CONTRIBUTORS.md](../../../CONTRIBUTORS.md)).

## Goals / Non-Goals

**Goals:**
- One conformance suite, written before any real backend, that every backend passes for the query kinds it declares.
- Ground truth computed mechanically by a brute-force oracle.
- Measurements that confirm or revise ADR-0003.

**Non-Goals:**
- A stable public API. The engine's API settles when the configurator UI uses it.

## Decisions

### 1. Modules and routing

Per ADR-0005: backends and query handlers are modules contributing to one composed registry.

| Key | Definition | Extended by |
| --- | --- | --- |
| `solver/backends` | list, empty | each backend module appends its backend |
| `solver/backend-preference` | list of backend ids, host-owned | host overrides per environment |
| `solver/queries` | map from query kind to handler | query modules add handlers |
| `solver/router` | first preferred backend that declares the kind | — |

The registry is the minimal version of config-based modularity: keyed definitions, extensions, override order, one immutable composed registry. Nothing more until a third tool arrives.

### 2. Backend interface and query kinds

```
load(model)                                           -> handle
check(handle, choices, assumptions, ruleIds)          -> sat | unsat           kind: check
optimise(handle, choices, assumptions, objectives[])  -> assignment + values   kind: optimise
consequences(handle, choices, assumptions)            -> id -> true|false|undetermined   kind: consequences
possible(handle, choices, assumptions)                -> options true in some completion  kind: possible
forced(handle, choices, assumptions)                  -> options true in all completions  kind: forced
```

`check` takes an explicit subset of constraining rule ids; choice-structure and consequence definitions are always included. `objectives` is a list in priority order (for soft rules by level, then cost or value). Handlers fall back on repeated `check` where a backend lacks `possible`, `forced` or `consequences`; only `optimise` has no fallback, and the router rejects it when no loaded backend declares it.

clingo declares all kinds (`possible` and `forced` through brave and cautious reasoning, `optimise` through weak constraints with priorities). MiniZinc declares `check`, `optimise` and `consequences`.

### 3. Compilers from the model format

Each backend compiles the model once per load:

| Model element | clingo | MiniZinc |
| --- | --- | --- |
| Decision with options | `1 { choose(D,O) : option(D,O) } 1 :- decision(D).` with families as `in(D,F,O)` facts | enum per decision |
| Constraining rule | integrity constraint guarded by `active(R)`, so `check` can switch rules off | `constraint :: "R"` guarded by a Boolean parameter per rule |
| Assumption (yes/no) | atom fixed per run by a fact | `bool` parameter per run |
| Numeric assumption | integer constant per run | `int` parameter |
| Consequence | rules deriving `k(K)` | `var bool` defined by its expression |
| Cost, value, combination terms | `#sum` aggregates | `sum(...)` |
| Soft rule | weak constraint `:~ violated(R), level(R,L). [1@P,R]` where `P` grows with the level | lexicographic objective (see §5) |

Choices and assumption values are passed as facts per call. The Siemens API passes them as external atoms so the program is not re-grounded ([Comploi-Taupe et al. 2023](https://www.cs.uni-potsdam.de/wv/publications/DBLP_conf/confws/Comploi-TaupeFH23.pdf)); `clingo-wasm` wraps the command-line tool and offers no such API, so every call re-grounds. Task 5.1 measures whether that fits the response-time requirement before the remaining handlers are built.

### 4. Explanations and repairs

- **Conflicts:** QuickXplain over `check`, treating rules, choices and known assumption values as removable. About 40 lines, backend-neutral. FindMUS is not in MiniZinc's WebAssembly build, and clingo's explanation tools are Python only, so owning this loop is the browser-compatible choice.
- **Repairs:** FastDiag over `check`, with only choices and assumption values removable (spec: repairs never touch rules). Further repairs are found by blocking each found set and repeating, smallest first.
- **Readable chains** (Kepler's approach, [Sahu et al. 2026](https://arxiv.org/abs/2604.25506)): before QuickXplain, rules whose expression is a conjunction are split into parts with sub-ids (`R2.1`, `R2.2`), so explanations point at the exact part responsible.

### 5. Soft rules by level

Levels map to priorities (verified highest, unrated lowest). clingo's weak-constraint priorities compare level first natively. MiniZinc has no priorities; the objective is a single weighted sum with base `B` greater than the number of rules: a violated rule at level index `n` weighs `Bⁿ`, which reproduces level-first comparison exactly.

### 6. Assumptions per value

An unknown yes/no assumption is never left free. For each option, the handler first checks with unknown assumptions unconstrained, then toggles only assumptions in rules reachable from that option. A numeric assumption without a value leaves its rules out and is listed as a dependency.

### 7. Cost and value

Totals, ranges, cheapest and most valuable configurations are linear and use `optimise`. The Pareto front is computed by the ε-constraint method: minimise cost, record, require value strictly greater, repeat until infeasible. On models of this size the front has few points. Value per cost and deltas are computed from optimisation results for each feasible option.

### 8. Brute-force oracle

The reference model has 6,912 option combinations × 4 hidden-choice combinations = 27,648 combinations of choices, and 2¹³ assignments of yes/no assumptions. A generic evaluator sweeps about 7.7 million assignments per second in Node, so a full naive sweep takes about 29 s.

Instead, the oracle enumerates the 27,648 choice combinations once per model and threshold, and for each records the set of assumption assignments under which it satisfies the hard rules, as a bitset of 8,192 bits. Possible options, forced options, per-assumption verdicts, consequences and cost ranges are then unions and intersections over cached bitsets, so the whole conformance suite needs only one sweep per model and threshold. Minimality of explanations and repairs is checked with the same table.

The oracle is itself a backend module declaring every query kind, so the shared handlers are developed against it before any real backend exists.

### 9. Runtime and deployment

- TypeScript, Vitest in Node, plus a browser run of the same suite from a static page.
- WebAssembly files ship with the application. A claude.ai artifact cannot fetch them from a CDN, and is not cross-origin isolated (ADR-0003, probe results).
- MiniZinc's `minizinc.wasm` (18.9 MB) is over the 15 MB limit for a single file published with an artifact. MiniZinc therefore serves self-hosted deployments; clingo is the backend for artifacts. The router's preference list differs per host.
- MiniZinc's npm package needs a native MiniZinc install in Node; the Node test run uses it, and the browser run covers the WebAssembly path.

### 10. Every iteration passes on both bundled models

CI runs the whole suite against the minimal example and the reference model on every push (model-format design §4).

## Risks / Trade-offs

- [Re-grounding on every clingo call misses the response-time target] → Measured first (task 5.1). Fallbacks: batch per-option checks into one brave/cautious call; restrict toggled assumptions; consider a multi-shot build later.
- [`clingo-wasm` has one maintainer] → The backend is a module; MiniZinc covers self-hosted use.
- [Oracle and backends share a misreading of the model] → Hand-written scenarios from the specs are checked against both.
- [Response-time target of 2 seconds is a guess] → Revised with measurements; changing it changes the spec.
