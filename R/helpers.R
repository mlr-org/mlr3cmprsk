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

#' @title Merge and interpolate CIF matrices
#'
#' @description
#' Given a list of CIF matrices (i.e. for a single cause), this function aligns
#' all matrices to a common time grid using step-wise constant
#' interpolation and combines them row-wise into a single matrix.
#'
#' @param cif_list (`list` of `matrix`)
#'  List of CIF matrices. Each matrix can have different time points.
#'
#' @return
#' A single matrix with all rows from `cif_list` aligned on a common time grid.
#'
#' @noRd
#' @keywords internal
merge_cifs = function(cif_list) {
  assert_list(cif_list, types = "matrix")
  # Extract time points from each matrix (we assume: colnames => time points)
  times_list = lapply(cif_list, function(mat) as.numeric(colnames(mat)))
  common_times = sort(unique(unlist(times_list)))

  # Interpolate each matrix to the common time grid
  interp_mats = mapply(function(mat, times) {
    survdistr::mat_interp(
      x          = mat,
      times      = times,
      eval_times = common_times,
      constant   = TRUE,
      type       = "cif",
      add_times  = FALSE,
      check      = FALSE
    )
  }, cif_list, times_list, SIMPLIFY = FALSE)

  # Combine row-wise
  merged_mat = do.call(rbind, interp_mats)
  colnames(merged_mat) = common_times

  merged_mat
}
