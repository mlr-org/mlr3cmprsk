#' @examplesIf mlr3misc::require_namespaces("riskRegression", quietly = TRUE)
#' # Define the Learner
#' learner = lrn("cmprsk.aalen")
#' learner
#'
#' # Define a Task
#' task = tsk("pbc")
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
#' # Score the predictions: Aalen-Johansen estimator
#' # has random discriminative performance
#' predictions$score(msr("cmprsk.auc", time_horizon = 100))
#'
