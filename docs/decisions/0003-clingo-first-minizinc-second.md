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

### Confirmation

A probe page published as a claude.ai artifact and opened in the Claude desktop app on 2026-11-16 found:

* The page is not cross-origin isolated and `SharedArrayBuffer` is unavailable, so `z3-solver` cannot start there. WebAssembly compilation is allowed.
* `clingo-wasm` 0.6.0 loaded from the jsDelivr CDN fails: the artifact's content-security policy blocks fetching `clingo.wasm` from the CDN.
* `clingo-wasm` 0.6.0 published together with the page (its JavaScript and `clingo.wasm` as the artifact's own files) runs: brave mode, cautious mode and `#minimize` returned the expected results.
* MiniZinc: pending a corrected probe. Its `minizinc.wasm` (18.9 MB) exceeds the 15 MB limit for a single binary file published with an artifact, so it cannot be self-hosted the way clingo is.

Consequence for deployment: solver WebAssembly files ship with the application, not from a CDN. The `solver-core` change records further measurements in its design.

## More Information

* Siemens' interactive configuration API over clingo ([Comploi-Taupe et al., ConfWS 2023](https://www.cs.uni-potsdam.de/wv/publications/DBLP_conf/confws/Comploi-TaupeFH23.pdf)) passes user choices as external atoms, so "no re-grounding is required". Its implementation, [OOASP](https://github.com/siemens/OOASP), is Python.
