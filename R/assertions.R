#' @title Assert a List of Cumulative Incidence Matrices
#'
#' @description
#' Validates the structure, optional cause names, time points, and probabilities
#' in a list of cumulative incidence function (CIF) matrices.
#' This is the format used by [PredictionCompRisks] to store the predictions of
#' competing risk models.
#'
#' Uses [survdistr::assert_prob()] with `type = "cif"`.
#'
#' @param x (`list()`)\cr
#'   A list of at least two numeric matrices, one per competing event.
#'   Names are checked only when `causes` is supplied.
#'   Rows represent observations, and columns represent time points.
#' @param times (`list()`|`NULL`)\cr
#'   List of numeric time vectors, matched to `x` by position.
#'   Names are checked only when `causes` is supplied.
#'   If `NULL`, time points are taken from each matrix's column names.
#' @param n_rows (`integer(1)`|`NULL`)\cr
#'   Expected number of observations in each matrix.
#'   If `NULL`, no specific row count is required.
#' @param causes (`character()`|`NULL`)\cr
#'   Expected unique, nonempty competing event names or codes.
#'   If supplied, these must match the list names exactly, including their order.
#'   If `NULL`, list names are not checked, and unnamed lists are accepted.
#'
#' @details
#' CIF matrices may use different time grids.
#' See [survdistr::assert_prob()] for the probability and time validation rules
#' for `type = "cif"`.
#'
#' @return Returns `NULL` invisibly if all checks pass, otherwise raises an error.
#' @examples
#' cif = list(
#'   "Death" = matrix(c(0, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.4), nrow = 2L),
#'   "Relapse" = matrix(c(0, 0, 0.2, 0.1, 0.4, 0.3), nrow = 2L)
#' )
#' times = list(Death = 0:3, Relapse = 0:2)
#'
#' assert_cif_list(cif, times, n_rows = 2L, causes = c("Death", "Relapse"))
#'
#' # Alternatively, supply time points through column names
#' colnames(cif$Death) = times$Death
#' colnames(cif$Relapse) = times$Relapse
#' cif
#' assert_cif_list(cif)
#' @export
assert_cif_list = function(x, times = NULL, n_rows = NULL, causes = NULL) {
  assert_count(n_rows, null.ok = TRUE)
  assert_character(
    causes,
    min.len = 2L,
    any.missing = FALSE,
    unique = TRUE,
    pattern = "\\S",
    null.ok = TRUE
  )
  # List of matrices, with at least 2 elements (competing events)
  assert_list(x, types = "matrix", min.len = 2L)

  if (!is.null(causes)) {
    assert_names(names(x), identical.to = causes)
  }

  if (!is.null(times)) {
    assert_list(times, types = "numeric", len = length(x))
    if (!is.null(causes)) {
      assert_names(names(times), identical.to = causes)
    }
  }

  for (i in seq_along(x)) {
    cif_mat = x[[i]]
    # Checks:
    # - numeric matrix, no missing values
    # - valid, unique, increasing non-negative times
    # - CIF values in [0,1]
    # - non-decreasing CIF
    # - CIF(0) = 0 if t = 0 is present
    survdistr::assert_prob(cif_mat, times = times[[i]], type = "cif")

    if (!is.null(n_rows)) {
      assert_true(nrow(cif_mat) == n_rows)
    }
  }

  invisible(NULL)
}
