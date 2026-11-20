# Convert to a Competing Risk Prediction

Convert object to a
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).
An existing
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
is returned unchanged. See Details for requirements on named `list`
inputs.

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

If `x` is a named `list`, it must meet the following requirements:

- Include `row_ids`, `truth`, `cif`, and `times` elements. `weights`,
  `extra`, and `raw` are optional.

- Provide `truth` as a
  [`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html)
  object; descriptive cause names are taken from its `states` attribute.

- Provide `cif` as a list of CIF matrices, one per cause, named with
  consecutive cause codes (`"1"`, `"2"`, ..., `"K"`).

- Provide `times` as a list of time point vectors, one per cause.

- Ensure the cause names and order in `times` match those in `cif`. For
  each cause, its time vector must contain one time point per column of
  the corresponding CIF matrix. Different causes may have different time
  grids.

## Examples

``` r
library(mlr3)
task = tsk("pbc")
learner = lrn("cmprsk.aalen")
learner$train(task)
p = learner$predict(task)

# PredictionCompRisks => PredictionCompRisks (no change)
as_prediction_cmprsk(p)
#> 
#> ── <PredictionCompRisks> for 276 observations: ─────────────────────────────────
#>  row_ids time event       CIF
#>        1  400     2 <list[2]>
#>        2 4500     0 <list[2]>
#>        3 1012     2 <list[2]>
#>      ---  ---   ---       ---
#>      274  939     0 <list[2]>
#>      275  839     0 <list[2]>
#>      276  788     0 <list[2]>

# list => PredictionCompRisks
p_list = list(
  row_ids = p$row_ids,
  truth = p$truth,
  cif = p$cif,
  times = p$times # supply the time grids per cause
)
as_prediction_cmprsk(p_list)
#> 
#> ── <PredictionCompRisks> for 276 observations: ─────────────────────────────────
#>  row_ids time event       CIF
#>        1  400     2 <list[2]>
#>        2 4500     0 <list[2]>
#>        3 1012     2 <list[2]>
#>      ---  ---   ---       ---
#>      274  939     0 <list[2]>
#>      275  839     0 <list[2]>
#>      276  788     0 <list[2]>

# PredictionDataCompRisks => PredictionCompRisks (using as_prediction())
p$data
#> <PredictionDataCompRisks> 276 obs, 2 causes, CIF times: 1 (Liver transplantation) = 18, 2 (Death without transplantation) = 109
as_prediction(p$data)
#> 
#> ── <PredictionCompRisks> for 276 observations: ─────────────────────────────────
#>  row_ids time event       CIF
#>        1  400     2 <list[2]>
#>        2 4500     0 <list[2]>
#>        3 1012     2 <list[2]>
#>      ---  ---   ---       ---
#>      274  939     0 <list[2]>
#>      275  839     0 <list[2]>
#>      276  788     0 <list[2]>
```
