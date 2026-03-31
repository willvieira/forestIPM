/-!
# Forest IPM — Lean Formalization

Formal mathematical properties of the Bayesian hierarchical Integral Projection
Model implemented in `R/`.  Each sub-module formalizes one component of the model.

| Component          | Module             | R source              | Content |
|--------------------|--------------------|-----------------------|---------|
| Demographic models | `Growth`           | `vital_rates.R`       | Fixed point, contraction, convergence of the growth map |
|                    | `Survival`         | `vital_rates.R`       | Survival probability lies in `(0, 1)` |
|                    | `Ingrowth`         | `vital_rates.R`, `kernel.R` | Recruitment rate positivity; F-kernel non-negativity |
| Covariates         | `Competition`      | `BasalArea_competition.R` | BA formula, non-negativity, monotonicity |
|                    | `Climate`          | `vital_rates.R`       | Bell curve response: positivity, maximum at optimum, strict mono |
| Population model   | `GaussLegendre`    | `gauss_legendre.R`    | Quadrature weight positivity and sum = `b − a` |
|                    | `Kernel`           | `kernel.R`            | `K = P + F`, non-negativity |
| Engines            | `AsymptoticLambda` | `lambda.R`            | `λ = max(eigenvalues(K))` — ecological interpretation |
|                    | `CommunityDynamic` | `project.R`           | `n_{t+1} = K(n_t)·n_t`, non-negativity invariant, equilibrium |
-/

import ForestIPM.Growth
import ForestIPM.Survival
import ForestIPM.Ingrowth
import ForestIPM.Competition
import ForestIPM.Climate
import ForestIPM.GaussLegendre
import ForestIPM.Kernel
import ForestIPM.AsymptoticLambda
import ForestIPM.CommunityDynamic
