# Spec Delta

## Purpose

Tells the caller, for a model and the current choices, which options remain feasible, which are forced, which open questions that depends on, and which accepted decisions no longer hold.

## ADDED Requirements

### Requirement: Solve request
The solver SHALL accept a model, choices (a decision id mapped to an option path or family path within it, or a hidden choice mapped to yes or no), assumption values (a yes/no assumption mapped to yes, no or unknown; a numeric assumption mapped to an integer within its bounds or unknown), and a confidence threshold (default `verified`). It SHALL answer only in the model's ids and paths.

#### Scenario: Family as a choice
- **WHEN** the choices are `{Hosting: Serverless}`
- **THEN** the solver treats Hosting as "one of Serverless.Functions or Serverless.Edge"

#### Scenario: Unknown id
- **WHEN** a choice refers to a decision or option path the model does not define
- **THEN** the solver rejects the request with an error naming the unknown id, and returns no result

#### Scenario: Numeric value out of bounds
- **WHEN** A10 is given the value 5000 and its bounds are 0 to 2000
- **THEN** the solver rejects the request with an error naming A10 and its bounds

### Requirement: Accepted decisions as choices
Decisions whose status in the model is `accepted` SHALL count as choices of their chosen option unless the request chooses something else for the same decision; the solver SHALL report every such override.

#### Scenario: Request overrides an accepted decision
- **WHEN** the reference model's CDN decision is accepted with `HostProvider` and the request chooses `{CDN: Independent}`
- **THEN** CDN = Independent is used, and the answer reports that it overrides the accepted decision

### Requirement: Accepted decisions that no longer hold
The solver SHALL report an accepted decision as stale when its `relies-on` names a retired rule, and as in conflict when its chosen option is infeasible under the other choices and known assumption values.

#### Scenario: Decision relying on a retired rule
- **WHEN** the reference model is solved with no choices
- **THEN** the CDN decision is reported stale, naming R14 and the fact R11 that retired it

### Requirement: Option feasibility
For every option the caller has not chosen, the solver SHALL report whether some completion of the current choices that includes the option satisfies all hard rules, for at least one combination of values of the unknown assumptions.

#### Scenario: Option ruled out by a rule
- **WHEN** the choices are `{Sessions: Token}`
- **THEN** the hidden choice `InstantRevocation = yes` is reported infeasible

#### Scenario: Option still open
- **WHEN** the choices are `{Sessions: Server}`
- **THEN** `InstantRevocation = yes` is reported feasible

#### Scenario: Agreement with exhaustive enumeration
- **WHEN** feasibility is computed for any reachable set of choices on either bundled model
- **THEN** each option's result equals the result of exhaustively enumerating all assignments

### Requirement: Option families
The solver SHALL report a family as feasible when at least one of its options is feasible, and SHALL report each option of the family separately.

#### Scenario: Family feasible through one member
- **WHEN** A5 is set to no and no choices are made in the reference model
- **THEN** `Hosting.Serverless` is feasible, `Hosting.Serverless.Edge` is infeasible because of R12, and `Hosting.Serverless.Functions` is feasible

### Requirement: Dependency conditions
For a feasible option whose feasibility depends on unknown assumptions, the solver SHALL report the condition under which it is feasible, as a minimal set of alternatives, each a conjunction of assumption values (for numeric assumptions, a bound such as `A10 ≤ 500`). An option feasible for every value of the unknown assumptions SHALL be reported without a condition.

#### Scenario: Condition on one assumption
- **WHEN** the choices are `{Realtime: WebSockets}` and A1 is unknown in the reference model
- **THEN** `Hosting.Serverless.Functions` is feasible under the condition "A1 = yes"

#### Scenario: Condition on two assumptions
- **WHEN** the choices are `{Realtime: WebSockets}` and A1 and A5 are unknown in the reference model
- **THEN** `Hosting.Serverless.Edge` is feasible under the condition "A1 = yes and A5 = yes"

#### Scenario: Numeric condition
- **WHEN** the threshold is `plausible`, A10 is unknown and `Hosting = Serverless.Functions` is unchosen
- **THEN** `Hosting.Serverless.Functions` is feasible under a condition that includes `A10 ≤ 500`

### Requirement: Configuration-level dependencies
When every feasible completion of the current choices requires the same assumption values, the solver SHALL report that condition once for the whole configuration, and SHALL NOT repeat it on each option.

#### Scenario: Assumption every option depends on
- **WHEN** the choices are `{Hosting: Serverless.Functions, Realtime: WebSockets}` and A1 is unknown
- **THEN** "A1 = yes" is reported once as a configuration-level condition, and no option lists A1 in its own condition

### Requirement: Forced options
The solver SHALL report as forced every unchosen option and family that holds in all feasible completions of the current choices for every value of the unknown assumptions under which the configuration is consistent. An option forced only under some assumption values SHALL be reported with that condition.

#### Scenario: Option forced by a rule
- **WHEN** the choices are `{InstantRevocation: yes}`
- **THEN** `Sessions.Server` is reported forced

#### Scenario: Family forced, no single option forced
- **WHEN** the threshold is `likely` and the choices are `{Sessions: Server, SessionStore: InMemory}` in the reference model
- **THEN** `Hosting.Containers` is reported forced, and neither `Hosting.Containers.ManagedCluster` nor `Hosting.Containers.PaaS` is

#### Scenario: Nothing forced in the minimal example
- **WHEN** the minimal example is solved with no choices and A1 unknown
- **THEN** no option or family is reported forced

### Requirement: Inconsistent configuration
When the current choices and known assumption values already violate a hard rule, the solver SHALL report the configuration as inconsistent instead of a feasibility list. When a model has no consistent configuration at all, the solver SHALL report it as void.

#### Scenario: Assumption closes against a choice
- **WHEN** the choices are `{Hosting: Serverless.Functions, Realtime: WebSockets}` and A1 is set to no
- **THEN** the configuration is reported inconsistent

#### Scenario: Void model
- **WHEN** a model's hard rules contradict each other with no choices made
- **THEN** the solver reports the model as void, with an explanation

### Requirement: Numeric rules
The solver SHALL evaluate rules that compare linear terms over numeric assumptions and constants.

#### Scenario: Cost exceeds budget
- **WHEN** the threshold is `plausible`, `Hosting = Serverless.Functions` is chosen and A10 is set to 600 (600 × 2 > 1000)
- **THEN** the configuration is reported inconsistent

#### Scenario: Cost within budget
- **WHEN** the threshold is `plausible`, `Hosting = Serverless.Functions` is chosen and A10 is set to 400
- **THEN** the configuration is consistent

### Requirement: Response time
With the clingo backend in a current desktop browser, a full propagation on the reference model (every unchosen option, its condition, and forced options, with no choices made and all assumptions unknown) SHALL complete within 2 seconds.

#### Scenario: Propagation on the reference model
- **WHEN** a full propagation runs in a browser with the clingo backend, no choices made and all assumptions unknown
- **THEN** it finishes within 2 seconds
