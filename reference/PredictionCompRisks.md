# Prediction Object for Competing Risks

Stores competing risks predictions returned by a learner of class
[LearnerCompRisks](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md).

- The `$cif` field provides **cumulative incidence function (CIF)
  predictions**, with one matrix (observations x times) per cause.

- The `$times` field provides the corresponding numeric time grids (can
  be different per cause).

- The `$cause_names` field provides the descriptive cause names.

- The `$raw` field provides optional upstream predictions, such as
  cause-specific hazard matrices.

- The `task_type` is set to `"cmprsk"`.

## Raw predictions

A learner can provide alternative upstream predictions, such as
all-cause survival estimates or cause-specific hazard matrices, in the
`raw` element of the list returned by its `.predict()` method. Set
`learner$predict_raw = TRUE` to request these values from a learner that
supports them. Keep in mind that:

- Filtering prediction rows via `$filter()` retains the entire raw
  object.

- Combining multiple predictions via
  [`c()`](https://rdrr.io/r/base/c.html) collects the non-`NULL` raw
  objects into a list in input order and each object is kept intact. The
  combined `$raw` is `NULL` if none of the inputs supplies a raw object.

- [`as.data.table()`](https://rdrr.io/pkg/data.table/man/as.data.table.html)
  omits raw predictions completely. Access them directly through `$raw`.

## Super class

[`mlr3::Prediction`](https://mlr3.mlr-org.com/reference/Prediction.html)
-\> `PredictionCompRisks`

## Active bindings

- `times`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Read-only numeric time grids, named by cause code and stored as an
  attribute of `$data`.

- `cause_names`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Read-only descriptive cause names, named by cause code and stored in
  the attribute `states` of `$truth`.

- `cif`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Read-only list of CIF matrices with column names derived from the
  corresponding `$times` vectors.

## Methods

### Public methods

- [`PredictionCompRisks$new()`](#method-PredictionCompRisks-initialize)

- [`PredictionCompRisks$clone()`](#method-PredictionCompRisks-clone)

Inherited methods

- [`mlr3::Prediction$filter()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-filter)
- [`mlr3::Prediction$format()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-format)
- [`mlr3::Prediction$help()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-help)
- [`mlr3::Prediction$obs_loss()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-obs_loss)
- [`mlr3::Prediction$print()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-print)
- [`mlr3::Prediction$score()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-score)

------------------------------------------------------------------------

### `PredictionCompRisks$new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    PredictionCompRisks$new(
      task = NULL,
      row_ids = task$row_ids,
      truth = task$truth(),
      cif,
      times,
      weights = NULL,
      check = TRUE,
      extra = NULL,
      raw = NULL
    )

#### Arguments

- `task`:

  ([TaskCompRisks](https://mlr3cmprsk.mlr-org.com/reference/TaskCompRisks.md))  
  Task, used to extract defaults for `row_ids` and `truth`.

- `row_ids`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row ids of the predicted observations, i.e. the row ids of the test
  set.

- `truth`:

  ([`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html))  
  True observed response. Descriptive cause names are derived from the
  `states` attribute, ordered by numeric cause code.

- `cif`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  A required `list` of two or more `matrix` objects. Each matrix
  represents a different competing event (or cause) and stores the
  **cumulative incidence function (CIF)** for each test observation. For
  each matrix, rows refer to observations and columns to time points.
  CIF lists must use numeric cause codes as names, i.e. `"1"`, `"2"`,
  ..., `"K"`, exactly in that order.

- `times`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Named list of numeric time vectors, with the same names and order as
  the CIF list. Time points must be finite, unique, non-negative,
  strictly increasing numbers, and have one entry per corresponding CIF
  matrix column. Different causes may use different time grids.

- `weights`:

  ([`numeric()`](https://rdrr.io/r/base/numeric.html))  
  Optional measurement weights for the predicted observations, as
  supplied by a task with column role `"weights_measure"`.

- `check`:

  (`logical(1)`)  
  If `TRUE` (default), performs argument checks which is encouraged for
  user-supplied data. With `FALSE`, inputs are assumed valid and correct
  behavior is not guaranteed.

- `extra`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Optional named list of additional per-observation data. Each element
  must have the same length as `row_ids`. Names must not be `row_ids`,
  `time`, `event`, `CIF`, or `weights`, which are reserved prediction
  columns.

- `raw`:

  (`any`)  
  Optional upstream predictions or metadata, such as a vector, matrix,
  or list. The constructor stores the object as-is without validation.

#### Details

The `cif` input is a named list of numeric CIF matrices, with rows =
observations and columns = time points. The list names are consecutive
cause codes (`"1"`, `"2"`, ..., `"K"`) matching the task's competing
events/causes. The `times` argument is required and supplies the
corresponding time grid for each cause. Predictions contain a matrix for
every task cause, including causes absent from the observed response of
the predicted observations. Filtering observations retains all causes
and their CIF matrices. Combining predictions requires matching cause
codes and descriptive names, and aligns each cause's matrices on the
union of its time grids.

With `check = TRUE`, nonempty predictions are validated using
[`assert_cif_list()`](https://mlr3cmprsk.mlr-org.com/reference/assert_cif_list.md).
This checks the list structure and cause codes, the time points used for
prediction, and validates that each CIF matrix includes probabilities in
\[0, 1\] which are non-decreasing over time.

With `options(mlr3cmprsk.warn_cif_sum = TRUE)`, joint coherence is
checked separately by aligning the CIF matrices on a common time grid
and summing their probabilities across causes for each observation and
time point. A sum greater than 1, allowing a numerical tolerance of
`sqrt(.Machine$double.eps)`, triggers a warning of class
`Mlr3WarningCIFSumExceedsOne`. This diagnostic is disabled by default;
see the Package Options section in
[mlr3cmprsk-package](https://mlr3cmprsk.mlr-org.com/reference/mlr3cmprsk-package.md).
Predictions are retained without modification. Such violations can arise
when cause-specific CIFs are estimated independently, as with separately
fitted Fine-Gray subdistribution hazards models.

------------------------------------------------------------------------

### `PredictionCompRisks$clone()`

The objects of this class are cloneable with this method.

#### Usage

    PredictionCompRisks$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(mlr3)
task = tsk("pbc")
task$select(c("age", "chol", "albumin", "ast", "bili", "protime"))
learner = lrn("cmprsk.fg")
part = partition(task)
p = learner$train(task, part$train)$predict(task, part$test)
p
#> 
#> ── <PredictionCompRisks> for 91 observations: ──────────────────────────────────
#>  row_ids time event       CIF
#>        1  400     2 <list[2]>
#>        6 1832     0 <list[2]>
#>       18 1356     2 <list[2]>
#>      ---  ---   ---       ---
#>      266 1271     0 <list[2]>
#>      274  939     0 <list[2]>
#>      276  788     0 <list[2]>

# CIF list: one matrix (obs x times) per competing event
str(p$cif)
#> List of 2
#>  $ 1: num [1:91, 1:12] 0.000554 0.003763 0.000496 0.000729 0.000904 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : NULL
#>   .. ..$ : chr [1:12] "533" "732" "837" "877" ...
#>  $ 2: num [1:91, 1:77] 0.050459 0.000524 0.006825 0.001709 0.002957 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : NULL
#>   .. ..$ : chr [1:77] "51" "71" "77" "131" ...
# numeric time points for each cause
p$times
#> $`1`
#>  [1]  533  732  837  877 1067 1435 1504 1542 2033 2241 2468 2475
#> 
#> $`2`
#>  [1]   51   71   77  131  140  179  191  198  223  304  321  348  388  515  549
#> [16]  597  611  694  733  762  769  797  859  890  904  930  943  974 1012 1077
#> [31] 1083 1165 1170 1191 1235 1360 1413 1427 1444 1487 1576 1682 1690 1741 1786
#> [46] 1827 1847 1925 2090 2105 2256 2288 2297 2386 2400 2466 2540 2583 2598 2769
#> [61] 2796 2847 3086 3090 3170 3244 3282 3358 3395 3428 3574 3584 3762 3839 3853
#> [76] 4079 4191
#> 
# descriptive names, indexed by numeric cause codes
p$cause_names
#>                               1                               2 
#>         "Liver transplantation" "Death without transplantation" 
# CIF matrix for cause 1 (first 5 test observations and 5 time points)
p$cif[["1"]][1:5, 1:5]
#>               533          732         837         877        1067
#> [1,] 0.0005543918 0.0011094504 0.001697085 0.002295556 0.002909697
#> [2,] 0.0037631261 0.0075186718 0.011481461 0.015503453 0.019616231
#> [3,] 0.0004959821 0.0009925898 0.001518375 0.002053889 0.002603460
#> [4,] 0.0007288863 0.0014585219 0.002230840 0.003017254 0.003824103
#> [5,] 0.0009040849 0.0018089403 0.002766555 0.003741464 0.004741515
# CIF matrix for cause 2 (first 5 test observations and 5 time points)
p$cif[["2"]][1:5, 1:5]
#>                51          71          77         131         140
#> [1,] 0.0504588489 0.101215904 0.150005167 0.197687927 0.245637744
#> [2,] 0.0005240451 0.001079769 0.001644044 0.002227396 0.002849701
#> [3,] 0.0068249325 0.014015428 0.021267345 0.028712622 0.036597378
#> [4,] 0.0017090387 0.003519177 0.005354836 0.007250086 0.009269130
#> [5,] 0.0029570413 0.006084973 0.009252766 0.012518912 0.015993382

# data.table conversion
tab = as.data.table(p)
# CIF for first test observation (2 causes)
tab$CIF[[1]]
#> $`1`
#>  [1] 0.0005543918 0.0011094504 0.0016970847 0.0022955563 0.0029096972
#>  [6] 0.0036382667 0.0044188070 0.0052072089 0.0062440746 0.0073512652
#> [11] 0.0086548608 0.0099663490
#> 
#> $`2`
#>  [1] 0.05045885 0.10121590 0.15000517 0.19768793 0.24563774 0.29262196
#>  [7] 0.33908667 0.38291904 0.42387061 0.46308041 0.49987571 0.53435966
#> [13] 0.56699757 0.59781448 0.62646788 0.65411793 0.67988410 0.70393916
#> [19] 0.72628186 0.74708790 0.76636185 0.78424534 0.80104941 0.81802397
#> [25] 0.83378549 0.84831474 0.86214997 0.87633395 0.88922528 0.90092609
#> [31] 0.91146442 0.92104829 0.93020335 0.94667155 0.95440814 0.96206741
#> [37] 0.96856426 0.97419315 0.97885720 0.98273004 0.98595438 0.98879748
#> [43] 0.99107549 0.99292415 0.99465334 0.99603360 0.99706682 0.99784891
#> [49] 0.99845477 0.99889328 0.99921819 0.99945876 0.99962903 0.99975381
#> [55] 0.99983848 0.99989594 0.99993310 0.99995940 0.99997546 0.99998537
#> [61] 0.99999148 0.99999515 0.99999750 0.99999873 0.99999941 0.99999975
#> [67] 0.99999989 0.99999996 0.99999999 1.00000000 1.00000000 1.00000000
#> [73] 1.00000000 1.00000000 1.00000000 1.00000000 1.00000000
#> 
# time points are available in the data.table attributes
attr(tab, "times")
#> $`1`
#>  [1]  533  732  837  877 1067 1435 1504 1542 2033 2241 2468 2475
#> 
#> $`2`
#>  [1]   51   71   77  131  140  179  191  198  223  304  321  348  388  515  549
#> [16]  597  611  694  733  762  769  797  859  890  904  930  943  974 1012 1077
#> [31] 1083 1165 1170 1191 1235 1360 1413 1427 1444 1487 1576 1682 1690 1741 1786
#> [46] 1827 1847 1925 2090 2105 2256 2288 2297 2386 2400 2466 2540 2583 2598 2769
#> [61] 2796 2847 3086 3090 3170 3244 3282 3358 3395 3428 3574 3584 3762 3839 3853
#> [76] 4079 4191
#> 
# descriptive cause names as well
attr(tab, "cause_names")
#>                               1                               2 
#>         "Liver transplantation" "Death without transplantation" 

# example raw predictions
# attach random cause-specific hazard matrices
n_obs = length(p$row_ids)
cs_hazard = lapply(p$times, function(cause_times) {
  matrix(runif(n_obs * length(cause_times)), nrow = n_obs)
})

p_raw = PredictionCompRisks$new(
  row_ids = p$row_ids,
  truth = p$truth,
  cif = p$cif,
  times = p$times,
  raw = list(cs_hazard = cs_hazard)
)
str(p_raw$raw$cs_hazard)
#> List of 2
#>  $ 1: num [1:91, 1:12] 0.7298 0.0384 0.3338 0.7493 0.9132 ...
#>  $ 2: num [1:91, 1:77] 0.438 0.807 0.481 0.258 0.17 ...
```
