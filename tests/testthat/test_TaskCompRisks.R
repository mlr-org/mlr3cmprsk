test_that("TaskCompRisks methods work", {
  event = c(1, 0, 1, 0, 2, 2)
  times = c(1, 3, 2, 4, 4, 5)
  df = data.frame(time = times, event = event, x = runif(6))
  task = TaskCompRisks$new(id = "test", backend = df)

  expect_equal(task$task_type, "cmprsk")
  assert_integer(task$event(), len = 6, lower = 0, upper = 2)
  truth = task$truth()
  assert_class(truth, "Surv", null.ok = FALSE)
  expect_identical(truth[, 1L], df$time)
  expect_identical(truth[, 2L], df$event)
  states = attr(truth, "states") # the cause names
  expect_identical(states, c("Cause 1", "Cause 2"))
  # check that the cause names are preserved when subsetting the truth
  expect_identical(attr(task$truth(1:2), "states"), states)
  expect_identical(attr(task$truth(integer()), "states"), states)
  assert_formula(task$formula())
  assert_numeric(task$times(), len = 6)
  assert_numeric(task$unique_times(), len = 5)
  assert_numeric(task$unique_event_times(), len = 4)
  assert_class(task$aalen_johansen(), "survfit")
  expect_equal(task$cens_prop(), 2 / 6)
  expect_equal(task$n_causes, 2L)
  expect_equal(task$cause_names, c("1" = "Cause 1", "2" = "Cause 2"))
  expect_equal(task$causes, 1:2)
  # check that the event counts are correct and include all defined causes
  expected_tbl = data.table(
    cause = 0:2,
    name = c("Censored", "Cause 1", "Cause 2"),
    n = c(2L, 2L, 2L),
    prop = c(2, 2, 2) / 6
  )
  expect_equal(task$event_counts(), expected_tbl)
  # event counts filtering checks
  expect_equal(task$event_counts(c(1L, 6L))$n, c(0L, 1L, 1L))
  expect_identical(task$event_counts(integer())$n, integer(3L)) # all zero counts for all causes
  expect_true(all(is.nan(task$event_counts(integer())$prop))) # proportions are NaN when no events are present
  expect_error(task$event_counts(7L)) # invalid row index
  # unique event times filtering checks
  expect_equal(task$unique_event_times(cause = 1L), 1:2) # cause 1 in rows 1 and 3
  expect_equal(task$unique_event_times(rows = c(1, 5), cause = 1L), 1)
  expect_equal(task$unique_event_times(rows = 5L, cause = 1L), integer(0)) # cause 1 not present in row 5

  # doesn't work with factor event column
  df2 = data.frame(time = times, event = as.factor(event), x = runif(6))
  expect_error(TaskCompRisks$new(id = "test", backend = df2), "Must be of type")

  # filtering errors if fewer than two competing events are left
  expect_error(task$clone()$filter(1:3), class = "Mlr3ErrorInput") # events = 0 and 1 (no 2)
  expect_error(task$clone()$filter(4:6), class = "Mlr3ErrorInput") # events = 0 and 2 (no 1)
  expect_error(task$clone()$filter(c(2, 4)), class = "Mlr3ErrorInput") # only censored obs left

  # check that after task filtering the causes don't change and
  # the events are reported correctly
  task2 = task$clone()$filter(3:5) # both events are kept
  expect_equal(task2$event(), c(1, 0, 2))
  expect_equal(task2$causes, 1:2) # competing events don't change

  task3 = task$clone()$filter(c(3, 5)) # only events are kept (no censoring)
  expect_equal(task3$event(), c(1, 2))
  expect_equal(task3$causes, 1:2) # competing events don't change

  # at least two competing risks are needed upon construction
  df = data.frame(time = 1:2, event = c(0, 1), x = runif(2))
  expect_error(
    TaskCompRisks$new(id = "test", backend = df),
    regexp = "at least two causes"
  )

  # filtering issues a warning when the number of competing events is reduced but remains >= 2
  df = data.frame(time = 1:8, event = c(0, 1, 1, 2, 2, 3, 3, 0), x = runif(8))
  task = TaskCompRisks$new(id = "test", backend = df)
  expect_equal(task$causes, 1:3)
  expect_warning(task$filter(1:5), "competing events")
  # competing events reflect the original task, not the filtered one
  expect_equal(task$cause_names, c("1" = "Cause 1", "2" = "Cause 2", "3" = "Cause 3"))

  # creating a task with no censoring at all works!
  df = data.frame(time = 1:2, event = c(2, 1), x = runif(2))
  task = TaskCompRisks$new(id = "test", backend = df)
  expect_equal(task$causes, 1:2)
  expect_equal(task$cens_prop(), 0)

  # cause names checks
  for (invalid_cause_names in list(
    character(),
    "Death",
    c("Death", "Other", "Third"),
    c("Death", "Death"),
    c("Death", ""),
    c("Death", "  "),
    c("Death", NA_character_),
    1:2,
    c("2" = "Other cause", "1" = "Death")
  )) {
    expect_error(
      TaskCompRisks$new(id = "test", backend = task$data(), cause_names = invalid_cause_names),
      "cause_names"
    )
  }
})

test_that("construction works with any DataBackend", {
  task = tsk("pbc")
  task$select(c("age", "sex"))
  # `$cbind()` wraps the backend in a `DataBackendCbind`
  task$cbind(data.frame(extra = runif(task$nrow)))
  backend = task$backend
  expect_class(backend, "DataBackendCbind")

  task2 = TaskCompRisks$new(
    id = "cbind",
    backend = backend,
    time = "time",
    event = "status",
    cause_names = c("Liver transplantation", "Death without transplantation")
  )
  expect_task_cmprsk(task2)
  expect_equal(task2$causes, task$causes)
  expect_equal(task2$cause_names, task$cause_names)
  expect_equal(task2$event(), task$event())
  expect_true("extra" %in% task2$feature_names)
})

test_that("as_task_cmprsk", {
  # Inf values in the data frame are detected and a warning is issued
  expect_warning(
    {
      task = as_task_cmprsk(data.frame(time = c(1, 2), event = c(1, 2), x = c(Inf, -2)))
    },
    "Detected columns with unsupported Inf values in data: x",
    class = "Mlr3WarningInput",
    fixed = TRUE
  )
  expect_task_cmprsk(task)

  # events must be coded as 1, 2, ..., K (censoring (0) is not needed)
  expect_error(
    as_task_cmprsk(data.frame(time = c(1, 2, 3), event = c(1, 4, 2))),
    regexp = "Causes must be consecutive integers starting at 1",
    class = "Mlr3ErrorInput"
  )

  expect_task_cmprsk(
    as_task_cmprsk(data.frame(time = c(1, 2), status = c(1, 2)), event = "status")
  )

  expect_task_cmprsk(
    as_task_cmprsk(
      data.frame(t = c(1, 2, 3), s = c(0, 1, 2)),
      time = "t",
      event = "s",
      id = "test"
    )
  )

  # default id is derived from the input expression, also for multi-line expressions
  df = data.frame(time = c(1, 2), event = c(1, 2))
  expect_equal(as_task_cmprsk(df)$id, "df")
  expect_equal(as_task_cmprsk(as_data_backend(df))$id, "as_data_backend(df)")
  task = as_task_cmprsk(data.frame(
    time = c(1, 2),
    event = c(1, 2),
    a_long_feature_name_to_force_line_breaks = c(1, 2),
    another_long_feature_name_to_force_line_breaks = c(3, 4)
  ))
  expect_string(task$id)

  # Deep-cloning: changing one task, doesn't change the other
  t1 = tsk("pbc")
  t2 = as_task_cmprsk(t1, clone = TRUE)
  expect_task_cmprsk(t2)
  t1$select("edema")
  expect_false("sex" %in% names(t1$data()))
  expect_true("sex" %in% names(t2$data()))

  # Non-deep cloning: changing one task (t1), changes the other (t2)
  t1 = tsk("pbc")
  t2 = as_task_cmprsk(t1, clone = FALSE)
  expect_task_cmprsk(t2)
  t1$select("edema")
  expect_false("sex" %in% names(t1$data()))
  expect_false("sex" %in% names(t2$data()))
})

test_that("predefined competing risks tasks are registered and constructed", {
  dataset_ids = c("pbc", "hoel", "transplant", "mgus2")
  expect_true(all(mlr_tasks$has(keys = dataset_ids)))

  # pbc
  task = tsk("pbc")
  expect_task_cmprsk(task)
  expect_equal(task$causes, 1:2)
  expect_identical(
    task$cause_names,
    c("1" = "Liver transplantation", "2" = "Death without transplantation")
  )
  expect_true(all(task$times() > 0))
  expect_setequal(task$event(), 0:2)
  expect_equal(task$man, "mlr3cmprsk::mlr_tasks_pbc")

  # mgus2
  task = tsk("mgus2")
  expect_task_cmprsk(task)
  expect_equal(task$causes, 1:2)
  expect_identical(
    task$cause_names,
    c("1" = "Plasma cell malignancy", "2" = "Death without progression")
  )
  expect_true(all(task$times() > 0))
  expect_setequal(task$event(), 0:2)
  expect_equal(task$man, "mlr3cmprsk::mlr_tasks_mgus2")

  # transplant
  task = tsk("transplant")
  expect_task_cmprsk(task)
  expect_equal(task$causes, 1:3)
  expect_identical(
    task$cause_names,
    c("1" = "Death", "2" = "Liver transplantation", "3" = "Withdrawal")
  )
  expect_true(all(task$times() > 0))
  expect_setequal(task$event(), 0:3)
  expect_equal(task$man, "mlr3cmprsk::mlr_tasks_transplant")

  # hoel
  task = tsk("hoel")
  expect_task_cmprsk(task)
  expect_equal(task$causes, 1:3)
  expect_identical(
    task$cause_names,
    c("1" = "Thymic lymphoma", "2" = "Reticulum cell sarcoma", "3" = "Other causes")
  )
  expect_true(all(task$times() > 0))
  expect_setequal(task$event(), 1:3)
  expect_equal(task$man, "mlr3cmprsk::mlr_tasks_hoel")
})
