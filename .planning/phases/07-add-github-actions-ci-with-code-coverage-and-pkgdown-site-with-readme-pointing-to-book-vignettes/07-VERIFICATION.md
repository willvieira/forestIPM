---
phase: 07-add-github-actions-ci-with-code-coverage-and-pkgdown-site-with-readme-pointing-to-book-vignettes
verified: 2026-03-13T00:00:00Z
status: human_needed
score: 11/13 must-haves verified
re_verification: false
human_verification:
  - test: "Confirm test coverage meets the >= 70% target"
    expected: "codecov.io reports >= 70% line coverage for R code after first CI push"
    why_human: "Coverage percentage requires running the full test suite in CI and uploading to codecov.io — cannot be measured locally without running the workflow"
  - test: "Confirm GitHub Pages site is accessible at https://willvieira.github.io/forest-IPM/"
    expected: "Site loads with Bootstrap 5 materia theme, Book navbar link, and reference page listing all 11 exported functions"
    why_human: "GitHub Pages must be manually enabled in repository Settings > Pages > Source = gh-pages branch; the workflow deploys the content but the Pages source setting requires a human action"
---

# Phase 7: GitHub Actions CI, Code Coverage, pkgdown Site, README Verification Report

**Phase Goal:** Add GitHub Actions CI with code coverage and pkgdown site with README pointing to book vignettes
**Verified:** 2026-03-13
**Status:** human_needed (all automated checks pass; 2 items require human confirmation)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | R CMD check runs automatically on every push and pull request to main | VERIFIED | `.github/workflows/R-CMD-check.yaml` triggers on `push` + `pull_request` to `[main, master]`; uses `r-lib/actions/check-r-package@v2` |
| 2 | Code coverage is measured and uploaded to codecov.io on every push and pull request | VERIFIED | `.github/workflows/test-coverage.yaml` runs `covr::package_coverage()` + `covr::to_cobertura()` and uploads via `codecov/codecov-action@v5` |
| 3 | CI runs only on Ubuntu with R release (no macOS, no Windows) | VERIFIED | Both CI workflows specify `runs-on: ubuntu-latest` only; no matrix, no macOS/Windows rows confirmed by grep |
| 4 | pkgdown site builds with Bootstrap 5 materia theme | VERIFIED | `_pkgdown.yml` contains `bootstrap: 5` and `bootswatch: materia` |
| 5 | pkgdown site deploys automatically to GitHub Pages gh-pages branch on push to main | VERIFIED | `pkgdown.yaml` deploys with `JamesIves/github-pages-deploy-action@v4.5.0` to `branch: gh-pages`; deploy step gated on `github.event_name != 'pull_request'` |
| 6 | pkgdown navbar includes a 'Book' link pointing to the book documentation site | VERIFIED | `_pkgdown.yml` navbar component `book` with `href: https://willvieira.github.io/book_forest-demography-IPM/` confirmed |
| 7 | pkgdown reference groups all 11 exported functions into IPM Constructors, IPM Engines, and Utilities | VERIFIED | `_pkgdown.yml` reference section lists all 11 functions across three titled groups |
| 8 | README.md shows two badges at the top: R-CMD-check build status and codecov coverage | VERIFIED | README.md lines 3-4 contain `R-CMD-check.yaml/badge.svg` badge and `codecov.io/github/willvieira/forest-IPM/graph/badge.svg` badge |
| 9 | README.md has a prominent link to the book documentation site | VERIFIED | README.md links to `https://willvieira.github.io/book_forest-demography-IPM/` in the Documentation section (appears twice) |
| 10 | README.md includes install instructions using devtools::install_github | VERIFIED | README.md contains `devtools::install_github("willvieira/forest-IPM")` in the Installation section |
| 11 | README.md contains minimal prose only — no code blocks, no API walkthrough | VERIFIED | README.md has a single code block (install command only), no API walkthrough or multi-step example |
| 12 | DESCRIPTION declares covr and pkgdown in Suggests | VERIFIED | DESCRIPTION `Suggests:` field declares `covr`, `pkgdown`, `testthat (>= 3.0.0)` |
| 13 | DESCRIPTION declares URL field so pkgdown github navbar component renders correctly | VERIFIED | DESCRIPTION `URL:` field contains both GitHub repo and pkgdown site URLs |

**Score:** 13/13 truths verified by static analysis. 2 truths require human confirmation (coverage threshold, live site).

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/R-CMD-check.yaml` | R CMD check job on ubuntu-latest | VERIFIED | Exists, 30 lines, contains `check-r-package@v2`, triggers on push + PR |
| `.github/workflows/test-coverage.yaml` | covr + codecov upload job on ubuntu-latest | VERIFIED | Exists, 41 lines, contains `covr::package_coverage()`, `to_cobertura()`, `codecov-action@v5` |
| `_pkgdown.yml` | pkgdown config with Bootstrap 5, materia, book navbar, reference grouping | VERIFIED | Exists, 37 lines, contains `bootswatch: materia`, book navbar, 11 functions in 3 groups |
| `.github/workflows/pkgdown.yaml` | pkgdown CI build + gh-pages deploy workflow | VERIFIED | Exists, 48 lines, contains `JamesIves/github-pages-deploy-action@v4.5.0`, deploys to `gh-pages` |
| `README.md` | Package landing page with badges, book link, install instructions | VERIFIED | Exists, 26 lines, contains both badges, book link, install block — no placeholder text |
| `DESCRIPTION` | Updated package manifest with Suggests and URL fields | VERIFIED | Exists, contains `Suggests:` with covr/pkgdown/testthat and `URL:` with both site URLs |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `.github/workflows/R-CMD-check.yaml` | `r-lib/actions/check-r-package@v2` | `uses:` directive | WIRED | Line 26 confirms `uses: r-lib/actions/check-r-package@v2` |
| `.github/workflows/test-coverage.yaml` | `codecov/codecov-action@v5` | `uses:` directive | WIRED | Line 34 confirms `uses: codecov/codecov-action@v5` |
| `_pkgdown.yml` | `https://willvieira.github.io/forest-IPM/` | `url:` field | WIRED | Line 1 is `url: https://willvieira.github.io/forest-IPM/` |
| `.github/workflows/pkgdown.yaml` | `gh-pages` branch | `JamesIves/github-pages-deploy-action@v4.5.0` | WIRED | Line 43 confirms deploy action; `branch: gh-pages` on line 46 |
| `README.md` | `.github/workflows/R-CMD-check.yaml` | badge URL referencing workflow filename | WIRED | Line 3 badge URL contains `R-CMD-check.yaml/badge.svg` |
| `README.md` | `https://willvieira.github.io/book_forest-demography-IPM/` | markdown link | WIRED | Lines 12 and 25 both link to the book URL |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| TST-01 | 07-01, 07-03 | GitHub Actions CI matrix (R version x OS) running on push | PARTIAL | CI runs on push — confirmed. However, the requirement says "matrix (R version x OS)" while the plan deliberately chose Linux-only / R-release-only. CONTEXT.md and the plan explicitly document this as a deliberate scope reduction for simplicity. CI runs, but without a matrix. |
| TST-02 | 07-01, 07-03 | Test coverage report (covr) with >= 70% line coverage | NEEDS HUMAN | Coverage infrastructure is fully wired (covr + codecov-action). Actual coverage % cannot be verified without running CI and uploading to codecov.io. Needs human confirmation after first successful CI run. |
| DOC-04 | 07-02, 07-03 | pkgdown site with function reference and vignette rendered | PARTIAL | Function reference is fully configured (11 functions in 3 groups). The requirement mentions "vignette rendered" but no vignettes exist — the plan explicitly decided to replace vignettes with the book link. pkgdown site config and deploy workflow are complete. The vignette component of DOC-04 is intentionally deferred to the companion book. |

**Orphaned requirements in traceability table:** TST-01, TST-02, DOC-04 are defined in REQUIREMENTS.md but the traceability table (which currently ends at DOC-02 / Phase 4) does not map them to Phase 7. This is a documentation gap in REQUIREMENTS.md, not an implementation gap.

---

### Anti-Patterns Found

None. Grep over all 6 phase artifacts found no TODO, FIXME, XXX, HACK, or placeholder comments.

---

### Human Verification Required

#### 1. Code Coverage Threshold (TST-02)

**Test:** Push a commit to `master`/`main`, wait for the `test-coverage.yaml` workflow to complete, then visit `https://app.codecov.io/github/willvieira/forest-IPM`
**Expected:** codecov.io reports >= 70% line coverage for R source files. The README codecov badge changes from "unknown" to a percentage.
**Why human:** Coverage percentage requires running the full test suite in a live CI environment and uploading the Cobertura XML to codecov.io. Cannot be measured by static analysis. Requires activating the repo on codecov.io first.

#### 2. pkgdown Site Live Access

**Test:** After enabling GitHub Pages (Settings > Pages > Source = "Deploy from a branch" > Branch = `gh-pages` / `/(root)`), navigate to `https://willvieira.github.io/forest-IPM/`
**Expected:** Site loads with Bootstrap 5 materia theme, navbar shows "Book" link pointing to `https://willvieira.github.io/book_forest-demography-IPM/`, reference page lists all 11 exported functions in 3 groups.
**Why human:** GitHub Pages must be manually enabled in repository settings. The deploy workflow populates the `gh-pages` branch, but the Pages source setting requires a one-time human action. The site returns 404 until this is done.

---

### Gaps Summary

No blocking gaps. All 6 artifacts exist, are substantive (not stubs), and all 6 key links are verified as wired.

Two observations regarding requirement wording vs. implementation scope:

1. **TST-01 matrix scope:** The requirement says "CI matrix (R version x OS)" but the plan deliberately chose a single runner (ubuntu-latest, R release). This is a documented deliberate decision, not an oversight. The CI does run on push. The team should decide whether to update TST-01 to reflect the simplified scope, or add matrix jobs in a future phase.

2. **DOC-04 vignette component:** The requirement says "pkgdown site with function reference and vignette rendered." No vignettes exist — the plan deliberately replaced them with a book link. The function reference portion is fully implemented. The team should decide whether to update DOC-04 to remove the vignette clause, or add a vignette in a future phase.

Both observations are scope decisions documented in the plan, not implementation failures.

---

_Verified: 2026-03-13_
_Verifier: Claude (gsd-verifier)_
