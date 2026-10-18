test_that("default_fallback works", {
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
