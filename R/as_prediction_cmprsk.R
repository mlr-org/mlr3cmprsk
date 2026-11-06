#' @title Convert to a Competing Risk Prediction
#'
#' @description
#' Convert object to a [PredictionCompRisks].
#' An existing [PredictionCompRisks] is returned unchanged.
#' See Details for requirements on `list` and `data.frame` inputs.
#'
#' Use [mlr3::as_prediction()] to convert the internal `PredictionDataCompRisks` data to a [PredictionCompRisks] object.
#'
#' @details
#' If `x` is a named `list`, it must contain `row_ids`, `truth`, and `cif`.
#' The `weights` and `extra` elements are optional.
#' Descriptive cause names are taken from the `states` attribute of `truth`.
#' These elements are passed to the [PredictionCompRisks] constructor and
#' validated there (using `check = TRUE` by default).
#' The `cif` element must be a nonempty list of matrices, with one matrix for
#' each competing cause.
#' This requirement also applies to the internal prediction data of `PredictionDataCompRisks` class.
#'
#' If `x` is a `data.frame`/`data.table` input, the following requirements must be met:
#' - Columns `row_ids`, `time`, `event`, and a list-column `CIF` must be present.
#' - An optional column `weights` may hold measurement weights.
#' - An optional `cause_names` attribute may hold descriptive cause names.
#' - All other columns are stored as `extra` data. Column names must be unique.
#' - The per-observation `CIF` object must be a named list of numeric vectors
#' (one per cause), with names exactly `"1"`, `"2"`, ..., `"K"`, in that order
#' (where `K` is the number of competing risks).
#' - Cause codes must be identical across observations and in the same order.
#' - CIF vectors corresponding to the same cause must have the same length and the same time names
#' (the names of the vectors) across all observations.
#' - Values for the `event` column must be 0 (censoring) or one of the consecutive
#' cause codes `"1"`, `"2"`, ..., `"K"`.
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
#' # from an existing PredictionCompRisks object (no change)
#' as_prediction_cmprsk(p)
#'
#' # Convert a named list to a PredictionCompRisks object
#' # The list must contain `row_ids`, `truth`, and `cif` elements
#' p_list = list(
#'   row_ids = p$row_ids,
#'   truth = p$truth,
#'   cif = p$cif
#' )
#' as_prediction_cmprsk(p_list)
#'
#' # Convert a data.frame to a PredictionCompRisks object
#' # The data.frame must contain the required columns: row_ids, time, event, and CIF
#' tab = as.data.frame(as.data.table(p))
#' as_prediction_cmprsk(tab)
#'
#' # Convert internal prediction data using as_prediction()
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
    must.include = c("row_ids", "truth", "cif"),
    subset.of = c("row_ids", "truth", "cif", "weights", "extra")
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
  reserved = c(mandatory, "weights")
  assert_names(names(x), type = "unique", must.include = mandatory)
  assert_list(x$CIF, min.len = 1L)

  causes = unique(unlist(lapply(x$CIF, names)))
  # Check that the cause codes are exactly "1", "2", ..., "K" in that order
  assert_names(causes, identical.to = as.character(seq_along(causes)))
  # Check that each observation's CIF list has the same cause codes
  for (obs_cif in x$CIF) {
    assert_list(obs_cif, min.len = 2L)
    assert_names(names(obs_cif), identical.to = causes)
  }
  # Check that the event column contains only 0 (censoring) or one of the cause codes
  assert_integerish(x$event, lower = 0L, upper = length(causes), any.missing = FALSE)

  # Reconstruct the list of CIF matrices (one per cause)
  mat_list = lapply(causes, function(cause) {
    cif_vectors = lapply(x$CIF, function(obs_cif) obs_cif[[cause]])
    # `rbind()` silently recycles shorter vectors, so check lengths and time names first
    times = names(cif_vectors[[1L]])
    for (cif_vector in cif_vectors) {
      if (length(cif_vector) != length(times) || !identical(names(cif_vector), times)) {
        error_input(
          "CIF vectors for cause '%s' must have the same length and time names across all observations",
          cause
        )
      }
    }
    do.call(rbind, cif_vectors)
  })
  cif = set_names(mat_list, causes)

  # convert a copy, so that a data.frame passed by the caller is not modified by reference
  x = as.data.table(x)
  extra_cols = setdiff(names(x), reserved)
  extra = if (length(extra_cols)) {
    set_names(map(extra_cols, function(col) x[[col]]), extra_cols)
  } else {
    NULL
  }
  x_subset = x[, intersect(names(x), c("row_ids", "weights")), with = FALSE]

  cause_names = assert_cause_names(unname(attr(x, "cause_names", exact = TRUE)), causes)
  truth = Surv(
    x$time,
    factor(x$event, levels = c("0", causes), labels = c("Censored", cause_names))
  )

  invoke(
    PredictionCompRisks$new,
    truth = truth,
    cif = cif,
    extra = extra,
    .args = x_subset
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
    .args = x
  )
}
