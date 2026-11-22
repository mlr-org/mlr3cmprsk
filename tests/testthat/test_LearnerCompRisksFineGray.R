test_that("autotest", {
  with_seed(42L, {
    learner = lrn("cmprsk.fg")
    expect_learner(learner)
    result = run_autotest(learner, N = 42, check_replicable = FALSE)
    expect_true(result, info = result$error)
  })
})

test_that("cmprsk.fg trains without censoring or with an absent cause", {
  test_absent_causes(lrn("cmprsk.fg"))
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

test_that("cmprsk.fg returns one model per cause and cause-specific CIF time grids", {
  with_seed(42L, {
    task = tgen("cmprsk", n_causes = 3L)$generate(240L)
    task$set_col_roles(cols = "event", add_to = "stratum")
    part = partition(task)

    learner = lrn("cmprsk.fg")
    learner$train(task, part$train)

    model = learner$model
    expect_s3_class(model, "fine_gray")
    expect_list(model, len = task$n_causes, types = "crr")
    expect_equal(names(model), as.character(task$causes))

    p = learner$predict(task, part$test)
    cif_list = p$cif
    expect_equal(names(cif_list), as.character(task$causes))

    for (cause in names(cif_list)) {
      uevents = task$unique_event_times(rows = part$train, cause = as.integer(cause))
      expect_identical(p$times[[cause]], uevents)
      expect_equal(ncol(cif_list[[cause]]), length(uevents))
      expect_identical(colnames(cif_list[[cause]]), as.character(uevents))
      expect_null(colnames(p$data$cif[[cause]]))
    }
  })
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
  expect_identical(p_warn$times, p$times)
})
