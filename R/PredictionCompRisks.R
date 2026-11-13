#' @title Prediction Object for Competing Risks
#'
#' @description
#' Stores competing risks predictions returned by a learner of class [LearnerCompRisks].
#'
#' - The `$cif` field provides **cumulative incidence function (CIF) predictions**,
#' with one matrix (observations x times) per cause.
#' - The `$times` field provides the corresponding numeric time grids (can be different per cause).
#' - The `$cause_names` field provides the descriptive cause names.
#' - The `task_type` is set to `"cmprsk"`.
#'
#' Accessing all-cause survival or cause-specific hazard functions or similar quantities
#' from the CIF prediction object is not possible at the moment.
#'
#' @family Prediction
#' @examples
#' library(mlr3)
#' task = tsk("pbc")
#' task$select(c("age", "chol", "albumin", "ast", "bili", "protime"))
#' learner = lrn("cmprsk.fg")
#' part = partition(task)
#' p = learner$train(task, part$train)$predict(task, part$test)
#' p
#'
#' # CIF list: one matrix (obs x times) per competing event
#' str(p$cif)
#' # numeric time points for each cause
#' p$times
#' # descriptive names, indexed by numeric cause codes
#' p$cause_names
#' # CIF matrix for cause 1 (first 5 test observations and 5 time points)
#' p$cif[["1"]][1:5, 1:5]
#' # CIF matrix for cause 2 (first 5 test observations and 5 time points)
#' p$cif[["2"]][1:5, 1:5]
#'
#' # data.table conversion
#' tab = as.data.table(p)
#' # CIF for first test observation (2 causes)
#' tab$CIF[[1]]
#' # time points are available in the data.table attributes
#' attr(tab, "times")
#'
#' @export
PredictionCompRisks = R6Class(
  "PredictionCompRisks",
  inherit = Prediction,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    #'
    #' @details
    #' The `cif` input is a named list of numeric CIF matrices, with rows = observations
    #' and columns = time points.
    #' The list names are consecutive cause codes (`"1"`, `"2"`, ..., `"K"`) matching
    #' the task's competing causes.
    #' Predictions contain a matrix for every task cause, including causes absent
    #' from the observed response of the predicted observations.
    #' Filtering observations retains all causes and their CIF matrices.
    #' Combining predictions requires matching cause codes and descriptive names,
    #' and aligns each cause's matrices on the union of its time grids.
    #'
    #' With `check = TRUE`, nonempty predictions are validated using [assert_cif_list()].
    #' This checks the list structure and cause codes, the time points used for
    #' prediction, and validates that each CIF matrix includes probabilities in \[0, 1\]
    #' which are non-decreasing over time.
    #'
    #' With `options(mlr3cmprsk.warn_cif_sum = TRUE)`, joint coherence is checked separately
    #' by aligning the CIF matrices on a common time grid
    #' and summing their probabilities across causes for each observation and time point.
    #' A sum greater than 1, allowing a numerical tolerance of `sqrt(.Machine$double.eps)`,
    #' triggers a warning of class `Mlr3WarningCIFSumExceedsOne`.
    #' This diagnostic is disabled by default; see the Package Options section in [mlr3cmprsk-package].
    #' Predictions are retained without modification.
    #' Such violations can arise when cause-specific CIFs are estimated
    #' independently, as with separately fitted Fine-Gray subdistribution
    #' hazards models.
    #'
    #' @param task ([TaskCompRisks])\cr
    #'   Task, used to extract defaults for `row_ids` and `truth`.
    #'
    #' @param row_ids (`integer()`)\cr
    #'   Row ids of the predicted observations, i.e. the row ids of the test set.
    #'
    #' @param truth (`survival::Surv()`)\cr
    #'   True observed response.
    #'   Descriptive cause names are derived from the `states` attribute, ordered
    #'   by numeric cause code.
    #'
    #' @param cif (`list()`)\cr
    #'   A required `list` of two or more `matrix` objects.
    #'   Each matrix represents a different competing event (or cause) and stores the
    #'   **cumulative incidence function (CIF)** for each test observation.
    #'   For each matrix, rows refer to observations and columns to time points.
    #'   CIF lists must use numeric cause codes as names, i.e.
    #'   `"1"`, `"2"`, ..., `"K"`, exactly in that order.
    #'
    #' @param times (`list()`)\cr
    #'   Required named list of numeric time vectors, with the same names and order as `cif`.
    #'   Each vector must be finite, non-negative, strictly increasing, and have
    #'   one entry per corresponding CIF matrix column.
    #'   Different causes may use different time grids.
    #'
    #' @param weights (`numeric()`)\cr
    #'   Optional measurement weights for the predicted observations, as supplied by a task with
    #'   column role `"weights_measure"`.
    #'
    #' @param extra (`list()`)\cr
    #'   Optional named list of additional per-observation data.
    #'   Each element must have the same length as `row_ids`.
    #'   Names must not be `row_ids`, `time`, `event`, `CIF`, or `weights`, which are reserved prediction columns.
    #'
    #' @param check (`logical(1)`)\cr
    #'   If `TRUE` (default), performs argument checks which is encouraged for user-supplied data.
    #'   With `FALSE`, inputs are assumed valid and correct behavior is not guaranteed.
    initialize = function(
      task = NULL,
      row_ids = task$row_ids,
      truth = task$truth(),
      cif,
      times,
      weights = NULL,
      extra = NULL,
      check = TRUE
    ) {
      assert_flag(check)

      pdata = list(
        row_ids = row_ids,
        truth = truth,
        cif = cif,
        weights = weights,
        extra = extra
      )
      pdata = discard(pdata, is.null)
      attr(pdata, "times") = times
      class(pdata) = c("PredictionDataCompRisks", "PredictionData")

      if (check) {
        pdata = check_prediction_data(pdata)
      }

      self$task_type = "cmprsk"
      self$man = "mlr3cmprsk::PredictionCompRisks"
      self$data = pdata
      self$predict_types = intersect("cif", names(pdata))
    }
  ),

  active = list(
    #' @field times (`list()`)\cr
    #' Read-only numeric time grids, named by cause code and stored as an attribute of `$data`.
    times = function(rhs) {
      assert_ro_binding(rhs)
      attr(self$data, "times")
    },

    #' @field cause_names (`character()`)\cr
    #' Read-only descriptive cause names, named by cause code and stored in the
    #' attribute `states` of `$truth`.
    cause_names = function(rhs) {
      assert_ro_binding(rhs)
      cause_names = attr(self$truth, "states")
      set_names(cause_names, as.character(seq_along(cause_names)))
    },

    #' @field cif (`list()`)\cr
    #' Read-only list of CIF matrices with column names derived from the corresponding `$times` vectors.
    cif = function(rhs) {
      assert_ro_binding(rhs)
      # TODO: convert to `survdistr` object with methods for easier conversion and interpolation

      cif = self$data$cif
      times = self$times
      for (cause in names(times)) {
        colnames(cif[[cause]]) = as.character(times[[cause]])
      }

      cif
    }
  )
)

#' @export
as.data.table.PredictionCompRisks = function(x, ...) {
  tab = as.data.table(x$data["row_ids"])
  tab$time = x$data$truth[, 1L]
  tab$event = as.integer(x$data$truth[, 2L])
  n_obs = length(x$row_ids)

  if ("cif" %in% x$predict_types) {
    tab$CIF = lapply(seq_len(n_obs), function(obs_index) {
      # we use a list since there is a possibility that each CIF matrix has
      # different number of time points (columns) per competing risk
      cif_list = lapply(x$data$cif, function(mat) mat[obs_index, , drop = TRUE])
      names(cif_list) = names(x$data$cif) # preserve the cause codes
      cif_list
    })
  }

  if (!is.null(x$data$weights)) {
    tab$weights = x$data$weights
  }

  if (!is.null(x$data$extra)) {
    tab = cbind(tab, as.data.table(x$data$extra))
  }

  setattr(tab, "cause_names", x$cause_names)
  setattr(tab, "times", x$times)
  setcolorder(tab, c("row_ids", "time", "event"))[]
}
