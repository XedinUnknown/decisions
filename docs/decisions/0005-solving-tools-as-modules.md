---
status: accepted
date: 2026-11-16
---

# Solving tools as modules that declare what they answer

## Context and Problem Statement

More tools may later answer more kinds of questions (a Prolog or Datalog backend, an explainer over MCP, new queries such as "what if"). How are tools added without changing the engine?

## Decision Drivers

* New backends and new query kinds must not require engine changes.
* A query no loaded tool can answer must fail clearly, not approximately.
* Tests must be able to compose the engine with exactly the backends they need.

## Considered Options

* Config-based modules: backends and query handlers contribute keyed definitions to one composed registry
* A plugin registry that tools call into at start-up
* Hard-wired backends behind an `if`

## Decision Outcome

Chosen option: "Config-based modules", because module selection and order stay with the host and are visible in one place, which also makes test composition simple.

* Each backend declares the query kinds it supports (check, optimise, consequences, possible, forced).
* Backends are contributed to a list; the host owns the order of preference.
* The router sends each query to the first preferred backend that supports it, and rejects queries that no loaded backend supports.
* Query handlers fall back on repeated checks where a backend lacks a richer kind, except for optimisation.
* The registry stays minimal until a third tool actually arrives.

### Consequences

* Good, because adding a tool or a query kind is adding a module.
* Bad, because routing adds a level of indirection that needs diagnostics (which backend answered).

### Confirmation

A test composes the engine with a test-only backend and routes a query to it without any engine file changing.
