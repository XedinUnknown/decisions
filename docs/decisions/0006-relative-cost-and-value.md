---
status: accepted
date: 2026-11-16
---

# Cost and value in equal points, sized with a Fibonacci guide; ratio for options, Pareto front for configurations

## Context and Problem Statement

Options can carry a cost (like story points) and a value, so that totals can be calculated and options ranked. A ratio such as value per cost only means something if every point is worth the same as every other point on both scales, and optimising a ratio over whole configurations tends to favour configurations that do almost nothing. How are cost and value expressed and used?

## Decision Drivers

* Ranking options by value per unit cost is the main question.
* Numbers must be comparable as sums and ratios, not only as ranks.
* People size things more reliably in coarse steps than in exact numbers.
* Options interact: a combination can be worth more or less than its parts.

## Considered Options

* Equal points for cost and value, with Fibonacci numbers as the sizing guide; ratio for single options, Pareto front for configurations
* Values restricted to the Fibonacci scale
* Cost in hours or money, value as a rank only

## Decision Outcome

Chosen option: "Equal points, Fibonacci as the sizing guide", because what makes sums and ratios meaningful is that each point equals every other point (an 8 is two 4s); Fibonacci only answers "where is the next step in size?" when someone picks a number.

* Cost and value are points: non-negative integers in which every point counts the same.
* Fibonacci numbers (0, 1, 2, 3, 5, 8, 13, 21, …) are the recommended sizes. A model may declare `guide: fibonacci`, and validation then warns, without failing, about values off the guide. Other values stay valid.
* Options are ranked by value per cost; an option with cost 0 is listed separately, not divided.
* Whole configurations are compared on the Pareto front: the configurations for which no other is both cheaper and more valuable. Ratios are not optimised over whole configurations.
* Costs and values may also be attached to combinations of options, so interactions are counted.
* A model may declare a measured unit (hours, money) instead of points; totals then use that unit.

### Consequences

* Good, because the ranking the product needs is meaningful.
* Good, because combination terms stop "the sum of the parts" from misrepresenting interacting options.
* Good, because the guide keeps sizes coarse without rejecting a deliberate in-between value.
* Bad, because relative sizing is less accurate than hour estimates ([Jørgensen & Escott 2022](https://conf.researchr.org/details/esem-2022/esem-2022-journal-first/4/Relative-estimates-of-software-development-effort-Are-they-more-accurate-or-less-tim)); the model may declare a measured unit when that matters.

### Confirmation

The `model/format` spec accepts off-guide values with a warning; the `solving/cost` spec covers ranking by value per cost, the Pareto front and a combination term that changes a total.

## More Information

* [RADAR](https://ucl-badass.github.io/radar) reports Pareto fronts for requirements and architecture decisions; see [docs/comparison.md](../comparison.md).
