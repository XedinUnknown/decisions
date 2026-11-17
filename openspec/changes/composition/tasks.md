# Tasks

Test tasks come before the implementation tasks they cover. A new test must fail first, for the expected reason, before the implementation that makes it pass.

## 1. Project scaffolding

- [ ] 1.1 Turn the root into a pnpm workspace with an empty root package `decisions` in `src/` and empty `packages/di/`, `packages/cli/` and `packages/node/` packages (`package.json`, `tsconfig.json`, Vitest), and verify `pnpm exec vitest run` exits successfully with an empty suite
- [ ] 1.2 Add `build`, `dev` and `test` targets to the `Makefile` and extend `setup` to install the workspace dependencies (no Docker inside it), and verify each target runs
- [ ] 1.3 Add `docker-compose.yml` with a Node service that runs `make` targets, plus `.env.example`, and verify `docker compose run --rm dev make test` passes
- [ ] 1.4 Add a GitHub Actions workflow that runs `make setup` and `make test` on pushes and pull requests to `0.1.x`, and verify it passes on a pushed branch
- [ ] 1.5 Update CONTRIBUTORS.md with the new targets, and verify the documented commands run as written

## 2. Composition library

- [ ] 2.1 Write one test per scenario in `specs/app/composition/spec.md`, plus tests that the same provider under two names contributes twice and that helpers report their dependencies; verify they fail because the library does not exist
- [ ] 2.2 Implement `packages/di/` per design.md §1 (contract, `composeProviders`, `scope`, `bootstrap`, helpers, errors) and verify the tests from 2.1 pass
- [ ] 2.3 Write tests for `bootstrapProviders` in `packages/di/testing` per design.md §4 (a test provider last replaces, extends and supplies keys; with a prefix, the list is scoped as one entry and read through a strict view); verify they fail, then implement it and verify they pass
- [ ] 2.4 Document the contract, the key conventions of design.md §2 and the testing levels of design.md §4 in `packages/di/README.md`, and verify every code example in it runs in a test

## 3. Command line, platform and application

- [ ] 3.1 Write one test per scenario in `specs/app/cli/spec.md` with `bootstrapProviders`, listing `cliProvider`, test-only command providers and a test provider supplying `cli/args`, `cli/output` and `cli/errors`; verify they fail because `cliProvider` does not exist
- [ ] 3.2 Implement `cliProvider`, `testPlatformProvider` and `runCliForTest` per design.md §3–§4, and verify the tests from 3.1 pass
- [ ] 3.3 Write tests for `nodeProvider` (each `node/` key against a temporary directory and captured streams; `cli/args`, `cli/output` and `cli/errors` resolve to the Node values); verify they fail, then implement it and verify they pass
- [ ] 3.4 Add `decisionsProvider` in `src/` and `bin/decisions` per design.md §3. Write application tests per design.md §4 that run without and with a generated prefix (help listing; every key declared as a dependency is supplied), the embedding test, and a test that runs the executable with no arguments and gets the help listing; verify each fails first, then passes, and `pnpm exec decisions` prints the listing
- [ ] 3.5 Add the lint rule that forbids `node:` imports outside `packages/node/` and `bin/`, run it in `make test`, and verify it fails on a deliberately bad fixture

## Workflow follow-up

- Archive the change after review; `model-format` then contributes its providers to `decisionsProvider` and its bindings to `nodeProvider`.
