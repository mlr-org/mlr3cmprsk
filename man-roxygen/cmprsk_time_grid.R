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
#' equally spaced time points between time 0 and an upper time horizon.
#' By default, the horizon is chosen as the time point corresponding to the
#' **90th percentile** of observed follow-up times (including both events and
#' censored observations) in the test set.
#' The user can change that percentile with `t_quantile`, or specify a fixed
#' horizon with `t_max`.
#' If `t_max` exceeds the maximum test-set follow-up, it is reduced to that maximum
#' to satisfy the restrictions of `riskRegression`, and a warning reports the effective horizon.
#' In any case, the resulting integration grid will always have exactly `ntimes`
#' points and its construction is completely independent of the time grids of the
#' predicted CIFs.
#'
#' The choice for the default 90th percentile is for minimizing the influence of
#' extreme evaluation times, which may cause **CIF extrapolation** (when the
#' integration grid has times larger than the maximum anchor of the CIF time grid)
#' and issues with **large IPCW weights**.
#'
