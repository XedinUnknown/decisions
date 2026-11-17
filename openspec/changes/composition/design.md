# Design

## Context

See proposal.md. Standing decision: [ADR-0005](../../../docs/decisions/0005-application-composed-from-config-based-modules.md) (the application is composed from config-based modules and is itself a provider). The contract comes from `@uny/di` in [XedinUnknown/uny-core](https://github.com/XedinUnknown/uny-core/tree/0.1.x/packages/di). That package's README states the intended contract; its shipped code is a prototype that still differs from it (`resolve()` instead of `get()`, an optional `keys()`, provenance always computed and served as `app/provenance`). This design follows the README. `@uny/di` is not on npm and its repository has no license, so the code is written here. Development is test-first ([CONTRIBUTORS.md](../../../CONTRIBUTORS.md)).

## Goals / Non-Goals

**Goals:**
- The smallest composition library that the article's primitives need, with semantics identical to `@uny/di`'s intended contract, plus scoping so that another system can load the application under a prefix.
- An application provider that later changes only add feature providers to, and a composition root that never changes.

**Non-Goals:**
- Composition provenance, composition logs and `inspect`; `withDependencies()`. Each can be added as a provider or a wrapper when needed, without changing the contract.
- A browser platform provider.

## Decisions

### 1. Contract

```ts
type Definition<T> = (c: Container) => T;
type Extension<T> = (previous: T | undefined, c: Container) => T;
interface Provider { definitions?: Record<string, Definition<unknown>>; extensions?: Record<string, Extension<unknown>> }
interface Container { get<T>(key: string): T; has(key: string): boolean }
```

- `composeProviders(Map<name, Provider>): Provider` keeps the last definition per key and one extension chain per key in map order; it invokes nothing. Entries are contributions: the same provider under two names contributes twice. The result is an ordinary provider and composes again.
- `scope(prefix, provider): Provider` is an optional wrapper that a loading system applies to an entry of its composition; nothing is scoped by default. It puts every key the entry defines or extends under `prefix/`, and gives its definitions and extensions a container in which `k` means `prefix/k`, with no fallback to the unprefixed key. The entry may itself be a composition: references between its providers stay consistent because they move together, and keys it requires become `prefix/…`, which the loading system binds there. A provider that refers to other modules' keys is therefore scoped in the same entry as those modules, or addressed by its prefixed keys from outside. The wrapper returns an ordinary provider, so the contract does not change; the wrapped providers are unchanged and unaware of the prefix.
- `bootstrap(Map<name, Provider>, sources: Container[] = []): Container` composes, then wires: a delegating container that evaluates the winning definition and the extension chain, passing the final container; a cycle detector; a composite that consults `sources` first; a cache; and a proxy that closes the loop. Nothing resolves eagerly.
- Helpers `factory(keys, fn)`, `construct(Class, keys)`, `value(v)`, `alias(key)` and `extend(keys, fn)` return callables with `getDependencies()`. Raw functions stay valid, with unknown dependencies.
- Errors: `MissingKeyError` (key and the keys that providers define), `CircularDependencyError` (the chain, printed `a → b → c → a`).
- `Container` has no `keys()`: value sources may not be enumerable. Listing what providers define is done on the provider map, not on the container.

*Alternatives:* depend on `@uny/di` (not published, not licensed); use a framework container such as InversifyJS or Awilix (decorators, auto-registration and lifecycles, which ADR-0005 rules out); prefix keys inside every provider (longer keys everywhere, and the prefix would be the provider's choice instead of the loading system's).

### 2. Keys

Keys are short and path-like, `<namespace>/<name>`. Each namespace belongs to one provider, which defines its keys; other providers may extend them but do not redefine them. What a provider needs from outside is a key in its own namespace, which it does not define; the platform provider (`nodeProvider`, or `testPlatformProvider` in tests) binds it.

| Namespace | Owner | Defines | Requires |
| --- | --- | --- | --- |
| `cli/` | `packages/cli` | `cli/commands` (map from name to command), `cli/main` | `cli/args`, `cli/output`, `cli/errors` |
| `node/` | `packages/node` | `node/args`, `node/files`, `node/stdout`, `node/stderr`, `node/load-wasm` | |
| `model/`, `records/` | `model-format` | `model/load`, `model/validate`, `records/sync`, … | `model/files`, `records/files` |
| `solver/` | `solver-core` | `solver/backends`, `solver/queries`, `solver/router`, … | `solver/load-wasm` |

A command is `{ summary: string; run(args: string[]): Promise<number> }`, returning the exit status. Output is `{ write(text: string): void }`. Collections are list or map keys defined empty by their owner and extended by contributors, as in the article's list services.

### 3. Providers and the composition root

- `packages/di/`: the library; no providers.
- `packages/cli/`: exports `cliProvider`. It defines `cli/commands` with `help`, and `cli/main`, which reads `cli/args`, dispatches to a command and returns its exit status, writing to `cli/output` and `cli/errors`. It is reusable by any application that composes it.
- `packages/node/`: exports `nodeProvider`. It defines the `node/` keys from `process.argv`, the working directory, `node:fs`, the standard streams and WebAssembly loading from disk, and binds required keys to them with aliases: `cli/args`, `cli/output` and `cli/errors` in this change; later changes add their own bindings (`model/files`, `records/files`, `solver/load-wasm`) to it.
- `src/`: the root package `decisions` exports `decisionsProvider`, the composition of the feature providers in order: `cliProvider` now, then the providers later changes add. It contains no platform code, so a browser root or another system loads it unchanged.
- `bin/decisions`: composes `decisionsProvider` then `nodeProvider`, resolves `cli/main`, runs it and exits with its status. It never changes when features are added.
- Feature code never imports `node:` modules. A lint rule enforces it outside `packages/node/` and `bin/`.

### 4. Testing

Follows the existing practice in [wp-oop/plugin-boilerplate](https://github.com/wp-oop/plugin-boilerplate/tree/HEAD/tests/phpunit) (bootstrap the providers under test, with test definitions and extensions last), in `@uny/di` (one test per composition primitive; the production composition with a final test provider) and in [Dhii/containers](https://github.com/Dhii/containers/tree/HEAD/tests/functional) (strict prefixing views). Tests import other packages through their package exports, never through relative paths into their sources.

- **One harness:** `bootstrapProviders(providers, { prefix? })` in `packages/di/testing`. A test lists the providers it needs and appends its own test provider last, which replaces, extends or supplies any key, including the keys the providers under test require. There is no separate overrides argument: a test provider at the end of the list is the override.
- **What a test lists** depends on what it tests:
  - a provider: that provider, any provider whose keys it uses on purpose (as a debug provider does), and a test provider that supplies its required keys;
  - the application: `decisionsProvider`, `testPlatformProvider(files)` (in-memory files, captured output) and a test provider; the same list as `bin/decisions`, with the in-memory platform instead of `nodeProvider`;
  - the Node bindings: `nodeProvider` against a temporary directory and captured streams.
- **Prefix mode.** With `prefix`, the harness composes the whole list as one entry under `scope(prefix, …)` and returns a strict view in which `k` means `prefix/k`, as Dhii's `DeprefixingContainer` in strict mode does, so assertions do not change. Application suites run once without a prefix and once with a prefix generated per run; this covers every later change's commands too.
- **Embedding test.** One test composes a foreign provider that defines the same short keys the application uses (`cli/commands`, `cli/output`, `model/files`) with values that fail the test if reached, then `scope(prefix, decisionsProvider)`, then the platform and aliases from `prefix/cli/args` and the rest, outside the scope, as a foreign system would.
- `runCliForTest(container, argv)` in `packages/cli/testing` resolves `cli/main` and returns the exit status and the captured output and errors.

### 5. Package layout and tooling

A pnpm workspace with the root package and `packages/*`. Each package has its own `package.json`, `tsconfig.json` and Vitest tests; the root runs them all. `make build` compiles with `tsc -b`, `make test` runs Vitest, `make dev` runs Vitest in watch mode. `docker-compose.yml` has one Node service running `make` targets; CI runs `make setup` and `make test`.

## Risks / Trade-offs

- [Contract drift from `@uny/di`] → The spec scenarios are taken from `@uny/di`'s semantics; when `@uny/di` is published, replacing `packages/di/` with it must keep this change's tests passing. `scope` is an addition on top of the contract, built from it, and can move into `@uny/di` or stay here.
- [Typos in keys found only at resolution] → Tests resolve every entry key (`cli/main` and each command) in the full composition, with the Node provider and with the test platform provider.
- [Unbound required keys found only at resolution] → A test lists every key that the providers' helpers declare as a dependency and checks that the full composition supplies it.
- [Indirection makes it hard to see which contribution won] → The order lives in `decisionsProvider`; provenance can be added as an opt-in wrapper when needed.
