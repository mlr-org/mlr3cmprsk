#' @title Liver Transplant Waiting List Competing Risks Task
#'
#' @name mlr_tasks_transplant
#' @templateVar type CompRisks
#' @templateVar task_type competing risks
#' @templateVar task_id transplant
#' @templateVar data transplant
#' @templateVar data_pkg survival
#' @template task
#' @template seealso_task
#'
#' @section Competing risks scenario:
#' The competing events are mutually exclusive exit-events from the liver transplant
#' waiting list: death (cause 1), liver transplantation (cause 2), or withdrawal
#' (cause 3), with 0 indicating censoring.
#' This analysis reduces a potentially more complex multi-state process to the
#' first outcome that happens to patients on the waiting list.
#' Patients may die after transplantation or withdrawal, but subsequent events
#' are not considered.
#'
#' @section Pre-processing:
#' - Kept only complete cases (no missing values).
#' - Removed four observations with zero follow-up time.
#' - Renamed `futime` to `time`, preserving the original values in days.
#' - Retained numeric predictors `age` and `year` and the existing factors
#'   `sex` and `abo`, without conversion.
#' - Replaced the factor `event` with integer codes using its labels:
#'   `censored` = 0, `death` = 1, `ltx` = 2 (liver transplantation), and `withdraw` = 3.
NULL
load_transplant = function() {
  data = survival::transplant
  data = stats::na.omit(data)
  data = data[data$futime > 0, ]
  names(data)[names(data) == "futime"] = "time"
  event_codes = c(censored = 0L, death = 1L, ltx = 2L, withdraw = 3L)
  data$event = unname(event_codes[as.character(data$event)])

  b = as_data_backend(data)
  task = TaskCompRisks$new(
    "transplant",
    b,
    time = "time",
    event = "event",
    label = "Liver Transplant Waiting List Data"
  )
  b$hash = task$man = "mlr3cmprsk::mlr_tasks_transplant"

  task
}

#' @include aaa.R
tasks[["transplant"]] = load_transplant
