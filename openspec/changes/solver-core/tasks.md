# Tasks

Builds on the `composition` change (library, application and platform providers, test harness, Makefile, docker-compose, CI) and the `model-format` change (format, validator, both bundled models). Test tasks come before the implementation tasks they cover; a new test must fail first, for the expected reason. Every task finishes with the full suite passing on both bundled models; scenarios that need constructs the bundled models lack also use small fixtures.

Tests use `bootstrapProviders` (`composition` design §4): provider tests list the providers under test and a test provider supplying their required keys; command tests list the application and run without and with a prefix.

## 1. Engine providers and routing

- [ ] 1.1 Write tests with the composition harness per design.md §1: `solverProvider` defines every `solver/` key in the table; backends contributed by two providers appear in `solver/backends` in provider order; a later definition of `solver/backend-preference` changes routing; an extension wrapping `solver/router` sees every routed call. Verify they fail because `packages/solver/` does not exist
- [ ] 1.2 Add `packages/solver/` with `solverProvider` defining the keys of design.md §1 (empty backends and queries), add it to `decisionsProvider`, bind `solver/load-wasm` in `nodeProvider` and `testPlatformProvider`, and verify the tests from 1.1 that do not need routing pass
- [ ] 1.3 Write one test per scenario in `specs/solving/backends/spec.md` using two stub backends with different declared query kinds; verify they fail because the router does not exist
- [ ] 1.4 Implement the router, fallback rules and query-kind declarations as `solver/router`, and verify the tests from 1.1 and 1.3 pass

## 2. Brute-force oracle

- [ ] 2.1 Write tests for the oracle's table on the minimal example with hand-checked answers (satisfying assignment masks, possible and forced options, consequences, totals), plus a test that one table build for the reference model finishes within 10 s in Node; verify they fail because the oracle does not exist
- [ ] 2.2 Implement the bit-parallel oracle per design.md §8 (assumption masks, per-soft-rule violation masks, numeric sampling at rule boundaries) as a backend declaring every query kind, contributed by `oracleProvider`, and verify the tests from 2.1 pass

## 3. Conformance suite (before any real backend)

- [ ] 3.1 Write one test per scenario in `specs/solving/feasibility/spec.md`, parameterised by backend; verify every test fails with "no handler" rather than a type or import error
- [ ] 3.2 Write one test per scenario in `specs/solving/conflict-explanation/spec.md`, with minimality and unsatisfiability checks on a sample of configurations; verify they fail as in 3.1
- [ ] 3.3 Write one test per scenario in `specs/solving/diagnosis/spec.md`, with subset-minimality and smallest-first checks for every repair; verify they fail as in 3.1
- [ ] 3.4 Write one test per scenario in `specs/solving/soft-rules/spec.md`, with the two named fixtures; verify they fail as in 3.1
- [ ] 3.5 Write one test per scenario in `specs/solving/consequences/spec.md`; verify they fail as in 3.1
- [ ] 3.6 Write one test per scenario in `specs/solving/cost/spec.md`; verify they fail as in 3.1
- [ ] 3.7 Write differential tests comparing feasibility, conditions, forced options, consequences and cost ranges with the oracle on a seeded random sample of configurations; verify they fail as in 3.1
- [ ] 3.8 Add a test that the README's answers for the minimal example match the solver's, and verify it fails as in 3.1

## 4. Query handlers on the oracle backend

- [ ] 4.1 Implement accepted-decision handling, feasibility, families, dependency conditions, configuration-level conditions, forced options and stale or conflicting accepted decisions, with `check` fallbacks; verify the tests from 3.1 and 3.8 pass on the oracle
- [ ] 4.2 Implement QuickXplain with consequence links; verify the tests from 3.2 pass on the oracle
- [ ] 4.3 Implement repairs in smallest-first order; verify the tests from 3.3 pass on the oracle
- [ ] 4.4 Implement threshold classification and level-first soft-rule blame; verify the tests from 3.4 pass on the oracle
- [ ] 4.5 Implement consequence reporting; verify the tests from 3.5 pass on the oracle
- [ ] 4.6 Implement totals, ranges, cheapest and most valuable configurations, the robust variant, the lexicographic Pareto front and value per cost; verify the tests from 3.6 pass on the oracle
- [ ] 4.7 Update docs/concept.md (§2 model elements, §4.4 levels, §5 solving with conditions, repairs and forced options, §8 worked example) to match ADR-0002 to ADR-0007, and verify every element and query kind named in the specs appears there

## 5. clingo backend

- [ ] 5.1 Write compiler tests for every row of design.md §3 against small models; verify they fail because the compiler does not exist
- [ ] 5.2 Implement the clingo compiler for the minimal example and measure one cold `check` and one brave/cautious call in Node and in a browser. Go on if a full propagation of the reference model, estimated from the measured calls per second and the number of calls design.md §6 needs, fits within 2 s; otherwise record the shortfall in design.md and revise the approach (batched calls, fewer conditions computed eagerly) before continuing
- [ ] 5.3 Complete the clingo compiler and backend, contributed by `clingoProvider` (all query kinds, WebAssembly through `solver/load-wasm`), and verify the compiler tests and the conformance suite pass on both bundled models

## 6. MiniZinc backend

- [ ] 6.1 Add native MiniZinc to the development container and the CI image, and verify `minizinc --version` runs in both
- [ ] 6.2 Write compiler tests for every row of design.md §3 against small models, including the level-weighted objective; verify they fail because the compiler does not exist
- [ ] 6.3 Implement the MiniZinc compiler and backend, contributed by `minizincProvider` (`check`, `optimise`, `consequences`), and verify the compiler tests and the conformance suite pass for those kinds on both bundled models

## 7. Browser run and measurements

- [ ] 7.1 Add a CI job that runs the conformance suite in a headless browser from a static page for both backends and fails if the clingo full propagation on the reference model exceeds 2 s; verify it reports pass/fail per backend
- [ ] 7.2 Measure full propagation time and bundle size for both backends, and verify the numbers are recorded in design.md
- [ ] 7.3 Run the clingo backend with the reference model inside a claude.ai artifact (WebAssembly published with the page), and verify the measured full propagation time is recorded in design.md

## 8. Decision record

- [ ] 8.1 Write a new ADR that confirms or supersedes ADR-0003 with the measurements from groups 5–7 (order and per-platform preference), and update docs/concept.md §10 to close Q3, Q6 and Q7; verify no `[U]` claim this change closed is still tagged `[U]`

## Workflow follow-up

- Archive the change after review.
- Candidate later changes, each a provider extending `solver/queries`: goals on consequences ("what must hold for this consequence to stay false?", answered with forced and impossible choices and repairs), what-if, which open question to answer first (value of information), per-instance decisions, EventCatalog generator (decisions as EventCatalog ADRs via `@eventcatalog/sdk` `writeAdr`).
