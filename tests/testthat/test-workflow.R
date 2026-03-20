# tests/testthat/test-workflow.R
# Full workflow integration tests: stand -> species_model -> parameters -> lambda -> project
# Species: ABIBAL (bundled RDS in inst/extdata/parameters/ — no network needed)
# All projections use years = 5 and progress = FALSE for speed

# ---------------------------------------------------------------------------
# Shared fixture helper
# ---------------------------------------------------------------------------
make_abibal_stand <- function(n_trees = 10) {
  stand(data.frame(
    size_mm    = seq(130, 600, length.out = n_trees),
    species_id = "ABIBAL",
    plot_size  = 1000
  ))
}

# ---------------------------------------------------------------------------
# Constructor chain
# ---------------------------------------------------------------------------
test_that("stand() returns ipm_stand with correct structure", {
  s <- make_abibal_stand()
  expect_s3_class(s, "ipm_stand")
  expect_true("size_mm" %in% names(s$trees))
  expect_true("species_id" %in% names(s$trees))
})

test_that("species_model() returns ipm_spModel for valid stand", {
  s   <- make_abibal_stand()
  mod <- species_model(s)
  expect_s3_class(mod, "ipm_spModel")
})

test_that("parameters() returns ipm_parameters with draw = 'mean' (offline)", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  expect_s3_class(pars, "ipm_parameters")
})

test_that("env_condition() returns ipm_env", {
  env <- env_condition(MAT = 8, MAP = 1200)
  expect_s3_class(env, "ipm_env")
})

test_that("control() returns ipm_control", {
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  expect_s3_class(ctrl, "ipm_control")
})

# ---------------------------------------------------------------------------
# lambda engine
# ---------------------------------------------------------------------------
test_that("lambda() returns ipm_lambda with finite values", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  lam  <- lambda(mod, pars, s, env, ctrl)
  expect_s3_class(lam, "ipm_lambda")
  lam_vals <- lam[["ABIBAL"]]
  expect_true(all(is.finite(lam_vals)))
  expect_true(all(lam_vals > 0))
})

# ---------------------------------------------------------------------------
# project engine
# ---------------------------------------------------------------------------
test_that("project() returns ipm_projection with lambda and stand_series fields", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_s3_class(proj, "ipm_projection")
  expect_true(!is.null(proj$lambda))
  expect_true(!is.null(proj$stand_series))
  lam_vals <- proj$lambda[["ABIBAL"]]
  expect_true(all(is.finite(lam_vals)))
})

test_that("project() with compute_lambda = FALSE returns NA lambda", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = FALSE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_s3_class(proj, "ipm_projection")
  lam_vals <- proj$lambda[["ABIBAL"]]
  expect_true(all(is.na(lam_vals)))
})

# ---------------------------------------------------------------------------
# plot.ipm_projection()
# ---------------------------------------------------------------------------
test_that("plot(proj, type = 'lambda') renders without error", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_no_error({
    png(tempfile())
    plot(proj, type = "lambda")
    dev.off()
  })
})

test_that("plot(proj, type = 'size_dist') renders without error", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_no_error({
    png(tempfile())
    plot(proj, type = "size_dist")
    dev.off()
  })
})

test_that("plot(proj, type = 'lambda_vs_n') renders without error", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_no_error({
    png(tempfile())
    plot(proj, type = "lambda_vs_n")
    dev.off()
  })
})

test_that("plot(proj) renders all three figures without error", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_no_error({
    png(tempfile())
    plot(proj)
    dev.off()
  })
})

test_that("plot(proj, type = 'invalid') raises error", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_error(plot(proj, type = "invalid"))
})

# ---------------------------------------------------------------------------
# Reproducibility: conditions tracking
# ---------------------------------------------------------------------------
test_that("lambda() carries conditions (pars, env, stand)", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "random", seed = 123L)
  env  <- env_condition(MAT = 8, MAP = 1200)
  lam  <- lambda(mod, pars, s, env)
  cond <- attr(lam, "conditions")
  expect_false(is.null(cond))
  expect_equal(cond$pars$draw_type, "random")
  expect_equal(cond$pars$seed, 123L)
  expect_equal(cond$env$MAT, 8)
  expect_equal(cond$env$MAP, 1200)
  expect_equal(cond$stand, s)
})

test_that("lambda() with draw = 'mean' carries conditions with seed = NULL", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  lam  <- lambda(mod, pars, s, env)
  cond <- attr(lam, "conditions")
  expect_equal(cond$pars$draw_type, "mean")
  expect_null(cond$pars$seed)
})

test_that("project() carries conditions with pars, env, ctrl, and stand", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "random", seed = 99L)
  env  <- env_condition(MAT = 6, MAP = 900)
  ctrl <- control(years = 5, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  cond <- proj$conditions
  expect_false(is.null(cond))
  expect_equal(cond$pars$draw_type, "random")
  expect_equal(cond$pars$seed, 99L)
  expect_equal(cond$env$MAT, 6)
  expect_equal(cond$env$MAP, 900)
  expect_equal(cond$ctrl$years, 5L)
  expect_equal(cond$stand, s)
})

test_that("project() with time-varying MAT records function in conditions", {
  s    <- make_abibal_stand()
  mod  <- species_model(s)
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = function(t) 6 + t * 0.1, MAP = 1200)
  ctrl <- control(years = 3, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_equal(proj$conditions$env$MAT, env$MAT)
})

# ---------------------------------------------------------------------------
# supported_species()
# ---------------------------------------------------------------------------
test_that("supported_species() returns a data frame with species_id column", {
  sp <- supported_species()
  expect_s3_class(sp, "data.frame")
  expect_true("species_id" %in% names(sp))
  expect_true("ABIBAL" %in% sp$species_id)
})

# ---------------------------------------------------------------------------
# stand() input validation
# ---------------------------------------------------------------------------
test_that("stand() rejects trees below minimum DBH threshold (127mm)", {
  df_small <- data.frame(size_mm = c(100, 120), species_id = "ABIBAL", plot_size = 400)
  expect_error(stand(df_small))
})

# ---------------------------------------------------------------------------
# Two-species project() workflow
# ---------------------------------------------------------------------------
make_two_sp_stand <- function() {
  stand(data.frame(
    size_mm    = c(seq(130, 600, length.out = 8),  seq(150, 550, length.out = 20)),
    species_id = c(rep("ABIBAL", 8),               rep("ACERUB", 6)),
    plot_size  = 1000
  ))
}

make_two_sp_mod <- function() species_model(make_two_sp_stand())

make_two_sp_pars_wf <- function() parameters(make_two_sp_mod(), draw = "mean")

test_that("`project()` allows single species dynamics - drop on missing", {
  s    <- make_two_sp_stand()
  mod  <- species_model("ABIBAL", on_missing = "drop")
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_s3_class(proj, "ipm_projection")
  expect_setequal(proj$species, c("ABIBAL"))
})

test_that("`project()` allows single species dynamics - static on missing", {
  s    <- make_two_sp_stand()
  mod  <- species_model("ABIBAL", on_missing = "static")
  pars <- parameters(mod, draw = "mean")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_s3_class(proj, "ipm_projection")
  expect_setequal(proj$species, c("ABIBAL"))
})

test_that("lambda under `static` is larger than on `drop`", {
  s    <- make_two_sp_stand()
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  mod  <- species_model("ABIBAL", on_missing = "static")
  pars <- parameters(mod, draw = "mean")
  proj_comp <- project(mod, pars, s, env, ctrl)
  mod  <- species_model("ABIBAL", on_missing = "drop")
  proj_noComp <- project(mod, pars, s, env, ctrl)
  expect_all_true(proj_comp$lambda$ABIBAL < proj_noComp$lambda$ABIBAL)
})

test_that("project() with two species returns both in $species", {
  s    <- make_two_sp_stand()
  mod  <- make_two_sp_mod()
  pars <- make_two_sp_pars_wf()
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_s3_class(proj, "ipm_projection")
  expect_setequal(proj$species, c("ABIBAL", "ACERUB"))
})

test_that("project() two-species lambda is finite and positive for both species", {
  s    <- make_two_sp_stand()
  mod  <- make_two_sp_mod()
  pars <- make_two_sp_pars_wf()
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_true(all(is.finite(proj$lambda[["ABIBAL"]])))
  expect_true(all(proj$lambda[["ABIBAL"]] > 0))
  expect_true(all(is.finite(proj$lambda[["ACERUB"]])))
  expect_true(all(proj$lambda[["ACERUB"]] > 0))
})

test_that("project() two-species summary has rows for both species at every timestep", {
  s    <- make_two_sp_stand()
  mod  <- make_two_sp_mod()
  pars <- make_two_sp_pars_wf()
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_true("ABIBAL" %in% proj$summary$species_id)
  expect_true("ACERUB" %in% proj$summary$species_id)
  expect_equal(nrow(proj$summary), 2L * length(proj$years))
})

test_that("project() two-species stand_series snapshots contain both species", {
  s    <- make_two_sp_stand()
  mod  <- make_two_sp_mod()
  pars <- make_two_sp_pars_wf()
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  last_snap <- proj$stand_series[[length(proj$stand_series)]]
  expect_true("ABIBAL" %in% names(last_snap$distributions))
  expect_true("ACERUB" %in% names(last_snap$distributions))
})

test_that("project() two-species with compute_lambda = FALSE returns NA lambda for both", {
  s    <- make_two_sp_stand()
  mod  <- make_two_sp_mod()
  pars <- make_two_sp_pars_wf()
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = FALSE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_true(all(is.na(proj$lambda[["ABIBAL"]])))
  expect_true(all(is.na(proj$lambda[["ACERUB"]])))
})

test_that("project() two-species with random effects on one species still produces finite output for both", {
  s    <- make_two_sp_stand()
  mod  <- make_two_sp_mod()
  pars <- set_random_effects(make_two_sp_pars_wf(), values = c(0.1, -0.1, 0.05), species = "ABIBAL")
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_true(all(is.finite(proj$lambda[["ABIBAL"]])))
  expect_true(all(is.finite(proj$lambda[["ACERUB"]])))
})

test_that("project() two-species with different random effects per species produces finite output", {
  s    <- make_two_sp_stand()
  mod  <- make_two_sp_mod()
  pars <- set_random_effects(
    make_two_sp_pars_wf(),
    values = list(ABIBAL = c(0.1, -0.1, 0.0), ACERUB = c(-0.1, 0.1, 0.0))
  )
  env  <- env_condition(MAT = 8, MAP = 1200)
  ctrl <- control(years = 5, compute_lambda = TRUE, progress = FALSE)
  proj <- project(mod, pars, s, env, ctrl)
  expect_true(all(is.finite(proj$lambda[["ABIBAL"]])))
  expect_true(all(is.finite(proj$lambda[["ACERUB"]])))
})
