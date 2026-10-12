set.seed(42L)
task = gen_cmprsk_task(n = 50, n_events = 3)
cif_list = gen_cif(n = 50, n_events = 3)
learner = lrn("cmprsk.aalen")

test_that("Initialization works", {
  # directly from constructor
  p = PredictionCompRisks$new(
    row_ids = task$row_ids,
    truth = task$truth(),
    cif = cif_list
  )
  expect_prediction_cmprsk(p)

  # from a model prediction
  p = learner$train(task)$predict(task)
  expect_prediction_cmprsk(p)
})

test_that("combining predictions", {
  set.seed(1L)
  task = tsk("pbc")
  feats = c("age", "chol", "albumin", "ast", "bili", "protime")
  task$select(feats)

  rr = resample(task, lrn("cmprsk.fg"), rsmp("cv", folds = 3L))
  p = rr$predictions()

  # check: different time points in each resampling `p[[i]]` (for cause 1)
  times1_fold1 = as.numeric(colnames(p[[1L]]$data$cif[["1"]]))
  times1_fold2 = as.numeric(colnames(p[[2L]]$data$cif[["1"]]))
  times1_fold3 = as.numeric(colnames(p[[3L]]$data$cif[["1"]]))
  expect_false(identical(times1_fold1, times1_fold2))
  expect_false(identical(times1_fold1, times1_fold3))
  expect_false(identical(times1_fold2, times1_fold3))

  # combine predictions
  pred = do.call(c, p)
  expect_prediction_cmprsk(pred)

  # check that time points are properly combined
  # cause 1
  times1 = as.numeric(colnames(pred$cif[["1"]]))
  # union of time points across folds in the combined prediction object
  expect_true(all(times1 == sort(unique(c(times1_fold1, times1_fold2, times1_fold3)))))

  # cause 2
  times2 = as.numeric(colnames(pred$cif[["2"]]))
  times2_fold1 = as.numeric(colnames(p[[1L]]$data$cif[["2"]]))
  times2_fold2 = as.numeric(colnames(p[[2L]]$data$cif[["2"]]))
  times2_fold3 = as.numeric(colnames(p[[3L]]$data$cif[["2"]]))
  # union of time points across folds in the combined prediction object
  expect_true(all(times2 == sort(unique(c(times2_fold1, times2_fold2, times2_fold3)))))

  # row ids are correctly combined
  dt = as.data.table(pred)
  expect_equal(dt$row_ids, c(p[[1]]$row_ids, p[[2]]$row_ids, p[[3]]$row_ids))
})

test_that("data.table/frame roundtrip", {
  p1 = learner$train(task)$predict(task)
  dt = as.data.table(p1)
  expect_data_table(dt, nrows = task$nrow, ncols = 4L, any.missing = FALSE)
  p2 = as_prediction_cmprsk(dt)
  expect_prediction_cmprsk(p2)

  expect_equal(p1$cif, p2$cif)
  expect_equal(dt[, !("CIF")], as.data.table(p2)[, !("CIF")])

  dt_df = as.data.frame(dt)
  p3 = as_prediction_cmprsk(dt_df)
  expect_prediction_cmprsk(p3)
})

test_that("named lists convert to predictions with validation", {
  p = learner$train(task)$predict(task)
  data_list = list(row_ids = p$row_ids, truth = p$truth, cif = p$cif)
  converted = as_prediction_cmprsk(data_list)
  expect_prediction_cmprsk(converted)
  expect_identical(converted$row_ids, p$row_ids)
  expect_identical(converted$truth, p$truth)
  expect_identical(converted$cif, p$cif)

  # removing mandatory elements should throw an error
  expect_error(as_prediction_cmprsk(data_list[-1L])) # no row_ids
  expect_error(as_prediction_cmprsk(data_list[-2L])) # no truth
  expect_error(as_prediction_cmprsk(data_list[-3L])) # no cif
  # adding extra elements should throw an error
  expect_error(as_prediction_cmprsk(c(data_list, list(extra_element = TRUE))))
  # invalid CIF values should throw an error
  data_list$cif[[1L]][1L, 1L] = -1
  expect_error(as_prediction_cmprsk(data_list))
})

test_that("filtering", {
  p = learner$train(task)$predict(task)

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

test_that("measurement weights are supported", {
  task_w = task$clone(deep = TRUE)$cbind(data.frame(w = runif(task$nrow)))
  task_w$set_col_roles("w", "weights_measure")

  p = learner$train(task_w)$predict(task_w)
  expect_prediction_cmprsk(p)
  expect_numeric(p$weights, len = task_w$nrow, any.missing = FALSE)
  expect_equal(p$weights, task_w$weights_measure$weight)

  dt = as.data.table(p)
  expect_data_table(dt, nrows = task_w$nrow, ncols = 5L)
  expect_equal(dt$weights, p$weights)
  p2 = as_prediction_cmprsk(dt)
  expect_equal(p2$weights, p$weights)
  p3 = as_prediction_cmprsk(list(row_ids = p$row_ids, truth = p$truth, cif = p$cif, weights = p$weights))
  expect_equal(p3$weights, p$weights)

  p$filter(c(20, 37, 42))
  expect_equal(p$weights, task_w$weights_measure[list(c(20, 37, 42)), on = "row_id"]$weight)

  pc = c(p, p)
  expect_prediction_cmprsk(pc)
  expect_equal(pc$weights, rep(p$weights, 2L))
  pc = c(p, p, keep_duplicates = FALSE)
  expect_equal(pc$weights, p$weights)

  # mismatched weights length and mixing weighted/unweighted predictions are rejected
  expect_error(
    PredictionCompRisks$new(row_ids = p$row_ids, truth = p$truth, cif = p$cif, weights = 1),
    "same length"
  )
  p_unweighted = PredictionCompRisks$new(row_ids = p$row_ids, truth = p$truth, cif = p$cif)
  expect_error(c(p, p_unweighted), "others do not", class = "Mlr3ErrorInput")
})

test_that("extra data is supported", {
  p = learner$train(task)$predict(task)
  extra = list(score = seq_len(task$nrow), flag = rep(c(TRUE, FALSE), length.out = task$nrow))
  pe = PredictionCompRisks$new(row_ids = p$row_ids, truth = p$truth, cif = p$cif, extra = extra)
  expect_prediction_cmprsk(pe)
  expect_equal(pe$extra, extra)

  dt = as.data.table(pe)
  expect_data_table(dt, nrows = task$nrow, ncols = 6L)
  expect_equal(dt$score, extra$score)

  pe$filter(c(20, 37, 42))
  expect_equal(pe$extra$score, c(20L, 37L, 42L))
  expect_equal(pe$extra$flag, extra$flag[c(20, 37, 42)])

  pc = c(pe, pe)
  expect_equal(pc$extra$score, rep(c(20L, 37L, 42L), 2L))
  pc = c(pe, pe, keep_duplicates = FALSE)
  expect_equal(pc$extra$score, c(20L, 37L, 42L))

  expect_error(
    PredictionCompRisks$new(row_ids = p$row_ids, truth = p$truth, cif = p$cif, extra = list(score = 1)),
    "same length"
  )
  expect_error(c(pe, p), "others do not", class = "Mlr3ErrorInput")
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
