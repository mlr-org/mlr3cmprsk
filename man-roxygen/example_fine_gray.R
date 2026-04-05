#' @examplesIf mlr3misc::require_namespaces("riskRegression", quietly = TRUE)
#' # Define the Learner
#' learner = lrn("cmprsk.fg")
#' learner
#'
#' # Define a Task
#' task = tsk("pbc")
#'
#' # Subset task features as Fine-Gray model doesn't accept factors
#' # Encode factors with `mlr3pipelines::po("encode")` if needed
#' feats = c("age", "chol", "albumin", "ast", "bili", "protime")
#' task$select(feats)
#'
#' # Stratification based on event
#' task$set_col_roles(cols = "status", add_to = "stratum")
#'
#' # Create train and test set
#' part = partition(task)
#'
#' # Train the learner on the training set
#' learner$train(task, row_ids = part$train)
#' learner$native_model
#'
#' # Make predictions for the test set
#' predictions = learner$predict(task, row_ids = part$test)
#' predictions
#'
#' # Score the predictions
#' # AUC(t = 100), weighted mean score across causes (default)
#' predictions$score(msr("cmprsk.auc", cause = "mean", time_horizon = 100))
#'
#' # AUC(t = 100), 1st cause
#' predictions$score(msr("cmprsk.auc", cause = 1, time_horizon = 100))
#'
#' # AUC(t = 100), 2nd cause
#' predictions$score(msr("cmprsk.auc", cause = 2, time_horizon = 100))
#'
