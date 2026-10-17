# Convert to a Competing Risk Prediction

Convert object to a
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).
An existing
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
is returned unchanged. See Details for requirements on `list` and
`data.frame` inputs.

Use
[`mlr3::as_prediction()`](https://mlr3.mlr-org.com/reference/as_prediction.html)
to convert the internal `PredictionDataCompRisks` data to a
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
object.

## Usage

``` r
as_prediction_cmprsk(x, ...)

# S3 method for class 'PredictionCompRisks'
as_prediction_cmprsk(x, ...)

# S3 method for class 'list'
as_prediction_cmprsk(x, ...)

# S3 method for class 'data.frame'
as_prediction_cmprsk(x, ...)

# S3 method for class 'PredictionDataCompRisks'
as_prediction(x, check = FALSE, ...)
```

## Arguments

- x:

  (any)  
  Object to convert.

- ...:

  (any)  
  Additional arguments.

- check:

  (`logical(1)`)  
  Whether to validate internal `PredictionDataCompRisks` data during
  conversion with
  [`mlr3::as_prediction()`](https://mlr3.mlr-org.com/reference/as_prediction.html).
  Use `TRUE` for user-supplied data; `FALSE` is intended for already
  validated internal data. With `FALSE`, correct behavior is not
  guaranteed if the input is invalid.

## Value

[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).

## Details

If `x` is a named `list`, it must contain `row_ids`, `truth`, and `cif`.
The `weights` and `extra` elements are optional. These elements are
passed to the
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
constructor and validated there (using `check = TRUE` by default). The
`cif` element must be a nonempty list of matrices, with one matrix for
every task competing cause. This requirement also applies to the
internal prediction data of `PredictionDataCompRisks` class.

If `x` is a `data.frame`/`data.table` input, the following requirements
must be met:

- Columns `row_ids`, `time`, `event`, and a list-column `CIF` must be
  present.

- An optional column `weights` may hold measurement weights.

- All other columns are stored as `extra` data. Column names must be
  unique.

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

# from an existing PredictionCompRisks object (no change)
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

# Convert a named list to a PredictionCompRisks object
# The list must contain `row_ids`, `truth`, and `cif` elements
p_list = list(
  row_ids = p$row_ids,
  truth = p$truth,
  cif = p$cif
)
as_prediction_cmprsk(p_list)
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

# Convert a data.frame to a PredictionCompRisks object
# The data.frame must contain the required columns: row_ids, time, event, and CIF
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

# Convert internal prediction data using as_prediction()
p$data
#> <PredictionDataCompRisks:276>
as_prediction(p$data)
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
