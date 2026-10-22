#' @title Monoclonal Gammopathy Competing Risks Task
#'
#' @name mlr_tasks_mgus2
#' @templateVar type CompRisks
#' @templateVar task_type competing risks
#' @templateVar task_id mgus2
#' @templateVar data mgus2
#' @templateVar data_pkg survival
#' @template task
#' @template seealso_task
#'
#' @section Competing risks scenario:
#' The competing events are progression to plasma cell malignancy (PCM, cause 1)
#' and death without prior progression (cause 2), with 0 indicating censoring.
#' The original data describe a multi-state process in which patients can progress
#' and subsequently die.
#' This task focuses only on the occurrence of the first event, reducing the
#' multi-state process to the competing risks setting, such that progression and
#' death with no prior progression are mutually exclusive events.
#'
#' @section Pre-processing:
#' - Kept only complete cases (no missing values).
#' - Constructed `time = ifelse(pstat == 1, ptime, futime)`, preserving the
#'   original time units in months.
#' - Constructed integer `event`: 1 for progression (`pstat == 1`),
#'   2 for death without prior progression (`pstat == 0` and `death == 1`),
#'   and 0 for censoring (`pstat == 0` and `death == 0`).
#'   Note that 9 subjects have progression and death recorded in the same month;
#'   these are classified as progression (cause 1).
#' - Removed `id` and the original outcome columns `ptime`, `pstat`, `futime`, and `death`.
#' - Retained features `age`, `sex`, `dxyr`, `hgb`, `creat`, and `mspike`.
#'   Kept `sex` as its original factor and the other predictors numeric, without conversion.
NULL
load_mgus2 = function() {
  data = survival::mgus2
  data = stats::na.omit(data)
  # event transformation is similar to the competing risks vignette
  # https://cran.r-project.org/web/packages/survival/vignettes/compete.pdf
  data$time = ifelse(data$pstat == 1, data$ptime, data$futime)
  data$event = ifelse(data$pstat == 1, 1L, ifelse(data$death == 1, 2L, 0L))
  data = data[, c("age", "sex", "dxyr", "hgb", "creat", "mspike", "time", "event")]

  b = as_data_backend(data)
  task = TaskCompRisks$new(
    "mgus2",
    b,
    time = "time",
    event = "event",
    label = "Monoclonal Gammopathy Data"
  )
  b$hash = task$man = "mlr3cmprsk::mlr_tasks_mgus2"

  task
}

#' @include aaa.R
tasks[["mgus2"]] = load_mgus2
