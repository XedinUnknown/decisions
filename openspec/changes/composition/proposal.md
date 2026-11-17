# Proposal

## Why

The application is a composition of config-based modules, and is itself a provider that other systems can load ([ADR-0005](../../../docs/decisions/0005-application-composed-from-config-based-modules.md)). Every later change (model format, decision records, solving, UI) contributes its parts through that composition, so the composition library, the command-line provider, the Node platform provider and the project scaffolding have to exist first.

## What Changes

- Scaffold the repository for code: a pnpm workspace, TypeScript, Vitest, `make build`, `make dev` and `make test`, `docker-compose.yml`, `.env.example` and a CI workflow.
- Add a composition library in `packages/di/` that implements the intended contract of `@uny/di` in this repository's own code: providers of keyed definitions and extensions, ordered composition (later definitions replace, extensions all apply), composed providers that compose again, optional scoping of a composition entry under a key prefix, lazy and cached resolution, extra value sources ahead of providers, and errors that name the missing key or the dependency cycle.
- Add a reusable command-line provider in `packages/cli/`: a generic command surface that it and other providers add commands to, with `help` as its only command. It declares the arguments and output it needs as its own keys.
- Add a Node platform provider in `packages/node/`, the only code that uses Node APIs: it defines arguments, file access, output and WebAssembly loading, and binds the keys that other providers require to them.
- Add the application provider in `src/`, which composes the feature providers and is platform-neutral, and the executable `bin/decisions`, which only composes the application provider with the Node provider and runs the command line.
- Add a test harness that composes chosen providers with test providers appended last.

Out of scope: any model, record or solving behaviour (later changes contribute it), a browser platform provider (comes with the configurator UI), composition provenance and logs.

## Capabilities

### New Capabilities

- `app/composition`: How providers compose: replacement, extension, order, nesting, scoping, laziness, caching, value sources and resolution errors.
- `app/cli`: The command-line provider: running commands contributed through composition, and reporting unknown commands and failed resolution.

### Modified Capabilities

None.

## Impact

- **Concept sections:** §2 (the pipeline whose stages become providers), §6 (the UI to come, with its own platform provider).
- **Open questions:** none closed; Q3 and Q9 later become platform or backend providers rather than engine changes.
- **Unverified claims relied on:** none.
- **New code:** `packages/di/`, `packages/cli/`, `packages/node/`, `src/`, `bin/decisions`.
- **Dependencies:** TypeScript, Vitest (development only).
- **Ordering:** comes first; `model-format` and `solver-core` contribute through it.
