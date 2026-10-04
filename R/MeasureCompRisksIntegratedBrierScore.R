#' @title Integrated Brier Score Competing Risks Measure
#' @name mlr_measures_cmprsk.ibs
#' @templateVar measure_id cmprsk.ibs
#' @template cmprsk_measure
#'
#' @description
#' Calculates the integrated competing risks prediction error (integrated Brier score, IBS)
#' over given time points, using IPCW as described in Schoop et al. (2011).
#'
#' @details
#' By default, this measure returns a **cause-independent IBS** (or all-cause)
#' score, calculated as a weighted average of the cause-specific integrated Brier scores.
#' The weights correspond to the relative event frequencies of each cause,
#' following Equation (8) in Spitoni et al. (2018).
#' User-supplied weights are also supported through `cause_weights`.
#' See the **Cause weights** section for weighting rules.
#'
#' Alternatively, users can obtain the **cause-specific IBS** for any
#' individual cause by specifying the `cause` parameter.
#'
#' Calls [riskRegression::Score()] with:
#' - `metric = "brier"`
#' - `summary = "ibs"`
#' - `cens.method = "ipcw"`
#' - `cens.model = "km"`
#'
#' Notes on the `riskRegression` implementation:
#' 1. IPCW weights are estimated using the **test data only**, so smaller test
#' sets may lead to less stable estimates.
#' 2. Integration times beyond the maximum observed test-set time are removed with a warning.
#' At least two distinct time points must remain after this removal.
#'
#' @template cmprsk_cause_weights
#'
#' @section Parameter details:
#' - `cause` (`numeric(1)|"mean"`)\cr
#'  Integer number indicating which cause to use.
#'  Default value is `"mean"` which returns an event-frequency weighted mean of
#'  the cause-specific integrated Brier scores.
#' - `cause_weights` (`numeric()`|`NULL`)\cr
#'  Optional custom weights for `cause = "mean"`.
#'  See the **Cause weights** section for weighting rules.
#' - `times` (`numeric()`|`NULL`)\cr
#'  Integration time points, supplied as a sorted vector of at least two distinct,
#' finite, non-negative values.
#'  If `NULL`, all unique observed times from the test set are used.
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

      # get list of predicted CIF matrices and causes requested
      cif_list = prediction$cif
      causes = names(cif_list)
      cause = assert_cause(pv$cause, causes)

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

      # For cause = "mean", get cause weights
      active_causes = cause
      if (cause == "mean") {
        weights = resolve_cause_weights(data$event, causes, pv$cause_weights)
        if (anyNA(weights)) {
          return(NA_real_)
        }
        active_causes = causes[weights > 0]
      }

      # Preserve absent causes for RiskRegression
      data$event = factor(data$event, levels = c("0", causes))
      warn_cif_extrapolation(cif_list, times, active_causes)

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

      ibs_scores = vapply(active_causes, ibs, numeric(1L))

      aggregate_cause_causes(ibs_scores, weights[active_causes])
    }
  )
)

#' @include aaa.R
measures[["cmprsk.ibs"]] = MeasureCompRisksIntegratedBrierScore
