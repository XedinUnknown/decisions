# Decisions

Decision modelling for business-tech choices that constrain each other. The domain is encoded once as a schema of decisions, options, constraints and unknowns. A constraint solver then propagates feasibility, detects conflicts and explains them. A generated UI renders the model, and an LLM drafts the resulting decision record.

**Status:** concept stage. See [docs/concept.md](docs/concept.md) for the problem, the approach, prior art and the open questions.

## Planning

Work is planned with [OpenSpec](https://github.com/Fission-AI/OpenSpec):

- [`openspec/specs/`](openspec/specs): requirements for behaviour that has shipped.
- [`openspec/changes/`](openspec/changes): proposed and in-progress changes.

## Branches

- `0.1.x`: current development line (default branch). May be unstable.
- `master`: latest stable state.

---

[Contributing](CONTRIBUTORS.md) · [Agent instructions](AGENTS.md)
