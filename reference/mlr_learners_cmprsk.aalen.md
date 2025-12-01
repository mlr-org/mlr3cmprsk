# Aalen Johansen Competing Risks Learner

This learner estimates the Cumulative Incidence Function (CIF) for
competing risks using the empirical Aalen-Johansen (AJ) estimator.

Transition probabilities to each event are computed from the training
data via the
[survfit](https://rdrr.io/pkg/survival/man/survfit.formula.html)
function and predictions are made at all unique times (both events and
censoring) observed in the training set.

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

|       |         |         |             |
|-------|---------|---------|-------------|
| Id    | Type    | Default | Levels      |
| model | logical | FALSE   | TRUE, FALSE |

## References

Aalen, O O, Johansen, Soren (1978). “An empirical transition matrix for
non-homogeneous Markov chains based on censored observations.”
*Scandinavian journal of statistics*, 141–150.

## Super classes

[`mlr3::Learner`](https://mlr3.mlr-org.com/reference/Learner.html) -\>
[`mlr3cmprsk::LearnerCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md)
-\> `LearnerCompRisksAalenJohansen`

## Methods

### Public methods

- [`LearnerCompRisksAalenJohansen$new()`](#method-LearnerCompRisksAalenJohansen-new)

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
- [`mlr3::Learner$selected_features()`](https://mlr3.mlr-org.com/reference/Learner.html#method-selected_features)
- [`mlr3::Learner$train()`](https://mlr3.mlr-org.com/reference/Learner.html#method-train)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    LearnerCompRisksAalenJohansen$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    LearnerCompRisksAalenJohansen$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(mlr3)

# Define the Learner
learner = lrn("cmprsk.aalen")
learner
#> 
#> ── <LearnerCompRisksAalenJohansen> (cmprsk.aalen): Aalen Johansen Estimator ────
#> • Model: -
#> • Parameters: list()
#> • Packages: mlr3, mlr3cmprsk, and survival
#> • Predict Types: [cif]
#> • Feature Types: logical, integer, numeric, and factor
#> • Encapsulation: none (fallback: -)
#> • Properties: weights
#> • Other settings: use_weights = 'use'

# Define a Task
task = tsk("pbc")

# Stratification based on event
task$set_col_roles(cols = "status", add_to = "stratum")

# Create train and test set
part = partition(task)

# Train the learner on the training set
learner$train(task, row_ids = part$train)
learner$model
#> Call: survfit(formula = task$formula(1), data = task$data(cols = task$target_names))
#> 
#>        n nevent     rmean se(rmean)*
#> (s0) 184      0 90.075885   4.316580
#> 1    184     12  8.034342   2.238112
#> 2    184     74 50.889773   4.306029
#>    *restricted mean time in state (max time = 149 )

# Make predictions for the test set
predictions = learner$predict(task, row_ids = part$test)
predictions
#> 
#> ── <PredictionCompRisks> for 92 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        3   33     2 <list[2]>
#>        4   63     2 <list[2]>
#>        7   81     2 <list[2]>
#>      ---  ---   ---       ---
#>      157   73     1 <list[2]>
#>      213   47     1 <list[2]>
#>      231   35     1 <list[2]>

# Score the predictions
# AUC(t = 100), weighted mean score across causes (default)
predictions$score(msr("cmprsk.auc", cause = "mean", time_horizon = 100))
#> cmprsk.auc 
#>        0.5 

# AUC(t = 100), 1st cause
predictions$score(msr("cmprsk.auc", cause = 1, time_horizon = 100))
#> cmprsk.auc 
#>        0.5 

# AUC(t = 100), 2nd cause
predictions$score(msr("cmprsk.auc", cause = 2, time_horizon = 100))
#> cmprsk.auc 
#>        0.5 
```
