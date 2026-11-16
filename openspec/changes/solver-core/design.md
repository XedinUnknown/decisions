# Design

## Context

There is no code yet. The concept ([docs/concept.md](../../../docs/concept.md)) compares two authoring routes, MiniZinc and UVL with Z3, and leans towards MiniZinc without evidence; this change adds Answer Set Programming (clingo) as a third. Development is test-first ([CONTRIBUTORS.md](../../../CONTRIBUTORS.md)), and tests of solving must run against a model comparable to a real-world specification. The real pilot stays outside the repository; only its structural profile is used here.

## Goals / Non-Goals

**Goals:**
- One conformance suite, written before any backend, that every backend must pass.
- Ground truth for that suite computed mechanically, not by hand.
- A recorded, evidence-based answer to Q6, Q7 and the browser part of Q3.

**Non-Goals:**
- A stable public API or file format for models. The model file format is the next change; here the two language files are fixtures.
- Production-quality UVL support. The UVL backend only has to be good enough to compare.

## Decisions

### 1. Modules and composition

The engine is a host; backends and query handlers are modules. Following config-based modularity, a module is only its provider: keyed definitions and extensions, with no lifecycle of its own. The host chooses the module set and order and composes one immutable registry.

| Key | Definition | Extended by |
| --- | --- | --- |
| `solver/backends` | list service, empty | each backend module appends its backend |
| `solver/backend-preference` | list of backend ids, host-owned | host overrides per environment |
| `solver/queries` | map from query kind to handler | query modules add handlers (feasibility, forced, explanation, soft rules, consequences, cost) |
| `solver/router` | picks, per query kind, the first preferred backend that declares that kind | — |

A backend module defines `solver/backend/<id>` (for example `minizinc`, `z3-uvl`, `clingo`, `brute-force`) with its declared query kinds, and extends `solver/backends` with it. A test composes the brute-force module only; production composes the winning backend. New tools later (a Prolog or Datalog backend, an MCP-backed explainer) are further modules; new questions (minimal undo, what-if) are further query handlers. Neither changes the engine.

*Alternative:* a plugin registry that backends call into at start-up. Rejected: registration as a side effect hides load order and makes test composition harder than appending a module to the set.

### 1a. Backend interface and query kinds

Every backend implements a subset of these query kinds and declares which:

```
load(model)                                          -> handle
check(handle, choices, assumptions, ruleIds)         -> sat | unsat                     kind: check
optimise(handle, choices, assumptions, objective)    -> assignment + objective value     kind: optimise
consequences(handle, choices, assumptions)           -> id -> true | false | undetermined kind: consequences
possible(handle, choices, assumptions)               -> options true in some completion  kind: enumerate-brave
forced(handle, choices, assumptions)                 -> options true in all completions  kind: enumerate-cautious
```

`check` takes an explicit subset of rule ids, which is all QuickXplain needs. Consequence and group-structure rules are always included; only rule-table rules are subject to subsetting. `objective` is one of: minimise weight of violated soft rules, minimise total cost, maximise total value under a cost bound.

Query handlers fall back on `check` when a backend lacks a richer kind: forced and possible options can be computed with one `check` per option; ranges with repeated bounded `check`. A backend with only `check` is therefore enough for everything except optimisation, which is the case `solving/backends` rejects explicitly.

*Alternative:* let each backend produce its own cores (Z3 unsat cores, FindMUS). Rejected as the primary path: it ties explanations to one backend and, for MiniZinc in the browser, depends on whether the WebAssembly build includes FindMUS `[?]`. Native cores may still be used as a seed to speed QuickXplain up.

### 2. QuickXplain over the interface

Explanations come from QuickXplain run over `check`, with choices and known assumption values treated as removable constraints alongside rules. This closes Q7 in favour of the in-browser loop unless it misses the response-time requirement.

### 3. Assumptions as per-run constraints

An unknown assumption is never left free. For each option, the shared layer first checks with all unknown assumptions free to find whether the option can be feasible at all, then toggles only the assumptions that appear in the rules reachable from that option (spec: limit on assumption combinations).

A numeric assumption cannot be toggled. While it has no value, rules that reference it are left out of the check, and every option those rules touch lists the assumption as a dependency.

### 3a. Cost, value and return on investment

Costs and values are integers on options, like story points. Totals are linear sums, so every candidate optimises them directly: MiniZinc with `minimize`/`maximize`, Z3 with its optimiser, clingo with `#minimize`/`#maximize` and priorities. Currency fits by using whole minor units (cents); clingo's 32-bit integers cover totals up to about 21 million in major units.

Return on investment (value ÷ cost) is not linear, so it is reported, not optimised: it is computed from the totals after solving. Optimisation targets are cheapest completion and most value within a budget, both linear. If "best ratio" is needed later, it can be added as a query handler that iterates the linear problem (Dinkelbach's method), without changing any backend.

Per-option cost deltas and the impact counts a UI may sort by (for example, how many options an open question affects) are numbers the engine reports; ordering them into lists is a UI concern.

### 4. Reference model

A generic SaaS web-application model, matched to the pilot's structural profile (kept on the internal Confluence page, §11). Ids are stable because tests cite them.

**Decisions (10):**

| Id | Options |
| --- | --- |
| Sessions | Server · Token |
| Hosting | Containers {ManagedCluster, PaaS} · Serverless {Functions, Edge} |
| Realtime | WebSockets · SSE · Polling |
| Database | ManagedSQL · ServerlessSQL · DocumentStore |
| SessionStore | Database · InMemory · ExternalKV |
| CDN | HostProvider · Independent (justification "decided by Hosting", made stale by R11) |
| Auth | Own · External |
| Region | Single · Multi |
| Logging | FullBodies · MetadataOnly |
| Search | DatabaseFullText · External |

**Hidden choices (2):** `InstantRevocation`, `AuditTrail`.

**Consequences (3):** K1 personal data at rest · K2 new third-party processor · K3 privacy review widens.

**Rules:**

| Id | Rule | Confidence |
| --- | --- | --- |
| R1 | InstantRevocation ⇒ Sessions = Server | 255 |
| R2 | Hosting ∈ Serverless ∧ Realtime = WebSockets ⇒ A1 | 255 |
| R3 | Hosting ∈ Serverless ∧ Sessions = Server ⇒ SessionStore ≠ InMemory | 255 |
| R4 | SessionStore = InMemory ⇒ Hosting ∈ Containers ∧ A4 | 180 |
| R5 | K1 ⇔ Logging = FullBodies ∨ AuditTrail | 255 |
| R6 | K2 ⇔ Auth = External ∨ Search = External ∨ SessionStore = ExternalKV | 255 |
| R7 | K2 ∧ Region = Single ⇒ A7 | 180 |
| R8 | K3 ⇔ K1 ∨ K2 | 255 |
| R9 | Region = Multi ⇒ A9 | 100 |
| R10 | Hosting ∈ Serverless ⇒ A10 × unitPrice ≤ budget | 100 |
| R12 | Hosting = Serverless/Edge ⇒ A5 | unrated |
| R13 | Database = ServerlessSQL ∧ Hosting ∈ Containers ⇒ A2 | 25 |
| R11 | Background fact: any CDN works with any host (no constraint; removes CDN's justification) | 255 |

R11 is deliberately not a constraint: it tests that background facts do not affect solving.

**Assumptions (14):** A1 long-lived WebSockets on the platform · A2 serverless SQL connection limits suffice · A3 external KV store in region · A4 PaaS sticky sessions · A5 database driver runs at the edge · A6 CDN does not buffer SSE · A7 processors offer hosting in region · A8 identity provider supports instant revocation · A9 database cross-region replication · A10 expected monthly requests (numeric) · A11 search latency target met · A12 log pipeline can redact bodies · A13 CDN passes WebSocket upgrades · A14 team can operate a cluster.

Some of these are referenced only by rules added while writing the conformance suite (for example A3, A6, A8, A11–A14); each must end up in at least one rule, so that the model has no dead assumptions. The profile targets are: one decision depending on 4 assumptions (Hosting: A1, A4, A5, A14), and at least 2 assumptions feeding 2 decisions each.

**Costs and values:** every option gets an integer cost from 1 to 13 (story-point scale) and a value from 0 to 10, chosen so that the cheapest options conflict through at least one hard rule, and the cheapest and the most valuable completions differ.

The model is written three times, as `reference.mzn`, `reference.uvl` and `reference.lp` (clingo), plus a language-neutral `reference.json` that the brute-force solver reads. A parity test checks that all three produce the same feasibility on a sample of configurations.

### 5. Brute-force reference solver

A test-only evaluator that enumerates every assignment of decisions, hidden choices and Boolean assumptions (about 4·4·3·3·3·2·2·2·2·2 option combinations × 2² hidden × 2¹³ assumptions ≈ 2.5 × 10⁸ worst case) is too slow if done naively. It therefore enumerates only the variables not fixed by the test's choices and known assumptions, and treats A10 by checking the numeric rule directly. Each conformance test compares backend output with it: feasibility exactly, explanations by minimality and unsatisfiability rather than by equality (several minimal explanations can exist).

*Alternative:* hand-written expected values only. Rejected: error-prone at this size. Named scenarios from the specs are still written by hand, and must agree with the reference solver.

### 6. Package and runtime

TypeScript, tested with Vitest in Node, plus a browser run of the same suite (Vitest browser mode or Playwright) to measure the response-time requirement and to settle Q3. The browser run uses a plain static page; a claude.ai artifact is tried once and recorded, not required.

### 7. Third candidate: Answer Set Programming (clingo)

clingo is a Prolog-like answer set solver from the Potassco group, built for configuration and search. Its brave and cautious reasoning modes answer "what is still possible" and "what is forced" in one call each, and it optimises with `#minimize`/`#maximize`. Checked on 2026-11-16 with `clingo-wasm` 0.6.0 in Node on a two-decision toy model with costs and an R1-shaped rule: brave mode excluded the ruled-out option, cautious mode returned the forced option, and `#minimize` returned the cheapest total with `OPTIMUM FOUND` `[V]`. Rules are plain facts and clauses, so the model itself can be queried (for example, which rules mention a decision).

Open for the spike: rule identity for explanations (rules as named, switchable clauses), soft rules via weak constraints, numeric assumptions within integer domains, and its browser behaviour.

### 8. Choosing the backend

A backend that passes the suite is a candidate. Among candidates, the decision weighs, in order: browser viability without cross-origin isolation, propagation time, bundle size, coverage of query kinds without fallbacks, then readability of the model file. The result and the measurements are recorded here before the losing backends are removed. More than one backend may stay if each covers query kinds the other lacks; the module mechanism allows that.

## Risks / Trade-offs

- [Brute force too slow for some tests] → Restrict it to unfixed variables; for tests with few choices, sample assignments and keep exhaustive checks for the named scenarios.
- [`z3-solver` needs `SharedArrayBuffer` and therefore cross-origin isolation] → Measured in the browser run; if so, it counts against the UVL route under decision 7.
- [Two model files drift apart] → The parity test against `reference.json`.
- [QuickXplain too slow at this size] → Seed it with the backend's native core where available.
- [Response-time target of 2 seconds is a guess] → Revisit it with the first measurements; changing it changes the spec.

## Open Questions

- Exact unit price, budget and traffic values for R10: chosen while writing the numeric scenarios; they do not change the approach.
