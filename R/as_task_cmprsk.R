#' @title Convert to a Competing Risks Task
#'
#' @description
#' Convert object to a competing risks task ([TaskCompRisks]).
#'
#' @param x (`any`)\cr
#'   Object to convert, e.g. a `data.frame()`.
#' @param ... (`any`)\cr
#'   Additional arguments.
#' @return [TaskCompRisks].
#' @export
as_task_cmprsk = function(x, ...) {
  UseMethod("as_task_cmprsk")
}

#' @rdname as_task_cmprsk
#' @param clone (`logical(1)`)\cr
#'   If `TRUE`, ensures that the returned object is not the same as the input `x`.
#' @export
as_task_cmprsk.TaskCompRisks = function(x, clone = FALSE, ...) {
  assert_flag(clone)
  if (clone) x$clone() else x
}

#' @rdname as_task_cmprsk
#' @template param_time
#' @template param_event
#' @template param_cause_names
#' @param id (`character(1)`)\cr
#'   Id for the new task.
#'   Defaults to the (deparsed and substituted) name of `x`.
#' @export
as_task_cmprsk.data.frame = function(
  x,
  time = "time",
  event = "event",
  id = deparse1(substitute(x)),
  cause_names = NULL,
  ...
) {
  force(id)

  assert_data_frame(x, min.rows = 1L, min.cols = 2L, col.names = "unique")

  ii = which(map_lgl(keep(x, is.double), anyInfinite))
  if (length(ii)) {
    warning_input(
      "Detected columns with unsupported Inf values in data: %s",
      str_collapse(names(ii))
    )
  }

  TaskCompRisks$new(
    id = id,
    backend = x,
    time = time,
    event = event,
    cause_names = cause_names,
    ...
  )
}

#' @rdname as_task_cmprsk
#' @export
as_task_cmprsk.DataBackend = function(
  x,
  time = "time",
  event = "event",
  id = deparse1(substitute(x)),
  cause_names = NULL,
  ...
) {
  force(id)

  TaskCompRisks$new(
    id = id,
    backend = x,
    time = time,
    event = event,
    cause_names = cause_names,
    ...
  )
}
