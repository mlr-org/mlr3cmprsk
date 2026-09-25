# Convert to a Competing Risk Prediction

Convert object to a
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).
An existing
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
is returned unchanged. Use
[`mlr3::as_prediction()`](https://mlr3.mlr-org.com/reference/as_prediction.html)
to convert its internal `PredictionDataCompRisks` data.

## Usage

``` r
# S3 method for class 'PredictionDataCompRisks'
as_prediction(x, check = FALSE, ...)

as_prediction_cmprsk(x, ...)

# S3 method for class 'PredictionCompRisks'
as_prediction_cmprsk(x, ...)

# S3 method for class 'list'
as_prediction_cmprsk(x, ...)

# S3 method for class 'data.frame'
as_prediction_cmprsk(x, ...)
```

## Arguments

- x:

  (any)  
  Object to convert.

- check:

  (`logical(1)`)  
  Whether to validate internal `PredictionDataCompRisks` data during
  conversion with
  [`mlr3::as_prediction()`](https://mlr3.mlr-org.com/reference/as_prediction.html).
  Use `TRUE` for user-supplied data; `FALSE` is intended for already
  validated internal data. With `FALSE`, correct behavior is not
  guaranteed if the input is invalid.

- ...:

  (any)  
  Additional arguments.

## Value

[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).

## Details

A named `list` must contain `row_ids`, `truth`, and `cif`. These
elements are passed to the
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
constructor and validated there (using `check = TRUE` by default). The
`cif` element must be a nonempty list of matrices, with one matrix for
every task cause. This requirement also applies to internal prediction
data.

If `x` is a `data.frame`/`data.table` input, the following requirements
must be met:

- Cols `row_ids`, `time`, `event`, and a list-column `CIF` must be
  present.

- The per-observation `CIF` object must be a named list of numeric
  vectors (one per cause), with names exactly `"1"`, `"2"`, ..., `"K"`,
  in that order (where `K` is the number of competing risks).

- Cause names should be identical across observations and in the same
  order; CIF vectors corresponding to the same cause should be of equal
  length (same time points).

- Values for the `event` column must be 0 (censoring) or one of the
  consecutive cause codes 1, 2, ..., K.

## Examples

``` r
library(mlr3)
task = tsk("pbc")
learner = lrn("cmprsk.aalen")
learner$train(task)
p = learner$predict(task)

# from an existing prediction
as_prediction_cmprsk(p)
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

# convert a named list
as_prediction_cmprsk(list(row_ids = p$row_ids, truth = p$truth, cif = p$cif))
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

# from a data.frame
tab = as.data.frame(as.data.table(p))
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

# from internal prediction data
as_prediction(p$data, check = TRUE)
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
