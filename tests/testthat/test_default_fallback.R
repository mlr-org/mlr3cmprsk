test_that("fallback = default_fallback() works", {
  learner = lrn("cmprsk.aalen")
  fallback = default_fallback(learner)
  expect_class(fallback, "LearnerCompRisksAalenJohansen")
  expect_equal(fallback$predict_type, "cif")
})
