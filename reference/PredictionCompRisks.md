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
#>      268   40     0 <list[2]>
#>      274   30     0 <list[2]>
#>      276   25     0 <list[2]>

# CIF list: 1 matrix (obs x times) per competing event
names(p$cif) # competing events
#> [1] "1" "2"
# CIF matrix for competing event 1 (first 5 test observations and 20 time points)
p$cif[["1"]][1:5, 1:20]
#>      1 2 4 6 7 9 10 11 12 16 18 19 20 22         24         25         26
#> [1,] 0 0 0 0 0 0  0  0  0  0  0  0  0  0 0.01081081 0.01081081 0.01081081
#> [2,] 0 0 0 0 0 0  0  0  0  0  0  0  0  0 0.01081081 0.01081081 0.01081081
#> [3,] 0 0 0 0 0 0  0  0  0  0  0  0  0  0 0.01081081 0.01081081 0.01081081
#> [4,] 0 0 0 0 0 0  0  0  0  0  0  0  0  0 0.01081081 0.01081081 0.01081081
#> [5,] 0 0 0 0 0 0  0  0  0  0  0  0  0  0 0.01081081 0.01081081 0.01081081
#>              27         28         29
#> [1,] 0.01081081 0.01625043 0.01625043
#> [2,] 0.01081081 0.01625043 0.01625043
#> [3,] 0.01081081 0.01625043 0.01625043
#> [4,] 0.01081081 0.01625043 0.01625043
#> [5,] 0.01081081 0.01625043 0.01625043
# CIF matrix for competing event 2 (first 5 test observations and 20 time points)
p$cif[["2"]][1:5, 1:20]
#>               1          2          4          6          7          9
#> [1,] 0.01081081 0.02162162 0.03243243 0.04864865 0.05945946 0.06486486
#> [2,] 0.01081081 0.02162162 0.03243243 0.04864865 0.05945946 0.06486486
#> [3,] 0.01081081 0.02162162 0.03243243 0.04864865 0.05945946 0.06486486
#> [4,] 0.01081081 0.02162162 0.03243243 0.04864865 0.05945946 0.06486486
#> [5,] 0.01081081 0.02162162 0.03243243 0.04864865 0.05945946 0.06486486
#>              10         11         12         16         18        19        20
#> [1,] 0.07027027 0.07567568 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027
#> [2,] 0.07027027 0.07567568 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027
#> [3,] 0.07027027 0.07567568 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027
#> [4,] 0.07027027 0.07567568 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027
#> [5,] 0.07027027 0.07567568 0.08108108 0.08648649 0.09189189 0.0972973 0.1027027
#>             22        24        25        26        27        28        29
#> [1,] 0.1081081 0.1135135 0.1243243 0.1297297 0.1297297 0.1351693 0.1460486
#> [2,] 0.1081081 0.1135135 0.1243243 0.1297297 0.1297297 0.1351693 0.1460486
#> [3,] 0.1081081 0.1135135 0.1243243 0.1297297 0.1297297 0.1351693 0.1460486
#> [4,] 0.1081081 0.1135135 0.1243243 0.1297297 0.1297297 0.1351693 0.1460486
#> [5,] 0.1081081 0.1135135 0.1243243 0.1297297 0.1297297 0.1351693 0.1460486

# data.table conversion
tab = as.data.table(p)
tab$CIF[[1]] # for first test observation, list of CIF vectors
#> $`1`
#>          1          2          4          6          7          9         10 
#> 0.00000000 0.00000000 0.00000000 0.00000000 0.00000000 0.00000000 0.00000000 
#>         11         12         16         18         19         20         22 
#> 0.00000000 0.00000000 0.00000000 0.00000000 0.00000000 0.00000000 0.00000000 
#>         24         25         26         27         28         29         30 
#> 0.01081081 0.01081081 0.01081081 0.01081081 0.01625043 0.01625043 0.01625043 
#>         31         32         33         35         37         38         39 
#> 0.01625043 0.01625043 0.01625043 0.02172607 0.02172607 0.02172607 0.02172607 
#>         41         42         43         44         46         47         48 
#> 0.02172607 0.02743931 0.02743931 0.02743931 0.02743931 0.03371144 0.03371144 
#>         49         50         51         53         54         55         57 
#> 0.04009078 0.04647012 0.04647012 0.04647012 0.04647012 0.04647012 0.04647012 
#>         58         60         61         62         63         64         65 
#> 0.04647012 0.04647012 0.04647012 0.04647012 0.04647012 0.04647012 0.04647012 
#>         66         69         71         72         73         74         75 
#> 0.04647012 0.04647012 0.04647012 0.04647012 0.05479725 0.05479725 0.05479725 
#>         76         77         78         79         80         81         83 
#> 0.05479725 0.05479725 0.05479725 0.05479725 0.05479725 0.07346784 0.07346784 
#>         84         85         87         90         91         93         94 
#> 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 
#>         96         97         98        100        101        103        104 
#> 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 
#>        106        107        108        109        110        111        112 
#> 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 
#>        117        118        120        123        125        126        128 
#> 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 
#>        129        131        132        133        134        135        137 
#> 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 
#>        139        143        145        147        149 
#> 0.07346784 0.07346784 0.07346784 0.07346784 0.07346784 
#> 
#> $`2`
#>          1          2          4          6          7          9         10 
#> 0.01081081 0.02162162 0.03243243 0.04864865 0.05945946 0.06486486 0.07027027 
#>         11         12         16         18         19         20         22 
#> 0.07567568 0.08108108 0.08648649 0.09189189 0.09729730 0.10270270 0.10810811 
#>         24         25         26         27         28         29         30 
#> 0.11351351 0.12432432 0.12972973 0.12972973 0.13516935 0.14604858 0.15148820 
#>         31         32         33         35         37         38         39 
#> 0.15692781 0.15692781 0.16240345 0.17335474 0.17335474 0.18445707 0.19555940 
#>         41         42         43         44         46         47         48 
#> 0.19555940 0.19555940 0.19555940 0.20149071 0.21363355 0.21990567 0.22628501 
#>         49         50         51         53         54         55         57 
#> 0.22628501 0.23266435 0.23910065 0.23910065 0.23910065 0.25258045 0.25938578 
#>         58         60         61         62         63         64         65 
#> 0.26619112 0.28036305 0.28036305 0.28036305 0.28776049 0.28776049 0.28776049 
#>         66         69         71         72         73         74         75 
#> 0.28776049 0.29568631 0.29568631 0.29568631 0.29568631 0.30412159 0.32099215 
#>         76         77         78         79         80         81         83 
#> 0.32099215 0.32099215 0.33882674 0.34774403 0.34774403 0.35707932 0.36641462 
#>         84         85         87         90         91         93         94 
#> 0.37607182 0.38590146 0.38590146 0.39629821 0.40669495 0.41730388 0.41730388 
#>         96         97         98        100        101        103        104 
#> 0.41730388 0.41730388 0.41730388 0.41730388 0.44155284 0.44155284 0.45466039 
#>        106        107        108        109        110        111        112 
#> 0.46776794 0.48087549 0.48087549 0.48087549 0.49480226 0.50872903 0.52313604 
#>        117        118        120        123        125        126        128 
#> 0.55301723 0.55301723 0.55301723 0.57080366 0.57080366 0.60824876 0.60824876 
#>        129        131        132        133        134        135        137 
#> 0.60824876 0.60824876 0.60824876 0.60824876 0.63718362 0.63718362 0.66933345 
#>        139        143        145        147        149 
#> 0.66933345 0.66933345 0.66933345 0.66933345 0.66933345 
#> 
```
