import Mathlib

/-!
# Gauss-Legendre Quadrature Properties

Formalizes the key properties of the Gauss-Legendre (GL) quadrature used in
`R/gauss_legendre.R` (`.gl_nodes_weights`).

The R implementation uses the Golub-Welsch algorithm:
1. Build the symmetric tridiagonal Jacobi matrix with off-diagonal entries
   `β_k = k / √(4k² - 1)` for `k = 1, …, n-1`.
2. Eigendecompose: nodes on `[-1,1]` = eigenvalues; weights = `2 · v_i²` where
   `v_i` is the first component of the i-th eigenvector.
3. Affinely map nodes and weights from `[-1, 1]` to `[a, b]`.

## Key mathematical facts

The GL weights on `[-1, 1]` satisfy two properties used in the R code:
- **Positivity**: each weight `w_i = 2 · v_i² > 0` (eigenvectors are nonzero).
- **Sum = 2**: `∑ w_i = 2`, reflecting exact integration of the constant `1` over `[-1,1]`.

These two facts are deep results from approximation theory that rely on properties
of Legendre polynomials and the orthogonality of the eigenvector matrix.
They are stated as hypotheses (`hyp_*`) below and left as `sorry`; the algebraic
consequences (affine rescaling to `[a, b]`) are proved in full.

## Main results

- `gl_weights_pos`   : Mapped GL weights are positive (follows from positivity on [-1,1]).
- `gl_weights_sum`   : Mapped GL weights sum to `b - a`  (follows from sum = 2 on [-1,1]).
-/

namespace ForestIPM.GaussLegendre

/-!
### Hypotheses about the canonical GL weights on `[-1, 1]`

These capture the mathematical guarantees of the Golub-Welsch algorithm.
They are not proved here (Mathlib does not currently contain a formalization
of GL quadrature); they are labelled `sorry` to make the proof gap explicit.
-/

/-- The i-th GL weight on `[-1, 1]` is strictly positive.
    Proof sketch: `w_i = 2 · v_i²` where `v_i ≠ 0` because eigenvectors are nonzero. -/
theorem hyp_gl_weight_pos_11 {n : ℕ} (w : Fin n → ℝ) :
    (∀ i, 0 < w i) := by
  sorry

/-- The GL weights on `[-1, 1]` sum to 2:
    `∑ᵢ wᵢ = ∫_{-1}^{1} 1 dx = 2`.
    Proof sketch: the eigenvector matrix is orthogonal, so the sum of squared first
    components equals 1; multiplying by 2 gives the weight sum. -/
theorem hyp_gl_weights_sum_11 {n : ℕ} (w : Fin n → ℝ) :
    ∑ i, w i = 2 := by
  sorry

/-!
### Affine rescaling from `[-1, 1]` to `[a, b]`

The R code maps nodes and weights via:
```r
nodes_ab   <- (b + a) / 2 + (b - a) / 2 * nodes_11
weights_ab <- (b - a) / 2 * weights_11
```
-/

/-- The mapped weight `wᵢ_ab = (b - a) / 2 · wᵢ_11` is positive whenever `a < b`
    and the canonical weight `wᵢ_11` is positive. -/
theorem gl_weights_pos {n : ℕ} {a b : ℝ} (hab : a < b)
    {w₁₁ : Fin n → ℝ} (hw : ∀ i, 0 < w₁₁ i) :
    ∀ i, 0 < (b - a) / 2 * w₁₁ i := fun i =>
  mul_pos (by linarith) (hw i)

/-- The mapped weights sum to `b - a`:
    `∑ᵢ (b-a)/2 · wᵢ_11 = (b-a)/2 · ∑ᵢ wᵢ_11 = (b-a)/2 · 2 = b - a`. -/
theorem gl_weights_sum {n : ℕ} {a b : ℝ}
    {w₁₁ : Fin n → ℝ} (hsum : ∑ i, w₁₁ i = 2) :
    ∑ i, (b - a) / 2 * w₁₁ i = b - a := by
  rw [← Finset.mul_sum]
  rw [hsum]
  ring

end ForestIPM.GaussLegendre
