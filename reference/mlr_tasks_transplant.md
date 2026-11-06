# Liver Transplant Waiting List Competing Risks Task

A competing risks task for the
[transplant](https://rdrr.io/pkg/survival/man/transplant.html) data set.

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

    mlr_tasks$get("transplant")
    tsk("transplant")

## Meta Information

- Task type: “cmprsk”

- Dimensions: 793x6

- Properties: -

- Has Missings: `FALSE`

- Target: “time”, “event”

- Features: “abo”, “age”, “sex”, “year”

## Competing risks scenario

The competing events are mutually exclusive exit-events from the liver
transplant waiting list: death (cause 1), liver transplantation (cause
2), or withdrawal (cause 3), with 0 indicating censoring. This analysis
reduces a potentially more complex multi-state process to the first
outcome that happens to patients on the waiting list. Patients may die
after transplantation or withdrawal, but subsequent events are not
considered.

## Pre-processing

- Kept only complete cases (no missing values).

- Removed four observations with zero follow-up time.

- Renamed `futime` to `time`, preserving the original values in days.

- Retained numeric predictors `age` and `year` and the existing factors
  `sex` and `abo`, without conversion.

- Replaced the factor `event` with integer codes using its labels:
  `censored` = 0, `death` = 1, `ltx` = 2 (liver transplantation), and
  `withdraw` = 3.

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
[`mlr_tasks_pbc`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_pbc.md)
