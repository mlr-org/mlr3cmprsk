# Competing Risks Integrated Brier Score

Calculates the integrated competing-risks prediction error or Brier
Score (IBS) at given times, using IPCW as described in Schoop et al.
(2011).

## Details

By default, this measure returns a **cause-independent IBS** (or
all-cause) score, calculated as a weighted average of the cause-specific
IBS (Integrated Brier Score) scores. The weights correspond to the
relative event frequencies of each cause, following Equation (8) in
Spitoni et al. (2018). User-supplied weights are also supported.

Alternatively, users can obtain the **cause-specific IBS** for any
individual cause by specifying the `cause` parameter.

## Dictionary

This [Measure](https://mlr3.mlr-org.com/reference/Measure.html) can be
instantiated via the
[dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
[mlr_measures](https://mlr3.mlr-org.com/reference/mlr_measures.html) or
with the associated sugar function
[msr()](https://mlr3.mlr-org.com/reference/mlr_sugar.html):

    mlr_measures$get("cmprsk.ibs")
    msr("cmprsk.ibs")

## Meta Information

- Task type: “cmprsk”

- Range: \\\[0, \infty)\\

- Minimize: TRUE

- Average: macro

- Required Prediction: “cif”

- Required Packages: [mlr3](https://CRAN.R-project.org/package=mlr3),
  [mlr3cmprsk](https://CRAN.R-project.org/package=mlr3cmprsk),
  [riskRegression](https://CRAN.R-project.org/package=riskRegression)

## Parameters

|               |         |         |                  |
|---------------|---------|---------|------------------|
| Id            | Type    | Default | Range            |
| cause         | integer | \-      | \\\[1, \infty)\\ |
| cause_weights | untyped | NULL    | \-               |
| times         | untyped | NULL    | \-               |

## Parameter details

- `cause` (`numeric(1)|"mean"`)  
  Integer number indicating which cause to use. Default value is
  `"mean"` which returns an event-frequency weighted mean of the
  cause-specific Brier scores.

- `cause_weights`
  ([`numeric()`](https://rdrr.io/r/base/numeric.html)\|`NULL`)  
  Optional custom weights for `cause = "mean"`. If `NULL`, observed
  cause frequencies **from the test data** are used. The weights must be
  non-negative, sum to 1 and match the number of causes 1-1, i.e. first
  weight for first cause, second weight for second cause, etc. See
  Spitoni et al. (2018), Equation (8) for a similar weighting scheme.

- `times` (`numeric(1)`)  
  Time points used for numerical integration. If `NULL`, all unique
  times from the test set are used.

## References

Schoop, Roland, Beyersmann, Jan, Schumacher, Martin, Binder, Harald
(2011). “Quantifying the predictive accuracy of time-to-event models in
the presence of competing risks.” *Biometrical Journal*, **53**(1),
88–112. <https://doi.org/10.1002/BIMJ.201000073>.

## Super classes

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
[`MeasureCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/MeasureCompRisks.md)
-\> `MeasureCompRisksIntegratedBrierScore`

## Methods

### Public methods

- [`MeasureCompRisksIntegratedBrierScore$new()`](#method-MeasureCompRisksIntegratedBrierScore-initialize)

- [`MeasureCompRisksIntegratedBrierScore$clone()`](#method-MeasureCompRisksIntegratedBrierScore-clone)

Inherited methods

- [`mlr3::Measure$aggregate()`](https://mlr3.mlr-org.com/reference/Measure.html#method-aggregate)
- [`mlr3::Measure$format()`](https://mlr3.mlr-org.com/reference/Measure.html#method-format)
- [`mlr3::Measure$help()`](https://mlr3.mlr-org.com/reference/Measure.html#method-help)
- [`mlr3::Measure$obs_loss()`](https://mlr3.mlr-org.com/reference/Measure.html#method-obs_loss)
- [`mlr3::Measure$print()`](https://mlr3.mlr-org.com/reference/Measure.html#method-print)
- [`mlr3::Measure$score()`](https://mlr3.mlr-org.com/reference/Measure.html#method-score)

------------------------------------------------------------------------

### `MeasureCompRisksIntegratedBrierScore$new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    MeasureCompRisksIntegratedBrierScore$new()

------------------------------------------------------------------------

### `MeasureCompRisksIntegratedBrierScore$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCompRisksIntegratedBrierScore$clone(deep = FALSE)

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
#> -0.103500 -1.222000 -0.004281 -0.051520  0.001392  0.081580 
#> standard errors:
#> [1] 0.024890 0.611900 0.004552 0.079210 0.001129 0.365900
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 3.2e-05 4.6e-02 3.5e-01 5.2e-01 2.2e-01 8.2e-01 
#> 
#> $`2`
#> convergence:  TRUE 
#> coefficients:
#>        age    albumin        ast       bili       chol    protime 
#>  0.0451100 -1.1070000  0.0045640  0.1449000 -0.0006038  0.1743000 
#> standard errors:
#> [1] 0.0132800 0.2790000 0.0019030 0.0274700 0.0006429 0.1209000
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 6.8e-04 7.3e-05 1.6e-02 1.3e-07 3.5e-01 1.5e-01 
#> 
#> attr(,"class")
#> [1] "fine_gray"

# Make predictions for the test set
predictions = learner$predict(task, row_ids = part$test)
#> Warning: 
#> ✖ Predicted cause-specific CIFs are not jointly coherent: their sum exceeds 1
#>   for some observations/time points.
#> → Class: Mlr3WarningCIFSumExceedsOne
predictions
#> 
#> ── <PredictionCompRisks> for 92 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        3   33     2 <list[2]>
#>        9    1     2 <list[2]>
#>       11    9     2 <list[2]>
#>      ---  ---   ---       ---
#>      221   24     1 <list[2]>
#>      231   35     1 <list[2]>
#>      253   35     1 <list[2]>

# Score the predictions
# AUC(t = 100), weighted mean score across causes (default)
predictions$score(msr("cmprsk.auc", cause = "mean", time = 100))
#> cmprsk.auc 
#>  0.8836612 

# AUC(t = 100), with user-specified weights
predictions$score(msr("cmprsk.auc", cause = "mean", cause_weights = c(0.2, 0.8),
  time = 100))
#> cmprsk.auc 
#>  0.8651568 

# AUC(t = 100), 1st cause
predictions$score(msr("cmprsk.auc", cause = 1, time = 100))
#> cmprsk.auc 
#>  0.6203302 

# AUC(t = 100), 2nd cause
predictions$score(msr("cmprsk.auc", cause = 2, time = 100))
#> cmprsk.auc 
#>  0.9263635 

# Prediction error (Brier score) at specific time point
# BS(t = 100) => weighted mean score across causes (default)
predictions$score(msr("cmprsk.brier", time = 100))
#> cmprsk.brier 
#>    0.1192584 

# BS(t = 100), 1st cause
predictions$score(msr("cmprsk.brier", cause = 1, time = 100))
#> cmprsk.brier 
#>   0.06631812 

# BS(t = 100), 2nd cause
predictions$score(msr("cmprsk.brier", cause = 2, time = 100))
#> cmprsk.brier 
#>    0.1278433 
```
