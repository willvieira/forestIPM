import Mathlib

/-!
# Survival Probability

Formalizes the survival vital rate from `R/vital_rates.R` (`survival_f`).

The R implementation:

```r
longev_log <- 1 / (1 + exp(-(η)))       -- logistic(η) = sigmoid(η)
survival_prob <- longev_log ^ delta_time  -- annual rate raised to census interval
```

where `η = ψ + plot_random + β·(BA_intra + θ·BA_inter) - τ_T·(T - T_opt)² - τ_P·(P - P_opt)²`.

## Main results

- `survival_pos`      : Survival probability is strictly positive.
- `survival_lt_one`   : Survival probability is strictly below 1 for any positive time step.
- `survival_mem_Ioo`  : Survival probability lies in the open interval `(0, 1)`.
- `survival_antimono` : Longer time steps yield lower (or equal) survival probability.
-/

namespace ForestIPM.Survival

open Real

/-- Survival probability: logistic annual rate raised to the census interval `Δt`. -/
noncomputable def survival (η Δt : ℝ) : ℝ := sigmoid η ^ Δt

/-- Survival probability is strictly positive (logistic is always positive). -/
theorem survival_pos (η Δt : ℝ) : 0 < survival η Δt :=
  rpow_pos_of_pos (sigmoid_pos η) Δt

/-- Survival probability is strictly less than 1 when the time step is positive.
    (If `Δt = 0`, `sigmoid η ^ 0 = 1` by convention.) -/
theorem survival_lt_one {η Δt : ℝ} (hΔt : 0 < Δt) : survival η Δt < 1 :=
  rpow_lt_one (sigmoid_pos η) (sigmoid_lt_one η) hΔt

/-- Survival probability lies strictly between 0 and 1 for any positive time step. -/
theorem survival_mem_Ioo {η Δt : ℝ} (hΔt : 0 < Δt) : survival η Δt ∈ Set.Ioo 0 1 :=
  ⟨survival_pos η Δt, survival_lt_one hΔt⟩

/-- Longer census intervals correspond to lower survival probabilities:
    if `Δt₁ ≤ Δt₂` then `sigmoid η ^ Δt₂ ≤ sigmoid η ^ Δt₁`. -/
theorem survival_antimono {η Δt₁ Δt₂ : ℝ} (h : Δt₁ ≤ Δt₂) (hΔt₁ : 0 ≤ Δt₁) :
    survival η Δt₂ ≤ survival η Δt₁ :=
  rpow_le_rpow_of_exponent_ge (sigmoid_pos η) (sigmoid_lt_one η).le h

end ForestIPM.Survival
