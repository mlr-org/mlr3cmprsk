if (requireNamespace("testthat", quietly = TRUE)) {
  library(testthat)
  library(mlr3cmprsk)
  library(checkmate)

  test_check("mlr3cmprsk")
}
