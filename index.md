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

task = tsk("pbc")
task$select(c("age", "chol", "albumin", "bili"))
task$set_col_roles(cols = "status", add_to = "stratum")

learners = lrns(c("cmprsk.fg", "cmprsk.aalen"))

bm_grid = benchmark_grid(task, learners, rsmp("cv", folds = 3))
bm = benchmark(bm_grid)
bm$score()
```

``` R
##    nr task_id   learner_id resampling_id iteration       prediction_test
## 1:  1     pbc    cmprsk.fg            cv         1 <PredictionCompRisks>
## 2:  1     pbc    cmprsk.fg            cv         2 <PredictionCompRisks>
## 3:  1     pbc    cmprsk.fg            cv         3 <PredictionCompRisks>
## 4:  2     pbc cmprsk.aalen            cv         1 <PredictionCompRisks>
## 5:  2     pbc cmprsk.aalen            cv         2 <PredictionCompRisks>
## 6:  2     pbc cmprsk.aalen            cv         3 <PredictionCompRisks>
##    cmprsk.auc
## 1:  0.7989382
## 2:  0.7848370
## 3:  0.8665564
## 4:  0.5000000
## 5:  0.5000000
## 6:  0.5000000
## Hidden columns: uhash, task, learner, resampling
```

For more competing risk learners, see the [available
list](https://mlr3extralearners.mlr-org.com/reference/index.html#competing-risks-learners)
at `mlr3extralearners`.

## Code of Conduct

Please note that the mlr3cmprsk project is released with a [Contributor
Code of Conduct](https://mlr3cmprsk.mlr-org.com/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
