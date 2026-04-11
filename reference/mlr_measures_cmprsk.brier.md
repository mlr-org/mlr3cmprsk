# Brier Score Competing Risks Measure

Calculates the competing risks prediction error (Brier score, BS) at a
**specific time point**, using IPCW as described in Schopp et al.
(2011).

## Details

By default, this measure returns a **cause-independent BS(t)** score,
calculated as a weighted average of the cause-specific Brier scores. The
weights correspond to the relative event frequencies of each cause,
following Equation (8) in Spitoni et al. (2018). User-supplied weights
are also supported. Alternatively, users can obtain the
**cause-specific** Brier score for any individual cause by specifying
the `cause` parameter.

Calls
[`riskRegression::Score()`](https://rdrr.io/pkg/riskRegression/man/Score.html)
with:

- `metric = "brier"`

- `cens.method = "ipcw"`

- `cens.model = "km"`

Notes on the `riskRegression` implementation:

1.  IPCW weights are estimated using the **test data only**, so smaller
    test sets may lead to less stable estimates.

2.  No extrapolation is supported: if `time` exceeds the maximum
    observed time on the test data, an error is thrown.

## Dictionary

This [Measure](https://mlr3.mlr-org.com/reference/Measure.html) can be
instantiated via the
[dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
[mlr_measures](https://mlr3.mlr-org.com/reference/mlr_measures.html) or
with the associated sugar function
[msr()](https://mlr3.mlr-org.com/reference/mlr_sugar.html):

    mlr_measures$get("cmprsk.brier")
    msr("cmprsk.brier")

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
| time          | numeric | NULL    | \\\[0, \infty)\\ |

## Parameter details

- `cause` (`numeric(1)|"mean"`)  
  Integer number indicating which cause to use. Default value is
  `"mean"` which returns an event-frequency weighted mean of the
  cause-specific Brier scores.

- `cause_weights` ([`numeric()`](https://rdrr.io/r/base/numeric.html) \|
  `NULL`)  
  Optional custom weights for `cause = "mean"`. If `NULL`, observed
  cause frequencies in the test data are used. The weights must be
  non-negative, sum to 1 and match the number of causes 1-1, i.e. first
  weight for first cause, second weight for second cause, etc. See
  Spitoni et al. (2018), Equation (8) for a similar weighting scheme.

- `time` (`numeric(1)`)  
  Single time point at which to return the score. If `NULL`, the
  **median observed time point** from the test set is used.

## References

Schoop, Roland, Beyersmann, Jan, Schumacher, Martin, Binder, Harald
(2011). “Quantifying the predictive accuracy of time-to-event models in
the presence of competing risks.” *Biometrical Journal*, **53**(1),
88–112. <https://doi.org/10.1002/BIMJ.201000073>.

Spitoni, Claudia, Lammens, Valerie, Putter, Hein (2018). “Prediction
errors for state occupation and transition probabilities in multi-state
models.” *Biometrical Journal*, **60**(1), 34–48. ISSN 0323-3847,
[doi:10.1002/BIMJ.201600191](https://doi.org/10.1002/BIMJ.201600191) ,
<https://doi.org/10.1002/BIMJ.201600191>.

## Super classes

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
[`mlr3cmprsk::MeasureCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/MeasureCompRisks.md)
-\> `MeasureCompRisksBrierScore`

## Methods

### Public methods

- [`MeasureCompRisksBrierScore$new()`](#method-MeasureCompRisksBrierScore-new)

- [`MeasureCompRisksBrierScore$clone()`](#method-MeasureCompRisksBrierScore-clone)

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

    MeasureCompRisksBrierScore$new()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCompRisksBrierScore$clone(deep = FALSE)

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
#> -0.117600 -0.152500 -0.006422  0.011550  0.001069 -0.512700 
#> standard errors:
#> [1] 0.025500 0.843100 0.004029 0.098670 0.001572 0.372900
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 4.0e-06 8.6e-01 1.1e-01 9.1e-01 5.0e-01 1.7e-01 
#> 
#> $`2`
#> convergence:  TRUE 
#> coefficients:
#>       age   albumin       ast      bili      chol   protime 
#>  0.036580 -1.230000  0.004897  0.089950 -0.000172  0.506000 
#> standard errors:
#> [1] 0.0141600 0.2469000 0.0020640 0.0221700 0.0004223 0.1372000
#> two-sided p-values:
#>     age albumin     ast    bili    chol protime 
#> 9.8e-03 6.3e-07 1.8e-02 5.0e-05 6.8e-01 2.3e-04 
#> 
#> attr(,"class")
#> [1] "fine_gray"

# Make predictions for the test set
predictions = learner$predict(task, row_ids = part$test)
predictions
#> 
#> ── <PredictionCompRisks> for 92 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        3   33     2 <list[2]>
#>        9    1     2 <list[2]>
#>       16    4     2 <list[2]>
#>      ---  ---   ---       ---
#>      256   29     1 <list[2]>
#>      260   28     1 <list[2]>
#>      262   17     1 <list[2]>

# Score the predictions
# AUC(t = 100), weighted mean score across causes (default)
predictions$score(msr("cmprsk.auc", cause = "mean", time = 100))
#> cmprsk.auc 
#>  0.6810654 

# AUC(t = 100), with user-specified weights
predictions$score(msr("cmprsk.auc", cause = "mean", cause_weights = c(0.2, 0.8),
  time = 100))
#> cmprsk.auc 
#>  0.6874814 

# AUC(t = 100), 1st cause
predictions$score(msr("cmprsk.auc", cause = 1, time = 100))
#> cmprsk.auc 
#>  0.7723702 

# AUC(t = 100), 2nd cause
predictions$score(msr("cmprsk.auc", cause = 2, time = 100))
#> cmprsk.auc 
#>  0.6662592 

# Prediction error (Brier score) at specific time point
# BS(t = 100) => weighted mean score across causes (default)
predictions$score(msr("cmprsk.brier", time = 100))
#> cmprsk.brier 
#>    0.2280758 

# BS(t = 100), 1st cause
predictions$score(msr("cmprsk.brier", cause = 1, time = 100))
#> cmprsk.brier 
#>   0.06184316 

# BS(t = 100), 2nd cause
predictions$score(msr("cmprsk.brier", cause = 2, time = 100))
#> cmprsk.brier 
#>    0.2550324 
```
