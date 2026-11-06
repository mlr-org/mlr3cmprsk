# Simulate competing risks data

Simulates right-censored competing risks data with baseline numerical
covariates (up to 10 features) and a specified number of competing event
causes (2 to 5). Event times and causes are generated from
cause-specific Weibull proportional hazards. Censoring times are
generated independently from a Weibull distribution.

## Usage

``` r
sim_cmprsk(
  n,
  n_features = 3L,
  n_causes = 2L,
  event_probs = NULL,
  shape = 1,
  rate = 0.2,
  beta_sd = 0.3
)
```

## Arguments

- n:

  (`integer(1)`)  
  Positive number of observations (sample size), should be at least
  `n_causes`.

- n_features:

  (`integer(1)`)  
  Number of independent features drawn from the standard normal
  distribution, from 1 to 10. Defaults to 3.

- n_causes:

  (`integer(1)`)  
  Number of competing event causes, from 2 to 5. Defaults to 2.

- event_probs:

  ([`numeric()`](https://rdrr.io/r/base/numeric.html) \| `NULL`)  
  Desired observed cause probabilities, in cause order, with length
  `n_causes`. Every entry must be finite and strictly positive, and
  their sum must not exceed 1. The remaining probability specifies
  censoring; a sum of 1 disables censoring. These probabilities hold
  theoretically when `beta_sd = 0`, and are approximate with covariate
  effects. `NULL` uses `rep(0.8 / n_causes, n_causes)`, targeting 20%
  censoring and dividing the remaining 80% equally among the competing
  causes when `beta_sd = 0`.

- shape:

  (`numeric(1)`)  
  Positive, finite common Weibull shape for event and censoring times.
  Defaults to 1, giving constant hazards and exponentially distributed
  times.

- rate:

  (`numeric(1)`)  
  Positive, finite multiplier for the baseline cumulative hazards,
  defaulting to 0.2. Cause-specific coefficients are
  `rate * event_probs`, and the censoring coefficient is
  `rate * (1 - sum(event_probs))`. Larger values produce shorter times
  without changing the theoretical event and censoring proportions.

- beta_sd:

  (`numeric(1)`)  
  Nonnegative, finite standard deviation of the normal regression
  coefficients. Defaults to 0.3; zero disables covariate effects.

## Value

A [data.table](https://rdrr.io/pkg/data.table/man/data.table.html) with
`n` rows and the following columns:

- `time`: positive, finite observed time \\T_i\\.

- `event`: integer observed event code, with 0 for censoring and 1
  through `n_causes` for competing events.

- `x1`, ..., `xp`: baseline features, where `p = n_features`.

- `event_time`, `event_cause`: latent first event time \\Y_i\\ and cause
  \\J_i\\.

- `cens_time`: independent censoring time \\C_i\\, or `Inf` when
  censoring is disabled.

- `total_rate`: total individual event cumulative-hazard coefficient
  \\R_i\\, excluding censoring.

- `lp1`, ..., `lpK`: cause-specific linear predictors \\x_i^\top
  \beta_k\\, where `K = n_causes`.

- `rate1`, ..., `rateK`: individual cause-specific cumulative-hazard
  coefficients \\r\_{ik}\\.

## Details

For each observation \\i\\, the baseline covariates \\x_i\\ are
independent standard normal variables. Each cause \\k = 1, \ldots, K\\
has a coefficient vector \\\beta_k\\, whose elements are independently
sampled from \\N(0, \mathrm{beta\\sd}^2)\\.

The cause-specific hazards follow a Weibull proportional hazards model:

\$\$h\_{ik}(t) = \gamma \lambda_k t^{\gamma - 1} \exp(x_i^\top
\beta_k),\$\$

where \\\gamma = \mathrm{shape} \> 0\\ is the common Weibull shape and
\\\lambda_k = \mathrm{rate} \cdot p_k \> 0\\ is the cause-specific
baseline cumulative-hazard coefficient. The \\p_k\\ are the specified
target proportions for the observed competing events. With `shape = 1`
(the default), the hazards are constant over time and event times follow
exponential distributions.

Define \\r\_{ik} = \lambda_k \exp(x_i^\top \beta_k)\\ and \\R_i =
\sum\_{k=1}^K r\_{ik}\\. The cumulative hazards and overall event-free
survival function, conditional on the covariates, are

\$\$H\_{ik}(t) = r\_{ik} t^\gamma, \qquad H_i(t) = R_i t^\gamma,\$\$

\$\$S_i(t) = \exp(-R_i t^\gamma).\$\$

The quantities \\r\_{ik}\\ and \\R_i\\ are cumulative-hazard
coefficients, corresponding to constant hazard rates when \\\gamma =
1\\.

To simulate the uncensored event time, draw \\E_i \sim \mathrm{Exp}(1)\\
and set

\$\$Y_i = (E_i / R_i)^{1/\gamma}.\$\$

The event cause \\J_i\\ is then sampled with probabilities \\P(J_i = k
\mid x_i) = r\_{ik}/R_i\\. Because all cause-specific hazards share the
same Weibull shape, the event cause and uncensored event time are
conditionally independent given the covariates. This follows the
cause-specific hazard-based simulation framework of Beyersmann et al.
(2009).

Censoring is generated independently of the covariates and event
process. Let \\p_0 = 1 - \sum\_{k=1}^K p_k\\ and \\\lambda_C =
\mathrm{rate} \cdot p_0\\. Draw \\E\_{Ci} \sim \mathrm{Exp}(1)\\
independently and set

\$\$C_i = (E\_{Ci} / \lambda_C)^{1/\gamma}.\$\$

If \\p_0 = 0\\, set \\C_i = \infty\\, corresponding to no censoring. The
observed time is \\T_i = \min(Y_i, C_i)\\, with observed event indicator
\\\delta_i = J_i\\ if \\Y_i \le C_i\\, and \\\delta_i = 0\\ otherwise.

Under this model, the cause-specific cumulative incidence functions have
the analytical form

\$\$F\_{ik}(t) = \frac{r\_{ik}}{R_i} \left(1 - \exp(-R_i
t^\gamma)\right),\$\$

satisfying \\\sum\_{k=1}^K F\_{ik}(t) = 1 - S_i(t)\\.

The conditional probability of observing cause \\k\\ is \\r\_{ik}/(R_i +
\lambda_C)\\, while the probability of censoring is \\\lambda_C/(R_i +
\lambda_C)\\. Thus, `event_probs` gives the exact theoretical marginal
proportions (\\p_k\\ and \\p_0\\ respectively) when `beta_sd = 0`. With
covariate effects, these are only nominal targets. Realized sample
proportions also vary due to random sampling.

The function errors if any cause is missing among the observed events,
and reports the missing causes. Missing causes are more likely with
small samples, rare causes, or heavy censoring, so try to adjust `n`,
`event_probs`, or `n_causes` if necessary. Extreme parameter values
producing invalid rates or event times also can result in an error.

Use [`set.seed()`](https://rdrr.io/r/base/Random.html) for
reproducibility.

## References

Beyersmann, Jan, Latouche, Aurelien, Buchholz, Anika, Schumacher, Martin
(2009). “Simulating competing risks data in survival analysis.”
*Statistics in Medicine*, **28**(6), 956–971.
[doi:10.1002/sim.3516](https://doi.org/10.1002/sim.3516) .

## See also

[mlr_task_generators_cmprsk](https://mlr3cmprsk.mlr-org.com/reference/mlr_task_generators_cmprsk.md)

## Examples

``` r
set.seed(42)
data = sim_cmprsk(200, n_features = 5L, n_causes = 3L, event_probs = c(0.4, 0.2, 0.1))
head(data)
#>         time event         x1         x2          x3         x4         x5
#>        <num> <int>      <num>      <num>       <num>      <num>      <num>
#> 1:  7.380396     0  1.3709584 -2.0009292  1.33491259 -0.2484829  0.6888078
#> 2:  5.246867     1 -0.5646982  0.3337772 -0.86927176  0.4223204  0.7250830
#> 3: 11.818363     2  0.3631284  1.1713251  0.05548695  0.9876533  0.2173802
#> 4: 11.533096     1  0.6328626  2.0595392  0.04906691  0.8355682 -0.2016567
#> 5: 12.563653     1  0.4042683 -1.3768616 -0.57835573 -0.6605219 -1.3656899
#> 6:  9.299781     1 -0.1061245 -1.1508556 -0.99873866  1.5640695 -0.3089376
#>    event_time event_cause cens_time        lp1        lp2        lp3      rate1
#>         <num>       <int>     <num>      <num>      <num>      <num>      <num>
#> 1:  10.367409           1  7.380396  0.7964980 -1.2894835  0.5662306 0.17742086
#> 2:   5.246867           1 34.018508 -0.7634335  0.9477437 -0.1367795 0.03728508
#> 3:  11.818363           2 20.705564  0.5003694 -0.2549223 -0.2379831 0.13194644
#> 4:  11.533096           1 15.133334  0.9343042 -0.3153013 -0.3935922 0.20363534
#> 5:  12.563653           1 23.690613  0.2304035  0.2082231 -0.2196737 0.10072863
#> 6:   9.299781           1 13.233164 -0.2766449  0.3675303 -0.4668071 0.06066590
#>         rate2      rate3 total_rate
#>         <num>      <num>      <num>
#> 1: 0.01101652 0.03523229  0.2236697
#> 2: 0.10319529 0.01744325  0.1579236
#> 3: 0.03099907 0.01576432  0.1787098
#> 4: 0.02918276 0.01349258  0.2463107
#> 5: 0.04925951 0.01605561  0.1660438
#> 6: 0.05776654 0.01254002  0.1309725
prop.table(table(data$event))
#> 
#>     0     1     2     3 
#> 0.215 0.360 0.350 0.075 
```
