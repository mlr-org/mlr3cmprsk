
# mlr3cmprsk <img src="man/figures/logo.png" align = "right" width = "120" />

Package website: [mlr3cmprsk](https://mlr3cmprsk.mlr-org.com/)

`mlr3cmprsk` extends the [mlr3](https://mlr3.mlr-org.com/) ecosystem for
machine learning with **competing risks survival outcomes**. It provides
task, learner, prediction, and measure abstractions that support model
training, resampling, benchmarking, and evaluation within the `mlr3`
framework.

<!-- badges: start -->

[![r-cmd-check](https://github.com/mlr-org/mlr3cmprsk/actions/workflows/r-cmd-check.yml/badge.svg)](https://github.com/mlr-org/mlr3cmprsk/actions/workflows/r-cmd-check.yml)
[![codecov](https://codecov.io/gh/mlr-org/mlr3cmprsk/graph/badge.svg)](https://codecov.io/gh/mlr-org/mlr3cmprsk)
[![CRAN
Status](https://www.r-pkg.org/badges/version-ago/mlr3cmprsk)](https://cran.r-project.org/package=mlr3cmprsk)
[![Mattermost](https://img.shields.io/badge/chat-mattermost-orange.svg)](https://lmmisld-lmu-stats-slds.srv.mwn.de/mlr_invite/)
<!-- badges: end -->

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("mlr-org/mlr3cmprsk")
```

## Example

Compare a Fine-Gray model with the Aalen-Johansen baseline using 3-fold
CV on the built-in `pbc` task.

``` r
library(mlr3cmprsk)
set.seed(42L)

task = tsk("pbc")
task$select(c("age", "chol", "albumin", "bili"))
# Stratify by event status so all splits keep all available causes
task$set_col_roles(cols = "status", add_to = "stratum")

learners = lrns(c("cmprsk.fg", "cmprsk.aalen"))

bm_grid = benchmark_grid(task, learners, rsmp("cv", folds = 3L))
bm = benchmark(bm_grid)

measures = list(
  # AUC(t = 100)
  msr("cmprsk.auc", time = 100, id = "auc_t100"),
  # BS(t = 100)
  msr("cmprsk.brier", time = 100, id = "bs_t100"),
  # Integrated Brier score over the observed times in each test fold
  msr("cmprsk.ibs", id = "ibs")
)

# By default, each measure averages the cause-specific scores, with weights
# equal to the observed event frequencies in each test fold
bm$score(measures)[, .(task_id, learner_id, iteration, auc_t100, bs_t100, ibs)]
```

    ##    task_id   learner_id iteration  auc_t100   bs_t100
    ## 1:     pbc    cmprsk.fg         1 0.7813865 0.1564736
    ## 2:     pbc    cmprsk.fg         2 0.7663073 0.1750273
    ## 3:     pbc    cmprsk.fg         3 0.8390308 0.1371346
    ## 4:     pbc cmprsk.aalen         1 0.5000000 0.2182071
    ## 5:     pbc cmprsk.aalen         2 0.5000000 0.2200391
    ## 6:     pbc cmprsk.aalen         3 0.5000000 0.2181846
    ##          ibs
    ## 1: 0.1282833
    ## 2: 0.1351360
    ## 3: 0.1083177
    ## 4: 0.1670896
    ## 5: 0.1718521
    ## 6: 0.1678390

## Measures

All currently available measures use **cumulative incidence function
(CIF) predictions** and are calculated with `riskRegression::Score()`;
the Integrated Brier Score (IBS) is the default measure for competing
risks tasks.

| ID | Measure | Category | Prediction Type |
|:---|:---|:---|:---|
| [`cmprsk.ibs`](https://mlr3cmprsk.mlr-org.com/reference/mlr_measures_cmprsk.ibs.html) | Integrated Brier score | Scoring Rule | `cif` |
| [`cmprsk.brier`](https://mlr3cmprsk.mlr-org.com/reference/mlr_measures_cmprsk.brier.html) | Brier score at a specified time | Scoring Rule | `cif` |
| [`cmprsk.auc`](https://mlr3cmprsk.mlr-org.com/reference/mlr_measures_cmprsk.auc.html) | Time-dependent AUC at a specified time | Discrimination | `cif` |

## Learners

The package includes two learners, both of which return CIF predictions
for every cause.

| ID | Learner | Underlying Package |
|:---|:---|:---|
| [`cmprsk.aalen`](https://mlr3cmprsk.mlr-org.com/reference/mlr_learners_cmprsk.aalen.html) | Aalen-Johansen estimator | `survival::survfit()` |
| [`cmprsk.fg`](https://mlr3cmprsk.mlr-org.com/reference/mlr_learners_cmprsk.fg.html) | Fine-Gray subdistribution hazards model | `cmprsk::crr()` |

For additional models, see the [available
list](https://mlr3extralearners.mlr-org.com/reference/index.html#competing-risks-learners)
in `mlr3extralearners`, including CoxBoost (`cmprsk.coxboost`) and
random forests (`cmprsk.rfsrc`).

## Code of Conduct

This project follows a [Contributor Code of
Conduct](https://mlr3cmprsk.mlr-org.com/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
