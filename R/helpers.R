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

#' Validates the `times` parameter for measures such as IBS and AUC(t)
#' @keywords internal
#' @noRd
validate_times = function(times, test_times, integrated = FALSE) {
  t_max = max(test_times)
  beyond_follow_up = times > t_max
  if (any(beyond_follow_up)) {
    if (!integrated) {
      error_input(
        "RiskRegression does not evaluate time points larger than the maximum test-set time (%f).",
        t_max
      )
    }
    warning_mlr3(
      paste0(
        "RiskRegression does not evaluate time points larger than the maximum test-set time (%f). ",
        "We remove %d time point(s) from `times`"
      ),
      t_max,
      sum(beyond_follow_up)
    )
    times = times[!beyond_follow_up]
  }

  if (integrated && length(times) < 2L) {
    error_mlr3("`times` must contain at least two distinct time points.")
  }

  times
}

#' Warns if scoring times exceed the final CIF prediction anchor (time point)
#' @keywords internal
#' @noRd
warn_cif_extrapolation = function(cif_list, times, causes) {
  if (!getOption("mlr3cmprsk.warn_cif_extrapolation", FALSE)) {
    return(invisible(NULL))
  }

  affected = causes[vapply(
    cif_list[causes],
    function(mat) {
      any(times > max(as.numeric(colnames(mat))))
    },
    logical(1L)
  )]

  if (length(affected)) {
    warning_mlr3(
      paste0(
        "Scoring times exceed the final CIF prediction anchor for cause(s): %s. ",
        "We apply constant CIF extrapolation after the final prediction time point."
      ),
      str_collapse(affected),
      class = "Mlr3WarningCIFExtrapolation"
    )
  }

  invisible(NULL)
}

#' Validates the `cause` parameter (against the `causes` from the prediction object)
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

#' Resolves custom or event-frequency weights into named `weights` aligned with `causes`.
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
      class = "RiskRegressionScoreNaN"
    )
  }

  sum(scores * weights)
}

#' @title Align CIF matrices on a common time grid
#'
#' @description
#' Given a list of CIF matrices, this function aligns all matrices to a common
#' time grid using step-wise constant interpolation.
#' Optionally, aligned matrices can be concatenated row-wise.
#'
#' @param cif_list (`list` of `matrix`)
#'  List of CIF matrices. Each matrix can have different time points.
#' @param bind_rows (`logical(1)`)
#'  If `TRUE` (default), return one row-bound matrix.
#'  If `FALSE`, return a list of aligned matrices.
#'
#' @return
#' If `bind_rows = TRUE`, a single matrix with all rows from `cif_list`
#' aligned on a common time grid.
#' If `bind_rows = FALSE`, a list of aligned matrices (same columns/time grid).
#'
#' @noRd
#' @keywords internal
align_cifs = function(cif_list, bind_rows = TRUE) {
  assert_list(cif_list, types = "matrix")
  assert_flag(bind_rows)

  # Extract time points from each matrix (we assume: colnames => time points)
  times_list = lapply(cif_list, function(mat) as.numeric(colnames(mat)))
  common_times = sort(unique(unlist(times_list)))

  # Interpolate each CIF matrix to the common time grid
  aligned_cifs = mapply(
    function(mat, times) {
      out = survdistr::interp_cif(
        x = mat,
        times = times,
        eval_times = common_times,
        add_times = FALSE,
        check = FALSE
      )
      colnames(out) = common_times
      out
    },
    cif_list,
    times_list,
    SIMPLIFY = FALSE
  )

  if (!bind_rows) {
    return(aligned_cifs)
  }

  do.call(rbind, aligned_cifs)
}
