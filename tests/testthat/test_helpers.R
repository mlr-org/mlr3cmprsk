test_that("aggregate_scores identifies causes with non-finite scores", {
  scores = c("1" = 0.5, "2" = NaN, "3" = 0.7)
  expect_warning(
    { result = aggregate_scores(scores, event = 1:3) },
    "cause\\(s\\): 2\\.",
    class = "RiskRegressionScoreNaN"
  )
  expect_true(is.nan(result))

  scores = c("1" = NaN, "2" = 0.5, "3" = NaN)
  expect_warning(
    aggregate_scores(scores, event = 1:3),
    "cause\\(s\\): 1, 3\\.",
    class = "RiskRegressionScoreNaN"
  )

  expect_no_warning(expect_equal(aggregate_scores(c("1" = 0.5, "2" = 0.7), event = 1:2), 0.6))
})
