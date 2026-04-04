#' @title Fine-Gray Competing Risks Learner
#' @name mlr_learners_cmprsk.fg
#' @templateVar id cmprsk.fg
#' @template cmprsk_learner
#'
#' @description
#' Fine-Gray subdistribution hazards model for competing risks using
#' [cmprsk::crr()].
#'
#' @details
#'
#' The fitted model is an S3 object of class `"fine_gray"` that stores a
#' cause-specific list of `crr` class models.
#'
#' At prediction time, each cause-specific model is evaluated with
#' [cmprsk::predict.crr()] and the resulting CIF matrices are aligned to a common
#' time grid across causes using constant CIF interpolation.
#' The time grid is the **unique event times (across all causes)** observed in the training set.
#'
#' Time-interaction terms (via `cov2`) are not implemented.
#'
#' @references
#' `r format_bib("fine_1999")`
#'
#' @template example_fine_gray
#' @export
LearnerCompRisksFineGray = R6Class("LearnerCompRisksFineGray",
  inherit = LearnerCompRisks,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      param_set = ps(
        censgroup = p_dbl(tags = "train"),
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
        label = "Competing Risks Regression: Fine-Gray model",
        man = "mlr3cmprsk::mlr_learners_cmprsk.fg"
      )
    }
  ),

  private = list(
    .train = function(task) {
      cov1 = as.matrix(task$data(cols = task$feature_names))
      ftime = task$times()
      fstatus = task$event()
      cmp_events = task$cmp_events

      pv = self$param_set$get_values(tags = "train")

      # different Fine-Gray model per competing event
      model_list = lapply(cmp_events, function(cause) {
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

      names(model_list) = cmp_events
      class(model_list) = "fine_gray"

      model_list
    },

    .predict = function(task) {
      cov1 = as.matrix(task$data(cols = task$feature_names))

      cif_list = map(self$model, function(m) {
        p = invoke(cmprsk::predict.crr, m, cov1 = cov1)
        cif_mat = t(p[, -1, drop = FALSE])
        colnames(cif_mat) = p[, 1] # first column is the time points
        cif_mat
      })

      cif_list = align_cifs(cif_list, bind_rows = FALSE)

      list(cif = cif_list)
    }
  )
)

#' @include aaa.R
learners[["cmprsk.fg"]] = LearnerCompRisksFineGray
