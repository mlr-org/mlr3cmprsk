expect_task_cmprsk = function(task) {
  expect_class(task, "TaskCompRisks")
  expect_task(task)
  expect_task_supervised(task)
  expect_class(task$truth(), "Surv")
  expect_equal(task$task_type, "cmprsk")

  f = task$formula()
  expect_formula(f)
  expect_setequal(mlr3misc::extract_vars(f)$lhs, task$target_names)
  expect_class(task$aalen_johansen(), "survfit")
  expect_numeric(task$event(), lower = 0, finite = TRUE, any.missing = FALSE)
  expect_numeric(task$times(), lower = 0, finite = TRUE, any.missing = FALSE)
  expect_numeric(task$unique_times(), unique = TRUE, any.missing = FALSE)
  expect_numeric(task$unique_event_times(), unique = TRUE, any.missing = FALSE)
  expect_number(task$cens_prop(), lower = 0, upper = 1, finite = TRUE, any.missing = FALSE)
  expect_in(task$cens_type, c("right"))
  expect_character(task$cmp_events, any.missing = FALSE)
}

expect_prediction_cmprsk = function(p) {
  testthat::expect_output(print(p), "Prediction")
  expect_data_table(data.table::as.data.table(p), nrows = length(p$row_ids))
  expect_integerish(p$missing)
  expect_r6(p, "Prediction", public = c("row_ids", "truth", "predict_types", "cif"))

  n_obs = length(assert_row_ids(p$row_ids))
  if (n_obs > 0) {
    assert_surv(p$truth, len = n_obs)
    causes = attr(p$truth, "states")
    assert_cif_list(p$cif, n_rows = n_obs, n_causes = length(causes))
  }

  expect_class(p, "PredictionCompRisks")
}
