test_that("autotest", {
  with_seed(42L, {
    learner = lrn("cmprsk.aalen")
    expect_learner(learner)
    result = run_autotest(learner, N = 42, check_replicable = FALSE)
    expect_true(result, info = result$error)
  })
})

test_that("cmprsk.aalen returns aligned CIF time grids", {
  with_seed(42L, {
    task = gen_cmprsk_task(n = 240, n_events = 3)
    task$set_col_roles(cols = "event", add_to = "stratum")
    part = partition(task)

    learner = lrn("cmprsk.aalen")
    learner$train(task, part$train)

    model = learner$native_model
    expect_s3_class(model, "survfit")
    expect_list(learner$model, len = 3)
    uevents = task$unique_event_times(rows = part$train)
    expect_equal(learner$model$event_times, uevents)

    p = learner$predict(task, part$test)
    cif_list = p$cif
    expect_setequal(names(cif_list), task$cmp_events)

    # CIF grids should match the training event-time grid for every cause (within tolerance)
    time_grids = lapply(cif_list, function(x) as.numeric(colnames(x)))

    # there is some loss of precision in the time grid, so we check that they
    # are equal within a tolerance
    for (cause in names(cif_list)) {
      expect_equal(time_grids[[cause]], uevents, tolerance = 1e-8)
    }
  })
})
