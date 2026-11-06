# Monoclonal Gammopathy Competing Risks Task

A competing risks task for the
[mgus2](https://rdrr.io/pkg/survival/man/mgus2.html) data set.

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

    mlr_tasks$get("mgus2")
    tsk("mgus2")

## Meta Information

- Task type: “cmprsk”

- Dimensions: 1338x8

- Properties: -

- Has Missings: `FALSE`

- Target: “time”, “event”

- Features: “age”, “creat”, “dxyr”, “hgb”, “mspike”, “sex”

## Competing risks scenario

The competing events are progression to plasma cell malignancy (PCM,
cause 1) and death without prior progression (cause 2), with 0
indicating censoring. The original data describe a multi-state process
in which patients can progress and subsequently die. This task focuses
only on the occurrence of the first event, reducing the multi-state
process to the competing risks setting, such that progression and death
with no prior progression are mutually exclusive events.

## Pre-processing

- Kept only complete cases (no missing values).

- Constructed `time = ifelse(pstat == 1, ptime, futime)`, preserving the
  original time units in months.

- Constructed integer `event`: 1 for progression (`pstat == 1`), 2 for
  death without prior progression (`pstat == 0` and `death == 1`), and 0
  for censoring (`pstat == 0` and `death == 0`). Note that 9 subjects
  have progression and death recorded in the same month; these are
  classified as progression (cause 1).

- Removed `id` and the original outcome columns `ptime`, `pstat`,
  `futime`, and `death`.

- Retained features `age`, `sex`, `dxyr`, `hgb`, `creat`, and `mspike`.
  Kept `sex` as its original factor and the other predictors numeric,
  without conversion.

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
[`mlr_tasks_pbc`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_pbc.md),
[`mlr_tasks_transplant`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_transplant.md)
