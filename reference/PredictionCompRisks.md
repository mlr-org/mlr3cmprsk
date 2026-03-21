# Prediction Object for Competing Risks

This object stores the predictions returned by a learner of class
[LearnerCompRisks](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md).

The `task_type` is set to `"cmprsk"`.

For accessing survival and hazard functions, as well as other complex
methods from a
[LearnerCompRisks](https://mlr3cmprsk.mlr-org.com/reference/LearnerCompRisks.md)
object is not possible atm.

## Super class

[`mlr3::Prediction`](https://mlr3.mlr-org.com/reference/Prediction.html)
-\> `PredictionCompRisks`

## Active bindings

- `truth`:

  (`Surv`)  
  True (observed) outcome.

- `cif`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  Access the stored CIFs.

## Methods

### Public methods

- [`PredictionCompRisks$new()`](#method-PredictionCompRisks-new)

- [`PredictionCompRisks$clone()`](#method-PredictionCompRisks-clone)

Inherited methods

- [`mlr3::Prediction$filter()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-filter)
- [`mlr3::Prediction$format()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-format)
- [`mlr3::Prediction$help()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-help)
- [`mlr3::Prediction$obs_loss()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-obs_loss)
- [`mlr3::Prediction$print()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-print)
- [`mlr3::Prediction$score()`](https://mlr3.mlr-org.com/reference/Prediction.html#method-score)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    PredictionCompRisks$new(
      task = NULL,
      row_ids = task$row_ids,
      truth = task$truth(),
      cif = NULL,
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
  True (observed) response.

- `cif`:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  A `list` of two or more `matrix` objects. Each matrix represents a
  different competing event and it stores the **Cumulative Incidence
  function** for each test observation. In each matrix, rows represent
  observations and columns time points. The names of the `list` must
  correspond to the competing event names (`task$cmp_events`).

- `check`:

  (`logical(1)`)  
  If `TRUE`, performs argument checks and predict type conversions.

#### Details

The `cif` input currently is a list of CIF matrices.

------------------------------------------------------------------------

### Method `clone()`

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
#>        1   13     2 <list[2]>
#>        6   60     0 <list[2]>
#>       18   44     2 <list[2]>
#>      ---  ---   ---       ---
#>      266   41     0 <list[2]>
#>      274   30     0 <list[2]>
#>      276   25     0 <list[2]>

# CIF list: 1 matrix (obs x times) per competing event
names(p$cif) # competing events
#> [1] "1" "2"
# CIF matrix for competing event 1 (first 5 test observations and 20 time points)
p$cif[["1"]][1:5, 1:20]
#>      1 2 4 5 6 7 9 10 11 12 16          17          18          19          20
#> [1,] 0 0 0 0 0 0 0  0  0  0  0 0.005405405 0.005405405 0.005405405 0.005405405
#> [2,] 0 0 0 0 0 0 0  0  0  0  0 0.005405405 0.005405405 0.005405405 0.005405405
#> [3,] 0 0 0 0 0 0 0  0  0  0  0 0.005405405 0.005405405 0.005405405 0.005405405
#> [4,] 0 0 0 0 0 0 0  0  0  0  0 0.005405405 0.005405405 0.005405405 0.005405405
#> [5,] 0 0 0 0 0 0 0  0  0  0  0 0.005405405 0.005405405 0.005405405 0.005405405
#>               22         24         25         26         27
#> [1,] 0.005405405 0.01081081 0.01081081 0.01081081 0.01621622
#> [2,] 0.005405405 0.01081081 0.01081081 0.01081081 0.01621622
#> [3,] 0.005405405 0.01081081 0.01081081 0.01081081 0.01621622
#> [4,] 0.005405405 0.01081081 0.01081081 0.01081081 0.01621622
#> [5,] 0.005405405 0.01081081 0.01081081 0.01081081 0.01621622
# CIF matrix for competing event 2 (first 5 test observations and 20 time points)
p$cif[["2"]][1:5, 1:20]
#>                1          2          4          5          6          7
#> [1,] 0.005405405 0.01621622 0.02702703 0.03243243 0.04324324 0.04864865
#> [2,] 0.005405405 0.01621622 0.02702703 0.03243243 0.04324324 0.04864865
#> [3,] 0.005405405 0.01621622 0.02702703 0.03243243 0.04324324 0.04864865
#> [4,] 0.005405405 0.01621622 0.02702703 0.03243243 0.04324324 0.04864865
#> [5,] 0.005405405 0.01621622 0.02702703 0.03243243 0.04324324 0.04864865
#>               9         10         11         12         16         17
#> [1,] 0.05405405 0.05945946 0.06486486 0.07027027 0.07567568 0.07567568
#> [2,] 0.05405405 0.05945946 0.06486486 0.07027027 0.07567568 0.07567568
#> [3,] 0.05405405 0.05945946 0.06486486 0.07027027 0.07567568 0.07567568
#> [4,] 0.05405405 0.05945946 0.06486486 0.07027027 0.07567568 0.07567568
#> [5,] 0.05405405 0.05945946 0.06486486 0.07027027 0.07567568 0.07567568
#>              18         19         20        22        24        25        26
#> [1,] 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027 0.1135135 0.1189189
#> [2,] 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027 0.1135135 0.1189189
#> [3,] 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027 0.1135135 0.1189189
#> [4,] 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027 0.1135135 0.1189189
#> [5,] 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027 0.1135135 0.1189189
#>             27
#> [1,] 0.1189189
#> [2,] 0.1189189
#> [3,] 0.1189189
#> [4,] 0.1189189
#> [5,] 0.1189189

# data.table conversion
tab = as.data.table(p)
tab$CIF[[1]] # for first test observation, list of CIF vectors
#> $`1`
#>           1           2           4           5           6           7 
#> 0.000000000 0.000000000 0.000000000 0.000000000 0.000000000 0.000000000 
#>           9          10          11          12          16          17 
#> 0.000000000 0.000000000 0.000000000 0.000000000 0.000000000 0.005405405 
#>          18          19          20          22          24          25 
#> 0.005405405 0.005405405 0.005405405 0.005405405 0.010810811 0.010810811 
#>          26          27          28          29          30          31 
#> 0.010810811 0.016216216 0.021655618 0.021655618 0.021655618 0.021655618 
#>          33          35          38          39          40          44 
#> 0.021655618 0.027167790 0.027167790 0.027167790 0.027167790 0.027167790 
#>          46          47          48          49          50          51 
#> 0.027167790 0.033488601 0.033488601 0.039974302 0.046460004 0.046460004 
#>          55          57          58          60          63          66 
#> 0.046460004 0.046460004 0.046460004 0.046460004 0.046460004 0.054253750 
#>          68          69          73          74          75          78 
#> 0.054253750 0.054253750 0.062439768 0.062439768 0.062439768 0.062439768 
#>          81          83          84          85          90          91 
#> 0.081340395 0.081340395 0.081340395 0.081340395 0.081340395 0.081340395 
#>          93         101         104         106         107         110 
#> 0.081340395 0.081340395 0.081340395 0.081340395 0.081340395 0.081340395 
#>         111         112         117         123         126         134 
#> 0.081340395 0.081340395 0.081340395 0.081340395 0.081340395 0.081340395 
#>         137 
#> 0.081340395 
#> 
#> $`2`
#>           1           2           4           5           6           7 
#> 0.005405405 0.016216216 0.027027027 0.032432432 0.043243243 0.048648649 
#>           9          10          11          12          16          17 
#> 0.054054054 0.059459459 0.064864865 0.070270270 0.075675676 0.075675676 
#>          18          19          20          22          24          25 
#> 0.081081081 0.086486486 0.091891892 0.097297297 0.102702703 0.113513514 
#>          26          27          28          29          30          31 
#> 0.118918919 0.118918919 0.124358321 0.135237124 0.146115927 0.151555329 
#>          33          35          38          39          40          44 
#> 0.157030753 0.168055097 0.179232557 0.190410017 0.196079743 0.202101080 
#>          46          47          48          49          50          51 
#> 0.214334907 0.220655718 0.227141420 0.227141420 0.227141420 0.233627121 
#>          55          57          58          60          63          66 
#> 0.247339748 0.254263279 0.261256047 0.275830446 0.283277803 0.283277803 
#>          68          69          73          74          75          78 
#> 0.291164332 0.299050861 0.299050861 0.307343191 0.324148979 0.342190486 
#>          81          83          84          85          90          91 
#> 0.351640800 0.361091113 0.370704363 0.380667185 0.390817986 0.400968786 
#>          93         101         104         106         107         110 
#> 0.411533905 0.436271744 0.449309254 0.462346764 0.475384273 0.489236627 
#>         111         112         117         123         126         134 
#> 0.503088982 0.517419003 0.547140529 0.564831914 0.602076934 0.630857177 
#>         137 
#> 0.662835224 
#> 
```
