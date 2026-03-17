#' Compute Gauss-Legendre quadrature nodes and weights on \code{[a, b]}
#'
#' Uses the Golub-Welsch algorithm: constructs the symmetric tridiagonal
#' Jacobi matrix for Legendre polynomials on \code{[-1, 1]}, decomposes it via
#' \code{getJacobiEigen()} (RcppEigen \code{SelfAdjointEigenSolver}), then
#' maps the result to the interval \code{[a, b]}.
#'
#' @param n Positive integer. Number of quadrature nodes.
#' @param a Numeric. Left endpoint of integration interval.
#' @param b Numeric. Right endpoint of integration interval.
#' @return A named list with two numeric vectors:
#'   \describe{
#'     \item{\code{nodes}}{Quadrature nodes on \code{[a, b]}, sorted ascending.}
#'     \item{\code{weights}}{Corresponding quadrature weights (positive, sum to b - a).}
#'   }
#' @keywords internal
.gl_nodes_weights <- function(n, a, b) {
  # Off-diagonal of Jacobi matrix: beta_k = k / sqrt(4*k^2 - 1), k = 1..n-1
  k    <- seq_len(n - 1L)
  beta <- k / sqrt(4 * k^2 - 1)

  # Eigendecompose via C++ SelfAdjointEigenSolver (faster + more accurate than base::eigen)
  eig <- getJacobiEigen(beta)

  # Nodes on [-1, 1]: eigenvalues; weights: 2 * (first eigenvector row)^2
  nodes_11   <- eig$values
  weights_11 <- 2 * as.numeric(eig$first_evec)^2

  # Map from [-1, 1] to [a, b]
  nodes_ab   <- (b + a) / 2 + (b - a) / 2 * nodes_11
  weights_ab <- (b - a) / 2 * weights_11

  # Sort by node value
  ord <- order(nodes_ab)
  list(nodes = nodes_ab[ord], weights = weights_ab[ord])
}
