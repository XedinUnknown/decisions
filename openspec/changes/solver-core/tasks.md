# Tasks

Test tasks come before the implementation tasks they cover. A new test must fail first, for the expected reason, before the implementation that makes it pass.

## 1. Project scaffolding

- [ ] 1.1 Create the TypeScript package (`package.json`, `tsconfig.json`, Vitest) under `packages/solver/` and verify `npx vitest run` exits successfully with an empty suite
- [ ] 1.2 Add a `Makefile` with `setup`, `build`, `dev` and `test` targets (no Docker inside it) and verify each target runs
- [ ] 1.3 Add `docker-compose.yml` with a Node service that runs `make test`, plus `.env.example`, and verify `docker compose run --rm solver make test` passes
- [ ] 1.4 Add a GitHub Actions workflow that runs `make test` on pushes and pull requests to `0.1.x`, and verify it passes on a pushed branch
- [ ] 1.5 Update CONTRIBUTORS.md setup instructions for the new targets and verify the documented commands run as written

## 2. Module composition

- [ ] 2.1 Write composition tests per design.md §1: provider order (definition, override, extension), list-service contributions to `solver/backends` in deterministic order, routing by `solver/backend-preference`, and a missing-key error; verify they fail because nothing exists
- [ ] 2.2 Implement the minimal registry (keyed lazy definitions, extensions, override order, one immutable composed registry) and verify the tests from 2.1 pass
- [ ] 2.3 Write tests for every scenario in `specs/solving/backends/spec.md` using two stub backends with different declared query kinds; verify they fail because the router does not exist
- [ ] 2.4 Implement the router and query-kind declarations, and verify the tests from 2.3 pass

## 3. Reference model and brute-force backend

- [ ] 3.1 Write tests for the brute-force solver on three hand-checked toy models (one alternative group, one cross-tree rule, one unknown assumption, option costs) covering satisfiability, possible and forced options, consequence values and cost totals; verify they fail because the solver does not exist
- [ ] 3.2 Implement the brute-force solver over the language-neutral model format as a backend module declaring every query kind, and verify the tests from 3.1 pass
- [ ] 3.3 Write `reference.json` per design.md §4, and a test that checks it against the profile targets (10 decisions, one nested, about 10 linking rules, 14 assumptions each used by at least one rule, one decision with 4 assumptions, at least 2 assumptions feeding 2 decisions, chain depth 4, one numeric rule, mixed confidence, integer costs and values on every option); verify the test passes
- [ ] 3.4 Add a test that background-fact R11 has no effect on any feasibility result, and verify it passes

## 4. Conformance suite (written before any real backend)

- [ ] 4.1 Write one test per scenario in `specs/solving/feasibility/spec.md`, parameterised by backend module, and verify every test fails with "no handler" rather than a type or import error
- [ ] 4.2 Write one test per scenario in `specs/solving/conflict-explanation/spec.md`, including minimality and unsatisfiability checks for every explanation produced on a sample of configurations; verify they fail as in 4.1
- [ ] 4.3 Write one test per scenario in `specs/solving/soft-rules/spec.md`; verify they fail as in 4.1
- [ ] 4.4 Write one test per scenario in `specs/solving/consequences/spec.md`; verify they fail as in 4.1
- [ ] 4.5 Write one test per scenario in `specs/solving/cost/spec.md`; verify they fail as in 4.1
- [ ] 4.6 Write differential tests that compare feasibility, forced options, consequences and cost ranges against the brute-force backend on a seeded random sample of configurations; verify they fail as in 4.1

## 5. Query handlers, run against the brute-force backend

- [ ] 5.1 Implement the feasibility and forced-option handlers (with `check` fallbacks), nested options and per-value assumption toggling, and verify the tests from 4.1 pass on the brute-force backend
- [ ] 5.2 Implement the QuickXplain explanation handler over `check`, and verify the tests from 4.2 pass on the brute-force backend
- [ ] 5.3 Implement threshold classification and the soft-rule handler over `optimise`, and verify the tests from 4.3 pass on the brute-force backend
- [ ] 5.4 Implement the consequence handler and consequence chains in explanations, and verify the tests from 4.4 pass on the brute-force backend
- [ ] 5.5 Implement the cost handlers (totals, ranges, cheapest, most valuable within budget, return on investment, per-option deltas), and verify the tests from 4.5 pass on the brute-force backend
- [ ] 5.6 Add "consequence", "cost and value" and "forced option" to docs/concept.md (§2 model elements, §4 encodings, §5 solving, §8 worked example) and add Answer Set Programming to §3 and §4; verify the doc names the same element kinds and query kinds as the specs

## 6. MiniZinc backend

- [ ] 6.1 Write `reference.mzn` and a parity test against `reference.json` on the sampled configurations; verify the parity test fails until the backend exists
- [ ] 6.2 Implement the MiniZinc backend module with the `minizinc` package, declaring the query kinds it supports, and verify the parity test and the conformance suite pass for those kinds
- [ ] 6.3 Record in design.md how rule metadata, nested options, consequences and costs are encoded in MiniZinc, and verify the snippets in design.md compile

## 7. UVL + Z3 backend

- [ ] 7.1 Write `reference.uvl` (rule-as-feature) and verify it parses with `uvl-parser`
- [ ] 7.2 Write a parity test for the UVL backend against `reference.json`; verify it fails until the backend exists
- [ ] 7.3 Implement the UVL-to-SMT compiler and the Z3 backend module with `z3-solver`, and verify the parity test and the conformance suite pass for its declared kinds, or record which tests cannot pass and why
- [ ] 7.4 Record in design.md the answers found to Q1 (semantics of feature-attached constraints) and Q2 (JS parser levels), and verify each answer cites the test that shows it

## 8. clingo backend

- [ ] 8.1 Write `reference.lp` with rules as named, switchable clauses, and a parity test against `reference.json`; verify the parity test fails until the backend exists
- [ ] 8.2 Implement the clingo backend module with `clingo-wasm`, using brave and cautious modes for possible and forced options and weak constraints for soft rules, and verify the parity test and the conformance suite pass for its declared kinds
- [ ] 8.3 Record in design.md how rule identity, soft rules, numeric assumptions and costs are encoded in clingo, and verify the snippets in design.md run

## 9. Browser run and measurements

- [ ] 9.1 Run the conformance suite in a browser from a plain static page for every real backend, and verify the run reports pass/fail per backend
- [ ] 9.2 Measure full propagation time, bundle size, query kinds covered without fallback, and whether cross-origin isolation is required, for every real backend, and verify the numbers are recorded in design.md
- [ ] 9.3 Try every real backend once inside a published claude.ai artifact, and verify the outcome (works, fails and why) is recorded in design.md

## 10. Decision and clean-up

- [ ] 10.1 Record the backend decision (Q6), the explanation route (Q7) and browser viability (Q3) in design.md with the evidence from groups 6–9, and verify each decision links to its measurements
- [ ] 10.2 Remove the losing backend modules, their model files and their dependencies, and verify the full suite still passes on the remaining backends and the brute-force backend
- [ ] 10.3 Update docs/concept.md §10 to close Q3, Q6 and Q7 (and Q1, Q2 if answered), and verify no `[U]` claim this change closed is still tagged `[U]`

## Workflow follow-up

- Archive the change with `/openspec-archive-change` after review.
- Start the next change (model file format) from the winning language.
- Candidate later changes as query modules: minimal undo, what-if, which open question to answer first, best return-on-investment ratio.
