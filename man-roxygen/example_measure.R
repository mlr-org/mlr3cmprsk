<%
is_ibs = measure_id == "cmprsk.ibs"
score_name = switch(measure_id, "cmprsk.auc" = "AUC", "cmprsk.brier" = "Brier score", "cmprsk.ibs" = "IBS")
default_time = if (is_ibs) "over all unique observed test-set times" else "at the median observed test-set time"
time_arg = if (is_ibs) "times = seq(0, 100, by = 5)" else "time = 100"
time_label = if (is_ibs) "from 0 to 100 months on a 5-month grid" else "at 100 months"
%>
#' @examples
#' # <%= score_name %> <%= default_time %>, weighted by event frequencies
#' predictions$score(msr("<%= measure_id %>"))
#'
#' # <%= score_name %> <%= time_label %>, weighted by event frequencies
#' predictions$score(msr("<%= measure_id %>", <%= time_arg %>))
#'
#' # <%= score_name %> <%= time_label %>, with equal weights for both causes
#' predictions$score(msr("<%= measure_id %>", <%= time_arg %>, cause_weights = c(0.5, 0.5)))
#'
#' # <%= score_name %> <%= time_label %>, with custom weights for transplant and death
#' predictions$score(msr("<%= measure_id %>", <%= time_arg %>, cause_weights = c(0.2, 0.8)))
#'
#' # <%= score_name %> <%= time_label %>, for transplant only
#' predictions$score(msr("<%= measure_id %>", <%= time_arg %>, cause = 1))
#'
#' # <%= score_name %> <%= time_label %>, for death only
#' predictions$score(msr("<%= measure_id %>", <%= time_arg %>, cause = 2))
