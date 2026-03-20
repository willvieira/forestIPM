# Tests for Phase 02-02: API constructors and engines

# --- env_condition() ---

test_that("env_condition() accepts numeric scalars and returns ipm_env", {
  env <- env_condition(MAT = 8, MAP = 1200)
  expect_s3_class(env, "ipm_env")
  expect_equal(env$MAT, 8)
  expect_equal(env$MAP, 1200)
})

test_that("env_condition() accepts function(t) for MAT", {
  env <- env_condition(MAT = function(t) 8 + 0.02 * t, MAP = 1200)
  expect_s3_class(env, "ipm_env")
  expect_true(is.function(env$MAT))
})

# --- control() ---

test_that("control() returns ipm_control with correct defaults", {
  ctrl <- control()
  expect_s3_class(ctrl, "ipm_control")
  expect_equal(ctrl$years, 100)
  expect_equal(ctrl$delta_time, 1)
  expect_equal(ctrl$store_every, 1)
  expect_equal(ctrl$bin_width, 1)
})

test_that("control() accepts custom values", {
  ctrl <- control(years = 50, delta_time = 0.5)
  expect_equal(ctrl$years, 50)
  expect_equal(ctrl$delta_time, 0.5)
})

# --- supported_species() ---

test_that("supported_species() returns a tibble with required columns", {
  sp <- supported_species()
  expect_true(inherits(sp, "tbl_df"))
  expect_gt(nrow(sp), 0L)
  expect_true("species_id" %in% names(sp))
  expect_true("common_name" %in% names(sp))
})

# --- stand() ---

test_that("stand() returns ipm_stand with $trees, $species, $plot_size", {
  df <- data.frame(
    size_mm = c(150, 200, 300),
    species_id = "ABIBAL",
    plot_size = 1000
  )
  s <- stand(df)
  expect_s3_class(s, "ipm_stand")
  expect_true(!is.null(s$trees))
  expect_true(!is.null(s$species))
  expect_true(!is.null(s$plot_size))
})

test_that("stand() rejects trees smaller than 127 mm with an error", {
  df <- data.frame(
    size_mm = c(100, 200),
    species_id = "ABIBAL",
    plot_size = 1000
  )
  expect_error(stand(df))
})

# --- species_model() ---

test_that("species_model() returns ipm_spModel with $species, $params, $on_missing", {
  df <- data.frame(size_mm = c(150, 200, 300), species_id = "ABIBAL", plot_size = 1000)
  s <- stand(df)
  mod <- species_model(s)
  expect_s3_class(mod, "ipm_spModel")
  expect_true("species" %in% names(mod))
  expect_true("params" %in% names(mod))
  expect_true("on_missing" %in% names(mod))
})

test_that("species_model() errors on unknown species", {
  df <- data.frame(size_mm = c(150, 200), species_id = "FAKESPP", plot_size = 1000)
  s <- stand(df)
  expect_error(species_model(s))
})

# --- parameters() ---

test_that("parameters() returns ipm_parameters with required structure", {
  df <- data.frame(size_mm = c(150, 200, 300), species_id = "ABIBAL", plot_size = 1000)
  s <- stand(df)
  mod <- species_model(s)
  p <- parameters(mod, draw = "random", seed = 42L)
  expect_s3_class(p, "ipm_parameters")
  expect_true("species_params" %in% names(p))
  expect_true("draw_type" %in% names(p))
  expect_true("seed" %in% names(p))
})

# --- set_random_effects() ---

make_pars <- function() {
  df  <- data.frame(size_mm = c(150, 200, 300), species_id = "ABIBAL", plot_size = 1000)
  mod <- species_model(stand(df))
  parameters(mod, draw = "mean")
}

test_that("set_random_effects() rejects non-ipm_parameters input", {
  expect_error(set_random_effects(list(), values = c(0, 0, 0)))
})

test_that("set_random_effects() with numeric(3) and species=NULL applies to all species", {
  pars2 <- set_random_effects(make_pars(), values = c(0.1, 0.2, 0.3))
  expect_equal(pars2$species_params[["ABIBAL"]]$random_effects, c(0.1, 0.2, 0.3))
})

test_that("set_random_effects() with numeric(3) and specific species applies only to that species", {
  pars2 <- set_random_effects(make_pars(), values = c(0.5, 0.6, 0.7), species = "ABIBAL")
  expect_equal(pars2$species_params[["ABIBAL"]]$random_effects, c(0.5, 0.6, 0.7))
})

test_that("set_random_effects() with named list applies per species", {
  pars2 <- set_random_effects(make_pars(), values = list(ABIBAL = c(1.0, 2.0, 3.0)))
  expect_equal(pars2$species_params[["ABIBAL"]]$random_effects, c(1.0, 2.0, 3.0))
})

test_that("set_random_effects() returns an ipm_parameters object", {
  pars2 <- set_random_effects(make_pars(), values = c(0, 0, 0))
  expect_s3_class(pars2, "ipm_parameters")
})

test_that("set_random_effects() rejects values of wrong length", {
  expect_error(set_random_effects(make_pars(), values = c(0, 0)))
  expect_error(set_random_effects(make_pars(), values = c(0, 0, 0, 0)))
})

test_that("set_random_effects() rejects non-numeric values", {
  expect_error(set_random_effects(make_pars(), values = c("a", "b", "c")))
})

test_that("set_random_effects() rejects unknown species in vector path", {
  expect_error(set_random_effects(make_pars(), values = c(0, 0, 0), species = "FAKESPP"))
})

test_that("set_random_effects() rejects unknown species in list path", {
  expect_error(set_random_effects(make_pars(), values = list(FAKESPP = c(0, 0, 0))))
})

test_that("set_random_effects() with named list rejects wrong-length vector per species", {
  expect_error(set_random_effects(make_pars(), values = list(ABIBAL = c(0, 0))))
})

# --- set_random_effects() multi-species ---

make_two_sp_pars <- function() {
  df <- data.frame(
    size_mm    = c(150, 200, 300, 180, 250),
    species_id = c("ABIBAL", "ABIBAL", "ABIBAL", "ACERUB", "ACERUB"),
    plot_size  = 1000
  )
  mod <- species_model(stand(df))
  parameters(mod, draw = "mean")
}

test_that("set_random_effects() assigns to only one species, leaving the other NULL", {
  pars2 <- set_random_effects(make_two_sp_pars(), values = c(0.1, 0.2, 0.3), species = "ABIBAL")
  expect_equal(pars2$species_params[["ABIBAL"]]$random_effects, c(0.1, 0.2, 0.3))
  expect_null(pars2$species_params[["ACERUB"]]$random_effects)
})

test_that("set_random_effects() assigns same values to both species via species=NULL", {
  pars2 <- set_random_effects(make_two_sp_pars(), values = c(0.5, 0.6, 0.7))
  expect_equal(pars2$species_params[["ABIBAL"]]$random_effects, c(0.5, 0.6, 0.7))
  expect_equal(pars2$species_params[["ACERUB"]]$random_effects, c(0.5, 0.6, 0.7))
})

test_that("set_random_effects() assigns different values per species via named list", {
  pars2 <- set_random_effects(
    make_two_sp_pars(),
    values = list(ABIBAL = c(1.0, 2.0, 3.0), ACERUB = c(4.0, 5.0, 6.0))
  )
  expect_equal(pars2$species_params[["ABIBAL"]]$random_effects, c(1.0, 2.0, 3.0))
  expect_equal(pars2$species_params[["ACERUB"]]$random_effects, c(4.0, 5.0, 6.0))
})

test_that("set_random_effects() list path rejects unknown second species, leaving valid one unchanged", {
  pars0 <- make_two_sp_pars()
  expect_error(
    set_random_effects(pars0, values = list(ABIBAL = c(1, 2, 3), FAKESPP = c(0, 0, 0)))
  )
})
