#' @import checkmate
#' @import data.table
#' @import mlr3
#' @import mlr3misc
#' @import paradox
#' @importFrom R6 R6Class
#' @importFrom survival Surv
#' @importFrom utils getFromNamespace
# @importFrom stats model.frame terms predict runif dist # IF NEEDED
"_PACKAGE"

# to silence RCMD check - IF NEEDED
# utils::globalVariables(c(
#   "ShortName", "ClassName", "missing", "task", "value", "variable", "y"
# ))

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
  x = getFromNamespace("mlr_reflections", ns = "mlr3")
  x$task_types = x$task_types[!"cmprsk"] # to ensure we don't have multiple row entries of 'surv'
  x$task_types = setkeyv(rbind(x$task_types, rowwise_table(
    ~type,    ~package,       ~task,           ~learner,           ~prediction,            ~prediction_data,          ~measure,
    "cmprsk", "mlr3cmprsk",   "TaskCompRisks", "LearnerCompRisks", "PredictionCompRisks",  "PredictionDataCompRisks", "MeasureCompRisks"
  )), "type")
  x$task_col_roles$cmprsk = x$task_col_roles$regr
  x$task_properties$cmprsk = x$task_properties$regr

  ## measures
  x$measure_properties$cmprsk = x$measure_properties$regr
  x$default_measures$cmprsk = "cmprsk.auc"

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
  x = getFromNamespace("mlr_reflections", ns = "mlr3")
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
