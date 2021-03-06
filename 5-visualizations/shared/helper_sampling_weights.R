library(survey)
# The most conservative approach would be to center any single-PSU strata around
# the sample grand mean rather than the stratum mean
options(survey.lonely.psu = "adjust")
# alternatively, most proprietary statistical software packages have single-PSU
# strata make no contribution to the variance by default
# options(survey.lonely.psu = "certainty")
compute_ci_with_sampling_weights <- function(df) {
  # Complex sample design parameters
  DHSdesign <- svydesign(
    id = df$cluster_no,
    strata = df$stratification,
    weights = df$wgt,
    data = df,
    nest = TRUE
  )
  # tabulate indicator by region
  df_survey <- svyby(~zscore, ~agem, DHSdesign, svymean, vartype = c("se", "ci"))
  df_n <- df %>% group_by(agem) %>% summarise(wgt_sum = sum(wgt))
  df_survey <- dplyr::left_join(df_survey, df_n, by = "agem")
  return(df_survey)
}
# meta analysis using fixed effects or random effects based pooling
fit.cont.rma <- function(data, age, yi, vi, ni, nlab, method = "REML") {
  data <- filter(data, agecat == age)
  fit <- NULL
  try(fit <- rma(yi = data[[yi]], vi = data[[vi]], method = method, measure = "GEN"))
  out <- data %>%
    ungroup() %>%
    summarise(
      nstudies = length(unique(studyid)),
      nmeas = sum(data[[ni]][agecat == age])
    ) %>%
    mutate(
      agecat = age, est = fit$beta, se = fit$se, lb = fit$ci.lb, ub = fit$ci.ub,
      nmeas.f = paste0(
        "N=", format(sum(data[[ni]]), big.mark = ",", scientific = FALSE),
        " ", nlab
      ),
      nstudy.f = paste0("N=", nstudies, " studies")
    )
  return(out)
}

do_metaanalysis <- function(df_survey, pool_over, method = "FE") {
  # method = "REML"
  dhs_pooled <- list()
  for (measure_here in unique(df_survey$measure)) {
    for (age_here in 0:24) {
      df_to_pool <- df_survey %>%
          mutate(variance = se^2, agecat = agem) %>%
          filter(measure == measure_here)
      df_to_pool[, "studyid"] <- df_to_pool[, pool_over]
      df_pooled <- fit.cont.rma(
        data = df_to_pool,
        age = age_here,
        yi = "zscore",
        vi = "variance",
        ni = "wgt_sum",
        nlab = "observations",
        method = method
      )
      df_pooled$measure <- measure_here
      df_pooled$agem <- age_here
      dhs_pooled <- c(dhs_pooled, list(df_pooled))
    }
  }
  dhs_pooled <- do.call(rbind, dhs_pooled)
  return(dhs_pooled)
}


#----------------------------------
# simulataneous CIs for GAMs
# estimated by resampling the
# Baysian posterior estimates of
# the variance-covariance matrix
# assuming that it is multivariate normal
# the function below also estimates
# the unconditional variance-covariance
# matrix, Vb=vcov(x,unconditional=TRUE),
# which allows for undertainty in the actual
# estimated mean as well
# (Marra & Wood 2012 Scandinavian Journal of Statistics,
#  Vol. 39: 53–74, 2012, doi: 10.1111/j.1467-9469.2011.00760.x )
# simultaneous CIs provide much better coverage than pointwise CIs
# see: http://www.fromthebottomoftheheap.net/2016/12/15/simultaneous-interval-revisited/
#----------------------------------
gamCI <- function(m, newdata, nreps = 10000) {
  require(mgcv)
  require(dplyr)
  Vb <- vcov(m, unconditional = TRUE)
  pred <- predict(m, newdata, se.fit = TRUE)
  fit <- pred$fit
  se.fit <- pred$se.fit
  BUdiff <- MASS::mvrnorm(n = nreps, mu = rep(0, nrow(Vb)), Sigma = Vb)
  Cg <- predict(m, newdata, type = "lpmatrix")
  simDev <- Cg %*% t(BUdiff)
  absDev <- abs(sweep(simDev, 1, se.fit, FUN = "/"))
  masd <- apply(absDev, 2L, max)
  crit <- quantile(masd, prob = 0.95, type = 8)
  pred <- data.frame(newdata, fit = pred$fit, se.fit = pred$se.fit)
  pred <- mutate(pred,
    uprP = fit + (2 * se.fit),
    lwrP = fit - (2 * se.fit),
    uprS = fit + (crit * se.fit),
    lwrS = fit - (crit * se.fit)
  )
  return(pred)
}
