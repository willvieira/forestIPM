devtools::load_all(".")
library(statmod)     # gauss.quad()
library(pracma)      # gaussLegendre()

# Helper: run our implementation and both packages, return comparison df
compare_gl <- function(n, a, b) {
  # Ours
  ours <- forestIPM:::.gl_nodes_weights(n, a, b)

  # statmod: returns nodes/weights on [-1,1], need to map to [a,b]
  sm   <- statmod::gauss.quad(n, kind = "legendre")
  sm_nodes   <- (b + a) / 2 + (b - a) / 2 * sm$nodes
  sm_weights <- (b - a) / 2 * sm$weights

  # pracma: directly accepts limits
  pm   <- pracma::gaussLegendre(n, a, b)

  # Sort everything by node for fair comparison
  o1 <- order(ours$nodes)
  o2 <- order(sm_nodes)
  o3 <- order(pm$x)

  data.frame(
    node_ours    = ours$nodes[o1],
    node_statmod = sm_nodes[o2],
    node_pracma  = pm$x[o3],
    w_ours       = ours$weights[o1],
    w_statmod    = sm_weights[o2],
    w_pracma     = pm$w[o3],
    diff_node_statmod = abs(ours$nodes[o1] - sm_nodes[o2]),
    diff_node_pracma  = abs(ours$nodes[o1] - pm$x[o3]),
    diff_w_statmod    = abs(ours$weights[o1] - sm_weights[o2]),
    diff_w_pracma     = abs(ours$weights[o1] - pm$w[o3])
  )
}

# Test a few node counts and intervals
cases <- list(
  list(n = 5,   a = 0, b = 1),
  list(n = 10,  a = 0, b = 1),
  list(n = 50,  a = 0, b = 1),
  list(n = 100, a = 0, b = 1),
  list(n = 20,  a = 1, b = 500),   # realistic IPM size range
  list(n = 200,  a = 1, b = 500)    # realistic IPM size range
)

for (case in cases) {
  cat(sprintf("\n=== n = %d, [%g, %g] ===\n", case$n, case$a, case$b))
  df <- compare_gl(case$n, case$a, case$b)

  cat("Max |node diff| vs statmod:", max(df$diff_node_statmod), "\n")
  cat("Max |node diff| vs pracma: ", max(df$diff_node_pracma),  "\n")
  cat("Max |weight diff| vs statmod:", max(df$diff_w_statmod), "\n")
  cat("Max |weight diff| vs pracma: ", max(df$diff_w_pracma),  "\n")
  cat("Weights sum (ours):", sum(df$w_ours),
      "  expected:", case$b - case$a, "\n")
}

# Also verify a known integral: integral of x^2 on [0,1] = 1/3
cat("\n=== Sanity check: integral of x^2 on [0,1] (should be 1/3) ===\n")
for (n in c(5, 10, 20)) {
  gl  <- forestIPM:::.gl_nodes_weights(n, 0, 1)
  est <- sum(gl$weights * gl$nodes^2)
  cat(sprintf("n = %2d: %.15f  (error = %.2e)\n", n, est, abs(est - 1/3)))
}
