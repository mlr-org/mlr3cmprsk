#' @title Fine-Gray Competing Risks Learner
#' @name mlr_learners_cmprsk.fg
#' @templateVar learner_id cmprsk.fg
#' @template cmprsk_learner
#' @template seealso_learner
#'
#' @description
#' Fine-Gray subdistribution hazards model for competing risks using
#' [cmprsk::crr()].
#'
#' @details
#'
#' A separate Fine-Gray subdistribution hazards model is fitted for every cause in `task$causes`.
#' This follows the [LearnerCompRisks] design: predictions contain CIFs for all available causes.
#'
#' The fitted model is an S3 object of class `"fine_gray"` that stores a list of
#' cause-specific `crr` class models.
#'
#' At prediction time, each cause-specific model is evaluated with
#' [cmprsk::predict.crr()], retaining its native cause-specific event-time grid.
#' Each grid contains the **unique training event times for that cause** and is stored
#' in the prediction's `$times` field.
#'
#' Independently fitted cause-specific models can produce CIFs whose sum exceeds 1.
#' The corresponding warning is disabled package-wide by default, as it can recur on every prediction call.
#' Set `options(mlr3cmprsk.warn_cif_sum = TRUE)` to enable it.
#' See also Package Options section in [mlr3cmprsk-package].
#'
#' Time-interaction terms (via `cov2`) are not implemented.
#'
#' @references
#' `r format_bib("fine_1999")`
#'
#' @template example
#' @examples
#' # Score predictions
#' predictions$score()
#' @export
LearnerCompRisksFineGray = R6Class(
  "LearnerCompRisksFineGray",
  inherit = LearnerCompRisks,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      param_set = ps(
        cengroup = p_uty(tags = "train"),
        gtol = p_dbl(default = 1e-06, lower = 0, tags = "train"),
        maxiter = p_int(default = 10L, lower = 0L, tags = "train"),
        init = p_uty(tags = "train"),
        variance = p_lgl(default = TRUE, tags = "train")
      )

      super$initialize(
        id = "cmprsk.fg",
        param_set = param_set,
        predict_types = "cif",
        feature_types = c("logical", "integer", "numeric"),
        packages = "cmprsk",
        label = "Fine-Gray subdistribution hazards model",
        man = "mlr3cmprsk::mlr_learners_cmprsk.fg"
      )
    }
  ),

  private = list(
    .train = function(task) {
      cov1 = as.matrix(task$data(cols = task$feature_names))
      ftime = task$times()
      fstatus = task$event()
      causes = as.character(task$causes)

      pv = self$param_set$get_values(tags = "train")

      # different Fine-Gray model per competing event
      model_list = lapply(causes, function(cause) {
        invoke(
          cmprsk::crr,
          ftime = ftime,
          fstatus = fstatus,
          cov1 = cov1,
          failcode = as.integer(cause),
          cencode = 0L,
          .args = pv
        )
      })

      names(model_list) = causes
      class(model_list) = "fine_gray"

      model_list
    },

    .predict = function(task) {
      cov1 = as.matrix(task$data(cols = task$feature_names))

      predictions = map(self$model, function(m) {
        # predict.crr() returns one row per training event time for this cause
        # The first column holds the times, followed by one CIF column per test observation
        invoke(cmprsk::predict.crr, m, cov1 = cov1)
      })
      # Keep each cause's time grid as a separate numeric vector
      times = map(predictions, function(p) as.numeric(p[, 1L]))
      # Transpose the CIF values so rows index test observations and columns index times
      cif_list = map(predictions, function(p) unname(t(p[, -1L, drop = FALSE])))

      structure(list(cif = cif_list), times = times)
    }
  )
)

#' @include aaa.R
learners[["cmprsk.fg"]] = LearnerCompRisksFineGray
