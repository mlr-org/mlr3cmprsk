# Integrated Brier Score Competing Risks Measure

Calculates the integrated competing risks prediction error (integrated
Brier score, IBS) using IPCW as described in Schoop et al. (2011).

## Details

By default, this measure returns a **cause-independent IBS** (or
all-cause) score, calculated as a weighted average of the cause-specific
integrated Brier scores. The weights correspond to the relative event
frequencies of each cause, following Equation (8) in Spitoni et al.
(2018). User-supplied weights are also supported through
`cause_weights`. See the **Cause weights** section for weighting rules.

Alternatively, users can obtain the **cause-specific IBS** for any
individual cause by specifying the `cause` parameter.

Calls
[`riskRegression::Score()`](https://rdrr.io/pkg/riskRegression/man/Score.html)
with:

- `metric = "brier"`

- `summary = "ibs"`

- `cens.method = "ipcw"`

- `cens.model = "km"`

Notes on the `riskRegression` implementation:

1.  IPCW weights are estimated using the **test data only**, so smaller
    test sets may lead to less stable estimates.

2.  Evaluation is limited to the maximum observed test-set follow-up
    time. See the **Integration grid** section for how this restriction
    is applied.

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
| ntimes        | untyped | 100L    | \-               |
| t_max         | untyped | NULL    | \-               |
| t_quantile    | untyped | NULL    | \-               |

## Parameter details

- `cause` (`numeric(1)|"mean"`)  
  Integer number indicating which cause to use. Default value is
  `"mean"` which returns an event-frequency weighted mean of the
  cause-specific integrated Brier scores.

- `cause_weights`
  ([`numeric()`](https://rdrr.io/r/base/numeric.html)\|`NULL`)  
  Optional custom weights for `cause = "mean"`. See the **Cause
  weights** section for weighting rules.

- `times` ([`numeric()`](https://rdrr.io/r/base/numeric.html)\|`NULL`)  
  Explicit integration grid, supplied as a sorted vector of at least two
  distinct, finite, non-negative time points. Default is `NULL`, which
  uses an automatically generated grid. `t_max` and `t_quantile` must
  both be `NULL` when supplying explicit `times`.

- `ntimes` (`integer(1)`)  
  Number of points in an automatically constructed integration grid,
  including time 0 and the upper integration horizon. Must be at least
  2; default is 100. Ignored when supplying explicit `times`.

- `t_max` (`numeric(1)`\|`NULL`)  
  Finite, non-negative upper integration horizon; default is `NULL`.
  Mutually exclusive with `t_quantile`.

- `t_quantile` (`numeric(1)`\|`NULL`)  
  Quantile probability of observed test-set follow-up times used to
  determine the upper integration horizon. Default is `NULL`, which uses
  the 90th percentile. Mutually exclusive with `t_max`.

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

## Integration grid

The integration grid determines the evaluation times for the IBS. Its
largest time point is the **effective integration horizon**. The grid is
the same for all causes.

If the user explicitly provides `times`, the supplied grid is used
directly. Points beyond the maximum test-set follow-up are removed with
a warning due to the limitations of
[`riskRegression::Score()`](https://rdrr.io/pkg/riskRegression/man/Score.html).
At least two distinct evaluation times must remain.

When `times = NULL` we construct a time grid consisting of `ntimes`
equally spaced time points between time 0 and an upper time horizon. By
default, the horizon is chosen as the time point corresponding to the
**90th percentile** of observed follow-up times (including both events
and censored observations) in the test set. The user can change that
percentile with `t_quantile`, or specify a fixed horizon with `t_max`.
If `t_max` exceeds the maximum test-set follow-up, it is reduced to that
maximum to satisfy the restrictions of `riskRegression`, and a warning
reports the effective horizon. In any case, the resulting integration
grid will always have exactly `ntimes` points and its construction is
completely independent of the time grids of the predicted CIFs (and
therefore of the learners used to make these predictions).

The choice for the default 90th percentile is for minimizing the
influence of extreme evaluation times, which may cause **CIF
extrapolation** (when the integration grid has times larger than the
maximum anchor of the CIF time grid) and issues with **large IPCW
weights**.

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

# IBS over 100 equally spaced points from 0 to the 90th test-set follow-up percentile,
# weighted by event frequencies
predictions$score(msr("cmprsk.ibs"))
#> cmprsk.ibs 
#>  0.1116802 

# IBS with an upper integration horizon of 100 months
predictions$score(msr("cmprsk.ibs", t_max = 100))
#> cmprsk.ibs 
#>  0.1036116 

# IBS up to the 85th percentile of test-set follow-up times
predictions$score(msr("cmprsk.ibs", t_quantile = 0.85))
#> cmprsk.ibs 
#>  0.1076083 

# IBS over 20 equally spaced points up to the default 90th percentile
predictions$score(msr("cmprsk.ibs", ntimes = 20L))
#> cmprsk.ibs 
#>  0.1078449 

# Define the integration grid in months
times = seq(0, 100, by = 5)

# IBS from 0 to 100 months on a 5-month grid, weighted by event frequencies
predictions$score(msr("cmprsk.ibs", times = times))
#> cmprsk.ibs 
#>  0.1002826 

# IBS from 0 to 100 months on a 5-month grid, with equal weights for both causes
predictions$score(msr("cmprsk.ibs", times = times, cause_weights = c(0.5, 0.5)))
#> cmprsk.ibs 
#> 0.06754883 

# IBS from 0 to 100 months on a 5-month grid, with custom weights for transplant and death
predictions$score(msr("cmprsk.ibs", times = times, cause_weights = c(0.2, 0.8)))
#> cmprsk.ibs 
#> 0.09479177 

# IBS from 0 to 100 months on a 5-month grid, for transplant only
predictions$score(msr("cmprsk.ibs", times = times, cause = 1))
#> cmprsk.ibs 
#> 0.02214392 

# IBS from 0 to 100 months on a 5-month grid, for death only
predictions$score(msr("cmprsk.ibs", times = times, cause = 2))
#> cmprsk.ibs 
#>  0.1129537 
```
