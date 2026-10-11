<%
is_ibs = measure_id == "cmprsk.ibs"
score_name = switch(measure_id, "cmprsk.auc" = "AUC", "cmprsk.brier" = "Brier score", "cmprsk.ibs" = "IBS")
default_time = if (is_ibs) {
  "over 100 equally spaced points from 0 to the 90th test-set follow-up percentile"
} else {
  "at the median observed test-set time"
}
time_arg = if (is_ibs) "times = times" else "time = 100"
time_label = if (is_ibs) "from 0 to 100 months on a 5-month grid" else "at 100 months"
%>
#' @examples
#' # <%= score_name %> <%= default_time %>, weighted by event frequencies
#' predictions$score(msr("<%= measure_id %>"))
#'
<% if (is_ibs) { %>
#' # IBS with an upper integration horizon of 100 months
#' predictions$score(msr("<%= measure_id %>", t_max = 100))
#'
#' # IBS up to the 80th percentile of test-set follow-up times
#' predictions$score(msr("<%= measure_id %>", t_quantile = 0.8))
#'
#' # IBS over 20 equally spaced points up to the default 90th percentile
#' predictions$score(msr("<%= measure_id %>", ntimes = 20L))
#'
#' # Define the integration grid in months
#' times = seq(0, 100, by = 5)
#'
<% } %>
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
