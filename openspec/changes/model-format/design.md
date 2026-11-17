# Design

## Context

See proposal.md. Standing decisions: [ADR-0002](../../../docs/decisions/0002-own-model-format-compiled-to-solver-languages.md) (own format), [ADR-0004](../../../docs/decisions/0004-confidence-as-ordered-levels.md) (confidence levels), [ADR-0005](../../../docs/decisions/0005-application-composed-from-config-based-modules.md) (composition), [ADR-0006](../../../docs/decisions/0006-relative-cost-and-value.md) (cost and value), [ADR-0007](../../../docs/decisions/0007-decisions-are-decision-records.md) (decision records). The reference model's shape follows the structural profile of a real specification; that specification and its model are kept outside this repository.

## Goals / Non-Goals

**Goals:**
- A format an AI can write and a person can review in a pull request.
- Validation that catches drafting errors with precise locations.
- Two bundled models, specified completely here, that every later change tests against.

**Non-Goals:**
- Solving or compiling to solver languages.
- A graphical editor.

## Decisions

### 1. Shape of a model file

An excerpt (other decisions omitted; the documented examples in `docs/model-format.md` must be complete and valid):

```yaml
format: 1
model: web-app
scale: relative            # or: {unit: hours}
guide: fibonacci           # optional: warn about off-guide sizes
constants:
  PricePerThousand: 2
  Budget: 1000
decisions:
  Sessions:
    summary: Where session state lives
    options:
      Server: {cost: 3, value: 5}
      Token:  {cost: 1, value: 3}
  Hosting:
    options:
      Containers: {options: {ManagedCluster: {cost: 8, value: 8}, PaaS: {cost: 3, value: 5}}}
      Serverless: {options: {Functions: {cost: 2, value: 5}, Edge: {cost: 3, value: 8}}}
hidden:
  InstantRevocation: {cost: 2, value: 5}
assumptions:
  A1:  {kind: bool, text: "The platform keeps WebSocket connections open for a whole session", closes_by: "Load test"}
  A10: {kind: int, min: 0, max: 2000, text: "Expected monthly requests, in thousands"}
consequences:
  K2: {any: [Auth.External, Search.External, SessionStore.ExternalKV]}
rules:
  R1:
    if: InstantRevocation
    then: Sessions.Server
    level: verified
    source: OWASP JWT Cheat Sheet
    reason: A signed token stays valid until it expires, so a logout cannot revoke it instantly
  R10:
    if: {in: Hosting.Serverless}
    then: {le: [{times: [A10, PricePerThousand]}, Budget]}
    level: plausible
    source: Platform pricing page
    reason: Per-request billing must stay within the monthly budget
  R14: {then: CDN.HostProvider, level: verified, retired_by: R11, source: "...", reason: "..."}
  R11: {fact: true, level: verified, source: "...", reason: "Any CDN works with any host"}
combinations:
  - when: {all: [{in: Hosting.Serverless}, Database.ManagedSQL]}
    cost: 3
```

- **Paths.** An option is always referenced by its full path, `Decision.Option` or `Decision.Family.Option`. A family path (`Hosting.Serverless`) is used only inside `in:`, meaning "one of the family's options". In requests and records, a choice names a decision and an option path within it (`Hosting: Serverless.Functions`).
- **Atoms.** A bare option path, hidden choice, yes/no assumption or consequence id is an expression that is true or false.
- **Numeric terms.** Integers, constants, numeric assumptions, `plus` and `times` (one factor must be a constant), compared with `lt`, `le`, `eq`, `ge`, `gt`, `ne`.
- **Namespace.** Decisions, hidden choices, assumptions, consequences, rules and constants share one namespace; option ids are unique within their decision or family.

*Alternatives:* JSON for authoring (noisier for review), TOML (awkward for nested expressions). YAML with a JSON Schema keeps editor support (completion, inline errors) through the schema.

### 1a. Linked decision records

```yaml
decisions:
  Sessions:
    summary: Where session state lives
    record: ../docs/decisions/0012-session-state.md
    synced:                    # written only by `sync`
      status: accepted
      chosen: Server
      relies-on: [R1]
      fingerprint: sha256:3f1c...   # of the record's frontmatter
    options: {Server: {cost: 3, value: 5}, Token: {cost: 1, value: 3}}
```

```markdown
---
status: accepted
date: 2026-11-20
x-decision:
  decision: Sessions
  chosen: Server
  relies-on: [R1]
---
# Keep session state on the server
...
```

The `x-decision` field fits both MADR (frontmatter is optional metadata) and EventCatalog ADRs (custom `x-` properties are allowed). Only `sync` and `check` read records, and only their frontmatter; loading a model never does. `sync` edits the parsed YAML document in place, so comments and ordering survive. A later adapter can sync from EventCatalog through its SDK (`getAdr`) instead of files.

### 1b. Retired rules

A rule that turned out to be wrong is not deleted while decisions rely on it: it gets `retired_by: <fact id>` and stops constraining. A decision whose `relies-on` names a retired rule is stale; the solver reports it (solver-core). This replaces the earlier idea of a separate "justification" element: the reliance is the `relies-on` list, the justification is the rule.

### 1c. Reserved instance qualifiers

`Name[instance]` is reserved for a later change in which a decision template applies once per unit (for example per service). The validator recognises the form and rejects it with "instance qualifiers are reserved".

### 2. Validation in two passes

1. JSON Schema (structure, types, enums), with errors mapped back to YAML line and column through the parser's source map.
2. Semantic pass: reference resolution, namespace and duplicate checks, consequence cycle detection (depth-first search), integer checks on costs, values and bounds, numeric-term checks (a `times` needs a constant factor), retired-by references, warnings (unused assumptions, unrated rules, off-guide sizes).

Both passes collect all errors before reporting.

### 3. Bundled models

Both are specified completely here; every scenario in later changes that names them depends on these exact contents.

#### 3.1 Minimal example (`examples/minimal.yaml`)

| Decision | Options (cost/value) |
| --- | --- |
| Sessions | Server (3/5) · Token (1/3) |
| Hosting | Containers (5/5) · Serverless (2/5) |
| Realtime | WebSockets (1/8) · Polling (2/2) |

Hidden choice: InstantRevocation (2/5). Assumption: A1 "the platform keeps WebSocket connections open for a whole session".

| Rule | Expression | Level |
| --- | --- | --- |
| R1 | InstantRevocation ⇒ Sessions.Server | verified |
| R2 | Hosting.Serverless ∧ Realtime.WebSockets ⇒ A1 | verified |

Questions it answers in the README: with Sessions = Token, instant revocation is impossible (R1); with Serverless and WebSockets, the configuration depends on A1; the cheapest configuration (Token, Serverless, WebSockets: 4 points) relies on A1.

#### 3.2 Reference model (`examples/reference.yaml`)

A generic SaaS web application matched to the profile of a real specification.

| Decision | Options (cost/value) |
| --- | --- |
| Sessions | Server (3/5) · Token (1/3) |
| Hosting | Containers { ManagedCluster (8/8) · PaaS (3/5) } · Serverless { Functions (2/5) · Edge (3/8) } |
| Realtime | WebSockets (1/8) · SSE (2/5) · Polling (2/2) |
| Database | ManagedSQL (3/5) · ServerlessSQL (1/3) · DocumentStore (2/3) |
| SessionStore | Database (1/2) · InMemory (2/3) · ExternalKV (2/5) |
| CDN | HostProvider (1/2) · Independent (3/5); declared `status: accepted`, `chosen: HostProvider`, `relies-on: [R14]` |
| Auth | Own (5/3) · External (2/5) |
| Region | Single (1/2) · Multi (8/8) |
| Logging | FullBodies (1/5) · MetadataOnly (2/3) |
| Search | DatabaseFullText (1/2) · External (3/8) |

Hidden choices: InstantRevocation (2/5), AuditTrail (3/5). Constants: PricePerThousand = 2, Budget = 1000. Combination term: Hosting.Serverless ∧ Database.ManagedSQL costs 3 more (connection pooling).

Consequences (definitions, not rules):

| Id | Meaning | Definition |
| --- | --- | --- |
| K1 | Personal data at rest | Logging.FullBodies ∨ AuditTrail |
| K2 | New third-party processor | Auth.External ∨ Search.External ∨ SessionStore.ExternalKV |
| K3 | Privacy review widens | K1 ∨ K2 |
| K4 | Cross-border transfer | K2 ∧ Region.Multi |
| K5 | Legal sign-off needed | K3 ∧ K4 |

Rules:

| Id | Expression | Level |
| --- | --- | --- |
| R1 | InstantRevocation ⇒ Sessions.Server | verified |
| R2 | Hosting.Serverless ∧ Realtime.WebSockets ⇒ A1 | verified |
| R3 | Hosting.Serverless ∧ Sessions.Server ⇒ ¬SessionStore.InMemory | verified |
| R4 | SessionStore.InMemory ⇒ Hosting.Containers ∧ A4 | likely |
| R7 | K2 ∧ Region.Single ⇒ A7 | likely |
| R9 | Region.Multi ⇒ A9 | plausible |
| R10 | Hosting.Serverless ⇒ A10 × PricePerThousand ≤ Budget | plausible |
| R11 | Fact: any CDN works with any host | verified |
| R12 | Hosting.Serverless.Edge ⇒ A5 | verified |
| R13 | Database.ServerlessSQL ∧ Hosting.Containers ⇒ A2 | guess |
| R14 | CDN.HostProvider (always), retired by R11 | verified |
| R15 | SessionStore.ExternalKV ⇒ A3 | likely |
| R16 | Realtime.SSE ⇒ A6 | plausible |
| R17 | InstantRevocation ∧ Auth.External ⇒ A8 | unrated |
| R18 | Search.External ⇒ A11 | likely |
| R19 | Logging.FullBodies ⇒ A12 | plausible |
| R20 | Realtime.WebSockets ∧ CDN.HostProvider ⇒ A13 | likely |
| R21 | Hosting.Containers.ManagedCluster ⇒ A14 | guess |

Assumptions: A1 long-lived WebSockets on the platform · A2 serverless SQL connection limits suffice · A3 external KV store available in region · A4 PaaS sticky sessions · A5 database driver runs at the edge · A6 CDN does not buffer SSE · A7 processors offer hosting in region · A8 identity provider supports instant revocation · A9 database cross-region replication · A10 expected monthly requests in thousands (numeric, 0–2000) · A11 search latency target met · A12 log pipeline can redact bodies · A13 CDN passes WebSocket upgrades · A14 team can operate a cluster.

How it meets the profile: 10 decisions, one with option families; 16 constraining rules at every level; 14 assumptions, each used; Hosting depends on A1, A2, A4, A5, A10 and A14; A1, A2, A8 and A13 each affect two decisions or choices; the chain Auth.External → K2 → K4 → K5 has four steps, and K3 and K4 converge in K5; R10 is numeric; R11 retires R14, on which the accepted CDN decision relies; the cheapest configuration (Token, Serverless.Functions, WebSockets, ServerlessSQL, SessionStore.Database, HostProvider, External auth, Single region, FullBodies, DatabaseFullText: 12 points) relies on A1.

### 4. Process rule: every iteration passes on both bundled models

From this change onwards, CI runs the full suite against both bundled models on every push. Scenarios that need a construct neither bundled model has (for example three `plausible` rules competing with one `likely` rule) use small fixtures in addition, never instead.

### 5. Providers and keys

Everything in this change is contributed through composition (`composition` change, design §2). `packages/model/` exports two providers, added to `decisionsProvider` after `cliProvider`:

| Key | Value | Contributed by |
| --- | --- | --- |
| `model/schema` | the JSON Schema | `modelProvider` |
| `model/parse` | YAML text → model with source positions | `modelProvider` |
| `model/files` | reads a file by path; required, not defined | bound by the platform provider |
| `model/load` | path → model, reading through `model/files` | `modelProvider` |
| `model/checks` | list of semantic checks, each model → errors and warnings | `modelProvider` defines the checks of §2; any provider may extend the list |
| `model/validate` | model → all errors and warnings (schema, then every check in `model/checks`) | `modelProvider` |
| `records/files` | reads and writes record files; required, not defined | bound by the platform provider |
| `records/readers` | map from record style (`madr`, `eventcatalog`) to a frontmatter reader | `recordsProvider`; extended for new styles |
| `records/sync`, `records/check` | the operations of the `model/decision-records` spec | `recordsProvider` |
| `cli/commands` | extended with `validate`, `sync` and `check` | `modelProvider`, `recordsProvider` |

Semantic checks are a list rather than one function so that later changes (for example `solver-core`, or a team's own conventions) add checks by extending `model/checks` instead of editing the validator. No code in `packages/model/` imports `node:` modules: file access comes from the required keys, which `nodeProvider` binds to `node/files` with aliases, and output goes through the commands' `cli/output`.

*Alternative:* one provider for the whole package. Two keep record handling optional: a system that loads the model without decision records leaves `recordsProvider` out.

## Risks / Trade-offs

- [The format turns out to miss something the solver needs] → `solver-core` may extend it through a modified `model/format` capability; the `format` field versions the file.
- [YAML ambiguities, for example `no` read as false] → The parser runs in YAML 1.2 core schema mode, where `no` is a string.
