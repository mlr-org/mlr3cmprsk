#' @title Mouse Cancer Competing Risks Task
#'
#' @name mlr_tasks_hoel
#' @templateVar type CompRisks
#' @templateVar task_type competing risks
#' @templateVar task_id hoel
#' @templateVar data hoel
#' @templateVar data_pkg survival
#' @template task
#' @template seealso_task
#'
#' @section Competing risks scenario:
#' Death is the terminal event, classified as thymic lymphoma (cause 1),
#' reticulum cell sarcoma (cause 2), or other causes of death (cause 3).
#' This is a classical competing risks setting where the recorded causes of
#' death are mutually exclusive.
#'
#' @section Pre-processing:
#' - Removed `id` and retained `trt` as the only feature, preserving its factor
#'   levels `Control` and `Germ-free` without conversion.
#' - Renamed `days` to `time`, preserving the original values in days.
#' - Replaced `outcome` with integer `event` using the original factor labels:
#'   `censor` = 0, `thymic lymphoma` = 1, `reticulum cell sarcoma` = 2, and `other` = 3.
#'   Code 0 does not occur in these data.
NULL
load_hoel = function() {
  data = survival::hoel
  data$id = NULL
  names(data)[names(data) == "days"] = "time"
  event_codes = c(
    "censor" = 0L,
    "thymic lymphoma" = 1L,
    "reticulum cell sarcoma" = 2L,
    "other" = 3L
  )
  data$event = unname(event_codes[as.character(data$outcome)])
  data$outcome = NULL

  b = as_data_backend(data)
  task = TaskCompRisks$new(
    "hoel",
    b,
    time = "time",
    event = "event",
    label = "Mouse Cancer Data"
  )
  b$hash = task$man = "mlr3cmprsk::mlr_tasks_hoel"

  task
}

#' @include aaa.R
tasks[["hoel"]] = load_hoel
