# Convert to a Competing Risk Prediction

Convert object to a
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).

## Usage

``` r
as_prediction_cmprsk(x, ...)

# S3 method for class 'PredictionCompRisks'
as_prediction_cmprsk(x, ...)

# S3 method for class 'data.frame'
as_prediction_cmprsk(x, ...)
```

## Arguments

- x:

  (any)  
  Object to convert.

- ...:

  (any)  
  Additional arguments.

## Value

[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).

## Examples

``` r
library(mlr3)
task = tsk("pbc")
learner = lrn("cmprsk.aalen")
learner$train(task)
p = learner$predict(task)

# convert to a data.table
tab = as.data.table(p)

# convert back to a Prediction
as_prediction_cmprsk(tab)
#> 
#> ── <PredictionCompRisks> for 276 observations: ─────────────────────────────────
#>  row_ids time event       CIF
#>        1   13     2 <list[2]>
#>        2  147     0 <list[2]>
#>        3   33     2 <list[2]>
#>      ---  ---   ---       ---
#>      274   30     0 <list[2]>
#>      275   27     0 <list[2]>
#>      276   25     0 <list[2]>
```
