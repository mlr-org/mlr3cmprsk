# Mouse Cancer Competing Risks Task

A competing risks task for the
[hoel](https://rdrr.io/pkg/survival/man/hoel.html) data set.

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

    mlr_tasks$get("hoel")
    tsk("hoel")

## Meta Information

- Task type: “cmprsk”

- Dimensions: 181x3

- Properties: -

- Has Missings: `FALSE`

- Target: “time”, “event”

- Features: “trt”

## Competing risks scenario

Death is the terminal event, classified as thymic lymphoma (cause 1),
reticulum cell sarcoma (cause 2), or other causes of death (cause 3).
This is a classical competing risks setting where the recorded causes of
death are mutually exclusive.

## Pre-processing

- Removed `id` and retained `trt` as the only feature, preserving its
  factor levels `Control` and `Germ-free` without conversion.

- Renamed `days` to `time`, preserving the original values in days.

- Replaced `outcome` with integer `event` using the original factor
  labels: `censor` = 0, `thymic lymphoma` = 1, `reticulum cell sarcoma`
  = 2, and `other` = 3. Code 0 does not occur in these data.

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
[`mlr_tasks_mgus2`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_mgus2.md),
[`mlr_tasks_pbc`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_pbc.md),
[`mlr_tasks_transplant`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_transplant.md)
