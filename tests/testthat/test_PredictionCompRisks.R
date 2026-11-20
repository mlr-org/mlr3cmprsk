with_seed(42L, {
  # generate example predictions with 3 causes and 50 observations
  task = tgen("cmprsk", n_causes = 3L)$generate(50L)
  task$set_col_roles(cols = "event", add_to = "stratum")
  learner = lrn("cmprsk.aalen")
  pred = learner$train(task)$predict(task)
  # same task, but generate a simpler set of CIF predictions
  cif_times = list("1" = c(0, 0.1, 1, 5), "2" = c(0, 2, 4), "3" = c(0, 3))
  cif_list = lapply(cif_times, function(times) {
    outer(seq_len(task$nrow) / (task$nrow * length(cif_times)), 1 - exp(-times))
  })
})

test_that("initialization", {
  # use constructor
  p = PredictionCompRisks$new(
    task = task,
    cif = cif_list,
    times = cif_times
  )
  expect_prediction_cmprsk(p)
  expect_identical(p$data$cif, cif_list)
  expect_identical(p$times, cif_times)

  # field accessors are read-only
  expect_error(
    {
      p$times = NULL
    },
    "read-only"
  )
  expect_error(
    {
      p$cause_names = NULL
    },
    "read-only"
  )
  expect_error(
    {
      p$cif = NULL
    },
    "read-only"
  )

  # from a model prediction
  expect_prediction_cmprsk(pred)
})

test_that("PredictionDataCompRisks.print works", {
  pdata = structure(
    list(
      row_ids = task$row_ids,
      truth = task$truth(),
      cif = cif_list
    ),
    times = cif_times,
    class = c("PredictionDataCompRisks", "PredictionData")
  )

  expect_output(
    expect_invisible(print(pdata)),
    "<PredictionDataCompRisks> 50 obs, 3 causes, CIF times: 1 (Cause 1) = 4, 2 (Cause 2) = 3, 3 (Cause 3) = 2",
    fixed = TRUE
  )
})

test_that("prediction validation", {
  truth = Surv(1:2, factor(1:2, levels = 0:2, labels = c("Censored", "Death", "Relapse")))
  cif = list(
    "1" = matrix(0.1, 2L, 2L),
    "2" = matrix(0.2, 2L, 3L)
  )
  times = list("1" = c(1, 2), "2" = c(1.5, 2.5, 3.5))

  # all arguments must be given
  expect_error(PredictionCompRisks$new(row_ids = 1:2, truth = NULL, cif = cif, times = times))
  expect_error(PredictionCompRisks$new(row_ids = 1:2, truth = truth, cif = NULL, times = times))
  expect_error(PredictionCompRisks$new(row_ids = 1:2, truth = truth, cif = cif, times = NULL))
  expect_error(PredictionCompRisks$new(row_ids = 1:2, truth = truth, cif = cif))
  expect_error(PredictionCompRisks$new(row_ids = 1:2, truth = truth, times = times))

  # CIF values must be numeric, finite, between 0 and 1, and non-decreasing over time
  for (value in list(-1, 2, Inf, NaN, NA_real_, "0.1")) {
    invalid_cif = cif
    invalid_cif[[1L]][1L, 1L] = value
    expect_error(
      PredictionCompRisks$new(
        row_ids = 1:2,
        truth = truth,
        cif = invalid_cif,
        times = times
      )
    )
  }

  # CIF list names must be consecutive integers starting at 1
  wrong_names = list(c("1", "1"), c("7", "8"), c("2", "1"), c("1", "3"), c("Death", "Relapse"))
  for (cif_names in wrong_names) {
    expect_error(
      PredictionCompRisks$new(
        row_ids = 1:2,
        truth = truth,
        cif = set_names(cif, cif_names),
        times = times
      )
    )
  }

  # times names must also be consecutive integers starting at 1
  expect_error(
    PredictionCompRisks$new(
      row_ids = 1:2,
      truth = truth,
      cif = cif,
      times = set_names(times, c("Death", "Relapse"))
    )
  )
})

test_that("tasks with specific cause names propagate these to predictions", {
  task = tsk("hoel")
  p = lrn("cmprsk.aalen")$train(task)$predict(task, row_ids = 1:3)
  expect_identical(attr(p$truth, "states"), unname(task$cause_names))
  expect_identical(p$cause_names, task$cause_names)
  # cif list names stay as "1","2",...,"K"
  expect_named(p$cif, as.character(task$causes))
})

test_that("combining predictions", {
  with_seed(42L, {
    rr = resample(task, lrn("cmprsk.fg"), rsmp("cv", folds = 3L))
    p = rr$predictions()

    # we can combine predictions
    combined_p = do.call(c, p)
    expect_prediction_cmprsk(combined_p)

    cause = "1"
    times1 = combined_p$times[[cause]]
    times1_fold1 = p[[1L]]$times[[cause]]
    times1_fold2 = p[[2L]]$times[[cause]]
    times1_fold3 = p[[3L]]$times[[cause]]
    # different folds => different train sets => different time points
    expect_false(identical(times1_fold1, times1_fold2))
    expect_false(identical(times1_fold1, times1_fold3))
    expect_false(identical(times1_fold2, times1_fold3))
    # union of time points across folds in the combined prediction object
    expect_identical(times1, sort(unique(c(times1_fold1, times1_fold2, times1_fold3))))

    cause = "2"
    times2 = combined_p$times[[cause]]
    times2_fold1 = p[[1L]]$times[[cause]]
    times2_fold2 = p[[2L]]$times[[cause]]
    times2_fold3 = p[[3L]]$times[[cause]]
    # union of time points across folds in the combined prediction object
    expect_identical(times2, sort(unique(c(times2_fold1, times2_fold2, times2_fold3))))

    cause = "3"
    times3 = combined_p$times[[cause]]
    times3_fold1 = p[[1L]]$times[[cause]]
    times3_fold2 = p[[2L]]$times[[cause]]
    times3_fold3 = p[[3L]]$times[[cause]]
    # union of time points across folds in the combined prediction object
    expect_identical(times3, sort(unique(c(times3_fold1, times3_fold2, times3_fold3))))

    # row ids are correctly combined
    dt = as.data.table(combined_p)
    expect_equal(dt$row_ids, c(p[[1L]]$row_ids, p[[2L]]$row_ids, p[[3L]]$row_ids))

    # combined prediction data keeps both classes, so mlr3 generics dispatch on it
    pdata = c(p[[1L]]$data, p[[2L]]$data, p[[3L]]$data)
    expect_class(pdata, c("PredictionDataCompRisks", "PredictionData"))
    expect_class(as_prediction_data(pdata), c("PredictionDataCompRisks", "PredictionData"))
    pp = as_prediction(pdata)
    expect_prediction_cmprsk(pp)
    expect_identical(pp$times, attr(pdata, "times"))

    # duplicates are removed and only the last occurence of each row_id is kept
    deduplicated = c(combined_p, p[[1L]], keep_duplicates = FALSE)
    expect_equal(deduplicated$row_ids, c(p[[2L]]$row_ids, p[[3L]]$row_ids, p[[1L]]$row_ids))
    expect_identical(deduplicated$times, combined_p$times)
  })
})

test_that("as.data.table() conversion", {
  dt = as.data.table(pred)
  expect_data_table(dt, nrows = task$nrow, ncols = 4L, any.missing = FALSE)
  expect_identical(dt$row_ids, pred$row_ids)
  expect_identical(dt$time, pred$truth[, 1L])
  expect_identical(dt$event, as.integer(pred$truth[, 2L]))
  expect_identical(attr(dt, "cause_names"), pred$cause_names)
  expect_identical(attr(dt, "times"), pred$times)
  expect_list(dt$CIF, types = "list", len = task$nrow) # list of lists

  # Observation-wise CIF is a list of CIF vectors, one for each cause
  for (obs_cif in dt$CIF) {
    expect_list(obs_cif, types = "numeric", len = task$n_causes)
    expect_named(obs_cif, as.character(task$causes))
    # The length of each cause-specific CIF vector match the corresponding time points length
    expect_identical(lengths(obs_cif), lengths(pred$times))
  }

  # converting back to PredictionCompRisks is not possible in the current API
  # as the resulting mapping is far too complex to keep maintaining
  expect_error(as_prediction_cmprsk(dt), "no applicable method")
  expect_error(as_prediction_cmprsk(as.data.frame(dt)), "no applicable method")
})

test_that("as_prediction_cmprsk.list() conversion", {
  data_list = list(
    row_ids = pred$row_ids,
    truth = pred$truth,
    cif = pred$cif,
    times = pred$times
  )
  pred2 = as_prediction_cmprsk(data_list)
  expect_prediction_cmprsk(pred2)
  expect_identical(pred2$row_ids, pred$row_ids)
  expect_identical(pred2$truth, pred$truth)
  expect_identical(pred2$cause_names, task$cause_names)
  expect_identical(pred2$cif, pred$cif)
  expect_identical(pred2$times, pred$times)

  # removing mandatory elements should throw an error
  expect_error(as_prediction_cmprsk(data_list[-1L])) # no row_ids
  expect_error(as_prediction_cmprsk(data_list[-2L])) # no truth
  expect_error(as_prediction_cmprsk(data_list[-3L])) # no cif
  expect_error(as_prediction_cmprsk(data_list[-4L])) # no times
  # adding extra elements without using the reserved name `extra` throws error
  expect_error(as_prediction_cmprsk(c(data_list, list(extra_element = TRUE))))
})

test_that("filtering", {
  p = pred$clone(deep = TRUE)

  # filter to 3 observations
  p$filter(c(20, 37, 42))
  expect_prediction_cmprsk(p)
  expect_equal(p$data$row_ids, c(20, 37, 42))
  expect_length(p$truth, 3)
  # filtering preserves CIF list names, cause names and time grids
  expect_named(p$cif, as.character(task$causes))
  expect_identical(p$cause_names, task$cause_names)
  expect_identical(p$times, pred$times)

  # edge case: filter to 1 observation
  p$filter(20)
  expect_prediction_cmprsk(p)
  expect_equal(p$data$row_ids, 20)
  expect_length(p$truth, 1)
  expect_named(p$cif, as.character(task$causes))
  expect_identical(p$cause_names, task$cause_names)
  expect_identical(p$times, pred$times)

  # filter to 0 observations
  p$filter(integer(0L))
  expect_prediction_cmprsk(p)
  expect_silent(check_prediction_data(p$data))
  expect_output(
    print(p$data),
    "<PredictionDataCompRisks> 0 obs, 3 causes, CIF times: 1 (Cause 1) = 0, 2 (Cause 2) = 0, 3 (Cause 3) = 0",
    fixed = TRUE
  )
  expect_identical(p$cause_names, task$cause_names)
  expect_identical(p$times, list())
  for (mat in p$cif) {
    expect_matrix(mat, nrows = 0L, ncols = 0L)
  }
})

test_that("empty predictions", {
  p = learner$train(task)$predict(task, row_ids = integer())
  expect_prediction_cmprsk(p)
  expect_silent(check_prediction_data(p$data))
  expect_identical(p$row_ids, integer())
  expect_length(p$truth, 0L)
  expect_identical(p$cause_names, task$cause_names)
  expect_named(p$cif, as.character(task$causes))
  for (mat in p$cif) {
    expect_matrix(mat, mode = "numeric", nrows = 0L, ncols = 0L)
  }
  expect_data_table(as.data.table(p), nrows = 0L)
  expect_identical(p$times, list())
  expect_prediction_cmprsk(as_prediction(p$data))
  expect_identical(p$cif, p$data$cif)
  expect_identical(c(p, p)$times, list())
  expect_equal(c(p, p)$cif, p$cif)

  # combining with a nonempty prediction works no matter the ordering
  p2 = learner$predict(task, row_ids = 1:3)
  pc1 = c(p, p2)
  expect_equal(pc1$row_ids, 1:3)
  expect_equal(pc1$cif, p2$cif)
  expect_identical(pc1$times, p2$times)
  pc2 = c(p2, p)
  expect_equal(pc2$row_ids, 1:3)
  expect_equal(pc2$cif, p2$cif)
  expect_identical(pc2$times, p2$times)

  # creating empty PredictionDataCompRisks with the constructor works
  pdata = create_empty_prediction_data(task, learner)
  expect_class(pdata, c("PredictionDataCompRisks", "PredictionData"))
  expect_equal(pdata$row_ids, integer())
  expect_length(pdata$truth, 0L)
  expect_identical(attr(pdata$truth, "states"), unname(task$cause_names))
  expect_named(pdata$cif, as.character(task$causes))
  expect_identical(attr(pdata, "times"), list())
})

test_that("measure weights are supported", {
  task_w = task$clone(deep = TRUE)$cbind(data.frame(w = runif(task$nrow)))
  task_w$set_col_roles("w", "weights_measure")

  # learner prediction on a weighted task preserves weights
  p = learner$train(task_w)$predict(task_w)
  expect_prediction_cmprsk(p)
  expect_numeric(p$weights, len = task_w$nrow, any.missing = FALSE)
  expect_equal(p$weights, task_w$weights_measure$weight)

  # exporting to data.table preserves weights
  dt = as.data.table(p)
  expect_data_table(dt, nrows = task_w$nrow, ncols = 5L)
  expect_equal(dt$weights, p$weights)

  # converting from a list preserves weights
  p2 = as_prediction_cmprsk(
    list(
      row_ids = p$row_ids,
      truth = p$truth,
      cif = p$cif,
      times = p$times,
      weights = p$weights
    )
  )
  expect_equal(p2$weights, p$weights)

  # filtering preserves weights
  p$filter(c(20, 37, 42))
  expect_equal(
    p$weights,
    task_w$weights_measure[list(c(20, 37, 42)), on = "row_id"]$weight
  )

  # combining predictions preserves weights
  pc = c(p, p)
  expect_prediction_cmprsk(pc)
  expect_equal(pc$weights, rep(p$weights, 2L))
  pc = c(p, p, keep_duplicates = FALSE)
  expect_equal(pc$weights, p$weights)

  # mismatched weights length errors
  expect_error(
    PredictionCompRisks$new(
      row_ids = p$row_ids,
      truth = p$truth,
      cif = p$cif,
      times = p$times,
      weights = 1
    ),
    "same length",
    class = "Mlr3ErrorLearnerPredict"
  )

  # mixing weighted and unweighted predictions errors
  expect_error(c(p, pred), "others do not", class = "Mlr3ErrorInput")
})

test_that("extra data is supported", {
  # extra data cannot use reserved prediction column names
  for (name in c("row_ids", "time", "event", "CIF", "weights")) {
    expect_error(
      PredictionCompRisks$new(
        row_ids = task$row_ids,
        truth = task$truth(),
        cif = cif_list,
        times = cif_times,
        extra = set_names(list(seq_len(task$nrow)), name)
      ),
      regexp = "Extra data may not use reserved prediction column names",
      class = "Mlr3ErrorInput"
    )
  }

  # make some test extra prediction data
  extra = list(
    score = seq_len(task$nrow),
    flag = rep(c(TRUE, FALSE), length.out = task$nrow)
  )

  # initialization preserves extra data
  pe = PredictionCompRisks$new(
    row_ids = pred$row_ids,
    truth = pred$truth,
    cif = pred$cif,
    times = pred$times,
    extra = extra
  )
  expect_prediction_cmprsk(pe)
  expect_equal(pe$extra, extra)

  # exporting to data.table preserves extra data
  dt = as.data.table(pe)
  expect_data_table(dt, nrows = task$nrow, ncols = 6L)
  expect_equal(dt$score, extra$score)
  expect_equal(dt$flag, extra$flag)

  # filtering preserves extra data
  filter_ids = c(20, 37, 42)
  score_filtered = extra$score[filter_ids]
  flag_filtered = extra$flag[filter_ids]
  pe$filter(filter_ids)
  expect_equal(pe$extra$score, score_filtered)
  expect_equal(pe$extra$flag, flag_filtered)

  # combining predictions preserves extra data
  pc = c(pe, pe)
  expect_equal(pc$extra$score, rep(score_filtered, 2L))
  expect_equal(pc$extra$flag, rep(flag_filtered, 2L))
  pc = c(pe, pe, keep_duplicates = FALSE)
  expect_equal(pc$extra$score, score_filtered)
  expect_equal(pc$extra$flag, flag_filtered)

  # mismatched extra length errors
  expect_error(
    PredictionCompRisks$new(
      row_ids = pred$row_ids,
      truth = pred$truth,
      cif = pred$cif,
      times = pred$times,
      extra = list(score = 1)
    ),
    "same length",
    class = "Mlr3ErrorLearnerPredict"
  )

  # mixing extra and non-extra predictions errors
  expect_error(c(pe, pred), "others do not", class = "Mlr3ErrorInput")
})

test_that("raw predictions are supported", {
  raw = list(
    cs_hazard = lapply(pred$times, function(times) {
      matrix(0.01, nrow = length(pred$row_ids), ncol = length(times))
    })
  )
  p = PredictionCompRisks$new(
    task = task,
    cif = pred$data$cif,
    times = pred$times,
    raw = raw
  )
  expect_identical(p$raw, raw)
  expect_identical(as_prediction(p$data, check = TRUE)$raw, raw)
  # similar to original prediction (except the `raw` part)
  expect_identical(p$predict_types, pred$predict_types)
  expect_equal(as.data.table(p), as.data.table(pred))
  expect_null(pred$raw)

  # raw metadata is kept
  metadata = c(iterations = 10L, status = 0L)
  p_metadata = as_prediction_cmprsk(
    list(
      row_ids = pred$row_ids,
      truth = pred$truth,
      cif = pred$data$cif,
      times = pred$times,
      raw = metadata
    )
  )
  expect_identical(p_metadata$raw, metadata)
  expect_identical(as_prediction(p_metadata$data)$raw, metadata)

  # raw predictions don't change when filtering
  row_ids = pred$row_ids[1:2]
  p$filter(row_ids)
  expect_identical(p$raw, raw)

  # raw predictions are collected in a list when combined
  combined = c(p, pred, p_metadata)
  expect_identical(combined$raw, list(raw, metadata))
  expect_identical(c(pred, p)$raw, list(raw))
})
