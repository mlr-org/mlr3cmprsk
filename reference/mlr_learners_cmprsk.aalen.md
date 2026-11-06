# Aalen Johansen Competing Risks Learner

This learner estimates the Cumulative Incidence Function (CIF) for
competing risks using the empirical Aalen-Johansen (AJ) estimator.

Transition probabilities to each competing event are computed from the
training data via the
[`survival::survfit.formula()`](https://rdrr.io/pkg/survival/man/survfit.formula.html)
function. Predictions are made at all **unique event times (across all
causes)** observed in the training set.

## Dictionary

This [Learner](https://mlr3.mlr-org.com/reference/Learner.html) can be
instantiated via the
[dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
[mlr_learners](https://mlr3.mlr-org.com/reference/mlr_learners.html) or
with the associated sugar function
[lrn()](https://mlr3.mlr-org.com/reference/mlr_sugar.html):

    mlr_learners$get("cmprsk.aalen")
    lrn("cmprsk.aalen")

## Meta Information

- Task type: “cmprsk”

- Predict Types: “cif”

- Feature Types: “logical”, “integer”, “numeric”, “factor”

- Required Packages: [mlr3](https://CRAN.R-project.org/package=mlr3),
  [mlr3cmprsk](https://CRAN.R-project.org/package=mlr3cmprsk),
  [survival](https://CRAN.R-project.org/package=survival)

## Parameters

Empty ParamSet

## References

Aalen, O O, Johansen, Soren (1978). “An empirical transition matrix for
non-homogeneous Markov chains based on censored observations.”
*Scandinavian journal of statistics*, 141–150.

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
[`mlr_learners_cmprsk.fg`](https://mlr3cmprsk.mlr-org.com/reference/mlr_learners_cmprsk.fg.md)

## Super classes

[`mlr3::Learner`](https://mlr3.mlr-org.com/reference/Learner.html) -\>
[`LearnerCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md)
-\> `LearnerCompRisksAalenJohansen`

## Active bindings

- `native_model`:

  ([survival::survfit](https://rdrr.io/pkg/survival/man/survfit.html))  
  The fitted model.

## Methods

### Public methods

- [`LearnerCompRisksAalenJohansen$new()`](#method-LearnerCompRisksAalenJohansen-initialize)

- [`LearnerCompRisksAalenJohansen$importance()`](#method-LearnerCompRisksAalenJohansen-importance)

- [`LearnerCompRisksAalenJohansen$selected_features()`](#method-LearnerCompRisksAalenJohansen-selected_features)

- [`LearnerCompRisksAalenJohansen$clone()`](#method-LearnerCompRisksAalenJohansen-clone)

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
- [`mlr3::Learner$train()`](https://mlr3.mlr-org.com/reference/Learner.html#method-train)

------------------------------------------------------------------------

### `LearnerCompRisksAalenJohansen$new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    LearnerCompRisksAalenJohansen$new()

------------------------------------------------------------------------

### `LearnerCompRisksAalenJohansen$importance()`

All features have a score of `0` for this learner. This method exists
solely for compatibility with the `mlr3` ecosystem, as this learner is
used as a fallback for other survival learners that may require an
`importance()` method.

#### Usage

    LearnerCompRisksAalenJohansen$importance()

#### Returns

Named [`numeric()`](https://rdrr.io/r/base/numeric.html).

------------------------------------------------------------------------

### `LearnerCompRisksAalenJohansen$selected_features()`

Selected features are always the empty set for this learner. This method
is implemented only for compatibility with the `mlr3` API, as this
learner does not perform feature selection.

#### Usage

    LearnerCompRisksAalenJohansen$selected_features()

#### Returns

`character(0)`.

------------------------------------------------------------------------

### `LearnerCompRisksAalenJohansen$clone()`

The objects of this class are cloneable with this method.

#### Usage

    LearnerCompRisksAalenJohansen$clone(deep = FALSE)

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
#> ── <TaskCompRisks> (276x8): Mayo Clinic Primary Biliary Cholangitis Data ───────
#> • Target: time and status
#> • Properties: strata
#> • Features (6):
#>   • dbl (4): albumin, ast, bili, protime
#>   • int (2): age, chol
#> • Strata: status
#> • Causes (2):
#>   • 1 (Liver transplantation): 18 (6.5%)
#>   • 2 (Death without transplantation): 111 (40.2%)
#> • Censored: 147 (53.3%)

# Create training and test sets
set.seed(42L)
part = partition(task)

# Define the learner
learner = lrn("cmprsk.aalen")

# Train on the training set
learner$train(task, row_ids = part$train)
learner$native_model
#> Call: survfit(formula = task$formula("1"), data = task$data(cols = task$target_names), 
#>     weights = NULL)
#> 
#>                                 n nevent     rmean se(rmean)*
#> (s0)                          184      0 2769.9515  123.93141
#> Liver transplantation         184     12  243.9978   68.02923
#> Death without transplantation 184     74 1542.0507  123.46668
#>    *restricted mean time in state (max time = 4556 )

# Predict CIFs for the test set
predictions = learner$predict(task, row_ids = part$test)
predictions
#> 
#> ── <PredictionCompRisks> for 92 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        1  400     2 <list[2]>
#>       10 3762     2 <list[2]>
#>       16  131     2 <list[2]>
#>      ---  ---   ---       ---
#>      157 2241     1 <list[2]>
#>      208  837     1 <list[2]>
#>      213 1435     1 <list[2]>

# Score predictions
predictions$score()
#> cmprsk.ibs 
#>  0.1775434 
```
