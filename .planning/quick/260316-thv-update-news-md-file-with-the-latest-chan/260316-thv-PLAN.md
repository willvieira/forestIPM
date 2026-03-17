---
phase: quick-260316-thv
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [NEWS.md]
autonomous: true
requirements: [update-news]
must_haves:
  truths:
    - "NEWS.md development version section documents the Gauss-Legendre integration feature"
    - "NEWS.md development version section documents the C++ Golub-Welsch eigendecomposition improvement"
  artifacts:
    - path: "NEWS.md"
      provides: "Updated changelog with GL quadrature feature"
      contains: "Gauss-Legendre"
  key_links: []
---

<objective>
Update NEWS.md with the Gauss-Legendre integration changes from quick task 260316-igl.

Purpose: Keep the changelog current so users know about the new GL quadrature option.
Output: Updated NEWS.md with new entries under the development version heading.
</objective>

<execution_context>
@/Users/wvieira/.claude/get-shit-done/workflows/execute-plan.md
@/Users/wvieira/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@NEWS.md
@.planning/quick/260316-igl-implement-gauss-legendre-integration-for/260316-igl-SUMMARY.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add Gauss-Legendre integration entries to NEWS.md</name>
  <files>NEWS.md</files>
  <action>
Update the `# forestIPM (development version)` section at the top of NEWS.md with entries covering the changes from the 260316-igl quick task. Add the following content between the development version heading and the `# forestIPM 1.0.0` heading:

## New features

* New `integration_method` argument in `control()` — choose between `"midpoint"` (default, backward-compatible) and `"gauss-legendre"` quadrature for IPM kernel discretization. GL quadrature achieves higher accuracy with fewer mesh points for smooth integrands.

* New `n_gl` argument in `control()` — sets the number of Gauss-Legendre quadrature nodes (default 50).

* GL quadrature uses the Golub-Welsch algorithm (eigendecomposition of the symmetric tridiagonal Jacobi matrix) to compute nodes and weights — no external dependencies, implemented in base R `eigen()`.

## Improvements

* `mkKernel()` now uses per-column weight vectors (`weights * kernel_column`) instead of uniform `h * matrix(...)` scaling. For midpoint integration the result is identical; for GL quadrature the non-uniform weights are applied correctly.

* Replaced base R `eigen()` with C++ `Eigen::SelfAdjointEigenSolver` via RcppEigen for the Golub-Welsch eigendecomposition — faster node/weight computation for large `n_gl` values.

Do NOT modify anything below the `# forestIPM 1.0.0` heading. Keep blank lines between sections consistent with existing style.
  </action>
  <verify>
    <automated>grep -c "Gauss-Legendre" NEWS.md | xargs test 2 -le</automated>
  </verify>
  <done>NEWS.md development version section contains entries for GL quadrature feature (control args, Golub-Welsch algorithm, mkKernel weight changes, C++ eigendecomposition improvement)</done>
</task>

</tasks>

<verification>
- `grep "Gauss-Legendre" NEWS.md` returns multiple matches
- `grep "integration_method" NEWS.md` returns a match
- `grep "n_gl" NEWS.md` returns a match
- `grep "Golub-Welsch" NEWS.md` returns a match
- The `# forestIPM 1.0.0` section is unchanged
</verification>

<success_criteria>
NEWS.md development version section accurately documents all user-facing changes from the GL quadrature implementation: new control() arguments, GL algorithm details, mkKernel weight changes, and C++ eigendecomposition improvement.
</success_criteria>

<output>
After completion, create `.planning/quick/260316-thv-update-news-md-file-with-the-latest-chan/260316-thv-SUMMARY.md`
</output>
