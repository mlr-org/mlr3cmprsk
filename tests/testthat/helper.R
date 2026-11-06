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

# Generate a list of CIF matrices
gen_cif = function(n = 20, n_events = 2, n_times = 20, max_time = 5) {
  # Common evaluation grid
  times = seq(0, max_time, length.out = n_times)

  # Random cause-specific hazards for each subject & cause =>
  # h_j => CONSTANT for j cause (and per observation)
  # shape: [n x n_events]
  hazards = matrix(runif(n * n_events, min = 0.1, max = 0.5), nrow = n, ncol = n_events)

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

# default: 3 causes, but no data for event 2
# 3rd cause starts from t = 3, 1st cause starts from t = 1
gen_PredictionCompRisks = function(event = c(1, 0, 3, 0, 3, 1, 3, 0)) {
  n = length(event)

  cif = set_names(
    lapply(seq_len(3L), function(cause) {
      # Vary risks across observations and rankings across causes
      risk = ((seq_len(n) + cause - 2L) %% n + 1L) / n
      matrix(
        rep(c(0.03, 0.07, 0.12) * cause, each = n) * risk,
        nrow = n,
        dimnames = list(NULL, c("1", "4", "8"))
      )
    }),
    as.character(1:3)
  )

  PredictionCompRisks$new(
    row_ids = seq_len(n),
    truth = Surv(seq_len(n), factor(event, levels = 0:3)),
    cif = cif
  )
}
