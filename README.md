# forestIPM

[![R-CMD-check](https://github.com/willvieira/forestIPM/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/willvieira/forestIPM/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/github/willvieira/forestIPM/graph/badge.svg)](https://app.codecov.io/github/willvieira/forestIPM)

`{forestIPM}` is an R package implementing a Bayesian hierarchical Integral Projection Model (IPM) designed to study tree population dynamics in eastern North America.
It combines growth, survival, and recruitment models, each parameterized as a function of climate and competition using forest inventory data.
The package provides two engines to compute population growth rates ($\lambda$) for 31 tree species and to simulate plot-level community dynamics over time.

This framework enables users to explore how demographic processes scale up to community patterns.
More broadly, `{forestIPM}` can be used to investigate the effects of climate warming on tree performance, evaluate the sensitivity of $\lambda$ to climate and competition ([📄](https://willvieira.github.io/ms_forest-ipm-sensitivity/)), examine how stochastic $\lambda$ influences species range limits ([📄](https://willvieira.github.io/ms_forest-suitable-probability/)), provides a foundation for studying the mechanisms driving species coexistence, and many more.

## Documentation

A complete description of the methodology, ranging from fitting hierarchical Bayesian demographic models to constructing the IPM and applying it to ecological questions, is available in the companion book:

📓 **[Forest Demography IPM Book](https://willvieira.github.io/book_forest-demography-IPM/)**

## Basic usage

The package website provides the [function reference](https://willvieira.github.io/forestIPM/reference/index.html).
The workflow is structured around 5 constructor functions used to define the key components of the model:
- `stand()` representing a forest plot
- `species_model()` defining which species to model
- `env_condition()` specifying climate drivers
- `parameters()` defining a single reproducible parameter realization from Bayesian posteriors
- `control()` Configure IPM projection settings

These components are then passed to two main IPM engines:
- `lambda()` computing population growth rate (lambda) per species
- `project()` projecting population or community dynamics through time

For a step-by-step introduction to the package, see the [Get Started](https://willvieira.github.io/book_forest-demography-IPM/guide_IPM.html) vignette in the IPM Book.

## Installation

```r
# install.packages("devtools")
devtools::install_github("willvieira/forestIPM")
```

## Citation

If you use this package in your research, please cite the associated [article](https://willvieira.github.io/ms_forest-ipm-sensitivity/).
