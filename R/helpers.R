# Wrapper around `riskRegression::Score()`
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
    times = times,
    cause = cause
  )
}

#' @noRd
extract_metric_value = function(result, metric, time_horizon = NULL, integrated = FALSE) {
  score = if (metric == "auc") result$AUC$score else result$Brier$score

  if (integrated) {
    col = intersect(c("IBS", "ibs", "Brier"), names(score))[1L]
    assert_string(col)
    return(score[[col]][1L])
  }

  time_col = intersect(c("times", "time"), names(score))[1L]
  metric_col = if (metric == "auc") {
    intersect(c("AUC", "auc", "score"), names(score))[1L]
  } else {
    intersect(c("Brier", "brier", "score"), names(score))[1L]
  }

  assert_string(time_col)
  assert_string(metric_col)

  if (is.null(time_horizon)) {
    return(score[[metric_col]][1L])
  }

  idx = which(score[[time_col]] == time_horizon)
  # I have interpolated exaclty on time_horizon, so there should be a match. But just in case, I take the closest time point.
  # if (!length(idx)) {
  #   idx = which.min(abs(score[[time_col]] - time_horizon))
  # }

  score[[metric_col]][idx[1L]]
}

#' @noRd
validate_cause_aggregation = function(cause, causes) {
  if (test_int(cause)) {
    cause = as.character(cause)
    if (cause %nin% causes) {
      stopf("Invalid cause. Use one of: %s", paste(causes, collapse = ", "))
    }
    return(list(mode = "single", cause = cause))
  }

  # cause can be "mean" or "sum" depending on the aggregation method
  list(mode = "aggregate", cause = cause)
}

#' @noRd
aggregate_cause_scores = function(scores, method, event, cause_weights = NULL) {
  if (!test_numeric(scores, any.missing = FALSE, finite = TRUE)) {
    mlr3misc::warning_mlr3(
      msg = "At least one of the scores is NaN",
      class = "RiskRegressionScoreNaN"
    )
  }

  if (method == "sum") {
    return(sum(scores))
  }

  # method == "mean"
  if (!is.null(cause_weights)) {
    w = cause_weights
  } else {
    # remove censored observations if present (event == 0)
    event = event[event != 0]
    # observed proportions per cause (table sorts in increasing order)
    w = as.numeric(prop.table(table(event)))
  }

  sum(w * scores)
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
  aligned_cifs = mapply(function(mat, times) {
    out = survdistr::interp_cif(
      x          = mat,
      times      = times,
      eval_times = common_times,
      add_times  = FALSE,
      check      = FALSE
    )
    colnames(out) = common_times
    out
  }, cif_list, times_list, SIMPLIFY = FALSE)

  if (!bind_rows) {
    return(aligned_cifs)
  }

  do.call(rbind, aligned_cifs)
}
