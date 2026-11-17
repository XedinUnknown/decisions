---
status: accepted
date: 2026-11-16
---

# clingo as the first backend, MiniZinc second, Z3 out of the spike

## Context and Problem Statement

[Concept §4](../concept.md#4-schema-language) compared UVL (solved with Z3) and MiniZinc, and Answer Set Programming (clingo) was added later as a third candidate. Building three backends to compare them is the largest part of the first change. Which backends are built, and in which order?

## Decision Drivers

* The product runs in a browser, including inside sandboxed hosts such as claude.ai artifacts.
* Questions to answer: what is still possible, what is forced, why not, what to change, cheapest and most valuable configurations.
* Package size and maintenance.

## Considered Options

* clingo (`clingo-wasm`)
* MiniZinc (`minizinc`)
* UVL compiled to SMT-LIB, solved with Z3 (`z3-solver`)
* Z3 (or native clingo) as a server-side backend

## Decision Outcome

Chosen option: "clingo first, MiniZinc second; Z3 dropped from the spike", because:

* **clingo** answers "possible" and "forced" natively (brave and cautious reasoning) and optimises with priorities, which is how confidence levels are ordered ([ADR-0004](0004-confidence-as-ordered-levels.md)). It is the established tool for product configuration in industry ([Falkner et al. 2018](https://dblp.uni-trier.de/rec/journals/ki/FalknerFSTT18.html)). `clingo-wasm` 0.6.0 is about 5.5 MB and runs single-threaded without special headers. Checked in Node on 2026-11-16: brave mode excluded a ruled-out option, cautious mode returned a forced option, and `#minimize` returned the cheapest total.
* **MiniZinc** is strongest at arithmetic and optimisation and stays as the second backend. Its browser package is about 19.6 MB, and FindMUS is not part of its WebAssembly build.
* **Z3** in the browser requires `SharedArrayBuffer`, which needs the page to be served with cross-origin isolation headers: "you'll need to serve your page with special headers" ([z3-solver README](https://www.npmjs.com/package/z3-solver)). It is also the largest package (about 40 MB) and needs a compiler from the IR to SMT-LIB.

### Consequences

* Good, because the spike builds two backends instead of three.
* Good, because the backends complement each other: clingo for possibility and forcing, MiniZinc for arithmetic.
* Bad, because `clingo-wasm` has a single maintainer.
* Bad, because `clingo-wasm` wraps the command-line tool, so each check re-grounds the model; whether that meets the response-time target must be measured early.

### Server-side backend: not now

A server-side backend would run Z3, or native clingo with multi-shot solving and its Python explanation tools, outside the browser. It is not built now, because:

* clingo in the browser already answers every query kind the specs need, and MiniZinc covers arithmetic where it can be self-hosted.
* Z3's distinctive strengths (real-number arithmetic, strings, native unsatisfiable cores and consequence queries) are not needed by the current specs.
* A server is one more service to run and secure, and it would send model data off the viewer's device.

Revisit when one of these holds: models need real-number arithmetic; models become too large for the browser; native multi-shot solving is needed for response time; or explanations need tools that exist only natively. Composition ([ADR-0005](0005-application-composed-from-config-based-modules.md)) lets a provider add a server-side backend, for example one exposed as an MCP server, without engine changes.

## More Information

* Specified in the `solver-core` change's `solving/backends` capability.

### Probe of 2026-11-16

A probe page published as a claude.ai artifact and opened in the Claude desktop app on 2026-11-16 found:

* The page is not cross-origin isolated and `SharedArrayBuffer` is unavailable, so `z3-solver` cannot start there. WebAssembly compilation is allowed.
* `clingo-wasm` 0.6.0 loaded from the jsDelivr CDN fails: the artifact's content-security policy blocks fetching `clingo.wasm` from the CDN.
* `clingo-wasm` 0.6.0 published together with the page (its JavaScript and `clingo.wasm` as the artifact's own files) runs: brave mode, cautious mode and `#minimize` returned the expected results.
* MiniZinc 4.5.2 loaded from the CDN, with its worker started from a same-origin blob, timed out after 30 s. Its `minizinc.wasm` (18.9 MB) also exceeds the 15 MB limit for a single binary file published with an artifact, so it cannot be self-hosted the way clingo is. MiniZinc therefore does not run inside a claude.ai artifact; it remains a candidate for self-hosted deployments.

Consequence for deployment: solver WebAssembly files ship with the application, not from a CDN. The application's build step copies each backend's JavaScript and `.wasm` files into its output (bundlers handle this; `clingo-wasm` documents that Vite needs `worker: { format: "es" }`), and publishing to a claude.ai artifact includes the same files with the page, as the probe did. The `solver-core` change records further measurements in its design.

### Prior art

* Siemens' interactive configuration API over clingo ([Comploi-Taupe et al., ConfWS 2023](https://www.cs.uni-potsdam.de/wv/publications/DBLP_conf/confws/Comploi-TaupeFH23.pdf)) passes user choices as external atoms, so "no re-grounding is required". Its implementation, [OOASP](https://github.com/siemens/OOASP), is Python.
