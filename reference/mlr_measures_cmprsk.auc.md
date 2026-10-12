# AUC(t) Competing Risks Measure

Calculates the time-dependent ROC-AUC at a **specific time point**, as
described in Blanche et al. (2013), Equation 4. Controls include
subjects who survive beyond the time horizon and those who experience a
competing event before the horizon.

## Details

By default, this measure returns a **cause-independent AUC(t)** score,
calculated as a weighted average of the cause-specific AUCs. The weights
correspond to the relative event frequencies of each cause, following
Equation 7 in Heyard et al. (2020). User-supplied weights are also
supported through `cause_weights`. See the **Cause weights** section for
weighting rules.

Alternatively, users can obtain the **cause-specific AUC(t)** for any
individual cause by specifying the `cause` parameter.

Calls
[`riskRegression::Score()`](https://rdrr.io/pkg/riskRegression/man/Score.html)
with:

- `metric = "auc"`

- `cens.method = "ipcw"`

- `cens.model = "km"`

Notes on the `riskRegression` implementation:

1.  IPCW weights are estimated using the **test data only**, so smaller
    test sets may lead to less stable estimates.

2.  Scoring at a `time` beyond the maximum observed test-set time
    produces an input error.

3.  AUC(t) is undefined if no events of the requested cause are observed
    at or before `time`, or if no controls are available at that time.
    In these cases, `riskRegression` returns `NaN` for the
    cause-specific AUC.

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

|               |         |         |                  |
|---------------|---------|---------|------------------|
| Id            | Type    | Default | Range            |
| cause         | integer | \-      | \\\[1, \infty)\\ |
| cause_weights | untyped | NULL    | \-               |
| time          | numeric | NULL    | \\\[0, \infty)\\ |

## Cause weights

Cause weights are used only for `cause = "mean"`. The `cause_weights`
parameter is ignored when scoring a specific cause.

With `cause_weights = NULL`, weights are the relative frequencies of
observed non-censored events from the test set. Causes without observed
events receive zero weight, are listed in a warning and are skipped when
calculating the mean score. If no events from any cause are observed,
weights are undefined, and the measure warns and returns `NA_real_`.

Alternatively, the user can supply custom weights via `cause_weights`.
Weights must be finite, non-negative, sum to 1, and contain one entry
per predicted cause. Entries must match the order of the predicted CIFs
cause names. If any user-supplied weight happens to be zero, it is
skipped silently.

In general, non-finite scores from positive-weight causes propagate to
the mean, causing the measure to return `NaN` and a warning identifies
the causes with non-finite scores.

## Parameter details

- `cause` (`numeric(1)|"mean"`)  
  Integer number indicating which cause to use. Default value is
  `"mean"` which returns an event-frequency weighted mean of the
  cause-specific AUCs.

- `cause_weights`
  ([`numeric()`](https://rdrr.io/r/base/numeric.html)\|`NULL`)  
  Optional custom weights for `cause = "mean"`. See the **Cause
  weights** section for weighting rules.

- `time` (`numeric(1)`)  
  Single time point at which to return the score. If `NULL`, the
  **median observed time point** from the test set is used.

## References

Blanche, Paul, Dartigues, Francois J, Jacqmin-Gadda, Helene (2013).
“Estimating and comparing time-dependent areas under receiver operating
characteristic curves for censored event times with competing risks.”
*Statistics in Medicine*, **32**(30), 5381–5397. ISSN 1097-0258,
[doi:10.1002/SIM.5958](https://doi.org/10.1002/SIM.5958) ,
<https://onlinelibrary.wiley.com/doi/10.1002/sim.5958>.

Spitoni, Claudia, Lammens, Valerie, Putter, Hein (2018). “Prediction
errors for state occupation and transition probabilities in multi-state
models.” *Biometrical Journal*, **60**(1), 34–48. ISSN 0323-3847,
[doi:10.1002/BIMJ.201600191](https://doi.org/10.1002/BIMJ.201600191) ,
<https://doi.org/10.1002/BIMJ.201600191>.

Heyard, Rachel, Timsit, Jean-Francois, Held, Leonhard (2020).
“Validation of discrete time-to-event prediction models in the presence
of competing risks.” *Biometrical Journal*, **62**(3), 643–657.
<https://doi.org/10.1002/BIMJ.201800293>.

## Super classes

[`mlr3::Measure`](https://mlr3.mlr-org.com/reference/Measure.html) -\>
[`MeasureCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/MeasureCompRisks.md)
-\> `MeasureCompRisksAUC`

## Methods

### Public methods

- [`MeasureCompRisksAUC$new()`](#method-MeasureCompRisksAUC-initialize)

- [`MeasureCompRisksAUC$clone()`](#method-MeasureCompRisksAUC-clone)

Inherited methods

- [`mlr3::Measure$aggregate()`](https://mlr3.mlr-org.com/reference/Measure.html#method-aggregate)
- [`mlr3::Measure$format()`](https://mlr3.mlr-org.com/reference/Measure.html#method-format)
- [`mlr3::Measure$help()`](https://mlr3.mlr-org.com/reference/Measure.html#method-help)
- [`mlr3::Measure$obs_loss()`](https://mlr3.mlr-org.com/reference/Measure.html#method-obs_loss)
- [`mlr3::Measure$print()`](https://mlr3.mlr-org.com/reference/Measure.html#method-print)
- [`mlr3::Measure$score()`](https://mlr3.mlr-org.com/reference/Measure.html#method-score)

------------------------------------------------------------------------

### `MeasureCompRisksAUC$new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    MeasureCompRisksAUC$new()

------------------------------------------------------------------------

### `MeasureCompRisksAUC$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MeasureCompRisksAUC$clone(deep = FALSE)

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

# AUC at the median observed test-set time,
# weighted by event frequencies
predictions$score(msr("cmprsk.auc"))
#> cmprsk.auc 
#>  0.8691053 

# AUC at 100 months, weighted by event frequencies
predictions$score(msr("cmprsk.auc", time = 100))
#> cmprsk.auc 
#>  0.8279221 

# AUC at 100 months, with equal weights for both causes
predictions$score(msr("cmprsk.auc", time = 100, cause_weights = c(0.5, 0.5)))
#> cmprsk.auc 
#>  0.8219801 

# AUC at 100 months, with custom weights for transplant and death
predictions$score(msr("cmprsk.auc", time = 100, cause_weights = c(0.2, 0.8)))
#> cmprsk.auc 
#>  0.8269254 

# AUC at 100 months, for transplant only
predictions$score(msr("cmprsk.auc", time = 100, cause = 1))
#> cmprsk.auc 
#>   0.813738 

# AUC at 100 months, for death only
predictions$score(msr("cmprsk.auc", time = 100, cause = 2))
#> cmprsk.auc 
#>  0.8302222 
```
