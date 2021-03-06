% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/susie_rss.R
\name{susie_rss}
\alias{susie_rss}
\title{Bayesian sum of single-effect (SuSiE) linear regression using z scores}
\usage{
susie_rss(z, R, maf = NULL, maf_thresh = 0, z_ld_weight = 0,
  L = 10, prior_variance = 50, residual_variance = NULL,
  r_tol = 1e-08, prior_weights = NULL, null_weight = NULL,
  estimate_residual_variance = TRUE, estimate_prior_variance = TRUE,
  estimate_prior_method = c("optim", "EM", "simple"),
  check_null_threshold = 0, prior_tol = 1e-09, max_iter = 100,
  s_init = list(), intercept_value = 0, coverage = 0.95,
  min_abs_corr = 0.5, tol = 0.001, verbose = FALSE,
  track_fit = FALSE, check_R = TRUE, check_z = TRUE)
}
\arguments{
\item{z}{a p vector of z scores.}

\item{R}{a p by p symmetric and positive semidefinite correlation matrix. If it is from a reference panel,
we recommend a modification on correlation matrix with parameter `z_ld_weight`.}

\item{maf}{minor allele frequency; to be used along with `maf_thresh` to filter input summary statistics}

\item{maf_thresh}{variants having MAF smaller than this threshold will be filtered out}

\item{z_ld_weight}{the weight assigned to the z in the ld matrix, the ld matrix used in model is cov2cor((1-w) R + w zz').
We recomment setting `z_ld_weight` as 1/number of samples in reference panel.}

\item{L}{maximum number of non-zero effects}

\item{prior_variance}{the prior variance (vector of length L, or scalar. In latter case gets repeated L times )}

\item{residual_variance}{the residual variance, a scaler between 0 and 1}

\item{r_tol}{tolerance level for eigen value check of positive semidefinite matrix of R.}

\item{prior_weights}{a p vector of prior probability that each element is non-zero}

\item{null_weight}{probability of no effect, for each single effect model}

\item{estimate_residual_variance}{indicates whether to estimate residual variance}

\item{estimate_prior_variance}{indicates whether to estimate prior}

\item{estimate_prior_method}{The method used for estimating prior
variance. "simple" method only compares the loglikelihood between
using specified prior variance and using zero, and chose the one that
gives larger loglikelihood.}

\item{check_null_threshold}{when prior variance is estimated, compare the
estimate with the null and set prior variance to null (zero) unless the log-likelihood
using the estimate is larger than that of null by this threshold. For example,
you can set it to 0.1 to nudge the estimate towards zero. Default is 0. Notice that setting it to non-zero
may lead to decreasing ELBO in some cases.}

\item{prior_tol}{when prior variance is estimated, compare the estimated value to this tol at the end of
the analysis and exclude a single effect from PIP computation if the estimated prior variance is smaller than it.}

\item{max_iter}{maximum number of iterations to perform}

\item{s_init}{a previous susie fit with which to initialize}

\item{intercept_value}{a value to assign to the intercept (since the intercept cannot be estimated from centered summary data). This
value will be used by coef.susie() to assign an intercept value, for consistency with the non-summary-statistic version of this function \code{susie}.
Set to NULL if you want coef.susie() not to include an intercept term (and so only return a p vector).}

\item{coverage}{coverage of confident sets. Default to 0.95 for 95\% credible interval.}

\item{min_abs_corr}{minimum of absolute value of correlation allowed in a credible set.}

\item{tol}{convergence tolerance based on elbo}

\item{verbose}{if true outputs some progress messages}

\item{track_fit}{add an attribute \code{trace} to output that saves current values of all iterations}

\item{check_R}{check whether R is positive semidefinite}

\item{check_z}{check whether z in space spanned by the non-zero eigenvectors of R}
}
\value{
a susie fit, which is a list with some or all of the following elements\cr
\item{alpha}{an L by p matrix of posterior inclusion probabilites}
\item{mu}{an L by p matrix of posterior means (conditional on inclusion)}
\item{mu2}{an L by p matrix of posterior second moments (conditional on inclusion)}
\item{Rr}{an p vector of t(X) times fitted values, the fitted values equal to X times colSums(alpha*mu))}
\item{sigma2}{residual variance}
\item{V}{prior variance}
}
\description{
Bayesian sum of single-effect (SuSiE) linear regression using z scores
}
\details{
Revised from susieR::susie_rss. Performs sum of single-effect (SuSiE) linear regression with z scores.
The summary data required are the p by p correlation matrix R, the p vector z. The summary stats should come from the same individuals.
This function fits the regression model z = sum_l Rb_l + e, where e is N(0,residual_variance * R) and the
sum_l b_l is a p vector of effects to be estimated.
The assumption is that each b_l has exactly one non-zero element, with all elements
equally likely to be non-zero. The prior on the non-zero element is N(0,var=prior_variance).
}
\examples{
set.seed(1)
n    <- 1000
p    <- 1000
beta <- rep(0,p)
beta[1:4] <- 1
X        <- matrix(rnorm(n*p),nrow=n,ncol=p)
y        <- c(X \%*\% beta + rnorm(n))
input_ss <- compute_ss(X,y,standardize = TRUE)
ss <- susieR:::univariate_regression(X, y)
R <- with(input_ss, cov2cor(XtX))
zhat <- with(ss, betahat/sebetahat)
res <- susie_rss(zhat, R)

}
