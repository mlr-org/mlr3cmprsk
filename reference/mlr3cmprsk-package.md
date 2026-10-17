# mlr3cmprsk: Competing Risks Machine Learning for 'mlr3'

Provides a unified interface for right-censored competing risks tasks in
'mlr3'.

## Package Options

The following options control optional predicted CIF diagnostics and
default to `FALSE`. Set them with
[`options()`](https://rdrr.io/r/base/options.html) to enable diagnostics
package-wide.

- `mlr3cmprsk.warn_cif_sum`: Warn with class
  `Mlr3WarningCIFSumExceedsOne` when predictions contain cause-specific
  CIFs whose sum exceeds 1 (allowing numerical tolerance). Predictions
  are retained without changing their probabilities. Enable by using
  `options(mlr3cmprsk.warn_cif_sum = TRUE)`.

- `mlr3cmprsk.warn_cif_extrapolation`: Warn with class
  `Mlr3WarningCIFExtrapolation` when a measure evaluates times after a
  scored cause's final CIF anchor. CIFs are constantly extrapolated
  after the final anchor. One warning lists all affected causes per
  scoring call. Enable by using
  `options(mlr3cmprsk.warn_cif_extrapolation = TRUE)`.

## See also

Useful links:

- <https://mlr3cmprsk.mlr-org.com>

- <https://github.com/mlr-org/mlr3cmprsk>

- Report bugs at <https://github.com/mlr-org/mlr3cmprsk/issues>

## Author

**Maintainer**: John Zobolas <bblodfon@gmail.com>
([ORCID](https://orcid.org/0000-0002-3609-8674))

Authors:

- John Zobolas <bblodfon@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-3609-8674))

- Andreas Bender <bender.andreas@lmu.de>
  ([ORCID](https://orcid.org/0000-0001-5628-8611))

Other contributors:

- Andrzej Galecki <agalecki@umich.edu>
  ([ORCID](https://orcid.org/0000-0003-1542-4001)) \[contributor\]
