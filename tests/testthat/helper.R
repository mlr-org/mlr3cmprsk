library(checkmate)
library(mlr3)

# source helper files from mlr3 and mlr3cmprsk
lapply(list.files(system.file("testthat", package = "mlr3"), pattern = "^helper.*\\.[rR]$", full.names = TRUE), source)
lapply(list.files(system.file("testthat", package = "mlr3cmprsk"), pattern = "^helper.*\\.[rR]", full.names = TRUE), source)

# TODO: make Task Generator???
gen_cmprsk_task = function(n = 50, n_events = 2) {
  # Generate exp distribution for event times
  times = stats::rexp(n, rate = 0.2)

  # Generate competing risks event types (0 = censored, 1 to n_events = events)
  event = sample(0:n_events, size = n, replace = TRUE,
                 prob = c(0.3, rep(0.7 / n_events, n_events)))

  # Covariate (could be expanded)
  x = runif(n)

  # Create data frame
  df = data.frame(time = times, event = event, x = x)

  # Return a TaskCompRisks object
  TaskCompRisks$new(id = "test", backend = df)
}

# Generate a list of CIF matrices
gen_cif = function(n = 20, n_events = 2, n_times = 20) {
  cif_list = lapply(1:n_events, function(i) {
    # Randomly choose the number of time points for this event
    k = sample(n_times, 1)

    # Generate a CIF matrix where each row starts at 0 and increases
    cif_mat = matrix(apply(matrix(runif(n * k, min = 0, max = 1), nrow = n), 1, function(x) {
      c(0, sort(x)) # Ensure first value is 0 and sequence is increasing
    }), nrow = n, byrow = TRUE)
    set_col_names(cif_mat, 1:(k+1))
  })
  names(cif_list) = 1:n_events

  cif_list
}
