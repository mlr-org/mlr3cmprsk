# Primary Biliary Cholangitis Competing Risks Task

A competing risks task for the
[pbc](https://rdrr.io/pkg/survival/man/pbc.html) data set.

## Format

[R6::R6Class](https://r6.r-lib.org/reference/R6Class.html) inheriting
from
[TaskCompRisks](https://mlr3cmprsk.mlr-org.com/reference/TaskCompRisks.md).

## Dictionary

This [Task](https://mlr3.mlr-org.com/reference/Task.html) can be
instantiated via the
[dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
[mlr_tasks](https://mlr3.mlr-org.com/reference/mlr_tasks.html) or with
the associated sugar function
[tsk()](https://mlr3.mlr-org.com/reference/mlr_sugar.html):

    mlr_tasks$get("pbc")
    tsk("pbc")

## Meta Information

- Task type: “cmprsk”

- Dimensions: 276x19

- Properties: -

- Has Missings: `FALSE`

- Target: “time”, “status”

- Features: “age”, “albumin”, “alk.phos”, “ascites”, “ast”, “bili”,
  “chol”, “copper”, “edema”, “hepato”, “platelet”, “protime”, “sex”,
  “spiders”, “stage”, “trig”, “trt”

## Competing risks scenario

Patients with primary biliary cholangitis are followed until liver
transplantation (cause 1), death without prior transplantation (cause
2), or censoring (0). Transplantation and death before transplantation
are mutually exclusive first events. This analysis reduces a potentially
more complex multi-state process to its first event: patients may die
after transplantation, but subsequent deaths are not considered.

## Pre-processing

- Removed column `id`.

- Kept only complete cases (no missing values).

- Column `age` has been converted to `integer`.

- Columns `trt`, `stage`, `hepato`, `edema` and `ascites` have been
  converted to `factor`s.

- Column `trt` has levels `Dpenicillmain` and `placebo` instead of 1 and
  2.

- Column `status` has 0 for censored, 1 for transplant and 2 for death.

## See also

- Chapter in the [mlr3book](https://mlr3book.mlr-org.com/):
  <https://mlr3book.mlr-org.com/chapters/chapter2/data_and_basic_modeling.html>

- [Dictionary](https://mlr3misc.mlr-org.com/reference/Dictionary.html)
  of [Tasks](https://mlr3.mlr-org.com/reference/Task.html):
  [mlr3::mlr_tasks](https://mlr3.mlr-org.com/reference/mlr_tasks.html)

- `as.data.table(mlr_tasks)` for a table of available
  [Tasks](https://mlr3.mlr-org.com/reference/Task.html) in the running
  session

Other Task:
[`TaskCompRisks`](https://mlr3cmprsk.mlr-org.com/reference/TaskCompRisks.md),
[`mlr_tasks_hoel`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_hoel.md),
[`mlr_tasks_mgus2`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_mgus2.md),
[`mlr_tasks_transplant`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_transplant.md)
