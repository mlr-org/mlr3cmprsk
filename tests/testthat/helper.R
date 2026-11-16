library(checkmate)
library(mlr3)

# source helper files from mlr3 and mlr3cmprsk
lapply(
  list.files(
    system.file("testthat", package = "mlr3"),
    pattern = "^helper.*\\.[rR]$",
    full.names = TRUE
  ),
  source
)
lapply(
  list.files(
    system.file("testthat", package = "mlr3cmprsk"),
    pattern = "^helper.*\\.[rR]",
    full.names = TRUE
  ),
  source
)
