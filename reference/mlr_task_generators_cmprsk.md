# Competing Risks Task Generator

A
[mlr3::TaskGenerator](https://mlr3.mlr-org.com/reference/TaskGenerator.html)
for simulating right-censored competing risks tasks with numerical
baseline covariates.

Uses
[`sim_cmprsk()`](https://mlr3cmprsk.mlr-org.com/reference/sim_cmprsk.md)
to generate event times and causes from cause-specific Weibull
proportional hazards, with independent right-censoring. The default
`shape = 1` corresponds to constant cause-specific hazards (exponential
event times), while other values allow increasing or decreasing hazards
over time.

See
[`sim_cmprsk()`](https://mlr3cmprsk.mlr-org.com/reference/sim_cmprsk.md)
for the underlying statistical model, parameter definitions, and
defaults.

## Details

The generated
[TaskCompRisks](https://mlr3cmprsk.mlr-org.com/reference/TaskCompRisks.md)
contains the observed `time`, `event`, and numerical features `x1`, ...,
`xp`. Event codes are integers, with `0` indicating censoring and `1`,
..., `n_causes` identifying competing causes.

Generation fails if any requested cause is absent among the observed
events. Event and censoring proportions may differ from their specified
targets due to sampling variability and covariate effects; see
[`sim_cmprsk()`](https://mlr3cmprsk.mlr-org.com/reference/sim_cmprsk.md)
for details.

Use [`set.seed()`](https://rdrr.io/r/base/Random.html) before
`$generate()` for reproducibility.

## Dictionary

This generator is available through
[mlr3::mlr_task_generators](https://mlr3.mlr-org.com/reference/mlr_task_generators.html)
and [`mlr3::tgen()`](https://mlr3.mlr-org.com/reference/mlr_sugar.html):

    mlr_task_generators$get("cmprsk")
    tgen("cmprsk")

## Parameters

|             |         |         |                  |
|-------------|---------|---------|------------------|
| Id          | Type    | Default | Range            |
| n_features  | integer | 3       | \\\[1, 10\]\\    |
| n_causes    | integer | 2       | \\\[2, 5\]\\     |
| event_probs | untyped | NULL    | \-               |
| shape       | numeric | 1       | \\\[0, \infty)\\ |
| rate        | numeric | 0.2     | \\\[0, \infty)\\ |
| beta_sd     | numeric | 0.3     | \\\[0, \infty)\\ |

## References

Beyersmann, Jan, Latouche, Aurelien, Buchholz, Anika, Schumacher, Martin
(2009). “Simulating competing risks data in survival analysis.”
*Statistics in Medicine*, **28**(6), 956–971.
[doi:10.1002/sim.3516](https://doi.org/10.1002/sim.3516) .

## See also

[`sim_cmprsk()`](https://mlr3cmprsk.mlr-org.com/reference/sim_cmprsk.md),
[mlr3::mlr_task_generators](https://mlr3.mlr-org.com/reference/mlr_task_generators.html)

## Super class

[`mlr3::TaskGenerator`](https://mlr3.mlr-org.com/reference/TaskGenerator.html)
-\> `TaskGeneratorCompRisks`

## Methods

### Public methods

- [`TaskGeneratorCompRisks$new()`](#method-TaskGeneratorCompRisks-initialize)

- [`TaskGeneratorCompRisks$clone()`](#method-TaskGeneratorCompRisks-clone)

Inherited methods

- [`mlr3::TaskGenerator$format()`](https://mlr3.mlr-org.com/reference/TaskGenerator.html#method-format)
- [`mlr3::TaskGenerator$generate()`](https://mlr3.mlr-org.com/reference/TaskGenerator.html#method-generate)
- [`mlr3::TaskGenerator$print()`](https://mlr3.mlr-org.com/reference/TaskGenerator.html#method-print)

------------------------------------------------------------------------

### `TaskGeneratorCompRisks$new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    TaskGeneratorCompRisks$new()

------------------------------------------------------------------------

### `TaskGeneratorCompRisks$clone()`

The objects of this class are cloneable with this method.

#### Usage

    TaskGeneratorCompRisks$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(mlr3)
library(mlr3cmprsk)

generator = tgen(
  "cmprsk",
  n_features = 5L,
  n_causes = 3L,
  event_probs = c(0.4, 0.2, 0.1)
)

set.seed(42)
task = generator$generate(1000L)
task
#> 
#> ── <TaskCompRisks> (1000x7) ────────────────────────────────────────────────────
#> • Target: time and event
#> • Properties: -
#> • Features (5):
#>   • dbl (5): x1, x2, x3, x4, x5
#> • Causes (3):
#>   • 1 (Cause 1): 392 (39.2%)
#>   • 2 (Cause 2): 183 (18.3%)
#>   • 3 (Cause 3): 130 (13.0%)
#> • Censored: 295 (29.5%)

# Observed event and censoring proportions
prop.table(table(task$event()))
#> 
#>     0     1     2     3 
#> 0.295 0.392 0.183 0.130 
```
