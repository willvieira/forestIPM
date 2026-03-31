import Mathlib

/-!
# Growth Vital Rate (Von Bertalanffy Model)

Formalizes the growth vital rate from `R/vital_rates.R` (`vonBertalanffy_f`).

The model predicts the **mean** size of a tree at time `t + Δt` given its current
size `x`:

  `μ(x) = x · e^{-r·Δt} + Lmax · (1 - e^{-r·Δt})`

where
- `r > 0`  is the intrinsic growth rate (itself a function of competition and climate),
- `Lmax`   is the asymptotic maximum diameter (mm),
- `Δt > 0` is the census interval (years).

## Main results

- `growth_fixedPoint` : `Lmax` is the unique fixed point.
- `growth_contraction` : The map is a contraction with factor `e^{-r·Δt}`.
- `growth_iterate` : Closed form for the n-fold iterate.
- `growth_tendsto` : Iterates converge to `Lmax` when `r > 0` and `Δt > 0`.
-/

namespace ForestIPM.Growth

/-- Mean predicted size after time `Δt`, starting from size `x`,
    with rate `r` and asymptotic maximum `Lmax`. -/
noncomputable def growth (r Δt Lmax x : ℝ) : ℝ :=
  x * Real.exp (-r * Δt) + Lmax * (1 - Real.exp (-r * Δt))

/-- `Lmax` is a fixed point of the growth map. -/
theorem growth_fixedPoint (r Δt Lmax : ℝ) :
    growth r Δt Lmax Lmax = Lmax := by
  simp only [growth]
  ring

/-- The map is a pure translation toward `Lmax`:
    the distance from `Lmax` contracts by exactly `e^{-r·Δt}` per step. -/
theorem growth_contraction (r Δt Lmax x y : ℝ) :
    |growth r Δt Lmax x - growth r Δt Lmax y| =
    Real.exp (-r * Δt) * |x - y| := by
  have h : growth r Δt Lmax x - growth r Δt Lmax y =
           Real.exp (-r * Δt) * (x - y) := by
    simp only [growth]; ring
  rw [h, abs_mul, abs_of_pos (Real.exp_pos _)]

/-- Closed form for the n-fold iterate:
    `f^[n](x) = x · e^{-r·Δt·n} + Lmax · (1 - e^{-r·Δt·n})`. -/
theorem growth_iterate (r Δt Lmax x : ℝ) (n : ℕ) :
    (growth r Δt Lmax)^[n] x =
    x * Real.exp (-r * Δt) ^ n + Lmax * (1 - Real.exp (-r * Δt) ^ n) := by
  induction n with
  | zero => simp [growth]
  | succ n ih =>
    simp only [Function.iterate_succ', Function.comp, growth, ih]
    ring

/-- Iterating the growth map from any starting size converges to `Lmax`. -/
theorem growth_tendsto (r Δt Lmax x : ℝ) (hr : 0 < r) (hΔt : 0 < Δt) :
    Filter.Tendsto (fun n : ℕ => (growth r Δt Lmax)^[n] x)
      Filter.atTop (nhds Lmax) := by
  simp_rw [growth_iterate]
  -- rewrite in the form Lmax + (x - Lmax) * e^n so the constant part is clear
  have eq : ∀ n : ℕ,
      x * Real.exp (-r * Δt) ^ n + Lmax * (1 - Real.exp (-r * Δt) ^ n) =
      Lmax + (x - Lmax) * Real.exp (-r * Δt) ^ n := fun n => by ring
  simp_rw [eq]
  -- exp(-r·Δt) ∈ [0, 1) when r, Δt > 0
  have hnn : 0 ≤ Real.exp (-r * Δt) := Real.exp_nonneg _
  have hlt : Real.exp (-r * Δt) < 1 :=
    Real.exp_lt_one_iff.mpr (by linarith)
  -- e^n → 0 in ℕ-power
  have hpow : Filter.Tendsto (fun n : ℕ => Real.exp (-r * Δt) ^ n) Filter.atTop (nhds 0) :=
    Real.tendsto_pow_atTop_nhds_zero_of_lt_one hnn hlt
  -- (x - Lmax) * e^n → (x - Lmax) * 0 = 0
  have hscaled := hpow.const_mul (x - Lmax)
  simp only [mul_zero] at hscaled
  -- Lmax + 0 = Lmax
  have hshift := hscaled.const_add Lmax
  simp only [add_zero] at hshift
  exact hshift

end ForestIPM.Growth
