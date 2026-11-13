expect_task_cmprsk = function(task) {
  expect_class(task, "TaskCompRisks")
  expect_task(task)
  expect_task_supervised(task)
  expect_class(task$truth(), "Surv")
  expect_identical(attr(task$truth(), "states"), unname(task$cause_names))
  expect_equal(task$task_type, "cmprsk")

  f = task$formula()
  expect_formula(f)
  expect_setequal(mlr3misc::extract_vars(f)$lhs, task$target_names)
  expect_class(task$aalen_johansen(), "survfit")
  expect_numeric(task$event(), lower = 0, finite = TRUE, any.missing = FALSE)
  expect_numeric(task$times(), lower = 0, finite = TRUE, any.missing = FALSE)
  expect_numeric(task$unique_times(), unique = TRUE, any.missing = FALSE)
  expect_numeric(task$unique_event_times(), unique = TRUE, any.missing = FALSE)
  expect_number(task$cens_prop(), lower = 0, upper = 1, finite = TRUE)
  expect_in(task$cens_type, c("right"))
  expect_integer(task$causes, lower = 1L, unique = TRUE, any.missing = FALSE)
  expect_int(task$n_causes, lower = 2L)
  expect_identical(task$causes, seq_len(task$n_causes))
  expect_character(task$cause_names, len = task$n_causes, unique = TRUE, any.missing = FALSE)
  expect_named(task$cause_names, as.character(task$causes))
}

expect_prediction_cmprsk = function(p) {
  expect_r6(
    p,
    classes = c("Prediction", "PredictionCompRisks"),
    public = c("row_ids", "truth", "predict_types", "cif", "times")
  )
  expect_class(
    p$data,
    classes = c("PredictionData", "PredictionDataCompRisks")
  )
  testthat::expect_output(print(p), "Prediction")
  expect_data_table(data.table::as.data.table(p), nrows = length(p$row_ids))
  assert_class(p$truth, "Surv")
  expect_equal(length(p$truth), length(p$row_ids))
  cause_names = attr(p$truth, "states")
  assert_list(p$cif, types = "matrix", len = length(cause_names))
  expect_equal(names(p$cif), as.character(seq_along(cause_names)))
  expect_named(p$cause_names, names(p$cif))
  expect_identical(unname(p$cause_names), cause_names)
  expect_identical(p$times, attr(p$data, "times"))
}
