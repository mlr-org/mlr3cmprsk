#' Wrapper around `riskRegression::Score()`
#' @keywords internal
#' @noRd
riskRegr_score = function(mat_list, metric, data, formula, times, cause, summary = NULL) {
  assert_choice(metric, c("auc", "brier"))

  invoke(
    riskRegression::Score,
    mat_list, # list with one risk prediction matrix (n_obs x times)
    data = data, # (time, event) values for `formula` => n_rows == n_obs
    # `Hist(time, event) ~ 1 => cens.model = 'km') or `Hist(time, event) ~ vars` for 'cox'
    formula = formula,
    summary = summary,
    se.fit = 0L,
    metrics = metric,
    cens.method = "ipcw",
    cens.model = "km", # "cox" if covariates in formula
    use.event.times = FALSE,
    null.model = FALSE,
    contrasts = FALSE,
    times = times, # must be the same exactly time points as in the risk prediction matrix
    cause = cause
  )
}

#' Validates the upper integration horizon `tau` for IBS.
#' This is required due to limitations in `riskRegression::Score()`, which
#' cannot evaluate beyond the maximum test-set follow-up.
#' @keywords internal
#' @noRd
validate_tau = function(tau, t_max_test) {
  if (tau > t_max_test) {
    warning_mlr3(
      paste0(
        "RiskRegression cannot evaluate beyond the maximum test-set follow-up (%g). ",
        "The requested upper integration horizon is %g. Using effective tau = %g."
      ),
      t_max_test,
      tau,
      t_max_test
    )
    tau = t_max_test
  }

  tau
}

#' Validates the `times` parameter for measures such as IBS and AUC(t)
#' This is required due to limitations in `riskRegression::Score()`, which
#' cannot evaluate beyond the maximum test-set follow-up.
#' @keywords internal
#' @noRd
validate_times = function(times, t_max_test, integrated = FALSE) {
  beyond_follow_up = times > t_max_test
  if (any(beyond_follow_up)) {
    if (!integrated) {
      error_input(
        "RiskRegression does not evaluate time points larger than the maximum test-set time (%f).",
        t_max_test
      )
    }

    warning_mlr3(
      paste0(
        "RiskRegression does not evaluate time points larger than the maximum test-set time (%f). ",
        "We remove %d time point(s) from `times`"
      ),
      t_max_test,
      sum(beyond_follow_up)
    )
    times = times[!beyond_follow_up]
  }

  if (integrated && length(unique(times)) < 2L) {
    error_mlr3("`times` must contain at least two distinct time points.")
  }

  times
}

#' Warns if scoring `times` exceed the final CIF prediction anchor time point
#' for any cause.
#' @keywords internal
#' @noRd
warn_cif_extrapolation = function(cif_times, times, causes) {
  if (!getOption("mlr3cmprsk.warn_cif_extrapolation", FALSE)) {
    return(invisible(NULL))
  }

  affected_causes = causes[vapply(
    cif_times[causes], # CIF anchor times for each cause
    function(cause_cif_times) {
      any(times > max(cause_cif_times))
    },
    logical(1L)
  )]

  if (length(affected_causes)) {
    warning_mlr3(
      paste0(
        "Scoring times exceed the final CIF prediction anchor for cause(s): %s. ",
        "We apply constant CIF extrapolation after the final prediction time point."
      ),
      str_collapse(affected_causes),
      class = "Mlr3WarningCIFExtrapolation"
    )
  }

  invisible(NULL)
}

#' Validates cause labels/names and upon successful check, returns them.
#'
#' @param cause_names (`character()`)\cr
#'   Cause names to validate.
#' @param causes (`character()`)\cr
#'   Expected cause codes: `"1"`, `"2"`, ..., `"K"`.
#'
#' @return The validated `cause_names` (invisible).
#' @keywords internal
#' @noRd
assert_cause_names = function(cause_names, causes) {
  cause_names = cause_names %??% paste("Cause", causes)

  assert_character(
    cause_names,
    any.missing = FALSE,
    unique = TRUE,
    len = length(causes),
    names = "unnamed",
    pattern = "\\S" # non-empty string
  )

  invisible(cause_names)
}

#' Validates the `cause` code parameter (against the `causes` from the prediction object, i.e. 1,2,...,K)
#' @keywords internal
#' @noRd
assert_cause = function(cause, causes) {
  if (test_int(cause)) {
    cause = as.character(cause)
    if (cause %nin% causes) {
      error_input("Invalid cause. Use one of: %s", paste(causes, collapse = ", "))
    }
  }

  cause
}

#' Resolves custom or event-frequency weights into named `weights` aligned with `causes` codes (1,2,...,K).
#' Warns for (automatically-derived) zero weights.
#' Returns `NA` weights + a warning when no events are observed.
#' @keywords internal
#' @noRd
resolve_cause_weights = function(event, causes, cause_weights = NULL) {
  # user-supplied (custom) weights
  if (!is.null(cause_weights)) {
    assert_numeric(
      cause_weights,
      lower = 0,
      upper = 1,
      len = length(causes),
      finite = TRUE,
      any.missing = FALSE
    )
    if (abs(sum(cause_weights) - 1) > 1e-8) {
      error_input("Cause weights must sum to 1.")
    }
    # align weights with causes
    return(set_names(cause_weights, causes))
  }

  # derive weights as the observed frequencies of non-censored events
  event_counts = as.numeric(table(factor(event[event != 0], levels = causes)))
  if (sum(event_counts) == 0) {
    warning_mlr3(
      "Event-frequency weights are undefined: no observed events. Returning NA."
    )
    return(set_names(rep(NA_real_, length(causes)), causes))
  }

  weights = set_names(event_counts / sum(event_counts), causes)
  if (any(weights == 0)) {
    warning_mlr3(
      "Event-frequency weights are zero for cause(s): %s, with no observed events. These causes are skipped.",
      str_collapse(causes[weights == 0])
    )
  }

  weights
}

#' Computes the weighted sum of cause-specific scores using weights ALREADY
#' aligned with the scores.
#' Warns if any score is non-finite.
#' @keywords internal
#' @noRd
aggregate_cause_causes = function(scores, weights) {
  if (!test_numeric(scores, any.missing = FALSE, finite = TRUE)) {
    warning_mlr3(
      msg = "Non-finite score (NaN, NA, or Inf) for cause(s): %s.",
      str_collapse(names(scores)[!is.finite(scores)]),
      class = "RiskRegressionScoreNotFinite"
    )
  }

  sum(scores * weights)
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
