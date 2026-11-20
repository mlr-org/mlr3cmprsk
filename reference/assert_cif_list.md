# Assert a List of Cumulative Incidence Matrices

Validates the structure, optional cause names, time points, and
probabilities in a list of cumulative incidence function (CIF) matrices.
This is the format used by
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
to store the predictions of competing risk models.

Uses
[`survdistr::assert_prob()`](https://survdistr.mlr-org.com/reference/assert_prob.html)
with `type = "cif"`.

## Usage

``` r
assert_cif_list(x, times = NULL, n_rows = NULL, causes = NULL)
```

## Arguments

- x:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  List of numeric matrices (at least two), one per competing event.
  Names are checked only when `causes` is supplied. CIF matrix rows
  represent observations, and columns represent time points.

- times:

  ([`list()`](https://rdrr.io/r/base/list.html)\|`NULL`)  
  List of numeric time vectors, one per competing event. Each vector
  must have one entry (i.e. time point) per corresponding CIF matrix
  column. Names are checked only when `causes` is supplied. If `NULL`,
  time points are taken from each matrix's column names.

- n_rows:

  (`integer(1)`\|`NULL`)  
  Expected number of observations in each matrix. If `NULL`, no specific
  row count is required.

- causes:

  ([`character()`](https://rdrr.io/r/base/character.html)\|`NULL`)  
  Expected unique, nonempty competing event names or codes. If supplied,
  these must match the list names exactly (both in `x` and `times`),
  including their order. If `NULL`, list names are not checked, and
  unnamed lists are accepted.

## Value

Returns `NULL` invisibly if all checks pass, otherwise raises an error.

## Details

CIF matrices may use different time grids. See
[`survdistr::assert_prob()`](https://survdistr.mlr-org.com/reference/assert_prob.html)
for the probability and time point validation rules for `type = "cif"`.

## Examples

``` r
cif = list(
  "Death" = matrix(c(0, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.4), nrow = 2L),
  "Relapse" = matrix(c(0, 0, 0.2, 0.1, 0.4, 0.3), nrow = 2L)
)
times = list(Death = 0:3, Relapse = 0:2)

assert_cif_list(cif, times, n_rows = 2L, causes = c("Death", "Relapse"))

# Alternatively, supply time points through column names
colnames(cif$Death) = times$Death
colnames(cif$Relapse) = times$Relapse
cif
#> $Death
#>      0   1   2   3
#> [1,] 0 0.1 0.3 0.5
#> [2,] 0 0.2 0.4 0.4
#> 
#> $Relapse
#>      0   1   2
#> [1,] 0 0.2 0.4
#> [2,] 0 0.1 0.3
#> 
assert_cif_list(cif)
```
