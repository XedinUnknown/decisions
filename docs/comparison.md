# How this compares to existing work

Researched 2026-11-16. Each section names what exists, what it does well, and what this project adds or borrows.

## Summary

No maintained tool combines a decision model, a constraint solver with conflict explanations, and the handling of uncertainty that real specifications need. The pieces exist separately:

| Need | Closest existing work | Status |
| --- | --- | --- |
| Decisions with dependencies between them | [Zimmermann's reusable decision models](https://researchweb.draco.res.ibm.com/publications/managing-architectural-decision-models-with-dependency-relations-integrity-constraints-and-production-rules), [ADMentor](https://github.com/IFS-HSR/ADMentor) | Dormant tools; no solver |
| Formal semantics of decision models, including forced options | [Szlenk, Alloy semantics](https://ar5iv.arxiv.org/html/1807.02798) | Paper; consistency checking left as future work |
| Propagation over design choices | [Egyed & Wile, TSE 2006](https://discovery.ucl.ac.uk/13287/1/13287.pdf) | Research, UML-specific |
| Solver plus "why not this option?" explanations | [Kepler, 2026](https://arxiv.org/abs/2604.25506) | Paper; networking domain; no published code, no UI |
| Interactive configuration with explanations | [Knowledge-based configuration](https://ase.ist.tugraz.at/wp-content/uploads/sites/34/2023/05/2011-Felfernig-Personalized-diagnoses-for-inconsistent-user-requirements.pdf), [COOM Suite](https://github.com/potassco/coom-suite), [Siemens over clingo](https://www.cs.uni-potsdam.de/wv/publications/DBLP_conf/confws/Comploi-TaupeFH23.pdf) | Mature for products, not for decisions |
| Uncertainty, Pareto fronts, value of information | [RADAR](https://ucl-badass.github.io/radar) | Research tool; simulation, no conflict explanations |
| Decision records | [MADR](https://adr.github.io/madr/), [EventCatalog ADRs](https://eventcatalog.dev/blog/introducing-adrs), AI drafting studies ([Dhar et al.](https://arxiv.org/abs/2403.01709v1), [DRAFT](https://arxiv.org/abs/2504.08207v1)) | Mature and crowded |

## What this project adds

1. **Open questions as assumptions.** An option can be "feasible only if A1 turns out true". When the question closes, everything re-propagates. None of the tools above model unanswered questions this way.
2. **Rules with confidence and evidence.** Rules carry a confidence level and a trail of sources. Low-confidence rules do not silently remove options; the tool says which doubtful rules stand in the way ([ADR-0004](decisions/0004-confidence-as-ordered-levels.md)).
3. **Consequences.** Derived outcomes such as "a new third-party processor is involved" are first-class, and several decisions can lead to the same consequence.
4. **AI maintenance against a deterministic checker.** An AI updates the model through conversation; the model is validated and solved deterministically, so drafting errors surface as validation errors or explained conflicts rather than as confident prose. Studies of LLM-written specifications ([Kepler: 43% failure without a checker](https://arxiv.org/html/2604.25506v1)) and of LLM-to-solver loops ([self-correction drives results](https://arxiv.org/pdf/2604.27960)) both point to this loop.
5. **A generated, browser-based configurator.** The model drives the UI. Most predecessors were tied to a host platform (Sparx EA, Eclipse, IBM's ADkwik) and disappeared with it.

## What this project borrows

| From | What |
| --- | --- |
| Zimmermann / ADMentor | The vocabulary of decisions, alternatives and outcomes; the split between reusable guidance (the model) and a decision log (a session) |
| Szlenk | "Forcing" as a derived relation: options that hold in every valid configuration |
| Kepler | Splitting a conflict into atomic parts and re-solving to isolate the responsible rules; priorities as lexicographic optimisation |
| Knowledge-based configuration | QuickXplain for conflicts, FastDiag for diagnoses |
| Linux kernel configurator research | Users mainly struggle to resolve errors and enable inactive options ([VaMoS'12 survey](https://gsd.uwaterloo.ca/sites/default/files/vamos12-survey.pdf)); the answer was suggested repairs ([range fixes, ICSE'12](https://gsd.uwaterloo.ca/publications/view/436.html)), not only conflicts |
| Siemens / clingo | User choices as switchable inputs so the model is not rebuilt on every change |
| RADAR | Pareto fronts instead of single ratios for whole configurations; value of information for ranking open questions |

## Known risk: capturing knowledge

Decision-rationale tools have historically failed on capture effort: the "capture problem" is "the spectre haunting design rationale" ([Conklin et al.](https://research-archive.stem.open.ac.uk/stemra-data/uploads/files/KMI-05-18.pdf)), and about half of repositories that keep ADRs hold fewer than five ([arXiv 2604.03826](https://arxiv.org/pdf/2604.03826)). This project's answer is that people do not author models: an AI maintains them from conversation and from existing specifications, and people review changes that a solver has already checked. The constraints already exist as prose in specifications; the model makes them explicit and checkable.

## Complementary tools

**EventCatalog** documents event-driven architectures and has had first-class ADRs since May 2026 ([announcement](https://eventcatalog.dev/blog/introducing-adrs)). ADR frontmatter covers `status`, `date`, `decisionMakers` and `appliesTo` links to services, domains and other resources, plus custom `x-` properties ([reference](https://www.eventcatalog.dev/docs/development/guides/resources/adrs/reference.md)). Its MIT-licensed SDK (`@eventcatalog/sdk` 2.32.1) offers `writeAdr` and `writeCustomDoc`, and pages can embed custom Astro or React components and Mermaid diagrams. The natural integration is a generator that writes accepted and proposed decisions as EventCatalog ADRs with model ids in `x-` properties, and an embedded component for the interactive model. EventCatalog 5.x itself is licensed under BUSL-1.1 (free for organisations under $10M revenue and funding, open-source projects and individuals; [licence FAQ](https://eventcatalog.dev/license-faq)).

**OpenSpec** plans changes in code repositories. This repository uses it together with MADR ([ADR-0001](decisions/0001-record-decisions-with-madr.md)).
