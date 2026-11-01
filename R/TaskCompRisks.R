#' @title Competing Risks Task
#'
#' @description
#'
#' This task extends [mlr3::Task] and [mlr3::TaskSupervised] for competing risks survival analysis.
#' The target outcome consists of a survival time and an event indicator.
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
#' # General info
#' task
#'
#' # Time and event target columns
#' task$target_names
#' # Feature names
#' task$feature_names
#' # Censoring type
#' task$cens_type
#'
#' # Survival data
#' task$formula(c("age", "sex")) # formula with survival::Surv() on LHS
#' task$truth() # survival::Surv() object
#' task$times() # (unsorted) times
#' task$event() # event indicators (0 = censored, >0 = different causes)
#' task$unique_times() # sorted unique times
#' task$unique_event_times() # sorted unique event times (from any cause)
#' task$unique_event_times(cause = 1L) # times for cause 1 only
#' task$cens_prop() # proportion of censored observations
#' task$event_counts() # observed counts and proportions, including censoring
#'
#' # Aalen-Johansen estimator
#' task$aalen_johansen(strata = "sex")
#'
#' # Causes
#' task$n_causes
#' task$causes
#' task$cause_names
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
    #' @template param_cause_names
    initialize = function(
      id,
      backend,
      time = "time",
      event = "event",
      label = NA_character_,
      cause_names = NULL
    ) {
      # only right-censoring supported
      private$.cens_type = "right"
      backend = as_data_backend(backend)

      # check event is an integer starting from 0
      assert_choice(event, backend$colnames)
      event_vals = backend$data(rows = backend$rownames, cols = event)[[1L]]
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
      private$.causes = causes
      private$.cause_names = assert_cause_names(cause_names, causes)

      super$initialize(
        id = id,
        task_type = "cmprsk",
        backend = backend,
        target = c(time, event),
        label = label
      )
    },

    #' @description
    #' Prints the task information, including cause names, event counts,
    #' proportions, and censoring frequency.
    #'
    #' @param ... (any)\cr
    #'   Additional arguments passed to the parent print method.
    #'
    #' @return The task object, invisibly.
    print = function(...) {
      super$print(...)
      counts = self$event_counts()

      cat_cli({
        cli_li("Causes ({self$n_causes}):")
        ulid = cli_ul()
        for (cause in self$causes) {
          cause_text = sprintf("%i (%s)", cause, self$cause_names[[as.character(cause)]])
          text = sprintf(
            "%s: %i (%.1f%%)",
            cause_text,
            counts$n[cause + 1L],
            100 * counts$prop[cause + 1L]
          )
          cli_li("{text}")
        }
        cli_end(ulid)

        censored = sprintf("%i (%.1f%%)", counts$n[1L], 100 * counts$prop[1L])
        cli_li("Censored: {censored}")
      })

      invisible(self)
    },

    #' @description
    #' True response for specified `row_ids`. This is the multi-state format
    #' using [Surv][survival::Surv()] with the `event` target column as a `factor`.
    #' Descriptive cause names are stored in the response's `states` attribute.
    #' Defaults to all active rows with role `"use"`.
    #'
    #' @return [survival::Surv()].
    truth = function(rows = NULL) {
      tn = self$target_names
      data = self$data(rows = rows, cols = self$target_names)
      times = data[[tn[1L]]]
      events = data[[tn[2L]]]

      args = list(
        time = times,
        # levels is needed for `Surv()` to preserve all causes
        event = factor(
          events,
          levels = 0:self$n_causes,
          labels = c("Censored", unname(self$cause_names))
        )
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
      event_levels = str_collapse(0:self$n_causes, sep = ", ")
      event_labels = paste(deparse(c("Censored", unname(self$cause_names))), collapse = "")
      lhs = sprintf(
        "Surv(`%s`, factor(`%s`, levels = c(%s), labels = %s))",
        tn[1L],
        tn[2L],
        event_levels,
        event_labels
      )
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
    #' `0` denotes censoring, and positive integers denote distinct event causes.
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
    #' Returns the sorted unique event outcome times, optionally restricted to
    #' a specific cause.
    #'
    #' @param cause (`integer(1)`|`NULL`)\cr
    #'   Cause code from `$causes`, or `NULL` to include events of every cause.
    #'
    #' @return `numeric()`
    unique_event_times = function(rows = NULL, cause = NULL) {
      if (!is.null(cause)) {
        assert_int(cause, lower = 1L, upper = self$n_causes)
      }

      events = self$event(rows)
      times = self$times(rows)
      keep = if (is.null(cause)) events != 0L else events == cause

      sort(unique(times[keep]))
    },

    #' @description
    #' Calls [survival::survfit()] to calculate the Aalen–Johansen estimator.
    #'
    #' @param strata (`character()`)\cr
    #'   Vector of features to use for stratification.
    #' @param rows (`integer()`)\cr
    #'   Subset of row indices.
    #' @param ... (any)\cr
    #'   Additional arguments passed down to [survival::survfit.formula()].
    #' @return [survival::survfit.object].
    aalen_johansen = function(strata = NULL, rows = NULL, ...) {
      assert_character(strata, any.missing = FALSE, unique = TRUE, null.ok = TRUE)
      assert_subset(strata, self$feature_names)

      f = self$formula(strata %??% 1)
      cols = c(self$target_names, strata)
      data = self$data(rows = rows, cols = cols)
      survival::survfit(f, data = data, ...)
    },

    #' @description
    #' Returns the counts and relative frequencies of observed outcomes,
    #' including censoring (`0`) and all competing causes (`1`, ..., `K`).
    #' Frequencies are calculated over the specified rows (all active rows by default).
    #'
    #' @return A [data.table::data.table()] with columns:
    #' - `cause`: Integer cause code (`0` denotes censoring).
    #' - `name`: Descriptive cause name.
    #' - `n`: Number of observations.
    #' - `prop`: Proportion of observations.
    event_counts = function(rows = NULL) {
      events = self$event(rows)
      counts = tabulate(events + 1L, nbins = self$n_causes + 1L)

      data.table(
        cause = 0:self$n_causes,
        name = c("Censored", unname(self$cause_names)),
        n = counts,
        prop = counts / length(events)
      )
    },

    #' @description
    #' Returns the **proportion of censored observations** for this competing risks task.
    #'
    #' @return `numeric()`
    cens_prop = function(rows = NULL) {
      events = self$event(rows)
      n_cens = sum(events == 0)
      n_obs = length(events)

      n_cens / n_obs
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
      n_events_before = self$n_causes
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
          "Original task '%s' has %i competing events, but row filtering
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
    #' Currently, only `"right"` censoring type is supported.
    cens_type = function(rhs) {
      assert_ro_binding(rhs)
      private$.cens_type
    },

    #' @field causes (`integer()`)\cr
    #' Read-only cause codes `1, 2, ..., K`, including causes absent from the active rows.
    causes = function(rhs) {
      assert_ro_binding(rhs)
      private$.causes
    },

    #' @field n_causes (`integer(1)`)\cr
    #' Read-only number of defined causes, excluding censoring.
    n_causes = function(rhs) {
      assert_ro_binding(rhs)
      length(private$.causes)
    },

    #' @field cause_names (`character()`)\cr
    #' Named vector with read-only descriptive names of the competing events.
    #' Names are the codes `1, 2, ..., K`. All causes are included, even those
    #' absent from the task's active rows.
    cause_names = function(rhs) {
      assert_ro_binding(rhs)
      set_names(private$.cause_names, nm = as.character(private$.causes))
    }
  ),

  private = list(
    .cens_type = NULL,
    .causes = NULL, # integer vector
    .cause_names = NULL # character vector
  )
)
