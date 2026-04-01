
import Mathlib

/-!
# Midpoint Rule Quadrature Properties

Formalizes the key properties of the uniform midpoint rule used in
`R/stand.R` (`.stand_to_nvec`, midpoint branch).

The R implementation builds the mesh and weights as:
```r
m      <- max(1L, as.integer(ceiling((lmax - 127) / bin_w)))
msh    <- 127 + ((seq_len(m)) - 0.5) * bin_w        -- midpoints of uniform bins
wts    <- rep(bin_w, m)                              -- all weights equal h
```

The mesh divides `[a, a + m*h]` into `m` bins of equal width `h = bin_w`,
placing mesh points at the centre of each bin:
  `meshpts[i] = a + (i - 1/2) * h`,  `i = 1, …, m`.
Each weight equals `h`, so the rule approximates `∫ f` by `h · ∑ f(meshpts[i])`.

## Key mathematical facts

- **Positivity**: each weight `h > 0`.
- **Sum = m * h**: `∑ wᵢ = m * h`, which equals the total interval length `m * h`.
  When `m = ⌈(b - a) / h⌉` this is `≥ b - a`, with equality when `h` divides `b - a` exactly.

Both facts follow directly from the uniform construction and are proved in full below.

## Main results

- `midpoint_weights_pos`        : Each weight equals `h > 0`, so is strictly positive.
- `midpoint_weights_sum`        : Weights sum to `m * h` (total interval length).
- `midpoint_meshpts_in_interval`: Each mesh point lies in `(a, a + m * h)`.
-/

namespace ForestIPM.MidpointRule

/-!
### Mesh points and weights

The midpoint rule on `n` points with bin width `h` starting at left endpoint `a`.
-/

/-- The `i`-th midpoint mesh point: centre of the `i`-th bin `[a + i*h, a + (i+1)*h]`.
    Mirrors the R formula `a + ((seq_len(m)) - 0.5) * h`, 0-indexed here. -/
noncomputable def meshpt (a h : ℝ) (i : ℕ) : ℝ := a + (↑i + 1 / 2) * h

/-- The uniform midpoint weights: each bin has width `h`. -/
def weight (h : ℝ) : ℝ := h

/-!
### Weight positivity
-/

/-- Each midpoint weight equals `h`, so is strictly positive whenever `h > 0`. -/
theorem midpoint_weights_pos {n : ℕ} {h : ℝ} (hh : 0 < h) :
    ∀ _i : Fin n, 0 < weight h :=
  fun _ => hh

/-!
### Weight sum
-/

/-- The midpoint weights for `n` bins each of width `h` sum to `n * h`. -/
theorem midpoint_weights_sum (n : ℕ) (h : ℝ) :
    ∑ _i : Fin n, weight h = ↑n * h := by
  simp [weight, Finset.sum_const, nsmul_eq_mul]

/-!
### Mesh points lie strictly inside the covered interval `(a, a + n * h)`
-/

/-- The `i`-th mesh point is strictly greater than `a` when `h > 0`. -/
theorem midpoint_meshpt_gt_left {a h : ℝ} (hh : 0 < h) (i : ℕ) :
    a < meshpt a h i := by
  simp [meshpt]
  positivity

/-- The `i`-th mesh point (0-indexed, `i < n`) is strictly less than `a + n * h`
    when `h > 0`. -/
theorem midpoint_meshpt_lt_right {a h : ℝ} (hh : 0 < h) {n : ℕ} (i : Fin n) :
    meshpt a h i < a + ↑n * h := by
  simp only [meshpt]
  have hi : (i.val : ℝ) + 1 ≤ (n : ℝ) := by exact_mod_cast Nat.succ_le_of_lt i.isLt
  have hlt : (i.val : ℝ) + 1 / 2 < (n : ℝ) := by linarith
  linarith [mul_lt_mul_of_pos_right hlt hh]

end ForestIPM.MidpointRule
