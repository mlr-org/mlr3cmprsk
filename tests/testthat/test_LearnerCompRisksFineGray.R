test_that("autotest", {
  with_seed(42L, {
    learner = lrn("cmprsk.fg")
    expect_learner(learner)
    result = run_autotest(learner, N = 42, check_replicable = FALSE)
    expect_true(result, info = result$error)
  })
})

test_that("cmprsk.fg returns one model per cause and aligned CIF time grids", {
  with_seed(42L, {
    task = gen_cmprsk_task(n = 240, n_events = 3)
    task$set_col_roles(cols = "event", add_to = "stratum")
    part = partition(task)

    learner = lrn("cmprsk.fg")
    learner$train(task, part$train)

    model = learner$model
    expect_s3_class(model, "fine_gray")
    expect_list(model, len = length(task$cmp_events), types = "crr")
    expect_setequal(names(model), task$cmp_events)

    p = learner$predict(task, part$test)
    cif_list = p$cif
    expect_setequal(names(cif_list), task$cmp_events)

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
    "subset", # hanlded by mlr3
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
