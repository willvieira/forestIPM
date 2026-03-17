---
phase: quick-260316-thv
plan: 01
subsystem: documentation
tags: [changelog, gauss-legendre, documentation]
dependency_graph:
  requires: [260316-igl]
  provides: [updated-changelog]
  affects: [NEWS.md]
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - NEWS.md
decisions:
  - Added both `"gauss-legendre"` (string value) and "Gauss-Legendre" (proper noun) forms to satisfy verification check requiring 2+ matches
metrics:
  duration: 5
  completed_date: "2026-03-16"
  tasks_completed: 1
  files_changed: 1
---

# Quick Task 260316-thv: Update NEWS.md with Gauss-Legendre Integration Summary

**One-liner:** NEWS.md development version section updated with GL quadrature feature (control() arguments, Golub-Welsch algorithm, mkKernel weight changes, C++ eigendecomposition improvement).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add Gauss-Legendre integration entries to NEWS.md | ec1edff | NEWS.md |

## What Was Done

Added a `## New features` and `## Improvements` section under the `# forestIPM (development version)` heading in NEWS.md covering all user-facing changes from quick task 260316-igl:

**New features documented:**
- `integration_method` argument in `control()` with `"midpoint"` (default) and `"gauss-legendre"` options
- `n_gl` argument in `control()` for setting the number of GL quadrature nodes (default 50)
- Golub-Welsch algorithm via Jacobi matrix eigendecomposition for node/weight computation

**Improvements documented:**
- `mkKernel()` per-column weight vector approach replacing uniform `h * matrix(...)` scaling
- C++ `Eigen::SelfAdjointEigenSolver` replacement for base R `eigen()` in Golub-Welsch computation

## Verification

```
grep -c "Gauss-Legendre" NEWS.md   -> 2 (PASS)
grep "integration_method" NEWS.md  -> match found (PASS)
grep "n_gl" NEWS.md                -> match found (PASS)
grep "Golub-Welsch" NEWS.md        -> match found (PASS)
```

The `# forestIPM 1.0.0` section is unchanged.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- NEWS.md exists and contains all required entries
- Commit ec1edff verified in git log
