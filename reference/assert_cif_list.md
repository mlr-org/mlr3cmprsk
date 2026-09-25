# Assert a List of Cumulative Incidence Matrices

Checks the structure, cause names, and probabilities of a list of
cumulative incidence function (CIF) matrices. This is the format used by
[PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md)
to store predictions for competing events.

## Usage

``` r
assert_cif_list(x, n_rows = NULL, causes = NULL)
```

## Arguments

- x:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  A list of at least two numeric matrices, one per competing event. List
  names must be exactly `"1"`, `"2"`, ..., `"K"`, in that order, where
  `K` is the number of matrices. Rows represent observations, and
  columns represent time points.

- n_rows:

  (`integer(1)`\|`NULL`)  
  Expected number of observations in each matrix. If `NULL`, no specific
  row count is required.

- causes:

  ([`character()`](https://rdrr.io/r/base/character.html)\|`NULL`)  
  Expected competing event names: `"1"`, `"2"`, ..., `"K"`, in that
  order. If supplied, these must match the list names exactly. If
  `NULL`, the expected names are determined from the length of `x`.

## Value

Returns `NULL` invisibly if all checks pass, otherwise raises an error.

## Details

Each matrix is checked with
[`survdistr::assert_prob()`](https://survdistr.mlr-org.com/reference/assert_prob.html)
using `type = "cif"`:

- At least one row and one column are required, and missing values are
  not allowed.

- Column names must represent unique, increasing, non-negative numeric
  time points.

- Probabilities must be between 0 and 1 and non-decreasing over time
  within each row.

- If time 0 is included, its probabilities must all be 0.

Matrices are checked individually and may use different time grids.

## Examples

``` r
cif = list(
  "1" = matrix(c(0, 0, 0.1, 0.2, 0.3, 0.4), nrow = 2L),
  "2" = matrix(c(0, 0, 0.2, 0.1, 0.4, 0.3), nrow = 2L)
)
cif = lapply(cif, function(x) {
  colnames(x) = c("0", "1", "2")
  x
})

assert_cif_list(cif)
assert_cif_list(cif, n_rows = 2L, causes = c("1", "2"))
```
