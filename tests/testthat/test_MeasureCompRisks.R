test_that("competing risks measures are available", {
  expect_r6(msr("cmprsk.auc"), "MeasureCompRisksAUC")
  #expect_r6(msr("cmprsk.brier"), "MeasureCompRisksBrierScore")
  #expect_r6(msr("cmprsk.ibs"), "MeasureCompRisksIntegratedBrierScore")
})

test_that("cmprsk.auc works", {
  task = tsk("pbc")
  feats = c("age", "chol", "albumin", "ast", "bili", "protime")
  task$select(feats)

  l1 = lrn("cmprsk.aalen")
  l2 = lrn("cmprsk.fg")
  p1 = l1$train(task)$predict(task)
  p2 = l2$train(task)$predict(task)

  m = msr("cmprsk.auc")
  expect_equal(m$properties, "na_score")
  expect_equal(m$minimize, FALSE)
  expect_equal(m$param_set$values$cause, "mean")

  # AUC should be 0.5 for AJ estimator
  auc_aj = p1$score(m)
  expect_equal(auc_aj, 0.5, ignore_attr = TRUE)
  # Fine-Gray should have AUC > 0.5 across causes
  auc_fg = p2$score(m)
  expect_gt(auc_fg, 0.5)

  # AUC can't be calculated via RiskRegression beyond the
  # maximum observed time from the test set
  m = msr("cmprsk.auc", time_horizon = 160)
  suppressMessages(expect_error(p1$score(m)))
  suppressMessages(expect_error(p2$score(m)))

  # request for early time point where no event have yet happened gives NaN AUC
  m = msr("cmprsk.auc", time_horizon = 5)
  expect_warning(p2$score(m), class = "RiskRegressionScoreNaN")

  # check usage of cause_weights for AUC calculation
  m = msr("cmprsk.auc", cause = "mean", cause_weights = c(1, 0))
  expect_equal(m$param_set$values$cause_weights, c(1, 0))
  auc1 = p2$score(m)

  m = msr("cmprsk.auc", cause = 1)
  auc11 = p2$score(m)
  expect_equal(auc1, auc11)

  m = msr("cmprsk.auc", cause = "mean", cause_weights = c(0, 1))
  expect_equal(m$param_set$values$cause_weights, c(0, 1))
  auc2 = p2$score(m)

  m = msr("cmprsk.auc", cause = 2)
  auc22 = p2$score(m)
  expect_equal(auc2, auc22)

  m = msr("cmprsk.auc", cause = "mean", cause_weights = c(0.5, 0.5))
  expect_equal(m$param_set$values$cause_weights, c(0.5, 0.5))
  auc_mean = p2$score(m)
  expect_equal(auc_mean, (auc1 + auc2) / 2)
  # weighted mean AUC across causes should be different from mean AUC across causes
  expect_true(auc_fg != auc_mean)

  # manually calculate weighted mean AUC across causes with user-specified weights
  event = task$event()
  weights = unname(prop.table(table(event[event != 0])))
  m = msr("cmprsk.auc", cause = "mean", cause_weights = weights)
  expect_equal(p2$score(m), auc_fg)
})
