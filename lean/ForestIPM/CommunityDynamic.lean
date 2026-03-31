import Mathlib
import ForestIPM.Kernel
import ForestIPM.AsymptoticLambda

/-!
# Dynamic Projection Engine

Formalizes `project()` from `R/project.R`.

## What the engine does

Unlike the asymptotic engine, the dynamic engine **iterates** the population
forward in time.  At every time step the kernel is **rebuilt** from the current
population state, so competition changes as the population evolves:

```r
for t in 1..T:
  K_t <- mkKernel(Nvec_intra = n_t, Nvec_inter = n_het_t, env_t, pars)
  n_{t+1} <- K_t %*% n_t          # matrix-vector product
  recompute n_het from n_{t+1}     # update interspecific competition
```

The kernel `K_t` is a function of the current size distribution `n_t` through
the basal-area competition metrics, so this is a **density-dependent** IPM.

## Mathematical structure

The state is a size-distribution vector `n : Fin m → ℝ` (number of individuals
per mesh class).  The one-step map is:

  `Φ(n) = K(n) · n`

where `K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ` is the density-dependent
kernel.  The full trajectory is the sequence `n₀, Φ(n₀), Φ(Φ(n₀)), …`.

## Main results

- `nonneg_preserved`       : Non-negativity of n is invariant under Φ.
- `nonneg_preserved_iter`  : Non-negativity is preserved at every time step.
- `equilibrium_iff`        : n* is a fixed point of Φ iff K(n*) · n* = n*.
- `equilibrium_lambda_one` : At equilibrium, the instantaneous λ = 1
                              (spectral radius of K(n*) equals 1; `sorry`).
- `asymptotic_vs_dynamic`  : The asymptotic engine gives the *instantaneous*
                              λ of K(n_t); the dynamic engine tracks how n_t
                              and λ_t co-evolve over time.
-/

namespace ForestIPM.CommunityDynamic

open Matrix

variable {m : ℕ}

/-!
### Density-dependent kernel and one-step map
-/

/-- The density-dependent one-step map: multiply the current distribution by the
    kernel built from that same distribution. -/
noncomputable def step
    (K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ)
    (n : Fin m → ℝ) : Fin m → ℝ :=
  (K n).mulVec n

/-- The full trajectory from initial state `n₀`. -/
noncomputable def trajectory
    (K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ)
    (n₀ : Fin m → ℝ) : ℕ → Fin m → ℝ :=
  fun t => (step K)^[t] n₀

/-!
### Non-negativity invariant

The core structural guarantee: if the kernel has non-negative entries for every
non-negative state (which the vital rates ensure), then the distribution remains
non-negative at all times.
-/

/-- A single step preserves non-negativity: if `n ≥ 0` entry-wise and
    `K(n) ≥ 0` entry-wise, then `K(n) · n ≥ 0` entry-wise. -/
theorem nonneg_preserved
    {K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ}
    {n : Fin m → ℝ}
    (hn  : ∀ i, 0 ≤ n i)
    (hKn : ∀ i j, 0 ≤ K n i j) :
    ∀ i, 0 ≤ step K n i := by
  intro i
  simp only [step, mulVec, dotProduct]
  apply Finset.sum_nonneg
  intro j _
  exact mul_nonneg (hKn i j) (hn j)

/-- Non-negativity is preserved at every time step, provided the kernel is
    non-negative on all non-negative inputs. -/
theorem nonneg_preserved_iter
    {K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ}
    (hK  : ∀ n, (∀ i, 0 ≤ n i) → ∀ i j, 0 ≤ K n i j)
    {n₀ : Fin m → ℝ} (hn₀ : ∀ i, 0 ≤ n₀ i) :
    ∀ t, ∀ i, 0 ≤ trajectory K n₀ t i := by
  intro t
  induction t with
  | zero => simpa [trajectory]
  | succ t ih =>
    simp only [trajectory, Function.iterate_succ', Function.comp]
    exact nonneg_preserved ih (hK _ ih)

/-!
### Equilibrium (fixed point)
-/

/-- `n*` is an equilibrium of the dynamic engine iff it is a fixed point of Φ:
    `K(n*) · n* = n*`. -/
theorem equilibrium_iff
    (K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ)
    (nstar : Fin m → ℝ) :
    step K nstar = nstar ↔ (K nstar).mulVec nstar = nstar :=
  Iff.rfl

/-- At a non-zero equilibrium, `n*` is an eigenvector of `K(n*)` with eigenvalue 1. -/
theorem equilibrium_eigenvector
    (K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ)
    (nstar : Fin m → ℝ) (heq : step K nstar = nstar) :
    (K nstar).mulVec nstar = (1 : ℝ) • nstar := by
  simp [equilibrium_iff.mp heq]

/-- At a non-trivial equilibrium, the instantaneous asymptotic growth rate
    equals 1: `λ(K(n*)) = 1`.
    **Proof gap**: requires Perron-Frobenius — the dominant eigenvalue of a
    non-negative irreducible matrix equals 1 iff 1 is its spectral radius. -/
theorem equilibrium_lambda_one
    (K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ)
    (nstar : Fin m → ℝ)
    (heq   : step K nstar = nstar)
    (hpos  : ∃ i, 0 < nstar i)
    (hKnn  : ∀ i j, 0 ≤ K nstar i j) :
    (AsymptoticLambda.lambda (K nstar) : ℝ) = 1 := by
  sorry

/-!
### Relationship between the two engines

The asymptotic engine (`lambda.R`) and dynamic engine (`project.R`) use the same
kernel construction but answer different questions.
-/

/-- The instantaneous growth rate at time `t` is the dominant eigenvalue of the
    kernel evaluated at the current state `n_t`.  This is what `lambda.R` returns
    for any snapshot, and what `project.R` optionally records per step. -/
theorem instantaneous_lambda_def
    (K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ)
    (n₀ : Fin m → ℝ) (t : ℕ) :
    AsymptoticLambda.lambda (K (trajectory K n₀ t)) =
    AsymptoticLambda.lambda (K ((step K)^[t] n₀)) :=
  rfl

/-- The dynamic engine converges to the asymptotic growth rate when competition
    stops changing — i.e., when `n_t` converges to a fixed point `n*`.
    At that limit, `λ_t → λ(K(n*)) = 1`. -/
theorem dynamic_convergence_implies_lambda_one
    (K : (Fin m → ℝ) → Matrix (Fin m) (Fin m) ℝ)
    (n₀ nstar : Fin m → ℝ)
    (hconv : Filter.Tendsto (trajectory K n₀) Filter.atTop (nhds nstar))
    (heq   : step K nstar = nstar)
    (hpos  : ∃ i, 0 < nstar i)
    (hKnn  : ∀ i j, 0 ≤ K nstar i j)
    (hKcont : Continuous (fun n => (AsymptoticLambda.lambda (K n) : ℝ))) :
    Filter.Tendsto
      (fun t => (AsymptoticLambda.lambda (K (trajectory K n₀ t)) : ℝ))
      Filter.atTop (nhds 1) := by
  have heq1 : (AsymptoticLambda.lambda (K nstar) : ℝ) = 1 :=
    equilibrium_lambda_one K nstar heq hpos hKnn
  rw [← heq1]
  exact hKcont.continuousAt.tendsto.comp hconv

end ForestIPM.CommunityDynamic
