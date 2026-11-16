# Tasks

Test tasks come before the implementation tasks they cover. A new test must fail first, for the expected reason, before the implementation that makes it pass.

## 1. Project scaffolding

- [ ] 1.1 Create the TypeScript package (`package.json`, `tsconfig.json`, Vitest) under `packages/solver/` and verify `npx vitest run` exits successfully with an empty suite
- [ ] 1.2 Add a `Makefile` with `setup`, `build`, `dev` and `test` targets (no Docker inside it) and verify each target runs
- [ ] 1.3 Add `docker-compose.yml` with a Node service that runs `make test`, plus `.env.example`, and verify `docker compose run --rm solver make test` passes
- [ ] 1.4 Add a GitHub Actions workflow that runs `make test` on pushes and pull requests to `0.1.x`, and verify it passes on a pushed branch
- [ ] 1.5 Update CONTRIBUTORS.md setup instructions for the new targets and verify the documented commands run as written

## 2. Reference model and brute-force reference solver

- [ ] 2.1 Write tests for the brute-force solver on three hand-checked toy models (one alternative group, one cross-tree rule, one unknown assumption) covering satisfiability, enumeration of feasible options and consequence values; verify they fail because the solver does not exist
- [ ] 2.2 Implement the brute-force solver over the language-neutral model format and verify the tests from 2.1 pass
- [ ] 2.3 Write `reference.json` per design.md §4, and a test that checks it against the profile targets (10 decisions, one nested, about 10 linking rules, 14 assumptions each used by at least one rule, one decision with 4 assumptions, at least 2 assumptions feeding 2 decisions, chain depth 4, one numeric rule, mixed confidence); verify the test passes
- [ ] 2.4 Add a test that background-fact R11 has no effect on any feasibility result, and verify it passes

## 3. Conformance suite (written before any backend)

- [ ] 3.1 Define the backend interface (`load`, `check`, `optimise`, `consequences`) as types only, and verify it type-checks
- [ ] 3.2 Write one test per scenario in `specs/solving/feasibility/spec.md`, parameterised by backend, and verify every test fails with "no backend" rather than a type or import error
- [ ] 3.3 Write one test per scenario in `specs/solving/conflict-explanation/spec.md`, including minimality and unsatisfiability checks for every explanation produced on a sample of configurations; verify they fail as in 3.2
- [ ] 3.4 Write one test per scenario in `specs/solving/soft-rules/spec.md`; verify they fail as in 3.2
- [ ] 3.5 Write one test per scenario in `specs/solving/consequences/spec.md`; verify they fail as in 3.2
- [ ] 3.6 Write differential tests that compare feasibility and consequences against the brute-force solver on a seeded random sample of configurations; verify they fail as in 3.2

## 4. Shared solving layer, run against the brute-force backend

- [ ] 4.1 Wrap the brute-force solver as a backend implementing the interface, and verify the interface tests from 3.1 pass for it
- [ ] 4.2 Implement propagation, nested-option handling and per-value assumption toggling over the interface, and verify the feasibility tests from 3.2 pass on the brute-force backend
- [ ] 4.3 Implement QuickXplain over `check`, and verify the explanation tests from 3.3 pass on the brute-force backend
- [ ] 4.4 Implement threshold classification and soft-rule reporting over `optimise`, and verify the soft-rule tests from 3.4 pass on the brute-force backend
- [ ] 4.5 Implement consequence reporting and consequence chains in explanations, and verify the consequence tests from 3.5 pass on the brute-force backend
- [ ] 4.6 Add "consequence" to docs/concept.md (§2 table of model elements, §4.3 and §4.2 encodings, §8 worked example) and verify the doc names the same element kinds as the specs

## 5. MiniZinc backend

- [ ] 5.1 Write `reference.mzn` and a parity test against `reference.json` on the sampled configurations; verify the parity test fails until the backend exists
- [ ] 5.2 Implement the MiniZinc backend with the `minizinc` package (Node build) and verify the parity test and the full conformance suite pass
- [ ] 5.3 Record in design.md how rule metadata, nested options and consequences are encoded in MiniZinc, and verify the snippets in design.md compile

## 6. UVL + Z3 backend

- [ ] 6.1 Write `reference.uvl` (rule-as-feature) and verify it parses with `uvl-parser`
- [ ] 6.2 Write a parity test for the UVL backend against `reference.json`; verify it fails until the backend exists
- [ ] 6.3 Implement the UVL-to-SMT compiler and the Z3 backend with `z3-solver`, and verify the parity test and the full conformance suite pass, or record which tests cannot pass and why
- [ ] 6.4 Record in design.md the answers found to Q1 (semantics of feature-attached constraints) and Q2 (JS parser levels), and verify each answer cites the test that shows it

## 7. Browser run and measurements

- [ ] 7.1 Run the conformance suite in a browser from a plain static page for both backends, and verify the run reports pass/fail per backend
- [ ] 7.2 Measure full propagation time, bundle size and whether cross-origin isolation is required, for both backends, and verify the numbers are recorded in design.md
- [ ] 7.3 Try both backends once inside a published claude.ai artifact, and verify the outcome (works, fails and why) is recorded in design.md

## 8. Decision and clean-up

- [ ] 8.1 Record the backend decision (Q6), the explanation route (Q7) and browser viability (Q3) in design.md with the evidence from groups 5–7, and verify each decision links to its measurements
- [ ] 8.2 Remove the losing backend, its model file and its dependency, and verify the full suite still passes on the remaining backend and the brute-force backend
- [ ] 8.3 Update docs/concept.md §10 to close Q3, Q6 and Q7 (and Q1, Q2 if answered), and verify no `[U]` claim this change closed is still tagged `[U]`

## Workflow follow-up

- Archive the change with `/openspec-archive-change` after review.
- Start the next change (model file format) from the winning language.
