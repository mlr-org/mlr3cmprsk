# Here we define some mlr3-mandatory S3 methods of the `PredictionDataSurv` object

#' @export
as_prediction.PredictionDataCompRisks = function(x, check = TRUE, ...) {
  invoke(PredictionCompRisks$new, check = check, .args = x)
}

#' @export
check_prediction_data.PredictionDataCompRisks = function(pdata, ...) {
  n_obs = length(assert_row_ids(pdata$row_ids))
  if (n_obs > 0) {
    assert_surv(pdata$truth, len = n_obs)

    causes = attr(pdata$truth, "states")
    assert_cif_list(pdata$cif, n_rows = n_obs, causes = causes)

    # Joint coherence between CIFs is desirable but not required
    # Independently fitted cause-specific models (e.g. Fine-Gray)
    # can produce CIFs whose sum exceeds 1.
    aligned_cifs = align_cifs(pdata$cif, bind_rows = FALSE)
    cif_sum = Reduce(`+`, aligned_cifs)
    tol = sqrt(.Machine$double.eps)

    if (any(cif_sum > 1 + tol)) {
      warning_mlr3(
        "Predicted cause-specific CIFs are not jointly coherent: their sum
        exceeds 1 for some observations/time points.",
        class = "Mlr3WarningCIFSumExceedsOne"
      )
    }
  }

  pdata
}

#' @export
is_missing_prediction_data.PredictionDataCompRisks = function(pdata, ...) {
  miss = logical(length(pdata$row_ids))

  # no missing values allowed in CIF list of matrices, see `assert_cif_list()`
  pdata$row_ids[miss]
}

#' @export
c.PredictionDataCompRisks = function(..., keep_duplicates = TRUE) {
  dots = list(...)
  assert_list(dots, types = "PredictionDataCompRisks")
  assert_flag(keep_duplicates)
  if (length(dots) == 1L) {
    return(dots[[1L]])
  }

  predict_types = names(mlr_reflections$learner_predict_types$cmprsk)
  predict_types = map(dots, function(x) intersect(names(x), predict_types))
  if (!every(predict_types[-1L], setequal, y = predict_types[[1L]])) {
    error_input("Cannot combine predictions: Different prediction types")
  }

  predict_types = predict_types[[1L]]
  row_ids = do.call(c, map(dots, "row_ids"))
  # row ids to keep (default => all)
  ii = if (keep_duplicates) seq_along(row_ids) else which(!duplicated(row_ids, fromLast = TRUE))

  # combine `truth` and `row_ids` (easy to combine via `c`)
  elems = c("row_ids", "truth")
  result = named_list(elems)
  result$row_ids = row_ids[ii]
  for (elem in elems) {
    result[[elem]] = do.call(c, map(dots, elem))[ii]
  }

  # combine CIFs (list of matrices) for each cause
  if ("cif" %in% predict_types) {
    # Extract list of CIF lists
    cif_lists = map(dots, "cif")

    # Check that all CIF lists have the same causes (names)
    causes = as.character(seq_along(cif_lists[[1L]]))
    for (cif_list in cif_lists) {
      assert_names(names(cif_list), identical.to = causes)
    }

    # Combine CIFs for each cause and align them on a common time grid
    merged_cifs = named_list(causes)
    for (cause in causes) {
      cs_cifs = map(cif_lists, function(cif_list) cif_list[[cause]])
      merged_cifs[[cause]] = align_cifs(cs_cifs, bind_rows = TRUE)[ii, , drop = FALSE]
    }
    result$cif = merged_cifs
  }

  set_class(result, "PredictionDataCompRisks")
}

#' @export
filter_prediction_data.PredictionDataCompRisks = function(pdata, row_ids, ...) {
  keep = pdata$row_ids %in% row_ids
  pdata$row_ids = pdata$row_ids[keep]
  pdata$truth = pdata$truth[keep]

  if (!is.null(pdata$cif)) {
    # simply keep the observations (rows) in each CIF matrix
    pdata$cif = lapply(pdata$cif, function(mat) mat[keep, , drop = FALSE])
  }

  pdata
}
