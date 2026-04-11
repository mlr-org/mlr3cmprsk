# mlr3cmprsk

![](reference/figures/warning.png) This package is **under development**

Package website: [release](https://mlr3cmprsk.mlr-org.com/)

`mlr3cmprsk` extends the [mlr3](https://mlr3.mlr-org.com/) ecosystem
with a unified interface for machine learning in **competing risks
survival analysis**. It provides consistent task, learner, and
prediction abstractions, enabling seamless benchmarking, model
comparison, and integration with the broader `mlr3` framework.

## Installation

Install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("mlr-org/mlr3cmprsk")
```

## Example

``` r
library(mlr3cmprsk)
set.seed(42)

task = tsk("pbc")
task$select(c("age", "chol", "albumin", "bili"))
task$set_col_roles(cols = "status", add_to = "stratum")

learners = lrns(c("cmprsk.fg", "cmprsk.aalen"))

bm_grid = benchmark_grid(task, learners, rsmp("cv", folds = 3))
bm = benchmark(bm_grid)

# AUC at t = 100 (mean over causes, weighted by event frequencies)
bm$score(msr("cmprsk.auc", time = 100))[, .(task_id, learner_id, iteration, cmprsk.auc)]
```

``` R
##    task_id   learner_id iteration cmprsk.auc
## 1:     pbc    cmprsk.fg         1  0.7813865
## 2:     pbc    cmprsk.fg         2  0.7663073
## 3:     pbc    cmprsk.fg         3  0.8390308
## 4:     pbc cmprsk.aalen         1  0.5000000
## 5:     pbc cmprsk.aalen         2  0.5000000
## 6:     pbc cmprsk.aalen         3  0.5000000
```

``` r
# Brier score at t = 100 (mean over causes, weighted by event frequencies)
bm$score(msr("cmprsk.brier", time = 100))[, .(task_id, learner_id, iteration, cmprsk.brier)]
```

``` R
##    task_id   learner_id iteration cmprsk.brier
## 1:     pbc    cmprsk.fg         1    0.1564736
## 2:     pbc    cmprsk.fg         2    0.1750273
## 3:     pbc    cmprsk.fg         3    0.1371346
## 4:     pbc cmprsk.aalen         1    0.2182071
## 5:     pbc cmprsk.aalen         2    0.2200391
## 6:     pbc cmprsk.aalen         3    0.2181846
```

For more competing risk learners, see the [available
list](https://mlr3extralearners.mlr-org.com/reference/index.html#competing-risks-learners)
at `mlr3extralearners`.

For more details about available measures and their parameters, see
[reference
list](https://mlr3cmprsk.mlr-org.com/reference/index.html#competing-risks-measures).

## Code of Conduct

Please note that the mlr3cmprsk project is released with a [Contributor
Code of Conduct](https://mlr3cmprsk.mlr-org.com/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
