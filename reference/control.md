# Configure IPM lambda and project engine settings

Configure IPM lambda and project engine settings

## Usage

``` r
control(
  delta_time = 1,
  years = 100,
  store_every = 1,
  compute_lambda = TRUE,
  progress = TRUE,
  integration_method = "gauss-legendre",
  n_gl = 200L,
  bin_width = 1
)
```

## Arguments

- delta_time:

  Positive numeric. Duration of each timestep in years. Default 1.

- years:

  Positive integer. Number of simulation timesteps. Used only for
  [`project()`](https://willvieira.github.io/forestIPM/reference/project.md)
  engine. Default 100.

- store_every:

  Positive integer. Store stand state every N timesteps. Used only for
  [`project()`](https://willvieira.github.io/forestIPM/reference/project.md)
  engine. Default 1.

- compute_lambda:

  Logical. Whether to compute the asymptotic lambda at each timestep.
  Used only for
  [`project()`](https://willvieira.github.io/forestIPM/reference/project.md)
  engine. Set to FALSE to skip (faster projections when only population
  structure is needed). Default TRUE.

- progress:

  Logical. Whether to display a progress bar during projection. Used
  only for
  [`project()`](https://willvieira.github.io/forestIPM/reference/project.md)
  engine. Default TRUE.

- integration_method:

  Character. Integration method for kernel discretization. One of
  `"midpoint"` (uniform midpoint rule) or `"gauss-legendre"` (Default;
  Gauss-Legendre quadrature, higher accuracy).

- n_gl:

  Positive integer. Number of Gauss-Legendre nodes when
  `integration_method = "gauss-legendre"`. Ignored for `"midpoint"`.
  Default 200.

- bin_width:

  Positive integer. Bin width for IPM kernel discretization when
  `integration_method = "midpoint"`. Ignored for `"gauss-legendre"`..
  Default 1.

## Value

An object of S3 class `"ipm_control"`.

## Examples

``` r
ctrl <- control(years = 10, compute_lambda = FALSE, progress = FALSE)
print(ctrl)
#> <ipm_control>  10 years | dt=1.0 | store_every=1 | bin_width=1 | lambda=no | progress=no | integration=gauss-legendre
```
