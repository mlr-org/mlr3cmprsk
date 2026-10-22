test_that("TaskGeneratorCompRisks", {
  # construction, parameters, and task generation
  with_seed(42L, {
    generator = tgen("cmprsk")
    expect_class(generator, "TaskGeneratorCompRisks")
    expect_equal(generator$task_type, "cmprsk")
    expect_setequal(
      generator$param_set$ids(),
      c("n_features", "n_causes", "event_probs", "shape", "rate", "beta_sd")
    )

    task = tgen("cmprsk", n_features = 5L, n_causes = 3L)$generate(100L)
    expect_task_cmprsk(task)
    expect_equal(task$nrow, 100L)
    expect_equal(task$ncol, 7L)
    expect_setequal(task$feature_names, paste0("x", 1:5))
    expect_setequal(unique(task$event()[task$event() > 0L]), 1:3)
    expect_integer(task$event(), lower = 0L, upper = 3L)
    expect_true(all(is.finite(task$times()) & task$times() > 0))
    expect_equal(task$cmp_events, as.character(1:3))
  })

  # generator rejects invalid parameters
  expect_error(tgen("cmprsk", n_features = 0L), "n_features")
  expect_error(tgen("cmprsk", n_features = 11L), "n_features")
  expect_error(tgen("cmprsk", n_causes = 1L), "n_causes")
  expect_error(tgen("cmprsk", n_causes = 6L), "n_causes")
  expect_error(tgen("cmprsk", event_probs = c(0, 0.5)), "strictly positive")
  expect_error(tgen("cmprsk", event_probs = c(0.6, 0.6)), "sum to at most 1")
  expect_error(tgen("cmprsk", event_probs = c(NA_real_, 0.5)), "event_probs")
  expect_error(
    tgen("cmprsk", n_causes = 2, event_probs = c(0.4, 0.2, 0.1))$generate(100L),
    "length 2"
  )
  expect_error(tgen("cmprsk", shape = 0)$generate(100L), "shape > 0")
  expect_error(tgen("cmprsk", rate = Inf)$generate(100L), "finite")
  expect_error(tgen("cmprsk", beta_sd = -1), "beta_sd")
  expect_error(tgen("cmprsk")$generate(1L), "n >= n_causes")
  expect_error(tgen("cmprsk", n_causes = 3L)$generate(2L), "n >= n_causes")
  expect_error(tgen("cmprsk")$generate(0L), ">= 1")
  expect_error(tgen("cmprsk")$generate(2.5), "type 'count'")
  expect_error(
    with_seed(42L, tgen("cmprsk", beta_sd = 0, event_probs = c(0.8, 1e-10))$generate(100L)),
    "Missing observed causes in simulated data: 2",
    class = "Mlr3ErrorInput"
  )

  # generation is reproducible with the caller's seed
  generator = tgen("cmprsk", n_causes = 3L)
  first = with_seed(42L, generator$generate(50L))
  second = with_seed(42L, generator$generate(50L))
  expect_equal(first$data(), second$data())
})
