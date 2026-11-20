#' @title Aalen Johansen Competing Risks Learner
#' @name mlr_learners_cmprsk.aalen
#' @templateVar learner_id cmprsk.aalen
#' @template cmprsk_learner
#' @template seealso_learner
#'
#' @description
#' This learner estimates the Cumulative Incidence Function (CIF) for competing
#' risks using the empirical Aalen-Johansen (AJ) estimator.
#'
#' Transition probabilities to each competing event are computed from the training
#' data via the [survival::survfit.formula()] function.
#' Each predicted CIF is evaluated on **its cause's unique training event times**.
#' The grid uses the fitted times, so `survfit()` can group nearly identical event
#' times into a single time point.
#' With observation weights, a time appears in a cause's grid only if the total
#' weight of that cause's events at that time is positive.
#' These numeric grids are stored in the prediction's `$times` field.
#' Causes without training events have a zero CIF anchored at time 0.
#'
#' @references
#' `r format_bib("aalen_1978")`
#'
#' @template example
#' @examples
#' # Score predictions
#' predictions$score()
#' @export
LearnerCompRisksAalenJohansen = R6Class(
  "LearnerCompRisksAalenJohansen",
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
    #' may require an `importance()` method.
    #'
    #' @return Named `numeric()`.
    importance = function() {
      if (is.null(self$model)) {
        error_learner("No model stored")
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
        error_learner("No model stored")
      }

      character()
    }
  ),

  private = list(
    .train = function(task) {
      survfit_model = invoke(
        survival::survfit,
        formula = task$formula("1"),
        data = task$data(cols = task$target_names),
        .args = list(weights = private$.get_weights(task))
      )

      list(
        model = survfit_model,
        features = task$feature_names, # for importance()
        event_times = set_names(
          map(task$causes, function(cause) {
            # Event counts are weighted, and column 1 corresponds to censoring
            survfit_model$time[survfit_model$n.event[, cause + 1L] > 0]
          }),
          as.character(task$causes)
        )
      )
    },

    .predict = function(task) {
      survfit_model = self$native_model
      # Drop initial state (censoring) => keep one CIF column per cause
      trans_mat = survfit_model$pstate[, -1L, drop = FALSE]

      n_causes = ncol(trans_mat)
      cif_list = set_names(
        vector("list", n_causes),
        as.character(seq_len(n_causes))
      )

      # Extract each cause's CIF at its own event times
      times = self$model$event_times
      n_obs = task$nrow
      for (i in seq_along(cif_list)) {
        cif_values = if (length(times[[i]])) {
          trans_mat[match(times[[i]], survfit_model$time), i]
        } else {
          # An absent cause has CIF(t = 0) = 0
          times[[i]] = 0
          0
        }

        cif_list[[i]] = matrix(
          data = rep(cif_values, times = n_obs),
          nrow = n_obs,
          byrow = TRUE
        )
      }

      structure(list(cif = cif_list), times = times)
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
