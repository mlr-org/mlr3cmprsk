test_that("autotest", {
  with_seed(42L, {
    learner = lrn("cmprsk.aalen")
    expect_learner(learner)
    result = run_autotest(learner, N = 42, check_replicable = FALSE)
    expect_true(result, info = result$error)
  })
})

test_that("cmprsk.aalen returns cause-specific CIF time grids", {
  with_seed(42L, {
    task = tgen("cmprsk", n_causes = 3L)$generate(240L)
    task$set_col_roles(cols = "event", add_to = "stratum")
    part = partition(task)

    learner = lrn("cmprsk.aalen")
    learner$train(task, part$train)

    model = learner$native_model
    expect_s3_class(model, "survfit")
    expect_list(learner$model, len = 3)
    # model keeps the unique train event times per cause
    uevents = set_names(
      map(task$causes, function(cause) {
        task$unique_event_times(rows = part$train, cause = cause)
      }),
      as.character(task$causes)
    )
    expect_equal(learner$model$event_times, uevents)

    p = learner$predict(task, part$test)
    expect_identical(p$times, uevents)
    cif_list = p$cif
    expect_equal(names(cif_list), as.character(task$causes))

    for (cause in names(cif_list)) {
      expect_equal(ncol(cif_list[[cause]]), length(uevents[[cause]]))
      expect_identical(colnames(cif_list[[cause]]), as.character(uevents[[cause]]))
      expect_null(colnames(p$data$cif[[cause]]))
    }
  })
})

test_that("cause-specific grids include only times with positive event weight", {
  # construct task where only on times 1 and 4 events happen with non-zero weight
  data = data.frame(
    time = c(1, 1, 2, 3, 4, 5),
    event = c(1L, 1L, 1L, 2L, 2L, 0L),
    w = c(0, 0.5, 0, 0, 2, 1)
  )
  task = as_task_cmprsk(data)
  task$set_col_roles("w", "weights_learner")

  learner = lrn("cmprsk.aalen")
  p = learner$train(task)$predict(task)

  expect_identical(p$times, list("1" = 1, "2" = 4))

  # With no positive-weight events, cause 2 has a zero CIF at time 0
  data$w[5L] = 0
  task = as_task_cmprsk(data)
  task$set_col_roles("w", "weights_learner")
  p = learner$train(task)$predict(task)

  expect_identical(p$times, list("1" = 1, "2" = 0))
  expect_equal(unname(p$cif[["2"]]), matrix(0, nrow = task$nrow, ncol = 1L))
})

test_that("train params of cmprsk.aalen", {
  learner = lrn("cmprsk.aalen")
  fun = list(survival::survfit.formula)
  exclude = c(
    "formula", # handled by mlr3
    "data", # handled by mlr3
    "weights", # handled by mlr3
    "subset", # handled by mlr3
    "na.action", # not supported
    "stype", # not supported
    "ctype", # not supported
    "id", # not supported
    "cluster", # not supported
    "robust", # not supported
    "istate", # not supported
    "timefix", # not supported
    "etype", # not supported
    "model", # not supported
    "error", # not supported
    "entry", # not supported
    "time0" # not supported
  )
  res = run_paramtest(learner, fun, exclude, tag = "train")
  expect_true(res, info = res$error)
})
# no predict wrapped function is used for this learner, so we do not test predict params

test_that("training works with no censored observations", {
  task = as_task_cmprsk(
    data.frame(time = 1:6, event = rep(c(1L, 2L), 3L), x = 1:6)
  )
  learner = lrn("cmprsk.aalen")
  p = learner$train(task)$predict(task)

  expect_prediction_cmprsk(p)
})

test_that("absent causes during training give zero CIF when predicting", {
  data = data.frame(
    time = 1:7,
    event = c(1L, 2L, 1L, 2L, 3L, 3L, 0L),
    x = 1:7
  )
  task = as_task_cmprsk(data)
  learner = lrn("cmprsk.aalen")
  learner$train(task, row_ids = 1:4) # causes 1 and 2
  expect_length(learner$native_model$states, 4) # all 3 causes + censoring accounted

  p = learner$predict(task, 5:7)
  expect_prediction_cmprsk(p)

  # cause 3 gives only CIF(t=0) = 0
  expect_identical(p$times[["3"]], 0)
  expect_equal(unname(p$cif[["3"]]), matrix(0, nrow = 3L, ncol = 1L))
  # cause 1 and 2 have CIFs
  expect_identical(p$times[["1"]], c(1, 3))
  expect_identical(p$times[["2"]], c(2, 4))
  expect_matrix(p$cif[["1"]], mode = "numeric", nrows = 3L, ncols = 2L)
  expect_matrix(p$cif[["2"]], mode = "numeric", nrows = 3L, ncols = 2L)
})
