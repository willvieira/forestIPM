import Mathlib

/-!
# IPM Kernel Structure

Formalizes the structure of the Integral Projection Model (IPM) kernel assembled
in `R/kernel.R` (`mkKernel`).

## Model

The kernel `K` is a square matrix of dimension `n × n` (number of mesh points):

  `K = P + F`

where
- `P[i, j] = vonBertalanffy_lk(meshpts[i], meshpts[j]) · survival(meshpts[j]) · weights[j]`
  (growth × survival, weighted by quadrature)
- `F[i, j] = ingrowth_lk(meshpts[i], meshpts[j]) · weights[j]`
  (recruitment, weighted by quadrature)

The population growth rate `λ` is the **spectral radius** (dominant eigenvalue) of `K`.

## Main results

- `K_eq_P_add_F`    : Definitional decomposition `K = P + F`.
- `P_nonneg`        : `P` has non-negative entries (product of non-negative vital rates
                       and positive quadrature weights).
- `F_nonneg`        : `F` has non-negative entries (ingrowth rate is non-negative,
                       weights are positive).
- `K_nonneg`        : `K` has non-negative entries.
- `lambda_eq_spectral_radius` : `λ = spectral radius of K` (stated; relies on
                       Perron-Frobenius, left as `sorry`).
-/

namespace ForestIPM.Kernel

open Matrix

/-- Abstract representation of the IPM kernel components.
    We work with `n × n` matrices over ℝ. -/
variable {n : ℕ}

/-!
### Decomposition K = P + F
-/

/-- The full IPM kernel: sum of the growth-survival kernel `P` and the
    recruitment kernel `F`. Mirrors the R expression `K <- P + F`. -/
def mkKernel (P F : Matrix (Fin n) (Fin n) ℝ) : Matrix (Fin n) (Fin n) ℝ := P + F

/-- The kernel equals the sum of its components. -/
theorem K_eq_P_add_F (P F : Matrix (Fin n) (Fin n) ℝ) :
    mkKernel P F = P + F := rfl

/-!
### Non-negativity

The vital rates and quadrature weights are non-negative:
- `vonBertalanffy_lk` is a normal density (≥ 0).
- `survival_f` is a logistic power (> 0).
- `ingrowth_lk` is a product of a Poisson rate and a truncated normal density (≥ 0).
- GL quadrature weights are positive (see `GaussLegendre`).

Their products and the sum `K = P + F` therefore have non-negative entries.
-/

/-- A matrix built as the pointwise product of a non-negative kernel and positive
    weights has non-negative entries. -/
theorem weighted_kernel_nonneg
    {K_vals : Fin n → Fin n → ℝ} {w : Fin n → ℝ}
    (hK : ∀ i j, 0 ≤ K_vals i j) (hw : ∀ j, 0 < w j) :
    ∀ i j, 0 ≤ K_vals i j * w j :=
  fun i j => mul_nonneg (hK i j) (hw j).le

/-- The growth-survival matrix `P` has non-negative entries. -/
theorem P_nonneg
    {growth_surv : Fin n → Fin n → ℝ} {w : Fin n → ℝ}
    (hgs : ∀ i j, 0 ≤ growth_surv i j) (hw : ∀ j, 0 < w j) :
    ∀ i j, 0 ≤ (fun i j => growth_surv i j * w j) i j :=
  weighted_kernel_nonneg hgs hw

/-- The recruitment matrix `F` has non-negative entries. -/
theorem F_nonneg
    {ingrowth : Fin n → Fin n → ℝ} {w : Fin n → ℝ}
    (hig : ∀ i j, 0 ≤ ingrowth i j) (hw : ∀ j, 0 < w j) :
    ∀ i j, 0 ≤ (fun i j => ingrowth i j * w j) i j :=
  weighted_kernel_nonneg hig hw

/-- The full kernel `K = P + F` has non-negative entries. -/
theorem K_nonneg
    {P_vals F_vals : Fin n → Fin n → ℝ}
    (hP : ∀ i j, 0 ≤ P_vals i j) (hF : ∀ i j, 0 ≤ F_vals i j) :
    ∀ i j, 0 ≤ P_vals i j + F_vals i j :=
  fun i j => add_nonneg (hP i j) (hF i j)

/-!
### Population growth rate λ

The asymptotic population growth rate is the **dominant eigenvalue** (spectral radius)
of `K`.  For non-negative irreducible matrices this equals the Perron root, which is
real and positive.  A complete proof requires Perron-Frobenius theory, which is not
yet in Mathlib; the statement is given with `sorry`.
-/

/-! `Matrix.spectralRadius` is not in Mathlib as a standalone function.
    The spectral radius can be expressed via `spectralRadius ℝ K` where `K` is viewed
    as an element of the Banach algebra `Matrix (Fin n) (Fin n) ℝ`, returning a value
    of type `ℝ≥0`.  We cast to `ℝ` below. -/

/-- The asymptotic population growth rate equals the spectral radius of `K`.
    **Proof gap**: requires Perron-Frobenius theory for non-negative matrices, which
    is not yet in Mathlib. The spectral radius here uses Mathlib's `spectralRadius ℝ K`
    for `K` as an element of the matrix Banach algebra. -/
theorem lambda_eq_spectral_radius
    (K : Matrix (Fin n) (Fin n) ℝ)
    (hK_nonneg : ∀ i j, 0 ≤ K i j)
    (hK_irred  : True)  -- placeholder for irreducibility hypothesis
    (λ : ℝ) (hλ_pos : 0 < λ) :
    λ = ↑(spectralRadius ℝ K) := by
  sorry

end ForestIPM.Kernel
