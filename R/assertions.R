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
#' @param causes (`character()`)\cr
#' Expected causes.
#' These must be consecutive integers starting at 1 (i.e. `"1"`, `"2"`, ...)
#' and match the names of the list.
#'
#' @return if the assertion fails an error occurs, otherwise `NULL` is returned
#' invisibly.
#'
#' @noRd
assert_cif_list = function(x, n_rows = NULL, causes = NULL) {
  # List of matrices, with at least 2 elements/competing risks
  assert_list(
    x,
    types = "matrix",
    any.missing = FALSE,
    min.len = 2L,
    len = if (is.null(causes)) NULL else length(causes),
    names = "unique"
  )

  # Competing events must be "1", ..., "K"
  expected_causes = as.character(seq_along(x))

  if (!is.null(causes) && !identical(causes, expected_causes)) {
    error_learner_predict(
      "Expected competing causes to be %s, but got %s.",
      str_collapse(expected_causes),
      str_collapse(causes)
    )
  }

  if (!identical(names(x), expected_causes)) {
    error_learner_predict(
      "CIF list names must be %s, and not %s.",
      str_collapse(expected_causes),
      str_collapse(names(x))
    )
  }

  for (mat in x) {
    # Checks:
    # - numeric matrix, no missing values
    # - valid, unique, increasing non-negative times
    # - CIF values in [0,1]
    # - non-decreasing CIF
    # - CIF(0) = 0 if t = 0 is present
    survdistr::assert_prob(mat, type = "cif")

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
  }

  invisible(NULL)
}
