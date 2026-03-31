import Mathlib

/-!
# Climate Covariate

Formalizes the climate response used in all three vital rates in `R/vital_rates.R`.

Each vital rate uses the same unimodal (Gaussian bell) response to temperature and
precipitation:

  `climate(x) = exp(-τ · (x - x_opt)²)`

where
- `τ > 0`   is the tolerance parameter (breadth of the climate niche),
- `x_opt`   is the optimal climate value,
- `x`       is the observed climate value.

This function appears as a multiplicative factor inside the linear predictor of
growth (`r`), survival (`η`), and ingrowth (`λ_ingrowth`).

## Main results

- `climate_pos`      : The response is strictly positive for all inputs.
- `climate_le_one`   : The response is at most 1.
- `climate_mem_Ioc`  : The response lies in `(0, 1]`.
- `climate_atOptimum`: The maximum value of 1 is attained at `x = x_opt`.
- `climate_symm`     : The response is symmetric around `x_opt`.
- `climate_strictMono_left`  : The response is strictly increasing for `x < x_opt`.
- `climate_strictAntiMono_right` : The response is strictly decreasing for `x > x_opt`.
-/

namespace ForestIPM.Climate

/-- Climate response: a Gaussian bell curve centred at `x_opt` with tolerance `τ`. -/
noncomputable def climate (τ x_opt x : ℝ) : ℝ :=
  Real.exp (-τ * (x - x_opt) ^ 2)

/-- The climate response is strictly positive for all inputs. -/
theorem climate_pos (τ x_opt x : ℝ) : 0 < climate τ x_opt x :=
  Real.exp_pos _

/-- The climate response never exceeds 1 (the exponent is always ≤ 0 when τ ≥ 0). -/
theorem climate_le_one (τ x_opt x : ℝ) (hτ : 0 ≤ τ) : climate τ x_opt x ≤ 1 := by
  apply Real.exp_le_one_iff_le_zero.mpr
  have : 0 ≤ (x - x_opt) ^ 2 := sq_nonneg _
  linarith [mul_nonneg hτ this]

/-- The climate response lies in `(0, 1]` when `τ ≥ 0`. -/
theorem climate_mem_Ioc (τ x_opt x : ℝ) (hτ : 0 ≤ τ) :
    climate τ x_opt x ∈ Set.Ioc 0 1 :=
  ⟨climate_pos τ x_opt x, climate_le_one τ x_opt x hτ⟩

/-- The maximum value of 1 is attained exactly at `x = x_opt`. -/
theorem climate_atOptimum (τ x_opt : ℝ) : climate τ x_opt x_opt = 1 := by
  simp [climate]

/-- The response is symmetric around `x_opt`. -/
theorem climate_symm (τ x_opt x : ℝ) :
    climate τ x_opt (x_opt + x) = climate τ x_opt (x_opt - x) := by
  simp [climate]; ring

/-- For `τ > 0`, the response is strictly increasing on `(-∞, x_opt]`. -/
theorem climate_strictMono_left (τ x_opt : ℝ) (hτ : 0 < τ) :
    StrictMonoOn (climate τ x_opt) (Set.Iic x_opt) := by
  intro a ha b hb hab
  simp only [Set.mem_Iic] at ha hb
  apply Real.exp_lt_exp.mpr
  apply neg_lt_neg
  apply mul_lt_mul_of_pos_left _ hτ
  have ha' : x_opt - a ≥ 0 := by linarith
  have hb' : x_opt - b ≥ 0 := by linarith
  have hab' : x_opt - b < x_opt - a := by linarith
  nlinarith [sq_nonneg (x_opt - a), sq_nonneg (x_opt - b)]

/-- For `τ > 0`, the response is strictly decreasing on `[x_opt, +∞)`. -/
theorem climate_strictAntiMono_right (τ x_opt : ℝ) (hτ : 0 < τ) :
    StrictAntiOn (climate τ x_opt) (Set.Ici x_opt) := by
  intro a ha b hb hab
  simp only [Set.mem_Ici] at ha hb
  apply Real.exp_lt_exp.mpr
  apply neg_lt_neg
  apply mul_lt_mul_of_pos_left _ hτ
  have ha' : a - x_opt ≥ 0 := by linarith
  have hb' : b - x_opt ≥ 0 := by linarith
  have hab' : a - x_opt < b - x_opt := by linarith
  nlinarith [sq_nonneg (a - x_opt), sq_nonneg (b - x_opt)]

end ForestIPM.Climate
