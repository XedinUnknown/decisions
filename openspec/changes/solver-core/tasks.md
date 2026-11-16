# Tasks

Builds on the `model-format` change (format, validator, both bundled models, Makefile, docker-compose, CI). Test tasks come before the implementation tasks they cover; a new test must fail first, for the expected reason. Every task finishes with the full suite passing on both bundled models.

## 1. Module composition

- [ ] 1.1 Write composition tests per design.md §1: definition, override and extension order; contributions to `solver/backends` in deterministic order; routing by `solver/backend-preference`; a missing-key error. Verify they fail because nothing exists
- [ ] 1.2 Implement the minimal registry and verify the tests from 1.1 pass
- [ ] 1.3 Write one test per scenario in `specs/solving/backends/spec.md` using two stub backends with different declared query kinds; verify they fail because the router does not exist
- [ ] 1.4 Implement the router and query-kind declarations, and verify the tests from 1.3 pass

## 2. Brute-force oracle

- [ ] 2.1 Write tests for the oracle on the minimal example with hand-checked answers (possible, forced, consequences, totals, one conflict, one repair); verify they fail because the oracle does not exist
- [ ] 2.2 Implement the bitset oracle per design.md §8 as a backend module declaring every query kind, and verify the tests from 2.1 pass
- [ ] 2.3 Add a test that one full table build for the reference model finishes within 10 s in Node, and verify it passes

## 3. Conformance suite (before any real backend)

- [ ] 3.1 Write one test per scenario in `specs/solving/feasibility/spec.md`, parameterised by backend; verify every test fails with "no handler" rather than a type or import error
- [ ] 3.2 Write one test per scenario in `specs/solving/conflict-explanation/spec.md`, with minimality and unsatisfiability checks on a sample of configurations; verify they fail as in 3.1
- [ ] 3.3 Write one test per scenario in `specs/solving/diagnosis/spec.md`, with minimality checks for every repair; verify they fail as in 3.1
- [ ] 3.4 Write one test per scenario in `specs/solving/soft-rules/spec.md`; verify they fail as in 3.1
- [ ] 3.5 Write one test per scenario in `specs/solving/consequences/spec.md`; verify they fail as in 3.1
- [ ] 3.6 Write one test per scenario in `specs/solving/cost/spec.md`; verify they fail as in 3.1
- [ ] 3.7 Write differential tests comparing possible and forced options, consequences and cost ranges with the oracle on a seeded random sample of configurations; verify they fail as in 3.1

## 4. Query handlers on the oracle backend

- [ ] 4.1 Implement feasibility and forced options with `check` fallbacks, nested options and per-value assumption toggling; verify the tests from 3.1 pass on the oracle
- [ ] 4.2 Implement QuickXplain with conjunction splitting; verify the tests from 3.2 pass on the oracle
- [ ] 4.3 Implement FastDiag repairs, smallest first; verify the tests from 3.3 pass on the oracle
- [ ] 4.4 Implement threshold classification and level-first soft-rule reporting; verify the tests from 3.4 pass on the oracle
- [ ] 4.5 Implement consequence reporting and consequence chains in explanations; verify the tests from 3.5 pass on the oracle
- [ ] 4.6 Implement totals, ranges, cheapest and most valuable configurations, the Pareto front and value per cost; verify the tests from 3.6 pass on the oracle
- [ ] 4.7 Update docs/concept.md (§2 model elements, §4.4 levels, §5 solving with repairs and forced options, §8 worked example) to match ADR-0002 to ADR-0006, and verify every element and query kind named in the specs appears there

## 5. clingo backend

- [ ] 5.1 Write the clingo compiler for the minimal example and measure one cold `check` and one brave/cautious call in Node and in a browser; record calls per second in design.md and decide whether per-call re-grounding fits the 2 s target before continuing
- [ ] 5.2 Write compiler tests for every row of design.md §3 against small models; verify they fail until the compiler is complete
- [ ] 5.3 Complete the clingo compiler and backend module (all query kinds), and verify the compiler tests and the conformance suite pass on both bundled models

## 6. MiniZinc backend

- [ ] 6.1 Write compiler tests for every row of design.md §3 against small models, including the level-weighted objective; verify they fail until the compiler exists
- [ ] 6.2 Implement the MiniZinc compiler and backend module (`check`, `optimise`, `consequences`), and verify the compiler tests and the conformance suite pass for those kinds on both bundled models

## 7. Browser run and measurements

- [ ] 7.1 Run the conformance suite in a browser from a static page for both backends, and verify the run reports pass/fail per backend
- [ ] 7.2 Measure full propagation time and bundle size for both backends, and verify the numbers are recorded in design.md
- [ ] 7.3 Run the clingo backend with the reference model inside a claude.ai artifact (WebAssembly published with the page), measure full propagation time there, and record the result in ADR-0003

## 8. Decision record

- [ ] 8.1 Update ADR-0003 with the measurements from groups 5–7 (confirm or revise the order and the per-host preference), and update docs/concept.md §10 to close Q3, Q6 and Q7; verify no `[U]` claim this change closed is still tagged `[U]`

## Workflow follow-up

- Archive the change after review.
- Candidate later changes as query modules: what-if, which open question to answer first (value of information), EventCatalog generator.
