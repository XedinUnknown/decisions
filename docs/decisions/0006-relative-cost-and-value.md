---
status: accepted
date: 2026-11-16
---

# Relative cost and value on a Fibonacci scale; ratio for options, Pareto front for configurations

## Context and Problem Statement

Options can carry a cost (like story points) and a value, so that totals can be calculated and options ranked. A ratio such as value per cost only means something if "twice the number" means "twice as much" on both scales, and optimising a ratio over whole configurations tends to favour configurations that do almost nothing. How are cost and value expressed and used?

## Decision Drivers

* Ranking options by value per unit cost is the main question.
* Numbers must be comparable as ratios, not only as ranks.
* Options interact: a combination can be worth more or less than its parts.

## Considered Options

* Relative cost and value on a Fibonacci scale, ratio for single options, Pareto front for configurations
* Free integer scores with value ÷ cost everywhere
* Cost in hours or money, value as a rank only

## Decision Outcome

Chosen option: "Relative cost and value on a Fibonacci scale", because relative sizing on a Fibonacci scale is meant to be proportional (an 8 is roughly two 4s), which makes value per cost meaningful for ranking.

* Cost and value are both relative points on the scale 0, 1, 2, 3, 5, 8, 13, 21.
* Options are ranked by value per cost; an option with cost 0 is ranked separately, not divided.
* Whole configurations are compared on the Pareto front: the configurations for which no other is both cheaper and more valuable. Ratios are not optimised over whole configurations.
* Costs and values may also be attached to combinations of options, so interactions are counted.
* A model may declare a different unit (hours, money) instead of points; totals then use that unit.

### Consequences

* Good, because the ranking the product needs is meaningful.
* Good, because combination terms stop "the sum of the parts" from misrepresenting interacting options.
* Bad, because relative sizing is less accurate than hour estimates ([Jørgensen & Escott 2022](https://conf.researchr.org/details/esem-2022/esem-2022-journal-first/4/Relative-estimates-of-software-development-effort-Are-they-more-accurate-or-less-tim)); the model may declare a measured unit when that matters.

### Confirmation

The `solving/cost` spec covers ranking by value per cost, the Pareto front and a combination term that changes a total.

## More Information

* [RADAR](https://ucl-badass.github.io/radar) reports Pareto fronts for requirements and architecture decisions; see [docs/comparison.md](../comparison.md).
