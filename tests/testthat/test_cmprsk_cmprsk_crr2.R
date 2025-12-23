# default competing risk score needs this package
skip_if_not_installed("riskRegression")
skip_if_not_installed("cmprsk")
skip_if_not_installed("rlang")

test_that("pbc test, emulates autotest", {
  set.seed(42)
  task = tsk("pbc")
  task$select(c("age", "trt"))
  size = task$nrow
  logicalf = sample(c(TRUE, FALSE), size = size, replace = TRUE)
  task$cbind(data.frame(logicalf = logicalf))
  ids = partition(task, ratio = 0.95)
  learner = lrn("cmprsk.crr")
  expect_learner(learner)
  expect_true(inherits(learner, "LearnerCompRisks"))  # Check class
  expect_true(learner$id == "cmprsk.crr")  # Verify learner ID
  expect_true(learner$encapsulation["train"] =="none")  # Check default encapsulation

  learner$train(task, ids$train)
  expect_true(!is.null(learner$model))  # Verify model was trained
  expect_true(inherits(learner$model, "list"))  # Check model structure
    
  preds = learner$predict(task, ids$test)

  expect_prediction_cmprsk(preds)  # Verify prediction object
  expect_true(inherits(preds, "PredictionCompRisks"))  # Check prediction class
  expect_true(length(preds$row_ids) > 0)  # Ensure predictions were made
  expect_true(all(preds$row_ids %in% ids$test))  # Verify row IDs match test set

  # Clone and encapsulate learner
  learner_encapsulated = learner$clone(deep = TRUE)
  learner_encapsulated$encapsulate("mirai", default_fallback(learner_encapsulated))

  expect_true(learner_encapsulated$encapsulation["train"] == "mirai")  # Check encapsulation setting
 
  # Resample using holdout
    resampling = rsmp("holdout")
    expect_true(resampling$iters == 1)  # Verify # of iterations

  rr =  resample(task, learner_encapsulated, resampling, store_models = TRUE)

  expect_resample_result(rr)  # Verify resampling result
  expect_true(length(rr$learners) == 1)  # Check one learner in resampling
  expect_true(inherits(rr$prediction(), "PredictionCompRisks"))
})

