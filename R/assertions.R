#' @title Assert survival object
#'
#' @description
#' Asserts `x` is a [survival::Surv] object with added checks.
#'
#' @param x (`Surv`)\cr
#' Object to check.
#' @param len (`integer(1)`|`NULL`)\cr
#' If non-`NULL`, checks object is length `len`.
#' @param any.missing (`logical(1)`)\cr
#' If `FALSE` then errors if there are any NAs in `x`.
#' @param null.ok (`logical(1)`)\cr
#' If `FALSE` then errors if `x` is NULL, otherwise passes.
#' @param .var.name (`character(1)`)\cr
#' Optional variable name to return if assertion fails.
#'
#' @noRd
assert_surv = function(x, len = NULL, any.missing = FALSE, null.ok = FALSE, .var.name = vname(x)) {
  assert_class(x, "Surv", null.ok = null.ok, .var.name = .var.name)
  assert_matrix(x, any.missing = any.missing, nrows = len, null.ok = null.ok, .var.name = .var.name)
}

#' @description Asserts if the given input list is a list of Cumulative Incidence
#' matrices.
#'
#' @param x (`list()`)\cr
#' A list of CIF matrices. Each matrix should have dimensions (obs x times).
#' @param n_rows (`numeric(1)`)\cr
#' Expected number of rows of each CIF matrix.
#' @param n_causes (`numeric(1)`)\cr
#' Expected number of competing events/causes.
#' This should be equal to the number of elements of the input list.
#'
#' @return if the assertion fails an error occurs, otherwise `NULL` is returned
#' invisibly.
#'
#' @noRd
assert_cif_list = function(x, n_rows = NULL, n_causes = NULL) {
  # List of matrices, with at least 2 elements/competing risks
  assert_list(
    x,
    types = "matrix",
    any.missing = FALSE,
    min.len = 2L,
    len = n_causes,
    names = "unique"
  )

  # Element names should be "1", "2", ..., "K" for K competing events
  assert_names(names(x), identical.to = as.character(seq_along(x)))

  for (mat in x) {
    # Each element a matrix
    assert_matrix(
      mat,
      mode = "numeric",
      any.missing = FALSE,
      min.rows = 1L,
      min.cols = 1L,
      col.names = "named" # for now, names of columns = times
    )

    # check `nrow` == `n_obs`
    if (!is.null(n_rows)) {
      assert_true(
        nrow(mat) == n_rows,
        .var.name = sprintf(
          "CIF matrix has %i rows and not %i (number of observations)",
          nrow(mat),
          n_rows
        )
      )
    }

    # check column names => time points
    assert_numeric(
      as.numeric(colnames(mat)),
      lower = 0,
      unique = TRUE,
      sorted = TRUE,
      finite = TRUE,
      any.missing = FALSE,
      null.ok = FALSE,
      .var.name = "Colnames must be coercible to positive, unique, increasing numeric time points"
    )
  }

  invisible(NULL)
}
