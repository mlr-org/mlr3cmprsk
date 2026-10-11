#' @section Integration grid:
#'
#' The integration grid determines the evaluation times for the IBS.
#' Its largest time point is the **effective integration horizon**.
#' The grid is the same for all causes.
#'
#' If the user explicitly provides `times`, the supplied grid is used directly.
#' Points beyond the maximum test-set follow-up are removed with a warning due to
#' the limitations of `riskRegression::Score()`.
#' At least two distinct evaluation times must remain.
#'
#' When `times = NULL` we construct a time grid consisting of `ntimes`
#' equally spaced time points between time 0 and the upper time horizon.
#' By default, the horizon is the time point corresponding to the **90th
#' percentile** of observed follow-up times in the test set (both events and
#' censored observations), unless the user specifies `t_max` or `t_quantile`.
#' `t_max` specifies the horizon directly, and `t_quantile` specifies the quantile
#' probability that determines the horizon from the observed follow-up times.
#' This method of constructing the integration grid is oblivious to the predicted
#' CIF time grids.
#'
#' For example, `t_quantile = 0.8` sets the requested horizon to the 80th percentile of
#' the observed follow-up times in the test set.
#' If it exceeds the maximum test-set follow-up, it is reduced to that maximum
#' to satisfy the restrictions of `riskRegression`.
#' A warning reports the effective horizon.
#' This validation happens before constructing the grid, so that the automatically
#' generated integration grid always has exactly `ntimes` points.
#'
