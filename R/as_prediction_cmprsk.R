#' @title Convert to a Competing Risk Prediction
#'
#' @description
#' Convert object to a [PredictionCompRisks].
#' An existing [PredictionCompRisks] is returned unchanged.
#' See Details for requirements on named `list` inputs.
#'
#' Use [mlr3::as_prediction()] to convert the internal `PredictionDataCompRisks` data to a [PredictionCompRisks] object.
#'
#' @details
#' If `x` is a named `list`, it must meet the following requirements:
#' - Include `row_ids`, `truth`, `cif`, and `times` elements; `weights` and `extra` are optional.
#' - Provide `truth` as a [survival::Surv()] object; descriptive cause names are taken from its `states` attribute.
#' - Provide `cif` as a list of CIF matrices, one per cause, named with consecutive cause codes (`"1"`, `"2"`, ..., `"K"`).
#' - Provide `times` as a list of time point vectors, one per cause.
#' - Ensure the cause names and order in `times` match those in `cif`.
#'   For each cause, its time vector must contain one time point per column of the
#'   corresponding CIF matrix.
#'   Different causes may have different time grids.
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
#' # PredictionCompRisks => PredictionCompRisks (no change)
#' as_prediction_cmprsk(p)
#'
#' # list => PredictionCompRisks
#' p_list = list(
#'   row_ids = p$row_ids,
#'   truth = p$truth,
#'   cif = p$cif,
#'   times = p$times # supply the time grids per cause
#' )
#' as_prediction_cmprsk(p_list)
#'
#' # PredictionDataCompRisks => PredictionCompRisks (using as_prediction())
#' p$data
#' as_prediction(p$data)
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
as_prediction_cmprsk.list = function(x, ...) {
  assert_names(
    names(x),
    must.include = c("row_ids", "truth", "cif", "times"),
    subset.of = c("row_ids", "truth", "cif", "times", "weights", "extra")
  )

  invoke(
    PredictionCompRisks$new,
    .args = x
  )
}

#' @rdname as_prediction_cmprsk
#' @param check (`logical(1)`)\cr
#'   Whether to validate internal `PredictionDataCompRisks` data during conversion with [mlr3::as_prediction()].
#'   Use `TRUE` for user-supplied data; `FALSE` is intended for already validated internal data.
#'   With `FALSE`, correct behavior is not guaranteed if the input is invalid.
#' @export
as_prediction.PredictionDataCompRisks = function(x, check = FALSE, ...) {
  invoke(
    PredictionCompRisks$new,
    check = check,
    times = attr(x, "times", exact = TRUE),
    .args = x
  )
}
