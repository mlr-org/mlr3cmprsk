#' @section Package Options:
#' The following options control optional predicted CIF diagnostics and default to `FALSE`.
#' Set them with [options()] to enable diagnostics package-wide.
#'
#' * `mlr3cmprsk.warn_cif_sum`: Warn with class `Mlr3WarningCIFSumExceedsOne`
#' when predictions contain cause-specific CIFs whose sum exceeds 1 (allowing
#' numerical tolerance). Predictions are retained without changing their
#' probabilities. Enable by using `options(mlr3cmprsk.warn_cif_sum = TRUE)`.
#' * `mlr3cmprsk.warn_cif_extrapolation`: Warn with class `Mlr3WarningCIFExtrapolation`
#' when a measure evaluates times after a scored cause's final CIF anchor.
#' CIFs are constantly extrapolated after the final anchor.
#' One warning lists all affected causes per scoring call.
#' Enable by using `options(mlr3cmprsk.warn_cif_extrapolation = TRUE)`.
#'
#' @import checkmate
#' @import data.table
#' @import mlr3
#' @import mlr3misc
#' @import paradox
#' @importFrom R6 R6Class
#' @importFrom survival Surv
#' @importFrom utils getFromNamespace tail
#' @importFrom stats median
"_PACKAGE"

# add tasks, learners and measures to mlr3 dictionaries
register_mlr3cmprsk = function() {
  x = utils::getFromNamespace("mlr_tasks", ns = "mlr3")
  iwalk(tasks, function(obj, nm) x$add(nm, obj))

  x = utils::getFromNamespace("mlr_learners", ns = "mlr3")
  iwalk(learners, function(obj, nm) x$add(nm, obj))

  x = utils::getFromNamespace("mlr_measures", ns = "mlr3")
  iwalk(measures, function(obj, nm) x$add(nm, obj))
}

.onLoad = function(libname, pkgname) {
  # logger
  lg = lgr::get_logger("mlr3/core")
  assign("lg", lg, envir = parent.env(environment()))

  # reflections
  ## tasks
  x = utils::getFromNamespace("mlr_reflections", ns = "mlr3")
  x$task_types = x$task_types[!"cmprsk"] # to ensure we don't have multiple row entries of 'surv'
  x$task_types = setkeyv(
    rbind(
      x$task_types,
      rowwise_table(
        ~type,
        ~package,
        ~task,
        ~learner,
        ~prediction,
        ~prediction_data,
        ~measure,
        "cmprsk",
        "mlr3cmprsk",
        "TaskCompRisks",
        "LearnerCompRisks",
        "PredictionCompRisks",
        "PredictionDataCompRisks",
        "MeasureCompRisks"
      )
    ),
    "type"
  )
  x$task_col_roles$cmprsk = x$task_col_roles$regr
  x$task_properties$cmprsk = x$task_properties$regr

  ## measures
  x$measure_properties$cmprsk = x$measure_properties$regr
  x$default_measures$cmprsk = "cmprsk.ibs"

  ## learners
  x$learner_properties$cmprsk = x$learner_properties$regr
  x$learner_predict_types$cmprsk = list(cif = "cif")

  # dictionary
  register_namespace_callback(pkgname, "mlr3", register_mlr3cmprsk)
}

.onUnload = function(libpath) {
  walk(names(learners), function(id) mlr_learners$remove(id))
  walk(names(measures), function(id) mlr_measures$remove(id))
  walk(names(tasks), function(id) mlr_tasks$remove(id))

  # reflections
  x = utils::getFromNamespace("mlr_reflections", ns = "mlr3")
  type = NULL # silence data.table note
  x$task_types = x$task_types[type != "cmprsk"]
  x$task_col_roles$cmprsk = NULL
  x$task_properties$cmprsk = NULL
  x$measure_properties$cmprsk = NULL
  x$default_measures$cmprsk = NULL
  x$learner_properties$cmprsk = NULL
  x$learner_predict_types$cmprsk = NULL
}

leanify_package()
