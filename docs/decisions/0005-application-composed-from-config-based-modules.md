---
status: accepted
date: 2026-11-17
---

# The application is composed from config-based modules

## Context and Problem Statement

The product grows by stages and by tools: a model format and its checks, decision records, several solving backends, query kinds, a command line, later a configurator UI, export, a write-up and EventCatalog sync. It runs on more than one platform (Node on the command line, a browser page, a claude.ai artifact), and parts of it may be loaded into other systems. How is the application put together so that any part can be added, replaced or wrapped without editing the others, so that platform-specific code stays out of the reusable parts, and so that the application itself can be loaded by another system?

## Decision Drivers

* Any behaviour can be added, replaced or decorated from outside, including by tests and diagnostics.
* One place decides what a running program consists of and in what order.
* Reusable code does not call platform APIs (files, process, WebAssembly loading) directly.
* The application can be embedded, whole or in parts, into another system that composes the same way.
* Resolution is predictable and explainable: which contribution won, which wrapped it.
* Tests compose exactly the parts they need.

## Considered Options

* Config-based modularity: the application is a composition of providers of keyed definitions and extensions
* Modularity for solving backends only, with the rest wired directly
* A plugin registry that parts call into at start-up
* A framework DI container with auto-discovery and provider lifecycles

## Decision Outcome

Chosen option: "Config-based modularity", as described in [Cross-Platform Modularity in PHP](https://dev.to/xedinunknown/cross-platform-modularity-in-php-30bo), because every behaviour becomes replaceable and extensible through two primitives, whoever loads the providers keeps control of composition, and reusable code stays free of platform APIs.

* **Everything is a value under a key.** Loaders, validators, commands, query handlers, routers, compilers, backends, renderers and settings are definitions under short, path-like keys (`model/load`, `solver/backends`, `cli/commands`). The keys and the types of their values are the application's architecture.
* **A module is its provider.** A provider is configuration only: definitions and extensions keyed by string. It has no setup, start or run step. A provider is a packaging unit, not a unit of behaviour: one provider may contribute several backends, or a backend together with its compiler. What matters is that every part is contributed through composition.
* **Two operations.** A later definition for a key replaces an earlier one. Extensions to a key all apply, in provider order, to whichever definition wins. Collections (backends, commands, query handlers) are list or map keys that providers extend.
* **Providers stand alone.** Each provider describes one piece of functionality and does not override other providers' keys. What it needs from outside it declares as keys in its own namespace (`model/files`, `cli/output`, `solver/load-wasm`); something else binds them.
* **The application is a provider too.** The application provider composes the feature providers (model, records, solver, command line) and is platform-neutral. Another system that composes providers the same way can load it whole, or load only some of its parts, next to its own providers. Such a system may scope any entry of its composition, a single provider or a whole group, under a prefix of its choosing; nothing is scoped by default, and providers never prefix their own keys. References between providers in a scoped group move with them; the group's required keys are bound under the prefix.
* **Platform access is a provider.** A platform provider (Node first, a browser later) defines the platform's services and binds the keys that the other providers require to them, with aliases. It is the only code that touches platform APIs.
* **A composition root only orders providers.** An executable such as `bin/decisions` lists the application provider and the platform provider, composes them and resolves an entry key. It has no special keys or powers; a test or an embedding system is a composition root in the same way. Composition is immutable once built; nothing resolves until asked.
* **Features are chosen by composition**, not by flags checked in code. Debug, test and environment-specific behaviour are ordinary providers appended to the composition.
* **The contract follows `@uny/di`.** The composition library implements the intended contract of [`@uny/di`](https://github.com/XedinUnknown/uny-core/tree/0.1.x/packages/di) (its README), written in this repository, so that the two can merge once that package is published.

### Consequences

* Good, because adding a backend, query kind, command or check is adding a provider, and the existing ones stay unmodified.
* Good, because tests and diagnostics replace or wrap any part without special access.
* Good, because the same providers run under the command line, a browser page, an artifact or another system; only the platform provider differs.
* Bad, because indirection through keys needs naming discipline and diagnostics (which contribution won, which backend answered).
* Bad, because a typo in a key is found at resolution, not at compile time; tests resolve every entry key.
* Bad, because the platform provider binds every required key and changes whenever a provider adds one.

## Pros and Cons of the Options

### Modularity for solving backends only

* Good, because it is less indirection.
* Bad, because the format, checks, commands and later stages could not be extended or replaced the same way, platform code would leak into them, and the application could not be embedded.

### A plugin registry that parts call into at start-up

* Bad, because registration order becomes import order, and parts run code at start-up instead of providing configuration.

### A framework DI container with auto-discovery and provider lifecycles

* Bad, because discovery hides load order, lifecycle hooks mix configuration with execution, and modules become tied to the framework.
