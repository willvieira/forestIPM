# Changelog

## forestIPM (development version)

## forestIPM 1.0.1

- New `integration_method` argument in
  [`control()`](https://willvieira.github.io/forestIPM/reference/control.md)
  — choose between `"midpoint"` and `"gauss-legendre"` (default)
  quadrature for IPM kernel discretization. GL quadrature achieves
  higher accuracy with fewer mesh points for smooth integrands.

- New `n_gl` argument in
  [`control()`](https://willvieira.github.io/forestIPM/reference/control.md)
  — sets the number of Gauss-Legendre quadrature nodes (default 100).

- GL quadrature uses the Golub-Welsch algorithm (eigendecomposition of
  the symmetric tridiagonal Jacobi matrix) to compute nodes and weights
  — no external dependencies, implemented in base R
  [`eigen()`](https://rdrr.io/r/base/eigen.html).

### Improvements

- [`mkKernel()`](https://willvieira.github.io/forestIPM/reference/mkKernel.md)
  now uses per-column weight vectors (`weights * kernel_column`) instead
  of uniform `h * matrix(...)` scaling. For midpoint integration the
  result is identical; for GL quadrature the non-uniform weights are
  applied correctly.

- Replaced base R [`eigen()`](https://rdrr.io/r/base/eigen.html) with
  C++ `Eigen::SelfAdjointEigenSolver` via RcppEigen for the Golub-Welsch
  eigendecomposition — faster node/weight computation for large `n_gl`
  values.

- `ipm_lambda` and `ipm_projection` objects now store the full `stand`,
  `env`, `pars`, and `ctrl` objects in their `conditions` attribute
  instead of individual scalar fields — enables complete reproducibility
  from a saved result.

- [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) for `ipm_lambda`
  and `ipm_projection` now correctly display time-varying climate inputs
  as `"function(t)"` when `env$MAT` or `env$MAP` is a function.

- Added Lean 4 formal mathematical proofs for core IPM components:
  Gauss-Legendre quadrature, midpoint rule, growth/survival/ingrowth
  vital rates, kernel assembly, asymptotic lambda, competition, climate
  scaling, and community dynamics.

### Bug fixes

- Fixed
  [`lambda()`](https://willvieira.github.io/forestIPM/reference/lambda.md):
  building size distributions now uses only the focal species instead of
  the union of all species in the stand — single-species models no
  longer include extraneous species in the mesh computation (#BUG-04).

- Fixed
  [`project()`](https://willvieira.github.io/forestIPM/reference/project.md)
  with `on_missing = "static"`: static competitors now correctly freeze
  at their initial sizes throughout the projection instead of being
  incorrectly dropped (#BUG-05).

- Removed a null-guard in
  [`parameters()`](https://willvieira.github.io/forestIPM/reference/parameters.md)
  that silently returned empty parameter lists when species data was not
  found —
  [`parameters()`](https://willvieira.github.io/forestIPM/reference/parameters.md)
  now raises an informative error immediately (#BUG-06).

### Tests

- Added tests for
  [`set_random_effects()`](https://willvieira.github.io/forestIPM/reference/set_random_effects.md)
  covering draw type resolution, seed reproducibility, and random effect
  application across species.

- Added integration test for two-species interactions, verifying that
  interspecific competition affects lambda as expected.

## forestIPM 1.0.0

Initial release of **forestIPM** — a Bayesian hierarchical Integral
Projection Model (IPM) for tree population dynamics in eastern North
America, covering 31 species across 3 demographic model variants.

### New features

- New composable API with five typed S3 constructors:

  - [`stand()`](https://willvieira.github.io/forestIPM/reference/stand.md)
    — initialise a forest stand from a data frame of trees (size in mm
    DBH, ≥ 127 mm threshold)
  - [`species_model()`](https://willvieira.github.io/forestIPM/reference/species_model.md)
    — select a species and demographic model variant with fuzzy-match
    suggestion on typos
  - [`parameters()`](https://willvieira.github.io/forestIPM/reference/parameters.md)
    — load vital-rate parameters by draw (`"mean"`, `"random"`, or
    integer index) with optional seed
  - [`env_condition()`](https://willvieira.github.io/forestIPM/reference/env_condition.md)
    — supply climate inputs (MAT/MAP) as numeric scalars or time-varying
    `function(t)`
  - [`control()`](https://willvieira.github.io/forestIPM/reference/control.md)
    — configure simulation settings (years, delta_time, store_every,
    bin_width)

- Two IPM engines:

  - [`lambda()`](https://willvieira.github.io/forestIPM/reference/lambda.md)
    — computes asymptotic population growth rate (dominant eigenvalue)
    via C++ RcppEigen solver
  - [`project()`](https://willvieira.github.io/forestIPM/reference/project.md)
    — runs a timestep projection loop and returns a full
    `ipm_projection` object with lambda trajectories, stand series, and
    summary tibble

- [`supported_species()`](https://willvieira.github.io/forestIPM/reference/supported_species.md)
  — returns a tibble of 33 eastern North America tree species with
  common names, French names, and model availability

- [`plot.ipm_projection()`](https://willvieira.github.io/forestIPM/reference/plot.ipm_projection.md)
  — three-panel visualisation via `type` argument dispatch: `"lambda"`,
  `"size_dist"`, `"lambda_vs_n"`, or `NULL` for all panels

- S3 print and summary methods for all six classes: `ipm_stand`,
  `ipm_spModel`, `ipm_parameters`, `ipm_env`, `ipm_control`,
  `ipm_projection`

### Performance improvements

- IPM kernel assembly
  ([`mkKernel()`](https://willvieira.github.io/forestIPM/reference/mkKernel.md))
  is **1.4× faster** overall and the F matrix (recruitment) is **2.4×
  faster**:
  - Replaced sequential [`outer()`](https://rdrr.io/r/base/outer.html)
    loops with vectorised `rep(meshpts, times = n)` /
    `rep(meshpts, each = n)` expansion
  - Replaced `truncnorm::dtruncnorm()` with an equivalent
    [`dnorm()`](https://rdrr.io/r/stats/Normal.html) /
    [`pnorm()`](https://rdrr.io/r/stats/Normal.html) formula using base
    R, eliminating a hotspot that consumed 46% of inclusive profiling
    time
  - 100-year projection runs reduced from ~76 s to ~54 s
- Removed `truncnorm` package dependency (no longer needed after the
  above optimisation)

### Bug fixes

- Fixed `getEigenValues()` (C++ via RcppEigen): replaced
  `Eigen::SelfAdjointEigenSolver` (symmetric-only) with
  `Eigen::EigenSolver` returning the `.real()` component — IPM kernels
  are non-negative but non-symmetric, so the symmetric solver produced
  incorrect eigenvalues (#BUG-01)

- Fixed `init_pop()`: removed `exists('fct')` global environment check
  and replaced with local `fct <- 1` initialisation before the
  while-loop, preventing silent failures when the function ran in
  non-global scopes (#BUG-02)

- Fixed `getPars_sp()` and `pars_to_list()`: replaced deprecated
  [`purrr::as_vector()`](https://purrr.tidyverse.org/reference/as_vector.html)
  with `unlist(use.names = TRUE)`, preserving named-vector contracts
  used for downstream parameter indexing (#BUG-03)
