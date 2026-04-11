# Changelog

## mlr3cmprsk 0.0.5

- Refactored `MeasureCompRisksAUC`, added `cause_weights` parameter,
  renamed `time_horizon` to `time`
- Added parameter tests for AJ and FG learners
- Added more tests =\> \>80% code coverage
- Added `MeasureCompRisksBrierScore`, i.e. `msr("cmprsk.brier")` for
  fixed time point prediction error evaluation
- Use `survdistr` from CRAN

## mlr3cmprsk 0.0.4

- Added `LearnerCompRisksFineGray` via `cmprsk` R package
- Refactor `merge_cifs()` to `align_cifs()`
- Added test coverage report + badge
- Added example in `README`

## mlr3cmprsk 0.0.3

- Added `missings`, `importance`, and `selected_features` properties to
  `cmprsk.aalen`.
- Added support for `native_model()` in `cmprsk.aalen`
- CIF predictions for `cmprsk.aalen` are now at unique event times (rest
  can be constantly interpolated).
- Minimum required `mlr3` version is now `1.4.0`.
- Added a noise feature to autotest tasks for improved testing.
- Improved documentation.

## mlr3cmprsk 0.0.2

- Use new `interp_cif()` function to interpolate CIF curves from
  `survdistr@0.0.2`

## mlr3cmprsk 0.0.1

- Initial transfer and update of code from `mlr3proba`.
- Fix compatibility with `mlr3` (1.3.0).
