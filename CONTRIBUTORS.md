# Contributing

## Setup

The stack isn't chosen yet (see [concept §10](docs/concept.md#10-open-questions)), so there is no build or dev environment yet. Planning needs only the OpenSpec CLI (Node.js 22.12+):

```bash
npm install -g @fission-ai/openspec@2.0.0
```

Or, with mise:

```bash
mise use -g npm:@fission-ai/openspec@2.0.0
```

## Workflow

1. Explore an idea with `/openspec-explore` (no files are written).
2. Propose a change with `/openspec-propose <change-name>`. This creates `openspec/changes/<change-name>/` with a proposal, spec deltas, a design and tasks.
3. Review the proposal, then implement it with `/openspec-apply-change`.
4. Archive it with `/openspec-archive-change`, which merges its spec deltas into `openspec/specs/`.

Validate changes and specs with `openspec validate`.

### Test-driven development

Work goes from spec to tests to implementation, in that order:

1. **Spec:** each requirement in a change's spec deltas has scenarios (WHEN/THEN) that are concrete enough to test.
2. **Tests:** every scenario becomes at least one automated test, written and run before the implementation. The new tests must fail at first, for the expected reason.
3. **Implementation:** write the minimum code that makes the tests pass, then refactor with the tests passing.

A change's `tasks.md` lists test tasks before the implementation tasks they cover.

Tests of solving behaviour run against two bundled models: a minimal example, also used in the README, and a reference model whose size and structure are comparable to a real-world specification. Every iteration passes the full suite against both; CI enforces this on every push. A scenario that needs a construct neither bundled model has may also use a small fixture, in addition to the bundled models, never instead.

### Decision records

A change that makes a decision spanning more than itself (a format, a library, a semantics) records it as an ADR in [`docs/decisions/`](docs/decisions/), copying [the template](docs/decisions/adr-template.md) with the next free number, and links it from the change's `design.md`. See [ADR-0001](docs/decisions/0001-record-decisions-with-madr.md).

## Branches

Branch from `0.1.x` and open pull requests against it. `master` receives stable releases only.

---

[README](README.md) · [Agent instructions](AGENTS.md)
