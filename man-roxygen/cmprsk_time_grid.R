#' @section Integration grid:
#'
#' The integration grid contains the time points at which Brier scores are evaluated for numerical integration.
#' Its largest time point is the **upper integration horizon**.
#' All causes use the same grid, with their predicted CIFs interpolated to these times.
#'
#' If the user explicitly provides `times`, the supplied grid is used directly.
#' Points beyond the maximum test-set follow-up are removed with a warning due to
#' the limitations of `riskRegression::Score()`.
#' At least two distinct evaluation times must remain.
#'
#' When `times = NULL`, the upper integration horizon is determined first.
#' By default, it is the **90th percentile** of observed test-set follow-up times,
#' including both events and censored observations.
#' Set `t_quantile` to change the quantile probability (e.g., `0.8` for the 80th
#' percentile), or supply `t_max` to specify the time horizon directly.
#' If `t_max` exceeds the maximum test-set follow-up, it is reduced to that maximum
#' before constructing the grid, and a warning reports the effective horizon.
#'
#' The automatic grid is then generated and contains exactly `ntimes` equally
#' spaced points from time 0 to the horizon, including both endpoints.
#' Thus, the default grid consists of 100 points from 0 to the 90th percentile
#' of test-set follow-up times.
#' Note that the generated grid is completely independent of the time grids of
#' the predicted CIFs.
#'
#' The default 90th percentile is chosen to limit evaluation at extreme follow-up
#' times, where IPCW weights may be large or CIF extrapolation beyond the last
#' predicted time point may be needed.
#'
