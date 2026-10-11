#' @title Integrated Brier Score Competing Risks Measure
#' @name mlr_measures_cmprsk.ibs
#' @templateVar measure_id cmprsk.ibs
#' @template cmprsk_measure
#'
#' @description
#' Calculates the integrated competing risks prediction error (integrated Brier score, IBS)
#' using IPCW as described in Schoop et al. (2011).
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
#' 2. Evaluation is limited to the maximum observed test-set follow-up time.
#' See the **Integration grid** section for how this restriction is applied.
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
#'  Explicit integration grid, supplied as a sorted vector of at least two
#'  distinct, finite, non-negative time points.
#'  Default is `NULL`, which uses an automatically generated grid.
#'  `t_max` and `t_quantile` must both be `NULL` when supplying explicit `times`.
#' - `ntimes` (`integer(1)`)\cr
#'  Number of points in an automatically constructed integration grid, including
#'  time 0 and the upper integration horizon.
#'  Must be at least 2; default is 100.
#'  Ignored when supplying explicit `times`.
#' - `t_max` (`numeric(1)`|`NULL`)\cr
#'  Finite, non-negative upper integration horizon; default is `NULL`.
#'  Mutually exclusive with `t_quantile`.
#' - `t_quantile` (`numeric(1)`|`NULL`)\cr
#'  Quantile probability of observed test-set follow-up times used to determine
#'  the upper integration horizon.
#'  Default is `NULL`, which uses the 90th percentile.
#'  Mutually exclusive with `t_max`.
#'
#' @template cmprsk_cause_weights
#' @template cmprsk_time_grid
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
          check_numeric(
            x,
            lower = 0,
            min.len = 2L,
            unique = TRUE,
            sorted = TRUE,
            finite = TRUE,
            any.missing = FALSE,
            null.ok = TRUE
          )
        }),
        ntimes = p_uty(default = 100L, custom_check = function(x) {
          check_int(x, lower = 2L)
        }),
        t_max = p_uty(default = NULL, special_vals = list(NULL), custom_check = function(x) {
          check_number(x, lower = 0, finite = TRUE, null.ok = TRUE)
        }),
        t_quantile = p_uty(default = NULL, special_vals = list(NULL), custom_check = function(x) {
          check_number(x, lower = 0, upper = 1, finite = TRUE, null.ok = TRUE)
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

      # check time grid parameters
      times = pv$times
      if (!is.null(pv$t_max) && !is.null(pv$t_quantile)) {
        error_input("`t_max` and `t_quantile` are mutually exclusive.")
      }
      if (!is.null(times) && (!is.null(pv$t_max) || !is.null(pv$t_quantile))) {
        error_input(
          "`t_max` and `t_quantile` must both be NULL when explicit `times` are supplied."
        )
      }

      t_max_test = max(data$time)
      if (is.null(times)) {
        # get upper integration horizon tau
        tau = if (!is.null(pv$t_max)) {
          validate_tau(pv$t_max, t_max_test)
        } else {
          stats::quantile(data$time, probs = pv$t_quantile %??% 0.9, names = FALSE)
        }
        # generate integration time grid
        times = seq(from = 0, to = tau, length.out = pv$ntimes %??% 100L)
      }
      times = validate_times(times, t_max_test, integrated = TRUE)

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
