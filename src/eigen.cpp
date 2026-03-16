#include <RcppEigen.h>

// [[Rcpp::depends(RcppEigen)]]

// [[Rcpp::export]]
Eigen::VectorXd getEigenValues(Eigen::Map<Eigen::MatrixXd> M) {
    // computeEigenvectors=false: faster, only eigenvalues needed
    Eigen::EigenSolver<Eigen::MatrixXd> es(M, false);
    // eigenvalues() returns VectorXcd (complex); .real() extracts real parts as VectorXd
    // For IPM kernels (non-negative matrices), dominant eigenvalue is real by Perron-Frobenius
    return es.eigenvalues().real();
}

// [[Rcpp::export]]
Rcpp::List getJacobiEigen(Eigen::VectorXd beta) {
    // Build symmetric tridiagonal Jacobi matrix from off-diagonal vector beta (length n-1).
    // Used by the Golub-Welsch algorithm for Gauss-Legendre quadrature nodes and weights.
    int n = beta.size() + 1;
    Eigen::MatrixXd J = Eigen::MatrixXd::Zero(n, n);
    for (int i = 0; i < n - 1; ++i) {
        J(i, i + 1) = beta(i);
        J(i + 1, i) = beta(i);
    }
    // SelfAdjointEigenSolver is faster and more accurate than EigenSolver for symmetric matrices.
    // ComputeEigenvectors=true: needed to derive quadrature weights via 2 * v[0,:]^2.
    Eigen::SelfAdjointEigenSolver<Eigen::MatrixXd> es(J);
    return Rcpp::List::create(
        Rcpp::Named("values")      = es.eigenvalues(),
        Rcpp::Named("first_evec")  = Rcpp::wrap(es.eigenvectors().row(0))
    );
}
