# Tasks

Test tasks come before the implementation tasks they cover. A new test must fail first, for the expected reason, before the implementation that makes it pass.

## 1. Project scaffolding

- [ ] 1.1 Create the TypeScript workspace with a `packages/model/` package (`package.json`, `tsconfig.json`, Vitest) and verify `npx vitest run` exits successfully with an empty suite
- [ ] 1.2 Add a `Makefile` with `setup`, `build`, `dev` and `test` targets (no Docker inside it) and verify each target runs
- [ ] 1.3 Add `docker-compose.yml` with a Node service that runs `make test`, plus `.env.example`, and verify `docker compose run --rm dev make test` passes
- [ ] 1.4 Add a GitHub Actions workflow that runs `make test` on pushes and pull requests to `0.1.x`, and verify it passes on a pushed branch
- [ ] 1.5 Update CONTRIBUTORS.md with the new targets and the rule that every iteration passes the full suite against both bundled models, and verify the documented commands run as written

## 2. Bundled models (fixtures first)

- [ ] 2.1 Write `examples/minimal.yaml` per design.md §3 and add it to the README's "what this solves" section with a short walk-through; verify the README renders the example and its expected answers
- [ ] 2.2 Write `examples/reference.yaml` per the `solver-core` design's reference model, with costs and values on the Fibonacci scale and at least one combination term
- [ ] 2.3 Write a test that checks `reference.yaml` against the profile targets in the "Reference model profile" scenario; verify it fails until the loader exists

## 3. Schema and loader

- [ ] 3.1 Write one test per scenario in `specs/model/format/spec.md`, using small inline YAML models; verify they fail because the loader does not exist
- [ ] 3.2 Write the JSON Schema and the YAML loader (YAML 1.2 core schema, source positions kept), and verify the tests from 3.1 and 2.3 pass

## 4. Semantic validation and CLI

- [ ] 4.1 Write one test per scenario in `specs/model/validation/spec.md`, including line and column in error messages; verify they fail because the validator does not exist
- [ ] 4.2 Implement the semantic pass (references, duplicates, consequence cycles, scales, numeric terms, warnings) and verify the tests from 4.1 pass
- [ ] 4.3 Implement the `validate` command and verify it exits 0 on both bundled models and non-zero on an invalid fixture
- [ ] 4.4 Write one test per scenario in `specs/model/decision-records/spec.md`, using MADR and EventCatalog-style record fixtures; verify they fail because records are not loaded
- [ ] 4.5 Implement record loading (frontmatter only) and the record consistency checks, and verify the tests from 4.4 pass
- [ ] 4.6 Document the format in `docs/model-format.md` (every element kind with an example, the decision-record convention, and the reserved instance syntax) and verify every example in that document passes the validator in a test

## Workflow follow-up

- Archive the change after review; `solver-core` then builds on the format.
