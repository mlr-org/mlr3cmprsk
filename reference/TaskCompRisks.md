# Competing Risks Task

This task extends
[mlr3::Task](https://mlr3.mlr-org.com/reference/Task.html) and
[mlr3::TaskSupervised](https://mlr3.mlr-org.com/reference/TaskSupervised.html)
to handle survival problems with **competing risks**. The target
variable consists of survival times and an event indicator, which must
be a non-negative integer in the set \\(0,1,2,...,K)\\. \\0\\ represents
censored observations, while other integers correspond to distinct
competing events. Every row corresponds to one subject/observation.

Predefined tasks are stored in
[mlr3::mlr_tasks](https://mlr3.mlr-org.com/reference/mlr_tasks.html).

The `task_type` is set to `"cmprsk"`.

**Note:** Currently only right-censoring is supported.

## See also

Other Task:
[`mlr_tasks_pbc`](https://mlr3cmprsk.mlr-org.com/reference/mlr_tasks_pbc.md)

## Super classes

[`mlr3::Task`](https://mlr3.mlr-org.com/reference/Task.html) -\>
[`mlr3::TaskSupervised`](https://mlr3.mlr-org.com/reference/TaskSupervised.html)
-\> `TaskCompRisks`

## Active bindings

- `cens_type`:

  (`character(1)`)  
  Returns the type of censoring.

  Currently, only the `"right"` censoring type is fully supported. The
  API might change in the future to support left and interval censoring.

- `cmp_events`:

  (`character(1)`)  
  Returns the names of the competing events.

## Methods

### Public methods

- [`TaskCompRisks$new()`](#method-TaskCompRisks-new)

- [`TaskCompRisks$truth()`](#method-TaskCompRisks-truth)

- [`TaskCompRisks$formula()`](#method-TaskCompRisks-formula)

- [`TaskCompRisks$times()`](#method-TaskCompRisks-times)

- [`TaskCompRisks$event()`](#method-TaskCompRisks-event)

- [`TaskCompRisks$unique_events()`](#method-TaskCompRisks-unique_events)

- [`TaskCompRisks$unique_times()`](#method-TaskCompRisks-unique_times)

- [`TaskCompRisks$unique_event_times()`](#method-TaskCompRisks-unique_event_times)

- [`TaskCompRisks$aalen_johansen()`](#method-TaskCompRisks-aalen_johansen)

- [`TaskCompRisks$cens_prop()`](#method-TaskCompRisks-cens_prop)

- [`TaskCompRisks$filter()`](#method-TaskCompRisks-filter)

- [`TaskCompRisks$clone()`](#method-TaskCompRisks-clone)

Inherited methods

- [`mlr3::Task$add_strata()`](https://mlr3.mlr-org.com/reference/Task.html#method-add_strata)
- [`mlr3::Task$cbind()`](https://mlr3.mlr-org.com/reference/Task.html#method-cbind)
- [`mlr3::Task$data()`](https://mlr3.mlr-org.com/reference/Task.html#method-data)
- [`mlr3::Task$divide()`](https://mlr3.mlr-org.com/reference/Task.html#method-divide)
- [`mlr3::Task$droplevels()`](https://mlr3.mlr-org.com/reference/Task.html#method-droplevels)
- [`mlr3::Task$format()`](https://mlr3.mlr-org.com/reference/Task.html#method-format)
- [`mlr3::Task$head()`](https://mlr3.mlr-org.com/reference/Task.html#method-head)
- [`mlr3::Task$help()`](https://mlr3.mlr-org.com/reference/Task.html#method-help)
- [`mlr3::Task$levels()`](https://mlr3.mlr-org.com/reference/Task.html#method-levels)
- [`mlr3::Task$materialize_view()`](https://mlr3.mlr-org.com/reference/Task.html#method-materialize_view)
- [`mlr3::Task$missings()`](https://mlr3.mlr-org.com/reference/Task.html#method-missings)
- [`mlr3::Task$print()`](https://mlr3.mlr-org.com/reference/Task.html#method-print)
- [`mlr3::Task$rbind()`](https://mlr3.mlr-org.com/reference/Task.html#method-rbind)
- [`mlr3::Task$rename()`](https://mlr3.mlr-org.com/reference/Task.html#method-rename)
- [`mlr3::Task$select()`](https://mlr3.mlr-org.com/reference/Task.html#method-select)
- [`mlr3::Task$set_col_roles()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_col_roles)
- [`mlr3::Task$set_levels()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_levels)
- [`mlr3::Task$set_row_roles()`](https://mlr3.mlr-org.com/reference/Task.html#method-set_row_roles)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    TaskCompRisks$new(
      id,
      backend,
      time = "time",
      event = "event",
      label = NA_character_
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
  Name of column giving that holds the event indicator. \\0\\
  corresponds to censoring, values \\\> 0\\ correspond to different
  competing events.

- `label`:

  (`character(1)`)  
  Label for the new instance.

#### Details

Only right-censoring competing risk tasks are currently supported.

------------------------------------------------------------------------

### Method `truth()`

True response for specified `row_ids`. This is the multi-state format
using [Surv](https://rdrr.io/pkg/survival/man/Surv.html) with the
`event` target column as a `factor`: `Surv(time, as.factor(event))`

Defaults to all rows with role `"use"`.

#### Usage

    TaskCompRisks$truth(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`survival::Surv()`](https://rdrr.io/pkg/survival/man/Surv.html).

------------------------------------------------------------------------

### Method [`formula()`](https://rdrr.io/r/stats/formula.html)

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

### Method `times()`

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

### Method `event()`

Returns the event indicator.

#### Usage

    TaskCompRisks$event(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`integer()`](https://rdrr.io/r/base/integer.html)

------------------------------------------------------------------------

### Method `unique_events()`

Returns the unique events (excluding censoring).

#### Usage

    TaskCompRisks$unique_events(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`integer()`](https://rdrr.io/r/base/integer.html)

------------------------------------------------------------------------

### Method `unique_times()`

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

### Method `unique_event_times()`

Returns the sorted unique event outcome times (by any cause).

#### Usage

    TaskCompRisks$unique_event_times(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`numeric()`](https://rdrr.io/r/base/numeric.html)

------------------------------------------------------------------------

### Method `aalen_johansen()`

Calls
[`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html)
to calculate the Aalen–Johansen estimator.

#### Usage

    TaskCompRisks$aalen_johansen(strata = NULL, rows = NULL, ...)

#### Arguments

- `strata`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Stratification variables to use.

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

### Method `cens_prop()`

Returns the **proportion of censoring** for this competing risks task.
By default, this is returned for all observations, otherwise only the
specified ones (`rows`).

#### Usage

    TaskCompRisks$cens_prop(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

[`numeric()`](https://rdrr.io/r/base/numeric.html)

------------------------------------------------------------------------

### Method [`filter()`](https://rdrr.io/r/stats/filter.html)

Subsets the task, keeping only the rows specified via row ids `rows`.
This operation mutates the task in-place.

#### Usage

    TaskCompRisks$filter(rows = NULL)

#### Arguments

- `rows`:

  ([`integer()`](https://rdrr.io/r/base/integer.html))  
  Row indices.

#### Returns

Returns the object itself, but modified **by reference.**

------------------------------------------------------------------------

### Method `clone()`

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

# meta data
task$target_names # target is always (time, status) for right-censoring tasks
#> [1] "time"   "status"
task$feature_names
#>  [1] "age"      "albumin"  "alk.phos" "ascites"  "ast"      "bili"    
#>  [7] "chol"     "copper"   "edema"    "hepato"   "platelet" "protime" 
#> [13] "sex"      "spiders"  "stage"    "trig"     "trt"     
task$formula()
#> Surv(time, as.factor(status)) ~ .
#> <environment: namespace:survival>

# survival data
task$truth() # survival::Surv() object
#>   [1]  13:2 147+   33:2  63:2  49:1  60+   81:2  78:2   1:2 123:2   9:2 117+ 
#>  [13] 117:2 120+   25:2   4:2 139+   44:2 113+   22:2   8:2 134:2 135+   47:2
#>  [25]   2:2  18:2 148+   10:2 126:2 148+  104:2 129+   93:2 118+    7:2 106:2
#>  [37]  75:2 149+  112:2  74:2  84+  145+   85:2 126:2  78:2  47:2  44:2  60:2
#>  [49] 107:2  73:2 143+  139+  101:2  28:2  48:2 131+  137:2  90:2 132+   38:2
#>  [61] 137+  137+  137+   60:2  39:2   2:2  10:2  55:2 121+   29:2  83:2 117:2
#>  [73] 133+  132+  110:2  54:2   6:2  80+   57:2  88:2  15:2  12:2 128+   24:2
#>  [85]  20:2 125+  125+   18:2 117+  101+    3:2 101:2 101:1 111+   84:2  82+ 
#>  [97]  69:2  77:1 113:2  32:2 111:2 112+  109+   35:2  75:2  16:2  66:1   6:2
#> [109] 108+  100+   81:1 106+   46:2  27:2  96+   91:2 103+  103+  101+   98+ 
#> [121]  42:2  69+  100+  100+   79:2  25:2  30:2  97+   98+   46:2  25:2  94+ 
#> [133]  37:2  94+    4:2  87+   28:2  93+   81:1  50:2  91+   91+    6:2  67:2
#> [145]  35:2  89+   55:2  39:2  88+   75+   87+   86+   85+   84+   84+   83+ 
#> [157]  73:1  31:2  83+   51:2  24:2  76+   80+    7:2  80+   26:2  80+   76+ 
#> [169]  77+   77+   77+   52+   76+   75+   74+   72+   68:2  74+   29:2  72+ 
#> [181]  73+   71+   71+   58:2  35:2  25:2  70+   40:2  67+   19:2  10:2  63+ 
#> [193]  66+   64+   32:2  64+   11:2  65+   38:2  64+   63+   58+   61+   62+ 
#> [205]  61+   22:2  60+   27:1  59+   30:2  55:2  58+   47:1  24:1  58+   58+ 
#> [217]  58+   47+   58+   57+   24:1  56+   55+   53+   55+   53+   54+   54+ 
#> [229]  42:1  50:1  35:1  53+    5:2  39:2  44+   51+   51+   50+   51+   44+ 
#> [241]  48+   47+   46+   47+   46+    1:2  47+   33+   46+   46+   46+   40+ 
#> [253]  35:1  26:2  44+   29:1  43+   43+   42+   28:1  43+   17:1  42+   42+ 
#> [265]  42+   41+   41+   40+   39+   39+   37+   37+   32+   30+   27+   25+ 
task$times() # (unsorted) times
#>   [1]  13 147  33  63  49  60  81  78   1 123   9 117 117 120  25   4 139  44
#>  [19] 113  22   8 134 135  47   2  18 148  10 126 148 104 129  93 118   7 106
#>  [37]  75 149 112  74  84 145  85 126  78  47  44  60 107  73 143 139 101  28
#>  [55]  48 131 137  90 132  38 137 137 137  60  39   2  10  55 121  29  83 117
#>  [73] 133 132 110  54   6  80  57  88  15  12 128  24  20 125 125  18 117 101
#>  [91]   3 101 101 111  84  82  69  77 113  32 111 112 109  35  75  16  66   6
#> [109] 108 100  81 106  46  27  96  91 103 103 101  98  42  69 100 100  79  25
#> [127]  30  97  98  46  25  94  37  94   4  87  28  93  81  50  91  91   6  67
#> [145]  35  89  55  39  88  75  87  86  85  84  84  83  73  31  83  51  24  76
#> [163]  80   7  80  26  80  76  77  77  77  52  76  75  74  72  68  74  29  72
#> [181]  73  71  71  58  35  25  70  40  67  19  10  63  66  64  32  64  11  65
#> [199]  38  64  63  58  61  62  61  22  60  27  59  30  55  58  47  24  58  58
#> [217]  58  47  58  57  24  56  55  53  55  53  54  54  42  50  35  53   5  39
#> [235]  44  51  51  50  51  44  48  47  46  47  46   1  47  33  46  46  46  40
#> [253]  35  26  44  29  43  43  42  28  43  17  42  42  42  41  41  40  39  39
#> [271]  37  37  32  30  27  25
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
#>   [1]   1   2   3   4   5   6   7   8   9  10  11  12  13  15  16  17  18  19
#>  [19]  20  22  24  25  26  27  28  29  30  31  32  33  35  37  38  39  40  41
#>  [37]  42  43  44  46  47  48  49  50  51  52  53  54  55  56  57  58  59  60
#>  [55]  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78
#>  [73]  79  80  81  82  83  84  85  86  87  88  89  90  91  93  94  96  97  98
#>  [91] 100 101 103 104 106 107 108 109 110 111 112 113 117 118 120 121 123 125
#> [109] 126 128 129 131 132 133 134 135 137 139 143 145 147 148 149
task$unique_event_times() # sorted unique event times (from any cause)
#>  [1]   1   2   3   4   5   6   7   8   9  10  11  12  13  15  16  17  18  19  20
#> [20]  22  24  25  26  27  28  29  30  31  32  33  35  37  38  39  40  42  44  46
#> [39]  47  48  49  50  51  54  55  57  58  60  63  66  67  68  69  73  74  75  77
#> [58]  78  79  81  83  84  85  88  90  91  93 101 104 106 107 110 111 112 113 117
#> [77] 123 126 134 137
task$aalen_johansen(strata = "sex") # Aalen-Johansen estimator
#> Call: survfit(formula = f, data = data)
#> 
#>               n nevent     rmean se(rmean)*
#> sex=m, (s0)  34      0 73.485839   8.777244
#> sex=f, (s0) 242      0 93.714998   3.738137
#> sex=m, 1     34      3 10.556980   5.624320
#> sex=f, 1    242     15  7.654985   1.904137
#> sex=m, 2     34     21 64.957181   9.152039
#> sex=f, 2    242     90 47.630017   3.733828
#>    *restricted mean time in state (max time = 149 )

# proportion of censored observations across all dataset
task$cens_prop()
#> [1] 0.5326087
```
