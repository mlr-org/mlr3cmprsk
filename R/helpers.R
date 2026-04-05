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
