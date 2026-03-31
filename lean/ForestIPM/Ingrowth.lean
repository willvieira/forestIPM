import Mathlib

/-!
# Ingrowth / Recruitment Vital Rate

Formalizes `ingrowth_f` and `ingrowth_lk` from `R/vital_rates.R` and `R/kernel.R`.

## Model

**Rate** (`ingrowth_f`): expected number of recruits entering the plot per census interval.

```r
mPlot    <- exp(mPop_log + plot_random + competition_climate_terms)
p        <- exp(-exp(p_log) + BA_adult * (-beta_p))
ingrowth <- mPlot * plot_size * (1 - p ^ delta_time) / (1 - p)
```

`p` is the annual "miss" probability (no recruits that year).
The factor `(1 - pᵟ) / (1 - p)` accumulates expected recruiting years over `[0, Δt]`.

**Size kernel** (`ingrowth_lk`): the full F-kernel entry multiplies the rate by the
truncated-normal density of recruit sizes on `[127 mm, ∞)`:

```r
ingrowth_prob <- ingrowth_f(...) * dnorm(x, μ, σ) / (1 - pnorm(127, μ, σ))
```

## Main results

- `ingrowthP_pos`          : The miss probability `p` is in `(0, 1)` (given `base_rate > 0`).
- `cumulative_factor_pos`  : The geometric factor `(1 - pᵟ)/(1 - p) > 0`.
- `ingrowth_rate_pos`      : `ingrowth_f(…) > 0`.
- `gaussianPDF_nonneg`     : The Gaussian density is non-negative.
- `ingrowth_kernel_nonneg` : The full F-kernel entry is non-negative.
-/

namespace ForestIPM.Ingrowth

open Real

/-! ### Annual miss probability `p` -/

/-- Annual miss probability: `p = exp(−(base_rate + ba_effect))`.
    In the R model: `base_rate = exp(p_log) > 0`, `ba_effect = BA_adult · beta_p ≥ 0`. -/
noncomputable def ingrowthP (base_rate ba_effect : ℝ) : ℝ :=
  exp (-(base_rate + ba_effect))

theorem ingrowthP_pos (base_rate ba_effect : ℝ) : 0 < ingrowthP base_rate ba_effect :=
  exp_pos _

theorem ingrowthP_lt_one {base_rate ba_effect : ℝ}
    (h_rate : 0 < base_rate) (h_ba : 0 ≤ ba_effect) :
    ingrowthP base_rate ba_effect < 1 := by
  unfold ingrowthP
  rw [exp_lt_one_iff]; linarith

/-! ### Cumulative factor `(1 − pᵟ) / (1 − p)` -/

/-- For `p ∈ (0, 1)` and `Δt > 0`, the cumulative factor is strictly positive. -/
theorem cumulative_factor_pos {p Δt : ℝ}
    (hp0 : 0 < p) (hp1 : p < 1) (hΔt : 0 < Δt) :
    0 < (1 - p ^ Δt) / (1 - p) :=
  div_pos (by linarith [rpow_lt_one hp0.le hp1 hΔt]) (by linarith)

/-! ### Full recruitment rate -/

/-- `ingrowth_f` is strictly positive given positive site rate, plot area, and time step,
    and a miss probability strictly between 0 and 1. -/
theorem ingrowth_rate_pos
    {mPlot plotSize p Δt : ℝ}
    (hm : 0 < mPlot) (hA : 0 < plotSize)
    (hp0 : 0 < p) (hp1 : p < 1) (hΔt : 0 < Δt) :
    0 < mPlot * plotSize * ((1 - p ^ Δt) / (1 - p)) :=
  mul_pos (mul_pos hm hA) (cumulative_factor_pos hp0 hp1 hΔt)

/-! ### Gaussian PDF and truncated-normal density -/

/-- Gaussian PDF with mean `μ` and standard deviation `σ`. -/
noncomputable def gaussianPDF (μ σ x : ℝ) : ℝ :=
  (sqrt (2 * π) * σ)⁻¹ * exp (-(x - μ) ^ 2 / (2 * σ ^ 2))

theorem gaussianPDF_nonneg (μ σ x : ℝ) : 0 ≤ gaussianPDF μ σ x := by
  unfold gaussianPDF; positivity

theorem gaussianPDF_pos {σ : ℝ} (hσ : 0 < σ) (μ x : ℝ) : 0 < gaussianPDF μ σ x := by
  unfold gaussianPDF
  apply mul_pos
  · positivity
  · positivity

/-- The truncated-normal normalising constant `1 − Φ(a; μ, σ)` is strictly positive
    for any finite threshold `a`.  The real claim is `Real.normCDF ((a - μ) / σ) < 1`,
    which follows from the fact that the standard normal CDF is strictly less than 1
    on all of ℝ.  Left as `sorry` pending full Mathlib CDF support. -/
theorem truncnorm_const_pos (μ σ a : ℝ) (hσ : 0 < σ) :
    0 < 1 - Real.normCDF ((a - μ) / σ) := by
  sorry

/-- The truncated-normal density `φ(x; μ, σ) / c` is non-negative whenever `c > 0`. -/
theorem truncnorm_density_nonneg {μ σ x c : ℝ} (hc : 0 < c) :
    0 ≤ gaussianPDF μ σ x / c :=
  div_nonneg (gaussianPDF_nonneg μ σ x) hc.le

/-! ### Full F-kernel entry `ingrowth_lk` -/

/-- `ingrowth_lk = ingrowth_rate · truncnorm_density ≥ 0`. -/
theorem ingrowth_kernel_nonneg
    {rate truncDensity : ℝ} (hr : 0 ≤ rate) (ht : 0 ≤ truncDensity) :
    0 ≤ rate * truncDensity :=
  mul_nonneg hr ht

end ForestIPM.Ingrowth
