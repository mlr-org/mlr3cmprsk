#' @title AUC(t) Competing Risks Measure
#' @name mlr_measures_cmprsk.auc
#' @templateVar measure_id cmprsk.auc
#' @template cmprsk_measure
#'
#' @description
#' Calculates the time-dependent ROC-AUC at a **specific time point**,
#' as described in Blanche et al. (2013), Equation 4.
#' Controls include subjects who survive beyond the time horizon
#' and those who experience a competing event before the horizon.
#'
#' @details
#' By default, this measure returns a **cause-independent AUC(t)** score,
#' calculated as a weighted average of the cause-specific AUCs.
#' The weights correspond to the relative event frequencies of each cause,
#' following Equation 7 in Heyard et al. (2020).
#' User-supplied weights are also supported through `cause_weights`.
#' See the **Cause weights** section for weighting rules.
#'
#' Alternatively, users can obtain the **cause-specific AUC(t)** for any
#' individual cause by specifying the `cause` parameter.
#'
#' Calls [riskRegression::Score()] with:
#' - `metric = "auc"`
#' - `cens.method = "ipcw"`
#' - `cens.model = "km"`
#'
#' Notes on the `riskRegression` implementation:
#' 1. IPCW weights are estimated using the **test data only**, so smaller test
#' sets may lead to less stable estimates.
#' 2. Scoring at a `time` beyond the maximum observed test-set time produces an
#' input error.
#' 3. AUC(t) is undefined if no events of the requested cause are observed at or
#' before `time`, or if no controls are available at that time.
#' In these cases, `riskRegression` returns `NaN` for the cause-specific AUC.
#'
#' @template cmprsk_cause_weights
#'
#' @section Parameter details:
#' - `cause` (`numeric(1)|"mean"`)\cr
#'  Integer number indicating which cause to use.
#'  Default value is `"mean"` which returns an event-frequency weighted mean of
#'  the cause-specific AUCs.
#' - `cause_weights` (`numeric()`|`NULL`)\cr
#'  Optional custom weights for `cause = "mean"`.
#'  See the **Cause weights** section for weighting rules.
#' - `time` (`numeric(1)`)\cr
#'  Single time point at which to return the score.
#'  If `NULL`, the **median observed time point** from the test set is used.
#'
#' @references
#' `r format_bib("blanche_2013", "spitoni_2018", "heyard_2020")`
#'
#' @templateVar learner_id cmprsk.fg
#' @template example
#' @template example_measure
#' @export
MeasureCompRisksAUC = R6Class(
  "MeasureCompRisksAUC",
  inherit = MeasureCompRisks,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      param_set = ps(
        cause = p_int(lower = 1, init = "mean", special_vals = list("mean")),
        cause_weights = p_uty(default = NULL, special_vals = list(NULL)),
        time = p_dbl(lower = 0, default = NULL, special_vals = list(NULL))
      )

      super$initialize(
        id = "cmprsk.auc",
        param_set = param_set,
        range = c(0, 1),
        minimize = FALSE,
        properties = "na_score",
        packages = "riskRegression",
        label = "Time-dependent AUC",
        man = "mlr3cmprsk::mlr_measures_cmprsk.auc"
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

      # Define evaluation time (single time point for AUC)
      time = if (is.null(pv$time)) {
        median(data$time)
      } else {
        assert_number(pv$time, lower = 0, finite = TRUE, na.ok = FALSE)
      }
      time = validate_times(time, data$time)

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
      warn_cif_extrapolation(cif_list, time, active_causes)

      auc_score = function(cause) {
        # get CIF on the given time point
        mat = survdistr::interp_cif(
          x = cif_list[[cause]], # cause-specific CIF
          eval_times = time,
          add_times = FALSE,
          check = FALSE
        )

        # calculate AUC(t) score
        res = riskRegr_score(
          mat_list = list(mat),
          metric = "auc",
          data = data,
          formula = form,
          times = time,
          cause = cause
        )

        res$AUC$score$AUC # one time point => one AUC value
      }

      if (cause != "mean") {
        return(auc_score(cause))
      }

      aucs = vapply(active_causes, auc_score, numeric(1L))

      aggregate_cause_causes(aucs, weights[active_causes])
    }
  )
)

#' @include aaa.R
measures[["cmprsk.auc"]] = MeasureCompRisksAUC
