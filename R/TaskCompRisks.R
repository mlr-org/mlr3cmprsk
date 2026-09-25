#' @title Competing Risks Task
#'
#' @description
#'
#' This task extends [mlr3::Task] and [mlr3::TaskSupervised] for competing risks survival analysis.
#' The target consists of a survival time and an event indicator.
#' Event codes must be non-negative integers in \eqn{(0, 1, 2, ..., K)}.
#' \eqn{0} denotes censoring, and positive integers denote distinct event causes.
#' Each row represents one observation.
#'
#' Predefined tasks are stored in [mlr3::mlr_tasks].
#'
#' The `task_type` is set to `"cmprsk"`.
#'
#' @details
#' The following design choices apply to this task:
#' - Only **right-censoring** is currently supported.
#' - Tasks must contain at **least two event causes**, i.e., \eqn{K \geq 2},
#' encoded as consecutive integers \eqn{1, 2, ..., K}.
#'
#' It is advised to use **stratified resampling** to reduce the risk of creating
#' training splits with fewer than two causes, which may cause issues during
#' model training (and later prediction).
#' Task filtering specifically issues a warning when the number of competing events
#' is reduced but remains >= 2, and an error if fewer than two causes remain.
#'
#' @template param_rows
#'
#' @family Task
#' @examples
#' library(mlr3)
#' task = tsk("pbc")
#'
#' # Time and event target columns
#' task$target_names
#' # Feature names
#' task$feature_names
#' # Censoring type
#' task$cens_type
#'
#' # survival data
#' task$formula(c("age", "sex")) # formula with survival::Surv() on LHS
#' task$truth() # survival::Surv() object
#' task$times() # (unsorted) times
#' task$event() # event indicators (0 = censored, >0 = different causes)
#' task$unique_times() # sorted unique times
#' task$unique_event_times() # sorted unique event times (from any cause)
#' task$cens_prop() # proportion of censored observations
#'
#' # Aalen-Johansen estimator
#' task$aalen_johansen(strata = "sex")
#'
#' # Causes
#' task$cmp_events
#'
#' @export
TaskCompRisks = R6Class(
  "TaskCompRisks",
  inherit = TaskSupervised,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    #'
    #' @details
    #' Only right-censoring competing risk tasks are currently supported.
    #'
    #' @template param_id
    #' @template param_backend
    #' @template param_time
    #' @template param_event
    #' @template param_label
    initialize = function(id, backend, time = "time", event = "event", label = NA_character_) {
      # only right-censoring supported
      private$.cens_type = "right"
      backend = as_data_backend(backend)

      # check event is an integer starting from 0
      event_vals = get_private(backend)$.data[, event, with = FALSE][[1L]]
      assert_integerish(event_vals, lower = 0L, any.missing = FALSE)

      # competing events must be encoded as 1, 2, ..., K
      causes = sort(setdiff(unique(event_vals), 0L))
      n_causes = length(causes)
      if (n_causes < 2L) {
        error_input(
          "Define at least two causes, there are only %i competing events in the data",
          n_causes
        )
      }

      causes = as.integer(causes)
      expected_causes = seq_len(n_causes)
      if (!identical(causes, expected_causes)) {
        error_input(
          "Causes must be consecutive integers starting at 1 (1, 2, ..., K), but got: %s",
          str_collapse(causes)
        )
      }

      # keep all the event levels
      private$.causes = as.character(causes)

      super$initialize(
        id = id,
        task_type = "cmprsk",
        backend = backend,
        target = c(time, event),
        label = label
      )
    },

    #' @description
    #' True response for specified `row_ids`. This is the multi-state format
    #' using [Surv][survival::Surv()] with the `event` target column as a `factor`.
    #' Defaults to all rows with role `"use"`.
    #'
    #' @return [survival::Surv()].
    truth = function(rows = NULL) {
      tn = self$target_names
      data = self$data(rows = rows, cols = self$target_names)
      times = data[[tn[1L]]]
      events = data[[tn[2L]]]

      args = list(
        time = times,
        # levels is needed, otherwise subsetting `Surv()` doesn't work as it should
        event = factor(events, levels = c("0", self$cmp_events))
      )

      invoke(Surv, .args = args)
    },

    #' @description
    #' Creates a formula for competing risk models with [survival::Surv()] on
    #' the LHS (left hand side).
    #'
    #' @param rhs
    #' If `NULL`, RHS (right hand side) is `"."`, otherwise RHS is `"rhs"`.
    #'
    #' @return [stats::formula()].
    formula = function(rhs = NULL) {
      tn = self$target_names
      event_levels = str_collapse(c("0", self$cmp_events), sep = ", ")
      lhs = sprintf("Surv(`%s`, factor(`%s`, levels = c(%s)))", tn[1L], tn[2L], event_levels)
      formulate(lhs, rhs %??% ".", env = getNamespace("survival"))
    },

    #' @description
    #' Returns the (unsorted) outcome times.
    #' @return `numeric()`
    times = function(rows = NULL) {
      truth = self$truth(rows)
      as.numeric(truth[, 1L])
    },

    #' @description
    #' Returns the event indicators.
    #' \eqn{0} denotes censoring, and positive integers denote distinct event causes.
    #' @return `integer()`
    event = function(rows = NULL) {
      truth = self$truth(rows)
      as.integer(truth[, 2L])
    },

    #' @description
    #' Returns the sorted unique outcome times.
    #' @return `numeric()`
    unique_times = function(rows = NULL) {
      sort(unique(self$times(rows)))
    },

    #' @description
    #' Returns the sorted unique event outcome times (by any cause).
    #' @return `numeric()`
    unique_event_times = function(rows = NULL) {
      sort(unique(self$times(rows)[self$event(rows) != 0]))
    },

    #' @description
    #' Calls [survival::survfit()] to calculate the Aalen–Johansen estimator.
    #'
    #' @param strata (`character()`)\cr
    #'   Stratification variables to use.
    #' @param rows (`integer()`)\cr
    #'   Subset of row indices.
    #' @param ... (any)\cr
    #'   Additional arguments passed down to [survival::survfit.formula()].
    #' @return [survival::survfit.object].
    aalen_johansen = function(strata = NULL, rows = NULL, ...) {
      assert_character(strata, null.ok = TRUE)
      f = self$formula(strata %??% 1)
      cols = c(self$target_names, intersect(self$backend$colnames, strata))
      data = self$data(rows = rows, cols = cols)
      survival::survfit(f, data = data, ...)
    },

    #' @description
    #' Returns the **proportion of censored observations** for this competing risks task.
    #'
    #' @return `numeric()`
    cens_prop = function(rows = NULL) {
      event = self$event(rows)
      total_censored = sum(event == 0)
      n_obs = length(event)

      total_censored / n_obs
    },

    #' @description
    #' Subsets the task, keeping only the rows specified via the row ids `rows`.
    #' This operation mutates the task in-place.
    #' A warning is thrown if the filtering results in fewer competing events
    #' than the original task.
    #' An error is thrown if fewer than two competing events remain after filtering.
    #'
    #' @return Returns the object itself, but modified **by reference.**
    filter = function(rows = NULL) {
      events_before = self$cmp_events
      n_events_before = length(events_before)
      events_after = setdiff(unique(self$event(rows)), 0)
      n_events_after = length(events_after)

      if (n_events_after < 2L) {
        error_input(
          "Can't filter task '%s': row filtering leaves %i competing event(s), but at least 2 are required",
          self$id,
          n_events_after
        )
      }

      if (n_events_after < n_events_before) {
        warning_mlr3(
          "While filtering task '%s': %i competing events found, but row filtering
          results in %i unique competing events.\nThis may result in errors when
          training models as some causes will be missing from the data.",
          self$id,
          n_events_before,
          n_events_after
        )
      }

      super$filter(rows)
    }
  ),

  active = list(
    #' @field cens_type (`character(1)`)\cr
    #' Returns the type of censoring.
    #'
    #' Currently, only `"right"` censoring type is supported.
    #' The API might change in the future to support left and interval censoring.
    cens_type = function(rhs) {
      assert_ro_binding(rhs)
      private$.cens_type
    },

    #' @field cmp_events (`character()`)\cr
    #' Returns the competing event names: `"1"`, `"2"`, ..., `"K"`, in that order.
    cmp_events = function(rhs) {
      assert_ro_binding(rhs)
      private$.causes
    }
  ),

  private = list(
    .cens_type = NULL,
    .causes = NULL
  )
)
