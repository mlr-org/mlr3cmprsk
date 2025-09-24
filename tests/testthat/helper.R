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
gen_cif = function(n = 20, n_events = 2, n_times = 20, max_time = 5) {
  # Common evaluation grid
  times = seq(0, max_time, length.out = n_times)

  # Random cause-specific hazards for each subject & cause =>
  # h_j => CONSTANT for j cause (and per observation)
  # shape: [n x n_events]
  hazards = matrix(runif(n * n_events, min = 0.1, max = 0.5),
                   nrow = n, ncol = n_events)

  # Total hazard per subject
  h_total = rowSums(hazards)

  # assume exponential survival with rate h_total: S(t) = exp(-h_total * t)
  # Compute CIF for each cause:
  # CIF_j(t) = \int_0^t S(u)*h_j du = (h_j / h_tot) * (1 - exp(-h_tot * t))
  # this guarantees: \sum CIF_j(t) = 1 - S(t)
  cif_list = lapply(seq_len(n_events), function(j) {
    mat = outer(times, seq_len(n), function(t, i) {
      (hazards[i, j] / h_total[i]) * (1 - exp(-h_total[i] * t))
    })
    t(mat) # rows = subjects, cols = times
  })

  # Assign colnames as times for convenience
  cif_list = lapply(cif_list, function(mat) {
    colnames(mat) = times
    mat
  })

  names(cif_list) = as.character(seq_len(n_events))
  cif_list
}
