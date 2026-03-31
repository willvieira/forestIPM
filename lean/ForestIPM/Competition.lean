import Mathlib

/-!
# Competition (Basal Area)

Formalizes the basal area computations from `R/BasalArea_competition.R`.

## Individual basal area

The R code (`size_to_BAind`) converts a tree's diameter at breast height (DBH) `d`
in millimetres to its cross-sectional area in m²:

```r
size_to_BAind <- function(mesh) pi * (mesh / 2 * 1e-3)^2
```

That is: `BA_ind(d) = π · (d / 2 · 10⁻³)² = π · (d / 2000)²`.

## Plot-level basal area

The R code (`size_to_BAplot`) aggregates individual basal areas to m²/ha:

```r
size_to_BAplot <- function(N, plot_size)
  sum(size_to_BAind(N$meshpts) * N$Nvec * 1e4 / plot_size)
```

For a discrete size distribution `(d_i, n_i)` and plot area `A` (m²):

  `BA_plot = (10000 / A) · Σ_i BA_ind(d_i) · n_i`

## Main results

- `baInd_nonneg`        : Basal area is non-negative.
- `baInd_pos`           : Strictly positive for positive diameter.
- `baInd_formula_equiv` : The R expression `π·(d/2·1e-3)²` equals `π·(d/2000)²`.
- `baInd_mono`          : Larger diameter → larger basal area.
- `baPlot_nonneg`       : Plot basal area is non-negative.
-/

namespace ForestIPM.Competition

open Real

/-- Individual basal area (m²) for a tree with DBH `d` (mm):
    the area of a circle with radius `d/2` mm = `d/2000` m. -/
noncomputable def baInd (d : ℝ) : ℝ := π * (d / 2000) ^ 2

/-- Basal area is non-negative for any diameter. -/
theorem baInd_nonneg (d : ℝ) : 0 ≤ baInd d :=
  mul_nonneg pi_pos.le (sq_nonneg _)

/-- Basal area is strictly positive for positive diameter. -/
theorem baInd_pos {d : ℝ} (hd : 0 < d) : 0 < baInd d := by
  unfold baInd
  apply mul_pos pi_pos
  positivity

/-- The formula `π · (d/2 · 10⁻³)²` used in the R code equals `baInd d`. -/
theorem baInd_formula_equiv (d : ℝ) : π * (d / 2 * 1e-3) ^ 2 = baInd d := by
  unfold baInd; norm_num

/-- Basal area is monotone in diameter: larger trees have larger cross-sections. -/
theorem baInd_mono {d₁ d₂ : ℝ} (hd₁ : 0 ≤ d₁) (h : d₁ ≤ d₂) : baInd d₁ ≤ baInd d₂ := by
  unfold baInd
  apply mul_le_mul_of_nonneg_left _ pi_pos.le
  exact pow_le_pow_left (div_nonneg hd₁ (by norm_num)) (by linarith) 2

variable {k : ℕ}

/-- Plot-level basal area (m²/ha) from a discrete size distribution.
    `ds` — DBH values (mm), `ns` — individual counts, `A` — plot area (m²). -/
noncomputable def baPlot (ds ns : Fin k → ℝ) (A : ℝ) : ℝ :=
  (1e4 / A) * ∑ i, baInd (ds i) * ns i

/-- Plot basal area is non-negative when all counts are non-negative and `A > 0`. -/
theorem baPlot_nonneg {k : ℕ} {ds ns : Fin k → ℝ} {A : ℝ}
    (hA : 0 < A) (hns : ∀ i, 0 ≤ ns i) : 0 ≤ baPlot ds ns A := by
  unfold baPlot
  apply mul_nonneg
  · positivity
  · apply Finset.sum_nonneg
    intro i _
    exact mul_nonneg (baInd_nonneg _) (hns i)

end ForestIPM.Competition
