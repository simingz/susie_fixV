% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/update_each_effect.R
\name{update_each_effect}
\alias{update_each_effect}
\title{update each effect}
\usage{
update_each_effect(X, Y, s, estimate_prior_variance = FALSE,
  estimate_prior_method = "optim", check_null_threshold)
}
\arguments{
\item{X}{an n by p matrix of regressor variables}

\item{Y}{an n vector of response variable}

\item{s}{a SuSiE fit}

\item{estimate_prior_variance}{boolean indicating whether to
estimate prior variance}

\item{check_null_threshold}{float a threshold on the log scale to
compare likelihood between current estimate and zero the null}
}
\description{
Revised from original susieR::update_each_effect.
  Added susieR::: for all functions from susie
}
