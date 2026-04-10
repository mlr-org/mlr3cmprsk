#' @title Blanche's AUC Competing Risks Measure
#' @name mlr_measures_cmprsk.auc
#' @templateVar id cmprsk.auc
#' @template cmprsk_measure
#'
#' @description
#' Calculates the time-dependent ROC-AUC at a **specific time point**,
#' as described in Blanche et al. (2013).
#'
#' @details
#' By default, this measure returns a **cause-independent AUC(t)** score,
#' calculated as a weighted average of the cause-specific AUCs.
#' The weights correspond to the relative event frequencies of each cause,
#' following Equation (7) in Heyard et al. (2020).
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
#' 2. No extrapolation is supported: if `time` exceeds the maximum observed
#' time on the test data, an error is thrown.
#' 3. The choice of `time` is critical: if, at that time, no events of a
#' given cause have occurred and all predicted CIFs are zero, `riskRegression`
#' will return `NaN` for that cause-specific AUC (and subsequently for the
#' summary AUC).
#'
#' @section Parameter details:
#' - `cause` (`numeric(1)|"mean"`)\cr
#'  Integer number indicating which cause to use.
#'  Default value is `"mean"` which returns a event-frequency weighted mean of
#'  the cause-specific AUCs.
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
#' `r format_bib("blanche_2013", "spitoni_2018", "heyard_2020")`
#'
#' @template example_fine_gray
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
        label = "Blanche's Time-dependent IPCW ROC-AUC score",
        man = "mlr3cmprsk::mlr_measures_cmprsk.auc"
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

      # Define evaluation time (single time point for AUC)
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

      cause_auc = function(cause) {
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

        extract_metric_value(res, metric = "auc", times = time)
      }

      if (aggregation$mode == "single") {
        return(cause_auc(aggregation$cause))
      }

      aucs = vapply(causes, cause_auc, numeric(1L))

      aggregate_cause_scores(
        scores = aucs,
        method = aggregation$cause, # "mean"
        event = data$event,
        cause_weights = cause_weights
      )
    }
  )
)

#' @include aaa.R
measures[["cmprsk.auc"]] = MeasureCompRisksAUC
