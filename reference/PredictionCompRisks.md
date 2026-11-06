# Prediction Object for Competing Risks

This object stores the predictions returned by a learner of class
[LearnerCompRisks](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md).

The `task_type` is set to `"cmprsk"`.

Causes use consecutive codes 1, 2, ..., K, matching the task used for
prediction. By design, **predictions contain one CIF matrix for every
cause** in `task$causes`, including causes that are not observed among
the predicted observations. Filtering observations retains all cause
levels and CIFs, even for unobserved causes. Combining predictions
requires the same cause set.

Accessing all-cause survival or cause-specific hazard functions or
similar quantities from a
[LearnerCompRisks](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md)
object is not possible at the moment.

## Super class

[`mlr3::Prediction`](https://mlr3.mlr-org.com/reference/Prediction.html)
-\> `PredictionCompRisks`

## Active bindings

- `cause_names`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Read-only descriptive cause names, named by the cause codes `"1"`,
  `"2"`, ..., `"K"`.

- `cif`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Access the stored CIFs.

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
      weights = NULL,
      extra = NULL,
      check = TRUE
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
  True (observed) response. The `states` attribute contains descriptive
  cause names, ordered by numeric cause code.

- `cif`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  A required `list` of two or more `matrix` objects. Each matrix
  represents a different competing event (or cause) and stores the
  **cumulative incidence function (CIF)** for each test observation. For
  each matrix, rows refer to observations and columns to time points.
  CIF lists must use numeric cause codes as names, i.e. `"1"`, `"2"`,
  ..., `"K"`, exactly in that order.

- `weights`:

  ([`numeric()`](https://rdrr.io/r/base/numeric.html))  
  Optional measurement weights for the predicted observations, as
  supplied by a task with column role `"weights_measure"`.

- `extra`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Optional named list of additional per-observation data. Each element
  must have the same length as `row_ids`. Names must not be `row_ids`,
  `time`, `event`, `CIF`, or `weights`, which are reserved prediction
  columns.

- `check`:

  (`logical(1)`)  
  If `TRUE`, performs argument checks. Use `TRUE` for user-supplied
  data. With `FALSE`, inputs are assumed valid and correct behavior is
  not guaranteed.

#### Details

The `cif` input is a list of CIF matrices. With `check = TRUE`, nonempty
predictions are validated using
[`assert_cif_list()`](https://mlr3cmprsk.mlr-org.com/reference/assert_cif_list.md).
This checks the list structure and cause codes, the time points used for
prediction, and validates each CIF matrix, including probabilities in
\[0, 1\] and non-decreasing probabilities over time.

With `options(mlr3cmprsk.warn_cif_sum = TRUE)`, joint coherence is
checked separately by aligning the CIF matrices on a common time grid
and summing their probabilities across causes for each observation and
time point. A sum greater than 1, allowing a numerical tolerance of
`sqrt(.Machine$double.eps)`, triggers a warning of class
`Mlr3WarningCIFSumExceedsOne`. This diagnostic is disabled by default;
see the Package Options section in
[mlr3cmprsk-package](https://mlr3cmprsk.mlr-org.com/reference/mlr3cmprsk-package.md).
The prediction is retained without modifying its probabilities. Such
sums can occur with independently fitted cause-specific models, such as
the Fine-Gray model.

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
learner = lrn("cmprsk.aalen")
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

# CIF list: 1 matrix (obs x times) per competing event
names(p$cif) # cause codes
#> [1] "1" "2"
p$cause_names # descriptive names, indexed by numeric cause codes
#>                               1                               2 
#>         "Liver transplantation" "Death without transplantation" 
# CIF matrix for cause 1 (first 5 test observations and 20 time points)
p$cif[["1"]][1:5, 1:20]
#>      51 71 77 131 140 179 191 198 223 304 321 348 388 515         533
#> [1,]  0  0  0   0   0   0   0   0   0   0   0   0   0   0 0.005405405
#> [2,]  0  0  0   0   0   0   0   0   0   0   0   0   0   0 0.005405405
#> [3,]  0  0  0   0   0   0   0   0   0   0   0   0   0   0 0.005405405
#> [4,]  0  0  0   0   0   0   0   0   0   0   0   0   0   0 0.005405405
#> [5,]  0  0  0   0   0   0   0   0   0   0   0   0   0   0 0.005405405
#>              549         597         611         694        732
#> [1,] 0.005405405 0.005405405 0.005405405 0.005405405 0.01081081
#> [2,] 0.005405405 0.005405405 0.005405405 0.005405405 0.01081081
#> [3,] 0.005405405 0.005405405 0.005405405 0.005405405 0.01081081
#> [4,] 0.005405405 0.005405405 0.005405405 0.005405405 0.01081081
#> [5,] 0.005405405 0.005405405 0.005405405 0.005405405 0.01081081
# CIF matrix for cause 2 (first 5 test observations and 20 time points)
p$cif[["2"]][1:5, 1:20]
#>               51         71         77        131        140        179
#> [1,] 0.005405405 0.01081081 0.01621622 0.02162162 0.02702703 0.03243243
#> [2,] 0.005405405 0.01081081 0.01621622 0.02162162 0.02702703 0.03243243
#> [3,] 0.005405405 0.01081081 0.01621622 0.02162162 0.02702703 0.03243243
#> [4,] 0.005405405 0.01081081 0.01621622 0.02162162 0.02702703 0.03243243
#> [5,] 0.005405405 0.01081081 0.01621622 0.02162162 0.02702703 0.03243243
#>             191        198        223        304        321        348
#> [1,] 0.03783784 0.04324324 0.04864865 0.05405405 0.05945946 0.06486486
#> [2,] 0.03783784 0.04324324 0.04864865 0.05405405 0.05945946 0.06486486
#> [3,] 0.03783784 0.04324324 0.04864865 0.05405405 0.05945946 0.06486486
#> [4,] 0.03783784 0.04324324 0.04864865 0.05405405 0.05945946 0.06486486
#> [5,] 0.03783784 0.04324324 0.04864865 0.05405405 0.05945946 0.06486486
#>             388        515        533        549        597        611
#> [1,] 0.07027027 0.07567568 0.07567568 0.08108108 0.08648649 0.09189189
#> [2,] 0.07027027 0.07567568 0.07567568 0.08108108 0.08648649 0.09189189
#> [3,] 0.07027027 0.07567568 0.07567568 0.08108108 0.08648649 0.09189189
#> [4,] 0.07027027 0.07567568 0.07567568 0.08108108 0.08648649 0.09189189
#> [5,] 0.07027027 0.07567568 0.07567568 0.08108108 0.08648649 0.09189189
#>            694       732
#> [1,] 0.0972973 0.0972973
#> [2,] 0.0972973 0.0972973
#> [3,] 0.0972973 0.0972973
#> [4,] 0.0972973 0.0972973
#> [5,] 0.0972973 0.0972973

# data.table conversion
tab = as.data.table(p)
tab$CIF[[1]] # for first test observation, list of CIF vectors
#> $`1`
#>          51          71          77         131         140         179 
#> 0.000000000 0.000000000 0.000000000 0.000000000 0.000000000 0.000000000 
#>         191         198         223         304         321         348 
#> 0.000000000 0.000000000 0.000000000 0.000000000 0.000000000 0.000000000 
#>         388         515         533         549         597         611 
#> 0.000000000 0.000000000 0.005405405 0.005405405 0.005405405 0.005405405 
#>         694         732         733         762         769         797 
#> 0.005405405 0.010810811 0.010810811 0.010810811 0.010810811 0.010810811 
#>         837         859         877         890         904         930 
#> 0.016216216 0.016216216 0.021655618 0.021655618 0.021655618 0.021655618 
#>         943         974        1012        1067        1077        1083 
#> 0.021655618 0.021655618 0.021655618 0.027167790 0.027167790 0.027167790 
#>        1165        1170        1191        1235        1360        1413 
#> 0.027167790 0.027167790 0.027167790 0.027167790 0.027167790 0.027167790 
#>        1427        1435        1444        1487        1504        1542 
#> 0.027167790 0.033538123 0.033538123 0.033538123 0.040019244 0.046500365 
#>        1576        1682        1690        1741        1786        1827 
#> 0.046500365 0.046500365 0.046500365 0.046500365 0.046500365 0.046500365 
#>        1847        1925        2033        2090        2105        2241 
#> 0.046500365 0.046500365 0.054377132 0.054377132 0.054377132 0.062657836 
#>        2256        2288        2297        2386        2400        2466 
#> 0.062657836 0.062657836 0.062657836 0.062657836 0.062657836 0.062657836 
#>        2468        2475        2540        2583        2598        2769 
#> 0.072091497 0.081525157 0.081525157 0.081525157 0.081525157 0.081525157 
#>        2796        2847        3086        3090        3170        3244 
#> 0.081525157 0.081525157 0.081525157 0.081525157 0.081525157 0.081525157 
#>        3282        3358        3395        3428        3574        3584 
#> 0.081525157 0.081525157 0.081525157 0.081525157 0.081525157 0.081525157 
#>        3762        3839        3853        4079        4191 
#> 0.081525157 0.081525157 0.081525157 0.081525157 0.081525157 
#> 
#> $`2`
#>          51          71          77         131         140         179 
#> 0.005405405 0.010810811 0.016216216 0.021621622 0.027027027 0.032432432 
#>         191         198         223         304         321         348 
#> 0.037837838 0.043243243 0.048648649 0.054054054 0.059459459 0.064864865 
#>         388         515         533         549         597         611 
#> 0.070270270 0.075675676 0.075675676 0.081081081 0.086486486 0.091891892 
#>         694         732         733         762         769         797 
#> 0.097297297 0.097297297 0.102702703 0.108108108 0.113513514 0.118918919 
#>         837         859         877         890         904         930 
#> 0.118918919 0.124358321 0.124358321 0.129797722 0.135237124 0.140676526 
#>         943         974        1012        1067        1077        1083 
#> 0.146115927 0.151555329 0.157030753 0.157030753 0.162542925 0.168055097 
#>        1165        1170        1191        1235        1360        1413 
#> 0.173643827 0.179232557 0.190410017 0.196163121 0.202230849 0.208445376 
#>        1427        1435        1444        1487        1504        1542 
#> 0.214762622 0.214762622 0.221132955 0.227614076 0.227614076 0.227614076 
#>        1576        1682        1690        1741        1786        1827 
#> 0.234153586 0.241004500 0.247855415 0.254773496 0.261976858 0.269256045 
#>        1847        1925        2033        2090        2105        2241 
#> 0.276535232 0.283974401 0.283974401 0.291851169 0.299727936 0.299727936 
#>        2256        2288        2297        2386        2400        2466 
#> 0.308117597 0.316507258 0.325011846 0.334016703 0.343021561 0.352455221 
#>        2468        2475        2540        2583        2598        2769 
#> 0.352455221 0.352455221 0.361888882 0.371827917 0.381766952 0.391893516 
#>        2796        2847        3086        3090        3170        3244 
#> 0.402218640 0.412973977 0.425303267 0.437632556 0.450628294 0.463624031 
#>        3282        3358        3395        3428        3574        3584 
#> 0.476619769 0.490427740 0.504695977 0.519473793 0.534251610 0.550260911 
#>        3762        3839        3853        4079        4191 
#> 0.567794908 0.586251747 0.604708585 0.633232791 0.673981655 
#> 
```
