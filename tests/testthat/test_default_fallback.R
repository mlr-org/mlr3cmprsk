test_that("default_fallback", {
  learner = lrn("cmprsk.fg")
  fallback = default_fallback(learner)
  expect_class(fallback, "LearnerCompRisksAalenJohansen")
  expect_equal(fallback$predict_type, "cif")

  # rejects unsupported predict types
  learner$.__enclos_env__$private$.predict_type = "response"
  expect_equal(learner$predict_type, "response")

  expect_error(
    default_fallback(learner),
    "Fallback learner 'cmprsk.aalen' does not support predict type 'response'.",
    class = "Mlr3ErrorConfig",
    fixed = TRUE
  )
})

test_that("default_fallback trains on all feature types", {
  data = tsk("pbc")$data(cols = c("time", "status", "age"))
  data$ord = factor(rep_len(c("a", "b"), nrow(data)), ordered = TRUE)
  data$chr = "a"
  data$date = as.Date("2020-01-01")
  data$pxc = as.POSIXct("2020-01-01", tz = "UTC")
  task = as_task_cmprsk(data, time = "time", event = "status")

  fallback = default_fallback(lrn("cmprsk.fg"))
  expect_subset(c("featureless", "missings"), fallback$properties)
  expect_set_equal(fallback$feature_types, mlr_reflections$task_feature_types)
  expect_prediction(fallback$train(task)$predict(task))
  task$select(character())
  expect_prediction(fallback$train(task)$predict(task))
})
