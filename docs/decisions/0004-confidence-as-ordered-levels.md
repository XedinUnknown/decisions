---
status: accepted
date: 2026-11-16
---

# Confidence as ordered levels, compared level first

## Context and Problem Statement

Rules carry a confidence. [Concept §4.4](../concept.md#44-confidence) stored it as a byte (0–255) and the first `solver-core` draft explained conflicts by blaming the rules with the lowest total confidence. Two problems: the byte suggests percentages the labels do not mean ("plausible" at 100/255 would read as "probably false"), and adding confidences up blames one solid rule rather than three flimsy ones. How is confidence stored and compared?

## Decision Drivers

* People judge a few levels reliably, not hundreds of values.
* Explanations must blame the rules most likely to be wrong.
* Labels must mean the same to every reader.

## Considered Options

* Ordered levels, compared level first (like log severities)
* Probabilities, combined as log-odds
* Byte confidence, summed (the first draft)

## Decision Outcome

Chosen option: "Ordered levels, compared level first", because it matches how the levels are actually assigned and needs no probability arithmetic.

* Levels, highest first: **verified**, **likely**, **plausible**, **guess**, and **unrated** (lowest).
* Each level is published with a numeric range so that readers interpret it the same way. The ranges are settled in the `solver-core` change, following the [UK intelligence yardstick](https://www.gov.uk/government/publications/explaining-uncertainty-in-uk-intelligence-assessment/explaining-uncertainty-in-uk-intelligence-assessment) approach.
* A configurable threshold makes rules at or above a level hard; the default is **verified** only.
* When an option needs soft rules to be wrong, explanations are compared like version numbers: the one whose highest blamed level is lower wins; at the same level, fewer blamed rules wins; then the next level down decides.

### Consequences

* Good, because one "likely" rule is never blamed when "guess" rules could explain the conflict, however many of them.
* Good, because clingo optimises with priority levels natively.
* Bad, because two rules at the same level count as equally doubtful even if their authors felt differently.

### Confirmation

The `solving/soft-rules` spec has a scenario where one "likely" rule and three "plausible" rules compete, and the three "plausible" rules are blamed.

## More Information

* Summing confidences is neither probabilistic nor [possibilistic](https://www.ijcai.org/proceedings/2025/1158.pdf); ordered levels follow the possibilistic reading.
* Verbal labels are read inconsistently without numbers ([Kent 1964](https://www.cia.gov/resources/csi/static/Words-of-Estimative-Probability.pdf); [Budescu et al. 2009](https://research.library.fordham.edu/psych_facultypubs/87)).
