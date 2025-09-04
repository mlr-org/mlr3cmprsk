#' @title Primary Biliary Cholangitis Competing Risks Task
#'
#' @name mlr_tasks_pbc
#' @templateVar type CompRisks
#' @templateVar task_type competing risks
#' @templateVar id pbc
#' @templateVar data pbc
#' @templateVar data_pkg survival
#' @template task
#' @template seealso_task
#'
#' @section Pre-processing:
#' - Removed column `id`.
#' - Kept only complete cases (no missing values).
#' - Column `age` has been converted to `integer`.
#' - Columns `trt`, `stage`, `hepato`, `edema` and `ascites` have been converted
#' to `factor`s.
#' - Column `trt` has levels `Dpenicillmain` and `placebo` instead of 1 and 2.
#' - Column `status` has 0 for censored, 1 for transplant and 2 for death.
#' - Column `time` as been converted from days to months.
NULL
load_pbc = function() {
  data = survival::pbc
  data = stats::na.omit(data)
  data$id = NULL
  data = map_at(data, c("age"), as.integer)
  data = map_at(data, c("spiders", "hepato", "edema", "ascites"), as.factor)
  data$trt = factor(ifelse(data$trt == 1, "Dpenicillmain", "placebo"),
                    levels = c("Dpenicillmain", "placebo"))
  data$stage = factor(data$stage)
  data$time = floor(data$time / 30.44) # convert to months

  b = as_data_backend(data)
  task = TaskCompRisks$new("pbc", b, time = "time", event = "status",
                           label = "Primary Biliary Cholangitis")
  b$hash = task$man = "mlr3cmprsk::mlr_tasks_pbc"

  task
}

#' @include aaa.R
tasks[["pbc"]] = load_pbc
