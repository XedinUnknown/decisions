# Design

## Context

See proposal.md. Standing decisions: [ADR-0002](../../../docs/decisions/0002-own-model-format-compiled-to-solver-languages.md) (own format), [ADR-0004](../../../docs/decisions/0004-confidence-as-ordered-levels.md) (confidence levels), [ADR-0006](../../../docs/decisions/0006-relative-cost-and-value.md) (cost and value). The real pilot model stays outside this repository; only its structural profile (kept on the internal Confluence page) shapes the reference model.

## Goals / Non-Goals

**Goals:**
- A format an AI can write and a person can review in a pull request.
- Validation that catches drafting errors with precise locations.
- Two bundled models that every later change tests against.

**Non-Goals:**
- Solving or compiling to solver languages.
- A graphical editor.

## Decisions

### 1. Shape of a model file

```yaml
model: web-app
scale: relative            # or: {unit: hours}
decisions:
  Sessions:
    options:
      Server: {cost: 3, value: 5}
      Token:  {cost: 1, value: 3}
  Hosting:
    options:
      Containers: {options: {ManagedCluster: {cost: 8}, PaaS: {cost: 5}}}
      Serverless: {options: {Functions: {cost: 3}, Edge: {cost: 5}}}
hidden: [InstantRevocation]
assumptions:
  A1: {kind: bool, text: "The platform keeps WebSocket connections open for a whole session", closes_by: "Load test"}
  A10: {kind: int, text: "Expected monthly requests"}
consequences:
  K2: {any: [{is: [Auth, External]}, {is: [Search, External]}]}
rules:
  R1:
    if: InstantRevocation
    then: {is: [Sessions, Server]}
    level: verified
    source: OWASP JWT Cheat Sheet
    reason: A signed token stays valid until it expires, so a logout cannot revoke it instantly
  R11: {fact: true, source: "...", reason: "Any CDN works with any host", level: verified}
combinations:
  - when: {all: [{in: [Hosting, Serverless]}, {is: [Realtime, WebSockets]}]}
    cost: 5
```

Option references are `Decision.Option` strings or the `is`/`in` forms; families are referenced with `in`. Ids are stable because explanations and tests cite them.

*Alternatives:* JSON for authoring (noisier for review), TOML (awkward for nested expressions). YAML with a JSON Schema keeps editor support (completion, inline errors) through the schema.

### 2. Validation in two passes

1. JSON Schema (structure, types, enums), with errors mapped back to YAML line and column through the parser's source map.
2. Semantic pass over the parsed model: reference resolution, duplicate ids, consequence cycle detection (depth-first search), scale checks, numeric-term checks, warnings.

Both passes collect all errors before reporting.

### 3. Bundled models

- `examples/minimal.yaml`: Sessions (Server, Token), Hosting (Containers, Serverless), Realtime (WebSockets, Polling); R1 instant revocation needs server-side sessions; R2 serverless with WebSockets needs A1; one hidden choice. Small enough for the README, and it contains a conflict and an assumption-dependent option.
- `examples/reference.yaml`: a generic SaaS web-application model matched to the pilot's structural profile. A test checks it against the profile targets. Its content:

| Id | Options |
| --- | --- |
| Sessions | Server · Token |
| Hosting | Containers {ManagedCluster, PaaS} · Serverless {Functions, Edge} |
| Realtime | WebSockets · SSE · Polling |
| Database | ManagedSQL · ServerlessSQL · DocumentStore |
| SessionStore | Database · InMemory · ExternalKV |
| CDN | HostProvider · Independent (justification "decided by Hosting", made stale by R11) |
| Auth | Own · External |
| Region | Single · Multi |
| Logging | FullBodies · MetadataOnly |
| Search | DatabaseFullText · External |

Hidden choices: `InstantRevocation`, `AuditTrail`. Consequences: K1 personal data at rest, K2 new third-party processor, K3 privacy review widens.

| Id | Rule | Level |
| --- | --- | --- |
| R1 | InstantRevocation ⇒ Sessions = Server | verified |
| R2 | Hosting ∈ Serverless ∧ Realtime = WebSockets ⇒ A1 | verified |
| R3 | Hosting ∈ Serverless ∧ Sessions = Server ⇒ SessionStore ≠ InMemory | verified |
| R4 | SessionStore = InMemory ⇒ Hosting ∈ Containers ∧ A4 | likely |
| R5 | K1 ⇔ Logging = FullBodies ∨ AuditTrail | verified |
| R6 | K2 ⇔ Auth = External ∨ Search = External ∨ SessionStore = ExternalKV | verified |
| R7 | K2 ∧ Region = Single ⇒ A7 | likely |
| R8 | K3 ⇔ K1 ∨ K2 | verified |
| R9 | Region = Multi ⇒ A9 | plausible |
| R10 | Hosting ∈ Serverless ⇒ A10 × unit price ≤ budget | plausible |
| R11 | Background fact: any CDN works with any host (removes CDN's justification) | verified |
| R12 | Hosting = Serverless.Edge ⇒ A5 | unrated |
| R13 | Database = ServerlessSQL ∧ Hosting ∈ Containers ⇒ A2 | guess |

Assumptions (14): A1 long-lived WebSockets on the platform · A2 serverless SQL connection limits suffice · A3 external KV store in region · A4 PaaS sticky sessions · A5 database driver runs at the edge · A6 CDN does not buffer SSE · A7 processors offer hosting in region · A8 identity provider supports instant revocation · A9 database cross-region replication · A10 expected monthly requests (numeric) · A11 search latency target met · A12 log pipeline can redact bodies · A13 CDN passes WebSocket upgrades · A14 team can operate a cluster. Rules for A3, A6, A8, A11–A14 are added while writing the file, so that every assumption is used; Hosting must end up depending on at least 4 (A1, A4, A5, A14), and at least 2 assumptions must affect 2 decisions each.

Costs and values use the Fibonacci scale, chosen so that the cheapest options conflict through at least one hard rule and the cheapest and most valuable configurations differ. At least one combination term (serverless with WebSockets) changes a total.

### 4. Process rule: every iteration passes on the reference model

From this change onwards, CI runs the full suite against both bundled models on every push, so no change can pass on the minimal example alone (recorded in CONTRIBUTORS.md).

## Risks / Trade-offs

- [The format turns out to miss something the solver needs] → `solver-core` may extend it; the schema is versioned by a `format` field from the first release.
- [YAML ambiguities, for example `no` read as false] → The parser runs in YAML 1.2 core schema mode, where `no` is a string.
