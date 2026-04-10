#' @examplesIf mlr3misc::require_namespaces("riskRegression", quietly = TRUE)
#' # Define the Learner (Aalen-Johansen/AJ estimator)
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
#' # Score the predictions
#' # AJ has random discriminative performance
#' predictions$score(msr("cmprsk.auc", time = 100))
#'
#' # Prediction error (Brier score) at specific time point
#' # BS(t) => weighted mean score across causes (default)
#' predictions$score(msr("cmprsk.brier", time = 100))
#'
