#' Compute Gauss-Legendre quadrature nodes and weights on [a, b]
#'
#' Uses the Golub-Welsch algorithm: constructs the symmetric tridiagonal
#' Jacobi matrix for Legendre polynomials on [-1, 1], decomposes it via
#' \code{eigen()}, then maps the result to the interval [a, b].
#'
#' @param n Positive integer. Number of quadrature nodes.
#' @param a Numeric. Left endpoint of integration interval.
#' @param b Numeric. Right endpoint of integration interval.
#' @return A named list with two numeric vectors:
#'   \describe{
#'     \item{\code{nodes}}{Quadrature nodes on [a, b], sorted ascending.}
#'     \item{\code{weights}}{Corresponding quadrature weights (positive, sum to b - a).}
#'   }
#' @keywords internal
.gl_nodes_weights <- function(n, a, b) {
  # Build symmetric tridiagonal Jacobi matrix for Legendre polynomials on [-1, 1].
  # Diagonal entries are all zero.
  # Sub/super-diagonal: beta_k = k / sqrt(4*k^2 - 1) for k = 1, ..., n-1.
  k <- seq_len(n - 1L)
  beta <- k / sqrt(4 * k^2 - 1)

  J <- matrix(0.0, nrow = n, ncol = n)
  diag(J) <- 0.0
  if (n > 1L) {
    J[cbind(k, k + 1L)] <- beta
    J[cbind(k + 1L, k)] <- beta
  }

  # Eigendecompose J (symmetric -> real eigenvalues)
  eig <- eigen(J, symmetric = TRUE)
  # Nodes on [-1, 1]: eigenvalues
  nodes_11 <- eig$values
  # Weights on [-1, 1]: 2 * (first row of eigenvectors)^2
  weights_11 <- 2 * eig$vectors[1L, ]^2

  # Map from [-1, 1] to [a, b]
  nodes_ab   <- (b + a) / 2 + (b - a) / 2 * nodes_11
  weights_ab <- (b - a) / 2 * weights_11

  # Sort by node value
  ord <- order(nodes_ab)
  list(nodes = nodes_ab[ord], weights = weights_ab[ord])
}
