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
#'   List of numeric matrices (at least two), one per competing event.
#'   Names are checked only when `causes` is supplied.
#'   CIF matrix rows represent observations, and columns represent time points.
#' @param times (`list()`|`NULL`)\cr
#'   List of numeric time vectors, one per competing event.
#'   Each vector must have one entry (i.e. time point) per corresponding CIF matrix column.
#'   Names are checked only when `causes` is supplied.
#'   If `NULL`, time points are taken from each matrix's column names.
#' @param n_rows (`integer(1)`|`NULL`)\cr
#'   Expected number of observations in each matrix.
#'   If `NULL`, no specific row count is required.
#' @param causes (`character()`|`NULL`)\cr
#'   Expected unique, nonempty competing event names or codes.
#'   If supplied, these must match the list names exactly (both in `x` and
#'   `times`), including their order.
#'   If `NULL`, list names are not checked, and unnamed lists are accepted.
#'
#' @details
#' CIF matrices may use different time grids.
#' See [survdistr::assert_prob()] for the probability and time point validation
#' rules for `type = "cif"`.
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

#' @title Align CIF matrices on a common time grid
#'
#' @description
#' Aligns a list of cumulative incidence function (CIF) matrices to a common time grid
#' using stepwise constant interpolation.
#' Optionally, the aligned matrices can be concatenated by rows.
#'
#' @param x (`list()`)\cr
#'   List of CIF matrices, with observations in rows and time points in columns.
#'   Matrices may have different time grids and numbers of rows.
#' @param times (`list()`)\cr
#'   List of numeric time vectors, matched to the matrices in `x` by position.
#'   Each vector must have one entry per corresponding CIF matrix column.
#' @param eval_times (`numeric()`)\cr
#'   Non-negative, strictly increasing time points at which to evaluate all CIFs.
#'   Defaults to the sorted union of the time grids in `times`.
#' @param bind_rows (`logical(1)`)\cr
#'   If `FALSE` (default), return a list of aligned matrices.
#'   If `TRUE`, return one matrix by concatenating the aligned matrices by rows.
#' @param add_times (`logical(1)`)\cr
#'   If `TRUE`, set the output matrices' column names to `eval_times`.
#'   If `FALSE` (default), no time column names are added.
#'
#' @details
#' The input matrices and their time grids are assumed to be valid and already
#' validated with [assert_cif_list()].
#' Interpolation uses [survdistr::interp_cif()] with `check = FALSE`.
#'
#' @return By default, a list of time-aligned matrices in the same order as `x`.
#'   If `bind_rows = TRUE`, a single matrix containing all input rows on the common time grid.
#'   Each output matrix has one column per evaluation time point.
#' @seealso [assert_cif_list()], [survdistr::interp_cif()]
#' @examples
#' cif = list(
#'   Death = matrix(c(0, 0, 0.2, 0.3, 0.4, 0.5), nrow = 2L),
#'   Relapse = matrix(c(0, 0, 0.1, 0.2), nrow = 2L)
#' )
#' times = list(Death = c(0, 2, 4), Relapse = c(1, 3))
#'
#' # Keep one matrix per cause on the union of the time grids
#' align_cifs(cif, times, add_times = TRUE)
#'
#' # Combine rows on the union of the time grids
#' align_cifs(cif, times, bind_rows = TRUE, add_times = TRUE)
#'
#' # Combine rows on an explicit evaluation grid
#' align_cifs(cif, times, eval_times = c(1.5, 2, 3.5), bind_rows = TRUE, add_times = TRUE)
#' @export
align_cifs = function(
  x,
  times,
  eval_times = sort(unique(unlist(times, use.names = FALSE))),
  bind_rows = FALSE,
  add_times = FALSE
) {
  assert_list(x, types = "matrix")
  assert_list(times, types = "numeric", len = length(x))
  assert_flag(bind_rows)
  assert_flag(add_times)

  # Interpolate each CIF matrix to the common or specified time grid
  aligned_cifs = mapply(
    function(cif_mat, cif_times) {
      survdistr::interp_cif(
        x = cif_mat,
        times = cif_times,
        eval_times = eval_times,
        add_times = add_times,
        check = FALSE
      )
    },
    x,
    times,
    SIMPLIFY = FALSE
  )

  if (!bind_rows) {
    return(aligned_cifs)
  }

  do.call(rbind, aligned_cifs)
}
