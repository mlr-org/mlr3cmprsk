#' @title Convert to a Competing Risk Prediction
#'
#' @description
#' Convert object to a [PredictionCompRisks].
#'
#' @details
#' If `x` is a `data.frame`/`data.table` input, the following requirements must be met:
#' - Cols `row_ids`, `time`, `event`, and a list-column `CIF` must be present.
#' - The per-observation `CIF` object must be a named list of numeric vectors
#' (one per cause), with names exactly `"1"`, `"2"`, ..., `"K"`, in that order
#' (where `K` is the number of competing risks).
#' - Cause names should be identical across observations and in the same order;
#' CIF vectors corresponding to the same cause should be of equal length (same time points).
#' - Values for the `event` column must be 0 (censoring) or one of the consecutive
#' cause codes 1, 2, ..., K.
#'
#' @inheritParams mlr3::as_prediction
#'
#' @return [PredictionCompRisks].
#' @export
#' @examples
#' library(mlr3)
#' task = tsk("pbc")
#' learner = lrn("cmprsk.aalen")
#' learner$train(task)
#' p = learner$predict(task)
#'
#' # convert to a data.table
#' tab = as.data.table(p)
#'
#' # convert back to a Prediction
#' as_prediction_cmprsk(tab)
as_prediction_cmprsk = function(x, ...) {
  UseMethod("as_prediction_cmprsk")
}

#' @rdname as_prediction_cmprsk
#' @export
as_prediction_cmprsk.PredictionCompRisks = function(x, ...) {
  x
}

#' @rdname as_prediction_cmprsk
#' @export
as_prediction_cmprsk.data.frame = function(x, ...) {
  mandatory = c("row_ids", "time", "event")
  optional = c("CIF")
  assert_names(names(x), must.include = mandatory, subset.of = c(mandatory, optional))

  cmp_event_ids = unique(unlist(lapply(x$CIF, names)))
  # Check that the cause names are exactly "1", "2", ..., "K" in that order
  assert_names(cmp_event_ids, identical.to = as.character(seq_along(cmp_event_ids)))
  # Check that each observation's CIF list has the same cause names
  for (obs_cif in x$CIF) {
    assert_names(names(obs_cif), identical.to = cmp_event_ids)
  }
  # Check that the event column contains only 0 (censoring) or one of the cause codes
  assert_integerish(x$event, lower = 0L, upper = length(cmp_event_ids), any.missing = FALSE)

  # Reconstruct the list of CIF matrices (one per cause)
  cif = if ("CIF" %in% names(x)) {
    mat_list = lapply(cmp_event_ids, function(event_id) {
      do.call(rbind, lapply(x$CIF, function(obs_cif) obs_cif[[event_id]]))
    })
    set_names(mat_list, cmp_event_ids)
  } else {
    NULL
  }

  # we need to convert here, because if `x` is a data.frame, `with = FALSE` below does not work!
  setDT(x)
  x_subset = x[, setdiff(names(x), c("time", "event", "CIF")), with = FALSE]

  invoke(
    PredictionCompRisks$new,
    truth = Surv(x$time, factor(x$event, levels = c("0", cmp_event_ids))),
    cif = cif,
    .args = x_subset
  )
}
