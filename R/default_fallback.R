default_fallback = function(learner, ...) {
  UseMethod("default_fallback")
}

#' @export
default_fallback.LearnerCompRisks = function(learner, ...) {
  fallback = lrn("cmprsk.aalen")

  # set predict type
  if (learner$predict_type %nin% fallback$predict_types) {
    stopf("Fallback learner '%s' does not support predict type '%s'.", fallback$id, learner$predict_type)
  }

  fallback$predict_type = learner$predict_type

  return(fallback)
}
