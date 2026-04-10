test_that("competing risks measures are available", {
  expect_r6(msr("cmprsk.auc"), "MeasureCompRisksAUC")
  expect_r6(msr("cmprsk.brier"), "MeasureCompRisksBrierScore")
  #expect_r6(msr("cmprsk.ibs"), "MeasureCompRisksIntegratedBrierScore")
})

task = tsk("pbc")
feats = c("age", "chol", "albumin", "ast", "bili", "protime")
task$select(feats)

l1 = lrn("cmprsk.aalen")
l2 = lrn("cmprsk.fg")
p1 = l1$train(task)$predict(task)
p2 = l2$train(task)$predict(task)

test_that("cmprsk.auc works", {
  m = msr("cmprsk.auc")
  expect_equal(m$properties, "na_score")
  expect_equal(m$minimize, FALSE)
  expect_equal(m$param_set$values$cause, "mean")

  # AUC(t) should be 0.5 for AJ estimator
  auc_aj = p1$score(m)
  expect_equal(auc_aj, 0.5, ignore_attr = TRUE)
  # Fine-Gray should have AUC > 0.5 across causes
  auc_fg = p2$score(m)
  expect_gt(auc_fg, 0.5)

  # AUC(t) can't be calculated via RiskRegression beyond the
  # maximum observed time from the test set
  m = msr("cmprsk.auc", time = 160)
  suppressMessages(expect_error(p1$score(m)))
  suppressMessages(expect_error(p2$score(m)))

  # request for early time point where no event have yet happened gives NaN AUC
  m = msr("cmprsk.auc", time = 5)
  expect_warning(p2$score(m), class = "RiskRegressionScoreNaN")

  # request for cause that doesn't exist should give an error
  m = msr("cmprsk.auc", cause = 3)
  expect_error(p2$score(m), "Invalid cause")

  # check usage of cause_weights for AUC(t) calculation
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

test_that("cmprsk.brier works", {
  m = msr("cmprsk.brier")
  expect_equal(m$properties, "na_score")
  expect_equal(m$minimize, TRUE)
  expect_equal(m$param_set$values$cause, "mean")

  # BS(t) for AJ estimator should be higher compared to Fine-Gray model
  bs_aj = p1$score(m)
  bs_fg = p2$score(m)
  expect_gt(bs_aj, bs_fg)

  # BS(t) can't be calculated via RiskRegression beyond the
  # maximum observed time from the test set
  m = msr("cmprsk.brier", time = 160)
  suppressMessages(expect_error(p1$score(m)))
  suppressMessages(expect_error(p2$score(m)))

  # request for early time point works just fine for BS(t)
  m = msr("cmprsk.brier", time = 3)
  expect_gte(p1$score(m), 0)
  expect_gte(p2$score(m), 0)

  # request for cause that doesn't exist should give an error
  m = msr("cmprsk.brier", cause = 3)
  expect_error(p2$score(m), "Invalid cause")

  # check usage of cause_weights for BS(t) calculation
  m = msr("cmprsk.brier", cause = "mean", cause_weights = c(1, 0))
  expect_equal(m$param_set$values$cause_weights, c(1, 0))
  bs1 = p2$score(m)

  m = msr("cmprsk.brier", cause = 1)
  bs11 = p2$score(m)
  expect_equal(bs1, bs11)

  m = msr("cmprsk.brier", cause = "mean", cause_weights = c(0, 1))
  expect_equal(m$param_set$values$cause_weights, c(0, 1))
  bs2 = p2$score(m)

  m = msr("cmprsk.brier", cause = 2)
  bs22 = p2$score(m)
  expect_equal(bs2, bs22)

  m = msr("cmprsk.brier", cause = "mean", cause_weights = c(0.5, 0.5))
  expect_equal(m$param_set$values$cause_weights, c(0.5, 0.5))
  bs_mean = p2$score(m)
  expect_equal(bs_mean, (bs1 + bs2) / 2)
  # weighted mean BS(t) across causes should be different from mean BS(t) across causes
  expect_true(bs_fg != bs_mean)

  # manually calculate weighted mean BS(t) across causes with user-specified weights
  event = task$event()
  weights = unname(prop.table(table(event[event != 0])))
  m = msr("cmprsk.brier", cause = "mean", cause_weights = weights)
  expect_equal(p2$score(m), bs_fg)
})
