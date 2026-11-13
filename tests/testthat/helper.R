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
# - n => number of observations
# - times => list with time points for each CIF matrix, length defines number of causes
gen_cif = function(n = 20, times = list("1" = 0:5, "2" = 0:3)) {
  n_causes = length(times)

  # Random cause-specific hazards for each subject & cause:
  # h_ik => CONSTANT for i obs and k cause
  # shape: [n x n_causes]
  hazards = matrix(
    runif(n * n_causes, min = 0.1, max = 0.5),
    nrow = n,
    ncol = n_causes
  )

  # (All-cause) total hazard per subject
  # h_i = \sum_k h_ik
  h_total = rowSums(hazards)

  # All-cause survival: S_i(t) = exp(-H_i(t)) = exp(-h_i * t)
  # Cause-specific CIF: F_ik(t) = \int_0^t S_i(u)*h_ik du = (h_ik / h_i) * (1 - exp(-h_i * t))
  # This guarantees: \sum F_ik(t) = 1 - S_i(t)
  cif_list = lapply(seq_len(n_causes), function(k) {
    mat = outer(times[[k]], seq_len(n), function(t, i) {
      (hazards[i, k] / h_total[i]) * (1 - exp(-h_total[i] * t))
    })
    t(mat) # rows = subjects, cols = times
  })

  names(cif_list) = names(times)
  cif_list
}

# Generate PredictionCompRisks object with 3 causes
# - By default, no observations with event 2
# - length of `event` defines the number of observations (n)
# - times are simply 1,2,...,n
# - all 3 causes have the same time grid
# - 3rd cause starts from t = 3, 1st cause starts from t = 1
gen_PredictionCompRisks = function(event = c(1, 0, 3, 0, 3, 1, 3, 0)) {
  n = length(event)

  cif = set_names(
    lapply(seq_len(3L), function(cause) {
      # Vary risks across observations and rankings across causes
      risk = ((seq_len(n) + cause - 2L) %% n + 1L) / n
      matrix(
        rep(c(0.03, 0.07, 0.12) * cause, each = n) * risk,
        nrow = n
      )
    }),
    as.character(1:3)
  )

  PredictionCompRisks$new(
    row_ids = seq_len(n),
    truth = Surv(
      seq_len(n),
      factor(event, levels = 0:3, labels = c("Censored", paste("Cause", 1:3)))
    ),
    cif = cif,
    times = set_names(rep(list(c(1, 4, 8)), 3L), as.character(1:3))
  )
}
