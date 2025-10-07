# default competing risk score needs this package
skip_if_not_installed("riskRegression")
skip_if_not_installed("cmprsk")
skip_if_not_installed("rlang")

test_that("autotest", {
  set.seed(42)
  learner = lrn("cmprsk.crr")
  expect_learner(learner)

  result = run_autotest(learner, N = 42, check_replicable = FALSE,
                        exclude = "utf8_feature_names")
    expect_true(result, info = result$error)
})

