#' @title Aalen Johansen Competing Risks Learner
#' @name mlr_learners_cmprsk.aalen
#' @templateVar id cmprsk.aalen
#' @template cmprsk_learner
#'
#' @description
#' This learner estimates the Cumulative Incidence Function (CIF) for competing
#' risks using the empirical Aalen-Johansen (AJ) estimator.
#'
#' Transition probabilities to each competing event are computed from the training
#' data via the [survival::survfit.formula()] function.
#' Predictions are made at all **unique event times (across all causes)** observed
#' in the training set.
#'
#' @references
#' `r format_bib("aalen_1978")`
#'
#' @template example_aalen
#' @export
LearnerCompRisksAalenJohansen = R6Class("LearnerCompRisksAalenJohansen",
  inherit = LearnerCompRisks,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      super$initialize(
        id = "cmprsk.aalen",
        predict_types = "cif",
        feature_types = c("logical", "integer", "numeric", "factor"),
        properties = c("missings", "weights", "importance", "selected_features"),
        packages = "survival",
        label = "Aalen-Johansen Estimator",
        man = "mlr3cmprsk::mlr_learners_cmprsk.aalen"
      )
    },

    #' @description
    #' All features have a score of `0` for this learner.
    #' This method exists solely for compatibility with the `mlr3` ecosystem,
    #' as this learner is used as a fallback for other survival learners that
    #' require an `importance()` method.
    #'
    #' @return Named `numeric()`.
    importance = function() {
      if (is.null(self$model)) {
        stopf("No model stored")
      }

      fn = self$model$features
      named_vector(fn, 0)
    },

    #' @description
    #' Selected features are always the empty set for this learner.
    #' This method is implemented only for compatibility with the `mlr3` API,
    #' as this learner does not perform feature selection.
    #'
    #' @return `character(0)`.
    selected_features = function() {
      if (is.null(self$model)) {
        stopf("No model stored")
      }

      character()
    }
  ),

  private = list(
    .train = function(task) {
      survfit_obj = invoke(
        survival::survfit,
        formula = task$formula(1),
        data = task$data(cols = task$target_names),
        .args = list(weights = private$.get_weights(task))
      )

      list(
        model = survfit_obj,
        features = task$feature_names, # keep features for importance
        event_times = task$unique_event_times() # add event times for use in prediction
      )
    },

    .predict = function(task) {
      survfit_model = self$native_model
      trans_mat = survfit_model$pstate
      trans_mat = trans_mat[, -1] # remove (s0) => prob of 'staying' censored (state 0)

      times = survfit_model$time # unique time points from train set
      event_times = self$model$event_times # unique event times from train set

      idx = which(times %in% event_times)
      times = times[idx] # keep only the unique event times
      trans_mat = trans_mat[idx, , drop = FALSE]

      n_obs = task$nrow # number of test observations
      cif_list = stats::setNames(vector("list", ncol(trans_mat)), colnames(trans_mat))

      for (i in seq_along(cif_list)) {
        cif_list[[i]] = matrix(
          data = rep(trans_mat[, i], times = n_obs),
          nrow = n_obs,
          byrow = TRUE,
          dimnames = list(NULL, times)
        )
      }

      list(cif = cif_list)
    }
  ),

  active = list(
    #' @field native_model ([survival::survfit])\cr
    #' The fitted model.
    native_model = function() {
      self$model$model
    }
  )
)

#' @include aaa.R
learners[["cmprsk.aalen"]] = LearnerCompRisksAalenJohansen
