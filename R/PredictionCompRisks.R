#' @title Prediction Object for Competing Risks
#'
#' @description
#' This object stores the predictions returned by a learner of class [LearnerCompRisks].
#'
#' The `task_type` is set to `"cmprsk"`.
#'
#' Causes use consecutive codes 1, 2, ..., K, matching the task used for prediction.
#' By design, predictions contain one CIF matrix for every cause in `task$cmp_events`,
#' including causes that are not observed among the predicted observations.
#' Filtering prediction rows retains all cause levels and CIFs, even for unobserved causes.
#' Combining predictions requires the same cause set.
#'
#' Accessing all-cause survival or cause-specific hazard functions or similar quantities
#' from a [LearnerCompRisks] object is not possible at the moment.
#'
#' @family Prediction
#' @examples
#' library(mlr3)
#' task = tsk("pbc")
#' learner = lrn("cmprsk.aalen")
#' part = partition(task)
#' p = learner$train(task, part$train)$predict(task, part$test)
#' p
#'
#' # CIF list: 1 matrix (obs x times) per competing event
#' names(p$cif) # competing events
#' # CIF matrix for competing event 1 (first 5 test observations and 20 time points)
#' p$cif[["1"]][1:5, 1:20]
#' # CIF matrix for competing event 2 (first 5 test observations and 20 time points)
#' p$cif[["2"]][1:5, 1:20]
#'
#' # data.table conversion
#' tab = as.data.table(p)
#' tab$CIF[[1]] # for first test observation, list of CIF vectors
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
    #' The `cif` input is a list of CIF matrices.
    #' With `check = TRUE`, nonempty predictions are validated using [assert_cif_list()].
    #' This checks the list structure and cause names, the time points used for
    #' prediction, and validates each CIF matrix, including probabilities in \[0, 1\]
    #' and non-decreasing probabilities over time.
    #'
    #' Joint coherence is checked separately by aligning the CIF matrices on a common time grid
    #' and summing their probabilities across causes for each observation and time point.
    #' A sum greater than 1, allowing a numerical tolerance of `sqrt(.Machine$double.eps)`,
    #' triggers a warning of class `Mlr3WarningCIFSumExceedsOne`.
    #' The prediction is retained without modifying its probabilities.
    #' Such sums can occur with independently fitted cause-specific models, such
    #' as the Fine-Gray model.
    #'
    #' @param task ([TaskCompRisks])\cr
    #'   Task, used to extract defaults for `row_ids` and `truth`.
    #'
    #' @param row_ids (`integer()`)\cr
    #'   Row ids of the predicted observations, i.e. the row ids of the test set.
    #'
    #' @param truth (`survival::Surv()`)\cr
    #'   True (observed) response.
    #'   State names must be `"1"`, `"2"`, ..., `"K"`, in that order, matching the CIF list.
    #'
    #' @param cif (`list()`)\cr
    #'   A required `list` of two or more `matrix` objects.
    #'   Each matrix represents a different competing event (or cause) and stores the
    #'   **Cumulative Incidence function** for each test observation.
    #'   In each matrix, rows represent observations and columns time points.
    #'   The names of the `list` must correspond to the cause names in the `truth`
    #'   object, i.e. `"1"`, `"2"`, ..., `"K"`, exactly in that order.
    #'
    #' @param check (`logical(1)`)\cr
    #'   If `TRUE`, performs argument checks.
    #'   Use `TRUE` for user-supplied data.
    #'   With `FALSE`, inputs are assumed valid and correct behavior is not guaranteed.
    initialize = function(
      task = NULL,
      row_ids = task$row_ids,
      truth = task$truth(),
      cif,
      check = TRUE
    ) {
      pdata = list(row_ids = row_ids, truth = truth, cif = cif)
      pdata = discard(pdata, is.null)
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
    #' @field truth (`Surv`)\cr
    #' True (observed) outcome.
    truth = function() {
      self$data$truth
    },

    #' @field cif (`list()`)\cr
    #' Access the stored CIFs.
    cif = function() {
      # TODO: convert to `survdistr` object with methods for easier conversion and interpolation
      self$data$cif
    }
  )
)

#' @export
as.data.table.PredictionCompRisks = function(x, ...) {
  tab = as.data.table(x$data["row_ids"])
  tab$time = x$data$truth[, 1L]
  tab$event = as.integer(x$data$truth[, 2L])
  n_obs = length(x$row_ids)

  if ("cif" %in% x$predict_types && n_obs > 0) {
    tab$CIF = lapply(1:n_obs, function(i) {
      # we use a list since there is a possibility that each CIF matrix has
      # different number of time points (columns) per competing risk
      cif_list = lapply(x$cif, function(mat) mat[i, , drop = TRUE])
      names(cif_list) = names(x$cif) # preserve the cause ids
      cif_list
    })
  }

  setcolorder(tab, c("row_ids", "time", "event"))[]
}
