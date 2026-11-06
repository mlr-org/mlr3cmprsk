# Competing Risks Task

This task extends
[mlr3::Task](https://mlr3.mlr-org.com/reference/Task.html) and
[mlr3::TaskSupervised](https://mlr3.mlr-org.com/reference/TaskSupervised.html)
for competing risks survival analysis. The target outcome consists of a
survival time and an event indicator. Event codes must be non-negative
integers in \\(0, 1, 2, ..., K)\\. \\0\\ denotes censoring, and positive
integers denote distinct event causes. Each row represents one
observation.

Predefined tasks are stored in
[mlr3::mlr_tasks](https://mlr3.mlr-org.com/reference/mlr_tasks.html).

The `task_type` is set to `"cmprsk"`.

## Details

The following design choices apply to this task:

- Only **right-censoring** is currently supported.

- Tasks must contain at **least two event causes**, i.e., \\K \geq 2\\,
  encoded as consecutive integers \\1, 2, ..., K\\.

It is advised to use **stratified resampling** to reduce the risk of
creating training splits with fewer than two causes, which may cause
issues during model training (and later prediction). Task filtering
specifically issues a warning when the number of competing events is
reduced but remains \>= 2, and an error if fewer than two causes remain.

## See also

Other Task:
[`mlr_tasks_hoel`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_hoel.md),
[`mlr_tasks_mgus2`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_mgus2.md),
[`mlr_tasks_pbc`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_pbc.md),
[`mlr_tasks_transplant`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_transplant.md)

## Super classes

[`mlr3::Task`](https://mlr3.mlr-org.com/reference/Task.html) -\>
[`mlr3::TaskSupervised`](https://mlr3.mlr-org.com/reference/TaskSupervised.html)
-\> `TaskCompRisks`

## Active bindings

- `cens_type`:

  (`character(1)`)  
  Returns the type of censoring. Currently, only `"right"` censoring
  type is supported.

- `causes`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Read-only cause codes `1, 2, ..., K`, including causes absent from the
  active rows.

- `n_causes`:

  (`integer(1)`)  
  Read-only number of defined causes, excluding censoring.

- `cause_names`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Named vector with read-only descriptive names of the competing events.
  Names are the codes `1, 2, ..., K`. All causes are included, even
  those absent from the task's active rows.

## Methods

### Public methods

- [`TaskCompRisks$new()`](#method-TaskCompRisks-initialize)

- [`TaskCompRisks$print()`](#method-TaskCompRisks-print)

- [`TaskCompRisks$truth()`](#method-TaskCompRisks-truth)

- [`TaskCompRisks$formula()`](#method-TaskCompRisks-formula)

- [`TaskCompRisks$times()`](#method-TaskCompRisks-times)

- [`TaskCompRisks$event()`](#method-TaskCompRisks-event)

- [`TaskCompRisks$unique_times()`](#method-TaskCompRisks-unique_times)

- [`TaskCompRisks$unique_event_times()`](#method-TaskCompRisks-unique_event_times)

- [`TaskCompRisks$aalen_johansen()`](#method-TaskCompRisks-aalen_johansen)

- [`TaskCompRisks$event_counts()`](#method-TaskCompRisks-event_counts)

- [`TaskCompRisks$cens_prop()`](#method-TaskCompRisks-cens_prop)

- [`TaskCompRisks$filter()`](#method-TaskCompRisks-filter)

- [`TaskCompRisks$clone()`](#method-TaskCompRisks-clone)

Inherited methods

- [`mlr3::Task$add_strata()`](https://mlr3.mlr-org.com/reference/Task.html#method-add_strata)
- [`mlr3::Task$cbind()`](https://mlr3.mlr-org.com/reference/Task.html#method-cbind)
- [`mlr3::Task$data()`](https://mlr3.mlr-org.com/reference/Task.html#method-data)
- [`mlr3::Task$droplevels()`](https://mlr3.mlr-org.com/reference/Task.html#method-droplevels)
- [`mlr3::Task$format()`](https://mlr3.mlr-org.com/reference/Task.html#method-format)
- [`mlr3::Task$head()`](https://mlr3.mlr-org.com/reference/Task.html#method-head)
- [`mlr3::Task$help()`](https://mlr3.mlr-org.com/reference/Task.html#method-help)
- [`mlr3::Task$levels()`](https://mlr3.mlr-org.com/reference/Task.html#method-levels)
- [`mlr3::Task$materialize_view()`](https://mlr3.mlr-org.com/reference/Task.html#method-materialize_view)
- [`mlr3::Task$missings()`](https://mlr3.mlr-org.com/reference/Task.html#method-missings)
- [`mlr3::Task$rbind()`](https://mlr3.mlr-org.com/reference/Task.html#method-rbind)
- [`mlr3::Task$rename()`](https://mlr3.mlr-org.com/reference/Task.html#method-rename)
- [`mlr3::Task$select()`](https://mlr3.mlr-org.com/reference/Task.html#method-select)
- [`mlr3::Task$set_col_roles()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_col_roles)
- [`mlr3::Task$set_levels()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_levels)
- [`mlr3::Task$set_row_roles()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_row_roles)

------------------------------------------------------------------------

### `TaskCompRisks$new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    TaskCompRisks$new(
      id,
      backend,
      time = "time",
      event = "event",
      label = NA_character_,
      cause_names = NULL
    )

#### Arguments

- `id`:

  (`character(1)`)  
  Identifier for the new instance.

- `backend`:

  ([mlr3::DataBackend](https://mlr3.mlr-org.com/reference/DataBackend.html))  
  Either a
  [DataBackend](https://mlr3.mlr-org.com/reference/DataBackend.html), or
  any object which is convertible to a
  [DataBackend](https://mlr3.mlr-org.com/reference/DataBackend.html)
  with
  [`as_data_backend()`](https://mlr3.mlr-org.com/reference/as_data_backend.html).
  E.g., a [`data.frame()`](https://rdrr.io/r/base/data.frame.html) will
  be converted to a
  [DataBackendDataTable](https://mlr3.mlr-org.com/reference/DataBackendDataTable.html).

- `time`:

  (`character(1)`)  
  Name of the column for outcome time.

- `event`:

  (`character(1)`)  
  Name of column that holds the event indicator. \\0\\ corresponds to
  censoring, values \\\> 0\\ correspond to different competing events
  (or causes).

- `label`:

  (`character(1)`)  
  Label for the new instance.

- `cause_names`:

  ([`character()`](https://rdrr.io/r/base/character.html)\|`NULL`)  
  Unnamed character vector of unique, nonempty descriptive names,
  ordered by cause code. If `NULL`, defaults to `"Cause 1"`,
  `"Cause 2"`, ..., `"Cause K"`.

#### Details

Only right-censoring competing risk tasks are currently supported.

------------------------------------------------------------------------

### `TaskCompRisks$print()`

Prints the task information, including cause names, event counts,
proportions, and censoring frequency.

#### Usage

    TaskCompRisks$print(...)

#### Arguments

- `...`:

  (any)  
  Additional arguments passed to the parent print method.

#### Returns

The task object, invisibly.

------------------------------------------------------------------------

### `TaskCompRisks$truth()`

True response for specified `row_ids`. This is the multi-state format
using [Surv](https://rdrr.io/pkg/survival/man/Surv.html) with the
`event` target column as a `factor`. Descriptive cause names are stored
in the response's `states` attribute. Defaults to all active rows with
role `"use"`.

#### Usage

    TaskCompRisks$truth(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html).

------------------------------------------------------------------------

### `TaskCompRisks$formula()`

Creates a formula for competing risk models with
[`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html) on the
LHS (left hand side).

#### Usage

    TaskCompRisks$formula(rhs = NULL)

#### Arguments

- `rhs`:

  If `NULL`, RHS (right hand side) is `"."`, otherwise RHS is `"rhs"`.

#### Returns

[`stats::formula()`](https://rdrr.io/r/stats/formula.html).

------------------------------------------------------------------------

### `TaskCompRisks$times()`

Returns the (unsorted) outcome times.

#### Usage

    TaskCompRisks$times(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`numeric()`](https://rdrr.io/r/base/numeric.html)

------------------------------------------------------------------------

### `TaskCompRisks$event()`

Returns the event indicators. `0` denotes censoring, and positive
integers denote distinct event causes.

#### Usage

    TaskCompRisks$event(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`integer()`](https://rdrr.io/r/base/integer.html)

------------------------------------------------------------------------

### `TaskCompRisks$unique_times()`

Returns the sorted unique outcome times.

#### Usage

    TaskCompRisks$unique_times(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`numeric()`](https://rdrr.io/r/base/numeric.html)

------------------------------------------------------------------------

### `TaskCompRisks$unique_event_times()`

Returns the sorted unique event outcome times, optionally restricted to
a specific cause.

#### Usage

    TaskCompRisks$unique_event_times(rows = NULL, cause = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

- `cause`:

  (`integer(1)`\|`NULL`)  
  Cause code from `$causes`, or `NULL` to include events of every cause.

#### Returns

[`numeric()`](https://rdrr.io/r/base/numeric.html)

------------------------------------------------------------------------

### `TaskCompRisks$aalen_johansen()`

Calls
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html)
to calculate the Aalen–Johansen estimator.

#### Usage

    TaskCompRisks$aalen_johansen(strata = NULL, rows = NULL, ...)

#### Arguments

- `strata`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Vector of features to use for stratification.

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Subset of row indices.

- `...`:

  (any)  
  Additional arguments passed down to
  [`survival::survfit.formula()`](https://rdrr.io/pkg/survival/man/survfit.formula.html).

#### Returns

[survival::survfit.object](https://rdrr.io/pkg/survival/man/survfit.object.html).

------------------------------------------------------------------------

### `TaskCompRisks$event_counts()`

Returns the counts and relative frequencies of observed outcomes,
including censoring (`0`) and all competing causes (`1`, ..., `K`).
Frequencies are calculated over the specified rows (all active rows by
default).

#### Usage

    TaskCompRisks$event_counts(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

A
[`data.table::data.table()`](https://rdrr.io/pkg/data.table/man/data.table.html)
with columns:

- `cause`: Integer cause code (`0` denotes censoring).

- `name`: Descriptive cause name.

- `n`: Number of observations.

- `prop`: Proportion of observations.

------------------------------------------------------------------------

### `TaskCompRisks$cens_prop()`

Returns the **proportion of censored observations** for this competing
risks task.

#### Usage

    TaskCompRisks$cens_prop(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`numeric()`](https://rdrr.io/r/base/numeric.html)

------------------------------------------------------------------------

### `TaskCompRisks$filter()`

Subsets the task, keeping only the rows specified via the row ids
`rows`. This operation mutates the task in-place. A warning is thrown if
the filtering results in fewer competing events than the original task.
An error is thrown if fewer than two competing events remain after
filtering.

#### Usage

    TaskCompRisks$filter(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

Returns the object itself, but modified **by reference.**

------------------------------------------------------------------------

### `TaskCompRisks$clone()`

The objects of this class are cloneable with this method.

#### Usage

    TaskCompRisks$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(mlr3)
task = tsk("pbc")

# General info
task
#> 
#> ── <TaskCompRisks> (276x19): Mayo Clinic Primary Biliary Cholangitis Data ──────
#> • Target: time and status
#> • Properties: -
#> • Features (17):
#>   • fct (7): ascites, edema, hepato, sex, spiders, stage, trt
#>   • int (5): age, chol, copper, platelet, trig
#>   • dbl (5): albumin, alk.phos, ast, bili, protime
#> • Causes (2):
#>   • 1 (Liver transplantation): 18 (6.5%)
#>   • 2 (Death without transplantation): 111 (40.2%)
#> • Censored: 147 (53.3%)

# Time and event target columns
task$target_names
#> [1] "time"   "status"
# Feature names
task$feature_names
#>  [1] "age"      "albumin"  "alk.phos" "ascites"  "ast"      "bili"    
#>  [7] "chol"     "copper"   "edema"    "hepato"   "platelet" "protime" 
#> [13] "sex"      "spiders"  "stage"    "trig"     "trt"     
# Censoring type
task$cens_type
#> [1] "right"

# Survival data
task$formula(c("age", "sex")) # formula with survival::Surv() on LHS
#> Surv(time, factor(status, levels = c(0, 1, 2), labels = c("Censored", 
#>     "Liver transplantation", "Death without transplantation"))) ~ 
#>     age + sex
#> <environment: namespace:survival>
task$truth() # survival::Surv() object
#>   [1]  400:Death without transplantation 4500:Censored                     
#>   [3] 1012:Death without transplantation 1925:Death without transplantation
#>   [5] 1504:Liver transplantation         1832:Censored                     
#>   [7] 2466:Death without transplantation 2400:Death without transplantation
#>   [9]   51:Death without transplantation 3762:Death without transplantation
#>  [11]  304:Death without transplantation 3577:Censored                     
#>  [13] 3584:Death without transplantation 3672:Censored                     
#>  [15]  769:Death without transplantation  131:Death without transplantation
#>  [17] 4232:Censored                      1356:Death without transplantation
#>  [19] 3445:Censored                       673:Death without transplantation
#>  [21]  264:Death without transplantation 4079:Death without transplantation
#>  [23] 4127:Censored                      1444:Death without transplantation
#>  [25]   77:Death without transplantation  549:Death without transplantation
#>  [27] 4509:Censored                       321:Death without transplantation
#>  [29] 3839:Death without transplantation 4523:Censored                     
#>  [31] 3170:Death without transplantation 3933:Censored                     
#>  [33] 2847:Death without transplantation 3611:Censored                     
#>  [35]  223:Death without transplantation 3244:Death without transplantation
#>  [37] 2297:Death without transplantation 4556:Censored                     
#>  [39] 3428:Death without transplantation 2256:Death without transplantation
#>  [41] 2576:Censored                      4427:Censored                     
#>  [43] 2598:Death without transplantation 3853:Death without transplantation
#>  [45] 2386:Death without transplantation 1434:Death without transplantation
#>  [47] 1360:Death without transplantation 1847:Death without transplantation
#>  [49] 3282:Death without transplantation 2224:Death without transplantation
#>  [51] 4365:Censored                      4256:Censored                     
#>  [53] 3090:Death without transplantation  859:Death without transplantation
#>  [55] 1487:Death without transplantation 3992:Censored                     
#>  [57] 4191:Death without transplantation 2769:Death without transplantation
#>  [59] 4039:Censored                      1170:Death without transplantation
#>  [61] 4196:Censored                      4184:Censored                     
#>  [63] 4190:Censored                      1827:Death without transplantation
#>  [65] 1191:Death without transplantation   71:Death without transplantation
#>  [67]  326:Death without transplantation 1690:Death without transplantation
#>  [69] 3707:Censored                       890:Death without transplantation
#>  [71] 2540:Death without transplantation 3574:Death without transplantation
#>  [73] 4050:Censored                      4032:Censored                     
#>  [75] 3358:Death without transplantation 1657:Death without transplantation
#>  [77]  198:Death without transplantation 2452:Censored                     
#>  [79] 1741:Death without transplantation 2689:Death without transplantation
#>  [81]  460:Death without transplantation  388:Death without transplantation
#>  [83] 3913:Censored                       750:Death without transplantation
#>  [85]  611:Death without transplantation 3823:Censored                     
#>  [87] 3820:Censored                       552:Death without transplantation
#>  [89] 3581:Censored                      3099:Censored                     
#>  [91]  110:Death without transplantation 3086:Death without transplantation
#>  [93] 3092:Liver transplantation         3388:Censored                     
#>  [95] 2583:Death without transplantation 2504:Censored                     
#>  [97] 2105:Death without transplantation 2350:Liver transplantation        
#>  [99] 3445:Death without transplantation  980:Death without transplantation
#> [101] 3395:Death without transplantation 3422:Censored                     
#> [103] 3336:Censored                      1083:Death without transplantation
#> [105] 2288:Death without transplantation  515:Death without transplantation
#> [107] 2033:Liver transplantation          191:Death without transplantation
#> [109] 3297:Censored                      3069:Censored                     
#> [111] 2468:Liver transplantation         3255:Censored                     
#> [113] 1413:Death without transplantation  850:Death without transplantation
#> [115] 2944:Censored                      2796:Death without transplantation
#> [117] 3149:Censored                      3150:Censored                     
#> [119] 3098:Censored                      2990:Censored                     
#> [121] 1297:Death without transplantation 2106:Censored                     
#> [123] 3059:Censored                      3050:Censored                     
#> [125] 2419:Death without transplantation  786:Death without transplantation
#> [127]  943:Death without transplantation 2976:Censored                     
#> [129] 2995:Censored                      1427:Death without transplantation
#> [131]  762:Death without transplantation 2870:Censored                     
#> [133] 1152:Death without transplantation 2863:Censored                     
#> [135]  140:Death without transplantation 2666:Censored                     
#> [137]  853:Death without transplantation 2835:Censored                     
#> [139] 2475:Liver transplantation         1536:Death without transplantation
#> [141] 2772:Censored                      2797:Censored                     
#> [143]  186:Death without transplantation 2055:Death without transplantation
#> [145] 1077:Death without transplantation 2721:Censored                     
#> [147] 1682:Death without transplantation 1212:Death without transplantation
#> [149] 2692:Censored                      2301:Censored                     
#> [151] 2657:Censored                      2624:Censored                     
#> [153] 2609:Censored                      2573:Censored                     
#> [155] 2563:Censored                      2556:Censored                     
#> [157] 2241:Liver transplantation          974:Death without transplantation
#> [159] 2527:Censored                      1576:Death without transplantation
#> [161]  733:Death without transplantation 2332:Censored                     
#> [163] 2456:Censored                       216:Death without transplantation
#> [165] 2443:Censored                       797:Death without transplantation
#> [167] 2449:Censored                      2330:Censored                     
#> [169] 2363:Censored                      2365:Censored                     
#> [171] 2357:Censored                      1592:Censored                     
#> [173] 2318:Censored                      2294:Censored                     
#> [175] 2272:Censored                      2221:Censored                     
#> [177] 2090:Death without transplantation 2255:Censored                     
#> [179]  904:Death without transplantation 2216:Censored                     
#> [181] 2224:Censored                      2176:Censored                     
#> [183] 2178:Censored                      1786:Death without transplantation
#> [185] 1080:Death without transplantation  790:Death without transplantation
#> [187] 2157:Censored                      1235:Death without transplantation
#> [189] 2050:Censored                       597:Death without transplantation
#> [191]  334:Death without transplantation 1945:Censored                     
#> [193] 2022:Censored                      1978:Censored                     
#> [195]  999:Death without transplantation 1967:Censored                     
#> [197]  348:Death without transplantation 1979:Censored                     
#> [199] 1165:Death without transplantation 1951:Censored                     
#> [201] 1932:Censored                      1776:Censored                     
#> [203] 1882:Censored                      1908:Censored                     
#> [205] 1882:Censored                       694:Death without transplantation
#> [207] 1831:Censored                       837:Liver transplantation        
#> [209] 1810:Censored                       930:Death without transplantation
#> [211] 1690:Death without transplantation 1790:Censored                     
#> [213] 1435:Liver transplantation          732:Liver transplantation        
#> [215] 1785:Censored                      1783:Censored                     
#> [217] 1769:Censored                      1457:Censored                     
#> [219] 1770:Censored                      1765:Censored                     
#> [221]  737:Liver transplantation         1735:Censored                     
#> [223] 1701:Censored                      1614:Censored                     
#> [225] 1702:Censored                      1615:Censored                     
#> [227] 1656:Censored                      1666:Censored                     
#> [229] 1301:Liver transplantation         1542:Liver transplantation        
#> [231] 1084:Liver transplantation         1614:Censored                     
#> [233]  179:Death without transplantation 1191:Death without transplantation
#> [235] 1363:Censored                      1568:Censored                     
#> [237] 1569:Censored                      1525:Censored                     
#> [239] 1558:Censored                      1349:Censored                     
#> [241] 1481:Censored                      1434:Censored                     
#> [243] 1420:Censored                      1433:Censored                     
#> [245] 1412:Censored                        41:Death without transplantation
#> [247] 1455:Censored                      1030:Censored                     
#> [249] 1418:Censored                      1401:Censored                     
#> [251] 1408:Censored                      1234:Censored                     
#> [253] 1067:Liver transplantation          799:Death without transplantation
#> [255] 1363:Censored                       901:Liver transplantation        
#> [257] 1329:Censored                      1320:Censored                     
#> [259] 1302:Censored                       877:Liver transplantation        
#> [261] 1321:Censored                       533:Liver transplantation        
#> [263] 1300:Censored                      1293:Censored                     
#> [265] 1295:Censored                      1271:Censored                     
#> [267] 1250:Censored                      1230:Censored                     
#> [269] 1216:Censored                      1216:Censored                     
#> [271] 1149:Censored                      1153:Censored                     
#> [273]  994:Censored                       939:Censored                     
#> [275]  839:Censored                       788:Censored                     
task$times() # (unsorted) times
#>   [1]  400 4500 1012 1925 1504 1832 2466 2400   51 3762  304 3577 3584 3672  769
#>  [16]  131 4232 1356 3445  673  264 4079 4127 1444   77  549 4509  321 3839 4523
#>  [31] 3170 3933 2847 3611  223 3244 2297 4556 3428 2256 2576 4427 2598 3853 2386
#>  [46] 1434 1360 1847 3282 2224 4365 4256 3090  859 1487 3992 4191 2769 4039 1170
#>  [61] 4196 4184 4190 1827 1191   71  326 1690 3707  890 2540 3574 4050 4032 3358
#>  [76] 1657  198 2452 1741 2689  460  388 3913  750  611 3823 3820  552 3581 3099
#>  [91]  110 3086 3092 3388 2583 2504 2105 2350 3445  980 3395 3422 3336 1083 2288
#> [106]  515 2033  191 3297 3069 2468 3255 1413  850 2944 2796 3149 3150 3098 2990
#> [121] 1297 2106 3059 3050 2419  786  943 2976 2995 1427  762 2870 1152 2863  140
#> [136] 2666  853 2835 2475 1536 2772 2797  186 2055 1077 2721 1682 1212 2692 2301
#> [151] 2657 2624 2609 2573 2563 2556 2241  974 2527 1576  733 2332 2456  216 2443
#> [166]  797 2449 2330 2363 2365 2357 1592 2318 2294 2272 2221 2090 2255  904 2216
#> [181] 2224 2176 2178 1786 1080  790 2157 1235 2050  597  334 1945 2022 1978  999
#> [196] 1967  348 1979 1165 1951 1932 1776 1882 1908 1882  694 1831  837 1810  930
#> [211] 1690 1790 1435  732 1785 1783 1769 1457 1770 1765  737 1735 1701 1614 1702
#> [226] 1615 1656 1666 1301 1542 1084 1614  179 1191 1363 1568 1569 1525 1558 1349
#> [241] 1481 1434 1420 1433 1412   41 1455 1030 1418 1401 1408 1234 1067  799 1363
#> [256]  901 1329 1320 1302  877 1321  533 1300 1293 1295 1271 1250 1230 1216 1216
#> [271] 1149 1153  994  939  839  788
task$event() # event indicators (0 = censored, >0 = different causes)
#>   [1] 2 0 2 2 1 0 2 2 2 2 2 0 2 0 2 2 0 2 0 2 2 2 0 2 2 2 0 2 2 0 2 0 2 0 2 2 2
#>  [38] 0 2 2 0 0 2 2 2 2 2 2 2 2 0 0 2 2 2 0 2 2 0 2 0 0 0 2 2 2 2 2 0 2 2 2 0 0
#>  [75] 2 2 2 0 2 2 2 2 0 2 2 0 0 2 0 0 2 2 1 0 2 0 2 1 2 2 2 0 0 2 2 2 1 2 0 0 1
#> [112] 0 2 2 0 2 0 0 0 0 2 0 0 0 2 2 2 0 0 2 2 0 2 0 2 0 2 0 1 2 0 0 2 2 2 0 2 2
#> [149] 0 0 0 0 0 0 0 0 1 2 0 2 2 0 0 2 0 2 0 0 0 0 0 0 0 0 0 0 2 0 2 0 0 0 0 2 2
#> [186] 2 0 2 0 2 2 0 0 0 2 0 2 0 2 0 0 0 0 0 0 2 0 1 0 2 2 0 1 1 0 0 0 0 0 0 1 0
#> [223] 0 0 0 0 0 0 1 1 1 0 2 2 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 1 2 0 1 0 0 0
#> [260] 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0
task$unique_times() # sorted unique times
#>   [1]   41   51   71   77  110  131  140  179  186  191  198  216  223  264  304
#>  [16]  321  326  334  348  388  400  460  515  533  549  552  597  611  673  694
#>  [31]  732  733  737  750  762  769  786  788  790  797  799  837  839  850  853
#>  [46]  859  877  890  901  904  930  939  943  974  980  994  999 1012 1030 1067
#>  [61] 1077 1080 1083 1084 1149 1152 1153 1165 1170 1191 1212 1216 1230 1234 1235
#>  [76] 1250 1271 1293 1295 1297 1300 1301 1302 1320 1321 1329 1349 1356 1360 1363
#>  [91] 1401 1408 1412 1413 1418 1420 1427 1433 1434 1435 1444 1455 1457 1481 1487
#> [106] 1504 1525 1536 1542 1558 1568 1569 1576 1592 1614 1615 1656 1657 1666 1682
#> [121] 1690 1701 1702 1735 1741 1765 1769 1770 1776 1783 1785 1786 1790 1810 1827
#> [136] 1831 1832 1847 1882 1908 1925 1932 1945 1951 1967 1978 1979 2022 2033 2050
#> [151] 2055 2090 2105 2106 2157 2176 2178 2216 2221 2224 2241 2255 2256 2272 2288
#> [166] 2294 2297 2301 2318 2330 2332 2350 2357 2363 2365 2386 2400 2419 2443 2449
#> [181] 2452 2456 2466 2468 2475 2504 2527 2540 2556 2563 2573 2576 2583 2598 2609
#> [196] 2624 2657 2666 2689 2692 2721 2769 2772 2796 2797 2835 2847 2863 2870 2944
#> [211] 2976 2990 2995 3050 3059 3069 3086 3090 3092 3098 3099 3149 3150 3170 3244
#> [226] 3255 3282 3297 3336 3358 3388 3395 3422 3428 3445 3574 3577 3581 3584 3611
#> [241] 3672 3707 3762 3820 3823 3839 3853 3913 3933 3992 4032 4039 4050 4079 4127
#> [256] 4184 4190 4191 4196 4232 4256 4365 4427 4500 4509 4523 4556
task$unique_event_times() # sorted unique event times (from any cause)
#>   [1]   41   51   71   77  110  131  140  179  186  191  198  216  223  264  304
#>  [16]  321  326  334  348  388  400  460  515  533  549  552  597  611  673  694
#>  [31]  732  733  737  750  762  769  786  790  797  799  837  850  853  859  877
#>  [46]  890  901  904  930  943  974  980  999 1012 1067 1077 1080 1083 1084 1152
#>  [61] 1165 1170 1191 1212 1235 1297 1301 1356 1360 1413 1427 1434 1435 1444 1487
#>  [76] 1504 1536 1542 1576 1657 1682 1690 1741 1786 1827 1847 1925 2033 2055 2090
#>  [91] 2105 2224 2241 2256 2288 2297 2350 2386 2400 2419 2466 2468 2475 2540 2583
#> [106] 2598 2689 2769 2796 2847 3086 3090 3092 3170 3244 3282 3358 3395 3428 3445
#> [121] 3574 3584 3762 3839 3853 4079 4191
task$unique_event_times(cause = 1L) # times for cause 1 only
#>  [1]  533  732  737  837  877  901 1067 1084 1301 1435 1504 1542 2033 2241 2350
#> [16] 2468 2475 3092
task$cens_prop() # proportion of censored observations
#> [1] 0.5326087
task$event_counts() # observed counts and proportions, including censoring
#>    cause                          name     n       prop
#>    <int>                        <char> <int>      <num>
#> 1:     0                      Censored   147 0.53260870
#> 2:     1         Liver transplantation    18 0.06521739
#> 3:     2 Death without transplantation   111 0.40217391

# Aalen-Johansen estimator
task$aalen_johansen(strata = "sex")
#> Call: survfit(formula = f, data = data)
#> 
#>                                        n nevent     rmean se(rmean)*
#> sex=m, (s0)                           34      0 2251.4679  267.17307
#> sex=f, (s0)                          242      0 2863.7077  114.13009
#> sex=m, Liver transplantation          34      3  321.2423  170.78563
#> sex=f, Liver transplantation         242     15  234.1051   58.22215
#> sex=m, Death without transplantation  34     21 1983.2898  278.68310
#> sex=f, Death without transplantation 242     90 1458.1872  114.05372
#>    *restricted mean time in state (max time = 4556 )

# Causes
task$n_causes
#> [1] 2
task$causes
#> [1] 1 2
task$cause_names
#>                               1                               2 
#>         "Liver transplantation" "Death without transplantation" 
```
