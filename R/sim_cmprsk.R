#' @title Simulate competing risks data
#'
#' @description
#' Simulates right-censored competing risks data with baseline numerical covariates
#' (up to 10 features) and a specified number of competing event causes (2 to 5).
#' Event times and causes are generated from cause-specific Weibull proportional hazards.
#' Censoring times are generated independently from a Weibull distribution.
#'
#' @details
#' For each observation \eqn{i}, the baseline covariates \eqn{x_i} are
#' independent standard normal variables. Each cause \eqn{k = 1, \ldots, K}
#' has a coefficient vector \eqn{\beta_k}, whose elements are independently
#' sampled from \eqn{N(0, \mathrm{beta\_sd}^2)}.
#'
#' The cause-specific hazards follow a Weibull proportional hazards model:
#'
#' \deqn{h_{ik}(t) = \gamma \lambda_k t^{\gamma - 1}
#'   \exp(x_i^\top \beta_k),}
#'
#' where \eqn{\gamma = \mathrm{shape} > 0} is the common Weibull shape and
#' \eqn{\lambda_k = \mathrm{rate} \cdot p_k > 0} is the cause-specific
#' baseline cumulative-hazard coefficient. The \eqn{p_k} are the
#' specified target proportions for the observed competing events.
#' With `shape = 1` (the default), the hazards are constant over time
#' and event times follow exponential distributions.
#'
#' Define \eqn{r_{ik} = \lambda_k \exp(x_i^\top \beta_k)} and
#' \eqn{R_i = \sum_{k=1}^K r_{ik}}. The cumulative hazards and overall
#' event-free survival function, conditional on the covariates, are
#'
#' \deqn{H_{ik}(t) = r_{ik} t^\gamma, \qquad
#' H_i(t) = R_i t^\gamma,}
#'
#' \deqn{S_i(t) = \exp(-R_i t^\gamma).}
#'
#' The quantities \eqn{r_{ik}} and \eqn{R_i} are cumulative-hazard
#' coefficients, corresponding to constant hazard rates when
#' \eqn{\gamma = 1}.
#'
#' To simulate the uncensored event time, draw \eqn{E_i \sim \mathrm{Exp}(1)} and set
#'
#' \deqn{Y_i = (E_i / R_i)^{1/\gamma}.}
#'
#' The event cause \eqn{J_i} is then sampled with probabilities
#' \eqn{P(J_i = k \mid x_i) = r_{ik}/R_i}.
#' Because all cause-specific hazards share the same Weibull shape,
#' the event cause and uncensored event time are conditionally independent
#' given the covariates. This follows the cause-specific hazard-based
#' simulation framework of Beyersmann et al. (2009).
#'
#' Censoring is generated independently of the covariates and event process.
#' Let \eqn{p_0 = 1 - \sum_{k=1}^K p_k} and \eqn{\lambda_C = \mathrm{rate} \cdot p_0}.
#' Draw \eqn{E_{Ci} \sim \mathrm{Exp}(1)} independently and set
#'
#' \deqn{C_i = (E_{Ci} / \lambda_C)^{1/\gamma}.}
#'
#' If \eqn{p_0 = 0}, set \eqn{C_i = \infty}, corresponding to no censoring.
#' The observed time is \eqn{T_i = \min(Y_i, C_i)}, with observed event indicator
#' \eqn{\delta_i = J_i} if \eqn{Y_i \le C_i}, and \eqn{\delta_i = 0} otherwise.
#'
#' Under this model, the cause-specific cumulative incidence functions
#' have the analytical form
#'
#' \deqn{F_{ik}(t) = \frac{r_{ik}}{R_i}
#'   \left(1 - \exp(-R_i t^\gamma)\right),}
#'
#' satisfying \eqn{\sum_{k=1}^K F_{ik}(t) = 1 - S_i(t)}.
#'
#' The conditional probability of observing cause \eqn{k} is
#' \eqn{r_{ik}/(R_i + \lambda_C)}, while the probability of
#' censoring is \eqn{\lambda_C/(R_i + \lambda_C)}.
#' Thus, `event_probs` gives the exact theoretical marginal proportions
#' (\eqn{p_k} and \eqn{p_0} respectively) when `beta_sd = 0`.
#' With covariate effects, these are only nominal targets. Realized sample
#' proportions also vary due to random sampling.
#'
#' The function errors if any cause is missing among the observed events, and
#' reports the missing causes.
#' Missing causes are more likely with small samples, rare causes, or heavy censoring,
#' so try to adjust `n`, `event_probs`, or `n_causes` if necessary.
#' Extreme parameter values producing invalid rates or event times also can result in an error.
#'
#' Use [set.seed()] for reproducibility.
#'
#' @param n (`integer(1)`)\cr
#'   Positive number of observations (sample size), should be at least `n_causes`.
#' @param n_features (`integer(1)`)\cr
#'   Number of independent features drawn from the standard normal distribution, from 1 to 10.
#'   Defaults to 3.
#' @param n_causes (`integer(1)`)\cr
#'   Number of competing event causes, from 2 to 5.
#'   Defaults to 2.
#' @param event_probs (`numeric()` | `NULL`)\cr
#'   Desired observed cause probabilities, in cause order, with length `n_causes`.
#'   Every entry must be finite and strictly positive, and their sum must not exceed 1.
#'   The remaining probability specifies censoring; a sum of 1 disables censoring.
#'   These probabilities hold theoretically when `beta_sd = 0`, and are approximate with covariate effects.
#'   `NULL` uses `rep(0.8 / n_causes, n_causes)`, targeting 20% censoring
#'   and dividing the remaining 80% equally among the competing causes when `beta_sd = 0`.
#' @param shape (`numeric(1)`)\cr
#'   Positive, finite common Weibull shape for event and censoring times.
#'   Defaults to 1, giving constant hazards and exponentially distributed times.
#' @param rate (`numeric(1)`)\cr
#'   Positive, finite multiplier for the baseline cumulative hazards, defaulting to 0.2.
#'   Cause-specific coefficients are `rate * event_probs`,
#'   and the censoring coefficient is `rate * (1 - sum(event_probs))`.
#'   Larger values produce shorter times without changing the theoretical event and censoring proportions.
#' @param beta_sd (`numeric(1)`)\cr
#'   Nonnegative, finite standard deviation of the normal regression coefficients.
#'   Defaults to 0.3; zero disables covariate effects.
#'
#' @return A [data.table][data.table::data.table] with `n` rows and the following columns:
#' * `time`: positive, finite observed time \eqn{T_i}.
#' * `event`: integer observed event code, with 0 for censoring and 1 through `n_causes` for competing events.
#' * `x1`, ..., `xp`: baseline features, where `p = n_features`.
#' * `event_time`, `event_cause`: latent first event time \eqn{Y_i} and cause \eqn{J_i}.
#' * `cens_time`: independent censoring time \eqn{C_i}, or `Inf` when censoring is disabled.
#' * `total_rate`: total individual event cumulative-hazard coefficient \eqn{R_i}, excluding censoring.
#' * `lp1`, ..., `lpK`: cause-specific linear predictors \eqn{x_i^\top \beta_k}, where `K = n_causes`.
#' * `rate1`, ..., `rateK`: individual cause-specific cumulative-hazard coefficients \eqn{r_{ik}}.
#'
#' @references
#' `r format_bib("beyersmann_2009")`
#'
#' @seealso [mlr_task_generators_cmprsk]
#' @export
#' @examples
#' set.seed(42)
#' data = sim_cmprsk(200, n_features = 5L, n_causes = 3L, event_probs = c(0.4, 0.2, 0.1))
#' head(data)
#' prop.table(table(data$event))
sim_cmprsk = function(
  n,
  n_features = 3L,
  n_causes = 2L,
  event_probs = NULL,
  shape = 1,
  rate = 0.2,
  beta_sd = 0.3
) {
  assert_count(n, positive = TRUE)
  assert_int(n_features, lower = 1L, upper = 10L)
  assert_int(n_causes, lower = 2L, upper = 5L)
  if (n < n_causes) {
    error_input(
      "`n` must be at least `n_causes` (%i). Increase `n` or reduce `n_causes`.",
      n_causes
    )
  }
  assert_number(shape, lower = 0, finite = TRUE)
  assert_number(rate, lower = 0, finite = TRUE)
  assert_number(beta_sd, lower = 0, finite = TRUE)
  if (shape == 0 || rate == 0) {
    error_input("`shape` and `rate` must be strictly positive.")
  }
  event_probs = event_probs %??% rep(0.8 / n_causes, n_causes)
  assert(check_cmprsk_event_probs(event_probs), .var.name = "event_probs")
  assert_numeric(event_probs, len = n_causes)

  # Sample baseline features and one coefficient vector per cause, shared by all observations
  x = matrix(stats::rnorm(n * n_features), nrow = n, ncol = n_features)
  beta = matrix(
    stats::rnorm(n_features * n_causes, sd = beta_sd),
    nrow = n_features,
    ncol = n_causes
  )
  # Individual rates combine baseline rates with the covariate effects
  lp = x %*% beta
  rates = sweep(exp(lp), 2L, rate * event_probs, `*`)
  total_rate = rowSums(rates)
  if (any(!is.finite(total_rate)) || any(!is.finite(rates)) || any(rates <= 0)) {
    error_input(
      "Simulation produced non-finite or non-positive rates; try different `rate` or `beta_sd`."
    )
  }

  # Invert the overall survival function to obtain the uncensored first event time
  event_time = (stats::rexp(n) / total_rate)^(1 / shape)
  # Sample each cause from its share of the total rate using cumulative probabilities
  u = stats::runif(n)
  cum_prob = numeric(n)
  event_cause = rep.int(1L, n)
  for (k in seq_len(n_causes - 1L)) {
    cum_prob = cum_prob + rates[, k] / total_rate
    event_cause = event_cause + as.integer(u > cum_prob) # +0 or +1
  }

  # Independent censoring uses the same Weibull shape
  # Zero censoring probability gives infinite times
  cens_prob = 1 - sum(event_probs)
  cens_rate = rate * cens_prob
  cens_time = if (cens_prob == 0) {
    rep(Inf, n)
  } else {
    (stats::rexp(n) / cens_rate)^(1 / shape)
  }

  # check for extreme event and censoring times
  # infinite times are valid only when censoring is disabled
  if (
    any(!is.finite(event_time)) ||
      any(event_time <= 0) ||
      (cens_prob > 0 && (any(!is.finite(cens_time)) || any(cens_time <= 0)))
  ) {
    error_input(
      "Simulation produced non-finite or non-positive times; use less extreme simulation parameters."
    )
  }

  # check that every requested cause has an observed event
  event = ifelse(event_time <= cens_time, event_cause, 0L)
  missing_causes = setdiff(seq_len(n_causes), event)
  if (length(missing_causes)) {
    error_input(
      paste0(
        "Missing observed causes in simulated data: %s. ",
        "Increase `n`, adjust `event_probs`, or reduce `n_causes`."
      ),
      str_collapse(missing_causes)
    )
  }

  # output table with observed outcomes, covariates x and some useful simulation quantities
  colnames(x) = paste0("x", seq_len(n_features))
  colnames(lp) = paste0("lp", seq_len(n_causes))
  colnames(rates) = paste0("rate", seq_len(n_causes))
  data.table(
    time = pmin(event_time, cens_time),
    event = event,
    as.data.table(x),
    event_time = event_time,
    event_cause = event_cause,
    cens_time = cens_time,
    total_rate = total_rate,
    as.data.table(lp),
    as.data.table(rates)
  )
}

# Shared event probability validation
check_cmprsk_event_probs = function(x) {
  result = check_numeric(x, min.len = 2L, max.len = 5L, finite = TRUE, any.missing = FALSE)

  if (!isTRUE(result)) {
    return(result)
  }

  if (any(x <= 0)) {
    return("Every cause probability must be strictly positive")
  }

  if (sum(x) > 1) {
    return("Cause probabilities must sum to at most 1")
  }

  TRUE
}
