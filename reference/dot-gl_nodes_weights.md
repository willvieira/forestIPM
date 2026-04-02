# Compute Gauss-Legendre quadrature nodes and weights on `[a, b]`

Uses the Golub-Welsch algorithm: constructs the symmetric tridiagonal
Jacobi matrix for Legendre polynomials on `[-1, 1]`, decomposes it via
`getJacobiEigen()` (RcppEigen `SelfAdjointEigenSolver`), then maps the
result to the interval `[a, b]`.

## Usage

``` r
.gl_nodes_weights(n, a, b)
```

## Arguments

- n:

  Positive integer. Number of quadrature nodes.

- a:

  Numeric. Left endpoint of integration interval.

- b:

  Numeric. Right endpoint of integration interval.

## Value

A named list with two numeric vectors:

- `nodes`:

  Quadrature nodes on `[a, b]`, sorted ascending.

- `weights`:

  Corresponding quadrature weights (positive, sum to b - a).
