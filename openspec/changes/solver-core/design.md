# Design

## Context

There is no code yet. The concept ([docs/concept.md](../../../docs/concept.md)) compares two authoring routes, MiniZinc and UVL with Z3, and leans towards MiniZinc without evidence. Development is test-first ([CONTRIBUTORS.md](../../../CONTRIBUTORS.md)), and tests of solving must run against a model comparable to a real-world specification. The real pilot stays outside the repository; only its structural profile is used here.

## Goals / Non-Goals

**Goals:**
- One conformance suite, written before any backend, that both backends must pass.
- Ground truth for that suite computed mechanically, not by hand.
- A recorded, evidence-based answer to Q6, Q7 and the browser part of Q3.

**Non-Goals:**
- A stable public API or file format for models. The model file format is the next change; here the two language files are fixtures.
- Production-quality UVL support. The UVL backend only has to be good enough to compare.

## Decisions

### 1. Backend interface

Both backends implement one interface, and everything above it (propagation, assumption toggling, QuickXplain, soft-rule reporting) is shared code:

```
load(model)                                     -> handle
check(handle, choices, assumptions, ruleIds)    -> sat | unsat
optimise(handle, choices, assumptions, soft)    -> violated soft rule ids (min total weight)
consequences(handle, choices, assumptions)      -> id -> true | false | undetermined
```

`check` takes an explicit subset of rule ids, which is all QuickXplain needs. Consequence and group-structure rules are always included; only rule-table rules are subject to subsetting.

*Alternative:* let each backend produce its own cores (Z3 unsat cores, FindMUS). Rejected as the primary path: it ties explanations to one backend and, for MiniZinc in the browser, depends on whether the WebAssembly build includes FindMUS `[?]`. Native cores may still be used as a seed to speed QuickXplain up.

### 2. QuickXplain over the interface

Explanations come from QuickXplain run over `check`, with choices and known assumption values treated as removable constraints alongside rules. This closes Q7 in favour of the in-browser loop unless it misses the response-time requirement.

### 3. Assumptions as per-run constraints

An unknown assumption is never left free. For each option, the shared layer first checks with all unknown assumptions free to find whether the option can be feasible at all, then toggles only the assumptions that appear in the rules reachable from that option (spec: limit on assumption combinations).

A numeric assumption cannot be toggled. While it has no value, rules that reference it are left out of the check, and every option those rules touch lists the assumption as a dependency.

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

The model is written twice, as `reference.mzn` and `reference.uvl`, plus a language-neutral `reference.json` that the brute-force solver reads. A parity test checks that all three produce the same feasibility on a sample of configurations.

### 5. Brute-force reference solver

A test-only evaluator that enumerates every assignment of decisions, hidden choices and Boolean assumptions (about 4·4·3·3·3·2·2·2·2·2 option combinations × 2² hidden × 2¹³ assumptions ≈ 2.5 × 10⁸ worst case) is too slow if done naively. It therefore enumerates only the variables not fixed by the test's choices and known assumptions, and treats A10 by checking the numeric rule directly. Each conformance test compares backend output with it: feasibility exactly, explanations by minimality and unsatisfiability rather than by equality (several minimal explanations can exist).

*Alternative:* hand-written expected values only. Rejected: error-prone at this size. Named scenarios from the specs are still written by hand, and must agree with the reference solver.

### 6. Package and runtime

TypeScript, tested with Vitest in Node, plus a browser run of the same suite (Vitest browser mode or Playwright) to measure the response-time requirement and to settle Q3. The browser run uses a plain static page; a claude.ai artifact is tried once and recorded, not required.

### 7. Choosing the backend

The backend that passes the suite wins. If both pass, the decision weighs, in order: browser viability without cross-origin isolation, propagation time, bundle size, then readability of the model file. The result and the measurements are recorded here before the losing backend is removed.

## Risks / Trade-offs

- [Brute force too slow for some tests] → Restrict it to unfixed variables; for tests with few choices, sample assignments and keep exhaustive checks for the named scenarios.
- [`z3-solver` needs `SharedArrayBuffer` and therefore cross-origin isolation] → Measured in the browser run; if so, it counts against the UVL route under decision 7.
- [Two model files drift apart] → The parity test against `reference.json`.
- [QuickXplain too slow at this size] → Seed it with the backend's native core where available.
- [Response-time target of 2 seconds is a guess] → Revisit it with the first measurements; changing it changes the spec.

## Open Questions

- Exact unit price, budget and traffic values for R10: chosen while writing the numeric scenarios; they do not change the approach.
