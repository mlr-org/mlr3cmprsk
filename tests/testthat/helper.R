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
