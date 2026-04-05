# Blanche's AUC Competing Risks Measure

Calculates the time-dependent ROC-AUC at a **specific time point**, as
described in Blanche et al. (2013).

By default, this measure returns a **cause-independent AUC(t)** score,
calculated as a weighted average of the cause-specific AUCs. The weights
correspond to the relative event frequencies of each cause, following
Equation (7) in Heyard et al. (2020).

Alternatively, users can obtain the **cause-specific AUC(t)** for any
individual cause by specifying the `cause` parameter.

## Details

Calls
[`riskRegression::Score()`](https://rdrr.io/pkg/riskRegression/man/Score.html)
with:

- `metric = "auc"`

- `cens.method = "ipcw"`

- `cens.model = "km"`

Notes on the `riskRegression` implementation:

1.  IPCW weights are estimated using the **test data only**.

2.  No extrapolation is supported: if `time_horizon` exceeds the maximum
    observed time on the test data, an error is thrown.

3.  The choice of `time_horizon` is critical: if, at that time, no
    events of a given cause have occurred and all predicted CIFs are
    zero, `riskRegression` will return `NaN` for that cause-specific AUC
    (and subsequently for the summary AUC).

## Dictionary

This [Measure](https://mlr3.mlr-org.com/reference/Measure.html) can be
instantiated via the
[dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
[mlr_measures](https://mlr3.mlr-org.com/reference/mlr_measures.html) or
with the associated sugar function
[msr()](https://mlr3.mlr-org.com/reference/mlr_sugar.html):

    mlr_measures$get("cmprsk.auc")
    msr("cmprsk.auc")

## Meta Information

- Task type: “cmprsk”

- Range: \\\[0, 1\]\\

- Minimize: FALSE

- Average: macro

- Required Prediction: “cif”

- Required Packages: [mlr3](https://CRAN.R-project.org/package=mlr3),
  [mlr3cmprsk](https://CRAN.R-project.org/package=mlr3cmprsk),
  [riskRegression](https://CRAN.R-project.org/package=riskRegression)

## Parameters

|              |         |         |                  |
|--------------|---------|---------|------------------|
| Id           | Type    | Default | Range            |
| cause        | integer | \-      | \\\[1, \infty)\\ |
| time_horizon | numeric | NULL    | \\\[0, \infty)\\ |

## Parameter details

- `cause` (`numeric(1)|"mean"`)  
  Integer number indicating which cause to use. Default value is
  `"mean"` which returns a weighted mean of the cause-specific AUCs.

- `time_horizon` (`numeric(1)`)  
  Single time point at which to return the score. If `NULL`, the
  **median time point** from the test set is used.

## References

Blanche, Paul, Dartigues, Francois J, Jacqmin-Gadda, Helene (2013).
“Estimating and comparing time-dependent areas under receiver operating
characteristic curves for censored event times with competing risks.”
*Statistics in Medicine*, **32**(30), 5381–5397. ISSN 1097-0258,
[doi:10.1002/SIM.5958](https://doi.org/10.1002/SIM.5958) ,
<https://onlinelibrary.wiley.com/doi/10.1002/sim.5958>.

Heyard, Rachel, Timsit, Jean-Francois, Held, Leonhard (2020).
“Validation of discrete time-to-event prediction models in the presence
of competing risks.” *Biometrical Journal*, **62**(3), 643–657.
<https://doi.org/10.1002/BIMJ.201800293>.

## Super classes

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
[`mlr3cmprsk::MeasureCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/MeasureCompRisks.md)
-\> `MeasureCompRisksAUC`

## Methods

### Public methods

- [`MeasureCompRisksAUC$new()`](#method-MeasureCompRisksAUC-new)

- [`MeasureCompRisksAUC$clone()`](#method-MeasureCompRisksAUC-clone)

Inherited methods

- [`mlr3::Measure$aggregate()`](https://mlr3.mlr-org.com/reference/Measure.html#method-aggregate)
- [`mlr3::Measure$format()`](https://mlr3.mlr-org.com/reference/Measure.html#method-format)
- [`mlr3::Measure$help()`](https://mlr3.mlr-org.com/reference/Measure.html#method-help)
- [`mlr3::Measure$obs_loss()`](https://mlr3.mlr-org.com/reference/Measure.html#method-obs_loss)
- [`mlr3::Measure$print()`](https://mlr3.mlr-org.com/reference/Measure.html#method-print)
- [`mlr3::Measure$score()`](https://mlr3.mlr-org.com/reference/Measure.html#method-score)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    MeasureCompRisksAUC$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCompRisksAUC$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Define the Learner
learner = lrn("cmprsk.fg")
learner
#> 
#> ── <LearnerCompRisksFineGray> (cmprsk.fg): Competing Risks Regression: Fine-Gray
#> • Model: -
#> • Parameters: list()
#> • Packages: mlr3, mlr3cmprsk, and cmprsk
#> • Predict Types: [cif]
#> • Feature Types: logical, integer, and numeric
#> • Encapsulation: none (fallback: -)
#> • Properties:
#> • Other settings: use_weights = 'error', predict_raw = 'FALSE'

# Define a Task
task = tsk("pbc")

# Subset task features as Fine-Gray model doesn't accept factors
# Encode factors with `mlr3pipelines::po("encode")` if needed
feats = c("age", "chol", "albumin", "ast", "bili", "protime")
task$select(feats)

# Stratification based on event
task$set_col_roles(cols = "status", add_to = "stratum")

# Create train and test set
part = partition(task)

# Train the learner on the training set
learner$train(task, row_ids = part$train)
learner$native_model
#> $`1`
#> convergence:  TRUE 
#> coefficients:
#>       age   albumin       ast      bili      chol   protime 
#> -0.081820 -0.233000  0.002990  0.028350  0.001049 -0.938500 
#> standard errors:
#> [1] 0.024320 1.002000 0.005755 0.130700 0.001832 0.536000
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 0.00077 0.82000 0.60000 0.83000 0.57000 0.08000 
#> 
#> $`2`
#> convergence:  TRUE 
#> coefficients:
#>        age    albumin        ast       bili       chol    protime 
#>  5.774e-02 -1.034e+00  8.724e-03  8.646e-02  1.455e-05  2.868e-01 
#> standard errors:
#> [1] 0.0143300 0.2537000 0.0021420 0.0198900 0.0004309 0.1157000
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 5.6e-05 4.6e-05 4.7e-05 1.4e-05 9.7e-01 1.3e-02 
#> 
#> attr(,"class")
#> [1] "fine_gray"

# Make predictions for the test set
predictions = learner$predict(task, row_ids = part$test)
predictions
#> 
#> ── <PredictionCompRisks> for 92 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        1   13     2 <list[2]>
#>       20   22     2 <list[2]>
#>       25    2     2 <list[2]>
#>      ---  ---   ---       ---
#>      221   24     1 <list[2]>
#>      229   42     1 <list[2]>
#>      262   17     1 <list[2]>

# Score the predictions
# AUC(t = 100), weighted mean score across causes (default)
predictions$score(msr("cmprsk.auc", cause = "mean", time_horizon = 100))
#> cmprsk.auc 
#>  0.8275552 

# AUC(t = 100), 1st cause
predictions$score(msr("cmprsk.auc", cause = 1, time_horizon = 100))
#> cmprsk.auc 
#>  0.7682148 

# AUC(t = 100), 2nd cause
predictions$score(msr("cmprsk.auc", cause = 2, time_horizon = 100))
#> cmprsk.auc 
#>  0.8371779 
```
