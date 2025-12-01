# Convert to a Competing Risks Task

Convert object to a competing risks task
([TaskCompRisks](https://mlr3cmprsk.mlr-org.com/reference/TaskCompRisks.md)).

## Usage

``` r
as_task_cmprsk(x, ...)

# S3 method for class 'TaskCompRisks'
as_task_cmprsk(x, clone = FALSE, ...)

# S3 method for class 'data.frame'
as_task_cmprsk(
  x,
  time = "time",
  event = "event",
  id = deparse(substitute(x)),
  ...
)

# S3 method for class 'DataBackend'
as_task_cmprsk(
  x,
  time = "time",
  event = "event",
  id = deparse(substitute(x)),
  ...
)
```

## Arguments

- x:

  (`any`)  
  Object to convert, e.g. a
  [`data.frame()`](https://rdrr.io/r/base/data.frame.html).

- ...:

  (`any`)  
  Additional arguments.

- clone:

  (`logical(1)`)  
  If `TRUE`, ensures that the returned object is not the same as the
  input `x`.

- time:

  (`character(1)`)  
  Name of the column for outcome time.

- event:

  (`character(1)`)  
  Name of column giving that holds the event indicator. \\0\\
  corresponds to censoring, values \\\> 0\\ correspond to different
  competing events.

- id:

  (`character(1)`)  
  Id for the new task. Defaults to the (deparsed and substituted) name
  of `x`.
