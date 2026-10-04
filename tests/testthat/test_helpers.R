test_that("aggregate_cause_causes works", {
  # check that it identifies causes with non-finite scores
  scores = c("1" = 0.5, "2" = NaN, "3" = 0.7)
  expect_warning(
    {
      result = aggregate_cause_causes(scores, weights = rep(1 / 3, 3L))
    },
    "2",
    class = "RiskRegressionScoreNaN"
  )
  expect_true(is.nan(result))

  scores = c("1" = NaN, "2" = 0.5, "3" = NaN)
  expect_warning(
    aggregate_cause_causes(scores, weights = rep(1 / 3, 3L)),
    "1, 3",
    class = "RiskRegressionScoreNaN"
  )

  # every score finite => no warning
  expect_no_warning(
    expect_equal(aggregate_cause_causes(c("1" = 0.5, "2" = 0.7), weights = c(0.5, 0.5)), 0.6)
  )
})

test_that("resolve_cause_weights works", {
  # no event 2 gives warning and zero weight for cause 2
  causes = c("1", "2", "3")
  expect_warning(
    {
      weights = resolve_cause_weights(c(0, 1, 3, 3, 3), causes)
    },
    "2"
  )
  expect_identical(weights, c("1" = 0.25, "2" = 0, "3" = 0.75))

  # no event for causes 1 and 2 gives warning and zero weights for causes 1 and 2
  expect_warning(
    {
      weights = resolve_cause_weights(c(0, 3, 3), causes)
    },
    "1, 2"
  )
  expect_identical(weights, c("1" = 0, "2" = 0, "3" = 1))

  # custom weights are checked and returned with names aligned to causes
  expect_no_warning(
    expect_identical(
      resolve_cause_weights(c(0, 1, 2), causes, c(1, 0, 0)),
      c("1" = 1, "2" = 0, "3" = 0)
    )
  )

  # event-frequency weights are derived correctly when all causes have events
  expect_no_warning(
    expect_identical(
      resolve_cause_weights(c(0, 1, 2, 2, 3), causes),
      c("1" = 0.25, "2" = 0.5, "3" = 0.25)
    )
  )

  # when no observed events at all, returns NA weights and a warning
  expect_warning(
    {
      weights = resolve_cause_weights(rep(0, 4L), causes)
    },
    "weights are undefined"
  )
  expect_identical(weights, set_names(rep(NA_real_, 3L), causes))

  # aligns custom weights with causes names
  causes = c("1", "2")
  expect_no_warning(
    expect_identical(
      resolve_cause_weights(c(0, 0), causes, c(a = 0.3, b = 0.7)),
      c("1" = 0.3, "2" = 0.7)
    )
  )

  # validates custom weights
  for (weights in list(1, c(-0.1, 1.1), c(NA, 1), c(NaN, 1), c(Inf, 0))) {
    expect_error(resolve_cause_weights(1:2, causes, weights))
  }

  expect_error(
    resolve_cause_weights(1:2, causes, c(0.5, 0.6)),
    "must sum to 1",
    class = "Mlr3ErrorInput"
  )
})
