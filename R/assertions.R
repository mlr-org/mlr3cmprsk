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

#' @title Assert a List of Cumulative Incidence Matrices
#'
#' @description
#' Checks the structure, cause names, and probabilities of a list of cumulative incidence function (CIF) matrices.
#' This is the format used by [PredictionCompRisks] to store predictions for competing events.
#'
#' @param x (`list()`)\cr
#'   A list of at least two numeric matrices, one per competing event.
#'   List names must be exactly `"1"`, `"2"`, ..., `"K"`, in that order, where `K` is the number of matrices.
#'   Rows represent observations, and columns represent time points.
#' @param n_rows (`integer(1)`|`NULL`)\cr
#'   Expected number of observations in each matrix.
#'   If `NULL`, no specific row count is required.
#' @param causes (`character()`|`NULL`)\cr
#'   Expected competing event names: `"1"`, `"2"`, ..., `"K"`, in that order.
#'   If supplied, these must match the list names exactly.
#'   If `NULL`, the expected names are determined from the length of `x`.
#'
#' @details
#' Each matrix is checked with [survdistr::assert_prob()] using `type = "cif"`:
#' - At least one row and one column are required, and missing values are not allowed.
#' - Column names must represent unique, increasing, non-negative numeric time points.
#' - Probabilities must be between 0 and 1 and non-decreasing over time within each row.
#' - If time 0 is included, its probabilities must all be 0.
#'
#' Matrices are checked individually and may use different time grids.
#'
#' @return Returns `NULL` invisibly if all checks pass, otherwise raises an error.
#' @export
#' @examples
#' cif = list(
#'   "1" = matrix(c(0, 0, 0.1, 0.2, 0.3, 0.4), nrow = 2L),
#'   "2" = matrix(c(0, 0, 0.2, 0.1, 0.4, 0.3), nrow = 2L)
#' )
#' cif = lapply(cif, function(x) {
#'   colnames(x) = c("0", "1", "2")
#'   x
#' })
#'
#' assert_cif_list(cif)
#' assert_cif_list(cif, n_rows = 2L, causes = c("1", "2"))
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
