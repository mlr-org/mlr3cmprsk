test_that("autotest", {
  with_seed(42L, {
    learner = lrn("cmprsk.fg")
    expect_learner(learner)
    result = run_autotest(learner, N = 42, check_replicable = FALSE)
    expect_true(result, info = result$error)
  })
})

test_that("train params of cmprsk.fg", {
  learner = lrn("cmprsk.fg")
  fun = list(cmprsk::crr)
  exclude = c(
    "ftime", # handled by mlr3
    "fstatus", # handled by mlr3
    "cov1", # handled by mlr3
    "cov2", # not supported
    "tf", # not supported
    "failcode", # handled by mlr3
    "cencode", # handled by mlr3
    "cengroup", # not supported
    "subset", # handled by mlr3
    "na.action" # not supported
  )
  res = run_paramtest(learner, fun, exclude, tag = "train")
  expect_true(res, info = res$error)
})

test_that("predict params of cmprsk.fg", {
  learner = lrn("cmprsk.fg")
  fun = list(cmprsk::predict.crr)
  exclude = c(
    "object", # handled by mlr3
    "cov1", # handled by mlr3
    "cov2" # not supported
  )
  res = run_paramtest(learner, fun, exclude, tag = "predict")
  expect_true(res, info = res$error)
})

test_that("cmprsk.fg returns one model per cause and aligned CIF time grids", {
  with_seed(42L, {
    task = tgen("cmprsk", n_causes = 3L)$generate(240L)
    task$set_col_roles(cols = "event", add_to = "stratum")
    part = partition(task)

    learner = lrn("cmprsk.fg")
    learner$train(task, part$train)

    model = learner$model
    expect_s3_class(model, "fine_gray")
    expect_list(model, len = length(task$cmp_events), types = "crr")
    expect_equal(names(model), task$cmp_events)

    p = learner$predict(task, part$test)
    cif_list = p$cif
    expect_equal(names(cif_list), task$cmp_events)

    # CIF grids should match the training event-time grid for every cause (within tolerance)
    time_grids = lapply(cif_list, function(x) as.numeric(colnames(x)))
    uevents = task$unique_event_times(rows = part$train)

    # there is some loss of precision in the time grid, so we check that they
    # are equal within a tolerance
    for (cause in names(cif_list)) {
      expect_equal(time_grids[[cause]], uevents, tolerance = 1e-8)
    }
  })
})

test_that("check that training works with no censored observations", {
  task = with_seed(42L, {
    tgen("cmprsk", event_probs = c(0.5, 0.5))$generate(50L)
  })
  learner = lrn("cmprsk.fg")
  p = learner$train(task)$predict(task)

  expect_prediction_cmprsk(p)
})

test_that("cmprsk.fg CIF sum warnings are opt-in", {
  withr::local_options(list(
    mlr3cmprsk.warn_cif_sum = NULL,
    mlr3cmprsk.warn_cif_extrapolation = NULL
  ))
  task = tsk("transplant")$filter(1:300)$select("age")
  learner = lrn("cmprsk.fg")
  p = expect_no_warning(learner$train(task)$predict(task))

  withr::local_options(mlr3cmprsk.warn_cif_sum = FALSE)
  expect_no_warning(learner$train(task)$predict(task))
  withr::local_options(mlr3cmprsk.warn_cif_sum = TRUE)
  expect_warning(
    {
      p_warn = learner$train(task)$predict(task)
    },
    class = "Mlr3WarningCIFSumExceedsOne"
  )
  expect_equal(p_warn$cif, p$cif)
})
