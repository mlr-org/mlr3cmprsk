#' @title Convert to a Competing Risk Prediction
#'
#' @description
#' Convert object to a [PredictionCompRisks].
#' An existing [PredictionCompRisks] is returned unchanged.
#' Use [mlr3::as_prediction()] to convert its internal `PredictionDataCompRisks` data.
#'
#' @details
#' A named `list` must contain `row_ids`, `truth`, and `cif`.
#' These elements are passed to the [PredictionCompRisks] constructor and
#' validated there (using `check = TRUE` by default).
#' The `cif` element must be a nonempty list of matrices, with one matrix for every task cause.
#' This requirement also applies to internal prediction data.
#'
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
#' # from an existing prediction
#' as_prediction_cmprsk(p)
#'
#' # convert a named list
#' as_prediction_cmprsk(list(row_ids = p$row_ids, truth = p$truth, cif = p$cif))
#'
#' # from a data.frame
#' tab = as.data.frame(as.data.table(p))
#' as_prediction_cmprsk(tab)
#'
#' # from internal prediction data
#' as_prediction(p$data, check = TRUE)
as_prediction_cmprsk = function(x, ...) {
  UseMethod("as_prediction_cmprsk")
}

#' @rdname as_prediction_cmprsk
#' @export
as_prediction_cmprsk.PredictionCompRisks = function(x, ...) {
  assert_list(x$cif, types = "matrix", min.len = 2L)
  x
}

#' @rdname as_prediction_cmprsk
#' @export
as_prediction_cmprsk.list = function(x, ...) {
  assert_names(
    names(x),
    must.include = c("row_ids", "truth", "cif"),
    subset.of = c("row_ids", "truth", "cif")
  )

  invoke(
    PredictionCompRisks$new,
    .args = x
  )
}

#' @rdname as_prediction_cmprsk
#' @export
as_prediction_cmprsk.data.frame = function(x, ...) {
  mandatory = c("row_ids", "time", "event", "CIF")
  assert_names(names(x), must.include = mandatory, subset.of = mandatory)
  assert_list(x$CIF, min.len = 1L)

  cmp_event_ids = unique(unlist(lapply(x$CIF, names)))
  # Check that the cause names are exactly "1", "2", ..., "K" in that order
  assert_names(cmp_event_ids, identical.to = as.character(seq_along(cmp_event_ids)))
  # Check that each observation's CIF list has the same cause names
  for (obs_cif in x$CIF) {
    assert_list(obs_cif, min.len = 2L)
    assert_names(names(obs_cif), identical.to = cmp_event_ids)
  }
  # Check that the event column contains only 0 (censoring) or one of the cause codes
  assert_integerish(x$event, lower = 0L, upper = length(cmp_event_ids), any.missing = FALSE)

  # Reconstruct the list of CIF matrices (one per cause)
  mat_list = lapply(cmp_event_ids, function(event_id) {
    do.call(rbind, lapply(x$CIF, function(obs_cif) obs_cif[[event_id]]))
  })
  cif = set_names(mat_list, cmp_event_ids)

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
