generate_tasks.LearnerCompRisks = function(learner, N = 20L, ...) {
  times = stats::rexp(N, rate = 0.2) # exp distr for event times
  # two competing events (0 => censored (30%), 1,2 => events (35% each))
  event = sample(0:2, size = N, replace = TRUE, prob = c(0.3, 0.35, 0.35))

  data = cbind(data.table::data.table(time = times, event = event), generate_data(learner, N))
  task = mlr3cmprsk::TaskCompRisks$new(id = "proto", backend = mlr3::as_data_backend(data))
  tasks = generate_generic_tasks(learner, task)

  # The sanity task has two equally sized groups (20 observations by default).
  # x = 0 has earlier times and mostly cause 1; x = 1 has later times and mostly cause 2.
  # All times in group 1 are greater than those in group 0, so x provides a strong predictive signal.
  # A separate standard normal feature adds noise unrelated to the generated times and events.
  # Ensure N is even
  if (N %% 2 == 1L) {
    N = N + 1L
  }
  N_half = N / 2L

  # Generate unique times
  times_group0 = seq(1, N_half)
  times_group1 = seq(max(times_group0) + 1, max(times_group0) + N_half)

  # Generate time ranges
  times_group0 = sort(rexp(N_half, rate = 0.3))
  times_group1 = sort(rexp(N_half, rate = 0.3)) + max(times_group0)

  # Group 0: 20% censoring, 60% cause 1, and 20% cause 2 (sampling probabilities).
  event_group0 = sample(c(0, 1, 2), size = N_half, replace = TRUE, prob = c(0.2, 0.6, 0.2))
  # Group 1: 30% censoring, 10% cause 1, and 60% cause 2 (sampling probabilities).
  event_group1 = sample(c(0, 1, 2), size = N_half, replace = TRUE, prob = c(0.3, 0.1, 0.6))

  data = data.table::data.table(
    x = rep(0:1, each = N_half),
    x_unif = stats::rnorm(N), # standard normal noise feature
    time = c(times_group0, times_group1),
    event = c(event_group0, event_group1)
  )
  tasks$sanity = mlr3cmprsk::TaskCompRisks$new(
    "sanity",
    mlr3::as_data_backend(data),
    time = "time",
    event = "event"
  )

  tasks
}
registerS3method("generate_tasks", "LearnerCompRisks", generate_tasks.LearnerCompRisks)

sanity_check.PredictionCompRisks = function(prediction, ...) {
  # sanity check (IBS should be between 0 and 1)
  prediction$score() >= 0 && prediction$score() <= 1
}
registerS3method("sanity_check", "PredictionCompRisks", sanity_check.PredictionCompRisks)
