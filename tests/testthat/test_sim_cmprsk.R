test_that("sim_cmprsk", {
  # input checks
  expect_error(sim_cmprsk(2L, n_causes = 3L), "n >= n_causes")
  expect_error(sim_cmprsk(10L, shape = 0), "shape > 0")
  expect_error(sim_cmprsk(10L, rate = 0), "rate > 0")
  expect_error(sim_cmprsk(10L, n_features = 11), "n_features")
  expect_error(sim_cmprsk(10L, n_causes = 6L), "n_causes")
  expect_error(
    sim_cmprsk(10L, event_probs = c(0.5, 0.6)),
    "Cause probabilities must sum to at most 1"
  )

  # check that invalid rates and times are rejected
  dbl_min = .Machine$double.xmin
  expect_error(
    sim_cmprsk(10L, beta_sd = 0, rate = dbl_min, event_probs = c(dbl_min, 0.5)),
    "non-finite or non-positive rates"
  )
  expect_error(
    with_seed(42L, sim_cmprsk(10L, beta_sd = 0, shape = dbl_min)),
    "non-finite or non-positive times"
  )

  # check reproducibility with the same seed
  expect_equal(
    with_seed(42L, sim_cmprsk(10L)),
    with_seed(42L, sim_cmprsk(10L))
  )

  # check minimal output data
  expect_error(sim_cmprsk(1L), "n >= n_causes")
  minimal = with_seed(42L, sim_cmprsk(2L, beta_sd = 0, event_probs = c(0.5, 0.5)))
  expect_data_table(minimal, nrows = 2L)
  expect_setequal(minimal$event, 1:2) # no censoring, both causes present

  # error if any requested cause is missing
  expect_error(
    with_seed(42L, sim_cmprsk(100L, beta_sd = 0, event_probs = c(0.8, 1e-10))),
    "Missing observed causes in simulated data: 2",
    class = "Mlr3ErrorInput"
  )
  expect_error(
    with_seed(42L, sim_cmprsk(100L, beta_sd = 0, event_probs = c(1e-10, 1e-10))),
    "Missing observed causes in simulated data: 1, 2",
    class = "Mlr3ErrorInput"
  )

  # 80% events (equally distributed), 20% censoring, 2 features, 3 causes,
  # shape = 1 (exponential), rate = 0.2, beta_sd = 0.8
  data = with_seed(
    42L,
    sim_cmprsk(3000L, n_features = 2L, n_causes = 3L, beta_sd = 0.8)
  )
  expect_data_table(data, nrows = 3000L, ncols = 14L, any.missing = FALSE)
  expect_equal(
    names(data),
    c(
      "time",
      "event",
      "x1",
      "x2",
      "event_time",
      "event_cause",
      "cens_time",
      "lp1",
      "lp2",
      "lp3",
      "rate1",
      "rate2",
      "rate3",
      "total_rate"
    )
  )
  expect_equal(data$time, pmin(data$event_time, data$cens_time))
  expect_identical(
    data$event,
    ifelse(data$event_time <= data$cens_time, data$event_cause, 0L)
  )
  expect_equal(
    data$total_rate,
    rowSums(data[, c("rate1", "rate2", "rate3"), with = FALSE])
  )
  # rate * p_k * exp(lp_k)
  expect_equal(data$rate1, 0.2 * (0.8 / 3) * exp(data$lp1))
  expect_equal(data$rate2, 0.2 * (0.8 / 3) * exp(data$lp2))
  expect_equal(data$rate3, 0.2 * (0.8 / 3) * exp(data$lp3))
  expect_setequal(data$event[data$event > 0L], 1:3)
  expect_true(all(is.finite(data$time) & data$time > 0))

  # 80% events (equally distributed), 0% censoring, 3 features, 2 causes,
  # shape = 1 (exponential), rate = 0.2, beta_sd = 0
  data_no_censor = with_seed(
    42L,
    sim_cmprsk(100L, shape = 1, beta_sd = 0, event_probs = c(0.5, 0.5))
  )
  expect_true(all(data_no_censor$cens_time == Inf))
  expect_identical(
    data_no_censor$time,
    pmin(data_no_censor$event_time, data_no_censor$cens_time)
  )
  expect_identical(
    data_no_censor$event,
    ifelse(data_no_censor$event_time <= data_no_censor$cens_time, data_no_censor$event_cause, 0L)
  )
  expect_true(all(data_no_censor$lp1 == 0 & data_no_censor$lp2 == 0)) # due to beta_sd = 0
  expect_equal(data_no_censor$rate1, rep(0.2 * 0.5, 100L)) # exp(lp_k = 0) = 1
  expect_equal(data_no_censor$rate2, rep(0.2 * 0.5, 100L))
  expect_equal(data_no_censor$total_rate, rep(0.2, 100L))
})
