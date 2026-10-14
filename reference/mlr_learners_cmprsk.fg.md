# Fine-Gray Competing Risks Learner

Fine-Gray subdistribution hazards model for competing risks using
[`cmprsk::crr()`](https://rdrr.io/pkg/cmprsk/man/crr.html).

## Details

A separate Fine-Gray subdistribution hazards model is fitted for every
cause in `task$cmp_events`. This follows the
[LearnerCompRisks](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md)
design: predictions contain CIFs for all available causes.

The fitted model is an S3 object of class `"fine_gray"` that stores a
cause-specific list of `crr` class models.

At prediction time, each cause-specific model is evaluated with
[`cmprsk::predict.crr()`](https://rdrr.io/pkg/cmprsk/man/predict.crr.html)
and the resulting CIF matrices are aligned to a common time grid across
causes using constant CIF interpolation. The time grid is the **unique
event times (across all causes)** observed in the training set.

Independently fitted cause-specific models can produce CIFs whose sum
exceeds 1. The corresponding warning is disabled package-wide by
default, as it can recur on every prediction call. Set
`options(mlr3cmprsk.warn_cif_sum = TRUE)` to enable it. See also Package
Options section in
[mlr3cmprsk-package](https://mlr3cmprsk.mlr-org.com/reference/mlr3cmprsk-package.md).

Time-interaction terms (via `cov2`) are not implemented.

## Dictionary

This [Learner](https://mlr3.mlr-org.com/reference/Learner.html) can be
instantiated via the
[dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
[mlr_learners](https://mlr3.mlr-org.com/reference/mlr_learners.html) or
with the associated sugar function
[lrn()](https://mlr3.mlr-org.com/reference/mlr_sugar.html):

    mlr_learners$get("cmprsk.fg")
    lrn("cmprsk.fg")

## Meta Information

- Task type: “cmprsk”

- Predict Types: “cif”

- Feature Types: “logical”, “integer”, “numeric”

- Required Packages: [mlr3](https://CRAN.R-project.org/package=mlr3),
  [mlr3cmprsk](https://CRAN.R-project.org/package=mlr3cmprsk),
  [cmprsk](https://CRAN.R-project.org/package=cmprsk)

## Parameters

|          |         |         |             |                  |
|----------|---------|---------|-------------|------------------|
| Id       | Type    | Default | Levels      | Range            |
| cengroup | untyped | \-      |             | \-               |
| gtol     | numeric | 1e-06   |             | \\\[0, \infty)\\ |
| maxiter  | integer | 10      |             | \\\[0, \infty)\\ |
| init     | untyped | \-      |             | \-               |
| variance | logical | TRUE    | TRUE, FALSE | \-               |

## References

Fine, P J, Gray, J R (1999). “A Proportional Hazards Model for the
Subdistribution of a Competing Risk.” *Journal of the American
Statistical Association*, **94**(446), 496–509.
[doi:10.1080/01621459.1999.10474144](https://doi.org/10.1080/01621459.1999.10474144)
.

## See also

- Chapter in the [mlr3book](https://mlr3book.mlr-org.com/):
  <https://mlr3book.mlr-org.com/chapters/chapter2/data_and_basic_modeling.html#sec-learners>

- [Dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
  of [Learners](https://mlr3.mlr-org.com/reference/Learner.html):
  [mlr3::mlr_learners](https://mlr3.mlr-org.com/reference/mlr_learners.html)

- `as.data.table(mlr_learners)` for a table of available
  [Learners](https://mlr3.mlr-org.com/reference/Learner.html) in the
  running session

- [mlr3pipelines](https://CRAN.R-project.org/package=mlr3pipelines) to
  combine learners with pre- and postprocessing steps

- [mlr3tuning](https://CRAN.R-project.org/package=mlr3tuning) for tuning
  of hyperparameters

Other competing risk learners:
[`mlr_learners_cmprsk.aalen`](https://mlr3cmprsk.mlr-org.com/reference/mlr_learners_cmprsk.aalen.md)

## Super classes

[`mlr3::Learner`](https://mlr3.mlr-org.com/reference/Learner.html) -\>
[`LearnerCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md)
-\> `LearnerCompRisksFineGray`

## Methods

### Public methods

- [`LearnerCompRisksFineGray$new()`](#method-LearnerCompRisksFineGray-initialize)

- [`LearnerCompRisksFineGray$clone()`](#method-LearnerCompRisksFineGray-clone)

Inherited methods

- [`mlr3::Learner$base_learner()`](https://mlr3.mlr-org.com/reference/Learner.html#method-base_learner)
- [`mlr3::Learner$configure()`](https://mlr3.mlr-org.com/reference/Learner.html#method-configure)
- [`mlr3::Learner$encapsulate()`](https://mlr3.mlr-org.com/reference/Learner.html#method-encapsulate)
- [`mlr3::Learner$format()`](https://mlr3.mlr-org.com/reference/Learner.html#method-format)
- [`mlr3::Learner$help()`](https://mlr3.mlr-org.com/reference/Learner.html#method-help)
- [`mlr3::Learner$predict()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict)
- [`mlr3::Learner$predict_newdata()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict_newdata)
- [`mlr3::Learner$print()`](https://mlr3.mlr-org.com/reference/Learner.html#method-print)
- [`mlr3::Learner$reset()`](https://mlr3.mlr-org.com/reference/Learner.html#method-reset)
- [`mlr3::Learner$selected_features()`](https://mlr3.mlr-org.com/reference/Learner.html#method-selected_features)
- [`mlr3::Learner$train()`](https://mlr3.mlr-org.com/reference/Learner.html#method-train)

------------------------------------------------------------------------

### `LearnerCompRisksFineGray$new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    LearnerCompRisksFineGray$new()

------------------------------------------------------------------------

### `LearnerCompRisksFineGray$clone()`

The objects of this class are cloneable with this method.

#### Usage

    LearnerCompRisksFineGray$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Define a task
task = tsk("pbc")
task$select(c("age", "chol", "albumin", "ast", "bili", "protime"))

# Stratify by event status
task$set_col_roles(cols = "status", add_to = "stratum")
task
#> 
#> ── <TaskCompRisks> (276x8): Primary Biliary Cholangitis ────────────────────────
#> • Target: time and status
#> • Properties: strata
#> • Features (6):
#>   • dbl (4): albumin, ast, bili, protime
#>   • int (2): age, chol
#> • Strata: status

# Create training and test sets
set.seed(42L)
part = partition(task)

# Define the learner
learner = lrn("cmprsk.fg")

# Train on the training set
learner$train(task, row_ids = part$train)
learner$native_model
#> $`1`
#> convergence:  TRUE 
#> coefficients:
#>        age    albumin        ast       bili       chol    protime 
#> -0.0977200 -0.3992000 -0.0019480  0.0006162  0.0009104 -0.2221000 
#> standard errors:
#> [1] 0.027980 0.924300 0.003838 0.076710 0.001232 0.393500
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 0.00048 0.67000 0.61000 0.99000 0.46000 0.57000 
#> 
#> $`2`
#> convergence:  TRUE 
#> coefficients:
#>        age    albumin        ast       bili       chol    protime 
#>  4.543e-02 -1.020e+00  3.061e-03  1.200e-01  6.019e-05  2.155e-01 
#> standard errors:
#> [1] 0.0132100 0.2377000 0.0019090 0.0173200 0.0003912 0.1083000
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 5.8e-04 1.8e-05 1.1e-01 4.3e-12 8.8e-01 4.7e-02 
#> 
#> attr(,"class")
#> [1] "fine_gray"

# Predict CIFs for the test set
predictions = learner$predict(task, row_ids = part$test)
predictions
#> 
#> ── <PredictionCompRisks> for 92 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        1   13     2 <list[2]>
#>       10  123     2 <list[2]>
#>       16    4     2 <list[2]>
#>      ---  ---   ---       ---
#>      157   73     1 <list[2]>
#>      208   27     1 <list[2]>
#>      213   47     1 <list[2]>

# Score predictions
predictions$score()
#> cmprsk.ibs 
#>  0.1116802 
```
