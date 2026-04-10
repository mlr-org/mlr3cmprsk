#' @title Brier Score Competing Risks Measure
#' @name mlr_measures_cmprsk.brier
#' @templateVar id cmprsk.brier
#' @template cmprsk_measure
#'
#' @description
#' Calculates the competing risks prediction error (Brier score, BS) at a
#' **specific time point**, using IPCW as described in Schopp et al. (2011).
#'
#' @details
#' By default, this measure returns a **cause-independent BS(t)** score,
#' calculated as a weighted average of the cause-specific Brier scores.
#' The weights correspond to the relative event frequencies of each cause,
#' following Equation (8) in Spitoni et al. (2018).
#' User-supplied weights are also supported.
#' Alternatively, users can obtain the **cause-specific** Brier score for any
#' individual cause by specifying the `cause` parameter.
#'
#' Calls [riskRegression::Score()] with:
#' - `metric = "brier"`
#' - `cens.method = "ipcw"`
#' - `cens.model = "km"`
#'
#' Notes on the `riskRegression` implementation:
#' 1. IPCW weights are estimated using the **test data only**, so smaller test
#' sets may lead to less stable estimates.
#' 2. No extrapolation is supported: if `time` exceeds the maximum observed
#' time on the test data, an error is thrown.
#'
#' @section Parameter details:
#' - `cause` (`numeric(1)|"mean"`)\cr
#'  Integer number indicating which cause to use.
#'  Default value is `"mean"` which returns an event-frequency weighted mean of
#'  the cause-specific Brier scores.
#' - `cause_weights` (`numeric()` | `NULL`)\cr
#'  Optional custom weights for `cause = "mean"`.
#'  If `NULL`, observed cause frequencies in the test data are used.
#'  The weights must be non-negative, sum to 1 and match the number of causes 1-1,
#'  i.e. first weight for first cause, second weight for second cause, etc.
#'  See Spitoni et al. (2018), Equation (8) for a similar weighting scheme.
#' - `time` (`numeric(1)`)\cr
#'  Single time point at which to return the score.
#'  If `NULL`, the **median observed time point** from the test set is used.
#'
#' @references
#' `r format_bib("schoop_2011", "spitoni_2018")`
#'
#' @templateVar msr_id brier
#' @template example_fine_gray
#' @export
MeasureCompRisksBrierScore = R6Class(
  "MeasureCompRisksBrierScore",
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
        id = "cmprsk.brier",
        param_set = param_set,
        range = c(0, Inf),
        minimize = TRUE,
        properties = "na_score",
        packages = "riskRegression",
        label = "Competing Risks Brier Score (fixed time)",
        man = "mlr3cmprsk::mlr_measures_cmprsk.brier"
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

      # Define evaluation time (single time point for BS)
      time = if (is.null(pv$time)) {
        median(data$time)
      } else {
        assert_number(pv$time, lower = 0, finite = TRUE, na.ok = FALSE)
      }

      # list of predicted CIF matrices
      cif_list = prediction$cif
      causes = names(cif_list)

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
          stop("Cause weights must sum to 1.")
        }
      }

      aggregation = validate_cause_aggregation(pv$cause, causes)

      cause_brier = function(cause) {
        # get CIF on the given time point
        mat = survdistr::interp_cif(
          x = cif_list[[cause]], # cause-specific CIF
          eval_times = time,
          add_times = FALSE,
          check = FALSE
        )

        # calculate BS(t) score
        res = riskRegr_score(
          mat_list = list(mat),
          metric = "brier",
          data = data,
          formula = form,
          times = time,
          cause = cause
        )

        extract_metric_value(res, metric = "brier", times = time)
      }

      if (aggregation$mode == "single") {
        return(cause_brier(aggregation$cause))
      }

      brier_scores = vapply(causes, cause_brier, numeric(1L))

      aggregate_cause_scores(brier_scores, data$event, cause_weights)
    }
  )
)

#' @include aaa.R
measures[["cmprsk.brier"]] = MeasureCompRisksBrierScore
