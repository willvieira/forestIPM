# tests/testthat/test-gauss-legendre.R
# Unit tests for Gauss-Legendre quadrature infrastructure and convergence
# Task 1 tests: GL infrastructure, control(), .stand_to_nvec()
# Task 2 tests: mkKernel convergence and accuracy

# ---------------------------------------------------------------------------
# Task 1: GL nodes/weights infrastructure
# ---------------------------------------------------------------------------

test_that(".gl_nodes_weights(n=3, a=0, b=1) integrates polynomials up to degree 5 exactly", {
  gl <- forestIPM:::.gl_nodes_weights(3L, 0, 1)
  expect_named(gl, c("nodes", "weights"))
  expect_length(gl$nodes,   3L)
  expect_length(gl$weights, 3L)

  # GL with n=3 is exact for polynomials of degree up to 2*3-1 = 5
  # Check: integral of x^k from 0 to 1 = 1/(k+1)
  for (k in 0:5) {
    approx_val <- sum(gl$weights * gl$nodes^k)
    exact_val  <- 1 / (k + 1)
    expect_equal(approx_val, exact_val, tolerance = 1e-12,
                 label = sprintf("integral of x^%d", k))
  }
})

test_that(".gl_nodes_weights(n=5, a=127, b=500) has nodes in [127, 500] and weights summing to 500-127", {
  gl <- forestIPM:::.gl_nodes_weights(5L, 127, 500)
  expect_true(all(gl$nodes >= 127))
  expect_true(all(gl$nodes <= 500))
  expect_equal(sum(gl$weights), 500 - 127, tolerance = 1e-10)
})

test_that(".stand_to_nvec with integration_method='gauss-legendre' returns weights vector of length n_gl", {
  df <- data.frame(size_mm = c(150, 200, 350),
                   species_id = "ABIBAL",
                   plot_size  = 1000)
  s    <- stand(df)
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")

  nvec <- forestIPM:::.stand_to_nvec(s, "ABIBAL", pars, bin_w = 1,
                                     integration_method = "gauss-legendre",
                                     n_gl = 30L)
  expect_true(!is.null(nvec$ABIBAL$N_con$weights))
  expect_length(nvec$ABIBAL$N_con$weights, 30L)
  expect_length(nvec$ABIBAL$N_con$meshpts, 30L)
})

test_that(".stand_to_nvec with integration_method='midpoint' (default) returns weights = rep(h, m)", {
  df <- data.frame(size_mm = c(150, 200, 350),
                   species_id = "ABIBAL",
                   plot_size  = 1000)
  s    <- stand(df)
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")

  bin_w <- 1
  nvec <- forestIPM:::.stand_to_nvec(s, "ABIBAL", pars, bin_w = bin_w,
                                     integration_method = "midpoint")
  m <- length(nvec$ABIBAL$N_con$meshpts)
  expect_equal(nvec$ABIBAL$N_con$weights, rep(bin_w, m))
})

test_that("control(integration_method='gauss-legendre', n_gl=50) stores both fields; default is 'midpoint'", {
  # Default
  ctrl_default <- control(years = 5, progress = FALSE)
  expect_equal(ctrl_default$integration_method, "midpoint")
  expect_equal(ctrl_default$n_gl, 50L)

  # GL method
  ctrl_gl <- control(years = 5, integration_method = "gauss-legendre", n_gl = 100L, progress = FALSE)
  expect_equal(ctrl_gl$integration_method, "gauss-legendre")
  expect_equal(ctrl_gl$n_gl, 100L)
  expect_s3_class(ctrl_gl, "ipm_control")
})

test_that("control(integration_method='invalid') raises error", {
  expect_error(control(integration_method = "invalid"))
})

# ---------------------------------------------------------------------------
# Task 2: mkKernel convergence and accuracy
# ---------------------------------------------------------------------------

test_that("lambda() with GL n_gl=200 produces value within 1e-4 of midpoint bin_width=1 for ABIBAL", {
  df <- data.frame(size_mm = seq(130, 600, length.out = 20),
                   species_id = "ABIBAL",
                   plot_size  = 1000)
  s    <- stand(df)
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)

  ctrl_mid <- control(years = 1, integration_method = "midpoint",    bin_width = 1, progress = FALSE)
  ctrl_gl  <- control(years = 1, integration_method = "gauss-legendre", n_gl = 200L, progress = FALSE)

  lam_mid <- lambda(mod, pars, s, env, ctrl_mid)[["ABIBAL"]]
  lam_gl  <- lambda(mod, pars, s, env, ctrl_gl)[["ABIBAL"]]

  expect_true(is.finite(lam_gl))
  expect_true(lam_gl > 0)
  expect_equal(lam_mid, lam_gl, tolerance = 1e-4)
})

test_that("GL lambda converges as n_gl increases: spread over n=200,300,500 is smaller than over n=50,100,200", {
  df <- data.frame(size_mm = seq(130, 600, length.out = 20),
                   species_id = "ABIBAL",
                   plot_size  = 1000)
  s    <- stand(df)
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)

  make_lam <- function(n) {
    lambda(mod, pars, s, env,
           control(years = 1, integration_method = "gauss-legendre",
                   n_gl = n, progress = FALSE))[["ABIBAL"]]
  }

  lam_50  <- make_lam(50L)
  lam_100 <- make_lam(100L)
  lam_200 <- make_lam(200L)
  lam_300 <- make_lam(300L)
  lam_500 <- make_lam(500L)

  # Spread of low-n group vs high-n group — high-n should be tighter
  spread_low  <- max(lam_50, lam_100, lam_200) - min(lam_50, lam_100, lam_200)
  spread_high <- max(lam_200, lam_300, lam_500) - min(lam_200, lam_300, lam_500)
  expect_lt(spread_high, spread_low)
})

test_that("K matrix from GL is square with dimension n_gl x n_gl", {
  df <- data.frame(size_mm = c(150, 200, 350),
                   species_id = "ABIBAL",
                   plot_size  = 1000)
  s    <- stand(df)
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")

  n_gl  <- 30L
  nvec  <- forestIPM:::.stand_to_nvec(s, "ABIBAL", pars, bin_w = 1,
                                       integration_method = "gauss-legendre",
                                       n_gl = n_gl)
  sp_pars <- pars$species_params[["ABIBAL"]]$fixed
  K_list  <- forestIPM:::mkKernel(
    Nvec_intra  = nvec$ABIBAL$N_con,
    Nvec_inter  = nvec$ABIBAL$N_het,
    delta_time  = 1,
    plotSize    = 1000,
    Temp        = 0,
    Prec        = 0,
    pars        = sp_pars,
    plot_random = c(0, 0, 0)
  )
  expect_equal(dim(K_list$K), c(n_gl, n_gl))
})

test_that("K matrix column sums are non-negative (valid transition kernel)", {
  df <- data.frame(size_mm = c(150, 200, 350),
                   species_id = "ABIBAL",
                   plot_size  = 1000)
  s    <- stand(df)
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")

  nvec <- forestIPM:::.stand_to_nvec(s, "ABIBAL", pars, bin_w = 1,
                                      integration_method = "gauss-legendre",
                                      n_gl = 30L)
  sp_pars <- pars$species_params[["ABIBAL"]]$fixed
  K_list  <- forestIPM:::mkKernel(
    Nvec_intra  = nvec$ABIBAL$N_con,
    Nvec_inter  = nvec$ABIBAL$N_het,
    delta_time  = 1,
    plotSize    = 1000,
    Temp        = 0,
    Prec        = 0,
    pars        = sp_pars,
    plot_random = c(0, 0, 0)
  )
  expect_true(all(colSums(K_list$K) >= 0))
})
