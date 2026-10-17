# mlr3cmprsk 0.0.7

* fix: `as_prediction_cmprsk()` now errors when per-observation CIF vectors of the same cause differ in length or time names, instead of silently recycling values.
* fix: `PredictionCompRisks` now supports measurement weights (task column role `weights_measure`) and `extra` learner data, so `$predict()` no longer fails on tasks with measurement weights. Both are kept when filtering, combining, and converting predictions to a `data.table`.
* fix: `TaskCompRisks` now reads the event column through the public `DataBackend` interface, so tasks can be constructed from any backend, such as `DataBackendCbind`.
* fix: `c()` on `PredictionDataCompRisks` objects now preserves the `PredictionData` class, so the combined data works with `as_prediction_data()` and other mlr3 generics.
* fix: `as_prediction_cmprsk()` no longer converts a `data.frame` input to a `data.table` by reference.
* fix: `as_task_cmprsk()` now derives the default task id with `deparse1()`, so multi-line input expressions no longer fail the id validation.
* fix: Unloading the package preserves unrelated hooks and tolerates dictionary entries that have already been removed.
* fix: `cmprsk.auc`, `cmprsk.brier`, and `cmprsk.ibs` now resolve cause weights before scoring and skip zero-weight causes. Event-frequency weights warn for absent causes and return `NA` if no events are observed.
* feat: `cmprsk.auc`, `cmprsk.brier`, and `cmprsk.ibs` now identify the affected causes when warning about non-finite scores.
* feat: `cmprsk.auc`, `cmprsk.brier`, and `cmprsk.ibs` can now warn when scoring requires constant CIF extrapolation after a cause's final prediction anchor.
* feat: `cmprsk.auc` now explicitly rejects scoring times beyond the maximum test-set follow-up, following the behavior of the Brier score.
* feat: `cmprsk.ibs` now defaults to 100 equally spaced integration points from 0 to the 90th percentile of test-set follow-up. New parameters `ntimes`, `t_max`, and `t_quantile` control the automatic grid size and horizon, using test-set outcomes only. Horizons exceeding the maximum test-set follow-up are reduced with a warning before constructing exactly `ntimes` points.
* feat: CIF sum and extrapolation diagnostics are now disabled by default. Enable them package-wide with `options(mlr3cmprsk.warn_cif_sum = TRUE, mlr3cmprsk.warn_cif_extrapolation = TRUE)`; warnings and errors affecting score validity remain enabled.
* refine doc: better learner and measure examples

# mlr3cmprsk 0.0.6

* Added `MeasureCompRisksIntegratedBrierScore` (`msr("cmprsk.ibs")`) via `RiskRegression`.
This is now the main measure for prediction error in the package.
* Added config files for code formatting and for AI agents.
* Raised the minimum required versions of `mlr3` to 1.8.0 and `mlr3misc` to 0.23.0. (#22)
* `as_prediction_cmprsk()` now accepts named lists of prediction data.
* `assert_cif_list()` is now exported for validating lists of cumulative incidence matrices.
* fix: `cmprsk.fg` parameter `cengroup` allows now for vector input.
* fix: `TaskCompRisks` now checks that the event column has 1,2,...,K ordered integer-like numbers for the causes.
* feat: more tests, refactoring, better assertions and expectations, better documentation across the package.
* fix: `TaskCompRisks$filter()` now errors when row filtering leaves fewer than two competing events and gives a warning if less causes than before remain.
* fix: `check_prediction_data()` was called (indirectly) twice after a learner finished its `.predict()` call, which was not required.

# mlr3cmprsk 0.0.5

* Refactored `MeasureCompRisksAUC`, added `cause_weights` parameter, renamed `time_horizon` to `time`
* Added parameter tests for AJ and FG learners
* Added more tests => >80% code coverage
* Added `MeasureCompRisksBrierScore`, i.e. `msr("cmprsk.brier")` for fixed time point prediction error evaluation
* Use `survdistr` from CRAN

# mlr3cmprsk 0.0.4

* Added `LearnerCompRisksFineGray` via `cmprsk` R package
* Refactor `merge_cifs()` to `align_cifs()`
* Added test coverage report + badge
* Added example in `README`

# mlr3cmprsk 0.0.3

* Added `missings`, `importance`, and `selected_features` properties to `cmprsk.aalen`.
* Added support for `native_model()` in `cmprsk.aalen`
* CIF predictions for `cmprsk.aalen` are now at unique event times (rest can be
constantly interpolated).
* Minimum required `mlr3` version is now `1.4.0`.
* Added a noise feature to autotest tasks for improved testing.
* Improved documentation.

# mlr3cmprsk 0.0.2

* Use new `interp_cif()` function to interpolate CIF curves from `survdistr@0.0.2`

# mlr3cmprsk 0.0.1

* Initial transfer and update of code from `mlr3proba`.
* Fix compatibility with `mlr3` (1.3.0).
