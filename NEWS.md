# forestIPM (development version)

# forestIPM 1.0.1

* New `integration_method` argument in `control()` — choose between `"midpoint"` and `"gauss-legendre"` (default) quadrature for IPM kernel discretization. GL quadrature achieves higher accuracy with fewer mesh points for smooth integrands.

* New `n_gl` argument in `control()` — sets the number of Gauss-Legendre quadrature nodes (default 100).

* GL quadrature uses the Golub-Welsch algorithm (eigendecomposition of the symmetric tridiagonal Jacobi matrix) to compute nodes and weights — no external dependencies, implemented in base R `eigen()`.

## Improvements

* `mkKernel()` now uses per-column weight vectors (`weights * kernel_column`) instead of uniform `h * matrix(...)` scaling. For midpoint integration the result is identical; for GL quadrature the non-uniform weights are applied correctly.

* Replaced base R `eigen()` with C++ `Eigen::SelfAdjointEigenSolver` via RcppEigen for the Golub-Welsch eigendecomposition — faster node/weight computation for large `n_gl` values.

# forestIPM 1.0.0

Initial release of **forestIPM** — a Bayesian hierarchical Integral Projection Model (IPM)
for tree population dynamics in eastern North America, covering 31 species across 3
demographic model variants.

## New features

* New composable API with five typed S3 constructors:
  - `stand()` — initialise a forest stand from a data frame of trees (size in mm DBH, ≥ 127 mm threshold)
  - `species_model()` — select a species and demographic model variant with fuzzy-match suggestion on typos
  - `parameters()` — load vital-rate parameters by draw (`"mean"`, `"random"`, or integer index) with optional seed
  - `env_condition()` — supply climate inputs (MAT/MAP) as numeric scalars or time-varying `function(t)`
  - `control()` — configure simulation settings (years, delta_time, store_every, bin_width)

* Two IPM engines:
  - `lambda()` — computes asymptotic population growth rate (dominant eigenvalue) via C++ RcppEigen solver
  - `project()` — runs a timestep projection loop and returns a full `ipm_projection` object with lambda trajectories, stand series, and summary tibble

* `supported_species()` — returns a tibble of 33 eastern North America tree species with common names, French names, and model availability

* `plot.ipm_projection()` — three-panel visualisation via `type` argument dispatch:
  `"lambda"`, `"size_dist"`, `"lambda_vs_n"`, or `NULL` for all panels

* S3 print and summary methods for all six classes: `ipm_stand`, `ipm_spModel`, `ipm_parameters`, `ipm_env`, `ipm_control`, `ipm_projection`

## Performance improvements

* IPM kernel assembly (`mkKernel()`) is **1.4× faster** overall and the F matrix (recruitment) is **2.4× faster**:
  - Replaced sequential `outer()` loops with vectorised `rep(meshpts, times = n)` / `rep(meshpts, each = n)` expansion
  - Replaced `truncnorm::dtruncnorm()` with an equivalent `dnorm()` / `pnorm()` formula using base R, eliminating a hotspot that consumed 46% of inclusive profiling time
  - 100-year projection runs reduced from ~76 s to ~54 s

* Removed `truncnorm` package dependency (no longer needed after the above optimisation)

## Bug fixes

* Fixed `getEigenValues()` (C++ via RcppEigen): replaced `Eigen::SelfAdjointEigenSolver` (symmetric-only) with `Eigen::EigenSolver` returning the `.real()` component — IPM kernels are non-negative but non-symmetric, so the symmetric solver produced incorrect eigenvalues (#BUG-01)

* Fixed `init_pop()`: removed `exists('fct')` global environment check and replaced with local `fct <- 1` initialisation before the while-loop, preventing silent failures when the function ran in non-global scopes (#BUG-02)

* Fixed `getPars_sp()` and `pars_to_list()`: replaced deprecated `purrr::as_vector()` with `unlist(use.names = TRUE)`, preserving named-vector contracts used for downstream parameter indexing (#BUG-03)
