import Mathlib
import ForestIPM.Kernel

/-!
# Asymptotic Growth Rate Engine

Formalizes `lambda()` from `R/lambda.R`.

## What the engine does

Given a **snapshot** of the population and environment, the asymptotic engine:
1. Builds the kernel matrix `K` once via `mkKernel(Nvec_intra, Nvec_inter, env, pars)`.
2. Returns `λ = max(Re(eigenvalues(K)))` — the **dominant eigenvalue**.

This is *not* a time iteration.  `λ` is an instantaneous quantity: the growth rate
the population *would* achieve asymptotically if the current conditions (population
structure, competition, climate) were held fixed forever.

```r
lambda <- function(mod, pars, stand, env, ctrl) {
  K_list <- mkKernel(...)
  max(getEigenValues(K_list$K))   # <── entire engine, mathematically
}
```

## Interpretation

| `λ`   | Long-run fate under fixed conditions |
|-------|--------------------------------------|
| `> 1` | Population grows without bound       |
| `= 1` | Population is asymptotically stable  |
| `< 1` | Population declines to extinction    |

## Main results

- `dominantEigenvalue_pos`       : `λ > 0` for non-negative K with a positive entry
                                    (Perron-Frobenius; `sorry`).
- `lambda_gt_one_iff_growth`     : Under constant K, `‖Kⁿ n₀‖ → ∞` iff `λ > 1` (`sorry`).
- `lambda_real`                  : The dominant eigenvalue of a non-negative matrix is real
                                    (Perron-Frobenius; `sorry`).
- `lambda_unique`                : The dominant eigenvalue is unique when K is irreducible
                                    (Perron-Frobenius; `sorry`).
-/

namespace ForestIPM.AsymptoticLambda

open Matrix

variable {n : ℕ}

/-!
### Dominant eigenvalue

The R function `getEigenValues` returns the real parts of all eigenvalues and the
engine takes the maximum.  We model this as the **spectral radius** `r(K)`.
-/

/-- The asymptotic growth rate is the spectral radius of K. -/
noncomputable def lambda (K : Matrix (Fin n) (Fin n) ℝ) : ℝ≥0 :=
  spectralRadius ℝ K

/-!
### Perron-Frobenius results (stated; not yet in Mathlib)

All four results below require the Perron-Frobenius theorem for non-negative
matrices, which is not yet formalized in Mathlib.
-/

/-- The dominant eigenvalue is strictly positive for a non-negative matrix that
    has at least one strictly positive entry. -/
theorem dominantEigenvalue_pos
    (K : Matrix (Fin n) (Fin n) ℝ)
    (hK_nonneg : ∀ i j, 0 ≤ K i j)
    (hK_pos    : ∃ i j, 0 < K i j) :
    0 < (lambda K : ℝ) := by
  sorry

/-- The dominant eigenvalue of a non-negative matrix is attained by a real eigenvalue
    (i.e., the spectral radius equals the largest real eigenvalue). -/
theorem lambda_real
    (K : Matrix (Fin n) (Fin n) ℝ)
    (hK : ∀ i j, 0 ≤ K i j) :
    ∃ v : Fin n → ℝ, v ≠ 0 ∧ K.mulVec v = (lambda K : ℝ) • v := by
  sorry

/-- For irreducible non-negative K, the dominant eigenvalue is simple
    (algebraic multiplicity 1). -/
theorem lambda_unique
    (K : Matrix (Fin n) (Fin n) ℝ)
    (hK_nonneg : ∀ i j, 0 ≤ K i j)
    (hK_irred  : True)  -- placeholder for irreducibility
    (μ : ℝ) (hμ : μ ≠ (lambda K : ℝ))
    (v : Fin n → ℝ) (hv : v ≠ 0) :
    K.mulVec v ≠ μ • v := by
  sorry

/-!
### Ecological interpretation of `λ`

These corollaries connect the eigenvalue to population dynamics under the
hypothetical scenario of constant conditions (fixed K).
-/

/-- **Growth criterion**: a population governed by constant kernel K grows without
    bound (in L² norm) if and only if `λ > 1`. -/
theorem lambda_gt_one_iff_growth
    (K : Matrix (Fin n) (Fin n) ℝ)
    (hK : ∀ i j, 0 ≤ K i j)
    (n₀ : Fin n → ℝ) (hn₀ : n₀ ≠ 0) (hn₀_nn : ∀ i, 0 ≤ n₀ i) :
    1 < (lambda K : ℝ) ↔
    Filter.Tendsto (fun t : ℕ => ‖(K ^ t).mulVec n₀‖) Filter.atTop Filter.atTop := by
  sorry

/-- **Decline criterion**: a population governed by constant K declines to zero
    if and only if `λ < 1`. -/
theorem lambda_lt_one_iff_decline
    (K : Matrix (Fin n) (Fin n) ℝ)
    (hK : ∀ i j, 0 ≤ K i j)
    (n₀ : Fin n → ℝ) (hn₀_nn : ∀ i, 0 ≤ n₀ i) :
    (lambda K : ℝ) < 1 ↔
    Filter.Tendsto (fun t : ℕ => ‖(K ^ t).mulVec n₀‖) Filter.atTop (nhds 0) := by
  sorry

/-!
### Algebraic relationship between `λ` and the kernel

The one result that follows purely from definitions: if `v` is an eigenvector
of K for eigenvalue `λ`, then `K · v = λ · v`.  This is tautological but
makes the connection between the computed eigenvalue and the kernel explicit.
-/

/-- If `v` is a Perron eigenvector and `K · v = λ · v`, then the total population
    `∑ᵢ (K·v)ᵢ · wᵢ = λ · ∑ᵢ vᵢ · wᵢ` — i.e., λ scales the weighted total. -/
theorem lambda_scales_total
    (K : Matrix (Fin n) (Fin n) ℝ)
    (v : Fin n → ℝ) (w : Fin n → ℝ) (λ_val : ℝ)
    (heig : K.mulVec v = λ_val • v) :
    ∑ i, (K.mulVec v) i * w i = λ_val * ∑ i, v i * w i := by
  simp [heig, Finset.mul_sum, mul_comm, mul_assoc]

end ForestIPM.AsymptoticLambda
