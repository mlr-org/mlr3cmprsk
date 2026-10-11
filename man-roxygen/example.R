#' @examples
#' # Define a task
#' task = tsk("pbc")
#' task$select(c("age", "chol", "albumin", "ast", "bili", "protime"))
#'
#' # Stratify by event status
#' task$set_col_roles(cols = "status", add_to = "stratum")
#' task
#'
#' # Create training and test sets
#' set.seed(42L)
#' part = partition(task)
#'
#' # Define the learner
#' learner = lrn("<%= learner_id %>")
#'
#' # Train on the training set
#' learner$train(task, row_ids = part$train)
#' learner$native_model
#'
#' # Predict CIFs for the test set
#' predictions = learner$predict(task, row_ids = part$test)
#' predictions
#'
