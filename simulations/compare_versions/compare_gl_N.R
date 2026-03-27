##############################################################
# compare_gl_N.R
# Accuracy check for Gauss-Legendre quadrature: effect of n_gl
# on equilibrium total population size (N).
#
# Parallel to compare_versions_gl.R (which checks lambda), this
# script runs density-dependent IPM projections from the observed
# stand state to equilibrium and reports the total N at convergence
# for each n_gl value.
#
# Reports convergence across n_gl = 20, 50, 100, 200, 500 and
# compares GL equilibrium N vs. midpoint rule (h=1).
#
# Usage: source("simulations/compare_versions/compare_gl_N.R")
# from the project root.
##############################################################


# ============================================================
# 0. Guard and package load
# ============================================================
stopifnot(file.exists("DESCRIPTION"))
devtools::load_all()
library(tidyverse)


# ============================================================
# 1. Constants (same as compare_versions_gl.R)
# ============================================================
SIM_DIR      <- "simulations/covariates_perturbation"
DATA_DIR     <- readLines("_data.path")
REPLICATIONS <- 100L
MISSING_IDS  <- c(32794L, 33256L, 33257L, 171478L, 195665L, 201283L)
GL_SIZES     <- c(20L, 50L, 100L, 200L, 500L)
GL_TOL       <- 0.05        # acceptable relative deviation from GL(500) reference

# IPM projection settings
N_YEARS_MAX  <- 500L        # maximum projection steps
CONV_TOL     <- 1e-6        # relative change in sum(N) to declare convergence
CONV_STEPS   <- 10L         # consecutive steps within tolerance to declare convergence


# ============================================================
# 2. Inline helpers (same as compare_versions_gl.R)
# ============================================================
pars_to_list <- function(pars) {
  pars |>
    select(contains('.')) |>
    pivot_longer(cols = everything()) |>
    mutate(
      vr  = str_replace(name, '\\..*', ''),
      par = str_replace(name, paste0(vr, '.'), ''),
      vr  = case_match(vr, 'recruit' ~ 'rec', .default = vr)
    ) |>
    select(!name) |>
    group_split(vr) ->
  pars_l

  set_names(
    pars_l,
    pars_l |> map_chr(~.x$vr[1])
  ) |>
    map(~.x |> select(!vr) |> pivot_wider(names_from = par) |> unlist(use.names = TRUE))
}

# Midpoint-based empty mesh (matches original init_pop, N=0 path)
init_pop_midpt <- function(params, L = 127, h = 1) {
  Lmax <- ceiling(params[["growth"]]["Lmax"])
  m    <- length(seq(L, Lmax, h))
  msh  <- L + ((seq_len(m)) - 0.5) * h
  list(meshpts = msh, Nvec = rep(0, m), h = h, weights = rep(h, m))
}

# GL-based empty mesh
init_pop_gl <- function(params, L = 127, n_gl = 50L) {
  Lmax <- ceiling(params[["growth"]]["Lmax"])
  gl   <- .gl_nodes_weights(n_gl, a = L, b = Lmax)
  list(meshpts = gl$nodes, Nvec = rep(0.0, n_gl), h = NA_real_, weights = gl$weights)
}

# Bin DBH values onto nearest GL node
dbh_to_sizeDist_gl <- function(dbh, N_gl) {
  msh        <- N_gl$meshpts
  bins       <- vapply(dbh, function(sz) which.min(abs(msh - sz)), integer(1L))
  N_out      <- N_gl
  N_out$Nvec <- tabulate(bins, nbins = length(msh)) * 1.0
  N_out
}

scale_vars <- function(value, cov, direction, range_dt = vars_rg) {
  cov_rg <- range_dt[[cov]]
  min_v  <- cov_rg[1]
  max_v  <- cov_rg[2]
  if (direction == 'scale')   return((value - min_v) / (max_v - min_v))
  if (direction == 'unscale') return(value * (max_v - min_v) + min_v)
  stop('`direction` must be "scale" or "unscale"')
}

# Run density-dependent IPM projection to equilibrium; return sum(N) at convergence.
# N_con_init: initial intraspecific N vector (list with meshpts, Nvec, weights)
# N_het: fixed interspecific N vector (same format)
run_to_equil <- function(N_con_init, N_het, plot_size, temp_scl, prec_scl,
                          pars_i, re_i, delta_time = 1) {
  N_con     <- N_con_init
  nochange  <- 0L
  N_prev    <- sum(N_con$Nvec)

  for (t in seq_len(N_YEARS_MAX)) {
    K  <- mkKernel(N_con, N_het, delta_time, plot_size, temp_scl, prec_scl, pars_i, re_i)$K
    N_con$Nvec <- as.numeric(K %*% N_con$Nvec)
    N_curr     <- sum(N_con$Nvec)

    if (N_prev > 0 && abs(N_curr - N_prev) / N_prev < CONV_TOL) {
      nochange <- nochange + 1L
    } else {
      nochange <- 0L
    }
    if (nochange >= CONV_STEPS) break
    if (!is.finite(N_curr) || N_curr <= 0) break
    N_prev <- N_curr
  }

  list(N = N_curr, BA = size_to_BAplot(N_con, plot_size))
}


# ============================================================
# 3. Load scaling ranges
# ============================================================
vars_rg <- append(
  setNames(readRDS(file.path(DATA_DIR, "climate_scaleRange.RDS")), c("temp", "prec")),
  list("dbh" = readRDS(file.path(SIM_DIR, "dbh_range.RDS")))
)


# ============================================================
# 4. Stratified row selection (same as compare_versions_gl.R)
# ============================================================
selected_rows <- c(
  1L, 884L, 5000L, 22234L, 25000L, 31527L, 32448L,
  2266L, 22235L, 10000L, 22236L, 15000L, 31528L, 1963L, 20000L
)
stopifnot(!any(selected_rows %in% MISSING_IDS))
stopifnot(length(unique(selected_rows)) == length(selected_rows))


# ============================================================
# 5. Load big files once
# ============================================================
cat("Loading data files...\n")
sim_pars_all <- readRDS(file.path(SIM_DIR, "simulation_pars.RDS"))
pop_pars_all <- readRDS(file.path(SIM_DIR, "pop_pars.RDS"))
cat("Data loaded.\n")

stopifnot(nrow(sim_pars_all) == 216027)


# ============================================================
# 6. Per-row comparison function
#    Returns: midpoint equilibrium N and GL equilibrium N for
#             each n_gl value, averaged across REPLICATIONS.
# ============================================================
compare_row_N <- function(array_id) {
  sim_pars  <- sim_pars_all[array_id, ]
  Sp        <- sim_pars$species_id
  plot_size <- sim_pars$plot_size
  temp_scl  <- scale_vars(sim_pars$bio_01_mean, "temp", "scale")
  prec_scl  <- scale_vars(sim_pars$bio_12_mean, "prec", "scale")

  set.seed(array_id)
  pop_pars <- pop_pars_all |>
    filter(species_id == Sp) |>
    select(!species_id) |>
    slice_sample(n = REPLICATIONS)

  plot_pars_list <- readRDS(file.path(SIM_DIR, "plot_parameters", paste0(Sp, ".RDS"))) |>
    filter(plot_id == sim_pars$plot_id, year_measured == sim_pars$year_measured) |>
    pull(plot_pars)
  plot_pars <- plot_pars_list[[1]]

  het_is_null <- is.null(unlist(sim_pars$het_dbh))
  con_dbh     <- unlist(sim_pars$con_dbh)

  # --- Midpoint equilibrium N and BA ---
  midpt_N  <- numeric(REPLICATIONS)
  midpt_BA <- numeric(REPLICATIONS)
  for (i in seq_len(REPLICATIONS)) {
    pars_i <- pars_to_list(pop_pars[i, ])
    re_i   <- plot_pars[i, ] |> unlist() |> unname()
    N_ref  <- init_pop_midpt(pars_i)
    N_con  <- dbh_to_sizeDist(dbh = con_dbh, N_intra = N_ref)
    N_het  <- if (het_is_null) N_ref else dbh_to_sizeDist(dbh = unlist(sim_pars$het_dbh), N_intra = N_ref)
    res_i      <- run_to_equil(N_con, N_het, plot_size, temp_scl, prec_scl, pars_i, re_i)
    midpt_N[i]  <- res_i$N
    midpt_BA[i] <- res_i$BA
  }

  # --- GL equilibrium N and BA for each n_gl ---
  gl_N  <- setNames(vector("list", length(GL_SIZES)), paste0("gl_", GL_SIZES))
  gl_BA <- setNames(vector("list", length(GL_SIZES)), paste0("gl_", GL_SIZES))
  for (n_gl in GL_SIZES) {
    key   <- paste0("gl_", n_gl)
    n_vals <- numeric(REPLICATIONS)
    b_vals <- numeric(REPLICATIONS)
    for (i in seq_len(REPLICATIONS)) {
      pars_i <- pars_to_list(pop_pars[i, ])
      re_i   <- plot_pars[i, ] |> unlist() |> unname()
      N_ref  <- init_pop_gl(pars_i, n_gl = n_gl)
      N_con  <- dbh_to_sizeDist_gl(dbh = con_dbh, N_gl = N_ref)
      N_het  <- if (het_is_null) N_ref else dbh_to_sizeDist_gl(dbh = unlist(sim_pars$het_dbh), N_gl = N_ref)
      res_i      <- run_to_equil(N_con, N_het, plot_size, temp_scl, prec_scl, pars_i, re_i)
      n_vals[i]  <- res_i$N
      b_vals[i]  <- res_i$BA
    }
    gl_N[[key]]  <- mean(n_vals, na.rm = TRUE)
    gl_BA[[key]] <- mean(b_vals, na.rm = TRUE)
  }

  list(
    array_id  = array_id,
    species   = Sp,
    het_null  = het_is_null,
    midpt_N   = mean(midpt_N,  na.rm = TRUE),
    midpt_BA  = mean(midpt_BA, na.rm = TRUE),
    gl_N      = gl_N,
    gl_BA     = gl_BA
  )
}


# ============================================================
# 7. Main execution
# ============================================================
cat(sprintf(
  "Running GL N accuracy check for %d rows × %d n_gl values × %d draws...\n\n",
  length(selected_rows), length(GL_SIZES), REPLICATIONS
))

results <- lapply(selected_rows, function(id) {
  cat(sprintf("  Row %6d ... ", id))
  res <- tryCatch(
    compare_row_N(id),
    error = function(e) {
      cat(sprintf("ERROR: %s\n", conditionMessage(e)))
      list(
        array_id = id, species = NA, het_null = NA,
        midpt_N  = NA_real_,
        gl_N     = setNames(as.list(rep(NA_real_, length(GL_SIZES))), paste0("gl_", GL_SIZES))
      )
    }
  )
  cat(sprintf(
    "midpt N=%.1f BA=%.3f  gl_%d N=%.1f BA=%.3f\n",
    res$midpt_N,
    res$midpt_BA %||% NA,
    GL_SIZES[length(GL_SIZES)],
    res$gl_N[[paste0("gl_", GL_SIZES[length(GL_SIZES)])]],
    res$gl_BA[[paste0("gl_", GL_SIZES[length(GL_SIZES)])]] %||% NA
  ))
  res
})


# ============================================================
# 8. Summary tables
# ============================================================

# 8a. Equilibrium N values by method
cat("\n=== EQUILIBRIUM N VALUES BY METHOD ===\n")
cat(sprintf("%-10s %-16s %10s %s\n",
            "array_id", "species", "midpoint",
            paste(sprintf("GL(%d)", GL_SIZES), collapse = "  ")))
cat(strrep("-", 90), "\n")

for (r in results) {
  gl_vals <- sapply(paste0("gl_", GL_SIZES), function(k) r$gl_N[[k]])
  cat(sprintf("%-10d %-16s %10.2f  %s\n",
              r$array_id, r$species %||% "NA",
              r$midpt_N %||% NA,
              paste(sprintf("%10.2f", gl_vals), collapse = "  ")))
}

# 8a2. Equilibrium BA values by method
cat("\n=== EQUILIBRIUM BA (m2/ha) VALUES BY METHOD ===\n")
cat(sprintf("%-10s %-16s %10s %s\n",
            "array_id", "species", "midpoint",
            paste(sprintf("GL(%d)", GL_SIZES), collapse = "  ")))
cat(strrep("-", 90), "\n")

for (r in results) {
  gl_vals <- sapply(paste0("gl_", GL_SIZES), function(k) r$gl_BA[[k]])
  cat(sprintf("%-10d %-16s %10.4f  %s\n",
              r$array_id, r$species %||% "NA",
              r$midpt_BA %||% NA,
              paste(sprintf("%10.4f", gl_vals), collapse = "  ")))
}

# 8b. Relative deviation from GL(max_n)
ref_key <- paste0("gl_", GL_SIZES[length(GL_SIZES)])
cat(sprintf("\n=== RELATIVE DEVIATION FROM GL(%d): |GL(n) - GL(%d)| / GL(%d) ===\n",
            GL_SIZES[length(GL_SIZES)], GL_SIZES[length(GL_SIZES)], GL_SIZES[length(GL_SIZES)]))
cat(sprintf("%-10s %-16s %10s %s\n",
            "array_id", "species", "midpt_dev",
            paste(sprintf("GL(%d)_dev", GL_SIZES[-length(GL_SIZES)]), collapse = "  ")))
cat(strrep("-", 90), "\n")

for (r in results) {
  ref_N     <- r$gl_N[[ref_key]]
  midpt_dev <- if (!is.na(ref_N) && ref_N > 0) abs(r$midpt_N - ref_N) / ref_N else NA_real_
  gl_devs   <- sapply(
    paste0("gl_", GL_SIZES[-length(GL_SIZES)]),
    function(k) if (!is.na(ref_N) && ref_N > 0) abs(r$gl_N[[k]] - ref_N) / ref_N else NA_real_
  )
  cat(sprintf("%-10d %-16s %10.4f  %s\n",
              r$array_id, r$species %||% "NA",
              midpt_dev,
              paste(sprintf("%9.4f", gl_devs), collapse = "  ")))
}

# 8c. GL convergence: |GL(n) - GL(max_n)| independent of midpoint
cat(sprintf("\n=== GL CONVERGENCE: |GL(n) - GL(%d)| / GL(%d) ===\n",
            GL_SIZES[length(GL_SIZES)], GL_SIZES[length(GL_SIZES)]))
convergence_sizes <- GL_SIZES[-length(GL_SIZES)]
cat(sprintf("%-10s %-16s %s\n",
            "array_id", "species",
            paste(sprintf("GL(%d)", convergence_sizes), collapse = "  ")))
cat(strrep("-", 70), "\n")

for (r in results) {
  ref_N     <- r$gl_N[[ref_key]]
  conv_devs <- sapply(
    paste0("gl_", convergence_sizes),
    function(k) if (!is.na(ref_N) && ref_N > 0) abs(r$gl_N[[k]] - ref_N) / ref_N else NA_real_
  )
  cat(sprintf("%-10d %-16s %s\n",
              r$array_id, r$species %||% "NA",
              paste(sprintf("%8.4f", conv_devs), collapse = "  ")))
}

# 8d. Pass/fail summary (relative tolerance vs GL(500))
cat(sprintf("\n=== PASS/FAIL SUMMARY (relative GL tolerance: %g) ===\n", GL_TOL))
for (n_gl in GL_SIZES[-length(GL_SIZES)]) {
  key   <- paste0("gl_", n_gl)
  devs  <- sapply(results, function(r) {
    ref_N <- r$gl_N[[ref_key]]
    if (!is.na(ref_N) && ref_N > 0) abs(r$gl_N[[key]] - ref_N) / ref_N else NA_real_
  })
  n_pass <- sum(devs < GL_TOL, na.rm = TRUE)
  max_d  <- max(devs, na.rm = TRUE)
  cat(sprintf("  GL(%3d): %d/%d PASS  max_rel_dev = %.4f\n",
              n_gl, n_pass, length(results), max_d))
}

midpt_devs <- sapply(results, function(r) {
  ref_N <- r$gl_N[[ref_key]]
  if (!is.na(ref_N) && ref_N > 0) abs(r$midpt_N - ref_N) / ref_N else NA_real_
})
cat(sprintf("  midpt  : %d/%d PASS  max_rel_dev = %.4f  (tol=%g)\n",
            sum(midpt_devs < GL_TOL, na.rm = TRUE), length(results),
            max(midpt_devs, na.rm = TRUE), GL_TOL))


# ============================================================
# 9. Save outputs as RDS
# ============================================================
OUT_DIR <- "simulations/compare_versions"

# 9a. Raw results list
saveRDS(results, file.path(OUT_DIR, "results_gl_N.RDS"))

# 9b. Tidy table: one row per (array_id x method), with N and BA
tbl_N_BA <- do.call(rbind, lapply(results, function(r) {
  # midpoint row
  midpt_row <- data.frame(
    array_id = r$array_id,
    species  = r$species %||% NA_character_,
    het_null = r$het_null %||% NA,
    method   = "midpoint",
    n_gl     = NA_integer_,
    N        = r$midpt_N  %||% NA_real_,
    BA       = r$midpt_BA %||% NA_real_
  )
  # GL rows
  gl_rows <- do.call(rbind, lapply(GL_SIZES, function(n_gl) {
    key <- paste0("gl_", n_gl)
    data.frame(
      array_id = r$array_id,
      species  = r$species %||% NA_character_,
      het_null = r$het_null %||% NA,
      method   = "GL",
      n_gl     = n_gl,
      N        = r$gl_N[[key]]  %||% NA_real_,
      BA       = r$gl_BA[[key]] %||% NA_real_
    )
  }))
  rbind(midpt_row, gl_rows)
}))
saveRDS(tbl_N_BA, file.path(OUT_DIR, "table_gl_N_BA.RDS"))

# 9c. Deviation table relative to GL(max_n)
ref_key <- paste0("gl_", GL_SIZES[length(GL_SIZES)])
tbl_dev <- do.call(rbind, lapply(results, function(r) {
  ref_N  <- r$gl_N[[ref_key]]  %||% NA_real_
  ref_BA <- r$gl_BA[[ref_key]] %||% NA_real_
  rows <- lapply(c("midpoint", paste0("GL_", GL_SIZES[-length(GL_SIZES)])), function(m) {
    if (m == "midpoint") {
      n_val  <- r$midpt_N  %||% NA_real_
      ba_val <- r$midpt_BA %||% NA_real_
      n_gl   <- NA_integer_
    } else {
      n_gl_val <- as.integer(sub("GL_", "", m))
      key    <- paste0("gl_", n_gl_val)
      n_val  <- r$gl_N[[key]]  %||% NA_real_
      ba_val <- r$gl_BA[[key]] %||% NA_real_
      n_gl   <- n_gl_val
    }
    data.frame(
      array_id  = r$array_id,
      species   = r$species %||% NA_character_,
      method    = m,
      n_gl      = n_gl,
      N_dev     = if (!is.na(ref_N)  && ref_N  > 0) abs(n_val  - ref_N)  / ref_N  else NA_real_,
      BA_dev    = if (!is.na(ref_BA) && ref_BA > 0) abs(ba_val - ref_BA) / ref_BA else NA_real_
    )
  })
  do.call(rbind, rows)
}))
saveRDS(tbl_dev, file.path(OUT_DIR, "table_gl_deviations.RDS"))

cat(sprintf(
  "\nOutputs saved to %s/:\n  results_gl_N.RDS\n  table_gl_N_BA.RDS\n  table_gl_deviations.RDS\n",
  OUT_DIR
))


# ============================================================
# 10. Single-rep trajectory function
#     Runs the model to equilibrium for one (array_id, rep)
#     pair, tracking lambda, N, and BA at every time step
#     for both midpoint and all GL integration methods.
#
# Arguments:
#   array_id  - row index into sim_pars_all (same as elsewhere)
#   rep       - integer in 1:REPLICATIONS selecting which
#               parameter draw to use (uses the same
#               set.seed(array_id) draw order as compare_row_N)
#   gl_sizes  - GL node counts to include (default: GL_SIZES)
#
# Returns a list:
#   $array_id, $rep, $species
#   $traj  - data.frame with columns:
#              method, n_gl, t, lambda, N, BA
# ============================================================
run_rep_trajectory <- function(array_id, rep, gl_sizes = GL_SIZES) {

  # --- simulation covariates ---
  sim_pars  <- sim_pars_all[array_id, ]
  Sp        <- sim_pars$species_id
  plot_size <- sim_pars$plot_size
  temp_scl  <- scale_vars(sim_pars$bio_01_mean, "temp", "scale")
  prec_scl  <- scale_vars(sim_pars$bio_12_mean, "prec", "scale")

  # --- parameter draw (reproduce same sample order as compare_row_N) ---
  set.seed(array_id)
  pop_pars <- pop_pars_all |>
    filter(species_id == Sp) |>
    select(!species_id) |>
    slice_sample(n = REPLICATIONS)

  pars_i <- pars_to_list(pop_pars[rep, ])

  plot_pars_list <- readRDS(
    file.path(SIM_DIR, "plot_parameters", paste0(Sp, ".RDS"))
  ) |>
    filter(plot_id == sim_pars$plot_id, year_measured == sim_pars$year_measured) |>
    pull(plot_pars)
  re_i <- plot_pars_list[[1]][rep, ] |> unlist() |> unname()

  het_is_null <- is.null(unlist(sim_pars$het_dbh))
  con_dbh     <- unlist(sim_pars$con_dbh)

  # --- inner loop: project to equilibrium and record trajectory ---
  # Each step records N and BA computed two ways:
  #   _nowt : sum(Nvec)            / sum(BAind * Nvec)          -- no quadrature weights
  #   _wt   : sum(Nvec * weights)  / sum(BAind * Nvec * weights) -- with quadrature weights
  # For midpoint (weights = h = 1) the two are identical.
  # Convergence is judged on the weighted N.
  run_trajectory <- function(N_con_init, N_het) {
    N_con_nowt   <- N_con_wt <- N_con_init
    nochange     <- 0L
    rows         <- vector("list", N_YEARS_MAX)
    N_prev_nowt  <- sum(N_con_nowt$Nvec)
    N_prev_wt  <- sum(N_con_wt$Nvec * N_con_wt$weights)

    for (t in seq_len(N_YEARS_MAX)) {
      K_nowt     <- mkKernel(N_con_nowt, N_het, 1, plot_size, temp_scl, prec_scl, pars_i, re_i, uw = FALSE)$K
      K_wt       <- mkKernel(N_con_wt, N_het, 1, plot_size, temp_scl, prec_scl, pars_i, re_i, uw = TRUE)$K
      
      N_con_nowt$Nvec <- as.numeric(K_nowt %*% N_con_nowt$Nvec)
      N_con_wt$Nvec <- as.numeric(K_wt %*% N_con_wt$Nvec)

      BAind_nowt      <- pi * (N_con_nowt$meshpts / 2 * 1e-3)^2
      BAind_wt        <- pi * (N_con_wt$meshpts / 2 * 1e-3)^2

      N_nowt     <- sum(N_con_nowt$Nvec)
      N_wt       <- sum(N_con_wt$Nvec * N_con_wt$weights)
      BA_nowt    <- sum(BAind_nowt * N_con_nowt$Nvec * 1e4 / plot_size)
      BA_wt      <- sum(BAind_wt * N_con_wt$Nvec * N_con_wt$weights * 1e4 / plot_size)

      r_nowt <- if (is.finite(N_prev_nowt) && N_prev_nowt > 0) N_nowt / N_prev_nowt else NA_real_
      r_wt   <- if (is.finite(N_prev_wt) && N_prev_wt > 0) N_wt   / N_prev_wt else NA_real_

      rows[[t]] <- data.frame(
        t           = t,
        lambda_nowt = max(getEigenValues(K_nowt)),
        lambda_wt   = max(getEigenValues(K_wt)),
        r_nowt      = r_nowt,
        r_wt        = r_wt,
        N_nowt      = N_nowt,
        N_wt        = N_wt,
        BA_nowt     = BA_nowt,
        BA_wt       = BA_wt
      )

      if (is.finite(N_prev_wt) && N_prev_wt > 0 &&
          abs(N_wt - N_prev_wt) / N_prev_wt < CONV_TOL) {
        nochange <- nochange + 1L
      } else {
        nochange <- 0L
      }
      if (nochange >= CONV_STEPS) break
      if (!is.finite(N_wt) || N_wt <= 0) break
      N_prev_nowt <- N_nowt
      N_prev_wt <- N_wt
    }

    do.call(rbind, rows[seq_len(t)])
  }

  # --- midpoint trajectory ---
  N_ref_mp <- init_pop_midpt(pars_i)
  N_con_mp <- dbh_to_sizeDist(dbh = con_dbh, N_intra = N_ref_mp)
  N_het_mp <- if (het_is_null) N_ref_mp else
    dbh_to_sizeDist(dbh = unlist(sim_pars$het_dbh), N_intra = N_ref_mp)
  mp_traj        <- run_trajectory(N_con_mp, N_het_mp)
  mp_traj$method <- "midpoint"
  mp_traj$ngl   <- NA_integer_

  # --- GL trajectories ---
  gl_trajs <- lapply(gl_sizes, function(n_gl) {
    N_ref_gl <- init_pop_gl(pars_i, n_gl = n_gl)
    N_con_gl <- dbh_to_sizeDist_gl(dbh = con_dbh, N_gl = N_ref_gl)
    N_het_gl <- if (het_is_null) N_ref_gl else
      dbh_to_sizeDist_gl(dbh = unlist(sim_pars$het_dbh), N_gl = N_ref_gl)
    traj        <- run_trajectory(N_con_gl, N_het_gl)
    traj$method <- paste0("GL_", n_gl)
    traj$ngl   <- n_gl
    traj
  })

  traj_all <- do.call(rbind, c(list(mp_traj), gl_trajs))
  traj_all <- traj_all[, c("method", "ngl", "t",
                            "lambda_nowt", "lambda_wt",
                            "N_nowt", "N_wt",
                            "BA_nowt", "BA_wt")]
  rownames(traj_all) <- NULL

  list(array_id = array_id, rep = rep, species = Sp, traj = traj_all)
}

# Example usage (not run automatically):
res5 <- run_rep_trajectory(array_id = selected_rows[5], rep = 1L)

out <- res4$traj |>
  filter(!method %in% c("GL_20", "GL_50"))

out |>
  pivot_longer(contains("lambda_")) |>
  ggplot() + 
  aes(t, value) +
  aes(color = name) +
  facet_wrap(~method) +
  geom_line() +
  labs(y = "lambda")

out |>
  pivot_longer(contains("N_")) |>
  ggplot() + 
  aes(t, value) +
  aes(color = name) +
  facet_wrap(~method) +
  geom_line() +
  labs(y = "N")

out |>
  pivot_longer(contains("BA_")) |>
  ggplot() + 
  aes(t, value) +
  aes(color = name) +
  facet_wrap(~method) +
  geom_line() +
  labs(y = "BA")
