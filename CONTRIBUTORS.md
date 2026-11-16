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

## Branches

Branch from `0.1.x` and open pull requests against it. `master` receives stable releases only.

---

[README](README.md) · [Agent instructions](AGENTS.md)
