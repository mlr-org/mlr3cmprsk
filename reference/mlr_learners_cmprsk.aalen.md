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

Other competing risk learners:
[`mlr_learners_cmprsk.fg`](https://mlr3cmprsk.mlr-org.com/reference/mlr_learners_cmprsk.fg.md)

## Super classes

[`mlr3::Learner`](https://mlr3.mlr-org.com/reference/Learner.html) -\>
[`mlr3cmprsk::LearnerCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md)
-\> `LearnerCompRisksAalenJohansen`

## Active bindings

- `native_model`:

  ([survival::survfit](https://rdrr.io/pkg/survival/man/survfit.html))  
  The fitted model.

## Methods

### Public methods

- [`LearnerCompRisksAalenJohansen$new()`](#method-LearnerCompRisksAalenJohansen-new)

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

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    LearnerCompRisksAalenJohansen$new()

------------------------------------------------------------------------

### Method `importance()`

All features have a score of `0` for this learner. This method exists
solely for compatibility with the `mlr3` ecosystem, as this learner is
used as a fallback for other survival learners that require an
`importance()` method.

#### Usage

    LearnerCompRisksAalenJohansen$importance()

#### Returns

Named [`numeric()`](https://rdrr.io/r/base/numeric.html).

------------------------------------------------------------------------

### Method `selected_features()`

Selected features are always the empty set for this learner. This method
is implemented only for compatibility with the `mlr3` API, as this
learner does not perform feature selection.

#### Usage

    LearnerCompRisksAalenJohansen$selected_features()

#### Returns

`character(0)`.

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
# Define the Learner (Aalen-Johansen/AJ estimator)
learner = lrn("cmprsk.aalen")
learner
#> 
#> ── <LearnerCompRisksAalenJohansen> (cmprsk.aalen): Aalen-Johansen Estimator ────
#> • Model: -
#> • Parameters: list()
#> • Packages: mlr3, mlr3cmprsk, and survival
#> • Predict Types: [cif]
#> • Feature Types: logical, integer, numeric, and factor
#> • Encapsulation: none (fallback: -)
#> • Properties: importance, missings, selected_features, and weights
#> • Other settings: use_weights = 'use', predict_raw = 'FALSE'

# Define a Task
task = tsk("pbc")

# Stratification based on event
task$set_col_roles(cols = "status", add_to = "stratum")

# Create train and test set
part = partition(task)

# Train the learner on the training set
learner$train(task, row_ids = part$train)
learner$native_model
#> Call: survfit(formula = task$formula(1), data = task$data(cols = task$target_names), 
#>     weights = NULL)
#> 
#>        n nevent     rmean se(rmean)*
#> (s0) 184      0 90.486196   4.278051
#> 1    184     12  7.761797   2.158935
#> 2    184     74 49.752008   4.282081
#>    *restricted mean time in state (max time = 148 )

# Make predictions for the test set
predictions = learner$predict(task, row_ids = part$test)
predictions
#> 
#> ── <PredictionCompRisks> for 92 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        4   63     2 <list[2]>
#>        7   81     2 <list[2]>
#>        8   78     2 <list[2]>
#>      ---  ---   ---       ---
#>      139   81     1 <list[2]>
#>      256   29     1 <list[2]>
#>      262   17     1 <list[2]>

# Score the predictions
# AJ has random discriminative performance
predictions$score(msr("cmprsk.auc", time = 100))
#> cmprsk.auc 
#>        0.5 

# Prediction error (Brier score) at specific time point
# BS(t) => weighted mean score across causes (default)
predictions$score(msr("cmprsk.brier", time = 100))
#> cmprsk.brier 
#>    0.2248736 
```
