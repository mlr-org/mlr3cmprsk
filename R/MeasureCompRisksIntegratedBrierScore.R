#' @title Integrated Brier Score Competing Risks Measure
#' @name mlr_measures_cmprsk.ibs
#' @templateVar measure_id cmprsk.ibs
#' @template cmprsk_measure
#'
#' @description
#' Calculates the integrated competing-risks prediction error or Brier Score
#' (IBS) at given times, using IPCW as described in Schoop et al. (2011).
#'
#' @details
#' By default, this measure returns a **cause-independent IBS** (or all-cause)
#' score, calculated as a weighted average of the cause-specific IBS (Integrated Brier Score) scores.
#' The weights correspond to the relative event frequencies of each cause,
#' following Equation (8) in Spitoni et al. (2018).
#' User-supplied weights are also supported.
#'
#' Alternatively, users can obtain the **cause-specific IBS** for any
#' individual cause by specifying the `cause` parameter.
#'
#' @section Parameter details:
#' - `cause` (`numeric(1)|"mean"`)\cr
#'  Integer number indicating which cause to use.
#'  Default value is `"mean"` which returns an event-frequency weighted mean of
#'  the cause-specific IBS (Integrated Brier Score) scores.
#' - `cause_weights` (`numeric()`|`NULL`)\cr
#'  Optional custom weights for `cause = "mean"`.
#'  If `NULL`, observed cause frequencies **from the test data** are used.
#'  The weights must be non-negative, sum to 1 and match the number of causes 1-1,
#'  i.e. first weight for first cause, second weight for second cause, etc.
#'  See Spitoni et al. (2018), Equation (8) for a similar weighting scheme.
#' - `times` (`numeric(1)`)\cr
#'  Time points used for numerical integration. If `NULL`, all unique
#'  times from the test set are used.
#'
#' @references
#' `r format_bib("schoop_2011", "spitoni_2018")`
#'
#' @templateVar learner_id cmprsk.fg
#' @template example
#' @template example_measure
#' @export
MeasureCompRisksIntegratedBrierScore = R6Class(
  "MeasureCompRisksIntegratedBrierScore",
  inherit = MeasureCompRisks,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      param_set = ps(
        cause = p_int(lower = 1, init = "mean", special_vals = list("mean")),
        cause_weights = p_uty(default = NULL, special_vals = list(NULL)),
        times = p_uty(default = NULL, special_vals = list(NULL), custom_check = function(x) {
          checkmate::check_numeric(
            x,
            lower = 0,
            min.len = 2L,
            unique = TRUE,
            sorted = TRUE,
            finite = TRUE,
            any.missing = FALSE,
            null.ok = TRUE
          )
        })
      )

      super$initialize(
        id = "cmprsk.ibs",
        param_set = param_set,
        range = c(0, Inf),
        minimize = TRUE,
        properties = "na_score",
        packages = "riskRegression",
        label = "Competing Risks Integrated Brier Score",
        man = "mlr3cmprsk::mlr_measures_cmprsk.ibs"
      )
    }
  ),

  private = list(
    .score = function(prediction, task, ...) {
      pv = self$param_set$values

      # Prepare test set data for IPCW
      # Must match the number of rows in the predicted CIF matrix
      data = data.table(
        time = prediction$truth[, 1L],
        event = prediction$truth[, 2L]
      )
      form = formulate(lhs = "Hist(time, event)", rhs = "1", env = getNamespace("prodlim"))

      # define evaluation/integration time grid
      times = pv$times
      if (is.null(times)) {
        times = sort(unique(data$time))
      }
      times = validate_times(times, data$time, integrated = TRUE)

      # list of predicted CIF matrices
      cif_list = prediction$cif
      causes = names(cif_list)
      # cause should be 1,2,... or "mean"
      cause = assert_cause(pv$cause, causes)

      # check weights
      cause_weights = pv$cause_weights
      if (!is.null(cause_weights)) {
        assert_numeric(
          cause_weights,
          lower = 0,
          upper = 1,
          len = length(causes),
          any.missing = FALSE,
          null.ok = FALSE
        )

        if (abs(sum(cause_weights) - 1) > 1e-8) {
          error_input("Cause weights must sum to 1.")
        }
      }

      scored_causes = if (cause == "mean") causes else cause
      warn_cif_extrapolation(cif_list, times, scored_causes)

      ibs = function(cause) {
        # get CIF on the times grid
        mat = survdistr::interp_cif(
          x = cif_list[[cause]], # cause-specific CIF
          eval_times = times,
          add_times = FALSE,
          check = FALSE
        )

        # calculate IBS score
        res = riskRegr_score(
          mat_list = list(mat),
          metric = "brier",
          data = data,
          formula = form,
          times = times,
          cause = cause,
          summary = "ibs"
        )

        # IBS up until last time point
        tail(res$Brier$score$IBS, 1L)
      }

      if (cause != "mean") {
        return(ibs(cause))
      }

      ibs_scores = vapply(causes, ibs, numeric(1L))

      aggregate_scores(ibs_scores, data$event, cause_weights)
    }
  )
)

#' @include aaa.R
measures[["cmprsk.ibs"]] = MeasureCompRisksIntegratedBrierScore
