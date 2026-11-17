# Tasks

Test tasks come before the implementation tasks they cover. A new test must fail first, for the expected reason, before the implementation that makes it pass.

Tests use `bootstrapProviders` (`composition` design §4): provider tests list the providers under test and a test provider supplying their required keys; command tests list the application and run without and with a prefix.

## 1. Package and providers

- [ ] 1.1 Add `packages/model/` to the workspace with empty `modelProvider` and `recordsProvider` that define the keys of design.md §5, add them to `decisionsProvider` after `cliProvider`, bind `model/files` and `records/files` in `nodeProvider` and `testPlatformProvider`, and verify the full suite passes and `decisions help` still runs

## 2. Bundled models (fixtures first)

- [ ] 2.1 Write `examples/minimal.yaml` per design.md §3.1 and add it to the README's "what this solves" section with the questions it answers (answers are checked by `solver-core`); verify it matches the design table
- [ ] 2.2 Write `examples/reference.yaml` exactly per design.md §3.2; verify every rule, consequence, cost and value matches the design tables
- [ ] 2.3 Write a test that checks `reference.yaml` against the profile targets in the "Reference model profile" scenario; verify it fails until the loader exists

## 3. Schema and loader

- [ ] 3.1 Write one test per scenario in `specs/model/format/spec.md`, using small inline YAML models; verify they fail because the loader does not exist
- [ ] 3.2 Write the JSON Schema and the YAML loader (YAML 1.2 core schema, source positions kept) as `model/schema`, `model/parse` and `model/load`, reading through `model/files`, and verify the tests from 3.1 and 2.3 pass

## 4. Semantic validation and CLI

- [ ] 4.1 Write one test per scenario in `specs/model/validation/spec.md`, including line and column in error messages; verify they fail because the validator does not exist
- [ ] 4.2 Implement the semantic checks (references, duplicates, consequence cycles, integer costs and values, numeric terms, warnings including the sizing guide) as entries of `model/checks` and `model/validate` over them, add a test in which a test provider extends `model/checks` with an extra check that then runs, and verify the tests from 4.1 pass
- [ ] 4.3 Contribute the `validate` command to `cli/commands` and verify `decisions validate` exits 0 on both bundled models and non-zero on an invalid fixture
- [ ] 4.4 Write one test per scenario in `specs/model/decision-records/spec.md`, using MADR and EventCatalog-style record fixtures; verify they fail because sync and check do not exist
- [ ] 4.5 Implement `records/readers`, `records/sync` (frontmatter only, in-place YAML edit, consistency checks) and `records/check` (fingerprint and hand-edit drift), contribute the `sync` and `check` commands to `cli/commands`, add `decisions check` to CI, and verify the tests from 4.4 pass and an unchanged sync leaves the file byte-for-byte identical
- [ ] 4.6 Document the format in `docs/model-format.md` (every element kind with an example, the decision-record convention, and the reserved instance syntax) and verify every example in that document passes the validator in a test

## Workflow follow-up

- Archive the change after review; `solver-core` then builds on the format.
