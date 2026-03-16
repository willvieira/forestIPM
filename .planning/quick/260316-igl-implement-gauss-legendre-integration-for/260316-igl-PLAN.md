---
phase: quick-260316-igl
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - R/gauss_legendre.R
  - R/stand.R
  - R/kernel.R
  - R/control.R
  - tests/testthat/test-gauss-legendre.R
  - tests/testthat/fixtures/lambda_baseline.rds
  - tests/testthat/fixtures/project_baseline.rds
autonomous: true
requirements: [IGL-01]

must_haves:
  truths:
    - "mkKernel integrates using Gauss-Legendre quadrature nodes and weights instead of uniform midpoint rule"
    - "control() accepts integration_method parameter ('midpoint' or 'gauss-legendre') with 'midpoint' as default for backward compatibility"
    - "GL quadrature with sufficient nodes produces lambda values that converge toward the same result as midpoint with bin_width=1"
    - "Existing tests pass unchanged when integration_method='midpoint' (default)"
  artifacts:
    - path: "R/gauss_legendre.R"
      provides: "Gauss-Legendre nodes and weights computation on arbitrary [a, b] interval"
      exports: [".gl_nodes_weights"]
    - path: "R/stand.R"
      provides: "Updated .stand_to_nvec that builds GL-based mesh when integration_method='gauss-legendre'"
      contains: "gauss.legendre"
    - path: "R/kernel.R"
      provides: "Updated mkKernel that uses per-column GL weights instead of uniform h"
      contains: "weights"
    - path: "tests/testthat/test-gauss-legendre.R"
      provides: "Unit tests for GL integration accuracy and convergence"
      min_lines: 30
  key_links:
    - from: "R/stand.R"
      to: "R/gauss_legendre.R"
      via: ".gl_nodes_weights() call in .stand_to_nvec"
      pattern: "\\.gl_nodes_weights"
    - from: "R/kernel.R"
      to: "Nvec_intra$weights"
      via: "per-column weight vector replaces uniform h"
      pattern: "weights"
    - from: "R/control.R"
      to: "R/stand.R"
      via: "integration_method field propagated through lambda/project"
      pattern: "integration_method"
---

<objective>
Replace the midpoint rule integration in the IPM kernel discretization with Gauss-Legendre (GL) quadrature.

Purpose: GL quadrature achieves much higher accuracy with fewer mesh points than midpoint rule. For smooth integrands (which the growth/survival/recruitment kernels are), GL with n nodes is exact for polynomials of degree 2n-1, meaning fewer mesh points can achieve the same or better accuracy. This enables faster kernel builds and eigenvalue computation without sacrificing numerical precision.

Output: GL integration infrastructure in R/gauss_legendre.R, updated mesh construction in R/stand.R, updated kernel assembly in R/kernel.R, control parameter for method selection, and convergence tests.
</objective>

<execution_context>
@/Users/wvieira/.claude/get-shit-done/workflows/execute-plan.md
@/Users/wvieira/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@R/kernel.R
@R/stand.R
@R/control.R
@R/lambda.R
@R/project.R
@tests/testthat/test-workflow.R
@tests/testthat/test-regression-baselines.R

<interfaces>
<!-- Key types and contracts the executor needs -->

From R/stand.R (.stand_to_nvec):
```r
# Current mesh structure (list returned per species):
# list(meshpts = numeric(m), Nvec = numeric(m), h = scalar)
# meshpts: midpoints at 127 + (i - 0.5) * bin_w
# h: uniform bin width (= bin_w from control())
# Nvec: tree counts per bin

# After GL: add $weights field
# list(meshpts = numeric(m), Nvec = numeric(m), h = bin_w_or_NA, weights = numeric(m))
```

From R/kernel.R (mkKernel):
```r
mkKernel = function(Nvec_intra, Nvec_inter, delta_time, plotSize, Temp, Prec, pars, plot_random)
# Currently: P <- h * matrix(P_vals, nrow = n, ncol = n)
# h is uniform scalar from Nvec_intra$h
# After GL: each column j weighted by weights[j] (integration over size_t0 dimension)
```

From R/control.R:
```r
control <- function(years = 100, delta_time = 1, store_every = 1, bin_width = 1,
                    compute_lambda = FALSE, progress = TRUE)
# Need to add: integration_method = c("midpoint", "gauss-legendre"), n_gl = 50L
```

From R/lambda.R and R/project.R:
```r
# Both call .stand_to_nvec(stand, species, pars, bin_w)
# Must also pass integration_method and n_gl through to .stand_to_nvec
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Implement GL quadrature infrastructure and update mesh construction</name>
  <files>R/gauss_legendre.R, R/control.R, R/stand.R, tests/testthat/test-gauss-legendre.R</files>
  <behavior>
    - Test 1: .gl_nodes_weights(n=3, a=0, b=1) returns nodes/weights that exactly integrate x^0..x^5 (2*3-1=5)
    - Test 2: .gl_nodes_weights(n=5, a=127, b=500) returns n nodes all within [127, 500] and weights summing to (500-127)
    - Test 3: .stand_to_nvec with integration_method="gauss-legendre" returns mesh with $weights vector of length n_gl
    - Test 4: .stand_to_nvec with integration_method="midpoint" (default) returns mesh with $weights = rep(h, m) for backward compat
    - Test 5: control(integration_method="gauss-legendre", n_gl=50) stores both fields; default is "midpoint"
    - Test 6: control(integration_method="invalid") raises error
  </behavior>
  <action>
    1. Create R/gauss_legendre.R with internal function .gl_nodes_weights(n, a, b):
       - Use the Golub-Welsch algorithm: construct the symmetric tridiagonal Jacobi matrix for Legendre polynomials on [-1,1]. The diagonal is zero; the subdiagonal beta_k = k / sqrt(4*k^2 - 1). Eigendecompose with eigen(). Nodes = eigenvalues, weights = 2 * (first component of each eigenvector)^2. Then map from [-1,1] to [a,b]: nodes_ab = (b+a)/2 + (b-a)/2 * nodes, weights_ab = (b-a)/2 * weights.
       - Return list(nodes = numeric(n), weights = numeric(n)) sorted by node value.
       - Add roxygen @keywords internal.

    2. Update R/control.R:
       - Add integration_method = "midpoint" and n_gl = 50L parameters to control().
       - Validate integration_method is one of "midpoint", "gauss-legendre".
       - Validate n_gl is a positive integer (only used when integration_method="gauss-legendre").
       - Update new_ipm_control and validate_ipm_control accordingly.
       - Update print and summary methods to show integration_method.

    3. Update R/stand.R .stand_to_nvec():
       - Add integration_method and n_gl parameters (defaulting to "midpoint" and 50L).
       - When integration_method="midpoint": keep existing logic, but add $weights = rep(bin_w, m) to the returned list for uniform interface.
       - When integration_method="gauss-legendre": call .gl_nodes_weights(n_gl, a=127, b=lmax) to get nodes and weights. Set meshpts = gl$nodes, weights = gl$weights. Nvec = rep(0, n_gl). h = NA_real_ (not meaningful for GL).
       - dbh_to_sizeDist must still work: for GL, bin observed trees into nearest GL node using findInterval or which.min distance.

    4. Update lambda.R and project.R to pass integration_method and n_gl from ctrl to .stand_to_nvec():
       - In lambda(): add ctrl$integration_method and ctrl$n_gl to .stand_to_nvec() call.
       - In project(): same propagation.

    5. Write tests/testthat/test-gauss-legendre.R with the behavior tests above.
  </action>
  <verify>
    <automated>cd /Users/wvieira/GitHub/forest-IPM && Rscript -e "devtools::test(filter='gauss-legendre')"</automated>
  </verify>
  <done>GL nodes/weights function implemented and tested; control() accepts integration_method; .stand_to_nvec builds GL mesh; all GL unit tests pass</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Update mkKernel to use per-node weights and validate convergence</name>
  <files>R/kernel.R, tests/testthat/test-gauss-legendre.R, tests/testthat/fixtures/lambda_baseline.rds, tests/testthat/fixtures/project_baseline.rds</files>
  <behavior>
    - Test 1: mkKernel with midpoint method produces identical output to current behavior (regression baselines unchanged at 1e-10)
    - Test 2: lambda() with GL n_gl=200 produces value within 1e-4 of midpoint bin_width=1 result for ABIBAL
    - Test 3: GL lambda converges as n_gl increases: |lambda(n=100) - lambda(n=200)| < |lambda(n=50) - lambda(n=100)|
    - Test 4: K matrix from GL is square with dimension n_gl x n_gl
    - Test 5: K matrix column sums are non-negative (valid transition kernel)
  </behavior>
  <action>
    1. Update R/kernel.R mkKernel():
       - Extract weights from Nvec_intra: weights <- Nvec_intra$weights (this is either rep(h, n) for midpoint or GL weights).
       - Replace `P <- h * matrix(P_vals, nrow = n, ncol = n)` with column-wise weighting:
         `P <- matrix(P_vals, nrow = n, ncol = n) * rep(weights, each = n)`
         This multiplies each column j by weights[j], because column j corresponds to integration over size_t0 = meshpts[j].
       - Same for F matrix: `F <- matrix(F_vals, nrow = n, ncol = n) * rep(weights, each = n)`
       - Remove the standalone `h = Nvec_intra$h` line at top (h is now absorbed into weights).
       - IMPORTANT: For midpoint method, $weights = rep(h, m), so `rep(weights, each=n)` produces the same result as `h * matrix(...)`. This preserves backward compatibility exactly.

    2. Regenerate regression baselines:
       - The baseline fixtures must be regenerated because the code path changed (even though midpoint results are numerically identical, the object structure of Nvec now includes $weights).
       - Run the baseline generation script or inline: compute lambda and project with QUERUB using default midpoint method, save to fixtures/.

    3. Add convergence tests to tests/testthat/test-gauss-legendre.R:
       - Test that GL with increasing n_gl converges toward midpoint bin_width=1 result.
       - Test lambda values are finite and positive with GL method.
       - These tests use ABIBAL (bundled params, no skip_on_ci needed).

    4. Run full test suite to confirm no regressions:
       - test-workflow.R must pass (all use default midpoint).
       - test-regression-baselines.R must pass with regenerated baselines.
       - test-gauss-legendre.R must pass.
  </action>
  <verify>
    <automated>cd /Users/wvieira/GitHub/forest-IPM && Rscript -e "devtools::test()"</automated>
  </verify>
  <done>mkKernel uses per-node weights; midpoint regression baselines pass at 1e-10; GL convergence tests demonstrate accuracy; full test suite green</done>
</task>

</tasks>

<verification>
1. `Rscript -e "devtools::test()"` -- all tests pass including workflow, regression, and GL tests
2. `Rscript -e "devtools::check(args='--no-manual')"` -- no new ERRORs or WARNINGs
3. Manual verification: lambda(ABIBAL, midpoint) equals lambda(ABIBAL, GL n=200) within 1e-4
</verification>

<success_criteria>
- GL quadrature nodes/weights computed via Golub-Welsch (no external dependency)
- control() exposes integration_method with backward-compatible "midpoint" default
- mkKernel uses $weights vector for integration (works for both midpoint and GL)
- Existing midpoint-based tests pass without modification (default behavior unchanged)
- GL convergence test demonstrates accuracy improvement with increasing n_gl
- No new package dependencies added
</success_criteria>

<output>
After completion, create `.planning/quick/260316-igl-implement-gauss-legendre-integration-for/260316-igl-SUMMARY.md`
</output>
