#' @section Cause weights:
#' Cause weights are used only for `cause = "mean"`.
#' The `cause_weights` parameter is ignored when scoring a specific cause.
#'
#' With `cause_weights = NULL`, weights are the relative frequencies of observed
#' non-censored events from the test set.
#' Causes without observed events receive zero weight, are listed in a warning and
#' are skipped when calculating the mean score.
#' If no events from any cause are observed, weights are undefined, and the
#' measure warns and returns `NA_real_`.
#'
#' Alternatively, the user can supply custom weights via `cause_weights`.
#' Weights must be finite, non-negative, sum to 1, and contain one entry per predicted cause.
#' Entries must match the order of the predicted CIFs cause names.
#' If any user-supplied weight happens to be zero, it is skipped silently.
#'
#' In general, non-finite scores from positive-weight causes propagate to the mean,
#' causing the measure to return `NaN` and a warning identifies the causes with
#' non-finite scores.
#'
