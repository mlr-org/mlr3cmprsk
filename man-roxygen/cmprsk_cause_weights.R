#' @section Cause weights:
#' Cause weights are used only for `cause = "mean"`.
#' The `cause_weights` parameter is ignored when scoring an explicit cause.
#'
#' With `cause_weights = NULL`, weights are the relative frequencies of observed non-censored events.
#' All observed events contribute to these frequencies, regardless of the evaluation time points.
#' Causes without observed events receive weight zero and are listed in a warning.
#' If no events are observed, weights are undefined, and the measure warns and returns `NA_real_`.
#'
#' Alternatively, supply custom weights through `cause_weights`.
#' They must be finite, non-negative, sum to 1, and contain one entry per predicted cause.
#' Entries must match the order of the predicted CIFs cause names.
#'
#' Causes with weight zero are skipped before scoring.
#' Custom zero weights are skipped silently (as per user request!).
#' Non-finite scores from positive-weight causes propagate to the mean,
#' and a warning identifies the affected causes.
#'
