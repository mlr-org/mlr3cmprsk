#' @title Competing Risks Task Generator
#' @name mlr_task_generators_cmprsk
#'
#' @description
#' A [mlr3::TaskGenerator] for simulating right-censored competing risks tasks
#' with numerical baseline covariates.
#'
#' Uses [sim_cmprsk()] to generate event times and causes from cause-specific
#' Weibull proportional hazards, with independent right-censoring.
#' The default `shape = 1` corresponds to constant cause-specific hazards
#' (exponential event times), while other values allow increasing or
#' decreasing hazards over time.
#'
#' See `sim_cmprsk()` for the underlying statistical model, parameter
#' definitions, and defaults.
#'
#' @details
#' The generated [TaskCompRisks] contains the observed `time`, `event`, and
#' numerical features `x1`, ..., `xp`. Event codes are integers, with `0`
#' indicating censoring and `1`, ..., `n_causes` identifying competing causes.
#'
#' Generation fails if any requested cause is absent among the observed events.
#' Event and censoring proportions may differ from their specified targets due
#' to sampling variability and covariate effects; see [sim_cmprsk()] for details.
#'
#' Use [set.seed()] before `$generate()` for reproducibility.
#'
#' @section Dictionary:
#' This generator is available through [mlr3::mlr_task_generators] and [mlr3::tgen()]:
#' ```
#' mlr_task_generators$get("cmprsk")
#' tgen("cmprsk")
#' ```
#'
#' @section Parameters:
#' `r mlr3misc::rd_info(mlr3::tgen("cmprsk")$param_set)`
#'
#' @references
#' `r format_bib("beyersmann_2009")`
#'
#' @seealso [sim_cmprsk()], [mlr3::mlr_task_generators]
#' @family TaskGenerator
#' @export
#' @examples
#' library(mlr3)
#' library(mlr3cmprsk)
#'
#' generator = tgen(
#'   "cmprsk",
#'   n_features = 5L,
#'   n_causes = 3L,
#'   event_probs = c(0.4, 0.2, 0.1)
#' )
#'
#' set.seed(42)
#' task = generator$generate(1000L)
#' task
#'
#' # Observed event and censoring proportions
#' prop.table(table(task$event()))
TaskGeneratorCompRisks = R6Class(
  "TaskGeneratorCompRisks",
  inherit = TaskGenerator,
  public = list(
    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      param_set = ps(
        n_features = p_int(lower = 1L, upper = 10L, default = 3L),
        n_causes = p_int(lower = 2L, upper = 5L, default = 2L),
        event_probs = p_uty(
          default = NULL,
          special_vals = list(NULL),
          custom_check = check_cmprsk_event_probs
        ),
        shape = p_dbl(lower = 0, default = 1),
        rate = p_dbl(lower = 0, default = 0.2),
        beta_sd = p_dbl(lower = 0, default = 0.3)
      )

      super$initialize(
        id = "cmprsk",
        task_type = "cmprsk",
        packages = "mlr3cmprsk",
        param_set = param_set,
        label = "Competing risks",
        man = "mlr3cmprsk::mlr_task_generators_cmprsk"
      )
    }
  ),

  private = list(
    .generate = function(n) {
      pv = self$param_set$get_values()
      data = invoke(sim_cmprsk, n = n, .args = pv)
      cols = c("time", "event", paste0("x", seq_len(pv$n_features %??% 3L)))
      TaskCompRisks$new(sprintf("%s_%i", self$id, n), data[, cols, with = FALSE])
    }
  )
)

#' @include aaa.R
task_generators[["cmprsk"]] = TaskGeneratorCompRisks
