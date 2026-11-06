#' @title Assert a List of Cumulative Incidence Matrices
#'
#' @description
#' Checks and validates the structure, optional cause names, and probabilities in a list
#' of cumulative incidence function (CIF) matrices.
#' This is the format used by [PredictionCompRisks] to store the predictions of
#' competing risk models.
#'
#' @param x (`list()`)\cr
#'   A list of at least two numeric matrices, one per competing event.
#'   Names are checked only when `causes` is supplied.
#'   Rows represent observations, and columns represent time points.
#' @param n_rows (`integer(1)`|`NULL`)\cr
#'   Expected number of observations in each matrix.
#'   If `NULL`, no specific row count is required.
#' @param causes (`character()`|`NULL`)\cr
#'   Expected unique, nonempty competing event names or codes.
#'   If supplied, these must match the list names exactly, including their order.
#'   If `NULL`, list names are not checked, and unnamed lists are accepted.
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
#' @examples
#' cif = list(
#'   "Death" = matrix(c(0, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.4), nrow = 2L),
#'   "Relapse" = matrix(c(0, 0, 0.2, 0.1, 0.4, 0.3), nrow = 2L)
#' )
#' colnames(cif$Death) = 0:3
#' colnames(cif$Relapse) = 0:2
#'
#' assert_cif_list(cif, n_rows = 2L, causes = c("Death", "Relapse"))
#' @export
assert_cif_list = function(x, n_rows = NULL, causes = NULL) {
  assert_count(n_rows, null.ok = TRUE)
  assert_character(
    causes,
    min.len = 2L,
    any.missing = FALSE,
    unique = TRUE,
    pattern = "\\S",
    null.ok = TRUE
  )
  # List of matrices, with at least 2 elements/competing risks
  assert_list(
    x,
    types = "matrix",
    any.missing = FALSE,
    min.len = 2L
  )

  if (!is.null(causes)) {
    assert_names(names(x), identical.to = causes)
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
