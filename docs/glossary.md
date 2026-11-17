# Glossary

The project's agreed terms. Documents, specs, code and conversations use them with these meanings. A term is added or changed here before it is used differently. Background terms from the field (SAT, MUS, QuickXplain and similar) are explained in [concept §9](concept.md#9-glossary).

## Domain

| Term | Meaning | Defined in |
| --- | --- | --- |
| **Model** | One file describing a set of related decisions: their options, rules, assumptions, consequences, costs and values | [ADR-0002](decisions/0002-own-model-format-compiled-to-solver-languages.md), `model-format` change |
| **Decision** | A question with mutually exclusive options, of which one is chosen | `model-format` change |
| **Option** | One possible answer to a decision, referenced by its full path (`Sessions.Server`) | `model-format` change |
| **Option family** | A named group of a decision's options (`Hosting.Serverless`); used only to mean "one of the family's options" | `model-format` change |
| **Choice** | A decision with the option picked for it, in a request or a decision record (`Hosting: Serverless.Functions`) | `model-format` change |
| **Hidden choice** | A yes/no choice that is not a decision of its own but has cost, value and rules (`InstantRevocation`) | `model-format` change |
| **Assumption** | An open question whose answer is not yet known, yes/no or numeric (`A1`, `A10`); rules may depend on it | `model-format` change |
| **Rule** | A constraint between options, hidden choices, assumptions and consequences, with a confidence level, a source and a reason | `model-format` change |
| **Fact** | A rule stating something found to be true; it can retire another rule | `model-format` change |
| **Retired rule** | A rule found to be wrong (`retired_by` a fact); it no longer constrains | `model-format` change |
| **Consequence** | A derived outcome (`K2`), true when its condition holds, usable by rules | `model-format` change |
| **Confidence level** | How sure a rule is: verified, likely, plausible, guess or unrated; only the order matters to solving | [ADR-0004](decisions/0004-confidence-as-ordered-levels.md) |
| **Threshold** | The lowest confidence level at which rules are hard; rules below it are soft | [ADR-0004](decisions/0004-confidence-as-ordered-levels.md) |
| **Hard rule / soft rule** | A rule that removes options / a rule that may be broken, and is then blamed | [ADR-0004](decisions/0004-confidence-as-ordered-levels.md) |
| **Cost, value** | Points (non-negative integers, every point equal) or a measured unit, on options, hidden choices and combinations | [ADR-0006](decisions/0006-relative-cost-and-value.md) |
| **Combination term** | Extra cost or value that applies when several options are chosen together | [ADR-0006](decisions/0006-relative-cost-and-value.md) |
| **Configuration** | A set of choices, possibly partial | `solver-core` change |
| **Feasible, infeasible, forced** | An option that some valid completion of the configuration contains / that none does / that every one does | `solver-core` change |
| **Repair** | A smallest set of choices to change so that a wanted option becomes feasible or a configuration consistent | `solver-core` change |
| **Decision record** | An ADR that records a decision's outcome; it is authoritative, and the model holds a synced copy of its status, chosen option and relied-on rules | [ADR-0007](decisions/0007-decisions-are-decision-records.md) |
| **Stale decision** | An accepted decision that relies on a retired rule | `model-format` change |

## Architecture

| Term | Meaning | Defined in |
| --- | --- | --- |
| **Key** | A short, path-like name of a value (`model/load`, `solver/backends`); its namespace belongs to one provider | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Definition** | Produces a key's value from the composed container, lazily | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Extension** | Receives a key's previous value and returns a new one; all extensions of a key apply in order | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Provider** | Definitions and extensions under keys, and nothing else: no setup or run step. The unit of modularity; also called a module | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Required key** | A key in a provider's own namespace that the provider uses but does not define (`model/files`); something else binds it | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Binding** | A definition, usually an alias, that supplies a required key from another key (`model/files` → `node/files`) | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Composition** | An ordered list of providers combined into one provider: later definitions replace earlier ones, extensions accumulate | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Composition entry** | One item in a composition: a provider, which may itself be a composition | `composition` change |
| **Scope** | Placing a composition entry's keys under a prefix chosen by whoever composes it; optional, and strict (no fallback to unprefixed keys) | `composition` change |
| **Container** | The composed result, from which keys are resolved (`get`, `has`); immutable once built | `composition` change |
| **Composition root** | Code that lists providers in order, builds the container and resolves an entry key (`bin/decisions`, a test, an embedding system); it has no special keys | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Application provider** | `decisionsProvider`: the composition of all feature providers; platform-neutral, loadable by another system | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Feature provider** | A provider contributing product behaviour (`cliProvider`, `modelProvider`, `solverProvider`, `clingoProvider`) | `composition` change |
| **Platform provider** | The only provider that uses a platform's APIs (files, streams, process, WebAssembly loading). It defines them under its own keys and binds the required keys of the other providers to them: `nodeProvider`, or `testPlatformProvider` with in-memory files and captured output | [ADR-0005](decisions/0005-application-composed-from-config-based-modules.md) |
| **Test provider** | A provider a test appends last to replace, extend or supply keys | `composition` change |
| **Backend** | A solving tool contributed to `solver/backends`, declaring the query kinds it answers | `solver-core` change |
| **Query kind** | A primitive question a backend answers: `check`, `optimise`, `consequences`, `possible`, `forced` | `solver-core` change |
