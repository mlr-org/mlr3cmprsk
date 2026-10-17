with_seed(42L, {
  task = gen_cmprsk_task(n = 50, n_events = 3)
  task$set_col_roles(cols = "event", add_to = "stratum")
  cif_list = gen_cif(n = 50, n_events = 3)
  learner = lrn("cmprsk.aalen")
  pred = learner$train(task)$predict(task)
})

test_that("Initialization works", {
  # use constructor
  expect_prediction_cmprsk(
    PredictionCompRisks$new(
      row_ids = task$row_ids,
      truth = task$truth(),
      cif = cif_list
    )
  )

  # from a model prediction
  expect_prediction_cmprsk(pred)
})

test_that("combining predictions", {
  with_seed(42L, {
    rr = resample(task, lrn("cmprsk.fg"), rsmp("cv", folds = 3L))
    p = rr$predictions()

    # different time points in each resampling as different
    # training sets have different event times
    cause = "1"
    times1_fold1 = as.numeric(colnames(p[[1L]]$data$cif[[cause]]))
    times1_fold2 = as.numeric(colnames(p[[2L]]$data$cif[[cause]]))
    times1_fold3 = as.numeric(colnames(p[[3L]]$data$cif[[cause]]))
    expect_false(identical(times1_fold1, times1_fold2))
    expect_false(identical(times1_fold1, times1_fold3))
    expect_false(identical(times1_fold2, times1_fold3))

    # combine predictions
    pred = do.call(c, p)
    expect_prediction_cmprsk(pred)

    # check that time points are properly combined
    times1 = as.numeric(colnames(pred$cif[[cause]]))
    # union of time points across folds in the combined prediction object
    expect_true(all(times1 == sort(unique(c(times1_fold1, times1_fold2, times1_fold3)))))

    cause = "2"
    times2 = as.numeric(colnames(pred$cif[[cause]]))
    times2_fold1 = as.numeric(colnames(p[[1L]]$data$cif[[cause]]))
    times2_fold2 = as.numeric(colnames(p[[2L]]$data$cif[[cause]]))
    times2_fold3 = as.numeric(colnames(p[[3L]]$data$cif[[cause]]))
    # union of time points across folds in the combined prediction object
    expect_true(all(times2 == sort(unique(c(times2_fold1, times2_fold2, times2_fold3)))))

    # row ids are correctly combined
    dt = as.data.table(pred)
    expect_equal(dt$row_ids, c(p[[1L]]$row_ids, p[[2L]]$row_ids, p[[3L]]$row_ids))

    # combined prediction data keeps both classes, so mlr3 generics dispatch on it
    pdata = c(p[[1L]]$data, p[[2L]]$data)
    expect_class(pdata, c("PredictionDataCompRisks", "PredictionData"))
    expect_class(as_prediction_data(pdata), c("PredictionDataCompRisks", "PredictionData"))
    expect_prediction_cmprsk(as_prediction(pdata))
  })
})

test_that("data.table/frame roundtrip", {
  dt = as.data.table(pred)
  expect_data_table(dt, nrows = task$nrow, ncols = 4L, any.missing = FALSE)
  p2 = as_prediction_cmprsk(dt)
  expect_prediction_cmprsk(p2)

  expect_equal(pred$cif, p2$cif)
  expect_equal(dt[, !("CIF")], as.data.table(p2)[, !("CIF")])
  expect_null(p2$extra)
  expect_null(p2$weights)

  dt_df = as.data.frame(dt)
  p3 = as_prediction_cmprsk(dt_df)
  expect_prediction_cmprsk(p3)

  # CIF vectors with mismatched lengths or time names are rejected instead of recycled
  dt_short = dt[1:2]
  dt_short$CIF[[2L]][["1"]] = dt_short$CIF[[2L]][["1"]][1L]
  expect_error(as_prediction_cmprsk(dt_short), "same length and time names", class = "Mlr3ErrorInput")

  dt_renamed = dt[1:2]
  names(dt_renamed$CIF[[2L]][["1"]])[1L] = "100"
  expect_error(as_prediction_cmprsk(dt_renamed), "same length and time names", class = "Mlr3ErrorInput")

  # the caller's data.frame is not converted to a data.table by reference
  expect_identical(class(dt_df), "data.frame")

  # data.frame conversion rejects duplicate column names
  dt = cbind(dt, dt[, "row_ids", with = FALSE])
  expect_error(as_prediction_cmprsk(dt), "unique")
})

test_that("named lists convert to predictions with validation", {
  data_list = list(row_ids = pred$row_ids, truth = pred$truth, cif = pred$cif)
  pred2 = as_prediction_cmprsk(data_list)
  expect_prediction_cmprsk(pred2)
  expect_identical(pred2$row_ids, pred$row_ids)
  expect_identical(pred2$truth, pred$truth)
  expect_identical(pred2$cif, pred$cif)

  # removing mandatory elements should throw an error
  expect_error(as_prediction_cmprsk(data_list[-1L])) # no row_ids
  expect_error(as_prediction_cmprsk(data_list[-2L])) # no truth
  expect_error(as_prediction_cmprsk(data_list[-3L])) # no cif
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
  # filtering preserves the cause names in the CIF list and the truth's states
  expect_identical(attr(p$truth, "states"), c("1", "2", "3"))
  expect_named(p$cif, c("1", "2", "3"))

  # edge case: filter to 1 observation
  p$filter(20)
  expect_prediction_cmprsk(p)
  expect_equal(p$data$row_ids, 20)
  expect_length(p$truth, 1)
  expect_length(p$cif, 3)

  # filter to 0 observations using non-existent (positive) id
  p$filter(42L)
  expect_prediction_cmprsk(p)
  expect_silent(check_prediction_data(p$data))
})

test_that("measure weights are supported", {
  task_w = task$clone(deep = TRUE)$cbind(data.frame(w = runif(task$nrow)))
  task_w$set_col_roles("w", "weights_measure")

  p = learner$train(task_w)$predict(task_w)
  expect_prediction_cmprsk(p)
  expect_numeric(p$weights, len = task_w$nrow, any.missing = FALSE)
  expect_equal(p$weights, task_w$weights_measure$weight)

  # convert to data.table and back preserves weights
  dt = as.data.table(p)
  expect_data_table(dt, nrows = task_w$nrow, ncols = 5L)
  expect_equal(dt$weights, p$weights)
  p2 = as_prediction_cmprsk(dt)
  expect_equal(p2$weights, p$weights)
  expect_null(p2$extra)
  p3 = as_prediction_cmprsk(list(
    row_ids = p$row_ids,
    truth = p$truth,
    cif = p$cif,
    weights = p$weights
  ))
  expect_equal(p3$weights, p$weights)

  # filtering preserves weights
  p$filter(c(20, 37, 42))
  expect_equal(p$weights, task_w$weights_measure[list(c(20, 37, 42)), on = "row_id"]$weight)

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
      weights = 1
    ),
    "same length",
    class = "Mlr3ErrorLearnerPredict"
  )
  # mixing weighted and unweighted predictions errors
  p_unweighted = PredictionCompRisks$new(
    row_ids = p$row_ids,
    truth = p$truth,
    cif = p$cif
  )
  expect_error(c(p, p_unweighted), "others do not", class = "Mlr3ErrorInput")
})

test_that("extra data is supported", {
  # extra data cannot use reserved prediction column names
  for (name in c("row_ids", "time", "event", "CIF", "weights")) {
    expect_error(
      PredictionCompRisks$new(
        row_ids = task$row_ids,
        truth = task$truth(),
        cif = cif_list,
        extra = set_names(list(seq_len(task$nrow)), name)
      ),
      "Names must be disjunct"
    )
  }

  extra = list(
    score = seq_len(task$nrow),
    flag = rep(c(TRUE, FALSE), length.out = task$nrow)
  )
  pe = PredictionCompRisks$new(
    row_ids = pred$row_ids,
    truth = pred$truth,
    cif = pred$cif,
    extra = extra
  )
  expect_prediction_cmprsk(pe)
  expect_equal(pe$extra, extra)

  # convert to data.table and back preserves extra data
  dt = as.data.table(pe)
  expect_data_table(dt, nrows = task$nrow, ncols = 6L)
  expect_equal(dt$score, extra$score)

  p2 = as_prediction_cmprsk(as.data.table(pe))
  expect_equal(p2$extra, pe$extra)
  expect_equal(p2$cif, pe$cif)
  expect_equal(p2$row_ids, pe$row_ids)
  expect_equal(p2$truth, pe$truth)
  expect_null(p2$weights)

  p3 = as_prediction_cmprsk(as.data.frame(dt))
  expect_equal(p3$extra, pe$extra)

  # filtering preserves extra data
  pe$filter(c(20, 37, 42))
  expect_equal(pe$extra$score, c(20L, 37L, 42L))
  expect_equal(pe$extra$flag, extra$flag[c(20, 37, 42)])

  # combining predictions preserves extra data
  pc = c(pe, pe)
  expect_equal(pc$extra$score, rep(c(20L, 37L, 42L), 2L))
  pc = c(pe, pe, keep_duplicates = FALSE)
  expect_equal(pc$extra$score, c(20L, 37L, 42L))

  # mismatched extra length errors
  expect_error(
    PredictionCompRisks$new(
      row_ids = pred$row_ids,
      truth = pred$truth,
      cif = pred$cif,
      extra = list(score = 1)
    ),
    "same length",
    class = "Mlr3ErrorLearnerPredict"
  )
  # mixing extra and non-extra predictions errors
  expect_error(c(pe, pred), "others do not", class = "Mlr3ErrorInput")
})

test_that("prediction validation rejects invalid CIFs and causes", {
  truth = Surv(1:2, factor(1:2, levels = 0:2))
  cif = list(
    "1" = matrix(0.1, 2L, 2L, dimnames = list(NULL, c("1", "2"))),
    "2" = matrix(0.2, 2L, 2L, dimnames = list(NULL, c("1", "2")))
  )

  # CIF must be given
  expect_error(PredictionCompRisks$new(row_ids = 1:2, truth = truth, cif = NULL))

  # CIF values must be numeric, finite, between 0 and 1, and non-decreasing over time
  for (value in list(-1, 2, Inf, NaN, NA_real_, "0.1")) {
    invalid = cif
    invalid[[1L]][1L, 1L] = value
    expect_error(PredictionCompRisks$new(row_ids = 1:2, truth = truth, cif = invalid))
  }

  invalid = cif
  invalid[[1L]][1L, 2L] = 0
  expect_error(
    PredictionCompRisks$new(row_ids = 1:2, truth = truth, cif = invalid),
    "non-decreasing"
  )

  # times must be coercible to finite numeric values
  invalid = cif
  colnames(invalid[[1L]]) = c("1", "Inf")
  expect_silent(PredictionCompRisks$new(row_ids = 1:2, truth = truth, cif = invalid))
  # TODO: update to expect_error() when `survdistr` is updated to check for finite times

  # cause names must be consecutive integers starting at 1
  for (causes in list(c("1", "1"), c("7", "8"), c("2", "1"), c("1", "3"))) {
    expect_error(
      PredictionCompRisks$new(
        row_ids = 1:2,
        truth = truth,
        cif = set_names(cif, causes)
      )
    )
  }

  # truth's states must correspond to the cause names in the CIF list
  invalid_truth = Surv(1:2, factor(c(2L, 3L), levels = c(0L, 2L, 3L)))
  expect_error(
    PredictionCompRisks$new(row_ids = 1:2, truth = invalid_truth, cif = cif),
    "Expected competing causes to be 1, 2, but got 2, 3"
  )
})
