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

test_that("cmprsk.fg includes a zero CIF for a cause absent from training", {
  task = as_task_cmprsk(data.frame(
    time = 1:10,
    event = c(1L, 0L, 1L, 0L, 1L, 0L, 1L, 0L, 2L, 2L),
    x = c(1, 4, 6, 8, 2, 7, 5, 3, 4, 5)
  ))
  learner = lrn("cmprsk.fg")
  # train set has no events of cause 2
  p = learner$train(task, row_ids = 1:8)$predict(task, row_ids = 9:10)

  expect_named(p$cif, c("1", "2"))
  expect_equal(p$times, list("1" = c(1, 3, 5, 7), "2" = 0))
  expect_identical(p$cif[["2"]], matrix(0, nrow = 2L, dimnames = list(NULL, "0")))
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
  expect_identical(p_warn$times, p$times)
})
