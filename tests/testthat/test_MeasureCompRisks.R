task = tsk("pbc")
feats = c("age", "chol", "albumin", "ast", "bili", "protime")
task$select(feats)

l1 = lrn("cmprsk.aalen")
l2 = lrn("cmprsk.fg")
p1 = l1$train(task)$predict(task)
p2 = l2$train(task)$predict(task)

test_that("cmprsk.auc works", {
  withr::local_options(list(
    mlr3cmprsk.warn_cif_sum = NULL,
    mlr3cmprsk.warn_cif_extrapolation = NULL
  ))
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
  expect_error(p1$score(m), "test", class = "Mlr3ErrorInput")
  expect_error(p2$score(m), "test", class = "Mlr3ErrorInput")

  # AUC is undefined when a positive-weight cause has no cases by the evaluation time
  m = msr("cmprsk.auc", time = 5)
  expect_warning(
    {
      score = p2$score(m)
    },
    regexp = "Non-finite score",
    class = "RiskRegressionScoreNotFinite"
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

  # AUC is undefined when a requested cause has no cases by the requested time
  p1 = gen_PredictionCompRisks(c(1, 0, 3, 0, 3, 1, 3, 0, 1, 1, 3, 3)) # no event 2
  for (cause in c(2L, 3L)) {
    # we dont issue a NaN warning as the user knows which cause it is!
    expect_true(
      is.nan(p1$score(msr("cmprsk.auc", cause = cause, time = 2)))
    )
  }

  # here, the all-cause score became NaN due to cause 3
  expect_warning(
    {
      score = p1$score(msr("cmprsk.auc", time = 2, cause_weights = c(0.4, 0.1, 0.5)))
    },
    "2, 3",
    class = "RiskRegressionScoreNotFinite"
  )
  expect_true(is.nan(score))

  # Absent causes are skipped when their event-frequency weight is zero
  expect_warning(
    {
      score = p1$score(msr("cmprsk.auc"))
    },
    "zero for cause\\(s\\): 2"
  )

  auc1 = p1$score(msr("cmprsk.auc", cause = 1))
  auc3 = p1$score(msr("cmprsk.auc", cause = 3))
  # Cause 1 accounts for 4/9 events, and cause 3 accounts for 5/9 events
  expect_equal(score, 4 / 9 * auc1 + 5 / 9 * auc3)
  expect_no_warning(
    expect_equal(
      p1$score(msr("cmprsk.auc", cause_weights = c(0.6, 0, 0.4))),
      0.6 * auc1 + 0.4 * auc3
    )
  )

  expect_no_warning({
    score = p1$score(msr("cmprsk.auc", time = 1, cause_weights = c(1, 0, 0)))
  })
  expect_true(is.finite(score))

  # Cases without controls also produce a non-finite AUC
  p2 = gen_PredictionCompRisks(rep(1, 8L)) # only 1st event for all observations
  expect_warning(
    {
      score = p2$score(msr("cmprsk.auc", time = 8, cause_weights = c(1, 0, 0)))
    },
    "1",
    class = "RiskRegressionScoreNotFinite"
  )
  expect_true(is.nan(score))

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
  expect_no_warning(p$score(m))
  withr::local_options(mlr3cmprsk.warn_cif_extrapolation = TRUE)
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
  expect_warning(
    p$score(m),
    regexp = "1, 2",
    class = "Mlr3WarningCIFExtrapolation"
  )

  # follow-up validation fails before checking for extrapolation
  m$param_set$values$time = 9
  expect_no_warning(
    expect_error(p$score(m), regexp = "test", class = "Mlr3ErrorInput")
  )
})

test_that("cmprsk.brier works", {
  withr::local_options(list(
    mlr3cmprsk.warn_cif_sum = NULL,
    mlr3cmprsk.warn_cif_extrapolation = NULL
  ))
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

  # Explicit causes remain calculable without observed events
  p = gen_PredictionCompRisks() # no event 2
  expect_no_warning({
    score = p$score(msr("cmprsk.brier", cause = 2))
  })
  expect_true(is.finite(score))
  expect_gte(score, 0)
  expect_equal(
    score,
    p$score(msr("cmprsk.brier", cause_weights = c(0, 1, 0)))
  )

  # all-cause score with event-frequency weights skips cause 2 (no observed events)
  expect_warning(
    {
      score = p$score(msr("cmprsk.brier"))
    },
    "zero for cause\\(s\\): 2"
  )
  expect_equal(
    score,
    # cause 1 => 2 events (2/5 = 0.4 weight)
    # cause 3 => 3 events (3/5 = 0.6 weight)
    0.4 * p$score(msr("cmprsk.brier", cause = 1)) + 0.6 * p$score(msr("cmprsk.brier", cause = 3))
  )

  # Explicit causes and custom weighting also work when all observations are censored
  p = gen_PredictionCompRisks(rep(0, 8L))
  expect_no_warning({
    score = p$score(msr("cmprsk.brier", cause = 2))
  })
  expect_true(is.finite(score))
  expect_no_warning(
    expect_equal(
      score,
      p$score(msr("cmprsk.brier", cause_weights = c(0, 1, 0)))
    )
  )

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
  expect_no_warning(p$score(m))
  withr::local_options(mlr3cmprsk.warn_cif_extrapolation = TRUE)
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
  expect_warning(
    p$score(m),
    regexp = "1, 2",
    class = "Mlr3WarningCIFExtrapolation"
  )

  # follow-up validation fails before checking for extrapolation
  m$param_set$values$time = 9
  expect_no_warning(expect_error(p$score(m), regexp = "test", class = "Mlr3ErrorInput"))
})

test_that("cmprsk.ibs works", {
  withr::local_options(list(
    mlr3cmprsk.warn_cif_sum = NULL,
    mlr3cmprsk.warn_cif_extrapolation = NULL
  ))
  m = msr("cmprsk.ibs")
  expect_r6(m, "MeasureCompRisksIntegratedBrierScore")
  expect_equal(m$properties, "na_score")
  expect_equal(m$minimize, TRUE)
  expect_equal(m$param_set$values$cause, "mean")
  expect_null(m$param_set$values$times)
  expect_null(m$param_set$values$t_max)
  expect_null(m$param_set$values$t_quantile)
  expect_identical(m$param_set$default$ntimes, 100L)

  # Fine-Gray is better than AJ estimator for IBS across causes
  ibs_aj = p1$score(m)
  ibs_fg = p2$score(m)
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
  ibs1 = p2$score(m)

  m = msr("cmprsk.ibs", cause = 1)
  ibs11 = p2$score(m)
  expect_equal(ibs1, ibs11)

  m = msr("cmprsk.ibs", cause = "mean", cause_weights = c(0, 1))
  expect_equal(m$param_set$values$cause_weights, c(0, 1))
  ibs2 = p2$score(m)

  m = msr("cmprsk.ibs", cause = 2)
  ibs22 = p2$score(m)
  expect_equal(ibs2, ibs22)

  m = msr("cmprsk.ibs", cause = "mean", cause_weights = c(0.5, 0.5))
  expect_equal(m$param_set$values$cause_weights, c(0.5, 0.5))
  ibs_mean = p2$score(m)
  expect_equal(ibs_mean, 0.5 * ibs1 + 0.5 * ibs2)
  # weighted mean IBS across causes should be different from mean IBS across causes
  expect_true(ibs_fg != ibs_mean)

  # manually calculate weighted mean IBS across causes with user-specified weights
  event = task$event()
  weights = unname(prop.table(table(event[event != 0])))
  m = msr("cmprsk.ibs", cause = "mean", cause_weights = weights)
  ibs_weighted = p2$score(m)
  expect_equal(ibs_weighted, ibs_fg)

  # Explicit causes remain calculable without observed events
  p = gen_PredictionCompRisks() # no event 2
  expect_no_warning({
    score = p$score(msr("cmprsk.ibs", cause = 2))
  })
  expect_true(is.finite(score))
  expect_gte(score, 0)
  expect_equal(
    score,
    p$score(msr("cmprsk.ibs", cause_weights = c(0, 1, 0)))
  )

  # all-cause score with event-frequency weights skips cause 2 (no observed events)
  expect_warning(
    {
      score = p$score(msr("cmprsk.ibs"))
    },
    "zero for cause\\(s\\): 2"
  )
  expect_equal(
    score,
    # cause 1 => 2 events (2/5 = 0.4 weight)
    # cause 3 => 3 events (3/5 = 0.6 weight)
    0.4 * p$score(msr("cmprsk.ibs", cause = 1)) + 0.6 * p$score(msr("cmprsk.ibs", cause = 3))
  )

  # Explicit causes and custom weighting also work when all observations are censored
  p = gen_PredictionCompRisks(rep(0, 8L))
  expect_no_warning({
    score = p$score(msr("cmprsk.ibs", cause = 2))
  })
  expect_true(is.finite(score))
  expect_no_warning(
    expect_equal(
      score,
      p$score(msr("cmprsk.ibs", cause_weights = c(0, 1, 0)))
    )
  )

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
  expect_no_warning(p$score(m))
  withr::local_options(mlr3cmprsk.warn_cif_extrapolation = TRUE)
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
  expect_warning(
    p$score(m),
    regexp = "1, 2",
    class = "Mlr3WarningCIFExtrapolation"
  )

  # follow-up validation removes times before checking for extrapolation
  m$param_set$values$times = c(2, 4, 9)
  expect_warning(
    p$score(m),
    regexp = "We remove 1 time point",
    class = "Mlr3Warning"
  )
  m$param_set$values$times = c(5, 9)
  expect_error(
    expect_warning(p$score(m), regexp = "We remove 1 time point", class = "Mlr3Warning"),
    regexp = "at least two distinct time points",
    class = "Mlr3Error"
  )

  # Time integration
  withr::local_options(mlr3cmprsk.warn_cif_extrapolation = NULL)
  m = msr("cmprsk.ibs")

  # input checks
  for (value in list(NULL, 1, 2.5, Inf, NA_real_, NaN, TRUE, "10", c(2, 3))) {
    expect_error(msr("cmprsk.ibs", ntimes = value), "ntimes")
  }
  for (value in list(-1, Inf, NA_real_, NaN, TRUE, "70", c(40, 70))) {
    expect_error(msr("cmprsk.ibs", t_max = value), "t_max")
  }
  for (value in list(-0.1, 1.1, Inf, NA_real_, NaN, TRUE, "0.8", c(0.5, 0.8))) {
    expect_error(msr("cmprsk.ibs", t_quantile = value), "t_quantile")
  }

  expect_error(
    p$score(msr("cmprsk.ibs", t_max = 70, t_quantile = 0.8)),
    "mutually exclusive",
    class = "Mlr3ErrorInput"
  )

  expect_error(
    get_grid(p, times = times, t_max = 70),
    "must both be NULL",
    class = "Mlr3ErrorInput"
  )
  expect_error(
    get_grid(p, times = times, t_quantile = 0.8),
    "must both be NULL",
    class = "Mlr3ErrorInput"
  )

  # 2 observations, 2 causes, 3 time points for cause 1 and cause 2
  p = PredictionCompRisks$new(
    row_ids = 1L:2L,
    truth = Surv(c(40, 120), factor(c(1, 0), levels = 0:2)),
    cif = list(
      "1" = matrix(
        rep(c(0, 0.1, 0.2), each = 2L),
        nrow = 2L,
        dimnames = list(NULL, c("0", "50", "150"))
      ),
      "2" = matrix(
        rep(c(0, 0.15, 0.25), each = 2L),
        nrow = 2L,
        dimnames = list(NULL, c("0", "30", "100"))
      )
    )
  )

  # mock RiskRegression::Score to capture the time grid used for integration
  backend = new.env()
  backend$calls = list()
  local_mocked_bindings(riskRegr_score = function(
    mat_list,
    metric,
    data,
    formula,
    times,
    cause,
    summary
  ) {
    backend$calls[[cause]] = list(
      times = times,
      mat = mat_list[[1L]], # CIF matrix interpolated to the `times`
      metric = metric,
      summary = summary
    )
    list(Brier = list(score = list(IBS = 0.1)))
  })

  get_grid = function(prediction, ...) {
    backend$calls = list()
    prediction$score(msr("cmprsk.ibs", cause = 1L, ...))
    backend$calls[["1"]]$times
  }

  grid = get_grid(p)
  # check default grid is from 0 to 90th percentile of observed times
  q90 = quantile(c(40, 120), 0.9, names = FALSE)
  expect_equal(grid, seq(0, q90, length.out = 100L))
  # single observations still gets the 100-point grid
  p_single = p$clone(deep = TRUE)$filter(1L)
  expect_identical(get_grid(p_single), seq(0, 40, length.out = 100L))
  expect_identical(dim(backend$calls[["1"]]$mat), c(1L, 100L))
  # `ntimes` controls the number of points in the grid
  expect_equal(get_grid(p, ntimes = 7L), seq(0, q90, length.out = 7L))
  expect_equal(get_grid(p, ntimes = 2L), c(0, q90))
  # `t_max` controls the upper limit of the grid
  expect_identical(get_grid(p, t_max = 70), seq(0, 70, length.out = 100L))
  expect_identical(get_grid(p, t_max = 120), seq(0, 120, length.out = 100L))
  # `t_max` can issue a warning if it is larger than the maximum observed time,
  # and the grid is truncated to the maximum observed time
  for (ntimes in c(2L, 7L, 100L)) {
    expect_warning(
      {
        grid = get_grid(p, t_max = 200, ntimes = ntimes)
      },
      "Using effective tau = 120",
      class = "Mlr3Warning"
    )
    expect_identical(grid, seq(0, 120, length.out = ntimes))
  }
  # too low `t_max` can cause an error
  expect_error(get_grid(p, t_max = 0), "at least two distinct time points", class = "Mlr3Error")
  # `t_quantile` also controls the upper limit of the grid
  expect_identical(get_grid(p, t_quantile = 0), seq(0, 40, length.out = 100L))
  expect_identical(get_grid(p, t_quantile = 1), seq(0, 120, length.out = 100L))
  q80 = quantile(c(40, 120), 0.8, names = FALSE)
  expect_identical(get_grid(p, t_quantile = 0.8), seq(0, q80, length.out = 100L))
  # using specific `times` is not affected by `ntimes`
  times = c(10, 30.5, 70, 120)
  expect_identical(get_grid(p, times = times, ntimes = 2L), times)
  expect_identical(get_grid(p, times = times, ntimes = 7L), times)
})
