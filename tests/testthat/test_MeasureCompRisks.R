task = tsk("pbc")
feats = c("age", "chol", "albumin", "ast", "bili", "protime")
task$select(feats)

l1 = lrn("cmprsk.aalen")
l2 = lrn("cmprsk.fg")
p1 = l1$train(task)$predict(task)
p2 = suppressWarnings(l2$train(task)$predict(task))

test_that("cmprsk.auc works", {
  m = msr("cmprsk.auc")
  expect_r6(m, "MeasureCompRisksAUC")
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
  expect_error(p1$score(m), "maximum test-set", class = "Mlr3ErrorInput")
  expect_error(p2$score(m), "maximum test-set", class = "Mlr3ErrorInput")

  # request for early time point where no event have yet happened gives NaN AUC
  m = msr("cmprsk.auc", time = 5)
  expect_warning(
    {
      score = p2$score(m)
    },
    regexp = "",
    class = "RiskRegressionScoreNaN"
  )
  expect_true(is.nan(score))

  # request for cause that doesn't exist should give an error
  m = msr("cmprsk.auc", cause = 3)
  expect_error(p2$score(m), "Invalid cause")

  # cause weights must sum to 1
  m = msr("cmprsk.auc", cause = "mean", cause_weights = c(0.5, 0.6))
  expect_error(p2$score(m), "must sum to 1")

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
  expect_equal(auc_mean, 0.5 * auc1 + 0.5 * auc2)
  # weighted mean AUC across causes should be different from mean AUC across causes
  expect_true(auc_fg != auc_mean)

  # manually calculate weighted mean AUC across causes with user-specified weights
  event = task$event()
  weights = unname(prop.table(table(event[event != 0])))
  m = msr("cmprsk.auc", cause = "mean", cause_weights = weights)
  expect_equal(p2$score(m), auc_fg)

  # check that constant CIF extrapolation warning is issued when necessary
  truth = Surv(1:8, factor(c(1, 2, 0, 1, 2, 0, 1, 2), levels = 0:2))
  cif = list(
    "1" = matrix(
      rep(c(0.1, 0.2, 0.3), each = 8L),
      nrow = 8L,
      dimnames = list(NULL, c("2", "4", "6"))
    ),
    "2" = matrix(rep(c(0.1, 0.2), each = 8L), nrow = 8L, dimnames = list(NULL, c("2", "4")))
  )
  p = PredictionCompRisks$new(row_ids = 1:8, truth = truth, cif = cif)
  m = msr("cmprsk.auc")

  # last anchor for cause 2 is at time 4, but we request AUC at time 5
  m$param_set$values$time = 5
  expect_warning(p$score(m), regexp = "2", class = "Mlr3WarningCIFExtrapolation")
  # scoring only cause 2 still issues warning
  m$param_set$values$cause = 2L
  expect_warning(p$score(m), regexp = "2", class = "Mlr3WarningCIFExtrapolation")
  # scoring only cause 1 does not issue warning
  m$param_set$values$cause = 1L
  expect_no_warning(p$score(m))

  # no warning for mean-weighted AUC across causes, when time is smaller than the last
  # anchor for both causes
  m$param_set$values$cause = "mean"
  m$param_set$values$time = 4
  expect_no_warning(p$score(m))
  # now time > last anchor for both causes
  m$param_set$values$time = 7
  expect_warning(p$score(m), regexp = "1, 2", class = "Mlr3WarningCIFExtrapolation")
})

test_that("cmprsk.brier works", {
  m = msr("cmprsk.brier")
  expect_r6(m, "MeasureCompRisksBrierScore")
  expect_equal(m$properties, "na_score")
  expect_equal(m$minimize, TRUE)
  expect_equal(m$param_set$values$cause, "mean")

  # Fine-Gray is better than AJ estimator for BS(t) across causes
  bs_aj = p1$score(m)
  bs_fg = p2$score(m)
  expect_lt(bs_fg, bs_aj)

  # BS(t) can't be calculated via RiskRegression beyond the
  # maximum observed time from the test set
  m = msr("cmprsk.brier", time = 160)
  expect_error(p1$score(m), class = "Mlr3ErrorInput")
  expect_error(p2$score(m), class = "Mlr3ErrorInput")

  # request for early time point works just fine for BS(t)
  m = msr("cmprsk.brier", time = 3)
  expect_gte(p1$score(m), 0)
  expect_gte(p2$score(m), 0)

  # request for cause that doesn't exist should give an error
  m = msr("cmprsk.brier", cause = 3)
  expect_error(p2$score(m), "Invalid cause")

  # cause weights must sum to 1
  m = msr("cmprsk.brier", cause = "mean", cause_weights = c(0.5, 0.6))
  expect_error(p2$score(m), "must sum to 1")

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
  expect_equal(bs_mean, 0.5 * bs1 + 0.5 * bs2)
  # weighted mean BS(t) across causes should be different from mean BS(t) across causes
  expect_true(bs_fg != bs_mean)

  # manually calculate weighted mean BS(t) across causes with user-specified weights
  event = task$event()
  weights = unname(prop.table(table(event[event != 0])))
  m = msr("cmprsk.brier", cause = "mean", cause_weights = weights)
  expect_equal(p2$score(m), bs_fg)

  # check that constant CIF extrapolation warning is issued when necessary
  truth = Surv(1:8, factor(c(1, 2, 0, 1, 2, 0, 1, 2), levels = 0:2))
  cif = list(
    "1" = matrix(
      rep(c(0.1, 0.2, 0.3), each = 8L),
      nrow = 8L,
      dimnames = list(NULL, c("2", "4", "6"))
    ),
    "2" = matrix(rep(c(0.1, 0.2), each = 8L), nrow = 8L, dimnames = list(NULL, c("2", "4")))
  )
  p = PredictionCompRisks$new(row_ids = 1:8, truth = truth, cif = cif)
  m = msr("cmprsk.brier")

  # last anchor for cause 2 is at time 4, but we request BS(t) at time 5
  m$param_set$values$time = 5
  expect_warning(p$score(m), regexp = "2", class = "Mlr3WarningCIFExtrapolation")
  # scoring only cause 2 still issues warning
  m$param_set$values$cause = 2L
  expect_warning(p$score(m), regexp = "2", class = "Mlr3WarningCIFExtrapolation")
  # scoring only cause 1 does not issue warning
  m$param_set$values$cause = 1L
  expect_no_warning(p$score(m))

  # no warning for mean-weighted BS(t) across causes, when time is smaller than the last
  # anchor for both causes
  m$param_set$values$cause = "mean"
  m$param_set$values$time = 4
  expect_no_warning(p$score(m))
  # now time > last anchor for both causes
  m$param_set$values$time = 7
  expect_warning(p$score(m), regexp = "1, 2", class = "Mlr3WarningCIFExtrapolation")
})

test_that("cmprsk.ibs works", {
  m = msr("cmprsk.ibs")
  expect_r6(m, "MeasureCompRisksIntegratedBrierScore")
  expect_equal(m$properties, "na_score")
  expect_equal(m$minimize, TRUE)
  expect_equal(m$param_set$values$cause, "mean")

  # Fine-Gray is better than AJ estimator for IBS across causes
  expect_warning(
    {
      ibs_aj = p1$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )
  expect_warning(
    {
      ibs_fg = p2$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )
  expect_lt(ibs_fg, ibs_aj)

  # IBS can't be calculated via RiskRegression beyond the
  # maximum observed time from the test set (149)
  m = msr("cmprsk.ibs", times = c(0, 1, 10, 100, 120, 150))
  expect_warning(p1$score(m), regexp = "We remove 1 time point", class = "Mlr3Warning")
  expect_warning(p2$score(m), regexp = "We remove 1 time point", class = "Mlr3Warning")
  m = msr("cmprsk.ibs", times = c(0, 1, 10, 100, 120, 150, 200))
  expect_warning(p1$score(m), regexp = "We remove 2 time point", class = "Mlr3Warning")

  # IBS must have at least two distinct time points
  expect_error(msr("cmprsk.ibs", times = 42))
  m = msr("cmprsk.ibs", times = c(42, 160))
  # ...even when some are removed due to being larger than the max test set time
  expect_error(
    expect_warning(p1$score(m), regexp = "We remove 1 time point", class = "Mlr3Warning"),
    regexp = "`times` must contain at least two distinct time points.",
    class = "Mlr3Error"
  )

  # request for early time points works just fine for IBS
  m = msr("cmprsk.ibs", times = c(0, 1, 2))
  expect_gte(p1$score(m), 0)
  expect_gte(p2$score(m), 0)

  # request for cause that doesn't exist should give an error
  m = msr("cmprsk.ibs", cause = 3)
  expect_error(p2$score(m), "Invalid cause")

  # cause weights must sum to 1
  m = msr("cmprsk.ibs", cause = "mean", cause_weights = c(0.5, 0.6))
  expect_error(p2$score(m), "must sum to 1")

  # check usage of cause_weights for IBS calculation
  m = msr("cmprsk.ibs", cause = "mean", cause_weights = c(1, 0))
  expect_equal(m$param_set$values$cause_weights, c(1, 0))
  expect_warning(
    {
      ibs1 = p2$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )

  m = msr("cmprsk.ibs", cause = 1)
  expect_warning(
    {
      ibs11 = p2$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )
  expect_equal(ibs1, ibs11)

  m = msr("cmprsk.ibs", cause = "mean", cause_weights = c(0, 1))
  expect_equal(m$param_set$values$cause_weights, c(0, 1))
  expect_warning(
    {
      ibs2 = p2$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )

  m = msr("cmprsk.ibs", cause = 2)
  expect_warning(
    {
      ibs22 = p2$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )
  expect_equal(ibs2, ibs22)

  m = msr("cmprsk.ibs", cause = "mean", cause_weights = c(0.5, 0.5))
  expect_equal(m$param_set$values$cause_weights, c(0.5, 0.5))
  expect_warning(
    {
      ibs_mean = p2$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )
  expect_equal(ibs_mean, 0.5 * ibs1 + 0.5 * ibs2)
  # weighted mean IBS across causes should be different from mean IBS across causes
  expect_true(ibs_fg != ibs_mean)

  # manually calculate weighted mean IBS across causes with user-specified weights
  event = task$event()
  weights = unname(prop.table(table(event[event != 0])))
  m = msr("cmprsk.ibs", cause = "mean", cause_weights = weights)
  expect_warning(
    {
      ibs_weighted = p2$score(m)
    },
    class = "Mlr3WarningCIFExtrapolation"
  )
  expect_equal(ibs_weighted, ibs_fg)

  # check that constant CIF extrapolation warning is issued when necessary
  truth = Surv(1:8, factor(c(1, 2, 0, 1, 2, 0, 1, 2), levels = 0:2))
  cif = list(
    "1" = matrix(
      rep(c(0.1, 0.2, 0.3), each = 8L),
      nrow = 8L,
      dimnames = list(NULL, c("2", "4", "6"))
    ),
    "2" = matrix(rep(c(0.1, 0.2), each = 8L), nrow = 8L, dimnames = list(NULL, c("2", "4")))
  )
  p = PredictionCompRisks$new(row_ids = 1:8, truth = truth, cif = cif)
  m = msr("cmprsk.ibs")

  # last anchor for cause 2 is at time 4, but we request IBS at times 3 and 5
  m$param_set$values$times = c(3, 5)
  expect_warning(p$score(m), regexp = "2", class = "Mlr3WarningCIFExtrapolation")
  # scoring only cause 2 still issues warning
  m$param_set$values$cause = 2L
  expect_warning(p$score(m), regexp = "2", class = "Mlr3WarningCIFExtrapolation")
  # scoring only cause 1 does not issue warning
  m$param_set$values$cause = 1L
  expect_no_warning(p$score(m))

  # no warning for mean-weighted IBS across causes, when all times are at or before the last
  # anchor for both causes
  m$param_set$values$cause = "mean"
  m$param_set$values$times = c(3, 4)
  expect_no_warning(p$score(m))
  # now the last time > last anchor for both causes
  m$param_set$values$times = c(3, 7)
  expect_warning(p$score(m), regexp = "1, 2", class = "Mlr3WarningCIFExtrapolation")
})
