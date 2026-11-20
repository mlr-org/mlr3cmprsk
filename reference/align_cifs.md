# Align CIF matrices on a common time grid

Aligns a list of cumulative incidence function (CIF) matrices to a
common time grid using stepwise constant interpolation. Optionally, the
aligned matrices can be concatenated by rows.

## Usage

``` r
align_cifs(
  x,
  times,
  eval_times = sort(unique(unlist(times, use.names = FALSE))),
  bind_rows = FALSE,
  add_times = FALSE
)
```

## Arguments

- x:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  List of CIF matrices, with observations in rows and time points in
  columns. Matrices may have different time grids and numbers of rows.

- times:

  ([`list()`](https://rdrr.io/r/base/list.html))  
  List of numeric time vectors, matched to the matrices in `x` by
  position. Each vector must have one entry per corresponding CIF matrix
  column.

- eval_times:

  ([`numeric()`](https://rdrr.io/r/base/numeric.html))  
  Non-negative, strictly increasing time points at which to evaluate all
  CIFs. Defaults to the sorted union of the time grids in `times`.

- bind_rows:

  (`logical(1)`)  
  If `FALSE` (default), return a list of aligned matrices. If `TRUE`,
  return one matrix by concatenating the aligned matrices by rows.

- add_times:

  (`logical(1)`)  
  If `TRUE`, set the output matrices' column names to `eval_times`. If
  `FALSE` (default), no time column names are added.

## Value

By default, a list of time-aligned matrices in the same order as `x`. If
`bind_rows = TRUE`, a single matrix containing all input rows on the
common time grid. Each output matrix has one column per evaluation time
point.

## Details

The input matrices and their time grids are assumed to be valid and
already validated with
[`assert_cif_list()`](https://mlr3cmprsk.mlr-org.com/reference/assert_cif_list.md).
Interpolation uses
[`survdistr::interp_cif()`](https://survdistr.mlr-org.com/reference/interp_cif.html)
with `check = FALSE`.

## See also

[`assert_cif_list()`](https://mlr3cmprsk.mlr-org.com/reference/assert_cif_list.md),
[`survdistr::interp_cif()`](https://survdistr.mlr-org.com/reference/interp_cif.html)

## Examples

``` r
cif = list(
  Death = matrix(c(0, 0, 0.2, 0.3, 0.4, 0.5), nrow = 2L),
  Relapse = matrix(c(0, 0, 0.1, 0.2), nrow = 2L)
)
times = list(Death = c(0, 2, 4), Relapse = c(1, 3))

# Keep one matrix per cause on the union of the time grids
align_cifs(cif, times, add_times = TRUE)
#> $Death
#>      0 1   2   3   4
#> [1,] 0 0 0.2 0.2 0.4
#> [2,] 0 0 0.3 0.3 0.5
#> 
#> $Relapse
#>      0 1 2   3   4
#> [1,] 0 0 0 0.1 0.1
#> [2,] 0 0 0 0.2 0.2
#> 

# Combine rows on the union of the time grids
align_cifs(cif, times, bind_rows = TRUE, add_times = TRUE)
#>      0 1   2   3   4
#> [1,] 0 0 0.2 0.2 0.4
#> [2,] 0 0 0.3 0.3 0.5
#> [3,] 0 0 0.0 0.1 0.1
#> [4,] 0 0 0.0 0.2 0.2

# Combine rows on an explicit evaluation grid
align_cifs(cif, times, eval_times = c(1.5, 2, 3.5), bind_rows = TRUE, add_times = TRUE)
#>      1.5   2 3.5
#> [1,]   0 0.2 0.2
#> [2,]   0 0.3 0.3
#> [3,]   0 0.0 0.1
#> [4,]   0 0.0 0.2
```
