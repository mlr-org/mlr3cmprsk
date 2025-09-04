#' @description
#' Constant interpolation of CIF matrix to requested evaluation times
#' If all `eval_times` are already present in the predicted time points, no interpolation is done.
#'
#' @param cif_mat A numeric matrix of predicted CIF values (observations × time points).
#'                Column names must be the predicted time points.
#' @param eval_times A numeric vector of requested evaluation time points.
#'
#' @return A matrix of interpolated CIF values with rows = observations and
#'         columns = `eval_times`.
#'
#' @note Uses the internal `distr6::C_Vec_WeightedDiscreteCdf()` for constant interpolation.
#' @noRd
interp_cif = function(cif_mat, eval_times) {
  # predicted time points
  pred_times = as.numeric(colnames(cif_mat))
  if (all(eval_times %in% pred_times)) {
    # no interpolation needed
    cif_mat[, as.character(eval_times), drop = FALSE]
  } else {
    extend_times = getFromNamespace("C_Vec_WeightedDiscreteCdf", ns = "distr6")
    t(extend_times(eval_times, pred_times, cdf = t(cif_mat), lower = TRUE, FALSE))
  }
}

# Wrapper around `riskRegression::Score()`
riskRegr_score = function(mat_list, metric, data, formula, times, cause) {
  assert_choice(metric, c("auc", "brier"))

  invoke(
    riskRegression::Score,
    mat_list, # list with one risk prediction matrix (n_obs x times)
    data = data, # (time, event) values for `formula` => n_rows == n_obs
    # `Hist(time, event) ~ 1 => cens.model = 'km') or `Hist(time, event) ~ vars` for 'cox'
    formula = formula,
    summary = base::switch(metric == "brier", "ibs"), # `NULL` otherwise
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
