
# mlr3cmprsk <img src="man/figures/logo.png" align = "right" width = "120" />

Package website: [mlr3cmprsk](https://mlr3cmprsk.mlr-org.com/)

`mlr3cmprsk` extends the [mlr3](https://mlr3.mlr-org.com/) ecosystem for
machine learning with **competing risks right-censored survival
outcomes**. It provides task, learner, prediction, and measure
abstractions that support model training, resampling, benchmarking, and
evaluation within the `mlr3` framework.

<!-- badges: start -->

[![r-cmd-check](https://github.com/mlr-org/mlr3cmprsk/actions/workflows/r-cmd-check.yml/badge.svg)](https://github.com/mlr-org/mlr3cmprsk/actions/workflows/r-cmd-check.yml)
[![codecov](https://codecov.io/gh/mlr-org/mlr3cmprsk/graph/badge.svg)](https://codecov.io/gh/mlr-org/mlr3cmprsk)
[![CRAN
Status](https://www.r-pkg.org/badges/version-ago/mlr3cmprsk)](https://cran.r-project.org/package=mlr3cmprsk)
<!-- badges: end -->

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("mlr-org/mlr3cmprsk")
```

## Example

Compare a Fine-Gray model with the Aalen-Johansen baseline using 3-fold
CV on all four built-in tasks. The Fine-Gray pipeline uses
`mlr3pipelines` to encode factor predictors and standardize features for
numerical stability.

``` r
library(mlr3cmprsk)
library(mlr3pipelines)
set.seed(42L)

tasks = tsks(c("pbc", "transplant", "mgus2", "hoel"))
tasks$pbc$select(c("age", "chol", "albumin", "bili"))
# Stratify by event status so all splits keep all available causes
for (task in tasks) {
  task$set_col_roles(task$target_names[2L], add_to = "stratum")
}

learner1 = as_learner(
  po("encode", method = "treatment") %>>% po("scale") %>>% lrn("cmprsk.fg")
)
learner1$id = "cmprsk.fg"
learner2 = lrn("cmprsk.aalen")
learners = list(learner1, learner2)

bm_grid = benchmark_grid(tasks, learners, rsmp("cv", folds = 3L))
bm = benchmark(bm_grid)

measures = list(
  # AUC and Brier score at each test fold's median follow-up time, which is in
  # months for `mgus2`, and days for the other tasks
  msr("cmprsk.auc", id = "auc"),
  msr("cmprsk.brier", id = "brier"),
  # IBS: 50 equally spaced times from 0 to each test fold's 90th follow-up percentile
  msr("cmprsk.ibs", ntimes = 50, id = "ibs")
)

# By default, each measure averages the cause-specific scores, with weights
# equal to the observed event frequencies in each test fold
bm$aggregate(measures)[, .(task_id, learner_id, auc, brier, ibs)]
```

    ##       task_id   learner_id       auc     brier        ibs
    ## 1:        pbc    cmprsk.fg 0.8509168 0.1180410 0.10811066
    ## 2:        pbc cmprsk.aalen 0.5000000 0.1800472 0.15472607
    ## 3: transplant    cmprsk.fg 0.7817820 0.1553654 0.14468693
    ## 4: transplant cmprsk.aalen 0.5000000 0.2160769 0.18127722
    ## 5:      mgus2    cmprsk.fg 0.7219273 0.1842674 0.15657283
    ## 6:      mgus2 cmprsk.aalen 0.5000000 0.2182213 0.18878181
    ## 7:       hoel    cmprsk.fg 0.5261999 0.1362216 0.09429959
    ## 8:       hoel cmprsk.aalen 0.5000000 0.1361634 0.09460271

## Tasks

The package includes four competing risks tasks from the `survival` R
package. The counts below describe the tasks after preprocessing; causes
exclude censoring.

| ID | Label | Source | Features | Rows | Causes |
|:---|:---|:---|---:|---:|---:|
| [`hoel`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_hoel.html) | Mouse Cancer Data | `survival::hoel` | 1 | 181 | 3 |
| [`transplant`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_transplant.html) | Liver Transplant Waiting List Data | `survival::transplant` | 4 | 793 | 3 |
| [`mgus2`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_mgus2.html) | Monoclonal Gammopathy Data | `survival::mgus2` | 6 | 1,338 | 2 |
| [`pbc`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_pbc.html) | Mayo Clinic Primary Biliary Cholangitis Data | `survival::pbc` | 17 | 276 | 2 |

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

We welcome contributions and pull requests to add new competing risks
learners in `mlr3extralearners`.

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

## Citation

If you use `mlr3cmprsk` in your work, please cite it using the following
BibTeX entry:

``` bibtex
@Manual{mlr3cmprsk,
  title = {mlr3cmprsk: Competing Risks Machine Learning for 'mlr3'},
  author = {John Zobolas and Andreas Bender},
  year = {2026},
  note = {R package version 0.0.8, https://github.com/mlr-org/mlr3cmprsk},
  url = {https://mlr3cmprsk.mlr-org.com},
}
```

## Code of Conduct

This project follows a [Contributor Code of
Conduct](https://mlr3cmprsk.mlr-org.com/CODE_OF_CONDUCT.html). By
contributing to this project, you agree to abide by its terms.
