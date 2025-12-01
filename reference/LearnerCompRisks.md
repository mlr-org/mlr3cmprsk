# Competing Risks Learner

This Learner specializes
[Learner](https://mlr3.mlr-org.com/reference/Learner.html) for competing
risks problems:

- `task_type` is set to `"cmprsk"`

- Creates
  [Prediction](https://mlr3.mlr-org.com/reference/Prediction.html)s of
  class
  [PredictionCompRisks](https://mlr3cmprsk.mlr-org.com/reference/PredictionCompRisks.md).

- The only currently available option for `predict_types` is `"cif"`,
  which represents the predicted **cumulative incidence function** for
  each observation in the test set.

## Super class

[`mlr3::Learner`](https://mlr3.mlr-org.com/reference/Learner.html) -\>
`LearnerCompRisks`

## Methods

### Public methods

- [`LearnerCompRisks$new()`](#method-LearnerCompRisks-new)

- [`LearnerCompRisks$clone()`](#method-LearnerCompRisks-clone)

Inherited methods

- [`mlr3::Learner$base_learner()`](https://mlr3.mlr-org.com/reference/Learner.html#method-base_learner)
- [`mlr3::Learner$configure()`](https://mlr3.mlr-org.com/reference/Learner.html#method-configure)
- [`mlr3::Learner$encapsulate()`](https://mlr3.mlr-org.com/reference/Learner.html#method-encapsulate)
- [`mlr3::Learner$format()`](https://mlr3.mlr-org.com/reference/Learner.html#method-format)
- [`mlr3::Learner$help()`](https://mlr3.mlr-org.com/reference/Learner.html#method-help)
- [`mlr3::Learner$predict()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict)
- [`mlr3::Learner$predict_newdata()`](https://mlr3.mlr-org.com/reference/Learner.html#method-predict_newdata)
- [`mlr3::Learner$print()`](https://mlr3.mlr-org.com/reference/Learner.html#method-print)
- [`mlr3::Learner$reset()`](https://mlr3.mlr-org.com/reference/Learner.html#method-reset)
- [`mlr3::Learner$selected_features()`](https://mlr3.mlr-org.com/reference/Learner.html#method-selected_features)
- [`mlr3::Learner$train()`](https://mlr3.mlr-org.com/reference/Learner.html#method-train)

------------------------------------------------------------------------

### Method `new()`

Creates a new instance of this
[R6](https://r6.r-lib.org/reference/R6Class.html) class.

#### Usage

    LearnerCompRisks$new(
      id,
      param_set = ps(),
      predict_types = "cif",
      feature_types = character(),
      properties = character(),
      packages = character(),
      label = NA_character_,
      man = NA_character_
    )

#### Arguments

- `id`:

  (`character(1)`)  
  Identifier for the new instance.

- `param_set`:

  ([paradox::ParamSet](https://paradox.mlr-org.com/reference/ParamSet.html))  
  Set of hyperparameters.

- `predict_types`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Supported predict types. Must be a subset of
  [`mlr_reflections$learner_predict_types`](https://mlr3.mlr-org.com/reference/mlr_reflections.html).

- `feature_types`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Feature types the learner operates on. Must be a subset of
  [`mlr_reflections$task_feature_types`](https://mlr3.mlr-org.com/reference/mlr_reflections.html).

- `properties`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Set of properties of the
  [Learner](https://mlr3.mlr-org.com/reference/Learner.html) (see
  initialization method `$new()`. Must be a subset of
  [`mlr_reflections$learner_properties`](https://mlr3.mlr-org.com/reference/mlr_reflections.html).

- `packages`:

  ([`character()`](https://rdrr.io/r/base/character.html))  
  Set of required packages. A warning is signaled by the constructor if
  at least one of the packages is not installed, but loaded (not
  attached) later on-demand via
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html).

- `label`:

  (`character(1)`)  
  Label for the new instance.

- `man`:

  (`character(1)`)  
  String in the format `[pkg]::[topic]` pointing to a manual page for
  this object. The referenced help package can be opened via method
  `$help()`.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    LearnerCompRisks$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
library(mlr3)
# get all survival learners from mlr_learners:
lrns = mlr_learners$mget(mlr_learners$keys("^cmprsk"))
names(lrns)
#> [1] "cmprsk.aalen"

# get a specific learner from mlr_learners:
mlr_learners$get("cmprsk.aalen")
#> 
#> ── <LearnerCompRisksAalenJohansen> (cmprsk.aalen): Aalen Johansen Estimator ────
#> • Model: -
#> • Parameters: list()
#> • Packages: mlr3, mlr3cmprsk, and survival
#> • Predict Types: [cif]
#> • Feature Types: logical, integer, numeric, and factor
#> • Encapsulation: none (fallback: -)
#> • Properties: weights
#> • Other settings: use_weights = 'use'
lrn("cmprsk.aalen")
#> 
#> ── <LearnerCompRisksAalenJohansen> (cmprsk.aalen): Aalen Johansen Estimator ────
#> • Model: -
#> • Parameters: list()
#> • Packages: mlr3, mlr3cmprsk, and survival
#> • Predict Types: [cif]
#> • Feature Types: logical, integer, numeric, and factor
#> • Encapsulation: none (fallback: -)
#> • Properties: weights
#> • Other settings: use_weights = 'use'
```
